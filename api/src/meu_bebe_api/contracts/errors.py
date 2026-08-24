"""Contrato de erro da API (envelope padronizado).

Toda resposta de erro segue ``ErrorResponse``. O ``details`` nunca carrega o
valor rejeitado (``input``) nem o corpo bruto — apenas localização, mensagem e
tipo do erro de validação.
"""

from __future__ import annotations

from pydantic import BaseModel, ConfigDict


class ErrorDetail(BaseModel):
    """Um item de detalhe de erro (posição, mensagem e tipo)."""

    model_config = ConfigDict(extra="forbid")

    loc: list[str | int]
    msg: str
    type: str


class ErrorResponse(BaseModel):
    """Envelope único de erro da API."""

    model_config = ConfigDict(extra="forbid")

    code: str
    message: str
    details: list[ErrorDetail]
