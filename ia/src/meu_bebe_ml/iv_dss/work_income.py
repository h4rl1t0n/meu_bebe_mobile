"""Dimensão Trabalho/Renda do IV-DSS.

Apesar do nome histórico, o indicador principal desta dimensão é **econômico**:
utiliza SOMENTE ``faixa_renda``.

``nao_informar`` é tratado como **missing verdadeiro** (``None``). NÃO é usado
``latent_income_band`` (que é metadado de simulação ``M_sim`` do DGM) e NÃO é
usado vínculo empregatício para substituir a renda. Nenhuma imputação.
"""

from __future__ import annotations

from typing import Any, Mapping

from .types import ScoreResult, analytically_indeterminate, missing, valid

# Mapeamento principal congelado (docs §8.2). Valores em [0, 1].
_RENDA_MAP: dict[str, float] = {
    "ate_1_sm": 1.00,
    "entre_1_2_sm": 0.67,
    "entre_2_3_sm": 0.33,
    "mais_3_sm": 0.00,
}


def score_faixa_renda(faixa_renda: str | None) -> ScoreResult:
    """Score de Trabalho/Renda a partir de ``faixa_renda``."""
    if faixa_renda is None:
        return missing("faixa_renda ausente")
    if faixa_renda == "nao_informar":
        return missing("faixa_renda == 'nao_informar' (não imputada no IV-DSS)")
    if faixa_renda not in _RENDA_MAP:
        return analytically_indeterminate(
            f"faixa_renda sem score definido: {faixa_renda!r}"
        )
    return valid(_RENDA_MAP[faixa_renda])


def D_trabalho(record: Mapping[str, Any]) -> ScoreResult:
    """Dimensão Trabalho/Renda = score(faixa_renda)."""
    return score_faixa_renda(record.get("faixa_renda"))
