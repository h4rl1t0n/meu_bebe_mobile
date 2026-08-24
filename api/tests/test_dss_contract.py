"""Testes do contrato de dados DSS 1.13 (Pydantic v2, strict).

Cobrem: cardinalidade (48 variáveis), presença de chave, tipagem estrita
(bool/int), enums canônicos, múltipla escolha, null estrutural, exclusividade,
``extra = "forbid"``, invariantes de Habitação e a versão do schema.
"""

from __future__ import annotations

import pytest
from pydantic import ValidationError

from meu_bebe_api.contracts.dss import (
    DSS_SCHEMA_VERSION,
    AlimentacaoModel,
    DssPayload,
    EducacaoModel,
    HabitacaoModel,
    SaneamentoModel,
    SaudeModel,
    TrabalhoModel,
)
from conftest import make_valid_payload

_DIMENSION_MODELS = [
    EducacaoModel,
    TrabalhoModel,
    SaneamentoModel,
    SaudeModel,
    HabitacaoModel,
    AlimentacaoModel,
]

_EXPECTED_VARIABLES = frozenset(
    {
        # Educação (6)
        "estuda_atualmente",
        "escolaridade",
        "situacao_estudos_gestacao",
        "dificuldades_educacao",
        "entende_orientacoes_saude",
        "fez_curso_qualificacao_profissional",
        # Trabalho/Renda (10)
        "empregado",
        "tipo_emprego",
        "faixa_renda",
        "trabalho_permite_pre_natal",
        "ambiente_trabalho_seguro",
        "tem_pausas_descanso",
        "beneficios_trabalho",
        "motivo_desemprego",
        "recebe_beneficio_social",
        "impacto_gestacao_trabalho",
        # Saneamento (7)
        "fonte_agua",
        "interrupcoes_agua",
        "esgotamento_sanitario",
        "frequencia_coleta_lixo",
        "destino_lixo_sem_coleta",
        "problema_saude_agua",
        "cuidados_vetores",
        # Saúde/Acesso (9)
        "distancia_ubs",
        "faltou_consulta",
        "acesso_ubs",
        "cadastrada_ubs",
        "servicos_pre_natal",
        "exames_pre_natal_completos",
        "vacinas_em_dia",
        "avaliacao_pre_natal",
        "dificuldades_saude",
        # Habitação (9)
        "tipo_moradia",
        "material_moradia",
        "numero_pessoas",
        "numero_comodos",
        "numero_dormitorios",
        "itens_residencia",
        "seguranca_residencia",
        "melhorias_desejadas",
        "facil_acesso_saude",
        # Alimentação (7)
        "refeicoes_por_dia",
        "deixou_de_comer_falta_dinheiro",
        "alimentos_consumidos",
        "fonte_alimentos",
        "mudanca_alimentacao_gestacao",
        "usa_suplementos",
        "avaliacao_alimentacao",
    }
)


def _validate(payload: dict) -> DssPayload:
    return DssPayload.model_validate(payload)


# ---------------------------------------------------------------------------
# Cardinalidade e presença de chave
# ---------------------------------------------------------------------------


def test_exactly_48_variables():
    total = sum(len(m.model_fields) for m in _DIMENSION_MODELS)
    assert total == 48


def test_exact_variable_names_match_frozen_schema():
    names = {
        name
        for model in _DIMENSION_MODELS
        for name in model.model_fields
    }
    assert names == _EXPECTED_VARIABLES


def test_envelope_has_schema_version_and_six_sections():
    assert set(DssPayload.model_fields) == {
        "schema_version",
        "educacao",
        "trabalho",
        "saneamento",
        "saude",
        "habitacao",
        "alimentacao",
    }


def test_valid_payload_accepted():
    assert _validate(make_valid_payload()) is not None


@pytest.mark.parametrize("section", ["educacao", "trabalho", "saneamento", "saude", "habitacao", "alimentacao"])
def test_missing_section_rejected(section):
    payload = make_valid_payload()
    del payload[section]
    with pytest.raises(ValidationError):
        _validate(payload)


def test_missing_leaf_key_rejected():
    payload = make_valid_payload()
    del payload["educacao"]["escolaridade"]
    with pytest.raises(ValidationError):
        _validate(payload)


def test_missing_schema_version_rejected():
    payload = make_valid_payload()
    del payload["schema_version"]
    with pytest.raises(ValidationError):
        _validate(payload)


# ---------------------------------------------------------------------------
# Versão do schema
# ---------------------------------------------------------------------------


def test_schema_version_constant():
    assert DSS_SCHEMA_VERSION == "1.13"


def test_schema_version_wrong_value_rejected():
    payload = make_valid_payload()
    payload["schema_version"] = "1.12"
    with pytest.raises(ValidationError):
        _validate(payload)


# ---------------------------------------------------------------------------
# Tipagem estrita (bool / int)
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("bad", [1, 0, "true", "false", "yes"])
def test_strict_bool_rejects_non_bool(bad):
    payload = make_valid_payload()
    payload["educacao"]["estuda_atualmente"] = bad
    with pytest.raises(ValidationError):
        _validate(payload)


@pytest.mark.parametrize("bad", ["3", 3.0, True])
def test_strict_int_rejects_non_int(bad):
    payload = make_valid_payload()
    payload["habitacao"]["numero_pessoas"] = bad
    with pytest.raises(ValidationError):
        _validate(payload)


# ---------------------------------------------------------------------------
# Enums canônicos (código snake_case, nunca rótulo)
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "bad",
    ["Ensino Médio Completo", "medio completo", "MEDIO_COMPLETO", "xyz", ""],
)
def test_enum_rejects_label_and_unknown_code(bad):
    payload = make_valid_payload()
    payload["educacao"]["escolaridade"] = bad
    with pytest.raises(ValidationError):
        _validate(payload)


def test_enum_accepts_canonical_code():
    payload = make_valid_payload()
    payload["educacao"]["escolaridade"] = "medio_completo"
    assert _validate(payload).educacao.escolaridade == "medio_completo"


# ---------------------------------------------------------------------------
# Múltipla escolha (lista de códigos)
# ---------------------------------------------------------------------------


def test_multiselect_rejects_null():
    payload = make_valid_payload()
    payload["educacao"]["dificuldades_educacao"] = None
    with pytest.raises(ValidationError):
        _validate(payload)


def test_multiselect_rejects_unknown_code():
    payload = make_valid_payload()
    payload["educacao"]["dificuldades_educacao"] = ["distancia", "codigo_inventado"]
    with pytest.raises(ValidationError):
        _validate(payload)


def test_multiselect_accepts_empty_list():
    # [] = "não respondido" (distinto de null) — deve ser aceito.
    payload = make_valid_payload()
    payload["educacao"]["dificuldades_educacao"] = []
    assert _validate(payload).educacao.dificuldades_educacao == []


def test_beneficios_trabalho_is_nullable_list():
    # Desempregada -> benefícios é null estrutural (não aplicável).
    payload = make_valid_payload()
    payload["trabalho"]["empregado"] = False
    payload["trabalho"]["tipo_emprego"] = None
    payload["trabalho"]["beneficios_trabalho"] = None
    payload["trabalho"]["motivo_desemprego"] = "gestacao"
    assert _validate(payload).trabalho.beneficios_trabalho is None


# ---------------------------------------------------------------------------
# Null estrutural
# ---------------------------------------------------------------------------


def test_empregado_true_requires_tipo_emprego():
    payload = make_valid_payload()
    payload["trabalho"]["empregado"] = True
    payload["trabalho"]["tipo_emprego"] = None
    with pytest.raises(ValidationError):
        _validate(payload)


def test_empregado_true_requires_nonempty_beneficios():
    payload = make_valid_payload()
    payload["trabalho"]["empregado"] = True
    payload["trabalho"]["beneficios_trabalho"] = []
    with pytest.raises(ValidationError):
        _validate(payload)


def test_empregado_false_requires_motivo_desemprego():
    payload = make_valid_payload()
    payload["trabalho"]["empregado"] = False
    payload["trabalho"]["tipo_emprego"] = None
    payload["trabalho"]["beneficios_trabalho"] = None
    payload["trabalho"]["motivo_desemprego"] = None
    with pytest.raises(ValidationError):
        _validate(payload)


def test_empregado_null_no_structural_requirement():
    # "não respondido" -> campos condicionais podem ficar null sem erro.
    payload = make_valid_payload()
    payload["trabalho"]["empregado"] = None
    payload["trabalho"]["tipo_emprego"] = None
    payload["trabalho"]["beneficios_trabalho"] = None
    payload["trabalho"]["motivo_desemprego"] = None
    assert _validate(payload) is not None


def test_frequencia_lixo_nao_regular_requires_destino():
    payload = make_valid_payload()
    payload["saneamento"]["frequencia_coleta_lixo"] = "irregular"
    payload["saneamento"]["destino_lixo_sem_coleta"] = None
    with pytest.raises(ValidationError):
        _validate(payload)


def test_frequencia_lixo_regular_destino_null_ok():
    payload = make_valid_payload()
    payload["saneamento"]["frequencia_coleta_lixo"] = "regular"
    payload["saneamento"]["destino_lixo_sem_coleta"] = None
    assert _validate(payload) is not None


# ---------------------------------------------------------------------------
# Exclusividade
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("field", "exclusive"),
    [
        ("dificuldades_educacao", "sem_dificuldades"),
        ("servicos_pre_natal", "nenhum_dos_listados"),
        ("dificuldades_saude", "sem_dificuldades"),
        ("itens_residencia", "nenhum_dos_listados"),
        ("melhorias_desejadas", "sem_melhorias"),
        ("alimentos_consumidos", "nenhum_dos_listados"),
        ("cuidados_vetores", "sem_cuidados"),
    ],
)
def test_exclusive_code_alone_is_valid(field, exclusive):
    payload = make_valid_payload()
    section = {
        "dificuldades_educacao": "educacao",
        "servicos_pre_natal": "saude",
        "dificuldades_saude": "saude",
        "itens_residencia": "habitacao",
        "melhorias_desejadas": "habitacao",
        "alimentos_consumidos": "alimentacao",
        "cuidados_vetores": "saneamento",
    }[field]
    payload[section][field] = [exclusive]
    assert _validate(payload) is not None


@pytest.mark.parametrize(
    ("field", "exclusive"),
    [
        ("dificuldades_educacao", "sem_dificuldades"),
        ("servicos_pre_natal", "nenhum_dos_listados"),
        ("dificuldades_saude", "sem_dificuldades"),
        ("itens_residencia", "nenhum_dos_listados"),
        ("melhorias_desejadas", "sem_melhorias"),
        ("alimentos_consumidos", "nenhum_dos_listados"),
        ("cuidados_vetores", "sem_cuidados"),
    ],
)
def test_exclusive_code_combined_with_others_rejected(field, exclusive):
    payload = make_valid_payload()
    section = {
        "dificuldades_educacao": "educacao",
        "servicos_pre_natal": "saude",
        "dificuldades_saude": "saude",
        "itens_residencia": "habitacao",
        "melhorias_desejadas": "habitacao",
        "alimentos_consumidos": "alimentacao",
        "cuidados_vetores": "saneamento",
    }[field]
    payload[section][field] = [exclusive, "outro"]
    with pytest.raises(ValidationError):
        _validate(payload)


def test_beneficios_exclusive_rule():
    payload = make_valid_payload()
    payload["trabalho"]["beneficios_trabalho"] = ["sem_beneficios", "vale_transporte"]
    with pytest.raises(ValidationError):
        _validate(payload)


# ---------------------------------------------------------------------------
# extra = "forbid"
# ---------------------------------------------------------------------------


def test_extra_field_at_envelope_rejected():
    payload = make_valid_payload()
    payload["campo_extra"] = 1
    with pytest.raises(ValidationError):
        _validate(payload)


def test_extra_field_nested_rejected():
    payload = make_valid_payload()
    payload["educacao"]["campo_extra"] = 1
    with pytest.raises(ValidationError):
        _validate(payload)


# ---------------------------------------------------------------------------
# Invariantes de Habitação
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("bad", [0, -1])
def test_housing_counts_must_be_positive(bad):
    payload = make_valid_payload()
    payload["habitacao"]["numero_pessoas"] = bad
    with pytest.raises(ValidationError):
        _validate(payload)


def test_dormitorios_cannot_exceed_comodos():
    payload = make_valid_payload()
    payload["habitacao"]["numero_comodos"] = 2
    payload["habitacao"]["numero_dormitorios"] = 3
    with pytest.raises(ValidationError):
        _validate(payload)
