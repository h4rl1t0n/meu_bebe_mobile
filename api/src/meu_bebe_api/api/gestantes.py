"""Rotas de ``GESTANTE`` — prefixo ``/gestantes/me`` (FASE 8D, seção 12).

Três rotas, todas sob ``/me`` (a gestante só acessa o próprio perfil; não há
admin nem acesso a outra usuária). O ``user_id`` é derivado do token, nunca do
body. Não há rota ``/{id}`` de gestante.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.orm import Session

from ..auth.dependencies import get_auth_session, get_current_user
from ..contracts.errors import ErrorResponse
from ..contracts.gestante import GestanteResponse, GestanteWrite
from ..domain.dependencies import get_current_gestante
from ..domain.services import GestanteService
from ..models.gestante import Gestante
from ..models.user import User

router = APIRouter(tags=["Gestante"], prefix="/gestantes")


@router.post(
    "/me",
    status_code=status.HTTP_201_CREATED,
    response_model=GestanteResponse,
    summary="Criar o perfil de gestante do usuário autenticado",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        409: {"model": ErrorResponse, "description": "Perfil já cadastrado."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def create_gestante(
    payload: GestanteWrite,
    request: Request,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_auth_session),
) -> GestanteResponse:
    gestante = GestanteService(session).create(user.id, payload)
    return GestanteResponse.model_validate(gestante)


@router.get(
    "/me",
    response_model=GestanteResponse,
    summary="Retornar o perfil de gestante do usuário autenticado",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Perfil não encontrado."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def get_gestante(gestante: Gestante = Depends(get_current_gestante)) -> GestanteResponse:
    return GestanteResponse.model_validate(gestante)


@router.put(
    "/me",
    response_model=GestanteResponse,
    summary="Atualizar o perfil de gestante (full update)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Perfil não encontrado."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def update_gestante(
    payload: GestanteWrite,
    gestante: Gestante = Depends(get_current_gestante),
    session: Session = Depends(get_auth_session),
) -> GestanteResponse:
    gestante = GestanteService(session).update(gestante, payload)
    return GestanteResponse.model_validate(gestante)
