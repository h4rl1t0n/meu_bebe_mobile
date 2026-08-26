"""Fábrica da aplicação FastAPI (FASE 4C).

- ``GET /health`` (liveness): sempre 200, sem depender do modelo.
- ``GET /ready`` (readiness): 200 se o modelo carregou; 503 ``MODEL_NOT_READY``.
- ``POST /api/v1/risk-estimate`` (funcional): estimativa probabilística
  experimental (FASE 4C).

O modelo é carregado no lifespan (``asynccontextmanager``) quando
``model_load_on_startup=true``; em falha o app SOBE mesmo assim (FAIL-CLOSED
apenas no ``/ready`` e no endpoint funcional), pois a liveness não pode
crashar por causa do modelo.
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from . import __version__
from .api.health import router as health_router
from .api.ready import router as ready_router
from .api.router import api_v1_router
from .config import Settings, get_settings
from .core.exception_handlers import register_exception_handlers
from .db.engine import build_engine
from .db.session import build_session_factory
from .ml.errors import ModelError
from .ml.runtime import ModelRuntime

logger = logging.getLogger(__name__)

_DESCRIPTION = (
    "API de coleta dos Determinantes Sociais de Saúde (DSS) do projeto Meu Bebê.\n\n"
    "**Aviso médico**: esta API coleta dados sociodemográficos e de saúde para "
    "fins de pesquisa acadêmica. Ela NÃO fornece diagnóstico, acompanhamento "
    "clínico nem orientação médica. Em caso de dúvida sobre a sua saúde ou a de "
    "seu bebê, procure um profissional de saúde."
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Registra o runtime e carrega o modelo (se habilitado).

    O runtime é SEMPRE registrado (mesmo sem load) para que ``/ready`` e o
    endpoint funcional respondam ``503`` de forma determinística. Falha de load
    NÃO impede o app de subir. Um runtime pode ser injetado via
    ``create_app(runtime=...)`` (testes usam um fake sem carregar o modelo real).
    """
    settings: Settings = app.state.settings
    runtime = getattr(app.state, "runtime_override", None)
    if runtime is None:
        runtime = ModelRuntime(settings)
    app.state.model_runtime = runtime

    if settings.model_load_on_startup:
        try:
            runtime.load()
        except ModelError:
            logger.exception("modelo não carregado no startup (readiness indisponível)")

    # FASE 8B — infraestrutura de persistência (SQLAlchemy 2.x sync + psycopg 3).
    # ``build_engine`` é PREGUIÇOSO (não abre conexão): o processo sobe mesmo com
    # o PostgreSQL temporariamente indisponível. A persistência NÃO se acopla ao
    # ModelRuntime nem ao fluxo DSS — são runtimes independentes (ML ≠ DB).
    engine = build_engine(settings)
    app.state.engine = engine
    app.state.session_factory = build_session_factory(engine)

    try:
        yield
    finally:
        # FASE 8B-AUDIT L-1: encerramento explícito dos recursos de
        # persistência no shutdown (devolve/descarta as conexões do pool).
        # Sem Engine (``DATABASE_URL`` ausente), ``engine`` é ``None`` e o
        # shutdown segue normalmente (ML runtime e DB runtime permanecem
        # independentes).
        if engine is not None:
            engine.dispose()


def create_app(
    settings: Settings | None = None,
    runtime: ModelRuntime | None = None,
) -> FastAPI:
    """Constrói a aplicação (permitindo injeção de settings/runtime em testes)."""
    settings = settings or get_settings()

    docs_enabled = settings.app_docs_enabled
    app = FastAPI(
        title="Meu Bebê API",
        version=__version__,
        description=_DESCRIPTION,
        docs_url="/docs" if docs_enabled else None,
        redoc_url="/redoc" if docs_enabled else None,
        openapi_url="/openapi.json" if docs_enabled else None,
        lifespan=lifespan,
    )

    # Configuração disponível via ``app.state`` para o lifespan e as rotas.
    app.state.settings = settings
    # Runtime injetado (testes). Se ``None``, o lifespan cria o runtime real.
    app.state.runtime_override = runtime

    # Liveness (infraestrutura) + readiness (modelo), ambos na RAIZ.
    app.include_router(health_router)
    app.include_router(ready_router)

    # Endpoint funcional versionado (FASE 4C) sob /api/v1.
    app.include_router(api_v1_router)

    register_exception_handlers(app)
    return app


app = create_app()
