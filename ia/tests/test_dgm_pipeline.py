"""Testes de pipeline do DGM: reprodutibilidade, anti-leakage e ruído (FASE 3C)."""

from __future__ import annotations

import numpy as np
import pytest

from meu_bebe_ml.schema import constants
from meu_bebe_ml.simulation import (
    LATENT_NAMES,
    CONTEXT_NAMES,
    M_SIM_DGM_FIELDS,
    TARGET_NAME,
    build_observed_dataset,
    generate_q_full,
    generate_target,
)


@pytest.fixture(scope="module")
def q_full_small():
    recs, m_sim = generate_q_full(n_samples=200, seed=42)
    latent = m_sim["latent_income_band"].tolist()
    masked = [bool(x) for x in m_sim["income_was_masked"].tolist()]
    return recs, latent, masked


# ---------------------------------------------------------------------------
# Reproducibilidade (section 28)
# ---------------------------------------------------------------------------

def test_same_seed_identical(q_full_small) -> None:
    recs, latent, masked = q_full_small
    r1 = generate_target(recs, latent, income_masked=masked, seed=42)
    r2 = generate_target(recs, latent, income_masked=masked, seed=42)
    assert r1.alpha == r2.alpha
    np.testing.assert_array_equal(r1.U, r2.U)
    np.testing.assert_array_equal(r1.p_true, r2.p_true)
    np.testing.assert_array_equal(r1.Y, r2.Y)


def test_different_seed_different(q_full_small) -> None:
    recs, latent, masked = q_full_small
    r1 = generate_target(recs, latent, income_masked=masked, seed=42)
    r2 = generate_target(recs, latent, income_masked=masked, seed=43)
    assert not np.allclose(r1.U, r2.U)
    assert not np.array_equal(r1.Y, r2.Y)


# ---------------------------------------------------------------------------
# Anti-leakage (section 29)
# ---------------------------------------------------------------------------

def test_observed_dataset_has_only_q_full_plus_target(q_full_small) -> None:
    recs, latent, masked = q_full_small
    result = generate_target(recs, latent, income_masked=masked, seed=42)
    dataset = build_observed_dataset(recs, result.Y)
    expected = set(constants.Q_FULL) | {TARGET_NAME}
    for row in dataset:
        assert set(row.keys()) == expected
        assert len(row) == 49


def test_no_msim_fields_leak_into_dataset(q_full_small) -> None:
    recs, latent, masked = q_full_small
    result = generate_target(recs, latent, income_masked=masked, seed=42)
    dataset = build_observed_dataset(recs, result.Y)
    forbidden = M_SIM_DGM_FIELDS | set(LATENT_NAMES) | set(CONTEXT_NAMES)
    for row in dataset:
        assert not (set(row.keys()) & forbidden)


def test_msim_guard_covers_target_internals() -> None:
    # O guard de M_sim deve listar explicitamente os internos do target.
    for name in ("g_escolaridade", "linear_component", "U", "eta", "p_true",
                 "alpha", "latent_income_band", "income_was_masked",
                 "interaction_income_food", "interaction_distance_transport"):
        assert name in M_SIM_DGM_FIELDS


# ---------------------------------------------------------------------------
# Sanidade do ruído (section 31)
# ---------------------------------------------------------------------------

def test_noise_mean_and_sd_sane() -> None:
    recs, m_sim = generate_q_full(n_samples=2000, seed=42)
    latent = m_sim["latent_income_band"].tolist()
    masked = [bool(x) for x in m_sim["income_was_masked"].tolist()]
    result = generate_target(recs, latent, income_masked=masked, seed=42)
    assert abs(float(np.mean(result.U))) < 0.1
    assert abs(float(np.std(result.U)) - 0.5) < 0.1


def test_noise_uncorrelated_with_z() -> None:
    recs, m_sim = generate_q_full(n_samples=2000, seed=42)
    latent = m_sim["latent_income_band"].tolist()
    masked = [bool(x) for x in m_sim["income_was_masked"].tolist()]
    result = generate_target(recs, latent, income_masked=masked, seed=42)
    for z in LATENT_NAMES:
        corr = float(np.corrcoef(result.U, m_sim[z].to_numpy())[0, 1])
        assert abs(corr) < 0.1, f"corr(U, {z}) = {corr}"


# ---------------------------------------------------------------------------
# Integração: Y é 0/1 e p_true disperso
# ---------------------------------------------------------------------------

def test_target_outputs_valid(q_full_small) -> None:
    recs, latent, masked = q_full_small
    result = generate_target(recs, latent, income_masked=masked, seed=42)
    assert set(result.Y.tolist()) <= {0, 1}
    assert np.all(result.p_true > 0.0) and np.all(result.p_true < 1.0)
    # p_true apresenta dispersão real (não constante)
    assert result.p_true.std() > 1e-6
    # nenhum g_* é constante
    for name, arr in result.g_factors.items():
        assert arr.std() > 1e-6, f"{name} constante"
