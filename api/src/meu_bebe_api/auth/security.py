"""Segurança: hash Argon2id + JWT HS256 (FASE 8C).

- ``hash_password`` / ``verify_password`` (Argon2id via ``pwdlib``; string PHC).
- ``normalize_email`` (``strip().lower()``) — função canônica.
- Emitir/validar access e refresh (PyJWT, HS256), com separação estrita de
  ``type`` (seção 6.3) e claims mínimas (sem ``iss``/``aud`` — seção 6.2).

NUNCA loga/retorna senha, hash, token ou segredo.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

import jwt
from pwdlib import PasswordHash
from pwdlib.hashers.argon2 import Argon2Hasher

from ..config import Settings
from .errors import (
    TOKEN_ERROR,
    TOKEN_ERROR_MESSAGE,
    TOKEN_EXPIRED,
    TOKEN_EXPIRED_MESSAGE,
    TOKEN_INVALID,
    TOKEN_INVALID_MESSAGE,
    UNAUTHORIZED,
    UNAUTHORIZED_MESSAGE,
    AuthError,
)

# Argon2id com os defaults do backend (argon2-cffi via pwdlib). Não inventar
# parâmetros próprios (seção 4 do plano).
_password_hasher = PasswordHash((Argon2Hasher(),))


def normalize_email(email: str) -> str:
    """Canônico: ``strip().lower()`` (usado para armazenar e buscar)."""
    return email.strip().lower()


def hash_password(plaintext: str) -> str:
    """Retorna a string PHC Argon2id. Nunca loga nem retorna a senha."""
    return _password_hasher.hash(plaintext)


def verify_password(plaintext: str, phc_hash: str) -> bool:
    """Comparação Argon2id; senha errada → ``False`` (nunca propaga exceção)."""
    try:
        return bool(_password_hasher.verify(plaintext, phc_hash))
    except Exception:  # noqa: BLE001 — hash malformado ≠ senha válida
        return False


def _now() -> datetime:
    return datetime.now(timezone.utc)


def create_access_token(settings: Settings, user_id: uuid.UUID) -> str:
    """Emite um access token HS256 (``type=access``, ``sub``, ``iat``, ``exp``)."""
    now = _now()
    payload = {
        "sub": str(user_id),
        "type": "access",
        "iat": now,
        "exp": now + timedelta(seconds=settings.access_token_ttl_seconds),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


@dataclass(frozen=True)
class RefreshToken:
    """Refresh emitido: o JWT + identificadores persistidos (nunca o token)."""

    token: str
    jti: uuid.UUID
    expires_at: datetime


def create_refresh_token(settings: Settings, user_id: uuid.UUID) -> RefreshToken:
    """Emite um refresh token HS256 (``type=refresh``, ``jti`` único, ``exp``)."""
    now = _now()
    jti = uuid.uuid4()
    expires_at = now + timedelta(seconds=settings.refresh_token_ttl_seconds)
    payload = {
        "sub": str(user_id),
        "type": "refresh",
        "jti": str(jti),
        "iat": now,
        "exp": expires_at,
    }
    token = jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)
    return RefreshToken(token=token, jti=jti, expires_at=expires_at)


def _decode(settings: Settings, token: str) -> dict:
    """Decodifica e valida assinatura/expiração (sem checar ``type``)."""
    try:
        return jwt.decode(
            token, settings.jwt_secret, algorithms=[settings.jwt_algorithm]
        )
    except jwt.ExpiredSignatureError:
        raise AuthError(TOKEN_EXPIRED, TOKEN_EXPIRED_MESSAGE, 401) from None
    except jwt.InvalidTokenError:
        raise AuthError(TOKEN_INVALID, TOKEN_INVALID_MESSAGE, 401) from None
    except Exception:  # noqa: BLE001 — falha inesperada, sanitizada
        raise AuthError(TOKEN_ERROR, TOKEN_ERROR_MESSAGE, 500) from None


def decode_access_token(settings: Settings, token: str) -> uuid.UUID:
    """Valida um access token e retorna o ``sub`` (UUID do usuário).

    ``type != "access"`` → ``401 UNAUTHORIZED`` (refresh não pode ser access).
    """
    payload = _decode(settings, token)
    if payload.get("type") != "access":
        raise AuthError(UNAUTHORIZED, UNAUTHORIZED_MESSAGE, 401)
    sub = payload.get("sub")
    if not sub:
        raise AuthError(TOKEN_INVALID, TOKEN_INVALID_MESSAGE, 401)
    try:
        return uuid.UUID(str(sub))
    except (ValueError, TypeError):
        raise AuthError(TOKEN_INVALID, TOKEN_INVALID_MESSAGE, 401) from None


def decode_refresh_token(settings: Settings, token: str) -> uuid.UUID:
    """Valida um refresh token e retorna o ``jti`` (UUID persistido).

    ``type != "refresh"`` → ``401 TOKEN_INVALID`` (access não pode ser refresh).
    """
    payload = _decode(settings, token)
    if payload.get("type") != "refresh":
        raise AuthError(TOKEN_INVALID, TOKEN_INVALID_MESSAGE, 401)
    jti = payload.get("jti")
    if not jti or not payload.get("sub"):
        raise AuthError(TOKEN_INVALID, TOKEN_INVALID_MESSAGE, 401)
    try:
        return uuid.UUID(str(jti))
    except (ValueError, TypeError):
        raise AuthError(TOKEN_INVALID, TOKEN_INVALID_MESSAGE, 401) from None
