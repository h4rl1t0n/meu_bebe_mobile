"""Modelo ``Consulta`` — consulta de pré-natal (FASE 8F).

Representa uma consulta (appointment) vinculada a uma ``Gestacao`` (1—N). Fiel ao
``Appointment`` do Flutter: apenas ``title``, ``appointmentDate`` (data civil) e
``description`` — os únicos campos realmente coletados/exibidos/editados no app.
NÃO há enums nem ``categoria`` (consulta não tem tipo).

NÃO duplica GESTAÇÃO nem EXAME.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base
from ._common import utc_now


class Consulta(Base):
    __tablename__ = "consultas"

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
    # DATE (não datetime): data de calendário da consulta, não um instante.
    data_consulta: Mapped[date] = mapped_column(Date, nullable=False)
    descricao: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now, onupdate=utc_now
    )
