"""Geração da dimensão Alimentação (7 variáveis de Q_full)."""

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
    cfg = state.config["food"]
    signals = state.signals()
    rec = state.record

    # 1) refeicoes_por_dia (ordinal; C_FOOD + Z_SES)
    rf_cfg = cfg["refeicoes_por_dia"]
    rf_context = signals[rf_cfg["context"]] + rf_cfg["z_ses_extra"] * state.z_ses
    rec["refeicoes_por_dia"] = sample_ordinal(
        state.rng,
        tuple(rf_cfg["base"].keys()),
        rf_cfg["base"],
        rf_cfg["severity"],
        rf_context,
        rf_cfg["strength"],
    )

    # 2) deixou_de_comer_falta_dinheiro (renda latente + pessoas + Z_SES)
    rec["deixou_de_comer_falta_dinheiro"] = sample_boolean(
        state.rng,
        cfg["deixou_de_comer_falta_dinheiro"]["base_true"],
        linear_delta(signals, cfg["deixou_de_comer_falta_dinheiro"]["logit_delta"]),
    )

    # 3) alimentos_consumidos (multiselect)
    al_cfg = cfg["alimentos_consumidos"]
    al_items = list(al_cfg["base"].keys())
    al_base_delta = linear_delta(signals, al_cfg["logit_delta"])
    al_delta = dict.fromkeys(al_items, al_base_delta)
    if rec["deixou_de_comer_falta_dinheiro"]:
        for item in al_items:
            al_delta[item] -= al_cfg["deixou_de_comer_reduction"]
    rec["alimentos_consumidos"] = sample_multiselect(
        state.rng, al_items, al_cfg["base"], al_delta, al_cfg["exclusive"]
    )

    # 4) fonte_alimentos (multiselect SEM exclusivo; fallback garante não vazio)
    fo_cfg = cfg["fonte_alimentos"]
    fo_items = list(fo_cfg["base"].keys())
    fo_delta = {
        item: linear_delta(signals, fo_cfg["logit_delta"].get(item, {}))
        for item in fo_items
    }
    fonte = sample_multiselect(state.rng, fo_items, fo_cfg["base"], fo_delta, None)
    if not fonte:
        fb = fo_cfg["fallback_base"]
        fonte = [
            sample_categorical(state.rng, list(fb.keys()), list(fb.values()))
        ]
    rec["fonte_alimentos"] = fonte

    # 5) mudanca_alimentacao_gestacao (OUT-TEMPORAL)
    rec["mudanca_alimentacao_gestacao"] = sample_boolean(
        state.rng,
        cfg["mudanca_alimentacao_gestacao"]["base_true"],
        linear_delta(signals, cfg["mudanca_alimentacao_gestacao"]["logit_delta"]),
    )

    # 6) usa_suplementos (OUT-TEMPORAL)
    rec["usa_suplementos"] = sample_boolean(
        state.rng,
        cfg["usa_suplementos"]["base_true"],
        linear_delta(signals, cfg["usa_suplementos"]["logit_delta"]),
    )

    # 7) avaliacao_alimentacao (ordinal; Z_SES + privação alimentar)
    av_cfg = cfg["avaliacao_alimentacao"]
    av_context = signals[av_cfg["context"]]
    if rec["deixou_de_comer_falta_dinheiro"]:
        av_context += av_cfg["deixou_de_comer_effect"]
    rec["avaliacao_alimentacao"] = sample_ordinal(
        state.rng,
        tuple(av_cfg["base"].keys()),
        av_cfg["base"],
        av_cfg["severity"],
        av_context,
        av_cfg["strength"],
    )
