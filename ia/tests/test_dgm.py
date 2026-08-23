"""Testes determinísticos dos fatores ``g_*`` do DGM (FASE 3C).

Cobrem os mapeamentos de cada fator (docs §18.1), a recuperação da renda
latente quando ``nao_informar``, a coerência de renda, e a restrição de inputs
do DGM (nenhuma OUT_LEAKAGE/OUT_TEMPORAL, tudo em X_MODEL).
"""

from __future__ import annotations

import pytest

from meu_bebe_ml.schema import constants
from meu_bebe_ml.simulation.dgm import (
    DGM_INPUT_FIELDS,
    compute_g_factors,
    crowding_ratio,
    g_adensamento,
    g_distancia,
    g_escolaridade,
    g_organizacao,
    g_privacao_alimentar,
    g_renda,
    g_trabalho,
    g_transporte,
)


# ---------------------------------------------------------------------------
# g_escolaridade
# ---------------------------------------------------------------------------

def test_g_escolaridade_full_mapping() -> None:
    expected = {
        "superior_completo": 0.00,
        "superior_incompleto": 0.17,
        "medio_completo": 0.33,
        "medio_incompleto": 0.50,
        "fundamental_completo": 0.67,
        "fundamental_incompleto": 0.83,
        "sem_instrucao": 1.00,
    }
    for cat, val in expected.items():
        assert g_escolaridade(cat) == val


def test_g_escolaridade_unknown_raises() -> None:
    with pytest.raises(ValueError):
        g_escolaridade("doutorado")


# ---------------------------------------------------------------------------
# g_renda (com renda latente)
# ---------------------------------------------------------------------------

def test_g_renda_observed() -> None:
    # caso A: faixa_renda == latent_income_band (não mascarada)
    assert g_renda("ate_1_sm", "ate_1_sm") == 1.00
    assert g_renda("mais_3_sm", "mais_3_sm") == 0.00


def test_g_renda_masked_uses_latent() -> None:
    # caso B: nao_informar -> usa latent_income_band
    assert g_renda("nao_informar", "entre_2_3_sm") == 0.33


def test_g_renda_masked_requires_latent() -> None:
    with pytest.raises(ValueError):
        g_renda("nao_informar", None)


def test_g_renda_incoherence_raises() -> None:
    # caso C: faixa_renda != nao_informar e != latent_income_band
    with pytest.raises(ValueError):
        g_renda("ate_1_sm", "entre_2_3_sm")


# ---------------------------------------------------------------------------
# g_distancia
# ---------------------------------------------------------------------------

def test_g_distancia_mapping() -> None:
    assert g_distancia("muito_proxima") == 0.00
    assert g_distancia("razoavelmente_proxima") == 0.50
    assert g_distancia("distante") == 1.00


def test_g_distancia_unknown_raises() -> None:
    with pytest.raises(ValueError):
        g_distancia("longe")


# ---------------------------------------------------------------------------
# g_transporte
# ---------------------------------------------------------------------------

def test_g_transporte_present() -> None:
    assert g_transporte(["falta_transporte", "distancia"]) == 1.0


def test_g_transporte_absent() -> None:
    assert g_transporte(["sem_dificuldades"]) == 0.0
    assert g_transporte([]) == 0.0
    assert g_transporte(None) == 0.0


# ---------------------------------------------------------------------------
# g_organizacao (não soma)
# ---------------------------------------------------------------------------

def test_g_organizacao_multiple_barriers_still_one() -> None:
    assert g_organizacao(["dificuldade_agendamento", "demora_atendimento"]) == 1.0
    assert g_organizacao(["horario_incompativel"]) == 1.0


def test_g_organizacao_none() -> None:
    assert g_organizacao(["sem_dificuldades"]) == 0.0
    assert g_organizacao(["outro"]) == 0.0  # `outro` sozinho não conta
    assert g_organizacao([]) == 0.0


# ---------------------------------------------------------------------------
# g_trabalho
# ---------------------------------------------------------------------------

def test_g_trabalho_unemployed() -> None:
    assert g_trabalho(False, None) == 0.0


def test_g_trabalho_employed_no_prenatal() -> None:
    assert g_trabalho(True, False) == 1.0


def test_g_trabalho_employed_with_prenatal() -> None:
    assert g_trabalho(True, True) == 0.0


# ---------------------------------------------------------------------------
# g_privacao_alimentar
# ---------------------------------------------------------------------------

def test_g_privacao_alimentar() -> None:
    assert g_privacao_alimentar(True) == 1.0
    assert g_privacao_alimentar(False) == 0.0
    assert g_privacao_alimentar(None) == 0.0


# ---------------------------------------------------------------------------
# g_adensamento / crowding_ratio
# ---------------------------------------------------------------------------

def test_crowding_ratio() -> None:
    assert crowding_ratio(6, 2) == 3.0
    assert crowding_ratio(7, 2) == 3.5


def test_crowding_ratio_denominator_guard() -> None:
    with pytest.raises(ValueError):
        crowding_ratio(3, 0)


def test_g_adensamento_thresholds() -> None:
    assert g_adensamento(2.0) == 0.0  # <= 2
    assert g_adensamento(3.0) == 0.5  # > 2 e <= 3
    assert g_adensamento(3.5) == 1.0  # > 3
    assert g_adensamento(2.5) == 0.5


# ---------------------------------------------------------------------------
# compute_g_factors (integração dos fatores em um registro)
# ---------------------------------------------------------------------------

def test_compute_g_factors_interactions() -> None:
    from conftest import make_valid_record

    rec = make_valid_record()
    gf = compute_g_factors(rec, "ate_1_sm")
    # make_valid_record: faixa_renda=ate_1_sm (g_renda=1), deixou_de_comer=False
    assert gf["g_renda"] == 1.0
    assert gf["g_privacao_alimentar"] == 0.0
    assert gf["interaction_income_food"] == 0.0  # 1.0 * 0.0
    # distancia_ubs=muito_proxima (0), sem falta_transporte -> I2 = 0
    assert gf["interaction_distance_transport"] == 0.0


# ---------------------------------------------------------------------------
# Inputs do DGM (section 30)
# ---------------------------------------------------------------------------

def test_dgm_inputs_no_leakage() -> None:
    assert not set(DGM_INPUT_FIELDS) & set(constants.OUT_LEAKAGE)


def test_dgm_inputs_no_temporal() -> None:
    assert not set(DGM_INPUT_FIELDS) & set(constants.OUT_TEMPORAL)


def test_dgm_inputs_subset_of_x_model() -> None:
    assert set(DGM_INPUT_FIELDS) <= set(constants.X_MODEL)


def test_latent_income_not_an_observed_input() -> None:
    assert "latent_income_band" not in DGM_INPUT_FIELDS
