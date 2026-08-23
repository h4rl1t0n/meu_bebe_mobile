"""Guards anti-leakage do protocolo de treinamento.

Garantem que o treinamento NUNCA receba, como feature ou coluna:
  * ``Z_*`` / ``C_*`` (latentes e contextos do gerador);
  * ``g_*`` / ``interaction_*`` / ``I1`` / ``I2`` / ``linear_component`` /
    ``U`` / ``eta`` / ``p_true`` (internals do DGM);
  * ``latent_income_band`` / ``income_was_masked`` (mascaramento de renda);
  * dimensões/scores do IV-DSS (``D_*``, ``IV_DSS``, ``iv_dss_parcial``, ...);
  * o target ``descontinuou_pre_natal`` (ou ``Y``);
  * metadados experimentais ``row_index`` / ``split`` / ``validation_fold``;
  * qualquer campo fora de ``X_MODEL`` (``OUT_LEAKAGE`` / ``OUT_TEMPORAL`` /
    ``DESCRIPTIVE`` / ``SENSITIVITY``).

O loader de treinamento continua retornando apenas ``X_MODEL`` (34) + ``y``.
"""

from __future__ import annotations

from collections.abc import Iterable

import numpy as np
import pandas as pd

from ..iv_dss.calculator import DIMENSION_NAMES
from ..schema import constants
from ..simulation import (
    CONTEXT_NAMES,
    G_FACTOR_NAMES,
    INTERACTION_NAMES,
    LATENT_NAMES,
    M_SIM_DGM_FIELDS,
)

# Nomes proibidos adicionais (não cobertos pelas tuplas importadas).
_EXTRA_FORBIDDEN = frozenset(
    {
        # Target / símbolo
        "descontinuou_pre_natal",
        "Y",
        # IV-DSS (score agregado + dimensões + saídas parciais)
        "IV_DSS",
        "iv_dss",
        "iv_dss_parcial",
        "iv_dss_partial",
        # IV-DSS contextos auxiliares (C_* específicos do cálculo do índice)
        "C_barreiras",
        "C_distancia",
        "C_agua",
        "C_esgotamento",
        "C_residuos",
        # Metadados experimentais (split/folds NÃO são features)
        "row_index",
        "split",
        "validation_fold",
    }
)


def forbidden_tokens() -> frozenset[str]:
    """Conjunto congelado de tokens proibidos como feature/coluna de treino."""
    tokens = set(_EXTRA_FORBIDDEN)
    tokens.update(LATENT_NAMES)  # Z_*
    tokens.update(CONTEXT_NAMES)  # C_*
    tokens.update(G_FACTOR_NAMES)  # g_*
    tokens.update(INTERACTION_NAMES)  # interaction_*
    tokens.update(M_SIM_DGM_FIELDS)  # latent_income_band, income_was_masked, ...
    tokens.update(DIMENSION_NAMES)  # D_educacao, D_trabalho, ...
    # Campos observados fora de X_MODEL (nunca features de treino).
    tokens.update(constants.OUT_LEAKAGE)
    tokens.update(constants.OUT_TEMPORAL)
    tokens.update(constants.DESCRIPTIVE)
    tokens.update(constants.SENSITIVITY)
    return frozenset(tokens)


def _find_forbidden(columns: Iterable[str]) -> list[str]:
    tokens = forbidden_tokens()
    found = [c for c in columns if c in tokens]
    # Também pega prefixos derivados (ex.: ``feature__categoria`` nunca deve
    # começar com token proibido; ex.: ``g_renda__x``).
    found += [c for c in columns if c.split("__")[0] in tokens]
    # desduplica preservando ordem
    return list(dict.fromkeys(found))


def assert_no_forbidden_columns(columns: Iterable[str]) -> None:
    """Levanta ``ValueError`` se qualquer coluna/feature for proibida."""
    found = _find_forbidden(columns)
    if found:
        raise ValueError(
            f"colunas proibidas no treinamento (M_sim/IV-DSS/DGM/target/"
            f"split-metadata): {sorted(found)!r}"
        )


def assert_x_is_x_model_only(X: pd.DataFrame) -> None:
    """Garante que ``X`` contém EXATAMENTE as 34 colunas de ``X_MODEL``."""
    cols = list(X.columns)
    expected = list(constants.X_MODEL)
    if cols != expected:
        raise ValueError(
            f"X deve conter exatamente X_MODEL (34) na ordem canônica; "
            f"recebido {len(cols)} colunas. extras={sorted(set(cols) - set(expected))!r} "
            f"faltando={sorted(set(expected) - set(cols))!r}"
        )
    assert_no_forbidden_columns(cols)


def y_is_binary(y: np.ndarray) -> bool:
    """Verifica (sem levantar) se ``y`` é binário 0/1."""
    arr = np.asarray(y)
    return set(np.unique(arr)) <= {0, 1}
