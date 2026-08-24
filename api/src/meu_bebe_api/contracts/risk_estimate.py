"""Contrato de resposta do ``POST /api/v1/risk-estimate`` (FASE 4C).

A resposta expõe APENAS a estimativa probabilística experimental e os metadados
SANITIZADOS do modelo (nome, versão do schema DSS e contagens de features). Não
expõe threshold, classe, faixa de risco, caminho, SHA, versões de bibliotecas,
hiperparâmetros nem as features do modelo (X_MODEL / transformadas).
"""

from __future__ import annotations

import math

from pydantic import BaseModel, ConfigDict, field_validator

from .errors import ErrorResponse

# Nome do target experimental congelado (variável resposta do experimento).
# NÃO é uma afirmação de que o desfecho ocorreu: a única saída numérica é
# ``probability``.
EXPERIMENTAL_TARGET: str = "descontinuou_pre_natal"

# Aviso obrigatório de caráter experimental / dados sintéticos. Constante única
# para evitar divergência entre API, OpenAPI e testes.
EXPERIMENTAL_ESTIMATE_NOTICE: str = (
    "Estimativa estatística experimental baseada em dados sintéticos; não "
    "constitui diagnóstico médico nem certeza de descontinuidade do pré-natal."
)


class RiskEstimateResult(BaseModel):
    """Estimativa pontual: target experimental + probabilidade em [0,1]."""

    model_config = ConfigDict(extra="forbid")

    target: str
    probability: float

    @field_validator("probability")
    @classmethod
    def _finite_bounded(cls, value: float) -> float:
        if not math.isfinite(value) or not (0.0 <= value <= 1.0):
            raise ValueError("probability deve ser finito e estar em [0,1]")
        return value


class RiskEstimateModelMetadata(BaseModel):
    """Metadados SANITIZADOS do modelo (sem caminho/SHA/versões/hiperparâmetros)."""

    model_config = ConfigDict(extra="forbid")

    name: str
    schema_version: str
    raw_feature_count: int
    transformed_feature_count: int


class RiskEstimateResponse(BaseModel):
    """Corpo de sucesso (200) do endpoint."""

    model_config = ConfigDict(extra="forbid")

    result: RiskEstimateResult
    model: RiskEstimateModelMetadata
    notice: str


class ErrorEnvelope(BaseModel):
    """Envelope de erro aninhado ``{"error": {...}}`` (respostas 500/503).

    Espelha o corpo já usado pelo ``/ready`` em falha (FASE 4B). Usado para
    documentar 500/503 no OpenAPI. O 422 usa ``ErrorResponse`` direto (formato
    plano congelado da FASE 4A).
    """

    model_config = ConfigDict(extra="forbid")

    error: ErrorResponse
