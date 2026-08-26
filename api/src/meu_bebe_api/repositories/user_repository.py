"""Repository de ``User`` (FASE 8C) — SEM ``commit``."""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models.user import User


class UserRepository:
    """Acesso a dados de ``users``. Nenhum método committa."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def find_by_email(self, email: str) -> User | None:
        """Busca por e-mail normalizado (``strip().lower()`` já aplicado)."""
        return self._session.scalar(select(User).where(User.email == email))

    def find_by_id(self, user_id: uuid.UUID) -> User | None:
        return self._session.get(User, user_id)

    def add(self, user: User) -> User:
        """Registra o ``User`` na sessão (pendente; sem flush/commit)."""
        self._session.add(user)
        return user
