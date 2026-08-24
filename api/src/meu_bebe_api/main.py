"""Fábrica da aplicação FastAPI (FASE 4A).

Esta fase NÃO carrega modelo, NÃO prediz, NÃO acessa banco e NÃO autentica.
Expõe apenas o health check de INFRAESTRUTURA na raiz (``GET /health``); o
prefixo ``/api/v1`` fica RESERVADO para endpoints funcionais versionados
futuros (nenhum endpoint é registrado sob ele nesta fase).
"""

from __future__ import annotations

from fastapi import FastAPI

from . import __version__
from .api.health import router as health_router
from .config import Settings, get_settings
from .core.exception_handlers import register_exception_handlers

_DESCRIPTION = (
    "API de coleta dos Determinantes Sociais de Saúde (DSS) do projeto Meu Bebê.\n\n"
    "**Aviso médico**: esta API coleta dados sociodemográficos e de saúde para "
    "fins de pesquisa acadêmica. Ela NÃO fornece diagnóstico, acompanhamento "
    "clínico nem orientação médica. Em caso de dúvida sobre a sua saúde ou a de "
    "seu bebê, procure um profissional de saúde."
)


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
    )
    # Health check de infraestrutura: fica na RAIZ, fora do prefixo funcional.
    app.include_router(health_router)

    # O prefixo /api/v1 fica RESERVADO para endpoints funcionais versionados
    # futuros. Nenhum endpoint é registrado sob ele nesta fase.
    register_exception_handlers(app)
    return app


app = create_app()
