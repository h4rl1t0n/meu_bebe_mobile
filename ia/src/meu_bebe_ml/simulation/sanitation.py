"""Geração da dimensão Saneamento (7 variáveis de Q_full)."""

from __future__ import annotations

from .random_utils import (
    linear_delta,
    sample_boolean,
    sample_categorical,
    sample_multiselect,
    sample_ordinal,
)
from .state import SimulationState


def generate(state: SimulationState) -> None:
    cfg = state.config["sanitation"]
    signals = state.signals()
    rec = state.record

    # 1) água encanada interna (M_sim) -> determina presença em itens_residencia
    state.has_piped_water = sample_boolean(
        state.rng,
        cfg["has_piped_water"]["base_true"],
        linear_delta(signals, cfg["has_piped_water"]["logit_delta"]),
    )

    # 2) fonte_agua (base condicionada à água encanada)
    fa_cfg = cfg["fonte_agua"]
    fa_base = (
        fa_cfg["base_with_piped"] if state.has_piped_water else fa_cfg["base_without_piped"]
    )
    fonte_agua = sample_ordinal(
        state.rng,
        tuple(fa_cfg["severity"].keys()),
        fa_base,
        fa_cfg["severity"],
        signals[fa_cfg["context"]],
        fa_cfg["strength"],
    )
    rec["fonte_agua"] = fonte_agua

    # 3) interrupcoes_agua
    int_cfg = cfg["interrupcoes_agua"]
    int_delta = linear_delta(signals, int_cfg["logit_delta"]) + int_cfg["fonte_boost"].get(
        fonte_agua, 0.0
    )
    rec["interrupcoes_agua"] = sample_boolean(state.rng, int_cfg["base_true"], int_delta)

    # 4) esgotamento_sanitario
    esg_cfg = cfg["esgotamento_sanitario"]
    rec["esgotamento_sanitario"] = sample_ordinal(
        state.rng,
        tuple(esg_cfg["base"].keys()),
        esg_cfg["base"],
        esg_cfg["severity"],
        signals[esg_cfg["context"]],
        esg_cfg["strength"],
    )

    # 5) frequencia_coleta_lixo
    col_cfg = cfg["frequencia_coleta_lixo"]
    frequencia = sample_ordinal(
        state.rng,
        tuple(col_cfg["base"].keys()),
        col_cfg["base"],
        col_cfg["severity"],
        signals[col_cfg["context"]],
        col_cfg["strength"],
    )
    rec["frequencia_coleta_lixo"] = frequencia

    # 6) destino_lixo_sem_coleta (condicional)
    if frequencia == "regular":
        rec["destino_lixo_sem_coleta"] = None
    else:
        dest_cfg = cfg["destino_lixo_sem_coleta"]
        dest_base = (
            dest_cfg["base_irregular"] if frequencia == "irregular" else dest_cfg["base_nao_possui"]
        )
        rec["destino_lixo_sem_coleta"] = sample_categorical(
            state.rng, list(dest_base.keys()), list(dest_base.values())
        )

    # 7) problema_saude_agua (SENSIBILIDADE)
    psa_cfg = cfg["problema_saude_agua"]
    psa_delta = linear_delta(signals, psa_cfg["logit_delta"])
    psa_delta += psa_cfg["fonte_boost"].get(fonte_agua, 0.0)
    if rec["interrupcoes_agua"]:
        psa_delta += psa_cfg["interrupcoes_boost"]
    rec["problema_saude_agua"] = sample_boolean(state.rng, psa_cfg["base_true"], psa_delta)

    # 8) cuidados_vetores (multiselect, DESCRIPTIVE)
    cv_cfg = cfg["cuidados_vetores"]
    items = list(cv_cfg["base"].keys())
    delta_map = {
        item: linear_delta(signals, cv_cfg["logit_delta"].get(item, {})) for item in items
    }
    rec["cuidados_vetores"] = sample_multiselect(
        state.rng, items, cv_cfg["base"], delta_map, cv_cfg["exclusive"]
    )
