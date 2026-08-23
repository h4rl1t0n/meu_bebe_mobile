"""Constantes congeladas do contrato de dados DSS 1.13.

Este módulo é a fonte de verdade *em código* dos conjuntos de variáveis e da
classificação metodológica (ML-IN / OUT-LEAKAGE / OUT-TEMPORAL / DESCRIPTIVE /
SENSITIVITY). O arquivo ``configs/schema_v1_13.yaml`` espelha o mesmo contrato
com a especificação detalhada (tipos, categorias, condicionalidades,
exclusividades); os testes de ``test_schema.py`` garantem que ambos permanecem
consistentes.

Nada aqui gera dados nem realiza transformações estatísticas: apenas declara
nomes e classificações.
"""

from __future__ import annotations

# ---------------------------------------------------------------------------
# Versão do contrato
# ---------------------------------------------------------------------------

SCHEMA_VERSION: str = "1.13"

# ---------------------------------------------------------------------------
# Dimensões (ordem canônica do dicionário de variáveis)
# ---------------------------------------------------------------------------

DIMENSIONS: tuple[str, ...] = (
    "educacao",
    "trabalho_renda",
    "saneamento",
    "saude",
    "habitacao",
    "alimentacao",
)

# ---------------------------------------------------------------------------
# Conjuntos de variáveis (chaves JSON canônicas)
# ---------------------------------------------------------------------------

# X_MODEL — as 34 features ML-IN admissíveis no experimento.
X_MODEL: tuple[str, ...] = (
    # Educação (5)
    "estuda_atualmente",
    "escolaridade",
    "dificuldades_educacao",
    "entende_orientacoes_saude",
    "fez_curso_qualificacao_profissional",
    # Trabalho e Renda (8)
    "empregado",
    "tipo_emprego",
    "faixa_renda",
    "trabalho_permite_pre_natal",
    "ambiente_trabalho_seguro",
    "tem_pausas_descanso",
    "beneficios_trabalho",
    "recebe_beneficio_social",
    # Saneamento (5)
    "fonte_agua",
    "interrupcoes_agua",
    "esgotamento_sanitario",
    "frequencia_coleta_lixo",
    "destino_lixo_sem_coleta",
    # Saúde/Acesso (4)
    "distancia_ubs",
    "acesso_ubs",
    "cadastrada_ubs",
    "dificuldades_saude",
    # Habitação (7)
    "tipo_moradia",
    "material_moradia",
    "numero_pessoas",
    "numero_comodos",
    "numero_dormitorios",
    "itens_residencia",
    "seguranca_residencia",
    # Alimentação (5)
    "refeicoes_por_dia",
    "deixou_de_comer_falta_dinheiro",
    "alimentos_consumidos",
    "fonte_alimentos",
    "avaliacao_alimentacao",
)

# OUT_LEAKAGE — proximidade com acompanhamento/desfecho (5).
OUT_LEAKAGE: tuple[str, ...] = (
    "faltou_consulta",
    "servicos_pre_natal",
    "exames_pre_natal_completos",
    "vacinas_em_dia",
    "avaliacao_pre_natal",
)

# OUT_TEMPORAL — mistura antecedente com acontecimento durante a gestação (5).
OUT_TEMPORAL: tuple[str, ...] = (
    "situacao_estudos_gestacao",
    "motivo_desemprego",
    "impacto_gestacao_trabalho",
    "mudanca_alimentacao_gestacao",
    "usa_suplementos",
)

# DESCRIPTIVE — caracterização, sem justificativa p/ feature principal (2).
DESCRIPTIVE: tuple[str, ...] = (
    "cuidados_vetores",
    "melhorias_desejadas",
)

# SENSITIVITY — fora do modelo principal; comparação 34 vs 36 (2).
SENSITIVITY: tuple[str, ...] = (
    "problema_saude_agua",
    "facil_acesso_saude",
)

# Q_FULL — conjunto completo das 48 variáveis observadas do questionário.
Q_FULL: tuple[str, ...] = (
    X_MODEL + OUT_LEAKAGE + OUT_TEMPORAL + DESCRIPTIVE + SENSITIVITY
)

# X_SENS — 34 ML-IN + 2 SENSIBILIDADE (36), usado só no experimento 34 vs 36.
X_SENS: tuple[str, ...] = X_MODEL + SENSITIVITY

# ---------------------------------------------------------------------------
# Mapas auxiliares (derivados dos conjuntos acima)
# ---------------------------------------------------------------------------

_VARIABLE_TO_CLASS: dict[str, str] = {}
for _name in X_MODEL:
    _VARIABLE_TO_CLASS[_name] = "IN"
for _name in OUT_LEAKAGE:
    _VARIABLE_TO_CLASS[_name] = "OUT_LEAKAGE"
for _name in OUT_TEMPORAL:
    _VARIABLE_TO_CLASS[_name] = "OUT_TEMPORAL"
for _name in DESCRIPTIVE:
    _VARIABLE_TO_CLASS[_name] = "DESCRIPTIVE"
for _name in SENSITIVITY:
    _VARIABLE_TO_CLASS[_name] = "SENSITIVITY"

# Nome da variável -> dimensão à qual pertence.
VARIABLE_TO_DIMENSION: dict[str, str] = {
    # Educação
    "estuda_atualmente": "educacao",
    "escolaridade": "educacao",
    "situacao_estudos_gestacao": "educacao",
    "dificuldades_educacao": "educacao",
    "entende_orientacoes_saude": "educacao",
    "fez_curso_qualificacao_profissional": "educacao",
    # Trabalho e Renda
    "empregado": "trabalho_renda",
    "tipo_emprego": "trabalho_renda",
    "faixa_renda": "trabalho_renda",
    "trabalho_permite_pre_natal": "trabalho_renda",
    "ambiente_trabalho_seguro": "trabalho_renda",
    "tem_pausas_descanso": "trabalho_renda",
    "beneficios_trabalho": "trabalho_renda",
    "motivo_desemprego": "trabalho_renda",
    "recebe_beneficio_social": "trabalho_renda",
    "impacto_gestacao_trabalho": "trabalho_renda",
    # Saneamento
    "fonte_agua": "saneamento",
    "interrupcoes_agua": "saneamento",
    "esgotamento_sanitario": "saneamento",
    "frequencia_coleta_lixo": "saneamento",
    "destino_lixo_sem_coleta": "saneamento",
    "problema_saude_agua": "saneamento",
    "cuidados_vetores": "saneamento",
    # Saúde
    "distancia_ubs": "saude",
    "faltou_consulta": "saude",
    "acesso_ubs": "saude",
    "cadastrada_ubs": "saude",
    "servicos_pre_natal": "saude",
    "exames_pre_natal_completos": "saude",
    "vacinas_em_dia": "saude",
    "avaliacao_pre_natal": "saude",
    "dificuldades_saude": "saude",
    # Habitação
    "tipo_moradia": "habitacao",
    "material_moradia": "habitacao",
    "numero_pessoas": "habitacao",
    "numero_comodos": "habitacao",
    "numero_dormitorios": "habitacao",
    "itens_residencia": "habitacao",
    "seguranca_residencia": "habitacao",
    "melhorias_desejadas": "habitacao",
    "facil_acesso_saude": "habitacao",
    # Alimentação
    "refeicoes_por_dia": "alimentacao",
    "deixou_de_comer_falta_dinheiro": "alimentacao",
    "alimentos_consumidos": "alimentacao",
    "fonte_alimentos": "alimentacao",
    "mudanca_alimentacao_gestacao": "alimentacao",
    "usa_suplementos": "alimentacao",
    "avaliacao_alimentacao": "alimentacao",
}


def ml_class_of(name: str) -> str:
    """Retorna a classe metodológica de uma variável (ex.: ``"IN"``)."""
    if name not in _VARIABLE_TO_CLASS:
        raise KeyError(f"variável desconhecida: {name!r}")
    return _VARIABLE_TO_CLASS[name]


def dimension_of(name: str) -> str:
    """Retorna a dimensão de uma variável (ex.: ``"educacao"``)."""
    if name not in VARIABLE_TO_DIMENSION:
        raise KeyError(f"variável desconhecida: {name!r}")
    return VARIABLE_TO_DIMENSION[name]
