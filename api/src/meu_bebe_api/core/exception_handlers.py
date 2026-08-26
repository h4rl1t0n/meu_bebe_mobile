"""Handlers de exceção — envelope de erro padronizado.

Nunca expõe o corpo bruto da requisição nem stack trace. O ``details`` carrega
apenas ``loc``, ``msg`` e ``type`` do erro de validação (o valor rejeitado
``input`` é descartado por segurança/privacidade).
"""

from __future__ import annotations

from typing import Any

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from ..auth.errors import AuthError
from ..contracts.errors import ErrorDetail, ErrorResponse
from ..domain.errors import DomainError


def _validation_details(exc: RequestValidationError) -> list[ErrorDetail]:
    details: list[ErrorDetail] = []
    for err in exc.errors():
        details.append(
            ErrorDetail(
                loc=list(err.get("loc", ())),
                msg=str(err.get("msg", "")),
                type=str(err.get("type", "")),
            )
        )
    return details


async def validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    body = ErrorResponse(
        code="VALIDATION_ERROR",
        message="Requisição inválida",
        details=_validation_details(exc),
    )
    return JSONResponse(status_code=422, content=body.model_dump())


async def http_exception_handler(
    request: Request, exc: StarletteHTTPException
) -> JSONResponse:
    if exc.status_code == 404:
        code = "NOT_FOUND"
        message = "Recurso não encontrado"
    else:
        code = "HTTP_ERROR"
        message = str(exc.detail) if exc.detail else "Erro da aplicação"

    body = ErrorResponse(code=code, message=message, details=[])
    return JSONResponse(status_code=exc.status_code, content=body.model_dump())


async def auth_error_handler(request: Request, exc: AuthError) -> JSONResponse:
    """Envelope de erro de autenticação (FASE 8C).

    401/403/409 → formato plano ``{code, message, details}`` (como o 422);
    500/503 → ``{"error": {...}}`` (mesmo envelope do ``/ready``/``/risk-estimate``).
    """
    body = ErrorResponse(code=exc.code, message=exc.message, details=[])
    if exc.status_code >= 500:
        content = {"error": body.model_dump()}
    else:
        content = body.model_dump()
    return JSONResponse(status_code=exc.status_code, content=content)


async def domain_error_handler(request: Request, exc: DomainError) -> JSONResponse:
    """Envelope de erro de domínio (FASE 8D) — mesmo padrão do ``AuthError``."""
    body = ErrorResponse(code=exc.code, message=exc.message, details=[])
    if exc.status_code >= 500:
        content = {"error": body.model_dump()}
    else:
        content = body.model_dump()
    return JSONResponse(status_code=exc.status_code, content=content)


def register_exception_handlers(app: FastAPI) -> None:
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(StarletteHTTPException, http_exception_handler)
    app.add_exception_handler(AuthError, auth_error_handler)
    app.add_exception_handler(DomainError, domain_error_handler)
