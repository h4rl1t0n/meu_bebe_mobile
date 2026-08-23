"""Testes de particionamento das 48 variáveis em classes metodológicas.

Garante, de forma explícita e independente, que as cinco classes
(X_MODEL, OUT_LEAKAGE, OUT_TEMPORAL, DESCRIPTIVE, SENSITIVITY) são mutuamente
disjuntas e que sua união é exatamente Q_FULL, preservando as cardinalidades
do contrato DSS 1.13.
"""

from __future__ import annotations

from itertools import combinations

from meu_bebe_ml.schema import constants


def _classes() -> dict[str, tuple[str, ...]]:
    return {
        "X_MODEL": constants.X_MODEL,
        "OUT_LEAKAGE": constants.OUT_LEAKAGE,
        "OUT_TEMPORAL": constants.OUT_TEMPORAL,
        "DESCRIPTIVE": constants.DESCRIPTIVE,
        "SENSITIVITY": constants.SENSITIVITY,
    }


def test_classes_are_mutually_disjoint() -> None:
    classes = _classes()
    names = list(classes.keys())
    for a, b in combinations(names, 2):
        set_a = set(classes[a])
        set_b = set(classes[b])
        assert set_a.isdisjoint(set_b), f"{a} e {b} se sobrepõem: {set_a & set_b}"


def test_union_of_classes_equals_q_full() -> None:
    classes = _classes()
    union: set[str] = set()
    for values in classes.values():
        union |= set(values)
    assert union == set(constants.Q_FULL)


def test_partition_cardinalities_preserved() -> None:
    assert len(constants.Q_FULL) == 48
    assert len(constants.X_MODEL) == 34
    assert len(constants.X_SENS) == 36
    assert len(constants.OUT_LEAKAGE) == 5
    assert len(constants.OUT_TEMPORAL) == 5
    assert len(constants.DESCRIPTIVE) == 2
    assert len(constants.SENSITIVITY) == 2
