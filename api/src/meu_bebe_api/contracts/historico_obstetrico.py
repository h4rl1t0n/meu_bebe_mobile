"""Contratos do domínio ``HISTÓRICO OBSTÉTRICO`` (FASE 8E) — escrita e resposta.

A entrada NUNCA contém ``id``, ``gestante_id``, ``user_id`` nem timestamps (o
vínculo é derivado do token). O recurso é um SINGLETON por gestante: GET/PUT em
``/gestantes/me/historico-obstetrico`` (não há rota ``/{id}``). As três
contagens são opcionais e ``>= 0`` (sem validação médica avançada).
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class HistoricoObstetricoWrite(BaseModel):
    """Payload de escrita do histórico (PUT — upsert do singleton)."""

    model_config = ConfigDict(extra="forbid")

    pregnancy_number: int | None = Field(default=None, ge=0)
    given_birth_number: int | None = Field(default=None, ge=0)
    abortions_number: int | None = Field(default=None, ge=0)


class HistoricoObstetricoResponse(BaseModel):
    """Resposta segura do histórico (sem ``gestante_id`` alheio)."""

    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: uuid.UUID
    pregnancy_number: int | None
    given_birth_number: int | None
    abortions_number: int | None
    created_at: datetime
    updated_at: datetime
