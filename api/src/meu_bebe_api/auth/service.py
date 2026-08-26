"""Caso de uso de autenticação (FASE 8C) — service/use case.

O service é o ÚNICO dono de ``commit``/``rollback`` (arquitetura 8B): uma
operação de escrita = uma unidade de trabalho atômica. Os repositories NÃO
committam. ``register`` cria USER + sessão num ÚNICO commit (seção 11);
``refresh`` rotaciona com revogação simples da sessão utilizada (seção 8).
Nunca loga senha/hash/token/segredo.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime, timezone

from sqlalchemy.exc import IntegrityError, OperationalError
from sqlalchemy.orm import Session

from ..config import Settings
from ..models.auth_refresh_session import AuthRefreshSession
from ..models.user import User
from ..repositories.auth_refresh_session_repository import AuthRefreshSessionRepository
from ..repositories.user_repository import UserRepository
from .errors import (
    ACCOUNT_INACTIVE,
    ACCOUNT_INACTIVE_MESSAGE,
    AUTH_NOT_CONFIGURED,
    AUTH_NOT_CONFIGURED_MESSAGE,
    DATABASE_UNAVAILABLE,
    DATABASE_UNAVAILABLE_MESSAGE,
    DUPLICATE_EMAIL,
    DUPLICATE_EMAIL_MESSAGE,
    INVALID_CREDENTIALS,
    INVALID_CREDENTIALS_MESSAGE,
    TOKEN_ERROR,
    TOKEN_ERROR_MESSAGE,
    TOKEN_EXPIRED,
    TOKEN_EXPIRED_MESSAGE,
    TOKEN_INVALID,
    TOKEN_INVALID_MESSAGE,
    TOKEN_REVOKED,
    TOKEN_REVOKED_MESSAGE,
    AuthError,
)
from .security import (
    create_access_token,
    create_refresh_token,
    decode_refresh_token,
    hash_password,
    normalize_email,
    verify_password,
)

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class AuthResult:
    """Resultado de register/login/refresh: usuário + par de tokens."""

    user: User
    access_token: str
    refresh_token: str


class AuthService:
    def __init__(self, settings: Settings, session: Session) -> None:
        self._settings = settings
        self._session = session
        self._users = UserRepository(session)
        self._refresh_sessions = AuthRefreshSessionRepository(session)

    # ------------------------------------------------------------------ helpers
    def _require_configured(self) -> None:
        """Defesa em profundidade (a dependency já valida; garante uso direto)."""
        if not self._settings.jwt_secret:
            raise AuthError(AUTH_NOT_CONFIGURED, AUTH_NOT_CONFIGURED_MESSAGE, 503)

    def _issue_tokens(self, user: User) -> tuple[str, str]:
        """Gera access+refresh e persiste a nova sessão (sem commit)."""
        access_token = create_access_token(self._settings, user.id)
        refresh = create_refresh_token(self._settings, user.id)
        self._refresh_sessions.add(
            AuthRefreshSession(
                user_id=user.id, jti=refresh.jti, expires_at=refresh.expires_at
            )
        )
        return access_token, refresh.token

    # ------------------------------------------------------------------- register
    def register(self, email: str, password: str) -> AuthResult:
        """Cria USER + sessão de refresh numa transação atômica (seção 11)."""
        self._require_configured()
        normalized = normalize_email(email)
        try:
            if self._users.find_by_email(normalized) is not None:
                raise AuthError(DUPLICATE_EMAIL, DUPLICATE_EMAIL_MESSAGE, 409)
            user = User(email=normalized, password_hash=hash_password(password))
            self._users.add(user)
            self._session.flush()  # garante ``user.id`` antes da sessão
            access_token, refresh_token = self._issue_tokens(user)
            self._session.commit()
        except AuthError:
            self._session.rollback()
            raise
        except IntegrityError:
            self._session.rollback()
            raise AuthError(DUPLICATE_EMAIL, DUPLICATE_EMAIL_MESSAGE, 409) from None
        except OperationalError:
            self._session.rollback()
            raise AuthError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise AuthError(TOKEN_ERROR, TOKEN_ERROR_MESSAGE, 500) from None
        return AuthResult(user=user, access_token=access_token, refresh_token=refresh_token)

    # ---------------------------------------------------------------------- login
    def login(self, email: str, password: str) -> AuthResult:
        """Autentica; anti-enumeração (e-mail/senha → mesmo 401)."""
        self._require_configured()
        normalized = normalize_email(email)
        try:
            user = self._users.find_by_email(normalized)
        except OperationalError:
            raise AuthError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        if user is None or not verify_password(password, user.password_hash):
            raise AuthError(INVALID_CREDENTIALS, INVALID_CREDENTIALS_MESSAGE, 401)
        if not user.is_active:
            raise AuthError(ACCOUNT_INACTIVE, ACCOUNT_INACTIVE_MESSAGE, 403)
        try:
            access_token, refresh_token = self._issue_tokens(user)
            self._session.commit()
        except OperationalError:
            self._session.rollback()
            raise AuthError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise AuthError(TOKEN_ERROR, TOKEN_ERROR_MESSAGE, 500) from None
        return AuthResult(user=user, access_token=access_token, refresh_token=refresh_token)

    # --------------------------------------------------------------------- refresh
    def refresh(self, refresh_token: str) -> AuthResult:
        """Rotação simples: revoga a sessão usada e emite novo par (atômico)."""
        self._require_configured()
        jti = decode_refresh_token(self._settings, refresh_token)
        try:
            session_obj = self._refresh_sessions.find_by_jti(jti)
            if session_obj is None:
                raise AuthError(TOKEN_INVALID, TOKEN_INVALID_MESSAGE, 401)
            if session_obj.revoked_at is not None:
                raise AuthError(TOKEN_REVOKED, TOKEN_REVOKED_MESSAGE, 401)
            if session_obj.expires_at < datetime.now(timezone.utc):
                raise AuthError(TOKEN_EXPIRED, TOKEN_EXPIRED_MESSAGE, 401)
            user = self._users.find_by_id(session_obj.user_id)
            if user is None:
                raise AuthError(TOKEN_INVALID, TOKEN_INVALID_MESSAGE, 401)
            if not user.is_active:
                raise AuthError(ACCOUNT_INACTIVE, ACCOUNT_INACTIVE_MESSAGE, 403)
            self._refresh_sessions.revoke(session_obj, datetime.now(timezone.utc))
            access_token, new_refresh_token = self._issue_tokens(user)
            self._session.commit()
        except AuthError:
            self._session.rollback()
            raise
        except OperationalError:
            self._session.rollback()
            raise AuthError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise AuthError(TOKEN_ERROR, TOKEN_ERROR_MESSAGE, 500) from None
        return AuthResult(
            user=user, access_token=access_token, refresh_token=new_refresh_token
        )

    # ---------------------------------------------------------------------- logout
    def logout(self, refresh_token: str) -> None:
        """Revoga a sessão (idempotente; sem blacklist de access — seção 9)."""
        self._require_configured()
        try:
            jti = decode_refresh_token(self._settings, refresh_token)
        except AuthError as exc:
            if exc.status_code == 401:
                return  # idempotente: token inválido/expirado → nada a revogar
            raise
        try:
            session_obj = self._refresh_sessions.find_by_jti(jti)
            if session_obj is not None and session_obj.revoked_at is None:
                self._refresh_sessions.revoke(session_obj, datetime.now(timezone.utc))
                self._session.commit()
        except OperationalError:
            self._session.rollback()
            raise AuthError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise AuthError(TOKEN_ERROR, TOKEN_ERROR_MESSAGE, 500) from None
