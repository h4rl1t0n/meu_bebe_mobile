"""Contratos do domínio ``EXAME`` (FASE 8F) — escrita e resposta.

A entrada NUNCA contém ``id``, ``gestacao_id``, ``user_id`` nem timestamps (o
vínculo é derivado da rota ``/gestacoes/{gestacao_id}/exames``, validada por
ownership). ``data_exame`` é ``date`` (data civil), nunca ``dd/MM/yyyy``.
``categoria`` é uma string livre opcional (ex.: ``"ultrassom"``) para o mapeamento
legado da 1ª ultrassonografia. A resposta NÃO ecoa ``gestacao_id``.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class ExameWrite(BaseModel):
    """Payload de escrita de ``EXAME`` (POST e PUT — full update)."""

    model_config = ConfigDict(extra="forbid")

    titulo: str = Field(max_length=255)
    data_exame: date
    descricao: str
    categoria: str | None = Field(default=None, max_length=64)

    @field_validator("titulo", "descricao")
    @classmethod
    def _strip_non_empty(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("não pode ser vazio")
        return value

    @field_validator("categoria")
    @classmethod
    def _strip_optional(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return value.strip()


class ExameResponse(BaseModel):
    """Resposta segura de ``EXAME`` (sem ``gestacao_id``)."""

    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: uuid.UUID
    titulo: str
    data_exame: date
    descricao: str
    categoria: str | None
    created_at: datetime
    updated_at: datetime
