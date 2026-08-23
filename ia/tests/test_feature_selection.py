"""Testes da seleção determinística de campos (features.selectors)."""

from __future__ import annotations

from meu_bebe_ml.features.selectors import (
    list_x_model,
    list_x_sens,
    select_x_model,
    select_x_sens,
)
from meu_bebe_ml.schema import constants

from conftest import make_valid_record


def test_select_x_model_returns_exactly_34_fields() -> None:
    selected = select_x_model(make_valid_record())
    assert len(selected) == 34


def test_select_x_model_keys_match_constants() -> None:
    selected = select_x_model(make_valid_record())
    assert set(selected.keys()) == set(constants.X_MODEL)


def test_select_x_model_excludes_leakage_temporal_descriptive_sensitivity() -> None:
    selected = select_x_model(make_valid_record())
    keys = set(selected.keys())
    assert keys.isdisjoint(set(constants.OUT_LEAKAGE))
    assert keys.isdisjoint(set(constants.OUT_TEMPORAL))
    assert keys.isdisjoint(set(constants.DESCRIPTIVE))
    assert keys.isdisjoint(set(constants.SENSITIVITY))


def test_select_x_sens_returns_exactly_36_fields() -> None:
    selected = select_x_sens(make_valid_record())
    assert len(selected) == 36


def test_select_x_sens_keys_match_constants() -> None:
    selected = select_x_sens(make_valid_record())
    assert set(selected.keys()) == set(constants.X_SENS)


def test_x_sens_equals_x_model_plus_sensitivity() -> None:
    selected_model = set(select_x_model(make_valid_record()).keys())
    selected_sens = set(select_x_sens(make_valid_record()).keys())
    assert selected_sens == selected_model | set(constants.SENSITIVITY)


def test_selection_preserves_values_verbatim() -> None:
    """A seleção não transforma valores: apenas copia os campos originais."""
    record = make_valid_record()
    selected = select_x_model(record)
    for name in constants.X_MODEL:
        assert selected[name] == record[name]


def test_list_helpers_return_expected_lengths() -> None:
    assert len(list_x_model()) == 34
    assert len(list_x_sens()) == 36
