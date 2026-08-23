"""Testes da calibração do intercepto ``alpha`` e do sigmoid estável (FASE 3C)."""

from __future__ import annotations

import numpy as np

from meu_bebe_ml.simulation import calibrate_alpha, sigmoid

_TARGET = 0.25


def _base_eta(n: int = 20000, seed: int = 0) -> np.ndarray:
    rng = np.random.default_rng(seed)
    # Mistura de sinais positivos/negativos para exercitar ambos os ramos.
    return rng.normal(0.0, 0.5, size=n) + rng.uniform(0.0, 2.0, size=n)


def test_sigmoid_range() -> None:
    x = np.linspace(-20, 20, 1000)
    p = sigmoid(x)
    assert np.all(p > 0.0) and np.all(p < 1.0)


def test_sigmoid_scalar() -> None:
    assert abs(sigmoid(0.0) - 0.5) < 1e-12


def test_sigmoid_stable_extremes() -> None:
    # Sem overflow/NaN: satura em 0/1 nas caudas extremas (|x| ~ 1000).
    assert np.isfinite(sigmoid(-1000.0))
    assert np.isfinite(sigmoid(1000.0))
    assert sigmoid(-1000.0) == 0.0
    assert sigmoid(1000.0) == 1.0


def test_alpha_is_finite() -> None:
    alpha = calibrate_alpha(_base_eta(), _TARGET)
    assert np.isfinite(alpha)


def test_calibration_converges_to_target() -> None:
    base = _base_eta()
    alpha = calibrate_alpha(base, _TARGET)
    mean_p = float(np.mean(sigmoid(alpha + base)))
    assert abs(mean_p - _TARGET) < 1e-8


def test_mean_p_increases_with_alpha() -> None:
    base = _base_eta()
    a = calibrate_alpha(base, _TARGET)
    assert float(np.mean(sigmoid(a + 1.0 + base))) > float(np.mean(sigmoid(a + base)))
    assert float(np.mean(sigmoid(a - 1.0 + base))) < float(np.mean(sigmoid(a + base)))


def test_p_true_in_unit_interval_after_calibration() -> None:
    base = _base_eta()
    alpha = calibrate_alpha(base, _TARGET)
    p = sigmoid(alpha + base)
    assert np.all(p > 0.0) and np.all(p < 1.0)
