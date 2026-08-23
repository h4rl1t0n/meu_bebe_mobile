"""Análise secundária exploratória de thresholds (FASE 3G-A).

Fornece funções PURAS e testáveis para descrever o comportamento do threshold
do modelo selecionado (Random Forest) usando EXCLUSIVAMENTE predições
out-of-fold do conjunto de TREINAMENTO.

Este módulo NÃO:
  * carrega o TEST, ``test_predictions_selected_v1.csv`` nem os índices do TEST;
  * seleciona um threshold operacional (``operational_threshold_selected`` é
    sempre ``False`` e ``selected_new_threshold`` permanece ``None``/``null``);
  * treina, recalibra, faz tuning nem altera o modelo selecionado.

Convenções (espelham o protocolo congelado):
  * threshold primário de referência = 0.50;
  * ``prediction = probability >= threshold``;
  * recall = TP/(TP+FN); specificity = TN/(TN+FP); precision/PPV = TP/(TP+FP);
    NPV = TN/(TN+FN); F1 = 2*precision*recall/(precision+recall);
    balanced accuracy = (recall+specificity)/2; predicted positive rate =
    (TP+FP)/N. Todas as divisões usam zero_division=0.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
import yaml

from .metrics import compute_binary_metrics

_CONFIG_PATH = (
    Path(__file__).resolve().parents[3] / "configs" / "threshold_analysis_v1.yaml"
)

# Quantis usados no resumo descritivo das probabilidades (seção 14).
_QUANTILES: tuple[float, ...] = (
    0.01, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.99,
)


@dataclass(frozen=True)
class ThresholdAnalysisConfig:
    """Configuração versionada da análise de threshold (imutável em uso)."""

    version: str
    analysis_type: str
    source: str
    model: str
    n_expected: int
    primary_threshold_reference: float
    grid_start: float
    grid_stop: float
    grid_step: float
    reference_thresholds: tuple[float, ...]
    selection_enabled: bool


def load_threshold_config(path: Path | None = None) -> ThresholdAnalysisConfig:
    """Carrega e valida a configuração versionada da análise de threshold."""
    config_path = path or _CONFIG_PATH
    with open(config_path, "r", encoding="utf-8") as fh:
        raw = yaml.safe_load(fh)

    if raw.get("selection", {}).get("enabled") is not False:
        raise ValueError("selection.enabled deve ser false (nenhum threshold é selecionado)")

    grid = raw["threshold_grid"]
    return ThresholdAnalysisConfig(
        version=raw["version"],
        analysis_type=raw["analysis_type"],
        source=raw["source"],
        model=raw["model"],
        n_expected=int(raw["n_expected"]),
        primary_threshold_reference=float(raw["primary_threshold_reference"]),
        grid_start=float(grid["start"]),
        grid_stop=float(grid["stop"]),
        grid_step=float(grid["step"]),
        reference_thresholds=tuple(float(t) for t in raw["reference_thresholds"]),
        selection_enabled=bool(raw["selection"]["enabled"]),
    )


def build_threshold_grid(
    start: float = 0.05,
    stop: float = 0.50,
    step: float = 0.01,
) -> list[float]:
    """Grade de thresholds ``[start, stop]`` inclusive, passo ``step``.

    Usa ``round(..., 10)`` para evitar deriva de ponto flutuante. Para o padrão
    (0.05, 0.50, 0.01) retorna exatamente 46 valores, de 0.05 até 0.50.
    """
    start = float(start)
    stop = float(stop)
    step = float(step)
    if step <= 0:
        raise ValueError("step deve ser > 0")
    if start > stop:
        raise ValueError("start deve ser <= stop")

    count = round((stop - start) / step)
    thresholds = [round(start + i * step, 10) for i in range(count + 1)]
    if thresholds and abs(thresholds[-1] - stop) > 1e-9:
        thresholds[-1] = round(stop, 10)
    return thresholds


def compute_threshold_metrics(
    y_true: np.ndarray,
    y_probability: np.ndarray,
    threshold: float = 0.50,
) -> dict[str, Any]:
    """Métricas completas de classificação binária em um threshold.

    Retorna ``threshold``, ``n``, ``tn``/``fp``/``fn``/``tp``, ``accuracy``,
    ``precision``, ``recall``, ``specificity``, ``f1``,
    ``negative_predictive_value``, ``false_positive_rate``,
    ``false_negative_rate``, ``balanced_accuracy``,
    ``predicted_positive_count`` e ``predicted_positive_rate``.

    ``zero_division=0`` em todas as divisões. Threshold fora de [0, 1] levanta
    ``ValueError``.
    """
    threshold = float(threshold)
    if not np.isfinite(threshold) or not (0.0 <= threshold <= 1.0):
        raise ValueError(f"threshold deve estar em [0, 1]; recebido {threshold!r}")

    base = compute_binary_metrics(y_true, y_probability, threshold)
    tn, fp = base["confusion_matrix"][0]
    fn, tp = base["confusion_matrix"][1]
    n = int(tn + fp + fn + tp)

    recall = float(base["recall"])
    precision = float(base["precision"])
    specificity = tn / (tn + fp) if (tn + fp) > 0 else 0.0
    npv = tn / (tn + fn) if (tn + fn) > 0 else 0.0
    fpr = fp / (fp + tn) if (fp + tn) > 0 else 0.0
    fnr = fn / (fn + tp) if (fn + tp) > 0 else 0.0
    balanced_accuracy = (recall + specificity) / 2.0
    predicted_positive_count = int(tp + fp)
    predicted_positive_rate = predicted_positive_count / n if n > 0 else 0.0

    return {
        "threshold": threshold,
        "n": n,
        "tn": int(tn),
        "fp": int(fp),
        "fn": int(fn),
        "tp": int(tp),
        "accuracy": float(base["accuracy"]),
        "precision": precision,
        "recall": recall,
        "specificity": float(specificity),
        "f1": float(base["f1"]),
        "negative_predictive_value": float(npv),
        "false_positive_rate": float(fpr),
        "false_negative_rate": float(fnr),
        "balanced_accuracy": float(balanced_accuracy),
        "predicted_positive_count": predicted_positive_count,
        "predicted_positive_rate": float(predicted_positive_rate),
    }


def compute_threshold_table(
    y_true: np.ndarray,
    y_probability: np.ndarray,
    thresholds: list[float],
) -> list[dict[str, Any]]:
    """Aplica :func:`compute_threshold_metrics` a cada threshold da grade."""
    return [compute_threshold_metrics(y_true, y_probability, t) for t in thresholds]


def select_reference_rows(
    table: list[dict[str, Any]],
    reference_thresholds: tuple[float, ...] | list[float],
    tol: float = 1e-9,
) -> list[dict[str, Any]]:
    """Filtra as linhas da tabela cujos thresholds pertencem à lista de referência."""
    refs = [round(float(t), 10) for t in reference_thresholds]
    out: list[dict[str, Any]] = []
    for row in table:
        t = round(float(row["threshold"]), 10)
        if any(abs(t - r) < tol for r in refs):
            out.append(row)
    return out


def find_exploratory_max_f1(table: list[dict[str, Any]]) -> dict[str, Any]:
    """Threshold do grid com maior F1 (EXPLORATÓRIO, não operacional).

    Em empate, escolhe o MENOR threshold (maior sensibilidade) — determinístico.
    NÃO altera o threshold primário nem seleciona threshold operacional.
    """
    if not table:
        raise ValueError("tabela de thresholds vazia")
    best = max(table, key=lambda r: (float(r["f1"]), -float(r["threshold"])))
    return {
        "threshold": float(best["threshold"]),
        "f1": float(best["f1"]),
        "precision": float(best["precision"]),
        "recall": float(best["recall"]),
        "predicted_positive_count": int(best["predicted_positive_count"]),
        "predicted_positive_rate": float(best["predicted_positive_rate"]),
    }


def validate_oof_train_only(
    row_index: np.ndarray,
    train_idx: np.ndarray,
    test_idx: np.ndarray,
) -> None:
    """Garante que todo ``row_index`` pertence ao TRAIN congelado (e NÃO ao TEST).

    Levanta ``ValueError`` se houver sobreposição com o TEST ou se a cobertura do
    TRAIN estiver incompleta. É a guarda funcional da REGRA DE OURO (o TEST não
    é usado).
    """
    rows = set(np.asarray(row_index, dtype=np.int64).ravel().tolist())
    train = set(np.asarray(train_idx, dtype=np.int64).ravel().tolist())
    test = set(np.asarray(test_idx, dtype=np.int64).ravel().tolist())

    if rows & test:
        raise ValueError(f"row_index contém {len(rows & test)} índice(s) do TEST")
    if not rows <= train:
        raise ValueError(
            f"row_index contém {len(rows - train)} índice(s) fora do TRAIN congelado"
        )


def summarize_analysis(
    table: list[dict[str, Any]],
    config: ThresholdAnalysisConfig,
    y_true: np.ndarray,
    y_probability: np.ndarray,
) -> dict[str, Any]:
    """Resumo determinístico da análise (sem hashes/timestamp — I/O fica no script).

    ``operational_threshold_selected`` é sempre ``False`` e
    ``selected_new_threshold`` permanece ``None``.
    """
    y_true = np.asarray(y_true).ravel().astype(int)
    p = np.asarray(y_probability, dtype=float).ravel()

    n = int(y_true.shape[0])
    y0 = int((y_true == 0).sum())
    y1 = int((y_true == 1).sum())
    grid = build_threshold_grid(config.grid_start, config.grid_stop, config.grid_step)
    max_f1 = find_exploratory_max_f1(table)

    return {
        "analysis_version": config.version,
        "analysis_type": config.analysis_type,
        "model": config.model,
        "source": config.source,
        "n": n,
        "y0": y0,
        "y1": y1,
        "positive_rate": (y1 / n) if n > 0 else 0.0,
        "probability": _probability_stats(p),
        "threshold_grid": grid,
        "primary_threshold_reference": float(config.primary_threshold_reference),
        "primary_threshold": float(config.primary_threshold_reference),
        "reference_thresholds": [float(t) for t in config.reference_thresholds],
        "metrics": table,
        "reference_metrics": select_reference_rows(table, config.reference_thresholds),
        "exploratory_max_f1_threshold": max_f1["threshold"],
        "exploratory_max_f1": max_f1["f1"],
        "exploratory_max_f1_detail": max_f1,
        "operational_threshold_selected": False,
        "selected_new_threshold": None,
    }


def _probability_stats(p: np.ndarray) -> dict[str, float]:
    p = np.asarray(p, dtype=float).ravel()
    return {
        "min": float(p.min()),
        "max": float(p.max()),
        "mean": float(p.mean()),
        "std": float(p.std(ddof=1)),
        **{f"q{int(q * 100):02d}": float(np.quantile(p, q)) for q in _QUANTILES},
    }
