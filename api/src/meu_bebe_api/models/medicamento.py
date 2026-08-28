"""Modelo ``Medicamento`` — medicamento de uso na gestação (FASE 8G).

Representa um medicamento vinculado a uma ``Gestacao`` (1—N). Fiel ao
``Medication`` do Flutter: apenas ``name``, ``dose`` e ``medicationTime`` (texto
livre, ex.: "6 em 6 horas") — os únicos campos coletados/exibidos/persistidos.

NÃO há posologia estruturada, prescrição médica, período, horário, lembrete nem
datas: o medicamento é um registro simples de NOME + DOSE + FREQUÊNCIA (texto
livre). NÃO duplica GESTAÇÃO nem VACINA.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base
from ._common import utc_now


class Medicamento(Base):
    __tablename__ = "medicamentos"

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
    # ``name`` do Flutter — nome do medicamento (obrigatório).
    nome: Mapped[str] = mapped_column(String(255), nullable=False)
    # ``dose`` do Flutter — dose (texto livre, ex.: "500mg").
    dose: Mapped[str] = mapped_column(String(255), nullable=False)
    # ``medicationTime`` do Flutter — frequência/intervalo (ex.: "6 em 6 horas").
    frequencia: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now, onupdate=utc_now
    )
