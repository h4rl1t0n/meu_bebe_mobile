"""Geração da dimensão Trabalho e Renda (10 variáveis de Q_full).

Dividida em duas funções para permitir que ``empregado`` e a faixa de renda
latente sejam gerados ANTES da Educação (que usa ``empregado`` em
``dificuldades_educacao``) e antes da Alimentação (que usa a renda latente).
"""

from __future__ import annotations

from .random_utils import (
    linear_delta,
    sample_boolean,
    sample_multiselect,
    sample_ordinal,
)
from .state import SimulationState


def generate_core(state: SimulationState) -> None:
    """Gera ``latent_income_band``, ``faixa_renda`` e ``empregado``."""
    cfg = state.config["work_income"]
    signals = state.signals()
    rec = state.record

    # Renda latente (M_sim) -> faixa de renda observável (com máscara 5%).
    band_cfg = cfg["income_band"]
    band = sample_ordinal(
        state.rng,
        tuple(band_cfg["base"].keys()),
        band_cfg["base"],
        band_cfg["severity"],
        signals[band_cfg["context"]],
        band_cfg["strength"],
    )
    state.latent_income_band = band
    state.income_adv = band_cfg["severity"][band]

    if state.rng.random() < band_cfg["mask_prob"]:
        rec["faixa_renda"] = "nao_informar"
        state.income_was_masked = True
    else:
        rec["faixa_renda"] = band
        state.income_was_masked = False

    # Empregada (estrutural; usado por educação/saúde/alimentação).
    rec["empregado"] = sample_boolean(
        state.rng,
        cfg["empregado"]["base_true"],
        linear_delta(signals, cfg["empregado"]["logit_delta"]),
    )


def generate_rest(state: SimulationState) -> None:
    """Gera os demais campos de Trabalho e Renda."""
    cfg = state.config["work_income"]
    signals = state.signals()
    rec = state.record
    empregado = rec["empregado"]

    # tipo_emprego (somente empregada)
    if empregado:
        te_cfg = cfg["tipo_emprego"]
        rec["tipo_emprego"] = sample_ordinal(
            state.rng,
            tuple(te_cfg["base"].keys()),
            te_cfg["base"],
            te_cfg["severity"],
            signals[te_cfg["context"]],
            te_cfg["strength"],
        )
    else:
        rec["tipo_emprego"] = None

    # Condições de trabalho (somente empregada)
    for field, wc_cfg in cfg["work_conditions"].items():
        if empregado:
            delta = linear_delta(signals, wc_cfg["logit_delta"])
            if rec["tipo_emprego"] == "informal":
                delta -= wc_cfg["informal_reduction"]
            rec[field] = sample_boolean(state.rng, wc_cfg["base_true"], delta)
        else:
            rec[field] = None

    # beneficios_trabalho (somente empregada; `null` quando desempregada).
    if empregado:
        ben_cfg = cfg["beneficios_trabalho"]
        items = list(ben_cfg["base"][rec["tipo_emprego"]].keys())
        delta = linear_delta(signals, ben_cfg["logit_delta"])
        delta_map = {item: delta for item in items}
        rec["beneficios_trabalho"] = sample_multiselect(
            state.rng,
            items,
            ben_cfg["base"][rec["tipo_emprego"]],
            delta_map,
            ben_cfg["exclusive"],
        )
    else:
        rec["beneficios_trabalho"] = None

    # motivo_desemprego (somente desempregada)
    if empregado:
        rec["motivo_desemprego"] = None
    else:
        md_cfg = cfg["motivo_desemprego"]
        rec["motivo_desemprego"] = sample_ordinal(
            state.rng,
            tuple(md_cfg["base"].keys()),
            md_cfg["base"],
            md_cfg["severity"],
            signals[md_cfg["context"]],
            md_cfg["strength"],
        )

    # recebe_beneficio_social
    rec["recebe_beneficio_social"] = sample_boolean(
        state.rng,
        cfg["recebe_beneficio_social"]["base_true"],
        linear_delta(signals, cfg["recebe_beneficio_social"]["logit_delta"]),
    )

    # impacto_gestacao_trabalho (OUT-TEMPORAL, todos os registros)
    imp_cfg = cfg["impacto_gestacao_trabalho"]
    rec["impacto_gestacao_trabalho"] = sample_ordinal(
        state.rng,
        tuple(imp_cfg["base"].keys()),
        imp_cfg["base"],
        imp_cfg["severity"],
        signals[imp_cfg["context"]],
        imp_cfg["strength"],
    )
