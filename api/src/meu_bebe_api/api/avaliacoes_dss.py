"""Rotas de ``AVALIAÇÃO DSS`` — snapshot imutável por gestação (FASE 8I).

Três rotas sob ``/gestacoes/{gestacao_id}/avaliacoes-dss``: criar (POST), listar
(GET) e obter (GET item). A avaliação enviada é um SNAPSHOT HISTÓRICO IMATÁVEL
(append-only): NÃO há PUT nem DELETE — preserva-se o histórico das respostas.

A ESCRITA reutiliza o contrato canônico ``DssPayload`` (o MESMO do
``/risk-estimate``), então o POST aceita exatamente ``FormularioData.toMap()``.
NÃO interage com o Random Forest: a estimativa continua stateless no
``/risk-estimate``. O ``gestacao_id`` vem da rota, validado por ownership via
``get_owned_gestacao`` (JWT → USER → GESTANTE → GESTAÇÃO); nunca do body.
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from ..auth.dependencies import get_auth_session
from ..contracts.avaliacao_dss import AvaliacaoDssResponse
from ..contracts.dss import DssPayload
from ..contracts.errors import ErrorResponse
from ..domain.dependencies import get_owned_gestacao
from ..domain.services import AvaliacaoDssService
from ..models.gestacao import Gestacao

router = APIRouter(
    tags=["Avaliação DSS"],
    prefix="/gestacoes/{gestacao_id}/avaliacoes-dss",
)


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=AvaliacaoDssResponse,
    summary="Registrar um snapshot da avaliação DSS da gestação",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Gestação inexistente ou de outra usuária."},
        422: {"model": ErrorResponse, "description": "Payload DSS inválido."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def create_avaliacao_dss(
    payload: DssPayload,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> AvaliacaoDssResponse:
    avaliacao = AvaliacaoDssService(session).create(gestacao.id, payload)
    return AvaliacaoDssResponse.model_validate(avaliacao)


@router.get(
    "",
    response_model=list[AvaliacaoDssResponse],
    summary="Listar as avaliações DSS da gestação (mais recente primeiro)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Gestação inexistente ou de outra usuária."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def list_avaliacoes_dss(
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> list[AvaliacaoDssResponse]:
    avaliacoes = AvaliacaoDssService(session).list(gestacao.id)
    return [AvaliacaoDssResponse.model_validate(a) for a in avaliacoes]


@router.get(
    "/{avaliacao_id}",
    response_model=AvaliacaoDssResponse,
    summary="Obter uma avaliação DSS (ownership-checked)",
    responses={
        401: {"model": ErrorResponse, "description": "Access ausente/inválido/expirado."},
        404: {"model": ErrorResponse, "description": "Avaliação/gestação inexistente ou alheia."},
        503: {"model": ErrorResponse, "description": "Auth não configurada / DB indisponível."},
    },
)
def get_avaliacao_dss(
    avaliacao_id: uuid.UUID,
    gestacao: Gestacao = Depends(get_owned_gestacao),
    session: Session = Depends(get_auth_session),
) -> AvaliacaoDssResponse:
    avaliacao = AvaliacaoDssService(session).get(gestacao.id, avaliacao_id)
    return AvaliacaoDssResponse.model_validate(avaliacao)
