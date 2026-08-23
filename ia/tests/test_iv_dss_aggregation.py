"""Testes de agregação do IV-DSS (principal, parcial e sensibilidade).

Cobrem as seções 32–34 da FASE 3D: média aritmética principal (6/6), cobertura,
IV-DSS parcial (exatamente 5/6) e média generalizada de ordem 2 (sensibilidade).
"""

from __future__ import annotations

import math

import pytest

from meu_bebe_ml.iv_dss import (
    N_DIMENSIONS,
    aggregate_dimensions,
    generalized_mean_p2,
)
from meu_bebe_ml.iv_dss.types import analytically_indeterminate, valid


def _dims(values: list[float | None]) -> list:
    out = []
    for v in values:
        out.append(valid(v) if v is not None else analytically_indeterminate("ausente"))
    return out


# ---------------------------------------------------------------------------
# 32. Agregação principal
# ---------------------------------------------------------------------------

def test_iv_all_zero() -> None:
    agg = aggregate_dimensions(_dims([0.0] * 6), valid(0.0))
    assert agg.iv_dss == 0.0
    assert agg.iv_dss_coverage == 1.0


def test_iv_all_one() -> None:
    agg = aggregate_dimensions(_dims([1.0] * 6), valid(1.0))
    assert agg.iv_dss == 1.0


def test_iv_mixed_mean() -> None:
    # [0, 0.5, 1, 0.5, 0, 1] -> média = 0.5
    agg = aggregate_dimensions(_dims([0.0, 0.5, 1.0, 0.5, 0.0, 1.0]), valid(0.0))
    assert agg.iv_dss == pytest.approx(0.5)


def test_iv_one_dimension_none_no_renormalize() -> None:
    # uma dimensão ausente -> iv_dss = None (sem renormalizar pesos)
    agg = aggregate_dimensions(
        _dims([0.0, 0.0, 0.0, 0.0, 0.0, None]), valid(0.0)
    )
    assert agg.iv_dss is None
    # o parcial (5/6) é auxiliar e NÃO é o principal
    assert agg.iv_dss_parcial == pytest.approx(0.0)
    assert agg.iv_dss_coverage == pytest.approx(5 / 6)


# ---------------------------------------------------------------------------
# 33. Parcial (exatamente 5/6)
# ---------------------------------------------------------------------------

def test_partial_5_of_6() -> None:
    agg = aggregate_dimensions(
        _dims([0.0, 0.5, 1.0, 0.5, 0.0, None]), valid(0.0)
    )
    assert agg.iv_dss is None
    assert agg.iv_dss_parcial == pytest.approx(0.4)  # (0 + 0.5 + 1 + 0.5 + 0)/5
    assert agg.iv_dss_coverage == pytest.approx(5 / 6)


def test_partial_none_when_6_of_6() -> None:
    agg = aggregate_dimensions(_dims([0.0] * 6), valid(0.0))
    assert agg.iv_dss is not None
    assert agg.iv_dss_parcial is None
    assert agg.iv_dss_coverage == 1.0


def test_partial_none_when_4_of_6() -> None:
    agg = aggregate_dimensions(
        _dims([0.0, 0.0, 0.0, 0.0, None, None]), valid(0.0)
    )
    assert agg.iv_dss is None
    assert agg.iv_dss_parcial is None
    assert agg.iv_dss_coverage == pytest.approx(4 / 6)


def test_coverage_always_n_over_6() -> None:
    assert N_DIMENSIONS == 6
    agg = aggregate_dimensions(_dims([None] * 6), valid(0.0))
    assert agg.iv_dss_coverage == 0.0


# ---------------------------------------------------------------------------
# 34. Média generalizada p=2
# ---------------------------------------------------------------------------

def test_generalized_p2_exact_formula() -> None:
    values = [0.0, 0.5, 1.0, 0.5, 0.0, 1.0]
    expected = math.sqrt(sum(v * v for v in values) / len(values))
    assert generalized_mean_p2(values) == pytest.approx(expected)


def test_generalized_p2_ge_arithmetic_mean() -> None:
    values = [0.0, 0.5, 1.0, 0.25, 0.75, 0.4]
    p2 = generalized_mean_p2(values)
    mean = sum(values) / len(values)
    assert p2 >= mean - 1e-12


def test_generalized_p2_equal_values() -> None:
    values = [0.4] * 6
    assert generalized_mean_p2(values) == pytest.approx(0.4)


def test_aggregate_p2_only_when_6_of_6() -> None:
    agg6 = aggregate_dimensions(_dims([0.0, 0.5, 1.0, 0.5, 0.0, 1.0]), valid(0.0))
    assert agg6.iv_dss_generalized_p2 is not None
    agg5 = aggregate_dimensions(
        _dims([0.0, 0.5, 1.0, 0.5, 0.0, None]), valid(0.0)
    )
    assert agg5.iv_dss_generalized_p2 is None


# ---------------------------------------------------------------------------
# 20. Sensibilidade binária de Habitação (agregação)
# ---------------------------------------------------------------------------

def test_housing_binary_sensitivity_6_of_6() -> None:
    # substitui D_habitacao pelo score binário; exige 6/6
    dims = _dims([0.0, 0.0, 0.0, 0.0, 0.5, 0.0])  # D_habitacao principal = 0.5
    agg = aggregate_dimensions(dims, valid(1.0))  # binário > 3 -> 1
    # média: [0, 0, 0, 0, 1, 0] / 6 = 1/6
    assert agg.iv_dss_housing_binary_sensitivity == pytest.approx(1 / 6)


def test_housing_binary_sensitivity_none_when_5_of_6() -> None:
    dims = _dims([0.0, 0.0, 0.0, 0.0, 0.5, None])
    agg = aggregate_dimensions(dims, valid(1.0))
    assert agg.iv_dss_housing_binary_sensitivity is None
