"""Dependências de domínio (FASE 8D/8F, seção 14.1).

- ``get_current_gestante``: resolve a ``Gestante`` do usuário autenticado
  (``Bearer access → get_current_user → buscar Gestante por user_id``). Se o USER
  ainda não possui perfil, responde ``404 PROFILE_NOT_FOUND``.
- ``get_owned_gestacao``: resolve a ``Gestacao`` de ``{gestacao_id}`` da rota
  pertencente à gestante autenticada (ownership JWT → USER → GESTANTE →
  GESTAÇÃO). Gestação inexistente OU alheia → ``404 PREGNANCY_NOT_FOUND``
  (indistinto, anti-enumeração).

Reutilizam ``get_current_user`` e ``get_auth_session`` (a mesma ``Session`` é
compartilhada via cache de dependências do FastAPI).
"""

from __future__ import annotations

import uuid

from fastapi import Depends
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

from ..auth.dependencies import get_auth_session, get_current_user
from ..models.gestacao import Gestacao
from ..models.gestante import Gestante
from ..models.user import User
from ..repositories.gestacao_repository import GestacaoRepository
from ..repositories.gestante_repository import GestanteRepository
from .errors import (
    DATABASE_UNAVAILABLE,
    DATABASE_UNAVAILABLE_MESSAGE,
    PREGNANCY_NOT_FOUND,
    PREGNANCY_NOT_FOUND_MESSAGE,
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


def get_owned_gestacao(
    gestacao_id: uuid.UUID,
    gestante: Gestante = Depends(get_current_gestante),
    session: Session = Depends(get_auth_session),
) -> Gestacao:
    """Resolve a ``Gestacao`` de ``gestacao_id`` pertencente à gestante (404 se alheia)."""
    try:
        gestacao = GestacaoRepository(session).find_by_id_and_gestante(
            gestacao_id, gestante.id
        )
    except OperationalError:
        raise DomainError(
            DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
        ) from None
    if gestacao is None:
        raise DomainError(PREGNANCY_NOT_FOUND, PREGNANCY_NOT_FOUND_MESSAGE, 404)
    return gestacao
