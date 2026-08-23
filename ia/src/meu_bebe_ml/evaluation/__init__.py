"""Avaliação dos modelos: métricas congeladas e regra de seleção (FASE 3F-A).

Fornece funções PURAS e testáveis para métricas preditivas (threshold 0.50,
ROC-AUC, PR-AUC, Brier, calibração) e a regra congelada de seleção do modelo
(PR-AUC → Recall → F1). NENHUMA métrica real do dataset é calculada nesta fase.

REGRA DE OURO DO TEST SET: o TEST nunca participa de decisões de modelo/
hiperparâmetro/threshold/feature/preprocessing/calibração; é aberto uma única
vez, na Fase 3F-B, após a seleção via TRAIN + CV.
"""

from __future__ import annotations

from .metrics import (
    average_precision,
    brier_score,
    calibration_curve_quantiles,
    compute_binary_metrics,
    pr_auc,
    roc_auc,
)
from .protocol import (
    SELECTION_PRIMARY_METRIC,
    SELECTION_TIEBREAK,
    select_best_model,
)

__all__ = [
    "SELECTION_PRIMARY_METRIC",
    "SELECTION_TIEBREAK",
    "average_precision",
    "brier_score",
    "calibration_curve_quantiles",
    "compute_binary_metrics",
    "pr_auc",
    "roc_auc",
    "select_best_model",
]
