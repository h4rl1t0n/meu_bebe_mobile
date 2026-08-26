"""Repositories de acesso a dados (FASE 8C).

Os repositories NÃO fazem ``commit`` — apenas queries/ORM na ``Session``. O
``commit``/``rollback`` é responsabilidade exclusiva do service (arquitetura 8B).
"""

from __future__ import annotations

from .auth_refresh_session_repository import AuthRefreshSessionRepository
from .gestacao_repository import GestacaoRepository
from .gestante_repository import GestanteRepository
from .user_repository import UserRepository

__all__ = [
    "UserRepository",
    "AuthRefreshSessionRepository",
    "GestanteRepository",
    "GestacaoRepository",
]
