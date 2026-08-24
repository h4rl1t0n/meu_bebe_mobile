"""Testes unitários do adaptador ``DssPayload`` -> X_MODEL (34 features)."""

from __future__ import annotations

import pandas as pd

from conftest import make_dss_payload, make_valid_payload
from meu_bebe_api.ml.adapter import flatten_q_full, to_x_model_dataframe


def test_flatten_q_full_has_48_keys():
    flat = flatten_q_full(make_dss_payload())
    # 48 variáveis observadas (Q_FULL), sem a chave schema_version.
    assert len(flat) == 48
    assert "estuda_atualmente" in flat
    assert "avaliacao_alimentacao" in flat


def test_to_x_model_dataframe_shape_and_columns():
    df = to_x_model_dataframe(make_dss_payload())
    assert df.shape == (1, 34)
    # Ordem canônica: a primeira coluna é estuda_atualmente, a última avaliacao_alimentacao.
    assert list(df.columns)[0] == "estuda_atualmente"
    assert list(df.columns)[-1] == "avaliacao_alimentacao"


def test_to_x_model_dataframe_multiselect_stays_as_cell():
    df = to_x_model_dataframe(make_dss_payload())
    # Múltipla escolha deve permanecer como lista dentro da célula (object dtype),
    # exatamente como no treino (não pode virar várias linhas/colunas).
    cell = df.iloc[0]["dificuldades_educacao"]
    assert isinstance(cell, list)
    assert cell == ["distancia"]


def test_to_x_model_dataframe_preserves_values():
    payload = make_dss_payload()
    df = to_x_model_dataframe(payload)
    row = df.iloc[0]
    # pandas armazena bools como numpy bool_ (mesmo dtype do treino).
    assert row["estuda_atualmente"] == True  # noqa: E712
    assert row["escolaridade"] == "medio_completo"
    assert row["numero_pessoas"] == 3
    assert row["tipo_emprego"] == "clt"


def test_adapter_does_not_include_sensitivity_features():
    # X_MODEL (34) NÃO inclui as features de sensibilidade (problema_saude_agua,
    # facil_acesso_saude). O adaptador seleciona apenas X_MODEL.
    flat = flatten_q_full(make_dss_payload())
    assert "problema_saude_agua" in flat  # existe no Q_FULL...
    df = to_x_model_dataframe(make_dss_payload())
    assert "problema_saude_agua" not in list(df.columns)  # ...mas não vai para o modelo
    assert "facil_acesso_saude" not in list(df.columns)


def test_adapter_returns_pandas_dataframe():
    assert isinstance(to_x_model_dataframe(make_dss_payload()), pd.DataFrame)
