"""Rotas de ``CONSULTA`` — lista aninhada na gestação (FASE 8F).

Cinco rotas sob ``/gestacoes/{gestacao_id}/consultas``: criar, listar, obter,
editar e excluir (DELETE físico — o Flutter realmente permite remover consulta).
O ``gestacao_id`` vem da rota e é validado por ownership via ``get_owned_gestacao``
(JWT → USER → GESTANTE → GESTAÇÃO); nunca é aceito do body.
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from ..auth.dependencies import get_auth_session
from ..contracts.consulta import ConsultaResponse, ConsultaWrite
from ..contracts.errors import ErrorResponse
from ..domain.dependencies import get_owned_gestacao
from ..domain.services import ConsultaService
from ..models.gestacao import Gestacao

router = APIRouter(
    tags=["Consulta"],
    prefix="/gestacoes/{gestacao_id}/consultas",
)


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=ConsultaResponse,
    summary="Criar uma consulta para a gestação",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Gestação inexistente ou de outra usuária."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def create_consulta(
    payload: ConsultaWrite,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> ConsultaResponse:
    consulta = ConsultaService(session).create(gestacao.id, payload)
    return ConsultaResponse.model_validate(consulta)


@router.get(
    "",
    response_model=list[ConsultaResponse],
    summary="Listar as consultas da gestação",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Gestação inexistente ou de outra usuária."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def list_consultas(
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> list[ConsultaResponse]:
    consultas = ConsultaService(session).list(gestacao.id)
    return [ConsultaResponse.model_validate(c) for c in consultas]


@router.get(
    "/{consulta_id}",
    response_model=ConsultaResponse,
    summary="Obter uma consulta (ownership-checked)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Consulta/gestação inexistente ou alheia."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def get_consulta(
    consulta_id: uuid.UUID,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> ConsultaResponse:
    consulta = ConsultaService(session).get(gestacao.id, consulta_id)
    return ConsultaResponse.model_validate(consulta)


@router.put(
    "/{consulta_id}",
    response_model=ConsultaResponse,
    summary="Editar uma consulta (ownership-checked)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Consulta/gestação inexistente ou alheia."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def update_consulta(
    consulta_id: uuid.UUID,
    payload: ConsultaWrite,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> ConsultaResponse:
    consulta = ConsultaService(session).update(gestacao.id, consulta_id, payload)
    return ConsultaResponse.model_validate(consulta)


@router.delete(
    "/{consulta_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Excluir uma consulta (ownership-checked; DELETE físico)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Consulta/gestação inexistente ou alheia."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def delete_consulta(
    consulta_id: uuid.UUID,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> None:
    ConsultaService(session).delete(gestacao.id, consulta_id)
