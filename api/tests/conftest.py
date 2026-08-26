"""Fixtures e helpers compartilhados dos testes da API."""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.engine import Engine

from meu_bebe_api.config import Settings
from meu_bebe_api.contracts.dss import DssPayload
from meu_bebe_api.db.engine import build_engine
from meu_bebe_api.main import create_app
from meu_bebe_api.ml.runtime import ModelRuntime

# URL apontando para uma porta fechada (indisponível): usada para testar a
# infraestrutura de DB sem exigir PostgreSQL real (o engine é preguiçoso).
UNREACHABLE_DATABASE_URL = "postgresql+psycopg://user:pass@127.0.0.1:1/none"


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


def make_dss_payload() -> DssPayload:
    """``DssPayload`` válido (objeto tipado) a partir do payload canônico."""
    return DssPayload.model_validate(make_valid_payload())


@pytest.fixture
def settings_no_load() -> Settings:
    """Settings SEM carregar o modelo (rápido para a maioria dos testes)."""
    return Settings(model_load_on_startup=False, _env_file=None)


@pytest.fixture
def client(settings_no_load: Settings) -> TestClient:
    app = create_app(settings_no_load)
    with TestClient(app) as c:
        yield c


@pytest.fixture
def client_with_validation_route(settings_no_load: Settings) -> TestClient:
    """Cliente com uma rota SOMENTE DE TESTE que valida um ``DssPayload``.

    A rota ``/_test/validate`` NÃO existe no app de produção — ela serve
    apenas para exercitar o handler de 422 (RequestValidationError) sem criar
    um endpoint público ``/validate``.
    """
    app = create_app(settings_no_load)

    @app.post("/_test/validate")
    def _test_validate(payload: DssPayload) -> dict[str, bool]:
        return {"accepted": True}

    with TestClient(app) as c:
        yield c


@pytest.fixture
def unreachable_engine() -> Engine:
    """Engine SQLAlchemy PREGUIÇOSO apontando para uma porta fechada.

    Não abre conexão alguma (``create_engine`` é preguiçoso); a porta 1 é
    inalcançável, então qualquer tentativa real de conexão falha de forma
    controlada. Serve para testar engine/session/probe sem PostgreSQL real.
    """
    settings = Settings(database_url=UNREACHABLE_DATABASE_URL, _env_file=None)
    engine = build_engine(settings)
    yield engine
    engine.dispose()


@pytest.fixture(scope="session")
def real_runtime() -> ModelRuntime:
    """Runtime carregado com o modelo REAL (uma única vez por sessão de testes).

    Requer o artefato congelado em ``ia/artifacts/models/`` (presente no
    monorepo). Usado apenas pelos testes de integração/inferência.
    """
    runtime = ModelRuntime(Settings(model_load_on_startup=False, _env_file=None))
    runtime.load()
    return runtime
