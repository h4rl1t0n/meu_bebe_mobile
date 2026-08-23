"""Gerador sintético de Q_full (DSS 1.13).

Subpacote que produz os 48 campos observados do questionário a partir dos
fatores latentes ``Z_*`` e contextos ``C_*``, respeitando as invariantes do
contrato. NÃO gera Y, ``g_*``, ``eta`` nem IV-DSS.
"""

from __future__ import annotations

from .config import (
    GENERATOR_CONFIG_PATH,
    SIMULATION_CONFIG_PATH,
    load_generator_config,
    load_simulation_config,
)
from .generator import GenerationError, generate_q_full, generate_record
from .latent import (
    CONTEXT_NAMES,
    LATENT_NAMES,
    compute_contexts,
    generate_latent_matrix,
)

__all__ = [
    "CONTEXT_NAMES",
    "GENERATOR_CONFIG_PATH",
    "LATENT_NAMES",
    "SIMULATION_CONFIG_PATH",
    "GenerationError",
    "compute_contexts",
    "generate_latent_matrix",
    "generate_q_full",
    "generate_record",
    "load_generator_config",
    "load_simulation_config",
]
