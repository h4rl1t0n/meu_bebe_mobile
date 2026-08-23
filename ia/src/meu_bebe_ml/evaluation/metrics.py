"""Métricas preditivas CONGELADAS do protocolo v1 (funções puras e testáveis).

Todas as funções recebem ``y_true`` (binário 0/1) e ``y_probability`` (prob.
da classe positiva, em [0, 1]) e NÃO dependem de dataset real — são testadas
apenas com fixtures artificiais nesta fase.

Convenções (seção 16–20 do protocolo):
  * threshold principal = 0.50; ``prediction = probability >= 0.50``;
  * ``precision``/``recall``/``f1`` usam ``zero_division=0``;
  * ROC-AUC usa sempre PROBABILIDADES da classe positiva (nunca predição
    binária);
  * PR-AUC é ``auc(recall, precision)`` obtido de ``precision_recall_curve``
    (NÃO é Average Precision; ``average_precision`` é diagnóstico separado);
  * calibração é apenas DIAGNÓSTICO (Brier + calibration_curve, sem recalibrar).
"""

from __future__ import annotations

import numpy as np
from sklearn.calibration import calibration_curve
from sklearn.metrics import (
    accuracy_score,
    auc,
    average_precision_score,
    brier_score_loss,
    confusion_matrix,
    f1_score,
    precision_recall_curve,
    precision_score,
    recall_score,
    roc_auc_score,
)


def _validate_inputs(y_true: np.ndarray, y_probability: np.ndarray) -> None:
    y_true = np.asarray(y_true).ravel()
    y_prob = np.asarray(y_probability).ravel()

    if y_true.shape[0] != y_prob.shape[0]:
        raise ValueError(
            f"tamanhos divergentes: y_true={y_true.shape[0]} != "
            f"y_probability={y_prob.shape[0]}"
        )
    if y_true.shape[0] == 0:
        raise ValueError("y_true vazio")

    # Probabilidades fora de [0, 1] -> erro (com pequena tolerância numérica).
    if np.any(y_prob < 0.0) or np.any(y_prob > 1.0):
        raise ValueError("y_probability deve estar em [0, 1]")
    if np.any(np.isnan(y_prob)):
        raise ValueError("y_probability contém NaN")

    labels = set(np.unique(y_true.astype(int)))
    if not labels <= {0, 1}:
        raise ValueError(f"y_true deve ser binário 0/1; recebido classes {sorted(labels)!r}")


def _predict(y_probability: np.ndarray, threshold: float) -> np.ndarray:
    return (np.asarray(y_probability) >= threshold).astype(int)


def compute_binary_metrics(
    y_true: np.ndarray,
    y_probability: np.ndarray,
    threshold: float = 0.50,
) -> dict:
    """Métricas no threshold principal (0.50) + matriz de confusão.

    Retorna um ``dict`` com ``accuracy``, ``precision``, ``recall``, ``f1``,
    ``confusion_matrix`` (lista ``[[TN, FP], [FN, TP]]``) e ``threshold``.
    """
    _validate_inputs(y_true, y_probability)
    y_true = np.asarray(y_true).ravel().astype(int)
    y_prob = np.asarray(y_probability).ravel()
    y_pred = _predict(y_prob, threshold)

    cm = confusion_matrix(y_true, y_pred, labels=[0, 1])

    return {
        "threshold": float(threshold),
        "accuracy": float(accuracy_score(y_true, y_pred)),
        "precision": float(precision_score(y_true, y_pred, zero_division=0)),
        "recall": float(recall_score(y_true, y_pred, zero_division=0)),
        "f1": float(f1_score(y_true, y_pred, zero_division=0)),
        "confusion_matrix": cm.tolist(),
    }


def roc_auc(y_true: np.ndarray, y_probability: np.ndarray) -> float:
    """ROC-AUC usando probabilidades da classe positiva."""
    _validate_inputs(y_true, y_probability)
    return float(
        roc_auc_score(
            np.asarray(y_true).ravel().astype(int),
            np.asarray(y_probability).ravel(),
        )
    )


def pr_auc(y_true: np.ndarray, y_probability: np.ndarray) -> float:
    """PR-AUC = ``auc(recall, precision)`` (implementação canônica congelada).

    Usa ``precision_recall_curve`` + ``auc`` — NÃO é ``average_precision``.
    """
    _validate_inputs(y_true, y_probability)
    precision, recall, _ = precision_recall_curve(
        np.asarray(y_true).ravel().astype(int),
        np.asarray(y_probability).ravel(),
    )
    return float(auc(recall, precision))


def average_precision(y_true: np.ndarray, y_probability: np.ndarray) -> float:
    """Average Precision (diagnóstico adicional; NÃO é PR-AUC)."""
    _validate_inputs(y_true, y_probability)
    return float(
        average_precision_score(
            np.asarray(y_true).ravel().astype(int),
            np.asarray(y_probability).ravel(),
        )
    )


def brier_score(y_true: np.ndarray, y_probability: np.ndarray) -> float:
    """Brier score (diagnóstico de calibração; menor é melhor)."""
    _validate_inputs(y_true, y_probability)
    return float(
        brier_score_loss(
            np.asarray(y_true).ravel().astype(int),
            np.asarray(y_probability).ravel(),
        )
    )


def calibration_curve_quantiles(
    y_true: np.ndarray,
    y_probability: np.ndarray,
    n_bins: int = 10,
) -> tuple[np.ndarray, np.ndarray]:
    """Curva de calibração (diagnóstico) com ``strategy="quantile"``.

    Retorna ``(prob_true, prob_pred)`` — NÃO recalibra os modelos.
    """
    _validate_inputs(y_true, y_probability)
    return calibration_curve(
        np.asarray(y_true).ravel().astype(int),
        np.asarray(y_probability).ravel(),
        n_bins=n_bins,
        strategy="quantile",
    )
