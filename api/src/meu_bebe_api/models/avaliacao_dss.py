"""Modelo ``AvaliacaoDss`` — snapshot imutável do questionário DSS (FASE 8I).

Persistência OPERACIONAL das respostas do questionário DSS (``FormularioData``
do Flutter), vinculada à gestação autenticada (GESTAÇÃO 1—N AVALIAÇÃO_DSS).

Cada envio é um SNAPSHOT HISTÓRICO IMATÁVEL do questionário num dado momento
(append-only): NÃO sobrescreve avaliações anteriores. Por isso NÃO há
``updated_at`` — o recurso é criado uma vez e nunca editado/removido.

As 48 respostas são persistidas como JSONB (``respostas``) — o dump JSON do
payload canônico ``DssPayload`` (6 dimensões, SEM o ``schema_version`` do
envelope, que fica na coluna própria). Não se persiste Pydantic internals nem
objetos Python: somente null/bool/number/string/listas do schema 1.13.

NÃO mistura com o dataset científico/experimental da IA: aqui NÃO há
``descontinuou_pre_natal`` (target), P(Random Forest), IV-DSS, threshold nem
classe de risco. A estimativa continua sendo o ``/risk-estimate`` (stateless).
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, ForeignKey, String, Uuid
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base
from ._common import utc_now


class AvaliacaoDss(Base):
    __tablename__ = "avaliacoes_dss"

    # UUID v4 gerado NO SERVIDOR (Python) — nunca ``gen_random_uuid()``.
    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    # FK → gestacoes.id: 1—N e ownership via gestação. CASCADE + índice (lista).
    gestacao_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("gestacoes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    # Versão do schema de dados do snapshot ("1.13") — validada pelo contrato.
    schema_version: Mapped[str] = mapped_column(String(16), nullable=False)
    # Snapshot canônico (6 dimensões / 48 variáveis) — JSONB nativo do PostgreSQL.
    respostas: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    # Data/hora SERVIDOR do momento da persistência (nunca do cliente).
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now
    )
