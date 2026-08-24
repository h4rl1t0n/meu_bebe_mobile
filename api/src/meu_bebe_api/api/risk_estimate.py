"""``POST /api/v1/risk-estimate`` — estimativa probabilística experimental.

FASE 4C: camada HTTP sobre o ``ModelRuntime`` da FASE 4B. A rota NÃO duplica o
adapter, NÃO chama o pipeline diretamente, NÃO recarrega o joblib e NÃO aplica
threshold/classificação — apenas delega a ``runtime.predict_probability`` e
sanitiza a resposta.

Contratos:
- 200 ``RiskEstimateResponse`` (``probability`` em [0,1], sem threshold).
- 503 ``MODEL_NOT_READY`` (MESMO contrato do ``/ready``) se o modelo não está
  carregado.
- 500 ``INFERENCE_ERROR`` (sanitizado) em falha inesperada da inferência.
"""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse

from ..contracts.dss import DssPayload
from ..contracts.errors import ErrorResponse
from ..contracts.risk_estimate import (
    EXPERIMENTAL_ESTIMATE_NOTICE,
    EXPERIMENTAL_TARGET,
    ErrorEnvelope,
    RiskEstimateModelMetadata,
    RiskEstimateResponse,
    RiskEstimateResult,
)
from ..ml.runtime import ModelRuntime
from .ready import MODEL_NOT_READY_CODE, MODEL_NOT_READY_MESSAGE, get_model_runtime

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Risk estimate"])

INFERENCE_ERROR_CODE = "INFERENCE_ERROR"
INFERENCE_ERROR_MESSAGE = "Não foi possível calcular a estimativa."


@router.post(
    "/risk-estimate",
    summary="Estimar probabilidade experimental de descontinuidade do pré-natal",
    description=(
        "Calcula uma estimativa estatística experimental da probabilidade do "
        "desfecho sintético de descontinuidade do acompanhamento pré-natal a "
        "partir do questionário DSS (Q_full 1.13). Não constitui diagnóstico "
        "médico nem previsão clínica validada."
    ),
    response_model=RiskEstimateResponse,
    responses={
        422: {"model": ErrorResponse, "description": "Payload DSS inválido."},
        500: {"model": ErrorEnvelope, "description": "Falha inesperada na inferência."},
        503: {"model": ErrorEnvelope, "description": "Modelo não carregado."},
    },
)
def risk_estimate(
    payload: DssPayload,
    runtime: ModelRuntime = Depends(get_model_runtime),
) -> RiskEstimateResponse | JSONResponse:
    """Estima ``P(descontinuou_pre_natal)`` a partir de um ``DssPayload``."""
    if not runtime.is_ready or runtime.metadata is None:
        error = ErrorResponse(
            code=MODEL_NOT_READY_CODE,
            message=MODEL_NOT_READY_MESSAGE,
            details=[],
        )
        return JSONResponse(status_code=503, content={"error": error.model_dump()})

    try:
        probability = runtime.predict_probability(payload)
    except Exception as exc:  # noqa: BLE001 — sanitizado (sem stack/payload no HTTP)
        logger.error("inferência falhou: %s", exc)
        error = ErrorResponse(
            code=INFERENCE_ERROR_CODE,
            message=INFERENCE_ERROR_MESSAGE,
            details=[],
        )
        return JSONResponse(status_code=500, content={"error": error.model_dump()})

    return RiskEstimateResponse(
        result=RiskEstimateResult(
            target=EXPERIMENTAL_TARGET,
            probability=probability,
        ),
        model=RiskEstimateModelMetadata(
            name=runtime.metadata.name,
            schema_version=runtime.metadata.schema_version,
            raw_feature_count=runtime.metadata.raw_feature_count,
            transformed_feature_count=runtime.metadata.transformed_feature_count,
        ),
        notice=EXPERIMENTAL_ESTIMATE_NOTICE,
    )
