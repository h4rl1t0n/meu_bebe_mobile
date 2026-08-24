"""Readiness probe (FASE 4B) — ``GET /ready`` na raiz.

Diferente do ``/health`` (liveness), o ``/ready`` reflete se o MODELO foi
carregado com sucesso. Em falha responde ``503`` com ``MODEL_NOT_READY`` e SEM
detalhes internos (nenhum caminho absoluto, hash ou mensagem de erro vazam).
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, Request
from fastapi.responses import JSONResponse

from ..contracts.errors import ErrorResponse
from ..ml.runtime import ModelRuntime

router = APIRouter(tags=["health"])

# Contrato público de erro do /ready quando o modelo NÃO está pronto.
MODEL_NOT_READY_CODE = "MODEL_NOT_READY"
MODEL_NOT_READY_MESSAGE = "Modelo de inferência indisponível."


def get_model_runtime(request: Request) -> ModelRuntime:
    """Dependency injection: recupera o runtime registrado no ``app.state``.

    Sempre disponível porque o lifespan registra o runtime antes de aceitar
    requisições (mesmo com ``model_load_on_startup=False``).
    """
    runtime = getattr(request.app.state, "model_runtime", None)
    if runtime is None:
        raise RuntimeError("model_runtime não inicializado no app.state")
    return runtime


@router.get("/ready", summary="Verificação de prontidão (modelo carregado)")
def ready(request: Request, runtime: ModelRuntime = Depends(get_model_runtime)) -> JSONResponse:
    """200 se READY; 503 com o envelope de erro padronizado caso contrário."""
    settings = request.app.state.settings

    if runtime.is_ready and runtime.metadata is not None:
        return JSONResponse(
            status_code=200,
            content={
                "status": "ready",
                "service": settings.app_name,
                "model": {
                    "name": runtime.metadata.name,
                    "raw_feature_count": runtime.metadata.raw_feature_count,
                    "transformed_feature_count": runtime.metadata.transformed_feature_count,
                },
            },
        )

    error = ErrorResponse(
        code=MODEL_NOT_READY_CODE,
        message=MODEL_NOT_READY_MESSAGE,
        details=[],
    )
    return JSONResponse(status_code=503, content={"error": error.model_dump()})
