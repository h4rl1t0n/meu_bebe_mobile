"""Testes dos fatores latentes Z e dos contextos C_* (M_sim)."""

from __future__ import annotations

import numpy as np

from meu_bebe_ml.simulation import (
    LATENT_NAMES,
    compute_contexts,
    generate_latent_matrix,
    load_simulation_config,
)

_CORR = load_simulation_config()["z_correlation_matrix"]


def test_latent_names_order() -> None:
    assert LATENT_NAMES == ("Z_SES", "Z_LAB", "Z_TERR", "Z_INFRA", "Z_SERV")


def test_shape() -> None:
    rng = np.random.default_rng(42)
    Z = generate_latent_matrix(rng, 100, _CORR)
    assert Z.shape == (100, 5)


def test_same_seed_identical() -> None:
    Z1 = generate_latent_matrix(np.random.default_rng(42), 100, _CORR)
    Z2 = generate_latent_matrix(np.random.default_rng(42), 100, _CORR)
    np.testing.assert_array_equal(Z1, Z2)


def test_different_seed_different() -> None:
    Z1 = generate_latent_matrix(np.random.default_rng(42), 100, _CORR)
    Z2 = generate_latent_matrix(np.random.default_rng(43), 100, _CORR)
    assert not np.allclose(Z1, Z2)


def test_mean_near_zero() -> None:
    Z = generate_latent_matrix(np.random.default_rng(42), 5000, _CORR)
    means = Z.mean(axis=0)
    assert np.all(np.abs(means) < 0.06)


def test_correlations_close_to_config() -> None:
    """Correlações amostrais perto da matriz congelada (N=5000, tol razoável)."""
    Z = generate_latent_matrix(np.random.default_rng(42), 5000, _CORR)
    sample_corr = np.corrcoef(Z, rowvar=False)
    target = np.asarray(_CORR, dtype=float)
    assert np.allclose(sample_corr, target, atol=0.06)


def test_compute_contexts_from_config() -> None:
    cfg = load_simulation_config()
    # Usa as configurações de contextos do gerador, não do simulation_v1.
    from meu_bebe_ml.simulation import load_generator_config

    contexts_cfg = load_generator_config()["contexts"]
    z = np.array([1.0, -0.5, 0.25, 0.75, -0.25])
    out = compute_contexts(z, contexts_cfg)
    assert set(out.keys()) == {"C_LAB", "C_INFRA", "C_ACCESS", "C_FOOD"}
    # C_LAB = 0.55*1.0 + 0.45*(-0.5) = 0.325
    assert abs(out["C_LAB"] - 0.325) < 1e-12
    # C_INFRA = 0.35*1.0 + 0.65*0.75 = 0.8375
    assert abs(out["C_INFRA"] - 0.8375) < 1e-12
    # C_ACCESS = 0.20*1.0 + 0.55*0.25 + 0.25*(-0.25) = 0.275
    assert abs(out["C_ACCESS"] - 0.275) < 1e-12
    # C_FOOD = 0.75*1.0 + 0.25*0.75 = 0.9375
    assert abs(out["C_FOOD"] - 0.9375) < 1e-12
