"""Contratos do domínio ``GESTANTE`` (FASE 8D) — escrita e resposta.

A entrada NUNCA contém ``id``, ``user_id``, timestamps ou credenciais (o
``user_id`` é derivado do token; ver seção 12/13 do plano). A resposta expõe
apenas o perfil, nunca ``user_id`` alheio, senha ou token.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

# Validações mínimas (seção 11 do plano): CPF 11 dígitos, CNS 15 dígitos, sem
# dígito verificador, sem validação clínica.
CPF_DIGITS = 11
CNS_DIGITS = 15


def _digits_only(value: str) -> str:
    """Extrai apenas os dígitos (normalização ``strip`` + remover não-dígitos)."""
    return "".join(ch for ch in value if ch.isdigit())


class GestanteWrite(BaseModel):
    """Payload de escrita de ``GESTANTE`` (POST e PUT — full update)."""

    model_config = ConfigDict(extra="forbid")

    nome: str = Field(min_length=1, max_length=255)
    nome_social: str | None = Field(default=None, max_length=255)
    data_nascimento: date
    cpf: str | None = Field(default=None)
    cns: str | None = Field(default=None)

    @field_validator("nome", "nome_social")
    @classmethod
    def _strip_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return value.strip()

    @field_validator("nome")
    @classmethod
    def _nome_not_blank(cls, value: str) -> str:
        if not value:
            raise ValueError("Nome não pode ser vazio.")
        return value

    @field_validator("data_nascimento")
    @classmethod
    def _not_future(cls, value: date) -> date:
        if value > date.today():
            raise ValueError("Data de nascimento não pode estar no futuro.")
        return value

    @field_validator("cpf")
    @classmethod
    def _normalize_cpf(cls, value: str | None) -> str | None:
        if value is None or value == "":
            return None
        digits = _digits_only(value)
        if len(digits) != CPF_DIGITS:
            raise ValueError("CPF deve conter exatamente 11 dígitos.")
        return digits

    @field_validator("cns")
    @classmethod
    def _normalize_cns(cls, value: str | None) -> str | None:
        if value is None or value == "":
            return None
        digits = _digits_only(value)
        if len(digits) != CNS_DIGITS:
            raise ValueError("CNS deve conter exatamente 15 dígitos.")
        return digits


class GestanteResponse(BaseModel):
    """Resposta segura de ``GESTANTE`` (sem ``user_id``/senha/token)."""

    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: uuid.UUID
    nome: str
    nome_social: str | None
    data_nascimento: date
    cpf: str | None
    cns: str | None
    created_at: datetime
    updated_at: datetime
