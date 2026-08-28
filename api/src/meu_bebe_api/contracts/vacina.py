"""Contratos do domínio ``VACINA`` (FASE 8G) — escrita e resposta.

A entrada NUNCA contém ``id``, ``gestacao_id``, ``user_id`` nem timestamps (o
vínculo é derivado da rota ``/gestacoes/{gestacao_id}/vacinas``, validada por
ownership). ``nome`` é string obrigatória (strip + não-vazia); ``aplicada`` é um
booleano — o ``used`` do Flutter, significando "tomada/aplicada". A resposta NÃO
ecoa ``gestacao_id``.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class VacinaWrite(BaseModel):
    """Payload de escrita de ``VACINA`` (POST e PUT — full update)."""

    model_config = ConfigDict(extra="forbid")

    nome: str = Field(max_length=255)
    aplicada: bool

    @field_validator("nome")
    @classmethod
    def _strip_non_empty(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("não pode ser vazio")
        return value


class VacinaResponse(BaseModel):
    """Resposta segura de ``VACINA`` (sem ``gestacao_id``)."""

    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: uuid.UUID
    nome: str
    aplicada: bool
    created_at: datetime
    updated_at: datetime
