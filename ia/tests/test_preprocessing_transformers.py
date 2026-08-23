"""Testes dos transformers do preprocessing v1 (seções 20–23).

Cobrem booleanos obrigatórios/estruturais, ordinais (com ordem congelada),
one-hot nominal (``nao_informar``, null estrutural, categoria ausente do fit),
e multi-hot multiselect (null estrutural, código desconhecido, lista vazia).
"""

from __future__ import annotations

import numpy as np
import pandas as pd
import pytest

from meu_bebe_ml.preprocessing.transformers import (
    BooleanRequiredEncoder,
    MultiSelectBinarizerTransformer,
    NominalOneHotEncoder,
    OrdinalFeatureEncoder,
    StructuralBooleanEncoder,
)

TOKEN = "__not_applicable__"


def _df(**cols) -> pd.DataFrame:
    return pd.DataFrame(cols)


# ---------------------------------------------------------------------------
# 20. Booleanos obrigatórios
# ---------------------------------------------------------------------------

def test_boolean_required_true_false() -> None:
    enc = BooleanRequiredEncoder(fields=["empregado", "cadastrada_ubs"])
    out = enc.fit_transform(_df(empregado=[True], cadastrada_ubs=[False]))
    assert out.tolist() == [[1.0, 0.0]]
    assert list(enc.get_feature_names_out()) == ["empregado", "cadastrada_ubs"]


def test_boolean_required_null_raises() -> None:
    enc = BooleanRequiredEncoder(fields=["empregado"])
    enc.fit(_df(empregado=[True]))
    with pytest.raises(ValueError):
        enc.transform(_df(empregado=[None]))


# ---------------------------------------------------------------------------
# 20. Booleanos estruturais
# ---------------------------------------------------------------------------

def test_structural_bool_true_false_null() -> None:
    enc = StructuralBooleanEncoder(fields=["trabalho_permite_pre_natal"])
    df = _df(
        trabalho_permite_pre_natal=[True, False, None],
    )
    out = enc.fit_transform(df)
    assert out.tolist() == [
        [1.0, 0.0],  # true
        [0.0, 0.0],  # false
        [0.0, 1.0],  # null
    ]
    assert list(enc.get_feature_names_out()) == [
        "trabalho_permite_pre_natal__value",
        "trabalho_permite_pre_natal__not_applicable",
    ]


# ---------------------------------------------------------------------------
# 21. Ordinais
# ---------------------------------------------------------------------------

ESCOLARIDADE_ORDER = [
    "sem_instrucao",
    "fundamental_incompleto",
    "fundamental_completo",
    "medio_incompleto",
    "medio_completo",
    "superior_incompleto",
    "superior_completo",
]


def test_ordinal_escolaridade_bounds() -> None:
    enc = OrdinalFeatureEncoder(
        fields=["escolaridade"], orders={"escolaridade": ESCOLARIDADE_ORDER}
    )
    df = _df(escolaridade=["sem_instrucao", "superior_completo", "medio_completo"])
    out = enc.fit_transform(df)
    assert out[:, 0].tolist() == [0.0, 6.0, 4.0]
    assert list(enc.get_feature_names_out()) == ["escolaridade"]


def test_ordinal_distancia_and_refeicoes() -> None:
    enc = OrdinalFeatureEncoder(
        fields=["distancia_ubs", "refeicoes_por_dia"],
        orders={
            "distancia_ubs": ["muito_proxima", "razoavelmente_proxima", "distante"],
            "refeicoes_por_dia": ["uma_duas", "tres", "quatro_mais"],
        },
    )
    df = _df(
        distancia_ubs=["muito_proxima", "distante"],
        refeicoes_por_dia=["uma_duas", "quatro_mais"],
    )
    out = enc.fit_transform(df)
    assert out.tolist() == [[0.0, 0.0], [2.0, 2.0]]


def test_ordinal_unknown_category_raises() -> None:
    enc = OrdinalFeatureEncoder(
        fields=["escolaridade"], orders={"escolaridade": ESCOLARIDADE_ORDER}
    )
    enc.fit(_df(escolaridade=["sem_instrucao"]))
    with pytest.raises(ValueError):
        enc.transform(_df(escolaridade=["doutorado"]))


def test_ordinal_null_raises() -> None:
    enc = OrdinalFeatureEncoder(
        fields=["escolaridade"], orders={"escolaridade": ESCOLARIDADE_ORDER}
    )
    enc.fit(_df(escolaridade=["sem_instrucao"]))
    with pytest.raises(ValueError):
        enc.transform(_df(escolaridade=[None]))


# ---------------------------------------------------------------------------
# 22. One-hot nominal
# ---------------------------------------------------------------------------

def test_onehot_faixa_renda_nao_informar_own_column() -> None:
    enc = NominalOneHotEncoder(
        fields=["faixa_renda"],
        categories={
            "faixa_renda": [
                "ate_1_sm",
                "entre_1_2_sm",
                "entre_2_3_sm",
                "mais_3_sm",
                "nao_informar",
            ]
        },
        structural_null_fields=[],
        not_applicable_token=TOKEN,
    )
    df = _df(faixa_renda=["nao_informar"])
    out = enc.fit_transform(df)
    names = list(enc.get_feature_names_out())
    assert names.index("faixa_renda__nao_informar") == 4
    assert out[0, 4] == 1.0
    assert out[0, :4].sum() == 0.0
    # exatamente uma categoria ativa
    assert out[0].sum() == 1.0


def test_onehot_exactly_one_active_per_row() -> None:
    enc = NominalOneHotEncoder(
        fields=["acesso_ubs"],
        categories={"acesso_ubs": ["a_pe", "transporte_publico", "carro_moto", "outro"]},
        structural_null_fields=[],
        not_applicable_token=TOKEN,
    )
    df = _df(acesso_ubs=["a_pe", "carro_moto", "outro"])
    out = enc.fit_transform(df)
    assert out.sum(axis=1).tolist() == [1.0, 1.0, 1.0]


def test_onehot_tipo_emprego_null_structural() -> None:
    enc = NominalOneHotEncoder(
        fields=["tipo_emprego"],
        categories={"tipo_emprego": ["clt", "autonomo", "informal", TOKEN]},
        structural_null_fields=["tipo_emprego"],
        not_applicable_token=TOKEN,
    )
    df = _df(tipo_emprego=[None])
    out = enc.fit_transform(df)
    names = list(enc.get_feature_names_out())
    assert "tipo_emprego__not_applicable" in names
    assert out[0, names.index("tipo_emprego__not_applicable")] == 1.0
    assert out[0].sum() == 1.0


def test_onehot_unknown_category_raises() -> None:
    enc = NominalOneHotEncoder(
        fields=["tipo_moradia"],
        categories={"tipo_moradia": ["casa", "apartamento", "comodo_unico", "outro"]},
        structural_null_fields=[],
        not_applicable_token=TOKEN,
    )
    enc.fit(_df(tipo_moradia=["casa"]))
    with pytest.raises(ValueError):
        enc.transform(_df(tipo_moradia=["mansao"]))


def test_onehot_category_absent_from_fit_still_transformable() -> None:
    # vocabulário vem do schema, NÃO do fit.
    enc = NominalOneHotEncoder(
        fields=["tipo_emprego"],
        categories={"tipo_emprego": ["clt", "autonomo", "informal", TOKEN]},
        structural_null_fields=["tipo_emprego"],
        not_applicable_token=TOKEN,
    )
    enc.fit(_df(tipo_emprego=["clt"]))  # 'informal' ausente no fit
    out = enc.transform(_df(tipo_emprego=["informal"]))
    names = list(enc.get_feature_names_out())
    assert out[0, names.index("tipo_emprego__informal")] == 1.0


# ---------------------------------------------------------------------------
# 23. Multi-hot multiselect
# ---------------------------------------------------------------------------

DIFIC_EDU = [
    "falta_dinheiro",
    "distancia",
    "falta_transporte",
    "falta_vagas",
    "gravidez",
    "trabalho",
    "cuidado_filhos",
    "sem_dificuldades",
    "outro",
]

BENEFICIOS = ["auxilio_maternidade", "vale_transporte", "vale_alimentacao", "sem_beneficios"]


def _ms_encoder(fields, categories, structural=()) -> MultiSelectBinarizerTransformer:
    return MultiSelectBinarizerTransformer(
        fields=fields,
        categories=categories,
        structural_null_fields=list(structural),
        not_applicable_token=TOKEN,
    )


def test_multihot_two_codes() -> None:
    enc = _ms_encoder(["dificuldades_educacao"], {"dificuldades_educacao": DIFIC_EDU})
    df = _df(dificuldades_educacao=[["falta_dinheiro", "distancia"]])
    out = enc.fit_transform(df)
    names = list(enc.get_feature_names_out())
    assert out[0, names.index("dificuldades_educacao__falta_dinheiro")] == 1.0
    assert out[0, names.index("dificuldades_educacao__distancia")] == 1.0
    assert out[0].sum() == 2.0


def test_multihot_sem_dificuldades_only() -> None:
    enc = _ms_encoder(["dificuldades_educacao"], {"dificuldades_educacao": DIFIC_EDU})
    df = _df(dificuldades_educacao=[["sem_dificuldades"]])
    out = enc.fit_transform(df)
    names = list(enc.get_feature_names_out())
    assert out[0, names.index("dificuldades_educacao__sem_dificuldades")] == 1.0
    assert out[0].sum() == 1.0


def test_multihot_beneficios_null_structural() -> None:
    enc = _ms_encoder(
        ["beneficios_trabalho"],
        {"beneficios_trabalho": BENEFICIOS + [TOKEN]},
        structural=["beneficios_trabalho"],
    )
    df = _df(beneficios_trabalho=[None])
    out = enc.fit_transform(df)
    names = list(enc.get_feature_names_out())
    assert out[0, names.index("beneficios_trabalho__not_applicable")] == 1.0
    # todas as categorias normais = 0
    for cat in BENEFICIOS:
        assert out[0, names.index(f"beneficios_trabalho__{cat}")] == 0.0


def test_multihot_beneficios_sem_beneficios() -> None:
    enc = _ms_encoder(
        ["beneficios_trabalho"],
        {"beneficios_trabalho": BENEFICIOS + [TOKEN]},
        structural=["beneficios_trabalho"],
    )
    df = _df(beneficios_trabalho=[["sem_beneficios"]])
    out = enc.fit_transform(df)
    names = list(enc.get_feature_names_out())
    assert out[0, names.index("beneficios_trabalho__sem_beneficios")] == 1.0
    assert out[0, names.index("beneficios_trabalho__not_applicable")] == 0.0


def test_multihot_unknown_code_raises() -> None:
    enc = _ms_encoder(["itens_residencia"], {"itens_residencia": ["agua_encanada", "banheiro_interno", "cozinha_separada", "nenhum_dos_listados"]})
    enc.fit(_df(itens_residencia=[["agua_encanada"]]))
    with pytest.raises(ValueError):
        enc.transform(_df(itens_residencia=[["piscina"]]))


def test_multihot_empty_list_raises() -> None:
    enc = _ms_encoder(["fonte_alimentos"], {"fonte_alimentos": ["supermercado_feira", "horta_propria", "doacoes", "cesta_basica", "outro"]})
    enc.fit(_df(fonte_alimentos=[["doacoes"]]))
    with pytest.raises(ValueError):
        enc.transform(_df(fonte_alimentos=[[]]))


def test_multihot_null_non_structural_raises() -> None:
    enc = _ms_encoder(["dificuldades_saude"], {"dificuldades_saude": ["sem_dificuldades", "outro"]})
    enc.fit(_df(dificuldades_saude=[["sem_dificuldades"]]))
    with pytest.raises(ValueError):
        enc.transform(_df(dificuldades_saude=[None]))
