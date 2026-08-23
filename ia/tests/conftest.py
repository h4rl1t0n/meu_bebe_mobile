"""Fixtures compartilhadas dos testes do pacote ``meu_bebe_ml``.

Fornece um registro DSS 1.13 válido (as 48 chaves de ``Q_FULL``) para os testes
de invariantes e de seleção de campos.
"""

from __future__ import annotations

import copy

import pytest


def make_valid_record() -> dict:
    """Retorna um registro DSS 1.13 completo e válido.

    Cenário: gestante empregada (``empregado == true``) com coleta de lixo
    regular (``frequencia_coleta_lixo == regular``). Todos os campos obrigatórios
    preenchidos e condicionalidades respeitadas.
    """
    return {
        # Educação (6)
        "estuda_atualmente": True,
        "escolaridade": "medio_completo",
        "situacao_estudos_gestacao": "nao_estudava",
        "dificuldades_educacao": ["sem_dificuldades"],
        "entende_orientacoes_saude": True,
        "fez_curso_qualificacao_profissional": False,
        # Trabalho e Renda (10)
        "empregado": True,
        "tipo_emprego": "clt",
        "faixa_renda": "ate_1_sm",
        "trabalho_permite_pre_natal": True,
        "ambiente_trabalho_seguro": True,
        "tem_pausas_descanso": True,
        "beneficios_trabalho": ["auxilio_maternidade"],
        "motivo_desemprego": None,
        "recebe_beneficio_social": True,
        "impacto_gestacao_trabalho": "nao_afetou",
        # Saneamento (7)
        "fonte_agua": "rede_publica",
        "interrupcoes_agua": False,
        "esgotamento_sanitario": "rede_coletora",
        "frequencia_coleta_lixo": "regular",
        "destino_lixo_sem_coleta": None,
        "problema_saude_agua": False,
        "cuidados_vetores": ["elimina_agua_parada"],
        # Saúde (9)
        "distancia_ubs": "muito_proxima",
        "faltou_consulta": False,
        "acesso_ubs": "a_pe",
        "cadastrada_ubs": True,
        "servicos_pre_natal": ["consulta_medica"],
        "exames_pre_natal_completos": True,
        "vacinas_em_dia": True,
        "avaliacao_pre_natal": "bom",
        "dificuldades_saude": ["sem_dificuldades"],
        # Habitação (9)
        "tipo_moradia": "casa",
        "material_moradia": "alvenaria",
        "numero_pessoas": 3,
        "numero_comodos": 5,
        "numero_dormitorios": 2,
        "itens_residencia": ["agua_encanada", "banheiro_interno"],
        "seguranca_residencia": "segura",
        "melhorias_desejadas": ["sem_melhorias"],
        "facil_acesso_saude": True,
        # Alimentação (7)
        "refeicoes_por_dia": "tres",
        "deixou_de_comer_falta_dinheiro": False,
        "alimentos_consumidos": ["feijao_leguminosas", "frutas_verduras"],
        "fonte_alimentos": ["supermercado_feira"],
        "mudanca_alimentacao_gestacao": False,
        "usa_suplementos": True,
        "avaliacao_alimentacao": "boa",
    }


@pytest.fixture
def valid_record() -> dict:
    """Registro válido; testes podem mutar sem afetar a fixture original."""
    return make_valid_record()


@pytest.fixture
def valid_record_copy(valid_record: dict) -> dict:
    """Cópia profunda do registro válido para testes que o alteram."""
    return copy.deepcopy(valid_record)
