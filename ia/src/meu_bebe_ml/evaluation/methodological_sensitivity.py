"""Análise de sensibilidade metodológica (FASE 3G-B2) — funções PURAS.

Fornece funções puras e testáveis para as duas trilhas independentes da análise
de sensibilidade metodológica (análise SECUNDÁRIA; o experimento principal das
Fases 3F-A / 3F-B / 3G-A / 3G-B1 permanece congelado):

  * **3G-B2A — sensibilidade ao conjunto de variáveis.** Compara o baseline
    ``X_model`` (34 variáveis brutas, 96 features) com o conjunto de variáveis de
    sensibilidade ``X_sens`` (36 = ``X_model`` + ``problema_saude_agua`` +
    ``facil_acesso_saude``, 98 features), usando o Random Forest congelado,
    EXCLUSIVAMENTE sobre o OOF do TREINAMENTO (4000 registros) e os 5 folds
    congelados. A comparação é feita por "diferença observada" (delta) por fold
    e por resumo (mean/std/min/max) — SEM teste de hipótese e SEM p-valor.

  * **3G-B2B — sensibilidade à taxa média de probabilidade simulada.** Gera
    cenários sintéticos experimentais com taxa média de probabilidade alvo de
    15 % / 25 % / 35 % (NÃO são prevalências reais). Mantém congelados os
    coeficientes, transformações, interações, a forma logística e o desvio do
    ruído; altera APENAS o intercepto ``alpha``. A realização secundária usa
    números aleatórios comuns (CRN): o MESMO ``U_sens`` e o MESMO ``V_sens``
    são reutilizados nos 3 cenários, garantindo comparabilidade pareada.

Linguagem adotada (NUNCA usar "prevalência real", "efeito clínico" nem "melhor
modelo"): "análise de sensibilidade metodológica", "cenário sintético
experimental", "conjunto de variáveis de sensibilidade", "taxa média de
probabilidade simulada", "prevalência realizada na simulação", "diferença
observada".

Este módulo NÃO:
  * abre o TEST nem o arquivo de predições do TEST;
  * seleciona modelo nem threshold;
  * recalibra (Platt / isotonic / CalibratedClassifierCV);
  * modifica o experimento principal congelado;
  * realiza inferência estatística (sem teste t / Wilcoxon / bootstrap / p-valor).
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Sequence

import numpy as np
import pandas as pd
import yaml

from ..simulation.calibration import calibrate_alpha, sigmoid
from .calibration_stability import validate_folds_present
from .metrics import brier_score, pr_auc, roc_auc
from .threshold_analysis import compute_threshold_metrics

_CONFIG_PATH = (
    Path(__file__).resolve().parents[3] / "configs" / "methodological_sensitivity_v1.yaml"
)

# Taxas médias de probabilidade simulada alvo congeladas (trilha B2B).
_TARGET_MEAN_PROBABILITIES: tuple[float, ...] = (0.15, 0.25, 0.35)

# Tolerância da calibração de ``alpha`` (|mean(p_s) - alvo| < 1e-10).
_CALIBRATION_TOL = 1e-10

# Métricas contínuas agregadas no delta entre X_model e X_sens (trilha B2A).
FEATURE_SET_METRIC_KEYS: tuple[str, ...] = (
    "roc_auc",
    "pr_auc",
    "brier",
    "accuracy",
    "precision",
    "recall",
    "specificity",
    "f1",
    "balanced_accuracy",
)

# Contagens da matriz de confusão @0.50 (também com delta entre X_model e X_sens).
FEATURE_SET_COUNT_KEYS: tuple[str, ...] = ("tn", "fp", "fn", "tp")

# Colunas canônicas do artefato ``sensitivity_outcomes_v1.csv`` (anti-leakage:
# NUNCA ``U_sens`` / ``V_sens`` / ``p_true``).
SENSITIVITY_OUTCOME_COLUMNS: tuple[str, ...] = (
    "row_index",
    "y_sens_15",
    "y_sens_25",
    "y_sens_35",
)

_TARGET_TO_COLUMN: dict[float, str] = {
    0.15: "y_sens_15",
    0.25: "y_sens_25",
    0.35: "y_sens_35",
}


@dataclass(frozen=True)
class MethodologicalSensitivityConfig:
    """Configuração versionada da análise de sensibilidade metodológica."""

    version: str
    analysis_type: str
    model: str
    n_expected: int
    n_folds: int
    feature_set_enabled: bool
    feature_set_baseline: str
    feature_set_sensitivity: str
    outcome_base_rate_enabled: bool
    target_mean_probabilities: tuple[float, ...]
    evaluation_source: str
    evaluation_folds: str
    threshold_reference: float
    selection_enabled: bool
    test_usage_allowed: bool
    recalibration_enabled: bool
    noise_seed: int
    outcome_seed: int
    noise_sd: float


def load_methodological_sensitivity_config(
    path: Path | None = None,
) -> MethodologicalSensitivityConfig:
    """Carrega e valida a configuração versionada da análise."""
    config_path = path or _CONFIG_PATH
    with open(config_path, "r", encoding="utf-8") as fh:
        raw = yaml.safe_load(fh)

    if raw.get("selection", {}).get("enabled") is not False:
        raise ValueError("selection.enabled deve ser false (nenhuma seleção nesta fase)")
    if raw.get("test_usage", {}).get("allowed") is not False:
        raise ValueError("test_usage.allowed deve ser false (TEST não é usado)")
    if raw.get("recalibration", {}).get("enabled") is not False:
        raise ValueError("recalibration.enabled deve ser false (nenhuma recalibração)")

    tracks = raw["tracks"]
    targets = tuple(float(t) for t in tracks["outcome_base_rate"]["target_mean_probabilities"])
    if targets != _TARGET_MEAN_PROBABILITIES:
        raise ValueError(
            f"target_mean_probabilities {targets!r} != congelado {_TARGET_MEAN_PROBABILITIES!r}"
        )

    mc = raw["monte_carlo"]
    return MethodologicalSensitivityConfig(
        version=raw["version"],
        analysis_type=raw["analysis_type"],
        model=raw["model"],
        n_expected=int(raw["n_expected"]),
        n_folds=int(raw["n_folds"]),
        feature_set_enabled=bool(tracks["feature_set"]["enabled"]),
        feature_set_baseline=tracks["feature_set"]["baseline"],
        feature_set_sensitivity=tracks["feature_set"]["sensitivity"],
        outcome_base_rate_enabled=bool(tracks["outcome_base_rate"]["enabled"]),
        target_mean_probabilities=targets,
        evaluation_source=raw["evaluation"]["source"],
        evaluation_folds=raw["evaluation"]["folds"],
        threshold_reference=float(raw["evaluation"]["threshold_reference"]),
        selection_enabled=bool(raw["selection"]["enabled"]),
        test_usage_allowed=bool(raw["test_usage"]["allowed"]),
        recalibration_enabled=bool(raw["recalibration"]["enabled"]),
        noise_seed=int(mc["noise_seed"]),
        outcome_seed=int(mc["outcome_seed"]),
        noise_sd=float(mc["noise_sd"]),
    )


# ---------------------------------------------------------------------------
# Métricas por fold (compartilhadas pelas trilhas B2A e B2B)
# ---------------------------------------------------------------------------

def fold_metrics(
    y_true: np.ndarray,
    y_probability: np.ndarray,
    threshold: float = 0.50,
) -> dict[str, Any]:
    """Métricas de um único fold no threshold de referência (0.50).

    Retorna ``n``, ``y0``/``y1``, ``prevalence``, ``roc_auc``, ``pr_auc``,
    ``brier``, e as métricas de classificação ``tn``/``fp``/``fn``/``tp``,
    ``accuracy``, ``precision``, ``recall``, ``specificity``, ``f1`` e
    ``balanced_accuracy``.
    """
    y_true = np.asarray(y_true).ravel().astype(int)
    p = np.asarray(y_probability, dtype=float).ravel()
    if y_true.shape[0] != p.shape[0]:
        raise ValueError(
            f"tamanhos divergentes: y_true={y_true.shape[0]} != "
            f"y_probability={p.shape[0]}"
        )

    tm = compute_threshold_metrics(y_true, p, threshold)
    n = int(y_true.shape[0])
    y1 = int((y_true == 1).sum())
    return {
        "n": n,
        "y0": int((y_true == 0).sum()),
        "y1": y1,
        "prevalence": (y1 / n) if n else 0.0,
        "roc_auc": roc_auc(y_true, p),
        "pr_auc": pr_auc(y_true, p),
        "brier": brier_score(y_true, p),
        "tn": int(tm["tn"]),
        "fp": int(tm["fp"]),
        "fn": int(tm["fn"]),
        "tp": int(tm["tp"]),
        "accuracy": float(tm["accuracy"]),
        "precision": float(tm["precision"]),
        "recall": float(tm["recall"]),
        "specificity": float(tm["specificity"]),
        "f1": float(tm["f1"]),
        "balanced_accuracy": float(tm["balanced_accuracy"]),
    }


def per_fold_metrics(
    folds: np.ndarray,
    y_true: np.ndarray,
    y_probability: np.ndarray,
    *,
    n_folds: int = 5,
    threshold: float = 0.50,
) -> list[dict[str, Any]]:
    """Métricas por validation fold (``fold`` + :func:`fold_metrics`)."""
    folds = np.asarray(folds).ravel().astype(int)
    y_true = np.asarray(y_true).ravel().astype(int)
    p = np.asarray(y_probability, dtype=float).ravel()
    if folds.shape[0] != y_true.shape[0] or folds.shape[0] != p.shape[0]:
        raise ValueError("folds, y_true e y_probability com tamanhos divergentes")
    validate_folds_present(folds, n_folds=n_folds)

    rows: list[dict[str, Any]] = []
    for fold_id in range(n_folds):
        mask = folds == fold_id
        rows.append({"fold": int(fold_id), **fold_metrics(y_true[mask], p[mask], threshold)})
    return rows


# ---------------------------------------------------------------------------
# Trilha B2A — sensibilidade ao conjunto de variáveis (X_model vs X_sens)
# ---------------------------------------------------------------------------

def feature_set_deltas(
    baseline_rows: list[dict[str, Any]],
    sensitivity_rows: list[dict[str, Any]],
    metric_keys: Sequence[str] = FEATURE_SET_METRIC_KEYS,
) -> dict[str, Any]:
    """Diferença observada (sensibilidade − baseline) por fold + resumo.

    Para cada métrica de ``metric_keys`` calcula o delta por fold
    (``per_fold``) e o resumo descritivo ``mean``/``std``/``min``/``max``/
    ``range`` (``summary``). Nenhum teste de hipótese nem p-valor.
    """
    base_by_fold = {int(r["fold"]): r for r in baseline_rows}
    sens_by_fold = {int(r["fold"]): r for r in sensitivity_rows}
    if set(base_by_fold) != set(sens_by_fold):
        raise ValueError(
            f"folds divergentes: baseline={sorted(base_by_fold)} "
            f"sensibilidade={sorted(sens_by_fold)}"
        )

    keys = tuple(metric_keys)
    per_fold: list[dict[str, Any]] = []
    for fold_id in sorted(base_by_fold):
        b = base_by_fold[fold_id]
        s = sens_by_fold[fold_id]
        row: dict[str, Any] = {"fold": fold_id}
        for key in keys:
            row[key] = float(s[key]) - float(b[key])
        per_fold.append(row)

    summary: dict[str, dict[str, float]] = {}
    for key in keys:
        vals = np.asarray([float(r[key]) for r in per_fold], dtype=float)
        summary[key] = {
            "mean": float(vals.mean()),
            "std": float(vals.std(ddof=1)),
            "min": float(vals.min()),
            "max": float(vals.max()),
            "range": float(vals.max() - vals.min()),
        }
    return {"per_fold": per_fold, "summary": summary}


# ---------------------------------------------------------------------------
# Trilha B2B — sensibilidade à taxa média de probabilidade simulada
# ---------------------------------------------------------------------------

@dataclass
class ScenarioOutcome:
    """Resultado de um cenário sintético experimental (15/25/35 %)."""

    target_mean_probability: float
    alpha: float
    achieved_mean_probability: float
    realized_prevalence: float
    p_true: np.ndarray  # M_sim — NUNCA exportado para o CSV observado.
    y: np.ndarray  # 0/1 — exportado como y_sens_<taxa>.


def generate_sensitivity_outcomes(
    linear_component: np.ndarray,
    *,
    noise_seed: int,
    outcome_seed: int,
    noise_sd: float,
    target_mean_probabilities: Sequence[float],
) -> dict[float, ScenarioOutcome]:
    """Gera os cenários sintéticos secundários (B2B) com números aleatórios comuns.

    Usa o MESMO ``U_sens ~ Normal(0, noise_sd)`` (seed ``noise_seed``) e o MESMO
    ``V_sens ~ Uniform(0, 1)`` (seed ``outcome_seed``) nos 3 cenários (CRN). Para
    cada taxa-alvo ``s``:

      ``score_without_intercept = linear_component + U_sens``
      ``alpha_s = calibrate_alpha(score_without_intercept, s)``
      ``p_s = sigmoid(alpha_s + score_without_intercept)``
      ``Y_s = 1 se V_sens < p_s, senão 0``

    Apenas o intercepto ``alpha`` muda entre cenários; os efeitos congelados do
    DGM (``linear_component``) e o ruído são idênticos.
    """
    linear = np.asarray(linear_component, dtype=float).ravel()
    n = linear.shape[0]
    if n == 0:
        raise ValueError("linear_component vazio")
    if noise_sd < 0:
        raise ValueError("noise_sd deve ser >= 0")

    noise_rng = np.random.default_rng(noise_seed)
    outcome_rng = np.random.default_rng(outcome_seed)
    U_sens = noise_rng.normal(0.0, noise_sd, size=n)
    V_sens = outcome_rng.random(n)
    score_without_intercept = linear + U_sens

    out: dict[float, ScenarioOutcome] = {}
    for target in target_mean_probabilities:
        target = float(target)
        if not (0.0 < target < 1.0):
            raise ValueError(f"target_mean_probability fora de (0,1): {target!r}")
        alpha = calibrate_alpha(score_without_intercept, target)
        p = np.asarray(sigmoid(alpha + score_without_intercept), dtype=float)
        achieved = float(p.mean())
        if abs(achieved - target) >= _CALIBRATION_TOL:
            raise RuntimeError(
                f"calibração de alpha divergiu: |mean(p) - alvo| = "
                f"{abs(achieved - target):.3e} >= {_CALIBRATION_TOL:.0e}"
            )
        y = (V_sens < p).astype(int)
        out[target] = ScenarioOutcome(
            target_mean_probability=target,
            alpha=alpha,
            achieved_mean_probability=achieved,
            realized_prevalence=float(y.mean()),
            p_true=p,
            y=y,
        )
    return out


def scenario_monotonicity(
    outcomes: dict[float, ScenarioOutcome],
) -> dict[str, bool]:
    """Invariantes de monotonicidade entre os cenários (B2B).

    Como apenas ``alpha`` muda e os números aleatórios são comuns (CRN):
      * ``alpha_15 < alpha_25 < alpha_35`` (estritamente crescente);
      * ``p_15 <= p_25 <= p_35`` elemento a elemento (não decrescente);
      * ``Y_15 <= Y_25 <= Y_35`` elemento a elemento (não decrescente).

    Retorna um dicionário de flags booleanas; o chamador deve PARE se alguma
    for ``False``.
    """
    targets = sorted(outcomes)
    if set(targets) != set(_TARGET_MEAN_PROBABILITIES):
        raise ValueError(
            f"cenários esperados {_TARGET_MEAN_PROBABILITIES!r}, recebido {targets!r}"
        )

    alphas = [outcomes[t].alpha for t in targets]
    alpha_ok = all(alphas[i] < alphas[i + 1] for i in range(len(alphas) - 1))

    p_ok = True
    y_ok = True
    for i in range(len(targets) - 1):
        p_ok = p_ok and bool(np.all(outcomes[targets[i]].p_true <= outcomes[targets[i + 1]].p_true))
        y_ok = y_ok and bool(np.all(outcomes[targets[i]].y <= outcomes[targets[i + 1]].y))

    return {
        "alpha_strictly_increasing": bool(alpha_ok),
        "p_non_decreasing": bool(p_ok),
        "y_non_decreasing": bool(y_ok),
    }


def build_sensitivity_outcomes_dataframe(
    row_index: np.ndarray,
    outcomes: dict[float, ScenarioOutcome],
    folds: np.ndarray | None = None,
) -> pd.DataFrame:
    """Monta o artefato ``sensitivity_outcomes_v1.csv`` (anti-leakage).

    Colunas: ``row_index`` (+ ``fold`` opcional) e ``y_sens_15``/``y_sens_25``/
    ``y_sens_35``. NUNCA inclui ``U_sens``, ``V_sens`` nem ``p_true`` (são
    ``M_sim`` e representariam vazamento de informação).
    """
    row_index = np.asarray(row_index, dtype=np.int64).ravel()
    n = row_index.shape[0]

    data: dict[str, Any] = {"row_index": row_index}
    for target in sorted(outcomes):
        if target not in _TARGET_TO_COLUMN:
            raise ValueError(f"taxa-alvo desconhecida para o CSV: {target!r}")
        y = outcomes[target].y
        if y.shape[0] != n:
            raise ValueError(f"y do cenário {target} tem {y.shape[0]} linhas != {n}")
        data[_TARGET_TO_COLUMN[target]] = np.asarray(y, dtype=np.int64)

    if folds is not None:
        folds = np.asarray(folds, dtype=np.int64).ravel()
        if folds.shape[0] != n:
            raise ValueError(f"folds tem {folds.shape[0]} linhas != {n}")
        df = pd.DataFrame({"row_index": row_index, "fold": folds})
        for col in SENSITIVITY_OUTCOME_COLUMNS[1:]:
            df[col] = data[col]
        ordered = ["row_index", "fold", "y_sens_15", "y_sens_25", "y_sens_35"]
        return df[ordered]

    return pd.DataFrame(data, columns=SENSITIVITY_OUTCOME_COLUMNS)


# ---------------------------------------------------------------------------
# Métricas da trilha B2B (por cenário)
# ---------------------------------------------------------------------------

def _baseline_brier(y_true: np.ndarray, prevalence: float) -> float:
    """Brier do baseline de prevalência constante."""
    return float(np.mean((prevalence - y_true) ** 2))


def _relative_brier_improvement(model_brier: float, baseline_brier: float) -> float:
    if baseline_brier > 0:
        return float((baseline_brier - model_brier) / baseline_brier)
    return 0.0


def scenario_fold_metrics(
    folds: np.ndarray,
    y_scenario: np.ndarray,
    p_scenario: np.ndarray,
    *,
    n_folds: int = 5,
    threshold: float = 0.50,
) -> list[dict[str, Any]]:
    """Métricas por fold de um cenário B2B (com descritores relativos)."""
    folds = np.asarray(folds).ravel().astype(int)
    y_true = np.asarray(y_scenario).ravel().astype(int)
    p = np.asarray(p_scenario, dtype=float).ravel()
    if not (folds.shape[0] == y_true.shape[0] == p.shape[0]):
        raise ValueError("folds, y e p com tamanhos divergentes")
    validate_folds_present(folds, n_folds=n_folds)

    rows: list[dict[str, Any]] = []
    for fold_id in range(n_folds):
        mask = folds == fold_id
        y = y_true[mask]
        pf = p[mask]
        m = fold_metrics(y, pf, threshold)
        prevalence = m["prevalence"]
        base_brier = _baseline_brier(y, prevalence)
        rows.append(
            {
                "fold": int(fold_id),
                **m,
                "baseline_brier": base_brier,
                "relative_brier_improvement": _relative_brier_improvement(m["brier"], base_brier),
                "pr_auc_minus_prevalence": m["pr_auc"] - prevalence,
                "pr_auc_over_prevalence": (m["pr_auc"] / prevalence) if prevalence > 0 else None,
            }
        )
    return rows


def scenario_pooled_metrics(
    y_scenario: np.ndarray,
    p_scenario: np.ndarray,
    threshold: float = 0.50,
) -> dict[str, Any]:
    """Métricas pooled OOF de um cenário B2B (4000 predições concatenadas)."""
    y_true = np.asarray(y_scenario).ravel().astype(int)
    p = np.asarray(p_scenario, dtype=float).ravel()
    if y_true.shape[0] != p.shape[0]:
        raise ValueError("y e p com tamanhos divergentes")

    m = fold_metrics(y_true, p, threshold)
    prevalence = m["prevalence"]
    base_brier = _baseline_brier(y_true, prevalence)
    return {
        "n": m["n"],
        "prevalence": prevalence,
        "roc_auc": m["roc_auc"],
        "pr_auc": m["pr_auc"],
        "brier": m["brier"],
        "baseline_brier": base_brier,
        "relative_brier_improvement": _relative_brier_improvement(m["brier"], base_brier),
        "pr_auc_minus_prevalence": m["pr_auc"] - prevalence,
        "pr_auc_over_prevalence": (m["pr_auc"] / prevalence) if prevalence > 0 else None,
    }
