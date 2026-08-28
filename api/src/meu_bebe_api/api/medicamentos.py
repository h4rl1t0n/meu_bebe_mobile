"""Rotas de ``MEDICAMENTO`` — lista aninhada na gestação (FASE 8G).

Cinco rotas sob ``/gestacoes/{gestacao_id}/medicamentos``: criar, listar, obter,
editar e excluir (DELETE físico — o Flutter realmente permite remover
medicamento). O ``gestacao_id`` vem da rota e é validado por ownership via
``get_owned_gestacao`` (JWT → USER → GESTANTE → GESTAÇÃO); nunca é aceito do
body.
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from ..auth.dependencies import get_auth_session
from ..contracts.errors import ErrorResponse
from ..contracts.medicamento import MedicamentoResponse, MedicamentoWrite
from ..domain.dependencies import get_owned_gestacao
from ..domain.services import MedicamentoService
from ..models.gestacao import Gestacao

router = APIRouter(
    tags=["Medicamento"],
    prefix="/gestacoes/{gestacao_id}/medicamentos",
)


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=MedicamentoResponse,
    summary="Criar um medicamento para a gestação",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Gestação inexistente ou de outra usuária."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def create_medicamento(
    payload: MedicamentoWrite,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> MedicamentoResponse:
    medicamento = MedicamentoService(session).create(gestacao.id, payload)
    return MedicamentoResponse.model_validate(medicamento)


@router.get(
    "",
    response_model=list[MedicamentoResponse],
    summary="Listar os medicamentos da gestação",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Gestação inexistente ou de outra usuária."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def list_medicamentos(
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> list[MedicamentoResponse]:
    medicamentos = MedicamentoService(session).list(gestacao.id)
    return [MedicamentoResponse.model_validate(m) for m in medicamentos]


@router.get(
    "/{medicamento_id}",
    response_model=MedicamentoResponse,
    summary="Obter um medicamento (ownership-checked)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Medicamento/gestação inexistente ou alheio."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def get_medicamento(
    medicamento_id: uuid.UUID,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> MedicamentoResponse:
    medicamento = MedicamentoService(session).get(gestacao.id, medicamento_id)
    return MedicamentoResponse.model_validate(medicamento)


@router.put(
    "/{medicamento_id}",
    response_model=MedicamentoResponse,
    summary="Editar um medicamento (ownership-checked)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Medicamento/gestação inexistente ou alheio."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def update_medicamento(
    medicamento_id: uuid.UUID,
    payload: MedicamentoWrite,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> MedicamentoResponse:
    medicamento = MedicamentoService(session).update(gestacao.id, medicamento_id, payload)
    return MedicamentoResponse.model_validate(medicamento)


@router.delete(
    "/{medicamento_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Excluir um medicamento (ownership-checked; DELETE físico)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Medicamento/gestação inexistente ou alheio."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def delete_medicamento(
    medicamento_id: uuid.UUID,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> None:
    MedicamentoService(session).delete(gestacao.id, medicamento_id)
