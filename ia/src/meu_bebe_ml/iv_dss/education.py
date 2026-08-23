"""Dimensão Educação do IV-DSS.

Utiliza SOMENTE ``escolaridade``. Os demais campos da dimensão Educação
(``estuda_atualmente``, ``dificuldades_educacao``, ``entende_orientacoes_saude``,
``fez_curso_qualificacao_profissional``, ``situacao_estudos_gestacao``) NÃO
entram no IV-DSS.

Os valores são uma **normalização ordinal operacional** congelada (docs §8.1):
não representam distâncias sociais empiricamente iguais entre categorias, nem
probabilidade, nem diagnóstico.
"""

from __future__ import annotations

from typing import Any, Mapping

from .types import ScoreResult, analytically_indeterminate, missing, valid

# Mapeamento principal congelado (docs §8.1). Valores em [0, 1].
_EDUCACAO_MAP: dict[str, float] = {
    "sem_instrucao": 1.00,
    "fundamental_incompleto": 0.83,
    "fundamental_completo": 0.67,
    "medio_incompleto": 0.50,
    "medio_completo": 0.33,
    "superior_incompleto": 0.17,
    "superior_completo": 0.00,
}


def score_escolaridade(escolaridade: str | None) -> ScoreResult:
    """Score de Educação a partir de ``escolaridade``."""
    if escolaridade is None:
        return missing("escolaridade ausente")
    if escolaridade not in _EDUCACAO_MAP:
        return analytically_indeterminate(
            f"escolaridade sem score definido: {escolaridade!r}"
        )
    return valid(_EDUCACAO_MAP[escolaridade])


def D_educacao(record: Mapping[str, Any]) -> ScoreResult:
    """Dimensão Educação = score(escolaridade)."""
    return score_escolaridade(record.get("escolaridade"))
