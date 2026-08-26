"""Modelo ``Gestante`` — perfil pessoal (FASE 8D).

Representa a PESSOA física vinculada a um ``USER`` numa relação 1—1. Somente
dados de perfil: nome, nome social, nascimento, CPF e CNS. NENHUM dado de
autenticação (e-mail/senha) nem de logística do pré-natal (local/profissional/
contato) — esses pertencem a ``USER`` e a ``GESTAÇÃO``, respectivamente.

NÃO há campo de telefone pessoal: o ``UserData.phone`` legado do Flutter é código
morto (nunca coletado/exibido/editado) e o único telefone real é o
``contato_local_pre_natal`` de ``GESTAÇÃO`` (logística).
"""

from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base
from ._common import utc_now


class Gestante(Base):
    __tablename__ = "gestantes"

    # UUID v4 gerado NO SERVIDOR (Python) — nunca ``gen_random_uuid()``.
    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    # FK UNIQUE → users.id: garante o 1—1 com USER e o ownership.
    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )
    nome: Mapped[str] = mapped_column(String(255), nullable=False)
    nome_social: Mapped[str | None] = mapped_column(String(255), nullable=True)
    # DATE (não datetime): é uma data de calendário, não um instante.
    data_nascimento: Mapped[date] = mapped_column(Date, nullable=False)
    # Somente dígitos, 11 quando informado. NÃO unique, NÃO PK, NÃO login.
    cpf: Mapped[str | None] = mapped_column(String(11), nullable=True)
    # Somente dígitos, 15 quando informado. NÃO unique.
    cns: Mapped[str | None] = mapped_column(String(15), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now, onupdate=utc_now
    )
