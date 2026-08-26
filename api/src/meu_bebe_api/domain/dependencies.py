"""Dependência de domínio ``get_current_gestante`` (FASE 8D, seção 14.1).

Resolve a ``Gestante`` do usuário autenticado: ``Bearer access → get_current_user
→ buscar Gestante por user_id → retornar Gestante``. Se o USER ainda não possui
perfil, responde ``404 PROFILE_NOT_FOUND``. Reutiliza ``get_current_user`` e
``get_auth_session`` (a mesma ``Session`` é compartilhada via cache de
dependências do FastAPI).
"""

from __future__ import annotations

from fastapi import Depends
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

from ..auth.dependencies import get_auth_session, get_current_user
from ..models.gestante import Gestante
from ..models.user import User
from ..repositories.gestante_repository import GestanteRepository
from .errors import (
    DATABASE_UNAVAILABLE,
    DATABASE_UNAVAILABLE_MESSAGE,
    PROFILE_NOT_FOUND,
    PROFILE_NOT_FOUND_MESSAGE,
    DomainError,
)


def get_current_gestante(
    user: User = Depends(get_current_user),
    session: Session = Depends(get_auth_session),
) -> Gestante:
    """Resolve a ``Gestante`` do usuário autenticado (404 se ainda não existir)."""
    try:
        gestante = GestanteRepository(session).find_by_user_id(user.id)
    except OperationalError:
        raise DomainError(
            DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
        ) from None
    if gestante is None:
        raise DomainError(PROFILE_NOT_FOUND, PROFILE_NOT_FOUND_MESSAGE, 404)
    return gestante
