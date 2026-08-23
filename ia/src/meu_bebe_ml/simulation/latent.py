"""Fatores latentes Z e contextos internos C_* (M_sim).

Gera os cinco fatores ``Z_SES, Z_LAB, Z_TERR, Z_INFRA, Z_SERV`` por normal
multivariada a partir da matriz de correlação congelada em
``simulation_v1.yaml``, e deriva os contextos internos ``C_LAB, C_INFRA,
C_ACCESS, C_FOOD`` usados pelas dimensões do questionário.

Tudo aqui é ``M_sim`` (metadados de simulação) e NUNCA entra em ``Q_full``.
"""

from __future__ import annotations

from typing import Any, Sequence

import numpy as np

LATENT_NAMES: tuple[str, ...] = (
    "Z_SES",
    "Z_LAB",
    "Z_TERR",
    "Z_INFRA",
    "Z_SERV",
)

CONTEXT_NAMES: tuple[str, ...] = (
    "C_LAB",
    "C_INFRA",
    "C_ACCESS",
    "C_FOOD",
)


def generate_latent_matrix(
    rng: np.random.Generator,
    n_samples: int,
    corr_matrix: Sequence[Sequence[float]],
    mean: Sequence[float] | None = None,
) -> np.ndarray:
    """Amostra ``n_samples`` vetores Z (5 dims) por normal multivariada.

    ``corr_matrix`` também é a matriz de covariância, pois cada fator tem
    variância unitária (diagonal = 1).
    """
    mean = list(mean) if mean is not None else [0.0] * len(LATENT_NAMES)
    cov = np.asarray(corr_matrix, dtype=float)
    return rng.multivariate_normal(mean=np.asarray(mean, dtype=float), cov=cov, size=n_samples)


def compute_contexts(
    z_row: np.ndarray, contexts_cfg: dict[str, Any]
) -> dict[str, float]:
    """Deriva os contextos ``C_*`` a partir de um vetor Z.

    ``contexts_cfg`` segue a estrutura do YAML::

        { "C_LAB": {"weights": {"Z_SES": 0.55, "Z_LAB": 0.45}}, ... }

    Também aceita a forma plana ``{"C_LAB": {"Z_SES": 0.55, ...}}``.
    """
    z_index = {name: i for i, name in enumerate(LATENT_NAMES)}
    result: dict[str, float] = {}
    for ctx_name, spec in contexts_cfg.items():
        if isinstance(spec, dict) and "weights" in spec:
            weights = spec["weights"]
        else:
            weights = spec
        value = 0.0
        for z_name, coef in weights.items():
            value += coef * float(z_row[z_index[z_name]])
        result[ctx_name] = value
    return result
