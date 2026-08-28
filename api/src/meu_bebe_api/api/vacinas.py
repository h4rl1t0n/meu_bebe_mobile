"""Rotas de ``VACINA`` — lista aninhada na gestação (FASE 8G).

Quatro rotas sob ``/gestacoes/{gestacao_id}/vacinas``: criar, listar, obter e
editar. NÃO há DELETE: o Flutter não permite remover vacina (o ``deleteVaccine``
do repositório Flutter é código morto — o checklist só alterna ``aplicada`` via
PUT). O ``gestacao_id`` vem da rota e é validado por ownership via
``get_owned_gestacao`` (JWT → USER → GESTANTE → GESTAÇÃO); nunca é aceito do
body.
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from ..auth.dependencies import get_auth_session
from ..contracts.errors import ErrorResponse
from ..contracts.vacina import VacinaResponse, VacinaWrite
from ..domain.dependencies import get_owned_gestacao
from ..domain.services import VacinaService
from ..models.gestacao import Gestacao

router = APIRouter(
    tags=["Vacina"],
    prefix="/gestacoes/{gestacao_id}/vacinas",
)


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=VacinaResponse,
    summary="Criar uma vacina para a gestação",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Gestação inexistente ou de outra usuária."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def create_vacina(
    payload: VacinaWrite,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> VacinaResponse:
    vacina = VacinaService(session).create(gestacao.id, payload)
    return VacinaResponse.model_validate(vacina)


@router.get(
    "",
    response_model=list[VacinaResponse],
    summary="Listar as vacinas da gestação",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Gestação inexistente ou de outra usuária."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def list_vacinas(
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> list[VacinaResponse]:
    vacinas = VacinaService(session).list(gestacao.id)
    return [VacinaResponse.model_validate(v) for v in vacinas]


@router.get(
    "/{vacina_id}",
    response_model=VacinaResponse,
    summary="Obter uma vacina (ownership-checked)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Vacina/gestação inexistente ou alheia."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def get_vacina(
    vacina_id: uuid.UUID,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> VacinaResponse:
    vacina = VacinaService(session).get(gestacao.id, vacina_id)
    return VacinaResponse.model_validate(vacina)


@router.put(
    "/{vacina_id}",
    response_model=VacinaResponse,
    summary="Editar uma vacina (ownership-checked; alterna aplicada)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Vacina/gestação inexistente ou alheia."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def update_vacina(
    vacina_id: uuid.UUID,
    payload: VacinaWrite,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> VacinaResponse:
    vacina = VacinaService(session).update(gestacao.id, vacina_id, payload)
    return VacinaResponse.model_validate(vacina)
