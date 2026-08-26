"""Modelo ``Gestacao`` — episódio gestacional (FASE 8D).

Representa um EPISÓDIO de gestação vinculado a uma ``Gestante`` (1—N). Carrega a
DUM (base de IG/DPP, que NÃO são persistidos) e a logística do pré-natal. O
``ended_at`` é o mecanismo de estado: NULL = ativa, NOT NULL = encerrada.

NÃO há ``data_primeira_ultrassom`` (é exame → FASE 8F), nem ``status`` enum, nem
IG/DPP persistidos.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import (
    Date,
    DateTime,
    ForeignKey,
    Index,
    String,
    Uuid,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base
from ._common import utc_now


class Gestacao(Base):
    __tablename__ = "gestacoes"

    # Índice único PARCIAL: no máximo UMA gestação ativa (``ended_at IS NULL``)
    # por gestante, garantido no banco (backstop contra corrida).
    __table_args__ = (
        Index(
            "uq_gestacoes_active_per_gestante",
            "gestante_id",
            unique=True,
            postgresql_where=text("ended_at IS NULL"),
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    gestante_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("gestantes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    # DATE nullable; base de IG/DPP (derivados, não persistidos).
    data_ultima_menstruacao: Mapped[date | None] = mapped_column(Date, nullable=True)
    local_pre_natal: Mapped[str | None] = mapped_column(String(255), nullable=True)
    profissional_pre_natal: Mapped[str | None] = mapped_column(String(255), nullable=True)
    contato_local_pre_natal: Mapped[str | None] = mapped_column(String(64), nullable=True)
    # NULL = ativa/atual; NOT NULL = encerrada (mecanismo de estado — seção 9).
    ended_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now, onupdate=utc_now
    )
