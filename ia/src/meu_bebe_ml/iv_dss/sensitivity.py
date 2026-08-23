"""Análises de sensibilidade do IV-DSS.

São saídas **auxiliares** e marcadas explicitamente como SENSIBILIDADE. NÃO
substituem a média aritmética principal.

* Média generalizada de ordem ``p = 2`` (docs §8.6):
  ``( (sum_i D_i^2) / n )^(1/2)``, somente quando as 6 dimensões principais
  estão disponíveis. Para dimensões não-negativas, ``p2 >= média aritmética``,
  com igualdade quando todas são iguais.
* Sensibilidade binária de Habitação (docs §8.7), já exposta em
  :mod:`meu_bebe_ml.iv_dss.housing`.

A média geométrica foi rejeitada como principal por colapsar quando há
dimensão zero; não é implementada.
"""

from __future__ import annotations

import math
from collections.abc import Sequence


def generalized_mean_p2(values: Sequence[float]) -> float:
    """Média generalizada de ordem 2 (raiz da média dos quadrados).

    Recebe valores não-negativos (dimensões do IV-DSS, em ``[0, 1]``). Exige ao
    menos um valor.
    """
    if len(values) == 0:
        raise ValueError("generalized_mean_p2 requer ao menos um valor")
    return math.sqrt(sum(v * v for v in values) / len(values))
