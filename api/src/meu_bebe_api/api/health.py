"""Health check do serviço.

NÃO declara ``model_ready``: nenhum modelo é carregado nesta fase.
"""

from __future__ import annotations

from fastapi import APIRouter

from .. import __version__
from ..config import get_settings
from ..contracts.dss import DSS_SCHEMA_VERSION

router = APIRouter(tags=["health"])


@router.get("/health", summary="Verificação de saúde do serviço")
def health() -> dict[str, str]:
    """Responde com o estado do serviço e as duas versões independentes."""
    return {
        "status": "ok",
        "service": get_settings().app_name,
        "api_version": __version__,
        "dss_schema_version": DSS_SCHEMA_VERSION,
    }
