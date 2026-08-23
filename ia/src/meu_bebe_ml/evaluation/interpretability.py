"""Interpretabilidade pós-hoc por permutation importance OOF (FASE 3H) — funções PURAS.

Responde "quais variáveis BRUTAS de ``X_MODEL`` apresentam maior importância
preditiva para o Random Forest congelado, medida pela perda de desempenho após
permutação nas porções de validação out-of-fold?". A análise é:

  * pós-hoc;
  * secundária;
  * exclusivamente TRAIN/OOF;
  * descritiva;
  * NÃO causal.

A permutação ocorre ANTES do preprocessing, sobre as variáveis BRUTAS. Assim:

  * ``faixa_renda`` é permutada como uma única variável bruta;
  * ``dificuldades_saude`` é permutada como a lista bruta inteira;
  * ``beneficios_trabalho`` é permutada como a lista bruta inteira;

NUNCA se calcula importância dummy por dummy (por categoria codificada).

Métrica primária de importância = ``PR-AUC`` (definição congelada:
``auc(recall, precision)`` de ``precision_recall_curve``). Métricas secundárias =
``ROC-AUC`` e ``Brier``. As definições de delta seguem a convenção "valor
positivo = deterioração da métrica após permutar":

  * ``delta_pr_auc   = baseline_pr_auc   - permuted_pr_auc``
  * ``delta_roc_auc  = baseline_roc_auc  - permuted_roc_auc``
  * ``delta_brier    = permuted_brier    - baseline_brier``

Valores negativos são permitidos (não truncar em zero): uma importância negativa
pode ocorrer por variabilidade amostral.

Este módulo NÃO:
  * abre o TEST nem o arquivo de predições do TEST;
  * seleciona modelo/feature/threshold;
  * recalibra;
  * calcula p-value / teste de hipótese / bootstrap / intervalo de confiança;
  * usa ``feature_importances_`` (impurity/Gini) do Random Forest;
  * calcula SHAP / PDP / ICE;
  * modifica o experimento principal congelado.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Sequence

import numpy as np
import pandas as pd
import yaml

from ..simulation.dgm import DGM_INPUT_FIELDS
from .metrics import brier_score, pr_auc, roc_auc

_CONFIG_PATH = (
    Path(__file__).resolve().parents[3] / "configs" / "interpretability_v1.yaml"
)

# ---------------------------------------------------------------------------
# Constantes congeladas da fase
# ---------------------------------------------------------------------------

# Métrica primária de importância (perda de desempenho após permutação).
PRIMARY_METRIC: str = "pr_auc"

# Métricas secundárias (também calculadas, de forma descritiva).
SECONDARY_METRICS: tuple[str, ...] = ("roc_auc", "brier")

# Colunas canônicas do artefato ``permutation_importance_repeats_v1.csv``.
REPEAT_COLUMNS: tuple[str, ...] = (
    "feature",
    "fold",
    "repeat",
    "baseline_pr_auc",
    "permuted_pr_auc",
    "delta_pr_auc",
    "baseline_roc_auc",
    "permuted_roc_auc",
    "delta_roc_auc",
    "baseline_brier",
    "permuted_brier",
    "delta_brier",
    "is_direct_dgm_input",
)

# Colunas canônicas do artefato ``permutation_importance_features_v1.csv``.
FEATURE_SUMMARY_COLUMNS: tuple[str, ...] = (
    "feature",
    "is_direct_dgm_input",
    "mean_delta_pr_auc",
    "std_fold_delta_pr_auc",
    "min_fold_delta_pr_auc",
    "max_fold_delta_pr_auc",
    "mean_delta_roc_auc",
    "std_fold_delta_roc_auc",
    "mean_delta_brier",
    "std_fold_delta_brier",
    "median_fold_rank_pr_auc",
    "min_fold_rank_pr_auc",
    "max_fold_rank_pr_auc",
    "overall_rank_pr_auc",
)

# Grupos estruturais congelados para a análise secundária de GROUPED permutation
# importance. A permutação conjunta preserva as combinações internas do grupo.
STRUCTURAL_GROUPS: tuple[tuple[str, tuple[str, ...]], ...] = (
    (
        "WORK_STRUCTURAL",
        (
            "empregado",
            "tipo_emprego",
            "trabalho_permite_pre_natal",
            "ambiente_trabalho_seguro",
            "tem_pausas_descanso",
            "beneficios_trabalho",
        ),
    ),
    (
        "WASTE_STRUCTURAL",
        ("frequencia_coleta_lixo", "destino_lixo_sem_coleta"),
    ),
    (
        "HOUSING_COUNTS",
        ("numero_pessoas", "numero_comodos", "numero_dormitorios"),
    ),
)

# Offset do "slot" de seed dos grupos, para NÃO colidir com feature_index (0..33).
# A permutação de grupo usa ``slot = GROUP_SLOT_OFFSET + group_index``.
GROUP_SLOT_OFFSET: int = 100

# Conjunto esperado de inputs diretos do DGM (docs §18 / item 23 do protocolo).
_EXPECTED_DIRECT_DGM_INPUTS: frozenset[str] = frozenset(
    {
        "escolaridade",
        "faixa_renda",
        "distancia_ubs",
        "dificuldades_saude",
        "empregado",
        "trabalho_permite_pre_natal",
        "deixou_de_comer_falta_dinheiro",
        "numero_pessoas",
        "numero_dormitorios",
    }
)


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class InterpretabilityConfig:
    """Configuração versionada da interpretabilidade pós-hoc (FASE 3H)."""

    version: str
    analysis_type: str
    model: str
    feature_set: str
    source: str
    n_expected: int
    n_folds: int
    n_repeats: int
    permutation_seed: int
    primary_importance_metric: str
    secondary_metrics: tuple[str, ...]
    test_usage_allowed: bool
    model_selection_enabled: bool
    feature_selection_enabled: bool
    recalibration_enabled: bool


def load_interpretability_config(
    path: Path | None = None,
) -> InterpretabilityConfig:
    """Carrega e valida a configuração versionada da FASE 3H.

    Rejeita (``ValueError``) qualquer configuração que habilite decisões
    proibidas nesta fase: uso do TEST, seleção de modelo, seleção de features
    ou recalibração.
    """
    config_path = path or _CONFIG_PATH
    with open(config_path, "r", encoding="utf-8") as fh:
        raw = yaml.safe_load(fh)

    if raw.get("test_usage", {}).get("allowed") is not False:
        raise ValueError("test_usage.allowed deve ser false (TEST não é usado)")
    if raw.get("model_selection", {}).get("enabled") is not False:
        raise ValueError("model_selection.enabled deve ser false (nenhuma seleção)")
    if raw.get("feature_selection", {}).get("enabled") is not False:
        raise ValueError("feature_selection.enabled deve ser false (nenhuma seleção)")
    if raw.get("recalibration", {}).get("enabled") is not False:
        raise ValueError("recalibration.enabled deve ser false (nenhuma recalibração)")

    perm = raw["permutation"]
    primary = raw["primary_importance_metric"]
    secondary = tuple(raw["secondary_metrics"])
    if primary != PRIMARY_METRIC:
        raise ValueError(
            f"primary_importance_metric {primary!r} != congelado {PRIMARY_METRIC!r}"
        )
    if secondary != SECONDARY_METRICS:
        raise ValueError(
            f"secondary_metrics {secondary!r} != congelado {SECONDARY_METRICS!r}"
        )

    return InterpretabilityConfig(
        version=raw["version"],
        analysis_type=raw["analysis_type"],
        model=raw["model"],
        feature_set=raw["feature_set"],
        source=raw["source"],
        n_expected=int(raw["n_expected"]),
        n_folds=int(raw["folds"]),
        n_repeats=int(perm["n_repeats"]),
        permutation_seed=int(perm["seed"]),
        primary_importance_metric=primary,
        secondary_metrics=secondary,
        test_usage_allowed=bool(raw["test_usage"]["allowed"]),
        model_selection_enabled=bool(raw["model_selection"]["enabled"]),
        feature_selection_enabled=bool(raw["feature_selection"]["enabled"]),
        recalibration_enabled=bool(raw["recalibration"]["enabled"]),
    )


# ---------------------------------------------------------------------------
# RNG determinístico + permutação
# ---------------------------------------------------------------------------

def permutation_seed_sequence(
    base_seed: int,
    fold: int,
    slot: int,
    repeat: int,
) -> np.random.SeedSequence:
    """SeedSequence determinística a partir de ``(base_seed, fold, slot, repeat)``.

    NÃO usa ``hash()`` (que varia entre processos). A ordem das features é a
    ordem congelada de ``X_MODEL``; ``slot`` é o ``feature_index`` (0..33) para
    variáveis brutas, ou ``GROUP_SLOT_OFFSET + group_index`` para grupos.
    """
    return np.random.SeedSequence([int(base_seed), int(fold), int(slot), int(repeat)])


def permutation_indices(
    n: int,
    *,
    base_seed: int,
    fold: int,
    slot: int,
    repeat: int,
) -> np.ndarray:
    """Permutação determinística de ``np.arange(n)`` (índices das linhas).

    Mesmos argumentos -> MESMA permutação (reprodutível); argumentos distintos ->
    permutações (em geral) distintas e válidas.
    """
    if n < 0:
        raise ValueError("n deve ser >= 0")
    ss = permutation_seed_sequence(base_seed, fold, slot, repeat)
    rng = np.random.default_rng(ss)
    return rng.permutation(int(n))


def permute_raw_feature(X: pd.DataFrame, feature: str, perm: np.ndarray) -> pd.DataFrame:
    """Cópia de ``X`` com APENAS a coluna ``feature`` reordenada por ``perm``.

    A reordenação move os VALORES BRUTOS entre linhas (null, strings, listas,
    inteiros, booleanos são preservados como estão). Nenhum objeto interno das
    listas é modificado; as demais colunas permanecem idênticas.
    """
    if feature not in X.columns:
        raise ValueError(f"feature {feature!r} não está em X")
    perm = np.asarray(perm)
    if perm.shape[0] != len(X):
        raise ValueError(f"perm tem {perm.shape[0]} índices != {len(X)} linhas")
    X_perm = X.copy()
    X_perm[feature] = X[feature].iloc[perm].to_numpy()
    return X_perm


def permute_raw_group(
    X: pd.DataFrame, group_fields: Sequence[str], perm: np.ndarray
) -> pd.DataFrame:
    """Cópia de ``X`` com TODAS as colunas do grupo reordenadas pelo MESMO ``perm``.

    Preserva a relação interna dos valores do mesmo indivíduo dentro do grupo;
    nenhuma coluna fora do grupo muda.
    """
    fields = tuple(group_fields)
    for f in fields:
        if f not in X.columns:
            raise ValueError(f"campo do grupo {f!r} não está em X")
    perm = np.asarray(perm)
    if perm.shape[0] != len(X):
        raise ValueError(f"perm tem {perm.shape[0]} índices != {len(X)} linhas")
    X_perm = X.copy()
    for f in fields:
        X_perm[f] = X[f].iloc[perm].to_numpy()
    return X_perm


# ---------------------------------------------------------------------------
# Métricas e deltas
# ---------------------------------------------------------------------------

def baseline_metrics(y_true: np.ndarray, probs: np.ndarray) -> dict[str, float]:
    """Métricas probabilísticas (threshold-independent) do baseline de um fold."""
    return {
        "pr_auc": pr_auc(y_true, probs),
        "roc_auc": roc_auc(y_true, probs),
        "brier": brier_score(y_true, probs),
    }


def metric_deltas(
    y_true: np.ndarray,
    baseline_probs: np.ndarray,
    permuted_probs: np.ndarray,
) -> dict[str, float]:
    """Deltas de importância (positivo = deterioração) entre baseline e permutado.

    ``delta_pr_auc`` e ``delta_roc_auc`` = baseline − permutado; ``delta_brier``
    = permutado − baseline. Negativos são permitidos (não truncar).
    """
    b = baseline_metrics(y_true, baseline_probs)
    p = baseline_metrics(y_true, permuted_probs)
    return {
        "delta_pr_auc": b["pr_auc"] - p["pr_auc"],
        "delta_roc_auc": b["roc_auc"] - p["roc_auc"],
        "delta_brier": p["brier"] - b["brier"],
    }


# ---------------------------------------------------------------------------
# Agregação
# ---------------------------------------------------------------------------

def aggregate_repeats_within_fold(repeat_deltas: Sequence[float]) -> float:
    """Média dos deltas dos ``n_repeats`` dentro de um único fold."""
    arr = np.asarray(repeat_deltas, dtype=float)
    if arr.size == 0:
        raise ValueError("repeat_deltas vazio")
    return float(arr.mean())


def aggregate_fold_means(fold_means: Sequence[float]) -> dict[str, float]:
    """Resumo dos 5 fold means: ``mean``/``std`` (ddof=1)/``min``/``max``.

    O desvio principal é o desvio ENTRE os 5 fold means (não os 100 repeats
    tratados como amostras independentes).
    """
    arr = np.asarray(fold_means, dtype=float)
    if arr.size == 0:
        raise ValueError("fold_means vazio")
    return {
        "mean": float(arr.mean()),
        "std": float(arr.std(ddof=1)),
        "min": float(arr.min()),
        "max": float(arr.max()),
    }


def rank_features_descending(
    values: Sequence[float],
    tiebreak: Sequence[float] | None = None,
) -> list[int]:
    """Ranks 1..n (decrescente por ``values``); empate desempata por ``tiebreak``
    (decrescente) e depois pelo índice da feature (ordem congelada) — método
    determinístico e documentado.
    """
    n = len(values)
    if n == 0:
        return []
    vals = [float(v) for v in values]
    tb = [float(t) for t in tiebreak] if tiebreak is not None else [0.0] * n
    if len(tb) != n:
        raise ValueError("tiebreak deve ter o mesmo tamanho de values")
    order = sorted(range(n), key=lambda i: (-vals[i], -tb[i], i))
    ranks = [0] * n
    for rank, i in enumerate(order, start=1):
        ranks[i] = rank
    return ranks


# ---------------------------------------------------------------------------
# Contexto do DGM (diagnóstico descritivo)
# ---------------------------------------------------------------------------

def validate_direct_dgm_inputs() -> frozenset[str]:
    """Valida os inputs diretos do DGM congelado contra o conjunto esperado.

    Se a implementação do DGM indicar diferença, NÃO corrige silenciosamente:
    levanta ``RuntimeError`` (o chamador deve PARE e reportar).
    """
    actual = frozenset(DGM_INPUT_FIELDS)
    if actual != _EXPECTED_DIRECT_DGM_INPUTS:
        raise RuntimeError(
            f"inputs diretos do DGM divergem do esperado. atual={sorted(actual)!r} "
            f"esperado={sorted(_EXPECTED_DIRECT_DGM_INPUTS)!r}"
        )
    return actual


def is_direct_dgm_input(feature: str) -> bool:
    """True se a variável bruta participa diretamente do DGM sintético principal."""
    return feature in DGM_INPUT_FIELDS


def summarize_dgm_context(
    ranked_features: Sequence[str],
    direct_inputs: set[str] | frozenset[str] | None = None,
) -> dict[str, Any]:
    """Contexto descritivo: quantos inputs diretos caem no top-5 / top-10 e onde.

    Retorna ``direct_raw_inputs`` (ordenado), ``top5_overlap``, ``top10_overlap``
    e ``positions`` (posição de cada input direto no ranking, 1-based). NÃO cria
    "accuracy de recuperação do DGM" nem rotula feature não direta como "falsa".
    """
    direct = set(direct_inputs) if direct_inputs is not None else set(DGM_INPUT_FIELDS)
    ranked = list(ranked_features)
    positions: dict[str, int] = {}
    for i, f in enumerate(ranked, start=1):
        if f in direct:
            positions[f] = i
    top5 = sum(1 for f in ranked[:5] if f in direct)
    top10 = sum(1 for f in ranked[:10] if f in direct)
    return {
        "direct_raw_inputs": sorted(direct),
        "top5_overlap": int(top5),
        "top10_overlap": int(top10),
        "positions": positions,
    }


# ---------------------------------------------------------------------------
# Guards anti-TEST
# ---------------------------------------------------------------------------

def assert_no_test_rows(row_indices: Sequence[int], train_rows: Sequence[int]) -> None:
    """Garante que TODOS os ``row_indices`` analisados pertencem ao TRAIN congelado."""
    train_set = set(int(r) for r in train_rows)
    analyzed = set(int(r) for r in row_indices)
    if not analyzed:
        raise ValueError("nenhum row_index analisado")
    if not analyzed.issubset(train_set):
        outside = sorted(analyzed - train_set)
        raise ValueError(
            f"row_index fora do TRAIN congelado (possível TEST): {outside!r}"
        )
