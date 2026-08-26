"""Contratos de dados (DSS), de erro e de resposta da API."""

from __future__ import annotations

from .dss import DSS_SCHEMA_VERSION, DssPayload
from .errors import ErrorDetail, ErrorResponse
from .gestacao import GestacaoResponse, GestacaoWrite
from .gestante import GestanteResponse, GestanteWrite
from .risk_estimate import (
    EXPERIMENTAL_ESTIMATE_NOTICE,
    EXPERIMENTAL_TARGET,
    ErrorEnvelope,
    RiskEstimateModelMetadata,
    RiskEstimateResponse,
    RiskEstimateResult,
)

__all__ = [
    "DSS_SCHEMA_VERSION",
    "DssPayload",
    "ErrorDetail",
    "ErrorResponse",
    "EXPERIMENTAL_ESTIMATE_NOTICE",
    "EXPERIMENTAL_TARGET",
    "ErrorEnvelope",
    "RiskEstimateModelMetadata",
    "RiskEstimateResponse",
    "RiskEstimateResult",
    "GestanteResponse",
    "GestanteWrite",
    "GestacaoResponse",
    "GestacaoWrite",
]
