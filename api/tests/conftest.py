"""Fixtures e helpers compartilhados dos testes da API."""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from meu_bebe_api.contracts.dss import DssPayload
from meu_bebe_api.main import create_app


def make_valid_payload() -> dict:
    """Payload canônico completo e válido (as 48 variáveis + schema_version)."""
    return {
        "schema_version": "1.13",
        "educacao": {
            "estuda_atualmente": True,
            "escolaridade": "medio_completo",
            "situacao_estudos_gestacao": "nao_estudava",
            "dificuldades_educacao": ["distancia"],
            "entende_orientacoes_saude": True,
            "fez_curso_qualificacao_profissional": False,
        },
        "trabalho": {
            "empregado": True,
            "tipo_emprego": "clt",
            "faixa_renda": "ate_1_sm",
            "trabalho_permite_pre_natal": True,
            "ambiente_trabalho_seguro": True,
            "tem_pausas_descanso": True,
            "beneficios_trabalho": ["vale_transporte"],
            "motivo_desemprego": None,
            "recebe_beneficio_social": False,
            "impacto_gestacao_trabalho": "nao_afetou",
        },
        "saneamento": {
            "fonte_agua": "rede_publica",
            "interrupcoes_agua": False,
            "esgotamento_sanitario": "rede_coletora",
            "frequencia_coleta_lixo": "regular",
            "destino_lixo_sem_coleta": None,
            "problema_saude_agua": False,
            "cuidados_vetores": ["elimina_agua_parada"],
        },
        "saude": {
            "distancia_ubs": "muito_proxima",
            "faltou_consulta": False,
            "acesso_ubs": "a_pe",
            "cadastrada_ubs": True,
            "servicos_pre_natal": ["consulta_medica"],
            "exames_pre_natal_completos": True,
            "vacinas_em_dia": True,
            "avaliacao_pre_natal": "bom",
            "dificuldades_saude": ["distancia"],
        },
        "habitacao": {
            "tipo_moradia": "casa",
            "material_moradia": "alvenaria",
            "numero_pessoas": 3,
            "numero_comodos": 5,
            "numero_dormitorios": 2,
            "itens_residencia": ["agua_encanada"],
            "seguranca_residencia": "segura",
            "melhorias_desejadas": ["melhorar_banheiro"],
            "facil_acesso_saude": True,
        },
        "alimentacao": {
            "refeicoes_por_dia": "tres",
            "deixou_de_comer_falta_dinheiro": False,
            "alimentos_consumidos": ["frutas_verduras"],
            "fonte_alimentos": ["supermercado_feira"],
            "mudanca_alimentacao_gestacao": False,
            "usa_suplementos": True,
            "avaliacao_alimentacao": "boa",
        },
    }


@pytest.fixture
def client() -> TestClient:
    app = create_app()
    with TestClient(app) as c:
        yield c


@pytest.fixture
def client_with_validation_route() -> TestClient:
    """Cliente com uma rota SOMENTE DE TESTE que valida um ``DssPayload``.

    A rota ``/_test/validate`` NÃO existe no app de produção — ela serve
    apenas para exercitar o handler de 422 (RequestValidationError) sem criar
    um endpoint público ``/validate``.
    """
    app = create_app()

    @app.post("/_test/validate")
    def _test_validate(payload: DssPayload) -> dict[str, bool]:
        return {"accepted": True}

    with TestClient(app) as c:
        yield c
