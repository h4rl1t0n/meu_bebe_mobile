"""Contratos de dados (DSS) e de erro da API."""

from __future__ import annotations

from .dss import DSS_SCHEMA_VERSION, DssPayload
from .errors import ErrorDetail, ErrorResponse

__all__ = [
    "DSS_SCHEMA_VERSION",
    "DssPayload",
    "ErrorDetail",
    "ErrorResponse",
]
