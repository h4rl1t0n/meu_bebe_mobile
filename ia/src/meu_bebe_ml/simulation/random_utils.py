"""Helpers genéricos e reutilizáveis de amostragem probabilística.

Todas as funções são *puras* em relação a ``rng`` (um
``numpy.random.Generator``): recebem o gerador por parâmetro e consomem dele
de forma determinística. Isso garante reprodutibilidade por seed.

A presença de :func:`sigmoid` e :func:`safe_logit` aqui serve exclusivamente
para gerar as variáveis de X. NÃO implementam o sigmoid/eta do target Y —
o DGM de Y permanece fora do escopo desta fase.
"""

from __future__ import annotations

import math
from typing import Any, Sequence

import numpy as np

_EPS = 1e-6


def sigmoid(x: float) -> float:
    """Sigmóide logística numericamente estável."""
    if x >= 0:
        z = math.exp(-x)
        return 1.0 / (1.0 + z)
    z = math.exp(x)
    return z / (1.0 + z)


def safe_logit(p: float, eps: float = _EPS) -> float:
    """Logit com probabilidade limitada a ``[eps, 1 - eps]``."""
    p = min(max(p, eps), 1.0 - eps)
    return math.log(p / (1.0 - p))


def linear_delta(signals: dict[str, float], coefs: dict[str, float]) -> float:
    """Soma ``coef * signal`` para os sinais presentes em ``coefs``."""
    total = 0.0
    for name, coef in coefs.items():
        total += coef * signals.get(name, 0.0)
    return total


def sample_boolean(
    rng: np.random.Generator, base_true: float, delta: float = 0.0
) -> bool:
    """Amostra um booleano com ``P(true) = sigmoid(logit(base) + delta)``."""
    p = sigmoid(safe_logit(base_true) + delta)
    return bool(rng.random() < p)


def sample_boolean_or_null(
    rng: np.random.Generator,
    base_true: float,
    delta: float,
    null_rate: float,
) -> bool | None:
    """Amostra um booleano opcional com ``P(null) = null_rate``.

    ``null_rate`` é um parâmetro experimental de simulação (não é taxa real de
    não resposta). Consumo determinístico do ``rng``: primeiro o sorteio de
    missing, depois o valor (apenas quando não missing).
    """
    if rng.random() < null_rate:
        return None
    return sample_boolean(rng, base_true, delta)


def sample_categorical(
    rng: np.random.Generator, categories: Sequence[Any], probs: Sequence[float]
) -> Any:
    """Amostra uma categoria com probabilidades normalizadas."""
    p = np.asarray(probs, dtype=float)
    total = p.sum()
    if total <= 0.0:
        raise ValueError("probabilidades não podem somar <= 0")
    p = p / total
    return categories[int(rng.choice(len(categories), p=p))]


def sample_ordinal(
    rng: np.random.Generator,
    categories: Sequence[Any],
    base: dict[Any, float],
    severity: dict[Any, float],
    context: float,
    strength: float,
) -> Any:
    """Amostra uma categoria ordinal por re-ponderação exponencial.

    ``weight_k = base_k * exp(strength * context * (2 * severity_k - 1))``.

    Maior ``context`` (adversidade) aumenta a massa das categorias com maior
    ``severity`` sem tornar a relação determinística.
    """
    weights: list[float] = []
    for cat in categories:
        base_p = base[cat]
        sev = severity[cat]
        weights.append(base_p * math.exp(strength * context * (2.0 * sev - 1.0)))
    total = sum(weights)
    if total <= 0.0:
        raise ValueError("pesos ordinais não podem somar <= 0")
    probs = [w / total for w in weights]
    return categories[int(rng.choice(len(categories), p=probs))]


def sample_int_ordinal(
    rng: np.random.Generator,
    values: Sequence[int],
    base: dict[int, float],
    severity: dict[int, float],
    context: float,
    strength: float,
) -> int:
    """Amostra um inteiro de ``values`` por re-ponderação ordinal.

    Variante de :func:`sample_ordinal` para valores inteiros (Habitação).
    """
    weights = [
        base[v] * math.exp(strength * context * (2.0 * severity[v] - 1.0))
        for v in values
    ]
    total = sum(weights)
    probs = [w / total for w in weights]
    return int(values[int(rng.choice(len(values), p=probs))])


def sample_multiselect(
    rng: np.random.Generator,
    items: Sequence[str],
    base: dict[str, float],
    delta_map: dict[str, float],
    exclusive: str | None = None,
) -> list[str]:
    """Amostra um multiselect por sorteios independentes por item.

    Cada item positivo é sorteado com ``P = sigmoid(logit(base) + delta)``.
    Se nenhum item for selecionado e ``exclusive`` for informado, retorna
    ``[exclusive]``. Caso contrário retorna a lista (possivelmente vazia) de
    itens selecionados — o chamador decide se aplica fallback.
    """
    selected: list[str] = []
    for item in items:
        if sample_boolean(rng, base.get(item, 0.0), delta_map.get(item, 0.0)):
            selected.append(item)
    if not selected and exclusive is not None:
        return [exclusive]
    return selected
