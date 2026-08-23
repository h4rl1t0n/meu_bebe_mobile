"""Testes de contrato do preprocessing v1 (seções 4, 5, 10, 17, 18, 24, 25).

Garantem que:
* a união dos grupos é exatamente X_MODEL, disjuntos e com 34 campos;
* o total derivado de features é 96, sem duplicatas, com ordem determinística;
* o mapa feature->campo deriva somente de X_MODEL;
* X_MODEL não intersecta OUT_LEAKAGE/OUT_TEMPORAL/DESCRIPTIVE/SENSITIVITY;
* nenhum nome de feature vem de target/OUT_*/IV-DSS/DGM internals.
"""

from __future__ import annotations

from meu_bebe_ml.preprocessing import (
    GROUP_ORDER,
    build_x_model_preprocessor,
    resolve_spec,
)
from meu_bebe_ml.schema import constants
from meu_bebe_ml.simulation import (
    CONTEXT_NAMES,
    G_FACTOR_NAMES,
    INTERACTION_NAMES,
    LATENT_NAMES,
)


def test_groups_union_equals_x_model() -> None:
    spec = resolve_spec()
    assert set(spec.config.all_fields_in_order()) == set(constants.X_MODEL)


def test_groups_disjoint() -> None:
    spec = resolve_spec()
    fields = spec.config.all_fields_in_order()
    assert len(fields) == len(set(fields))


def test_cardinality_34() -> None:
    spec = resolve_spec()
    assert len(spec.config.all_fields_in_order()) == 34
    assert spec.config.raw_feature_count == 34


def test_group_membership_counts() -> None:
    spec = resolve_spec()
    g = spec.config.group_fields()
    assert len(g["boolean_required"]) == 8
    assert len(g["boolean_structural"]) == 3
    assert len(g["numeric"]) == 3
    assert len(g["ordinal"]) == 6
    assert len(g["nominal"]) == 8
    assert len(g["multiselect"]) == 6


def test_group_order_canonical() -> None:
    assert GROUP_ORDER == (
        "boolean_required",
        "boolean_structural",
        "numeric",
        "ordinal",
        "nominal",
        "multiselect",
    )


# ---------------------------------------------------------------------------
# 17. Anti-leakage — RAW
# ---------------------------------------------------------------------------

def test_x_model_disjoint_from_out_sets() -> None:
    x = set(constants.X_MODEL)
    assert not x & set(constants.OUT_LEAKAGE)
    assert not x & set(constants.OUT_TEMPORAL)
    assert not x & set(constants.DESCRIPTIVE)
    assert not x & set(constants.SENSITIVITY)


def test_x_model_no_forbidden_raw_fields() -> None:
    forbidden = {
        "descontinuou_pre_natal",
        "Y",
        "iv_dss",
        "IV_DSS",
        "p_true",
        "eta",
        "U",
        "linear_component",
        "latent_income_band",
        "income_was_masked",
    }
    forbidden |= set(LATENT_NAMES)  # Z_*
    forbidden |= set(CONTEXT_NAMES)  # C_*
    forbidden |= set(G_FACTOR_NAMES)  # g_*
    forbidden |= set(INTERACTION_NAMES)
    assert not set(constants.X_MODEL) & forbidden


# ---------------------------------------------------------------------------
# 10 / 24. Total 96 e nomes determinísticos
# ---------------------------------------------------------------------------

def test_total_features_96() -> None:
    spec = resolve_spec()
    assert spec.n_features == 96
    assert len(spec.feature_names) == 96


def test_feature_names_unique() -> None:
    spec = resolve_spec()
    assert len(set(spec.feature_names)) == 96


def test_feature_names_deterministic() -> None:
    a = resolve_spec().feature_names
    b = resolve_spec().feature_names
    assert a == b


def test_builder_feature_names_match_spec() -> None:
    import pandas as pd

    from meu_bebe_ml.preprocessing import load_x_y

    spec = resolve_spec()
    pre = build_x_model_preprocessor(spec)
    X_raw, _ = load_x_y()
    pre.fit(X_raw)
    assert tuple(pre.get_feature_names_out()) == spec.feature_names


# ---------------------------------------------------------------------------
# 18. Anti-leakage — TRANSFORMADO
# ---------------------------------------------------------------------------

def test_source_map_sources_exactly_x_model() -> None:
    spec = resolve_spec()
    assert set(spec.source_map.values()) == set(constants.X_MODEL)
    assert len(spec.source_map) == 96


def test_feature_names_derive_only_from_x_model() -> None:
    spec = resolve_spec()
    forbidden_tokens = set(constants.OUT_LEAKAGE) | set(constants.OUT_TEMPORAL)
    forbidden_tokens |= set(constants.DESCRIPTIVE) | set(constants.SENSITIVITY)
    forbidden_tokens |= set(LATENT_NAMES) | set(CONTEXT_NAMES) | set(G_FACTOR_NAMES)
    forbidden_tokens |= {
        "descontinuou_pre_natal",
        "iv_dss",
        "IV_DSS",
        "p_true",
        "eta",
        "latent_income_band",
        "income_was_masked",
    }
    for name in spec.feature_names:
        # nenhum nome de feature é igual a um token proibido (deriva de X_MODEL).
        assert name not in forbidden_tokens


def test_every_feature_name_prefix_is_a_raw_field() -> None:
    spec = resolve_spec()
    raw = set(constants.X_MODEL)
    for name in spec.feature_names:
        prefix = name.split("__")[0]
        assert prefix in raw
