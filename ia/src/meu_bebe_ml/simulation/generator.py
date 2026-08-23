"""Orquestrador do gerador sintético de Q_full.

Fluxo de uma gestante: fatores latentes ``Z_*`` → contextos ``C_*`` →
variáveis estruturais → variáveis dependentes → multiselects → ``Q_full``
(48 variáveis) → validação contra o contrato DSS 1.13.

Cada registro retornado contém EXATAMENTE as 48 variáveis canônicas. Os
metadados de auditoria (``M_sim``) são devolvidos separadamente e NUNCA entram
em ``Q_full``. Não há geração de Y, ``g_*``, ``eta`` nem ``IV-DSS`` nesta fase.
"""

from __future__ import annotations

from typing import Any

import numpy as np
import pandas as pd

from ..schema import constants
from ..schema.validator import load_schema, validate_record
from . import education, food, health_access, housing, sanitation, work_income
from .config import load_generator_config, load_simulation_config
from .latent import compute_contexts, generate_latent_matrix
from .state import SimulationState

# Colunas de M_sim devolvidas para auditoria (sem g_*, eta, p_true, Y).
_MSIM_COLUMNS: tuple[str, ...] = (
    "row_index",
    "Z_SES",
    "Z_LAB",
    "Z_TERR",
    "Z_INFRA",
    "Z_SERV",
    "C_LAB",
    "C_INFRA",
    "C_ACCESS",
    "C_FOOD",
    "latent_income_band",
    "income_was_masked",
    "has_piped_water",
    "has_internal_bathroom",
    "has_separate_kitchen",
    "density_target",
)


class GenerationError(RuntimeError):
    """Levantada quando um registro gerado viola o contrato DSS 1.13."""


def generate_record(
    rng: np.random.Generator,
    config: dict[str, Any],
    z_row: np.ndarray,
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Gera UMA gestante: retorna ``(record, m_sim_row)``.

    ``record`` tem exatamente as 48 chaves de ``Q_FULL``; ``m_sim_row`` traz os
    auxiliares internos para auditoria.
    """
    state = SimulationState(rng=rng, config=config)
    state.z_ses, state.z_lab, state.z_terr, state.z_infra, state.z_serv = (
        float(z_row[i]) for i in range(5)
    )
    contexts = compute_contexts(z_row, config["contexts"])
    state.c_lab = contexts["C_LAB"]
    state.c_infra = contexts["C_INFRA"]
    state.c_access = contexts["C_ACCESS"]
    state.c_food = contexts["C_FOOD"]

    # Ordem explícita: núcleo estrutural -> Educação -> restante do Trabalho ->
    # Saneamento -> Saúde -> Habitação -> Alimentação.
    work_income.generate_core(state)
    education.generate(state)
    work_income.generate_rest(state)
    sanitation.generate(state)
    health_access.generate(state)
    housing.generate(state)
    food.generate(state)

    record = {name: state.record[name] for name in constants.Q_FULL}

    m_sim = {
        "Z_SES": state.z_ses,
        "Z_LAB": state.z_lab,
        "Z_TERR": state.z_terr,
        "Z_INFRA": state.z_infra,
        "Z_SERV": state.z_serv,
        "C_LAB": state.c_lab,
        "C_INFRA": state.c_infra,
        "C_ACCESS": state.c_access,
        "C_FOOD": state.c_food,
        "latent_income_band": state.latent_income_band,
        "income_was_masked": state.income_was_masked,
        "has_piped_water": state.has_piped_water,
        "has_internal_bathroom": state.has_internal_bathroom,
        "has_separate_kitchen": state.has_separate_kitchen,
        "density_target": state.density_target,
    }
    return record, m_sim


def generate_q_full(
    n_samples: int | None = None,
    seed: int | None = None,
    config: dict[str, Any] | None = None,
    sim_config: dict[str, Any] | None = None,
    fail_on_invalid: bool = True,
) -> tuple[list[dict[str, Any]], pd.DataFrame]:
    """Gera ``n_samples`` registros de Q_full e o M_sim de auditoria.

    Usa ``seed``/``n_samples`` do YAML quando não informados. Valida cada
    registro contra o contrato DSS 1.13; qualquer violação levanta
    :class:`GenerationError` (nunca salva um dataset parcialmente inválido).
    """
    config = config if config is not None else load_generator_config()
    sim_config = sim_config if sim_config is not None else load_simulation_config()

    n = n_samples if n_samples is not None else int(config["n_samples"])
    seed_val = seed if seed is not None else int(config["seed"])

    rng = np.random.default_rng(seed_val)
    corr = sim_config["z_correlation_matrix"]
    mean = config["latent"]["mean"]
    Z = generate_latent_matrix(rng, n, corr, mean)

    spec = load_schema()

    records: list[dict[str, Any]] = []
    m_sim_rows: list[dict[str, Any]] = []

    for i in range(n):
        record, m_sim = generate_record(rng, config, Z[i])
        errors = validate_record(record, spec)
        if errors:
            if fail_on_invalid:
                raise GenerationError(
                    f"registro {i} inválido: {errors[:5]}"
                )
            # fallback: registra mas não valida (somente para depuração)
        m_sim["row_index"] = i
        records.append(record)
        m_sim_rows.append(m_sim)

    m_sim_df = pd.DataFrame(m_sim_rows, columns=_MSIM_COLUMNS)
    return records, m_sim_df
