"""Testes das factories de pipelines (seções 11–14, 27, 29).

Verificam APENAS que os pipelines podem ser construídos, são cloneable, usam o
preprocessor v1 NÃO-fit globalmente e têm os hiperparâmetros congelados do
protocolo. NENHUM modelo é fitado no dataset principal; nenhuma métrica real.
"""

from __future__ import annotations

import numpy as np
import pytest
from sklearn.base import clone
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from xgboost import XGBClassifier

from meu_bebe_ml.preprocessing import build_x_model_preprocessor
from meu_bebe_ml.training import (
    build_logistic_pipeline,
    build_random_forest_pipeline,
    build_xgboost_pipeline,
    load_training_config,
    model_class_of,
)
from meu_bebe_ml.training.guards import forbidden_tokens

_MODEL_STEP_CLASS = {
    "logistic_regression": LogisticRegression,
    "random_forest": RandomForestClassifier,
    "xgboost": XGBClassifier,
}


def _build_all():
    return {
        "logistic_regression": build_logistic_pipeline(),
        "random_forest": build_random_forest_pipeline(),
        "xgboost": build_xgboost_pipeline(),
    }


def test_pipelines_buildable() -> None:
    for name, pipe in _build_all().items():
        assert pipe is not None
        assert list(pipe.named_steps) == ["preprocessor", "model"], name


def test_pipelines_cloneable() -> None:
    for name, pipe in _build_all().items():
        cloned = clone(pipe)
        assert cloned is not pipe
        assert cloned.named_steps["preprocessor"] is not pipe.named_steps["preprocessor"]


def test_preprocessor_step_is_preprocessing_v1() -> None:
    for name, pipe in _build_all().items():
        pre = pipe.named_steps["preprocessor"]
        assert isinstance(pre, ColumnTransformer), name


def test_preprocessor_not_fitted_globally() -> None:
    for name, pipe in _build_all().items():
        pre = pipe.named_steps["preprocessor"]
        assert not hasattr(pre, "transformers_"), f"{name}: preprocessor já fitado"


def test_fresh_preprocessor_each_build() -> None:
    p1 = build_logistic_pipeline()
    p2 = build_logistic_pipeline()
    assert p1.named_steps["preprocessor"] is not p2.named_steps["preprocessor"]


def test_model_step_class_correct() -> None:
    for name, pipe in _build_all().items():
        assert isinstance(pipe.named_steps["model"], _MODEL_STEP_CLASS[name]), name


def test_hyperparameters_match_frozen_config() -> None:
    cfg = load_training_config()
    pipes = _build_all()
    for name, pipe in pipes.items():
        model = pipe.named_steps["model"]
        frozen = cfg.model_params[name]
        for key, expected in frozen.items():
            assert model.get_params()[key] == expected, f"{name}.{key}"


def test_no_forbidden_steps() -> None:
    tokens = forbidden_tokens()
    for name, pipe in _build_all().items():
        for step_name in pipe.named_steps:
            assert step_name not in tokens, f"{name}: passo proibido {step_name}"


def test_lr_class_weight_balanced() -> None:
    model = build_logistic_pipeline().named_steps["model"]
    assert model.get_params()["class_weight"] == "balanced"


def test_rf_class_weight_balanced_subsample() -> None:
    model = build_random_forest_pipeline().named_steps["model"]
    assert model.get_params()["class_weight"] == "balanced_subsample"


def test_rf_random_state_42() -> None:
    model = build_random_forest_pipeline().named_steps["model"]
    assert model.get_params()["random_state"] == 42


def test_xgb_random_state_42() -> None:
    model = build_xgboost_pipeline().named_steps["model"]
    assert model.get_params()["random_state"] == 42


def test_xgb_fixed_params_correct() -> None:
    cfg = load_training_config()
    model = build_xgboost_pipeline().named_steps["model"]
    frozen = cfg.model_params["xgboost"]
    for key in (
        "objective",
        "eval_metric",
        "n_estimators",
        "learning_rate",
        "max_depth",
        "min_child_weight",
        "subsample",
        "colsample_bytree",
        "gamma",
        "reg_lambda",
        "tree_method",
        "n_jobs",
        "verbosity",
    ):
        assert model.get_params()[key] == frozen[key], key


def test_model_class_of_known() -> None:
    assert model_class_of("logistic_regression") is LogisticRegression
    assert model_class_of("random_forest") is RandomForestClassifier
    assert model_class_of("xgboost") is XGBClassifier


def test_model_class_of_unknown_raises() -> None:
    with pytest.raises(KeyError):
        model_class_of("svm")


def test_preprocessor_param_respected() -> None:
    custom = build_x_model_preprocessor()
    pipe = build_logistic_pipeline(preprocessor=custom)
    assert pipe.named_steps["preprocessor"] is custom
