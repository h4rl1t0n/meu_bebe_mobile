"""Geração do desfecho sintético ``Y`` e montagem dos artefatos finais (FASE 3C).

Fluxo (docs §18): ``g_*`` → ``linear_component`` → ``eta = alpha + linear + U``
→ ``p_true = sigmoid(eta)`` → ``Y ~ Bernoulli(p_true)``.

* ``U ~ Normal(0, noise_sd)`` e o sorteio Bernoulli usam **streams aleatórios
  independentes** derivados de ``numpy.random.SeedSequence(master_seed).spawn(2)``.
  Isso desacopla o RNG do target do RNG que gerou ``Q_full`` (FASE 3B), garantindo
  reprodutibilidade sem dependência da sequência da fase anterior.
* ``Y`` é o símbolo interno; o nome de armazenamento canônico é
  ``descontinuou_pre_natal`` (docs §7/§18).
* Nenhum campo de ``M_sim`` (``g_*``, ``eta``, ``p_true``, ``U``,
  ``linear_component``, renda latente, etc.) entra no dataset observado.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Mapping, Sequence

import numpy as np
import pandas as pd

from ..schema import constants
from .calibration import calibrate_alpha, sigmoid
from .dgm import (
    G_FACTOR_NAMES,
    INTERACTION_NAMES,
    compute_g_factors,
    compute_linear_component,
    load_dgm_spec,
)
from .config import load_simulation_config

# Símbolo interno do desfecho (cálculos).
TARGET_SYMBOL: str = "Y"

# Nome canônico de armazenamento tabular (docs: "descontinuou_pre_natal ∈ {0,1}").
TARGET_NAME: str = "descontinuou_pre_natal"


@dataclass
class TargetResult:
    """Resultado completo da geração do desfecho (M_sim do DGM + Y)."""

    alpha: float
    Y: np.ndarray  # int 0/1
    p_true: np.ndarray
    eta: np.ndarray
    U: np.ndarray
    linear_component: np.ndarray
    g_factors: dict[str, np.ndarray] = field(default_factory=dict)
    interactions: dict[str, np.ndarray] = field(default_factory=dict)
    crowding_ratio: np.ndarray = field(default_factory=lambda: np.array([]))
    latent_income_band: list[str] = field(default_factory=list)
    income_was_masked: list[bool] = field(default_factory=list)


def generate_target(
    records: Sequence[Mapping[str, Any]],
    latent_income_bands: Sequence[str | None],
    *,
    income_masked: Sequence[bool] | None = None,
    seed: int = 42,
    sim_config: Mapping[str, Any] | None = None,
) -> TargetResult:
    """Gera ``Y``, ``eta``, ``p_true`` e os fatores ``g_*`` para ``records``.

    ``records`` são os 48 campos de ``Q_full``; ``latent_income_bands`` é a renda
    verdadeira sintética (``M_sim``) alinhada por ``row_index``. ``income_masked``
    é opcional para auditoria (default: derivado de ``faixa_renda``).
    """
    sim_config = sim_config if sim_config is not None else load_simulation_config()
    spec = load_dgm_spec(sim_config)
    noise_sd = float(sim_config["noise_sd"])
    target_rate = float(sim_config["target_positive_rate"])

    n = len(records)
    if len(latent_income_bands) != n:
        raise ValueError("latent_income_bands deve estar alinhado com records")

    if income_masked is None:
        income_masked = [
            bool(r["faixa_renda"] == "nao_informar") for r in records
        ]
    elif len(income_masked) != n:
        raise ValueError("income_masked deve estar alinhado com records")

    g_factors = {name: np.empty(n, dtype=float) for name in G_FACTOR_NAMES}
    interactions = {name: np.empty(n, dtype=float) for name in INTERACTION_NAMES}
    crowding = np.empty(n, dtype=float)
    linear = np.empty(n, dtype=float)

    for i, record in enumerate(records):
        gf = compute_g_factors(record, latent_income_bands[i])
        for name in G_FACTOR_NAMES:
            g_factors[name][i] = gf[name]
        for name in INTERACTION_NAMES:
            interactions[name][i] = gf[name]
        crowding[i] = gf["crowding_ratio"]
        linear[i] = compute_linear_component(gf, spec)

    # Streams independentes: (1) ruído U; (2) sorteio Bernoulli de Y.
    noise_ss, y_ss = np.random.SeedSequence(seed).spawn(2)
    noise_rng = np.random.default_rng(noise_ss)
    y_rng = np.random.default_rng(y_ss)

    U = noise_rng.normal(0.0, noise_sd, size=n)
    base_eta = linear + U
    alpha = calibrate_alpha(base_eta, target_rate)
    eta = alpha + base_eta
    p_true = np.asarray(sigmoid(eta), dtype=float)
    Y = (y_rng.random(n) < p_true).astype(int)

    return TargetResult(
        alpha=alpha,
        Y=Y,
        p_true=p_true,
        eta=eta,
        U=U,
        linear_component=linear,
        g_factors=g_factors,
        interactions=interactions,
        crowding_ratio=crowding,
        latent_income_band=list(latent_income_bands),
        income_was_masked=list(income_masked),
    )


def build_observed_dataset(
    records: Sequence[Mapping[str, Any]], y: Sequence[int] | np.ndarray
) -> list[dict[str, Any]]:
    """Monta o dataset observado: ``Q_full`` (48) + ``TARGET_NAME``.

    NUNCA inclui ``M_sim`` (``Z_*``, ``C_*``, ``g_*``, ``eta``, ``p_true``,
    renda latente, etc.). Cada linha tem exatamente 49 chaves.
    """
    out: list[dict[str, Any]] = []
    for record, yi in zip(records, y):
        row = {name: record[name] for name in constants.Q_FULL}
        row[TARGET_NAME] = int(yi)
        out.append(row)
    return out


def build_audit_dataframe(result: TargetResult) -> pd.DataFrame:
    """Monta o DataFrame de auditoria do DGM (colunas na ordem da spec da fase)."""
    n = len(result.Y)
    rows = {
        "row_index": list(range(n)),
        "latent_income_band": result.latent_income_band,
        "income_was_masked": result.income_was_masked,
    }
    for name in G_FACTOR_NAMES:
        rows[name] = result.g_factors[name]
    rows["crowding_ratio"] = result.crowding_ratio
    rows["g_adensamento"] = result.g_factors["g_adensamento"]
    for name in INTERACTION_NAMES:
        rows[name] = result.interactions[name]
    rows["linear_component"] = result.linear_component
    rows["U"] = result.U
    rows["eta"] = result.eta
    rows["p_true"] = result.p_true
    rows[TARGET_SYMBOL] = result.Y

    columns = (
        ["row_index", "latent_income_band", "income_was_masked"]
        + [name for name in G_FACTOR_NAMES if name != "g_adensamento"]
        + ["crowding_ratio", "g_adensamento"]
        + list(INTERACTION_NAMES)
        + ["linear_component", "U", "eta", "p_true", TARGET_SYMBOL]
    )
    return pd.DataFrame(rows)[columns]
