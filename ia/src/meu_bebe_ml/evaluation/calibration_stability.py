"""Análise secundária diagnóstica de calibração e estabilidade (FASE 3G-B1).

Fornece funções PURAS e testáveis para caracterizar descritivamente a calibração
e a estabilidade das probabilidades OUT-OF-FOLD do Random Forest, usando somente
o TREINAMENTO (4000 registros) e os folds congelados.

Este módulo NÃO:
  * abre o TEST nem o arquivo de predições do TEST;
  * recalibra (Platt / isotonic / regressão logística calibrada);
  * treina, retreina, ajusta hiperparâmetro nem seleciona threshold;
  * gera modelo recalibrado.

Linguagem adotada: "diagnóstico de calibração no cenário sintético
experimental" — NUNCA "modelo clinicamente calibrado" nem "probabilidade real".

Nota metodológica (pooled OOF × média dos folds): a AUC calculada sobre todas as
predições OOF concatenadas ("pooled OOF") não precisa coincidir com a média
aritmética das AUCs calculadas separadamente nos cinco folds ("mean fold").
Ambas são reportadas para transparência, mas possuem papéis distintos.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
import yaml

from .metrics import pr_auc, roc_auc

_CONFIG_PATH = (
    Path(__file__).resolve().parents[3] / "configs" / "calibration_stability_v1.yaml"
)

# Quantis do resumo descritivo (seções 10 e 16).
_QUANTILES: tuple[float, ...] = (0.05, 0.25, 0.50, 0.75, 0.95)

# Número de bins por fold (seção 12): ~800 registros/fold -> menos bins.
_FOLD_N_BINS = 5

# Métricas agregadas na análise de estabilidade entre folds (seção 13).
_STABILITY_METRICS: tuple[str, ...] = (
    "brier",
    "roc_auc",
    "pr_auc",
    "mean_probability",
    "observed_positive_rate",
    "calibration_in_the_large_difference",
)


@dataclass(frozen=True)
class CalibrationStabilityConfig:
    """Configuração versionada da análise de calibração/estabilidade."""

    version: str
    analysis_type: str
    model: str
    source: str
    n_expected: int
    n_folds: int
    n_bins: int
    strategy: str
    recalibration_enabled: bool
    test_usage_allowed: bool
    primary_threshold_reference: float


def load_calibration_config(path: Path | None = None) -> CalibrationStabilityConfig:
    """Carrega e valida a configuração versionada da análise."""
    config_path = path or _CONFIG_PATH
    with open(config_path, "r", encoding="utf-8") as fh:
        raw = yaml.safe_load(fh)

    if raw.get("recalibration", {}).get("enabled") is not False:
        raise ValueError("recalibration.enabled deve ser false (apenas medir)")
    if raw.get("test_usage", {}).get("allowed") is not False:
        raise ValueError("test_usage.allowed deve ser false (TEST não é usado)")

    cal = raw["calibration"]
    return CalibrationStabilityConfig(
        version=raw["version"],
        analysis_type=raw["analysis_type"],
        model=raw["model"],
        source=raw["source"],
        n_expected=int(raw["n_expected"]),
        n_folds=int(raw["n_folds"]),
        n_bins=int(cal["n_bins"]),
        strategy=cal["strategy"],
        recalibration_enabled=bool(raw["recalibration"]["enabled"]),
        test_usage_allowed=bool(raw["test_usage"]["allowed"]),
        primary_threshold_reference=float(raw["primary_threshold_reference"]),
    )


def _validate(y_true: np.ndarray, y_probability: np.ndarray) -> None:
    y_true = np.asarray(y_true).ravel().astype(int)
    y_prob = np.asarray(y_probability, dtype=float).ravel()

    if y_true.shape[0] != y_prob.shape[0]:
        raise ValueError(
            f"tamanhos divergentes: y_true={y_true.shape[0]} != "
            f"y_probability={y_prob.shape[0]}"
        )
    if y_true.shape[0] == 0:
        raise ValueError("y_true vazio")

    if np.any(y_prob < 0.0) or np.any(y_prob > 1.0):
        raise ValueError("y_probability deve estar em [0, 1]")
    if np.any(~np.isfinite(y_prob)):
        raise ValueError("y_probability contém NaN ou Inf")

    labels = set(np.unique(y_true))
    if not labels <= {0, 1}:
        raise ValueError(f"y_true deve ser binário 0/1; recebido {sorted(labels)!r}")


def calibration_bins(
    y_true: np.ndarray,
    y_probability: np.ndarray,
    n_bins: int = 10,
    strategy: str = "quantile",
) -> list[dict[str, Any]]:
    """Bins de calibração (fração de positivos × média prevista) por bin.

    Espelha a binagem de ``sklearn.calibration.calibration_curve`` (mesma
    estratégia ``quantile``/``uniform``) mas devolve também os counts e o
    min/max de probabilidade por bin, SEM modificar as probabilidades.

    Cada bin retorna ``bin_index``, ``n``, ``min_probability``,
    ``max_probability``, ``mean_predicted_probability``,
    ``fraction_of_positives``, ``calibration_gap`` e
    ``absolute_calibration_gap``.
    """
    _validate(y_true, y_probability)
    if n_bins < 1:
        raise ValueError("n_bins deve ser >= 1")
    if strategy not in ("quantile", "uniform"):
        raise ValueError(f"strategy desconhecida: {strategy!r}")

    y_true = np.asarray(y_true).ravel().astype(int)
    y_prob = np.asarray(y_probability, dtype=float).ravel()

    if strategy == "quantile":
        quantiles = np.linspace(0, 1, n_bins + 1)
        edges = np.percentile(y_prob, quantiles * 100)
    else:
        edges = np.linspace(0.0, 1.0, n_bins + 1)

    binids = np.searchsorted(edges[1:-1], y_prob)
    bin_total = np.bincount(binids, minlength=len(edges))
    bin_sums = np.bincount(binids, weights=y_prob, minlength=len(edges))
    bin_true = np.bincount(binids, weights=y_true, minlength=len(edges))

    out: list[dict[str, Any]] = []
    idx = 0
    for i in range(len(edges)):
        n = int(bin_total[i])
        if n == 0:
            continue
        mean_pred = float(bin_sums[i] / n)
        frac_pos = float(bin_true[i] / n)
        gap = frac_pos - mean_pred
        mask = binids == i
        out.append(
            {
                "bin_index": idx,
                "n": n,
                "min_probability": float(y_prob[mask].min()),
                "max_probability": float(y_prob[mask].max()),
                "mean_predicted_probability": mean_pred,
                "fraction_of_positives": frac_pos,
                "calibration_gap": gap,
                "absolute_calibration_gap": abs(gap),
            }
        )
        idx += 1
    return out


def probability_summary(p: np.ndarray) -> dict[str, Any]:
    """Resumo descritivo de probabilidades (n, mean, std, min, max, mediana, quantis)."""
    p = np.asarray(p, dtype=float).ravel()
    q = {f"q{int(q * 100):02d}": float(np.quantile(p, q)) for q in _QUANTILES}
    return {
        "n": int(p.shape[0]),
        "mean_probability": float(p.mean()),
        "std_probability": float(p.std(ddof=1)),
        "min_probability": float(p.min()),
        "max_probability": float(p.max()),
        "median_probability": float(np.median(p)),
        **q,
    }


def distribution_by_class(
    y_true: np.ndarray,
    y_probability: np.ndarray,
) -> dict[str, dict[str, Any]]:
    """Resumo descritivo das probabilidades separado por ``y_true`` (0 e 1)."""
    _validate(y_true, y_probability)
    y_true = np.asarray(y_true).ravel().astype(int)
    p = np.asarray(y_probability, dtype=float).ravel()
    return {
        "y0": probability_summary(p[y_true == 0]),
        "y1": probability_summary(p[y_true == 1]),
    }


def calibration_in_the_large(
    y_true: np.ndarray,
    y_probability: np.ndarray,
) -> dict[str, float]:
    """Calibração "in the large": média prevista × prevalência observada.

    NÃO deve ser chamada isoladamente de calibração completa.
    """
    _validate(y_true, y_probability)
    y_true = np.asarray(y_true).ravel().astype(int)
    p = np.asarray(y_probability, dtype=float).ravel()
    mean_pred = float(p.mean())
    observed = float(y_true.mean())
    return {
        "mean_predicted_probability": mean_pred,
        "observed_positive_rate": observed,
        "calibration_in_the_large_difference": mean_pred - observed,
    }


def brier_and_baseline(
    y_true: np.ndarray,
    y_probability: np.ndarray,
    baseline_probability: float,
) -> dict[str, float]:
    """Brier do modelo + Brier do baseline de probabilidade constante.

    ``baseline_probability`` é a prevalência usada como predição constante.
    ``brier_relative_improvement`` é a melhoria relativa contra o baseline
    (positiva = melhor que o baseline; NÃO usada para seleção).
    """
    _validate(y_true, y_probability)
    if not (0.0 <= baseline_probability <= 1.0):
        raise ValueError(f"baseline_probability deve estar em [0,1]; recebido {baseline_probability!r}")

    y_true = np.asarray(y_true).ravel().astype(int)
    p = np.asarray(y_probability, dtype=float).ravel()

    model = float(np.mean((p - y_true) ** 2))
    baseline = float(np.mean((baseline_probability - y_true) ** 2))
    difference = model - baseline
    relative = (baseline - model) / baseline if baseline > 0 else 0.0
    return {
        "brier_model": model,
        "brier_baseline": baseline,
        "brier_difference": difference,
        "brier_relative_improvement": relative,
    }


def mean_absolute_bin_gap(bins: list[dict[str, Any]]) -> float:
    """Média (não ponderada) dos ``absolute_calibration_gap`` dos bins."""
    gaps = [abs(float(b["calibration_gap"])) for b in bins]
    return float(np.mean(gaps)) if gaps else 0.0


def weighted_mean_absolute_bin_gap(bins: list[dict[str, Any]]) -> float:
    """Média dos gaps absolutos ponderada pelo tamanho ``n`` de cada bin."""
    total = sum(int(b["n"]) for b in bins)
    if total == 0:
        return 0.0
    weighted = sum(abs(float(b["calibration_gap"])) * int(b["n"]) for b in bins)
    return float(weighted / total)


def validate_folds_present(folds: np.ndarray, n_folds: int = 5) -> None:
    """Garante que todos os folds 0..n_folds-1 estão presentes (sem fold estranho)."""
    folds = np.asarray(folds).ravel().astype(int)
    present = set(folds.tolist())
    expected = set(range(n_folds))
    if present != expected:
        raise ValueError(f"folds presentes {sorted(present)!r} != esperado {sorted(expected)!r}")


def training_prevalence(folds: np.ndarray, y_true: np.ndarray, fold_id: int) -> float:
    """Prevalência da training portion de um fold (os OUTROS folds), não do próprio."""
    folds = np.asarray(folds).ravel().astype(int)
    y_true = np.asarray(y_true).ravel().astype(int)
    mask = folds != fold_id
    if mask.sum() == 0:
        raise ValueError(f"fold {fold_id} sem training portion")
    return float(y_true[mask].mean())


def per_fold_diagnostics(
    folds: np.ndarray,
    y_true: np.ndarray,
    y_probability: np.ndarray,
    *,
    strategy: str = "quantile",
    fold_n_bins: int = _FOLD_N_BINS,
) -> list[dict[str, Any]]:
    """Diagnósticos por validation fold (seções 10–12).

    Para cada fold: n, y0, y1, prevalência observada, resumo de probabilidades,
    Brier (modelo e baseline usando a prevalência da training portion), ROC-AUC,
    PR-AUC, diferença de calibração-in-the-large e bins de calibração por fold.
    """
    folds = np.asarray(folds).ravel().astype(int)
    y_true = np.asarray(y_true).ravel().astype(int)
    p = np.asarray(y_probability, dtype=float).ravel()
    _validate(y_true, p)
    if folds.shape[0] != y_true.shape[0]:
        raise ValueError("folds e y_true com tamanhos divergentes")

    validate_folds_present(folds, n_folds=5)

    rows: list[dict[str, Any]] = []
    for fold_id in range(5):
        mask = folds == fold_id
        y = y_true[mask]
        pf = p[mask]
        train_prev = float(y_true[~mask].mean())
        b = brier_and_baseline(y, pf, train_prev)
        citl = calibration_in_the_large(y, pf)
        rows.append(
            {
                "fold": int(fold_id),
                "n": int(mask.sum()),
                "y0": int((y == 0).sum()),
                "y1": int((y == 1).sum()),
                "observed_positive_rate": float(y.mean()),
                **probability_summary(pf),
                "brier": b["brier_model"],
                "baseline_brier": b["brier_baseline"],
                "brier_difference": b["brier_difference"],
                "brier_relative_improvement": b["brier_relative_improvement"],
                "training_prevalence_used_for_baseline": train_prev,
                "roc_auc": roc_auc(y, pf),
                "pr_auc": pr_auc(y, pf),
                "calibration_in_the_large_difference": citl["calibration_in_the_large_difference"],
                "calibration_bins": calibration_bins(y, pf, n_bins=fold_n_bins, strategy=strategy),
            }
        )
    return rows


def stability_summary(per_fold: list[dict[str, Any]]) -> dict[str, dict[str, float]]:
    """Estatísticas de dispersão (mean/std/min/max/range) por métrica entre folds."""
    out: dict[str, dict[str, float]] = {}
    for metric in _STABILITY_METRICS:
        vals = [float(r[metric]) for r in per_fold]
        arr = np.asarray(vals, dtype=float)
        out[metric] = {
            "mean": float(arr.mean()),
            "std": float(arr.std(ddof=1)),
            "min": float(arr.min()),
            "max": float(arr.max()),
            "range": float(arr.max() - arr.min()),
        }
    return out


def summarize_calibration(
    config: CalibrationStabilityConfig,
    folds: np.ndarray,
    y_true: np.ndarray,
    y_probability: np.ndarray,
) -> dict[str, Any]:
    """Resumo determinístico da análise (sem hashes/timestamp — I/O fica no script).

    ``recalibration_performed``, ``test_used`` e ``model_modified`` são sempre
    ``False``.
    """
    folds = np.asarray(folds).ravel().astype(int)
    y_true = np.asarray(y_true).ravel().astype(int)
    p = np.asarray(y_probability, dtype=float).ravel()
    _validate(y_true, p)
    if folds.shape[0] != y_true.shape[0]:
        raise ValueError("folds e y_true com tamanhos divergentes")
    validate_folds_present(folds, n_folds=config.n_folds)

    n = int(y_true.shape[0])
    y0 = int((y_true == 0).sum())
    y1 = int((y_true == 1).sum())
    global_prev = (y1 / n) if n else 0.0

    global_bins = calibration_bins(y_true, p, n_bins=config.n_bins, strategy=config.strategy)
    brier = brier_and_baseline(y_true, p, global_prev)
    citl = calibration_in_the_large(y_true, p)
    per_fold = per_fold_diagnostics(
        folds, y_true, p, strategy=config.strategy, fold_n_bins=_FOLD_N_BINS
    )
    stability = stability_summary(per_fold)

    return {
        "analysis_version": config.version,
        "analysis_type": config.analysis_type,
        "model": config.model,
        "source": config.source,
        "n": n,
        "y0": y0,
        "y1": y1,
        "observed_positive_rate": float(global_prev),
        "probability": probability_summary(p),
        "calibration_in_the_large": citl,
        "global": {
            "brier": brier["brier_model"],
            "baseline_brier": brier["brier_baseline"],
            "brier_difference": brier["brier_difference"],
            "brier_relative_improvement": brier["brier_relative_improvement"],
            # MÉDIA DOS FOLDS — a métrica canônica da seleção (FASE 3F-B) é a
            # mean_fold_pr_auc = 0.350786 (coerente com o protocolo congelado).
            "mean_fold_roc_auc": stability["roc_auc"]["mean"],
            "mean_fold_pr_auc": stability["pr_auc"]["mean"],
            # POOLED OOF — AUC sobre as 4000 predições concatenadas. NÃO é a
            # métrica de seleção; reportada apenas para transparência.
            "pooled_oof_roc_auc": roc_auc(y_true, p),
            "pooled_oof_pr_auc": pr_auc(y_true, p),
            "calibration_bins": global_bins,
            "mean_absolute_bin_gap": mean_absolute_bin_gap(global_bins),
            "weighted_mean_absolute_bin_gap": weighted_mean_absolute_bin_gap(global_bins),
        },
        "distribution_by_class": distribution_by_class(y_true, p),
        "per_fold": per_fold,
        "stability": stability,
        "recalibration_performed": False,
        "test_used": False,
        "model_modified": False,
    }
