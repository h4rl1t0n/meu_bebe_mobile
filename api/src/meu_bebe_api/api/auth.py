"""Rotas de autenticação — prefixo ``/api/v1/auth`` (FASE 8C).

Endpoints: ``register``, ``login``, ``refresh``, ``logout``, ``me``. Nenhuma
autenticação é aplicada globalmente (não há middleware): auth é declarada apenas
nas rotas que a exigem (``refresh``/``logout``/``me``). ``POST
/api/v1/risk-estimate`` permanece público/stateless (seção 10/19.4 do plano).
"""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, Request, status
from fastapi.responses import Response
from sqlalchemy.orm import Session

from ..auth.dependencies import get_auth_session, get_current_user, require_auth_configured
from ..auth.service import AuthService
from ..contracts.auth import (
    LoginRequest,
    LogoutRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
)
from ..contracts.errors import ErrorResponse
from ..models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Auth"], prefix="/auth")


@router.post(
    "/register",
    status_code=status.HTTP_201_CREATED,
    response_model=TokenResponse,
    summary="Criar usuário e devolver tokens",
    responses={
        409: {"model": ErrorResponse, "description": "E-mail já cadastrado."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def register(
    payload: RegisterRequest,
    request: Request,
    _configured: None = Depends(require_auth_configured),
    session: Session = Depends(get_auth_session),
) -> TokenResponse:
    result = AuthService(request.app.state.settings, session).register(
        payload.email, payload.password
    )
    return TokenResponse(
        user=UserResponse.model_validate(result.user),
        access_token=result.access_token,
        refresh_token=result.refresh_token,
    )


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Autenticar com e-mail e senha",
    responses={
        401: {"model": ErrorResponse, "description": "Credenciais inválidas."},
        403: {"model": ErrorResponse, "description": "Conta inativa."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def login(
    payload: LoginRequest,
    request: Request,
    _configured: None = Depends(require_auth_configured),
    session: Session = Depends(get_auth_session),
) -> TokenResponse:
    result = AuthService(request.app.state.settings, session).login(
        payload.email, payload.password
    )
    return TokenResponse(
        user=UserResponse.model_validate(result.user),
        access_token=result.access_token,
        refresh_token=result.refresh_token,
    )


@router.post(
    "/refresh",
    response_model=TokenResponse,
    summary="Rotacionar refresh token (revoga a sessão usada)",
    responses={
        401: {"model": ErrorResponse, "description": "Token inválido/expirado/revogado."},
        403: {"model": ErrorResponse, "description": "Conta inativa."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def refresh(
    payload: RefreshRequest,
    request: Request,
    _configured: None = Depends(require_auth_configured),
    session: Session = Depends(get_auth_session),
) -> TokenResponse:
    result = AuthService(request.app.state.settings, session).refresh(
        payload.refresh_token
    )
    return TokenResponse(
        user=UserResponse.model_validate(result.user),
        access_token=result.access_token,
        refresh_token=result.refresh_token,
    )


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Revogar a sessão de refresh (idempotente)",
    responses={
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def logout(
    payload: LogoutRequest,
    request: Request,
    _configured: None = Depends(require_auth_configured),
    session: Session = Depends(get_auth_session),
) -> Response:
    AuthService(request.app.state.settings, session).logout(payload.refresh_token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Retornar o usuário autenticado",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        403: {"model": ErrorResponse, "description": "Conta inativa."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def me(user: User = Depends(get_current_user)) -> UserResponse:
    return UserResponse.model_validate(user)
