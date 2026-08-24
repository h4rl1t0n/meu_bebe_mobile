"""Fábrica da aplicação FastAPI (FASE 4B).

- ``GET /health`` (liveness): sempre 200, sem depender do modelo.
- ``GET /ready`` (readiness): 200 se o modelo carregou; 503 ``MODEL_NOT_READY``.
- O prefixo ``/api/v1`` fica RESERVADO para endpoints funcionais versionados
  futuros (nenhum endpoint público de previsão é registrado — FASE 4C).

O modelo é carregado no lifespan (``asynccontextmanager``) quando
``model_load_on_startup=true``; em falha o app SOBE mesmo assim (FAIL-CLOSED
apenas no ``/ready``), pois a liveness não pode crashar por causa do modelo.
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from . import __version__
from .api.health import router as health_router
from .api.ready import router as ready_router
from .config import Settings, get_settings
from .core.exception_handlers import register_exception_handlers
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

    O runtime é SEMPRE registrado (mesmo sem load) para que ``/ready`` responda
    ``503`` de forma determinística. Falha de load NÃO impede o app de subir.
    """
    settings: Settings = app.state.settings
    runtime = ModelRuntime(settings)
    app.state.model_runtime = runtime

    if settings.model_load_on_startup:
        try:
            runtime.load()
        except ModelError:
            logger.exception("modelo não carregado no startup (readiness indisponível)")

    yield


def create_app(settings: Settings | None = None) -> FastAPI:
    """Constrói a aplicação (permitindo injeção de settings em testes)."""
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

    # Liveness (infraestrutura) + readiness (modelo), ambos na RAIZ.
    app.include_router(health_router)
    app.include_router(ready_router)

    # O prefixo /api/v1 fica RESERVADO para endpoints funcionais versionados
    # futuros. Nenhum endpoint é registrado sob ele nesta fase.
    register_exception_handlers(app)
    return app


app = create_app()
