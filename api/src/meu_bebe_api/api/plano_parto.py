"""Rotas de ``PLANO DE PARTO`` — singleton por gestação (FASE 8H).

Duas rotas (GET/PUT) sobre o recurso SINGLETON da gestação, em
``/gestacoes/{gestacao_id}/plano-de-parto``. Não há rota ``/{id}``: o plano é
1—0..1 com a gestação e o ``gestacao_id`` vem da rota, validado por ownership via
``get_owned_gestacao`` (JWT → USER → GESTANTE → GESTAÇÃO) — nunca do body.

``PUT`` é UPSERT (cria se ausente, atualiza se existente), como o Histórico
Obstétrico. Não há POST separado nem DELETE: o app nunca remove o plano.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..auth.dependencies import get_auth_session
from ..contracts.errors import ErrorResponse
from ..contracts.plano_parto import PlanoPartoResponse, PlanoPartoWrite
from ..domain.dependencies import get_owned_gestacao
from ..domain.services import PlanoPartoService
from ..models.gestacao import Gestacao

router = APIRouter(
    tags=["Plano de Parto"],
    prefix="/gestacoes/{gestacao_id}/plano-de-parto",
)


@router.get(
    "",
    response_model=PlanoPartoResponse,
    summary="Retornar o plano de parto da gestação autenticada",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Gestação ou plano não encontrado."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def get_plano_parto(
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> PlanoPartoResponse:
    plano = PlanoPartoService(session).get(gestacao.id)
    return PlanoPartoResponse.model_validate(plano)


@router.put(
    "",
    response_model=PlanoPartoResponse,
    summary="Criar ou atualizar o plano de parto (upsert do singleton)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Gestação inexistente ou de outra usuária."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def upsert_plano_parto(
    payload: PlanoPartoWrite,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> PlanoPartoResponse:
    plano = PlanoPartoService(session).upsert(gestacao.id, payload)
    return PlanoPartoResponse.model_validate(plano)
