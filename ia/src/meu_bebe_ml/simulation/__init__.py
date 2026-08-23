"""Gerador sintético de ``Q_full`` e do desfecho ``Y`` (DSS 1.13).

Subpacote que (1) produz os 48 campos observados do questionário a partir dos
fatores latentes ``Z_*`` e contextos ``C_*``, e (2) gera o desfecho sintético
experimental ``Y`` via DGM (``g_*`` → ``linear`` → ``eta`` → ``sigmoid`` →
Bernoulli). NÃO implementa IV-DSS nem modelos de ML.
"""

from __future__ import annotations

from .calibration import calibrate_alpha, sigmoid
from .config import (
    GENERATOR_CONFIG_PATH,
    SIMULATION_CONFIG_PATH,
    load_generator_config,
    load_simulation_config,
)
from .dgm import (
    DGM_INPUT_FIELDS,
    G_FACTOR_NAMES,
    INTERACTION_NAMES,
    M_SIM_DGM_FIELDS,
    compute_g_factors,
    compute_linear_component,
    load_dgm_spec,
)
from .generator import GenerationError, generate_q_full, generate_record
from .latent import (
    CONTEXT_NAMES,
    LATENT_NAMES,
    compute_contexts,
    generate_latent_matrix,
)
from .target import (
    TARGET_NAME,
    TARGET_SYMBOL,
    TargetResult,
    build_audit_dataframe,
    build_observed_dataset,
    generate_target,
)

__all__ = [
    "CONTEXT_NAMES",
    "DGM_INPUT_FIELDS",
    "GENERATOR_CONFIG_PATH",
    "G_FACTOR_NAMES",
    "INTERACTION_NAMES",
    "LATENT_NAMES",
    "M_SIM_DGM_FIELDS",
    "SIMULATION_CONFIG_PATH",
    "TARGET_NAME",
    "TARGET_SYMBOL",
    "TargetResult",
    "GenerationError",
    "build_audit_dataframe",
    "build_observed_dataset",
    "calibrate_alpha",
    "compute_contexts",
    "compute_g_factors",
    "compute_linear_component",
    "generate_latent_matrix",
    "generate_q_full",
    "generate_record",
    "generate_target",
    "load_dgm_spec",
    "load_generator_config",
    "load_simulation_config",
    "sigmoid",
]
