"""Repository de ``AuthRefreshSession`` (FASE 8C) — SEM ``commit``."""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models.auth_refresh_session import AuthRefreshSession


class AuthRefreshSessionRepository:
    """Acesso a dados de ``auth_refresh_sessions``. Nenhum método committa."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def find_by_jti(self, jti: uuid.UUID) -> AuthRefreshSession | None:
        return self._session.scalar(
            select(AuthRefreshSession).where(AuthRefreshSession.jti == jti)
        )

    def add(self, session_obj: AuthRefreshSession) -> AuthRefreshSession:
        self._session.add(session_obj)
        return session_obj

    def revoke(self, session_obj: AuthRefreshSession, now: datetime) -> None:
        """Marca a sessão como revogada (mutação in-place; sem commit)."""
        session_obj.revoked_at = now
