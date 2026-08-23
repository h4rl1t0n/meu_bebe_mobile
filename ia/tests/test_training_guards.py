"""Testes dos guards anti-leakage (seção 33).

Garantem que o treinamento nunca recebe M_sim/IV-DSS/DGM internals, target nem
metadados de split/folds como feature/coluna.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
import pytest

from meu_bebe_ml.preprocessing import load_x_y
from meu_bebe_ml.schema import constants
from meu_bebe_ml.training.guards import (
    assert_no_forbidden_columns,
    assert_x_is_x_model_only,
    forbidden_tokens,
    y_is_binary,
)


def test_forbidden_contains_dgm_internals() -> None:
    tokens = forbidden_tokens()
    for name in (
        "Z_SES",
        "Z_LAB",
        "Z_TERR",
        "Z_INFRA",
        "Z_SERV",
        "C_LAB",
        "C_INFRA",
        "C_ACCESS",
        "C_FOOD",
        "g_escolaridade",
        "g_renda",
        "interaction_income_food",
        "interaction_distance_transport",
        "I1",
        "I2",
        "linear_component",
        "U",
        "eta",
        "p_true",
        "latent_income_band",
        "income_was_masked",
        "crowding_ratio",
        "alpha",
    ):
        assert name in tokens, name


def test_forbidden_contains_iv_dss() -> None:
    tokens = forbidden_tokens()
    for name in (
        "IV_DSS",
        "iv_dss",
        "iv_dss_parcial",
        "D_educacao",
        "D_trabalho",
        "D_saneamento",
        "D_acesso",
        "D_habitacao",
        "D_alimentacao",
    ):
        assert name in tokens, name


def test_forbidden_contains_target_and_split_metadata() -> None:
    tokens = forbidden_tokens()
    for name in ("descontinuou_pre_natal", "Y", "row_index", "split", "validation_fold"):
        assert name in tokens, name


def test_forbidden_contains_out_sets() -> None:
    tokens = forbidden_tokens()
    for name in (
        constants.OUT_LEAKAGE
        + constants.OUT_TEMPORAL
        + constants.DESCRIPTIVE
        + constants.SENSITIVITY
    ):
        assert name in tokens, name


def test_assert_no_forbidden_columns_ok() -> None:
    assert_no_forbidden_columns(list(constants.X_MODEL))


def test_assert_no_forbidden_columns_raises() -> None:
    with pytest.raises(ValueError):
        assert_no_forbidden_columns(["empregado", "g_renda"])


def test_assert_no_forbidden_columns_prefix_raises() -> None:
    # feature derivada nunca deve começar com token proibido.
    with pytest.raises(ValueError):
        assert_no_forbidden_columns(["g_renda__x"])


def test_x_is_x_model_only_ok() -> None:
    X_raw, _ = load_x_y()
    assert_x_is_x_model_only(X_raw)


def test_x_is_x_model_only_extra_raises() -> None:
    X_raw, _ = load_x_y()
    extra = X_raw.copy()
    extra["latent_income_band"] = 0.0
    with pytest.raises(ValueError):
        assert_x_is_x_model_only(extra)


def test_y_is_binary() -> None:
    assert y_is_binary(np.array([0, 1, 0, 1])) is True
    assert y_is_binary(np.array([0, 0])) is True
    assert y_is_binary(np.array([0, 2])) is False
