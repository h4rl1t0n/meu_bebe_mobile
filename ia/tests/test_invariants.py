"""Testes dos validadores e invariantes do schema DSS 1.13.

Cobrem: registro válido mínimo, chaves exatas, categorias inválidas, booleanos
inválidos, multiselects inválidos, exclusividades, condicionalidades de
`empregado` e `frequencia_coleta_lixo`, e regras numéricas da Habitação.
"""

from __future__ import annotations

import copy

from meu_bebe_ml.schema.validator import validate_record

from conftest import make_valid_record


def test_valid_record_passes() -> None:
    assert validate_record(make_valid_record()) == []


def test_invalid_when_unknown_category() -> None:
    record = make_valid_record()
    record["escolaridade"] = "doutorado"
    errors = validate_record(record)
    assert any("escolaridade" in e and "categoria" in e for e in errors)


def test_invalid_when_bool_receives_string() -> None:
    record = make_valid_record()
    record["estuda_atualmente"] = "sim"
    errors = validate_record(record)
    assert any("estuda_atualmente" in e for e in errors)


def test_invalid_when_bool_receives_int() -> None:
    record = make_valid_record()
    record["estuda_atualmente"] = 1
    errors = validate_record(record)
    assert any("estuda_atualmente" in e for e in errors)


def test_invalid_when_multiselect_not_list() -> None:
    record = make_valid_record()
    record["dificuldades_educacao"] = "falta_dinheiro"
    errors = validate_record(record)
    assert any("dificuldades_educacao" in e for e in errors)


def test_invalid_when_multiselect_has_unknown_code() -> None:
    record = make_valid_record()
    record["dificuldades_educacao"] = ["falta_dinheiro", "codigo_inventado"]
    errors = validate_record(record)
    assert any("dificuldades_educacao" in e and "codigo_inventado" in e for e in errors)


def test_invalid_when_exclusivity_violated() -> None:
    record = make_valid_record()
    record["dificuldades_educacao"] = ["sem_dificuldades", "falta_dinheiro"]
    errors = validate_record(record)
    assert any("sem_dificuldades" in e for e in errors)


def test_invalid_when_exclusivity_nenhum_dos_listados_violated() -> None:
    record = make_valid_record()
    record["alimentos_consumidos"] = ["nenhum_dos_listados", "feijao_leguminosas"]
    errors = validate_record(record)
    assert any("nenhum_dos_listados" in e for e in errors)


def test_valid_when_missing_key() -> None:
    record = make_valid_record()
    del record["escolaridade"]
    errors = validate_record(record)
    assert any("escolaridade" in e for e in errors)


def test_invalid_when_unknown_key() -> None:
    record = make_valid_record()
    record["campo_inexistente"] = 1
    errors = validate_record(record)
    assert any("campo_inexistente" in e for e in errors)


# ---------------------------------------------------------------------------
# Condicionalidades — empregado
# ---------------------------------------------------------------------------

def test_empregado_true_requires_tipo_emprego() -> None:
    record = make_valid_record()
    record["empregado"] = True
    record["tipo_emprego"] = None
    errors = validate_record(record)
    assert any("tipo_emprego" in e for e in errors)


def test_empregado_true_requires_beneficios_non_empty() -> None:
    record = make_valid_record()
    record["empregado"] = True
    record["beneficios_trabalho"] = []
    errors = validate_record(record)
    assert any("beneficios_trabalho" in e for e in errors)


def test_empregado_true_forbids_motivo_desemprego() -> None:
    record = make_valid_record()
    record["empregado"] = True
    record["motivo_desemprego"] = "gestacao"
    errors = validate_record(record)
    assert any("motivo_desemprego" in e for e in errors)


def test_empregado_false_requires_motivo_desemprego() -> None:
    record = make_valid_record()
    record["empregado"] = False
    record["tipo_emprego"] = None
    record["beneficios_trabalho"] = None
    record["motivo_desemprego"] = None
    errors = validate_record(record)
    assert any("motivo_desemprego" in e for e in errors)


def test_empregado_false_forbids_tipo_emprego() -> None:
    record = make_valid_record()
    record["empregado"] = False
    record["tipo_emprego"] = "clt"
    record["beneficios_trabalho"] = None
    record["motivo_desemprego"] = "gestacao"
    errors = validate_record(record)
    assert any("tipo_emprego" in e for e in errors)


def test_empregado_false_forbids_beneficios() -> None:
    record = make_valid_record()
    record["empregado"] = False
    record["tipo_emprego"] = None
    record["beneficios_trabalho"] = ["auxilio_maternidade"]
    record["motivo_desemprego"] = "gestacao"
    errors = validate_record(record)
    assert any("beneficios_trabalho" in e for e in errors)


# ---------------------------------------------------------------------------
# Condicionalidades — frequencia_coleta_lixo
# ---------------------------------------------------------------------------

def test_coleta_regular_forbids_destino() -> None:
    record = make_valid_record()
    record["frequencia_coleta_lixo"] = "regular"
    record["destino_lixo_sem_coleta"] = "queima"
    errors = validate_record(record)
    assert any("destino_lixo_sem_coleta" in e for e in errors)


def test_coleta_irregular_requires_destino() -> None:
    record = make_valid_record()
    record["frequencia_coleta_lixo"] = "irregular"
    record["destino_lixo_sem_coleta"] = None
    errors = validate_record(record)
    assert any("destino_lixo_sem_coleta" in e for e in errors)


def test_coleta_nao_possui_requires_destino() -> None:
    record = make_valid_record()
    record["frequencia_coleta_lixo"] = "nao_possui"
    record["destino_lixo_sem_coleta"] = None
    errors = validate_record(record)
    assert any("destino_lixo_sem_coleta" in e for e in errors)


def test_coleta_nao_possui_forbids_aguarda_proxima_coleta() -> None:
    record = make_valid_record()
    record["frequencia_coleta_lixo"] = "nao_possui"
    record["destino_lixo_sem_coleta"] = "aguarda_proxima_coleta"
    errors = validate_record(record)
    assert any("aguarda_proxima_coleta" in e for e in errors)


def test_coleta_irregular_allows_aguarda_proxima_coleta() -> None:
    record = make_valid_record()
    record["frequencia_coleta_lixo"] = "irregular"
    record["destino_lixo_sem_coleta"] = "aguarda_proxima_coleta"
    # `aguarda_proxima_coleta` é válida em `irregular`; o restante do registro
    # continua válido.
    assert validate_record(record) == []


# ---------------------------------------------------------------------------
# Regras numéricas — Habitação
# ---------------------------------------------------------------------------

def test_numero_pessoas_less_than_one() -> None:
    record = make_valid_record()
    record["numero_pessoas"] = 0
    errors = validate_record(record)
    assert any("numero_pessoas" in e for e in errors)


def test_numero_comodos_less_than_one() -> None:
    record = make_valid_record()
    record["numero_comodos"] = -1
    errors = validate_record(record)
    assert any("numero_comodos" in e for e in errors)


def test_numero_dormitorios_less_than_one() -> None:
    record = make_valid_record()
    record["numero_dormitorios"] = 0
    errors = validate_record(record)
    assert any("numero_dormitorios" in e for e in errors)


def test_dormitorios_greater_than_comodos() -> None:
    record = make_valid_record()
    record["numero_comodos"] = 2
    record["numero_dormitorios"] = 3
    errors = validate_record(record)
    assert any("numero_dormitorios" in e for e in errors)


def test_numero_fields_must_be_int() -> None:
    record = make_valid_record()
    record["numero_pessoas"] = "3"
    errors = validate_record(record)
    assert any("numero_pessoas" in e for e in errors)


# ---------------------------------------------------------------------------
# Obrigatoriedade
# ---------------------------------------------------------------------------

def test_required_multiselect_cannot_be_empty() -> None:
    record = make_valid_record()
    record["cuidados_vetores"] = []
    errors = validate_record(record)
    assert any("cuidados_vetores" in e for e in errors)


def test_required_bool_cannot_be_null() -> None:
    record = make_valid_record()
    record["estuda_atualmente"] = None
    errors = validate_record(record)
    assert any("estuda_atualmente" in e for e in errors)


def test_mutating_record_does_not_affect_original() -> None:
    original = make_valid_record()
    mutated = copy.deepcopy(original)
    mutated["escolaridade"] = "invalido"
    assert validate_record(original) == []
    assert any("escolaridade" in e for e in validate_record(mutated))


# ---------------------------------------------------------------------------
# Booleanos opcionais (leakage): null permitido, chave obrigatória
# ---------------------------------------------------------------------------

def test_optional_leakage_bool_null_is_valid() -> None:
    for field in ("faltou_consulta", "exames_pre_natal_completos", "vacinas_em_dia"):
        record = make_valid_record()
        record[field] = None
        assert validate_record(record) == [], field


def test_optional_leakage_bool_missing_key_is_invalid() -> None:
    for field in ("faltou_consulta", "exames_pre_natal_completos", "vacinas_em_dia"):
        record = make_valid_record()
        del record[field]
        errors = validate_record(record)
        assert any(field in e for e in errors), field


# ---------------------------------------------------------------------------
# beneficios_trabalho — contrato null vs sem_beneficios
# ---------------------------------------------------------------------------

def _unemployed_record() -> dict:
    record = make_valid_record()
    record["empregado"] = False
    record["tipo_emprego"] = None
    record["trabalho_permite_pre_natal"] = None
    record["ambiente_trabalho_seguro"] = None
    record["tem_pausas_descanso"] = None
    record["motivo_desemprego"] = "gestacao"
    return record


def test_empregado_false_beneficios_null_valid() -> None:
    record = _unemployed_record()
    record["beneficios_trabalho"] = None
    assert validate_record(record) == []


def test_empregado_false_beneficios_empty_list_invalid() -> None:
    record = _unemployed_record()
    record["beneficios_trabalho"] = []
    errors = validate_record(record)
    assert any("beneficios_trabalho" in e for e in errors)


def test_empregado_false_beneficios_sem_beneficios_invalid() -> None:
    record = _unemployed_record()
    record["beneficios_trabalho"] = ["sem_beneficios"]
    errors = validate_record(record)
    assert any("beneficios_trabalho" in e for e in errors)


def test_empregado_true_beneficios_sem_beneficios_valid() -> None:
    record = make_valid_record()  # empregado == true, tipo_emprego == clt
    record["beneficios_trabalho"] = ["sem_beneficios"]
    assert validate_record(record) == []
