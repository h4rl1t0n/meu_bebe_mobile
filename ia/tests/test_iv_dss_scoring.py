"""Testes dos mapeamentos de score do IV-DSS (dimensões e subcomponentes).

Cobrem os mapeamentos congelados das seções 24–31 da FASE 3D (docs §8):
educação, renda, água, resíduos, saneamento, acesso, habitação e alimentação.
"""

from __future__ import annotations

import pytest

from meu_bebe_ml.iv_dss import (
    C_agua,
    C_barreiras,
    C_distancia,
    C_esgotamento,
    C_residuos,
    D_habitacao,
    ScoreStatus,
    barreira_disponibilidade,
    barreira_organizacao,
    barreira_transporte,
    crowding_ratio,
    score_agua_encanada,
    score_alimentacao,
    score_escolaridade,
    score_faixa_renda,
    score_habitacao_binary_from_ratio,
    score_habitacao_from_ratio,
)
from meu_bebe_ml.iv_dss.saneamento import D_saneamento_from
from meu_bebe_ml.iv_dss.types import analytically_indeterminate, valid


# ---------------------------------------------------------------------------
# 24. Educação
# ---------------------------------------------------------------------------

def test_educacao_full_mapping() -> None:
    expected = {
        "sem_instrucao": 1.00,
        "fundamental_incompleto": 0.83,
        "fundamental_completo": 0.67,
        "medio_incompleto": 0.50,
        "medio_completo": 0.33,
        "superior_incompleto": 0.17,
        "superior_completo": 0.00,
    }
    for cat, val in expected.items():
        assert score_escolaridade(cat).value == val


def test_educacao_unknown_indeterminate() -> None:
    r = score_escolaridade("doutorado")
    assert r.value is None
    assert r.status is ScoreStatus.ANALYTICALLY_INDETERMINATE


# ---------------------------------------------------------------------------
# 25. Renda
# ---------------------------------------------------------------------------

def test_renda_full_mapping() -> None:
    assert score_faixa_renda("ate_1_sm").value == 1.00
    assert score_faixa_renda("entre_1_2_sm").value == 0.67
    assert score_faixa_renda("entre_2_3_sm").value == 0.33
    assert score_faixa_renda("mais_3_sm").value == 0.00


def test_renda_nao_informar_is_missing() -> None:
    r = score_faixa_renda("nao_informar")
    assert r.value is None
    assert r.status is ScoreStatus.MISSING


# ---------------------------------------------------------------------------
# 26. Água
# ---------------------------------------------------------------------------

def test_C_agua_all_zero() -> None:
    rec = {
        "fonte_agua": "rede_publica",
        "itens_residencia": ["agua_encanada"],
        "interrupcoes_agua": False,
    }
    assert C_agua(rec).value == 0.0


def test_C_agua_all_one() -> None:
    rec = {
        "fonte_agua": "carro_pipa",
        "itens_residencia": ["nenhum_dos_listados"],
        "interrupcoes_agua": True,
    }
    assert C_agua(rec).value == 1.0


def test_C_agua_cisterna_two_valid() -> None:
    # fonte cisterna é indeterminada; água presente (0) + interrupções false (0) -> 0
    rec = {
        "fonte_agua": "cisterna",
        "itens_residencia": ["agua_encanada"],
        "interrupcoes_agua": False,
    }
    r = C_agua(rec)
    assert r.value == 0.0


def test_C_agua_outra_insufficient() -> None:
    # fonte 'outra' indeterminada + itens ausente (missing) + 1 válido -> None
    rec = {
        "fonte_agua": "outra",
        "itens_residencia": None,
        "interrupcoes_agua": False,
    }
    r = C_agua(rec)
    assert r.value is None
    assert not r.is_valid


# ---------------------------------------------------------------------------
# 27. Resíduos
# ---------------------------------------------------------------------------

def test_C_residuos_regular() -> None:
    rec = {"frequencia_coleta_lixo": "regular", "destino_lixo_sem_coleta": None}
    assert C_residuos(rec).value == 0.0


def test_C_residuos_irregular_aguarda() -> None:
    rec = {
        "frequencia_coleta_lixo": "irregular",
        "destino_lixo_sem_coleta": "aguarda_proxima_coleta",
    }
    assert C_residuos(rec).value == 0.25


def test_C_residuos_irregular_queima() -> None:
    rec = {"frequencia_coleta_lixo": "irregular", "destino_lixo_sem_coleta": "queima"}
    assert C_residuos(rec).value == 0.75


def test_C_residuos_nao_possui_queima() -> None:
    rec = {"frequencia_coleta_lixo": "nao_possui", "destino_lixo_sem_coleta": "queima"}
    assert C_residuos(rec).value == 1.0


def test_C_residuos_irregular_outro() -> None:
    rec = {"frequencia_coleta_lixo": "irregular", "destino_lixo_sem_coleta": "outro"}
    assert C_residuos(rec).value == 0.5


def test_C_residuos_nao_possui_outro() -> None:
    rec = {"frequencia_coleta_lixo": "nao_possui", "destino_lixo_sem_coleta": "outro"}
    assert C_residuos(rec).value == 1.0


# ---------------------------------------------------------------------------
# 28. Saneamento (agregação 3/2/1 válidos)
# ---------------------------------------------------------------------------

def test_saneamento_3_of_3() -> None:
    r = D_saneamento_from(valid(0.0), valid(0.5), valid(1.0))
    assert r.value == pytest.approx(0.5)


def test_saneamento_2_of_3() -> None:
    r = D_saneamento_from(valid(0.0), valid(0.5), analytically_indeterminate("x"))
    assert r.value == pytest.approx(0.25)


def test_saneamento_1_of_3() -> None:
    r = D_saneamento_from(
        valid(0.0), analytically_indeterminate("x"), analytically_indeterminate("y")
    )
    assert r.value is None
    assert not r.is_valid


# ---------------------------------------------------------------------------
# 29. Acesso
# ---------------------------------------------------------------------------

def test_C_distancia_mapping() -> None:
    assert C_distancia({"distancia_ubs": "muito_proxima"}).value == 0.0
    assert C_distancia({"distancia_ubs": "razoavelmente_proxima"}).value == 0.5
    assert C_distancia({"distancia_ubs": "distante"}).value == 1.0


def test_C_barreiras_sem_dificuldades() -> None:
    assert C_barreiras({"dificuldades_saude": ["sem_dificuldades"]}).value == 0.0


def test_barreira_transporte_present() -> None:
    assert barreira_transporte(["falta_transporte"]) == 1.0
    assert barreira_transporte(["sem_dificuldades"]) == 0.0


def test_barreira_organizacao_not_summed() -> None:
    # duas barreiras organizacionais -> domínio = 1, não 2
    assert barreira_organizacao(["dificuldade_agendamento", "demora_atendimento"]) == 1.0
    assert barreira_organizacao(["horario_incompativel"]) == 1.0
    assert barreira_organizacao(["sem_dificuldades"]) == 0.0


def test_barreira_disponibilidade() -> None:
    assert barreira_disponibilidade(["falta_profissional", "falta_exames"]) == 1.0
    assert barreira_disponibilidade(["sem_dificuldades"]) == 0.0


def test_C_barreiras_distancia_only() -> None:
    # distância é representada exclusivamente em C_distancia -> 0
    assert C_barreiras({"dificuldades_saude": ["distancia"]}).value == 0.0


def test_C_barreiras_outro_only() -> None:
    assert C_barreiras({"dificuldades_saude": ["outro"]}).value is None


def test_C_barreiras_distancia_outro() -> None:
    assert C_barreiras({"dificuldades_saude": ["distancia", "outro"]}).value is None


def test_C_barreiras_outro_plus_known() -> None:
    # 'outro' é ignorado; a barreira conhecida (transporte) é pontuada.
    r = C_barreiras({"dificuldades_saude": ["outro", "falta_transporte"]})
    assert r.value == pytest.approx(1 / 3)


# ---------------------------------------------------------------------------
# 30. Habitação
# ---------------------------------------------------------------------------

def test_crowding_ratio() -> None:
    assert crowding_ratio(4, 2) == 2.0
    assert crowding_ratio(5, 2) == 2.5
    assert crowding_ratio(6, 2) == 3.0
    assert crowding_ratio(7, 2) == 3.5


def test_habitacao_thresholds() -> None:
    assert score_habitacao_from_ratio(2.0).value == 0.0  # <= 2
    assert score_habitacao_from_ratio(2.5).value == 0.5  # > 2 e <= 3
    assert score_habitacao_from_ratio(3.0).value == 0.5  # == 3
    assert score_habitacao_from_ratio(3.5).value == 1.0  # > 3


def test_habitacao_from_record() -> None:
    rec = {"numero_pessoas": 4, "numero_dormitorios": 2}
    assert D_habitacao(rec).value == 0.0


def test_habitacao_binary_sensitivity() -> None:
    assert score_habitacao_binary_from_ratio(3.0).value == 0.0  # <= 3
    assert score_habitacao_binary_from_ratio(3.5).value == 1.0  # > 3


# ---------------------------------------------------------------------------
# 31. Alimentação
# ---------------------------------------------------------------------------

def test_alimentacao_mapping() -> None:
    assert score_alimentacao(False).value == 0.0
    assert score_alimentacao(True).value == 1.0
    assert score_alimentacao(None).value is None
    assert score_alimentacao(None).status is ScoreStatus.MISSING
