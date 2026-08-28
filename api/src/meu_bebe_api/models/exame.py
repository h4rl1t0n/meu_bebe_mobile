"""Modelo ``Exame`` — exame/ultrassonografia (FASE 8F).

Representa um exame vinculado a uma ``Gestacao`` (1—N). Fiel ao ``Exam`` do
Flutter (``title``, ``examDate``, ``description``) e ainda ao legado
``CurrentPregnancyData.firstUltrasound``, representado aqui via ``categoria``
(string livre, ex.: ``"ultrassom"``) — NÃO há ``data_primeira_ultrassom`` em
GESTAÇÃO (decisão congelada: uma única fonte de verdade).

NÃO há enums nem estrutura clínica complexa.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base
from ._common import utc_now


class Exame(Base):
    __tablename__ = "exames"

    # UUID v4 gerado NO SERVIDOR (Python) — nunca ``gen_random_uuid()``.
    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    # FK → gestacoes.id: 1—N e ownership via gestação. CASCADE (recurso de lista).
    gestacao_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("gestacoes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    titulo: Mapped[str] = mapped_column(String(255), nullable=False)
    # DATE (não datetime): data de calendário do exame, não um instante.
    data_exame: Mapped[date] = mapped_column(Date, nullable=False)
    descricao: Mapped[str] = mapped_column(Text, nullable=False)
    # String livre de identificação de tipo (ex.: "ultrassom" para a 1ª USG).
    # Opcional — o Flutter não coleta categoria; reservada ao mapeamento legado.
    categoria: Mapped[str | None] = mapped_column(String(64), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now, onupdate=utc_now
    )
