"""Modelo ``User`` — identidade e autenticação (FASE 8C).

Somente identidade/autenticação: id, e-mail normalizado, hash de senha
(Argon2id), flag de atividade e timestamps. NENHUM dado pessoal/obstétrico —
esses pertencerão a ``GESTANTE`` (fase posterior), numa relação USER 1—1
GESTANTE (seção 3 do plano).
"""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base
from ._common import utc_now


class User(Base):
    __tablename__ = "users"

    # UUID v4 gerado NO SERVIDOR (Python) — nunca ``gen_random_uuid()``.
    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    # E-mail normalizado (strip().lower()) e UNIQUE (constraint uq_users_email).
    email: Mapped[str] = mapped_column(String(320), nullable=False, unique=True)
    # String PHC Argon2id (nunca senha em claro).
    password_hash: Mapped[str] = mapped_column(Text, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now, onupdate=utc_now
    )
