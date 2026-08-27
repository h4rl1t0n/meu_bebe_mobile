"""Modelo ``HistoricoObstetrico`` — histórico obstétrico (FASE 8E).

Representa o histórico obstétrico da ``Gestante`` numa relação 1—1. É um
AGREGADO SIMPLES de três contagens opcionais — número de gestações anteriores,
de partos e de abortos — fiel ao ``PreviousPregnancy`` do Flutter (o único dado
realmente coletado/exibido/editado no app). NÃO há enums, datas civis nem
strings: apenas três inteiros opcionais.

NÃO duplica dados de GESTAÇÃO (DUM, local pré-natal, profissional, contato,
ended_at) nem consultas/exames/medicamentos/vacinas/plano de parto/DSS/ML.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base
from ._common import utc_now


class HistoricoObstetrico(Base):
    __tablename__ = "historicos_obstetricos"

    # UUID v4 gerado NO SERVIDOR (Python) — nunca ``gen_random_uuid()``.
    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    # FK UNIQUE → gestantes.id: garante o 1—1 com GESTANTE e o ownership.
    gestante_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("gestantes.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )
    # Número de vezes que já ficou grávida (opcional; >= 0 no contrato).
    pregnancy_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    # Número de vezes que já teve parto (opcional).
    given_birth_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    # Número de abortos que já teve (opcional).
    abortions_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now, onupdate=utc_now
    )
