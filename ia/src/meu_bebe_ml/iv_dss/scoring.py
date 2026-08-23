"""Helpers genéricos de agregação dos scores do IV-DSS.

Funções puras e sem estado. Nada aqui depende de ``Y``, ``p_true``, ``g_*``,
``Z_*``, ``C_*`` ou qualquer metadado de simulação — apenas agrega
:class:`~meu_bebe_ml.iv_dss.types.ScoreResult`.
"""

from __future__ import annotations

from collections.abc import Sequence

from .types import ScoreResult, analytically_indeterminate, valid


def mean_of_valid(
    results: Sequence[ScoreResult], *, min_valid: int, insufficient_reason: str
) -> ScoreResult:
    """Média aritmética dos componentes válidos, exigindo ao menos ``min_valid``.

    Se houver menos de ``min_valid`` componentes com status ``VALID``, retorna
    ``analytically_indeterminate`` (ausência analítica por insuficiência de
    componentes — NÃO é substituída por zero nem imputada). Se houver
    componentes suficientes, retorna a média aritmética dos válidos.
    """
    values = [r.value for r in results if r.is_valid]
    if len(values) < min_valid:
        return analytically_indeterminate(insufficient_reason)
    return valid(sum(values) / len(values))


def arithmetic_mean(values: Sequence[float]) -> float:
    """Média aritmética simples (os valores devem ser numéricos)."""
    return sum(values) / len(values)
