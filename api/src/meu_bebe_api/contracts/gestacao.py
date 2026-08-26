"""Contratos do domínio ``GESTAÇÃO`` (FASE 8D) — escrita e resposta.

A entrada NUNCA contém ``id``, ``gestante_id``, ``user_id`` nem timestamps (o
vínculo é derivado do token). ``ended_at`` é campo de ESCRITA (mecanismo de
conclusão): no POST nasce ``NULL`` (ativa); no PUT pode ir de ``NULL`` →
timestamp (ATIVA→ENCERRADA). A reabertura (timestamp → ``NULL``) é PROIBIDA e é
validada no service. NÃO há ``data_primeira_ultrassom`` (exame → FASE 8F).
"""

from __future__ import annotations

import uuid
from datetime import date, datetime, timezone

from pydantic import BaseModel, ConfigDict, Field, field_validator


class GestacaoWrite(BaseModel):
    """Payload de escrita de ``GESTAÇÃO`` (POST e PUT — full update)."""

    model_config = ConfigDict(extra="forbid")

    data_ultima_menstruacao: date | None = None
    local_pre_natal: str | None = Field(default=None, max_length=255)
    profissional_pre_natal: str | None = Field(default=None, max_length=255)
    contato_local_pre_natal: str | None = Field(default=None, max_length=64)
    ended_at: datetime | None = None

    @field_validator("local_pre_natal", "profissional_pre_natal", "contato_local_pre_natal")
    @classmethod
    def _strip_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return value.strip()

    @field_validator("data_ultima_menstruacao")
    @classmethod
    def _not_future(cls, value: date | None) -> date | None:
        if value is not None and value > date.today():
            raise ValueError("Data da última menstruação não pode estar no futuro.")
        return value

    @field_validator("ended_at")
    @classmethod
    def _ensure_timezone_aware(cls, value: datetime | None) -> datetime | None:
        if value is not None and value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value


class GestacaoResponse(BaseModel):
    """Resposta segura de ``GESTAÇÃO`` (sem ``gestante_id`` alheio)."""

    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: uuid.UUID
    data_ultima_menstruacao: date | None
    local_pre_natal: str | None
    profissional_pre_natal: str | None
    contato_local_pre_natal: str | None
    ended_at: datetime | None
    created_at: datetime
    updated_at: datetime
