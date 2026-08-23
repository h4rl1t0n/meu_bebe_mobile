"""Dimensão Alimentação do IV-DSS.

Utiliza SOMENTE ``deixou_de_comer_falta_dinheiro`` — autorrelato de privação
alimentar recente por motivo financeiro.

NÃO é EBIA, FIES, diagnóstico nem classificação validada de insegurança
alimentar. ``null`` é missing verdadeiro (não respondido).
"""

from __future__ import annotations

from typing import Any, Mapping

from .types import ScoreResult, analytically_indeterminate, missing, valid


def score_alimentacao(deixou_de_comer: bool | None) -> ScoreResult:
    """Score de Alimentação a partir de ``deixou_de_comer_falta_dinheiro``."""
    if deixou_de_comer is None:
        return missing("deixou_de_comer_falta_dinheiro ausente")
    if isinstance(deixou_de_comer, bool):
        return valid(1.0 if deixou_de_comer else 0.0)
    return analytically_indeterminate(
        f"deixou_de_comer_falta_dinheiro não booleano: {deixou_de_comer!r}"
    )


def D_alimentacao(record: Mapping[str, Any]) -> ScoreResult:
    """Dimensão Alimentação = score(deixou_de_comer_falta_dinheiro)."""
    return score_alimentacao(record.get("deixou_de_comer_falta_dinheiro"))
