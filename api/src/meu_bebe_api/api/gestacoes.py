"""Rotas de ``GESTAÇÃO`` — prefixo ``/gestacoes`` (FASE 8D, seção 13).

Cinco rotas: criar, listar, obter a atual, detalhar e editar (com ownership).
A rota ``/atual`` é declarada ANTES de ``/{gestacao_id}`` para não ser capturada
pelo path param. O ``gestante_id`` é derivado do token (via ``get_current_gestante``),
nunca do body.
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from ..auth.dependencies import get_auth_session
from ..contracts.errors import ErrorResponse
from ..contracts.gestacao import GestacaoResponse, GestacaoWrite
from ..domain.dependencies import get_current_gestante
from ..domain.services import GestacaoService
from ..models.gestante import Gestante

router = APIRouter(tags=["Gestação"], prefix="/gestacoes")


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=GestacaoResponse,
    summary="Criar uma gestação ativa para a gestante autenticada",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Perfil não encontrado."},
        409: {"model": ErrorResponse, "description": "Já existe gestação ativa."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def create_gestacao(
    payload: GestacaoWrite,
    gestante: Gestante = Depends(get_current_gestante),
    session: Session = Depends(get_auth_session),
) -> GestacaoResponse:
    gestacao = GestacaoService(session).create(gestante.id, payload)
    return GestacaoResponse.model_validate(gestacao)


@router.get(
    "",
    response_model=list[GestacaoResponse],
    summary="Listar as gestações da gestante autenticada",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Perfil não encontrado."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def list_gestacoes(
    gestante: Gestante = Depends(get_current_gestante),
    session: Session = Depends(get_auth_session),
) -> list[GestacaoResponse]:
    gestacoes = GestacaoService(session).list_gestacoes(gestante.id)
    return [GestacaoResponse.model_validate(g) for g in gestacoes]


@router.get(
    "/atual",
    response_model=GestacaoResponse,
    summary="Retornar a gestação ativa da gestante autenticada",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Perfil não encontrado / sem gestação ativa."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def get_gestacao_atual(
    gestante: Gestante = Depends(get_current_gestante),
    session: Session = Depends(get_auth_session),
) -> GestacaoResponse:
    gestacao = GestacaoService(session).get_atual(gestante.id)
    return GestacaoResponse.model_validate(gestacao)


@router.get(
    "/{gestacao_id}",
    response_model=GestacaoResponse,
    summary="Detalhar uma gestação (ownership-checked)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Gestação inexistente ou de outra usuária."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def get_gestacao(
    gestacao_id: uuid.UUID,
    gestante: Gestante = Depends(get_current_gestante),
    session: Session = Depends(get_auth_session),
) -> GestacaoResponse:
    gestacao = GestacaoService(session).get_by_id(gestante.id, gestacao_id)
    return GestacaoResponse.model_validate(gestacao)


@router.put(
    "/{gestacao_id}",
    response_model=GestacaoResponse,
    summary="Editar uma gestação (ownership-checked; permite encerrar)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Gestação inexistente ou de outra usuária."},
        409: {"model": ErrorResponse, "description": "Reabertura de gestação encerrada proibida."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def update_gestacao(
    gestacao_id: uuid.UUID,
    payload: GestacaoWrite,
    gestante: Gestante = Depends(get_current_gestante),
    session: Session = Depends(get_auth_session),
) -> GestacaoResponse:
    gestacao = GestacaoService(session).update(gestante.id, gestacao_id, payload)
    return GestacaoResponse.model_validate(gestacao)
