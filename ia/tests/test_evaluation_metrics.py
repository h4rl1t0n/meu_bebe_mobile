"""Testes determinísticos das métricas preditivas (seções 16–20, 25, 26).

Usam APENAS fixtures artificiais controladas — nunca resultados reais do
dataset. Validam o comportamento exato de cada métrica e as guardas de
entrada (probabilidades fora de [0,1], tamanhos divergentes).
"""

from __future__ import annotations

import numpy as np
import pytest

from meu_bebe_ml.evaluation import (
    average_precision,
    brier_score,
    calibration_curve_quantiles,
    compute_binary_metrics,
    pr_auc,
    roc_auc,
)


# ---------------------------------------------------------------------------
# 26. Testes determinísticos
# ---------------------------------------------------------------------------

def test_perfect_prediction() -> None:
    y = np.array([0, 1, 0, 1])
    p = np.array([0.0, 1.0, 0.1, 0.9])
    m = compute_binary_metrics(y, p)
    assert m["accuracy"] == 1.0
    assert m["precision"] == 1.0
    assert m["recall"] == 1.0
    assert m["f1"] == 1.0
    assert m["confusion_matrix"] == [[2, 0], [0, 2]]
    assert roc_auc(y, p) == 1.0
    assert pr_auc(y, p) == 1.0


def test_all_low_probability() -> None:
    y = np.array([1, 1])
    p = np.array([0.1, 0.2])
    m = compute_binary_metrics(y, p)
    assert m["precision"] == 0.0  # zero_division=0
    assert m["recall"] == 0.0
    assert m["f1"] == 0.0


def test_threshold_0_5_boundary() -> None:
    y = np.array([1])
    p = np.array([0.5])
    # probability >= 0.50 -> positivo.
    assert compute_binary_metrics(y, p)["recall"] == 1.0


def test_confusion_matrix_correct() -> None:
    y = np.array([0, 1, 0, 1])
    p = np.array([0.9, 0.9, 0.1, 0.1])  # pred [1,1,0,0]
    cm = compute_binary_metrics(y, p)["confusion_matrix"]
    assert cm == [[1, 1], [1, 1]]  # [[TN, FP], [FN, TP]]


def test_precision_correct() -> None:
    y = np.array([0, 1, 1])
    p = np.array([0.9, 0.9, 0.1])  # pred [1,1,0]
    m = compute_binary_metrics(y, p)
    assert m["precision"] == pytest.approx(0.5)  # TP=1, FP=1
    assert m["recall"] == pytest.approx(0.5)  # TP=1, FN=1
    assert m["f1"] == pytest.approx(0.5)


def test_roc_auc_correct() -> None:
    y = np.array([0, 0, 1, 1])
    p = np.array([0.1, 0.4, 0.6, 0.9])
    assert roc_auc(y, p) == 1.0


def test_roc_auc_inverted() -> None:
    y = np.array([0, 0, 1, 1])
    p = np.array([0.9, 0.5, 0.4, 0.1])  # ranking invertido
    assert roc_auc(y, p) == 0.0


def test_pr_auc_within_expected() -> None:
    # Caso controlado com valor exato (verificado contra sklearn).
    y = np.array([0, 0, 1, 1])
    p = np.array([0.9, 0.5, 0.4, 0.1])
    assert pr_auc(y, p) == pytest.approx(0.29166667)
    # Average Precision é DIFERENTE de PR-AUC neste caso (diagnóstico separado).
    assert average_precision(y, p) == pytest.approx(0.41666667)


def test_pr_auc_distinct_from_average_precision() -> None:
    y = np.array([0, 0, 1, 1])
    p = np.array([0.9, 0.5, 0.4, 0.1])
    assert pr_auc(y, p) != pytest.approx(average_precision(y, p))


def test_brier_correct() -> None:
    y = np.array([1, 0, 1])
    p = np.array([0.9, 0.1, 0.8])
    assert brier_score(y, p) == pytest.approx(0.02)


def test_calibration_curve_diagnostic() -> None:
    y = np.array([0, 0, 1, 1, 1, 0])
    p = np.array([0.1, 0.2, 0.6, 0.7, 0.9, 0.4])
    prob_true, prob_pred = calibration_curve_quantiles(y, p, n_bins=3)
    assert prob_true.shape == prob_pred.shape
    assert np.all(prob_true >= 0.0) and np.all(prob_true <= 1.0)


# ---------------------------------------------------------------------------
# 26. Guardas de entrada
# ---------------------------------------------------------------------------

def test_probabilities_out_of_range_raises() -> None:
    with pytest.raises(ValueError):
        compute_binary_metrics(np.array([0, 1]), np.array([0.5, 1.5]))
    with pytest.raises(ValueError):
        roc_auc(np.array([0, 1]), np.array([0.5, -0.1]))


def test_length_mismatch_raises() -> None:
    with pytest.raises(ValueError):
        compute_binary_metrics(np.array([0, 1, 1]), np.array([0.5, 0.5]))
    with pytest.raises(ValueError):
        brier_score(np.array([0, 1]), np.array([0.5, 0.5, 0.5]))


def test_non_binary_y_raises() -> None:
    with pytest.raises(ValueError):
        compute_binary_metrics(np.array([0, 2]), np.array([0.5, 0.5]))
