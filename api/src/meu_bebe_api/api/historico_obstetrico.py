"""Rotas de ``HISTÓRICO OBSTÉTRICO`` — singleton (FASE 8E).

Duas rotas (GET/PUT) sobre o recurso SINGLETON da gestante, em
``/gestantes/me/historico-obstetrico``. Não há rota ``/{id}``: o histórico é
1—1 com a gestante e o ``gestante_id`` é derivado do token (via
``get_current_gestante``), nunca do body.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..auth.dependencies import get_auth_session
from ..contracts.errors import ErrorResponse
from ..contracts.historico_obstetrico import (
    HistoricoObstetricoResponse,
    HistoricoObstetricoWrite,
)
from ..domain.dependencies import get_current_gestante
from ..domain.services import HistoricoObstetricoService
from ..models.gestante import Gestante

router = APIRouter(
    tags=["Histórico Obstétrico"],
    prefix="/gestantes/me/historico-obstetrico",
)


@router.get(
    "",
    response_model=HistoricoObstetricoResponse,
    summary="Retornar o histórico obstétrico da gestante autenticada",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Perfil ou histórico não encontrado."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def get_historico_obstetrico(
    gestante: Gestante = Depends(get_current_gestante),
    session: Session = Depends(get_auth_session),
) -> HistoricoObstetricoResponse:
    historico = HistoricoObstetricoService(session).get(gestante.id)
    return HistoricoObstetricoResponse.model_validate(historico)


@router.put(
    "",
    response_model=HistoricoObstetricoResponse,
    summary="Criar ou atualizar o histórico obstétrico (upsert do singleton)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Perfil não encontrado."},
        422: {"model": ErrorResponse, "description": "Payload inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def upsert_historico_obstetrico(
    payload: HistoricoObstetricoWrite,
    gestante: Gestante = Depends(get_current_gestante),
    session: Session = Depends(get_auth_session),
) -> HistoricoObstetricoResponse:
    historico = HistoricoObstetricoService(session).upsert(gestante.id, payload)
    return HistoricoObstetricoResponse.model_validate(historico)
