"""Contratos do domínio ``CONSULTA`` (FASE 8F) — escrita e resposta.

A entrada NUNCA contém ``id``, ``gestacao_id``, ``user_id`` nem timestamps (o
vínculo é derivado da rota ``/gestacoes/{gestacao_id}/consultas``, validada por
ownership). ``data_consulta`` é ``date`` (data civil), nunca ``dd/MM/yyyy``. A
resposta NÃO ecoa ``gestacao_id`` (o recurso é escopado pela rota).
"""

from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class ConsultaWrite(BaseModel):
    """Payload de escrita de ``CONSULTA`` (POST e PUT — full update)."""

    model_config = ConfigDict(extra="forbid")

    titulo: str = Field(max_length=255)
    data_consulta: date
    descricao: str

    @field_validator("titulo", "descricao")
    @classmethod
    def _strip_non_empty(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("não pode ser vazio")
        return value


class ConsultaResponse(BaseModel):
    """Resposta segura de ``CONSULTA`` (sem ``gestacao_id``)."""

    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: uuid.UUID
    titulo: str
    data_consulta: date
    descricao: str
    created_at: datetime
    updated_at: datetime
