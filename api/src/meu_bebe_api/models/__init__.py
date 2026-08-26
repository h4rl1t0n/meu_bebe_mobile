"""Modelos ORM de domínio (FASE 8C).

Importar este pacote registra as tabelas em ``Base.metadata`` (usado pelo
Alembic como ``target_metadata``). Mantenha os imports dos models aqui.
"""

from __future__ import annotations

from .auth_refresh_session import AuthRefreshSession
from .user import User

__all__ = ["User", "AuthRefreshSession"]
