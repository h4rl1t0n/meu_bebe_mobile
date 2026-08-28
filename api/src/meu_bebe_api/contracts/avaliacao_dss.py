"""Contrato de resposta da AVALIAÇÃO DSS operacional (FASE 8I).

A ESCRITA reutiliza o contrato canônico ``DssPayload`` (``contracts/dss.py``),
o MESMO usado pelo ``POST /risk-estimate`` — NÃO há uma segunda definição das 48
variáveis. O corpo do POST é exatamente ``FormularioData.toMap()``
(``schema_version`` + 6 dimensões).

A resposta expõe o snapshot persistido: ``id``, ``schema_version``,
``respostas`` (as 6 dimensões / 48 variáveis) e ``created_at``. Não expõe
``gestacao_id`` nem qualquer ID de vínculo (o vínculo é derivado da rota,
validada por ownership). ``respostas`` é o dump JSON canônico (null/bool/number/
string/listas) — sem Pydantic internals.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict


class AvaliacaoDssResponse(BaseModel):
    """Resposta segura de uma avaliação DSS (sem ``gestacao_id``)."""

    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: uuid.UUID
    schema_version: str
    respostas: dict[str, Any]
    created_at: datetime
