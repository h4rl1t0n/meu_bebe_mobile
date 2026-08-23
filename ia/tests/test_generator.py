"""Testes do gerador sintético de Q_full (DSS 1.13).

Cobrem reprodutibilidade por seed, integridade de Q_full (48 chaves), ausência
de metadados internos, validade integral no contrato, condicionalidades,
exclusividades e coerência estrutural.
"""

from __future__ import annotations

import numpy as np
import pytest

from meu_bebe_ml.schema import constants
from meu_bebe_ml.schema.invariants import EXCLUSIVE_OF
from meu_bebe_ml.schema.validator import load_schema, validate_record
from meu_bebe_ml.simulation import generate_q_full

_N = 150
_SEED = 42


@pytest.fixture(scope="module")
def spec():
    return load_schema()


@pytest.fixture(scope="module")
def generated():
    recs, msim = generate_q_full(n_samples=_N, seed=_SEED)
    return recs, msim


# ---------------------------------------------------------------------------
# Reproducibilidade
# ---------------------------------------------------------------------------

def test_same_seed_identical() -> None:
    r1, m1 = generate_q_full(n_samples=60, seed=7)
    r2, m2 = generate_q_full(n_samples=60, seed=7)
    assert r1 == r2
    assert m1.equals(m2)


def test_different_seed_different() -> None:
    r1, _ = generate_q_full(n_samples=60, seed=7)
    r2, _ = generate_q_full(n_samples=60, seed=8)
    assert r1 != r2


# ---------------------------------------------------------------------------
# Integridade de Q_full
# ---------------------------------------------------------------------------

def test_q_full_has_exactly_48_keys(generated) -> None:
    recs, _ = generated
    for r in recs:
        assert set(r.keys()) == set(constants.Q_FULL)
        assert len(r) == 48


def test_all_48_variables_present(generated) -> None:
    recs, _ = generated
    for r in recs:
        assert set(r.keys()) == set(constants.Q_FULL)


def test_no_internal_keys_in_q_full(generated) -> None:
    """Z, C_*, latent_*, g_*, eta, p_true, Y e IV-DSS NÃO entram em Q_full."""
    recs, _ = generated
    forbidden_exact = {
        "latent_income_band",
        "income_was_masked",
        "eta",
        "p_true",
        "Y",
        "y",
        "iv_dss",
        "IV_DSS",
    }
    for r in recs:
        keys = set(r.keys())
        assert not any(k.startswith("Z_") for k in keys)
        assert not any(k.startswith("C_") for k in keys)
        assert not any(k.startswith("g_") for k in keys)
        assert not (keys & forbidden_exact)


def test_leakage_generated_without_y(generated) -> None:
    recs, _ = generated
    nullable_bool = {"faltou_consulta", "exames_pre_natal_completos", "vacinas_em_dia"}
    for r in recs:
        assert "Y" not in r
        for name in constants.OUT_LEAKAGE:
            assert name in r
            val = r[name]
            if name in nullable_bool:
                assert val in (True, False, None), name
            else:
                assert val is not None, name


# ---------------------------------------------------------------------------
# Validação integral no contrato
# ---------------------------------------------------------------------------

def test_100_plus_records_pass_validator(generated, spec) -> None:
    recs, _ = generated
    assert len(recs) >= 100
    for r in recs:
        assert validate_record(r, spec) == []


def test_categories_belong_to_schema(generated, spec) -> None:
    recs, _ = generated
    for r in recs:
        for name, val in r.items():
            var = spec.variables[name]
            if var["type"] == "categorical" and val is not None:
                assert val in var["categories"], f"{name}={val!r}"
            elif var["type"] == "multiselect" and val is not None:
                for code in val:
                    assert code in var["categories"], f"{name} contém {code!r}"


# ---------------------------------------------------------------------------
# Condicionalidades e exclusividade
# ---------------------------------------------------------------------------

def test_employment_conditionals(generated) -> None:
    recs, _ = generated
    for r in recs:
        if r["empregado"] is True:
            assert r["tipo_emprego"] is not None
            assert r["beneficios_trabalho"], "beneficios não pode ser vazio"
            assert r["motivo_desemprego"] is None
            assert r["trabalho_permite_pre_natal"] in (True, False)
            assert r["ambiente_trabalho_seguro"] in (True, False)
            assert r["tem_pausas_descanso"] in (True, False)
        else:
            assert r["tipo_emprego"] is None
            assert r["beneficios_trabalho"] is None
            assert r["motivo_desemprego"] is not None
            assert r["trabalho_permite_pre_natal"] is None
            assert r["ambiente_trabalho_seguro"] is None
            assert r["tem_pausas_descanso"] is None


def test_coleta_conditionals(generated) -> None:
    recs, _ = generated
    for r in recs:
        if r["frequencia_coleta_lixo"] == "regular":
            assert r["destino_lixo_sem_coleta"] is None
        else:
            assert r["destino_lixo_sem_coleta"] is not None
            if r["frequencia_coleta_lixo"] == "nao_possui":
                assert r["destino_lixo_sem_coleta"] != "aguarda_proxima_coleta"


def test_multiselect_exclusivity(generated) -> None:
    recs, _ = generated
    for r in recs:
        for field, exclusive in EXCLUSIVE_OF.items():
            val = r[field]
            if not isinstance(val, list):
                continue
            if exclusive in val:
                assert val == [exclusive], f"{field}={val!r}"


# ---------------------------------------------------------------------------
# Coerência estrutural
# ---------------------------------------------------------------------------

def test_agua_encanada_coherent(generated) -> None:
    recs, msim = generated
    for i, r in enumerate(recs):
        has_piped = bool(msim.iloc[i]["has_piped_water"])
        has_agua = "agua_encanada" in r["itens_residencia"]
        assert has_agua == has_piped


def test_comodo_unico_rooms(generated) -> None:
    recs, _ = generated
    for r in recs:
        if r["tipo_moradia"] == "comodo_unico":
            assert r["numero_dormitorios"] == 1
            assert r["numero_comodos"] == 1


def test_housing_numbers_valid(generated) -> None:
    recs, _ = generated
    for r in recs:
        assert r["numero_pessoas"] >= 1
        assert r["numero_dormitorios"] >= 1
        assert r["numero_comodos"] >= 1
        assert r["numero_dormitorios"] <= r["numero_comodos"]
        assert r["numero_dormitorios"] <= r["numero_pessoas"]


def test_renda_nao_informar_keeps_latent(generated) -> None:
    recs, msim = generated
    valid_bands = {"ate_1_sm", "entre_1_2_sm", "entre_2_3_sm", "mais_3_sm"}
    for i, r in enumerate(recs):
        row = msim.iloc[i]
        band = row["latent_income_band"]
        assert band in valid_bands
        if r["faixa_renda"] == "nao_informar":
            assert bool(row["income_was_masked"]) is True
        else:
            assert r["faixa_renda"] == band
            assert bool(row["income_was_masked"]) is False


# ---------------------------------------------------------------------------
# Diversidade mínima (anti-determinismo; tolerâncias amplas)
# ---------------------------------------------------------------------------

def test_key_categorical_diversity(generated) -> None:
    recs, _ = generated
    assert len({r["escolaridade"] for r in recs}) >= 4
    assert len({r["distancia_ubs"] for r in recs}) >= 2
    assert len({r["frequencia_coleta_lixo"] for r in recs}) >= 2


def test_nao_informar_rate_reasonable(generated) -> None:
    recs, _ = generated
    rate = sum(1 for r in recs if r["faixa_renda"] == "nao_informar") / len(recs)
    assert 0.0 <= rate <= 0.2


# ---------------------------------------------------------------------------
# Benefícios (contrato Flutter: null quando desempregada)
# ---------------------------------------------------------------------------

def test_unemployed_beneficios_never_empty_list(generated) -> None:
    """empregado == false nunca usa ``[]`` para beneficios (sempre ``null``)."""
    recs, _ = generated
    for r in recs:
        if r["empregado"] is False:
            assert r["beneficios_trabalho"] is None
        else:
            assert isinstance(r["beneficios_trabalho"], list)
            assert r["beneficios_trabalho"]


def test_optional_leakage_bools_produce_some_null() -> None:
    """Os 3 booleanos opcionais (leakage) produzem null em amostra grande.

    Não exige 5,00% exato — apenas que o null_rate experimental gere algum
    missing num N suficientemente grande.
    """
    recs, _ = generate_q_full(n_samples=2000, seed=42)
    for field in ("faltou_consulta", "exames_pre_natal_completos", "vacinas_em_dia"):
        nulls = sum(1 for r in recs if r[field] is None)
        assert nulls > 0, f"{field} deveria apresentar null com null_rate=0.05"
