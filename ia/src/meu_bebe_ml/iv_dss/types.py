"""Tipos de resultado dos scores do IV-DSS.

O IV-DSS é um índice **descritivo e experimental**: cada componente/dimensão
pode resultar em um valor numérico em ``[0, 1]`` ou em uma ausência analítica.
Este módulo distingue conceitualmente quatro estados (docs §6.4 / §8):

1. **valor válido** — ``ScoreStatus.VALID``;
2. **missing verdadeiro** — a informante não respondeu / recusou
   (ex.: ``faixa_renda == "nao_informar"``, ``interrupcoes_agua == null``);
3. **structural_not_applicable** — a categoria não se aplica dado outro campo
   (ex.: ``destino_lixo_sem_coleta`` quando a coleta é ``regular``);
4. **analytically_indeterminate** — o dado existe, mas não há score definido
   para a categoria (ex.: ``fonte_agua == "cisterna"``, ``esgotamento == "outro"``).

Nenhum desses estados é substituído automaticamente por zero, e não há
imputação no IV-DSS. Todos os scores são independentes de ``Y``, ``p_true``,
``g_*``, ``Z_*``, ``C_*`` e demais metadados de simulação (``M_sim``).
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class ScoreStatus(str, Enum):
    """Estado analítico de um score do IV-DSS."""

    VALID = "valid"
    MISSING = "missing"
    STRUCTURAL_NOT_APPLICABLE = "structural_not_applicable"
    ANALYTICALLY_INDETERMINATE = "analytically_indeterminate"


@dataclass(frozen=True)
class ScoreResult:
    """Resultado de um score: valor em ``[0,1]`` (ou ``None``) + estado + motivo.

    ``value`` só é significativo quando ``status == VALID``; nos demais casos é
    ``None`` e ``reason`` descreve a causa (para auditoria). O ``reason`` é
    texto livre e informativo, nunca usado para pontuação.
    """

    value: float | None
    status: ScoreStatus
    reason: str

    @property
    def is_valid(self) -> bool:
        """``True`` se o score possui valor numérico calculável."""
        return self.status is ScoreStatus.VALID and self.value is not None


def valid(value: float) -> ScoreResult:
    """Score válido com valor numérico em ``[0, 1]``."""
    return ScoreResult(value=float(value), status=ScoreStatus.VALID, reason="")


def missing(reason: str) -> ScoreResult:
    """Missing verdadeiro (não respondido/recusado)."""
    return ScoreResult(value=None, status=ScoreStatus.MISSING, reason=reason)


def structural_not_applicable(reason: str) -> ScoreResult:
    """Categoria não aplicável dada outra resposta do questionário."""
    return ScoreResult(
        value=None, status=ScoreStatus.STRUCTURAL_NOT_APPLICABLE, reason=reason
    )


def analytically_indeterminate(reason: str) -> ScoreResult:
    """Dado presente, mas sem score definido para a categoria."""
    return ScoreResult(
        value=None, status=ScoreStatus.ANALYTICALLY_INDETERMINATE, reason=reason
    )
