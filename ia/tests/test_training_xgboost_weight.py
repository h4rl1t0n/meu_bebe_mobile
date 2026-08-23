"""Testes específicos do ``scale_pos_weight`` do XGBoost (seções 14, 28).

Garantem que o peso é calculado SOMENTE a partir do ``y`` passado (o ``y`` do
training fold corrente), nunca de validation/test/dataset completo/taxa DGM.
"""

from __future__ import annotations

import numpy as np
import pytest

from meu_bebe_ml.training import build_xgboost_pipeline, compute_scale_pos_weight


def test_scale_pos_weight_three_neg_one_pos() -> None:
    # [0,0,0,1] -> n_neg=3, n_pos=1 -> 3.0
    assert compute_scale_pos_weight(np.array([0, 0, 0, 1])) == 3.0


def test_scale_pos_weight_balanced() -> None:
    # [0,0,1,1] -> 2/2 -> 1.0
    assert compute_scale_pos_weight(np.array([0, 0, 1, 1])) == 1.0


def test_scale_pos_weight_uses_only_y() -> None:
    # o valor independe de qualquer outro argumento além de y.
    a = compute_scale_pos_weight(np.array([0, 0, 0, 1]))
    b = compute_scale_pos_weight(np.array([0, 0, 0, 1]))
    assert a == b == 3.0


def test_scale_pos_weight_single_class_raises() -> None:
    with pytest.raises(ValueError):
        compute_scale_pos_weight(np.array([0, 0, 0, 0]))
    with pytest.raises(ValueError):
        compute_scale_pos_weight(np.array([1, 1, 1]))


def test_scale_pos_weight_non_binary_raises() -> None:
    with pytest.raises(ValueError):
        compute_scale_pos_weight(np.array([0, 1, 2]))


def test_xgboost_pipeline_sets_scale_pos_weight_from_y_fit() -> None:
    pipe = build_xgboost_pipeline(y_fit=np.array([0, 0, 0, 1]))
    assert pipe.named_steps["model"].get_params()["scale_pos_weight"] == 3.0


def test_xgboost_pipeline_no_weight_without_y_fit() -> None:
    pipe = build_xgboost_pipeline()
    assert pipe.named_steps["model"].get_params()["scale_pos_weight"] is None
