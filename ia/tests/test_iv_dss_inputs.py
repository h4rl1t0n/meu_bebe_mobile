"""Testes de escopo e anti-dupla-contagem do IV-DSS (seções 22–23).

Garantem que o IV-DSS:

* usa apenas os campos necessários de ``Q_full`` (``IV_DSS_INPUT_FIELDS``);
* não lê ``Y``, ``p_true``, ``eta``, ``g_*``, ``Z_*``, ``C_*`` nem
  ``latent_income_band``;
* não usa nenhuma variável ``OUT_LEAKAGE``;
* não pontua ``agua_encanada`` duas vezes (saneamento x habitação);
* não pontua ``distancia`` (de ``dificuldades_saude``) em ``C_barreiras``.
"""

from __future__ import annotations

import pytest

from meu_bebe_ml.iv_dss import (
    IV_DSS_INPUT_FIELDS,
    C_barreiras,
    D_habitacao,
    score_agua_encanada,
)
from meu_bebe_ml.schema import constants
from meu_bebe_ml.simulation import (
    CONTEXT_NAMES,
    G_FACTOR_NAMES,
    INTERACTION_NAMES,
    LATENT_NAMES,
)


# ---------------------------------------------------------------------------
# 23. IV_DSS_INPUT_FIELDS
# ---------------------------------------------------------------------------

def test_input_fields_no_leakage() -> None:
    assert not set(IV_DSS_INPUT_FIELDS) & set(constants.OUT_LEAKAGE)


def test_input_fields_subset_of_q_full() -> None:
    assert set(IV_DSS_INPUT_FIELDS) <= set(constants.Q_FULL)


def test_input_fields_all_in_x_model() -> None:
    # todos os inputs do IV-DSS são metodologicamente IN (X_MODEL).
    assert set(IV_DSS_INPUT_FIELDS) <= set(constants.X_MODEL)


def test_input_fields_no_forbidden() -> None:
    forbidden = {
        "Y",
        "descontinuou_pre_natal",
        "latent_income_band",
        "income_was_masked",
        "eta",
        "p_true",
        "U",
        "linear_component",
        "alpha",
    }
    forbidden |= set(LATENT_NAMES)  # Z_*
    forbidden |= set(CONTEXT_NAMES)  # C_*
    forbidden |= set(G_FACTOR_NAMES)  # g_*
    forbidden |= set(INTERACTION_NAMES)  # interações
    assert not set(IV_DSS_INPUT_FIELDS) & forbidden


# ---------------------------------------------------------------------------
# 22. Anti-dupla-contagem
# ---------------------------------------------------------------------------

def test_agua_encanada_in_sanitation_not_housing() -> None:
    # água encanada é lida de itens_residencia e pontuada em Saneamento.
    assert score_agua_encanada(["agua_encanada"]).value == 0.0
    assert score_agua_encanada(["banheiro_interno"]).value == 1.0

    # Habitação NÃO lê itens_residencia: mudar o item não altera D_habitacao.
    base = {"numero_pessoas": 4, "numero_dormitorios": 2}
    assert D_habitacao(base).value == D_habitacao({**base, "itens_residencia": ["agua_encanada"]}).value
    assert D_habitacao(base).value == D_habitacao({**base, "itens_residencia": ["banheiro_interno"]}).value


def test_distancia_ubs_enters_once() -> None:
    # distancia_ubs aparece exatamente uma vez nos inputs (somente em C_distancia).
    assert IV_DSS_INPUT_FIELDS.count("distancia_ubs") == 1


def test_distancia_item_not_in_barreiras() -> None:
    # `distancia` (item de dificuldades_saude) não é pontuado em C_barreiras.
    assert C_barreiras({"dificuldades_saude": ["distancia"]}).value == 0.0
    # com transporte presente, somente transporte é pontuado (distância ignorada).
    r = C_barreiras({"dificuldades_saude": ["distancia", "falta_transporte"]})
    assert r.value == pytest.approx(1 / 3)
