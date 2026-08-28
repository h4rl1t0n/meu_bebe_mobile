"""Rotas de ``EXAME`` — lista aninhada na gestação (FASE 8F).

Cinco rotas sob ``/gestacoes/{gestacao_id}/exames``: criar, listar, obter,
editar e excluir (DELETE físico — o Flutter realmente permite remover exame). O
``gestacao_id`` vem da rota e é validado por ownership via ``get_owned_gestacao``
(JWT → USER → GESTANTE → GESTAÇÃO); nunca é aceito do body. A 1ª ultrassonografia
legada é representada como um EXAME (ex.: ``categoria="ultrassom"``).
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from ..auth.dependencies import get_auth_session
from ..contracts.errors import ErrorResponse
from ..contracts.exame import ExameResponse, ExameWrite
from ..domain.dependencies import get_owned_gestacao
from ..domain.services import ExameService
from ..models.gestacao import Gestacao

router = APIRouter(
    tags=["Exame"],
    prefix="/gestacoes/{gestacao_id}/exames",
)


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=ExameResponse,
    summary="Criar um exame para a gestação",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Gestação inexistente ou de outra usuária."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def create_exame(
    payload: ExameWrite,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> ExameResponse:
    exame = ExameService(session).create(gestacao.id, payload)
    return ExameResponse.model_validate(exame)


@router.get(
    "",
    response_model=list[ExameResponse],
    summary="Listar os exames da gestação",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Gestação inexistente ou de outra usuária."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def list_exames(
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> list[ExameResponse]:
    exames = ExameService(session).list(gestacao.id)
    return [ExameResponse.model_validate(e) for e in exames]


@router.get(
    "/{exame_id}",
    response_model=ExameResponse,
    summary="Obter um exame (ownership-checked)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Exame/gestação inexistente ou alheio."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def get_exame(
    exame_id: uuid.UUID,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> ExameResponse:
    exame = ExameService(session).get(gestacao.id, exame_id)
    return ExameResponse.model_validate(exame)


@router.put(
    "/{exame_id}",
    response_model=ExameResponse,
    summary="Editar um exame (ownership-checked)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Exame/gestação inexistente ou alheio."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def update_exame(
    exame_id: uuid.UUID,
    payload: ExameWrite,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> ExameResponse:
    exame = ExameService(session).update(gestacao.id, exame_id, payload)
    return ExameResponse.model_validate(exame)


@router.delete(
    "/{exame_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Excluir um exame (ownership-checked; DELETE físico)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Exame/gestação inexistente ou alheio."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def delete_exame(
    exame_id: uuid.UUID,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> None:
    ExameService(session).delete(gestacao.id, exame_id)
