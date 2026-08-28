"""Modelo ``Vacina`` — vacina do pré-natal (FASE 8G).

Representa uma vacina vinculada a uma ``Gestacao`` (1—N). Fiel ao
``VaccineData`` do Flutter: ``name`` (código estável, ex.: "HB_1", "dTpa") e
``used`` (booleano "tomada/aplicada"). NÃO há lote, fabricante, data de
aplicação, registro profissional nem catálogo clínico: é um ITEM DE CHECKLIST
com o estado ``aplicada`` (true/false). O catálogo (nomes de exibição e textos
informativos) vive no Flutter, NÃO no banco.

NÃO duplica GESTAÇÃO nem MEDICAMENTO.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base
from ._common import utc_now


class Vacina(Base):
    __tablename__ = "vacinas"

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
    # ``name`` do Flutter — código/nome da vacina (obrigatório).
    nome: Mapped[str] = mapped_column(String(255), nullable=False)
    # ``used`` do Flutter — "tomada/aplicada" (checklist).
    aplicada: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now, onupdate=utc_now
    )
