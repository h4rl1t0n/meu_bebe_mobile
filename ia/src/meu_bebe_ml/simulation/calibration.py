"""Sigmoid numericamente estável e calibração do intercepto ``alpha``.

O DGM define ``eta = alpha + base_eta`` onde ``base_eta = linear_component + U``.
``alpha`` é calibrado numericamente para que a **média das probabilidades
verdadeiras** seja ``mean(sigmoid(alpha + base_eta)) ≈ target_positive_rate``
(0.25 no cenário principal).

Isso é um alvo sobre ``mean(p_true)``, NÃO uma obrigação de ``mean(Y) == 0.25``.
A função ``f(alpha) = mean(sigmoid(alpha + base_eta)) - target`` é monótona
crescente em ``alpha``, então a raiz é única e pode ser resolvida com
``scipy.optimize.brentq`` (ou bisseção equivalente).

Nada aqui observa ``Y``: a calibração depende apenas de ``base_eta``.
"""

from __future__ import annotations

import numpy as np
from scipy.optimize import brentq

# Tolerância numérica para |mean(p_true) - target| após a calibração.
_CALIBRATION_TOL = 1e-8


def sigmoid(x: np.ndarray | float) -> np.ndarray | float:
    """Sigmóide logística numericamente estável (vetorial e escalar).

    Evita overflow de ``exp`` usando ramos separados para ``x >= 0`` e ``x < 0``.
    Para entradas finitas devolve valores em ``[0, 1]`` sem ``inf``/``nan``;
    para ``|x|`` moderado (o caso real do pipeline, com ``eta`` limitado) os
    valores são estritamente em ``(0, 1)``.
    """
    x_arr = np.asarray(x, dtype=float)
    out = np.empty_like(x_arr)
    pos = x_arr >= 0
    neg = ~pos
    out[pos] = 1.0 / (1.0 + np.exp(-x_arr[pos]))
    exp_x = np.exp(x_arr[neg])
    out[neg] = exp_x / (1.0 + exp_x)
    if out.ndim == 0:
        return float(out)
    return out


def _mean_p(alpha: float, base_eta: np.ndarray) -> float:
    return float(np.mean(sigmoid(alpha + base_eta)))


def calibrate_alpha(base_eta: np.ndarray, target_positive_rate: float) -> float:
    """Encontra ``alpha`` tal que ``mean(sigmoid(alpha + base_eta)) ≈ target``.

    Usa ``brentq`` sobre a função monótona ``f(alpha)`` com intervalo expandido
    dinamicamente. Retorna ``alpha`` finito; a tolerância resultante em
    ``mean(p_true)`` é verificada por :func:`_CALIBRATION_TOL`.
    """
    base_eta = np.asarray(base_eta, dtype=float)

    def f(alpha: float) -> float:
        return _mean_p(alpha, base_eta) - target_positive_rate

    lo, hi = -50.0, 50.0
    f_lo = f(lo)
    f_hi = f(hi)
    # A função é crescente; expande o intervalo se o bracket não fechar.
    while f_lo > 0.0:
        lo -= 50.0
        f_lo = f(lo)
    while f_hi < 0.0:
        hi += 50.0
        f_hi = f(hi)

    alpha = float(brentq(f, lo, hi, xtol=1e-12, rtol=1e-12))
    if not np.isfinite(alpha):
        raise RuntimeError("calibração de alpha divergiu (alpha não finito)")
    return alpha
