"""Geração da dimensão Habitação (9 variáveis de Q_full)."""

from __future__ import annotations

from typing import Any

from .random_utils import (
    linear_delta,
    sample_boolean,
    sample_int_ordinal,
    sample_multiselect,
    sample_ordinal,
    sigmoid,
)
from .state import ORGANIZATIONAL_BARRIERS, SimulationState


def _melhorias_delta(
    item: str, boost_cfg: dict[str, float], state: SimulationState
) -> float:
    """Computa o deslocamento logit de um item de ``melhorias_desejadas``."""
    rec = state.record
    delta = 0.0
    for condition, value in boost_cfg.get(item, {}).items():
        if condition == "comodo_unico" and rec["tipo_moradia"] == "comodo_unico":
            delta += value
        elif condition == "n_pessoas_high" and rec["numero_pessoas"] >= 6:
            delta += value
        elif condition == "material_nao_alvenaria" and rec["material_moradia"] != "alvenaria":
            delta += value
        elif condition == "no_banheiro_interno" and not state.has_internal_bathroom:
            delta += value
        elif condition == "no_agua_encanada" and not state.has_piped_water:
            delta += value
        elif condition == "interrupcoes_agua" and rec["interrupcoes_agua"] is True:
            delta += value
        elif condition == "seguranca_baixa" and rec["seguranca_residencia"] in (
            "insegura",
            "muito_insegura",
        ):
            delta += value
    return delta


def generate(state: SimulationState) -> None:
    cfg = state.config["housing"]
    signals = state.signals()
    rec = state.record

    # 1) tipo_moradia
    tm_cfg = cfg["tipo_moradia"]
    rec["tipo_moradia"] = sample_ordinal(
        state.rng,
        tuple(tm_cfg["base"].keys()),
        tm_cfg["base"],
        tm_cfg["severity"],
        signals[tm_cfg["context"]],
        tm_cfg["strength"],
    )

    # 2) material_moradia
    mm_cfg = cfg["material_moradia"]
    rec["material_moradia"] = sample_ordinal(
        state.rng,
        tuple(mm_cfg["base"].keys()),
        mm_cfg["base"],
        mm_cfg["severity"],
        signals[mm_cfg["context"]],
        mm_cfg["strength"],
    )

    # 3) numero_pessoas (1..8)
    np_cfg = cfg["numero_pessoas"]
    pessoas = sample_int_ordinal(
        state.rng,
        list(range(1, 9)),
        np_cfg["base"],
        np_cfg["severity"],
        signals[np_cfg["context"]],
        np_cfg["strength"],
    )
    rec["numero_pessoas"] = pessoas
    state.n_pessoas_std = (pessoas - 1) / 7.0

    # 4) alvo de densidade (M_sim) -> dormitórios e cômodos
    dt_cfg = cfg["density_target"]
    density = dt_cfg["intercept"] + dt_cfg["c_infra_coef"] * sigmoid(state.c_infra)
    density += state.rng.normal(0.0, dt_cfg["noise_sd"])
    density = float(min(max(density, dt_cfg["clip_min"]), dt_cfg["clip_max"]))
    state.density_target = density

    if rec["tipo_moradia"] == "comodo_unico":
        rec["numero_dormitorios"] = 1
        rec["numero_comodos"] = 1
    else:
        dormitorios = int(round(pessoas / density))
        dormitorios = max(1, min(pessoas, dormitorios))
        rec["numero_dormitorios"] = dormitorios

        extra_cfg = cfg["extra_comodos"]
        extra = int(state.rng.integers(extra_cfg["min"], extra_cfg["max"] + 1))
        reduction = int(round(extra_cfg["c_infra_reduction"] * sigmoid(state.c_infra)))
        extra = max(0, extra - reduction)
        rec["numero_comodos"] = dormitorios + extra

    # 5) itens da residência (banheiro/cozinha + água encanada)
    it_cfg = cfg["itens_residencia"]
    bath_delta = linear_delta(signals, it_cfg["logit_delta"])
    kitchen_delta = linear_delta(signals, it_cfg["logit_delta"])
    if rec["tipo_moradia"] == "comodo_unico":
        kitchen_delta -= it_cfg["comodo_unico_cozinha_reduction"]

    state.has_internal_bathroom = sample_boolean(
        state.rng, it_cfg["banheiro_interno_base"], bath_delta
    )
    state.has_separate_kitchen = sample_boolean(
        state.rng, it_cfg["cozinha_separada_base"], kitchen_delta
    )

    itens: list[str] = []
    if state.has_piped_water:
        itens.append("agua_encanada")
    if state.has_internal_bathroom:
        itens.append("banheiro_interno")
    if state.has_separate_kitchen:
        itens.append("cozinha_separada")
    rec["itens_residencia"] = itens if itens else [it_cfg["exclusive"]]

    # 6) seguranca_residencia
    seg_cfg = cfg["seguranca_residencia"]
    seg_context = signals[seg_cfg["context"]] + seg_cfg["z_ses_extra"] * state.z_ses
    seguranca = sample_ordinal(
        state.rng,
        tuple(seg_cfg["base"].keys()),
        seg_cfg["base"],
        seg_cfg["severity"],
        seg_context,
        seg_cfg["strength"],
    )
    rec["seguranca_residencia"] = seguranca
    state.seguranca_adv = seg_cfg["severity"][seguranca]

    # 7) melhorias_desejadas (multiselect com antecedentes habitacionais)
    me_cfg = cfg["melhorias_desejadas"]
    me_items = list(me_cfg["base"].keys())
    me_delta = {
        item: _melhorias_delta(item, me_cfg["boost"], state) for item in me_items
    }
    rec["melhorias_desejadas"] = sample_multiselect(
        state.rng, me_items, me_cfg["base"], me_delta, me_cfg["exclusive"]
    )

    # 8) facil_acesso_saude (SENSIBILIDADE)
    fa_cfg = cfg["facil_acesso_saude"]
    fa_delta = linear_delta(signals, fa_cfg["logit_delta"])
    fa_delta += fa_cfg["distancia_effect"] * state.distancia_adv
    if "falta_transporte" in rec["dificuldades_saude"]:
        fa_delta += fa_cfg["falta_transporte_boost"]
    if ORGANIZATIONAL_BARRIERS & set(rec["dificuldades_saude"]):
        fa_delta += fa_cfg["barreira_boost"]
    rec["facil_acesso_saude"] = sample_boolean(
        state.rng, fa_cfg["base_true"], fa_delta
    )
