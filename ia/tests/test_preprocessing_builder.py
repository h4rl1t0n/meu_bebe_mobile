"""Testes de integração do preprocessing v1 (builder, loader, dataset).

Cobrem seções 16, 19, 25, 26, 28, 29, 30: loader X/y, 96 features sem
NaN/Inf, independência do target, transformação determinística, 5000 linhas,
nulls estruturais e ``nao_informar`` como categoria observada.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
import pytest

from meu_bebe_ml.preprocessing import (
    build_x_model_preprocessor,
    check_structural_nulls,
    load_x_y,
    resolve_spec,
)
from meu_bebe_ml.schema import constants


@pytest.fixture(scope="module")
def loaded():
    X_raw, y = load_x_y()
    spec = resolve_spec()
    pre = build_x_model_preprocessor(spec)
    return X_raw, y, spec, pre


# ---------------------------------------------------------------------------
# 16. Dataset loader
# ---------------------------------------------------------------------------

def test_loader_columns_are_exactly_x_model(loaded) -> None:
    X_raw, _, _, _ = loaded
    assert set(X_raw.columns) == set(constants.X_MODEL)
    assert len(X_raw.columns) == 34


def test_loader_y_is_target_only(loaded) -> None:
    _, y, _, _ = loaded
    assert y.shape == (5000,)
    assert set(np.unique(y)) <= {0, 1}
    assert int((y == 0).sum()) == 3779
    assert int((y == 1).sum()) == 1221


def test_loader_no_target_in_x(loaded) -> None:
    X_raw, _, _, _ = loaded
    assert "descontinuou_pre_natal" not in X_raw.columns


# ---------------------------------------------------------------------------
# 26 / 28. 5000 linhas transformáveis, shape/dtype/NaN/Inf
# ---------------------------------------------------------------------------

def test_transform_5000_rows_shape_96(loaded) -> None:
    X_raw, _, _, pre = loaded
    Xt = pre.fit_transform(X_raw)
    assert Xt.shape == (5000, 96)
    assert Xt.dtype == np.float64


def test_transform_no_nan_inf(loaded) -> None:
    X_raw, _, _, pre = loaded
    Xt = pre.fit_transform(X_raw)
    assert np.isnan(Xt).sum() == 0
    assert np.isinf(Xt).sum() == 0


def test_all_96_columns_named(loaded) -> None:
    X_raw, _, spec, pre = loaded
    pre.fit_transform(X_raw)
    names = list(pre.get_feature_names_out())
    assert len(names) == 96
    assert all(isinstance(n, str) and n for n in names)
    assert tuple(names) == spec.feature_names


def test_no_row_lost(loaded) -> None:
    X_raw, _, _, pre = loaded
    Xt = pre.fit_transform(X_raw)
    assert Xt.shape[0] == len(X_raw) == 5000


# ---------------------------------------------------------------------------
# 25. Determinismo
# ---------------------------------------------------------------------------

def test_transform_deterministic(loaded) -> None:
    X_raw, _, _, pre = loaded
    Xt1 = pre.fit_transform(X_raw)
    Xt2 = pre.fit_transform(X_raw)
    assert np.array_equal(Xt1, Xt2)


# ---------------------------------------------------------------------------
# 19. Independência do target
# ---------------------------------------------------------------------------

def test_transform_independent_of_y(loaded) -> None:
    X_raw, y, _, pre = loaded
    y_a = y.copy()
    y_b = np.zeros_like(y)  # target completamente diferente
    pre_a = build_x_model_preprocessor(resolve_spec())
    pre_b = build_x_model_preprocessor(resolve_spec())
    Xa = pre_a.fit(X_raw, y_a).transform(X_raw)
    Xb = pre_b.fit(X_raw, y_b).transform(X_raw)
    assert np.array_equal(Xa, Xb)


# ---------------------------------------------------------------------------
# 29. Nulls estruturais
# ---------------------------------------------------------------------------

def test_structural_nulls_valid(loaded) -> None:
    X_raw, _, _, _ = loaded
    d = check_structural_nulls(X_raw)
    assert d["ok"] is True
    assert d["violations"] == []
    # null somente onde esperado
    assert d["structural_null_counts"]["tipo_emprego"] == 2097
    assert d["structural_null_counts"]["beneficios_trabalho"] == 2097
    assert d["structural_null_counts"]["destino_lixo_sem_coleta"] == 3649
    assert d["unexpected_null_counts"] == {}


# ---------------------------------------------------------------------------
# 30. nao_informar não é NaN
# ---------------------------------------------------------------------------

def test_nao_informar_is_observed_category(loaded) -> None:
    X_raw, _, _, pre = loaded
    Xt = pre.fit_transform(X_raw)
    names = list(pre.get_feature_names_out())
    idx = names.index("faixa_renda__nao_informar")
    # 285 registros têm faixa_renda == nao_informar; cada um ativa a coluna.
    assert int(Xt[:, idx].sum()) == 285
    assert np.isnan(Xt).sum() == 0  # não aumentou NaN


# ---------------------------------------------------------------------------
# 12. Preprocessor é encaixável em Pipeline (sem fit de modelo)
# ---------------------------------------------------------------------------

def test_preprocessor_pipeline_compatible() -> None:
    from sklearn.pipeline import Pipeline

    pre = build_x_model_preprocessor(resolve_spec())
    pipe = Pipeline([("preprocessor", pre)])
    # fit apenas do preprocessor (nenhum estimador final), sem split.
    X_raw, _ = load_x_y()
    Xt = pipe.fit_transform(X_raw)
    assert Xt.shape == (5000, 96)
