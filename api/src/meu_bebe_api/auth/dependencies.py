"""Dependências de autenticação (FASE 8C).

- ``require_auth_configured``: falha 503 ``AUTH_NOT_CONFIGURED`` se ``JWT_SECRET``
  ausente (declarada ANTES da session para que a config falhe antes do banco).
- ``get_auth_session``: Session por request; ausência de DB → 503
  ``DATABASE_UNAVAILABLE`` (espelho do ``get_session`` da 8B, porém mapeado ao
  envelope de auth em vez de ``RuntimeError``).
- ``get_current_user``: resolve o ``User`` autenticado a partir do access token.
"""

from __future__ import annotations

from collections.abc import Iterator

from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

from ..config import Settings
from ..models.user import User
from ..repositories.user_repository import UserRepository
from .errors import (
    ACCOUNT_INACTIVE,
    ACCOUNT_INACTIVE_MESSAGE,
    AUTH_NOT_CONFIGURED,
    AUTH_NOT_CONFIGURED_MESSAGE,
    DATABASE_UNAVAILABLE,
    DATABASE_UNAVAILABLE_MESSAGE,
    UNAUTHORIZED,
    UNAUTHORIZED_MESSAGE,
    AuthError,
)
from .security import decode_access_token

# ``auto_error=False`` → ``None`` em vez de 403 automático; o código mapeia para
# ``401 UNAUTHORIZED`` no envelope próprio.
_bearer = HTTPBearer(auto_error=False)


def require_auth_configured(request: Request) -> None:
    """Falha 503 ``AUTH_NOT_CONFIGURED`` se a auth não está configurada."""
    settings: Settings = request.app.state.settings
    if not settings.jwt_secret:
        raise AuthError(AUTH_NOT_CONFIGURED, AUTH_NOT_CONFIGURED_MESSAGE, 503)


def get_auth_session(request: Request) -> Iterator[Session]:
    """Session por request; ausência de DB → 503 ``DATABASE_UNAVAILABLE``."""
    factory = getattr(request.app.state, "session_factory", None)
    if factory is None:
        raise AuthError(DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503)
    session: Session = factory()
    try:
        yield session
    finally:
        session.close()


def get_current_user(
    request: Request,
    _configured: None = Depends(require_auth_configured),
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    session: Session = Depends(get_auth_session),
) -> User:
    """Resolve o ``User`` autenticado (access token Bearer, ``type=access``)."""
    if credentials is None or not credentials.credentials:
        raise AuthError(UNAUTHORIZED, UNAUTHORIZED_MESSAGE, 401)
    user_id = decode_access_token(request.app.state.settings, credentials.credentials)
    try:
        user = UserRepository(session).find_by_id(user_id)
    except OperationalError:
        raise AuthError(DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503) from None
    if user is None:
        raise AuthError(UNAUTHORIZED, UNAUTHORIZED_MESSAGE, 401)
    if not user.is_active:
        raise AuthError(ACCOUNT_INACTIVE, ACCOUNT_INACTIVE_MESSAGE, 403)
    return user
