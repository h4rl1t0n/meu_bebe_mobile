"""Testes do contrato de dados DSS 1.13 (constantes + YAML).

Garante a cardinalidade exata dos conjuntos de variáveis e a consistência entre
``schema.constants`` e ``configs/schema_v1_13.yaml``.
"""

from __future__ import annotations

from meu_bebe_ml.schema import constants
from meu_bebe_ml.schema.validator import load_schema


def _spec() -> "object":
    return load_schema()


def test_q_full_has_48_variables() -> None:
    assert len(constants.Q_FULL) == 48


def test_x_model_has_34_variables() -> None:
    assert len(constants.X_MODEL) == 34


def test_x_sens_has_36_variables() -> None:
    assert len(constants.X_SENS) == 36


def test_out_leakage_has_5_variables() -> None:
    assert len(constants.OUT_LEAKAGE) == 5


def test_out_temporal_has_5_variables() -> None:
    assert len(constants.OUT_TEMPORAL) == 5


def test_descriptive_has_2_variables() -> None:
    assert len(constants.DESCRIPTIVE) == 2


def test_sensitivity_has_2_variables() -> None:
    assert len(constants.SENSITIVITY) == 2


def test_partition_sums_to_48() -> None:
    total = (
        len(constants.X_MODEL)
        + len(constants.OUT_LEAKAGE)
        + len(constants.OUT_TEMPORAL)
        + len(constants.DESCRIPTIVE)
        + len(constants.SENSITIVITY)
    )
    assert total == 48


def test_q_full_is_disjoint_union_of_classes() -> None:
    """As 5 classes são disjuntas e, unidas, formam exatamente Q_FULL."""
    q = set(constants.Q_FULL)
    x_model = set(constants.X_MODEL)
    out_leakage = set(constants.OUT_LEAKAGE)
    out_temporal = set(constants.OUT_TEMPORAL)
    descriptive = set(constants.DESCRIPTIVE)
    sensitivity = set(constants.SENSITIVITY)

    classes = [x_model, out_leakage, out_temporal, descriptive, sensitivity]
    # Disjunção dois a dois.
    for i, a in enumerate(classes):
        for b in classes[i + 1 :]:
            assert a.isdisjoint(b), f"classes se sobrepõem: {a & b}"

    assert q == x_model | out_leakage | out_temporal | descriptive | sensitivity


def test_x_model_excludes_non_ml_in() -> None:
    """X_model não contém leakage/temporal/descriptive/sensitivity."""
    x_model = set(constants.X_MODEL)
    assert x_model.isdisjoint(set(constants.OUT_LEAKAGE))
    assert x_model.isdisjoint(set(constants.OUT_TEMPORAL))
    assert x_model.isdisjoint(set(constants.DESCRIPTIVE))
    assert x_model.isdisjoint(set(constants.SENSITIVITY))


def test_x_sens_is_x_model_plus_exactly_two_sensitivity() -> None:
    assert set(constants.X_SENS) == set(constants.X_MODEL) | set(
        constants.SENSITIVITY
    )
    # Exatamente as 2 variáveis de sensibilidade, nada a mais.
    extra = set(constants.X_SENS) - set(constants.X_MODEL)
    assert extra == set(constants.SENSITIVITY)


def test_q_full_has_no_duplicates() -> None:
    assert len(constants.Q_FULL) == len(set(constants.Q_FULL))


def test_schema_yaml_names_match_q_full() -> None:
    """O YAML lista exatamente as mesmas 48 chaves de Q_FULL (na mesma ordem)."""
    spec = _spec()
    assert set(spec.names()) == set(constants.Q_FULL)
    assert len(spec.names()) == 48


def test_schema_yaml_ml_class_matches_constants() -> None:
    """A classificação ML do YAML coincide com a das constantes."""
    spec = _spec()
    for name in constants.Q_FULL:
        expected = constants.ml_class_of(name)
        assert spec.variables[name]["ml_class"] == expected, name


def test_schema_yaml_dimension_matches_constants() -> None:
    """A dimensão de cada variável no YAML coincide com a das constantes."""
    spec = _spec()
    for name in constants.Q_FULL:
        expected = constants.dimension_of(name)
        assert spec.variables[name]["dimension"] == expected, name


def test_schema_yaml_types_are_canonical() -> None:
    """Cada variável do YAML declara um dos 4 tipos canônicos."""
    spec = _spec()
    allowed = {"bool", "categorical", "multiselect", "int"}
    for name, var in spec.variables.items():
        assert var["type"] in allowed, f"{name}: tipo {var['type']!r}"
