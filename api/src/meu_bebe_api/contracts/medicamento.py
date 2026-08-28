"""Contratos do domínio ``MEDICAMENTO`` (FASE 8G) — escrita e resposta.

A entrada NUNCA contém ``id``, ``gestacao_id``, ``user_id`` nem timestamps (o
vínculo é derivado da rota ``/gestacoes/{gestacao_id}/medicamentos``, validada
por ownership). ``nome``, ``dose`` e ``frequencia`` são strings obrigatórias,
normalizadas (strip) e NÃO-vazias (lição da 8F). A resposta NÃO ecoa
``gestacao_id``.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class MedicamentoWrite(BaseModel):
    """Payload de escrita de ``MEDICAMENTO`` (POST e PUT — full update)."""

    model_config = ConfigDict(extra="forbid")

    nome: str = Field(max_length=255)
    dose: str = Field(max_length=255)
    frequencia: str = Field(max_length=255)

    @field_validator("nome", "dose", "frequencia")
    @classmethod
    def _strip_non_empty(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("não pode ser vazio")
        return value


class MedicamentoResponse(BaseModel):
    """Resposta segura de ``MEDICAMENTO`` (sem ``gestacao_id``)."""

    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: uuid.UUID
    nome: str
    dose: str
    frequencia: str
    created_at: datetime
    updated_at: datetime
