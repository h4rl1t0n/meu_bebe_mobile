"""Geração da dimensão Saúde/Acesso (9 variáveis de Q_full, incluindo leakage)."""

from __future__ import annotations

import math

from .random_utils import (
    linear_delta,
    sample_boolean,
    sample_boolean_or_null,
    sample_categorical,
    sample_multiselect,
    sample_ordinal,
)
from .state import ORGANIZATIONAL_BARRIERS, SimulationState


def generate(state: SimulationState) -> None:
    cfg = state.config["health_access"]
    signals = state.signals()
    rec = state.record

    # 1) distancia_ubs (adversidade alimenta dificuldades/faltou_consulta)
    du_cfg = cfg["distancia_ubs"]
    distancia = sample_ordinal(
        state.rng,
        tuple(du_cfg["base"].keys()),
        du_cfg["base"],
        du_cfg["severity"],
        signals[du_cfg["context"]],
        du_cfg["strength"],
    )
    rec["distancia_ubs"] = distancia
    state.distancia_adv = du_cfg["severity"][distancia]

    # 2) acesso_ubs (categórica com deslocamentos por categoria, sem ordinal)
    au_cfg = cfg["acesso_ubs"]
    au_base = au_cfg["base_by_distancia"][distancia]
    au_cats = list(au_base.keys())
    au_probs = [
        au_base[c] * math.exp(linear_delta(signals, au_cfg["logit_delta"].get(c, {})))
        for c in au_cats
    ]
    rec["acesso_ubs"] = sample_categorical(state.rng, au_cats, au_probs)

    # 3) cadastrada_ubs
    rec["cadastrada_ubs"] = sample_boolean(
        state.rng,
        cfg["cadastrada_ubs"]["base_true"],
        linear_delta(signals, cfg["cadastrada_ubs"]["logit_delta"]),
    )

    # 4) dificuldades_saude (multiselect)
    ds_cfg = cfg["dificuldades_saude"]
    ds_items = list(ds_cfg["base"].keys())
    ds_delta: dict[str, float] = {}
    for item in ds_items:
        delta = linear_delta(signals, ds_cfg["logit_delta"].get(item, {}))
        if item == "horario_incompativel" and rec.get("empregado") is True:
            delta += ds_cfg["horario_empregado_boost"]
        ds_delta[item] = delta
    rec["dificuldades_saude"] = sample_multiselect(
        state.rng, ds_items, ds_cfg["base"], ds_delta, ds_cfg["exclusive"]
    )

    # 5) faltou_consulta (OUT-LEAKAGE; NÃO depende de Y, apenas de antecedentes)
    lk = cfg["leakage"]
    faltou_cfg = lk["faltou_consulta"]
    faltou_delta = linear_delta(signals, faltou_cfg["logit_delta"])
    faltou_delta += faltou_cfg["distancia_effect"] * state.distancia_adv
    if "falta_transporte" in rec["dificuldades_saude"]:
        faltou_delta += faltou_cfg["falta_transporte_boost"]
    if ORGANIZATIONAL_BARRIERS & set(rec["dificuldades_saude"]):
        faltou_delta += faltou_cfg["barreira_boost"]
    rec["faltou_consulta"] = sample_boolean_or_null(
        state.rng, faltou_cfg["base_true"], faltou_delta, faltou_cfg["null_rate"]
    )

    # 6) servicos_pre_natal (multiselect)
    sp_cfg = lk["servicos_pre_natal"]
    sp_items = list(sp_cfg["base"].keys())
    sp_delta = linear_delta(signals, sp_cfg["logit_delta"])
    rec["servicos_pre_natal"] = sample_multiselect(
        state.rng,
        sp_items,
        sp_cfg["base"],
        {item: sp_delta for item in sp_items},
        sp_cfg["exclusive"],
    )

    # 7) exames_pre_natal_completos
    ex_cfg = lk["exames_pre_natal_completos"]
    ex_delta = linear_delta(signals, ex_cfg["logit_delta"])
    if ORGANIZATIONAL_BARRIERS & set(rec["dificuldades_saude"]):
        ex_delta += ex_cfg["barreira_boost"]
    rec["exames_pre_natal_completos"] = sample_boolean_or_null(
        state.rng, ex_cfg["base_true"], ex_delta, ex_cfg["null_rate"]
    )

    # 8) vacinas_em_dia
    rec["vacinas_em_dia"] = sample_boolean_or_null(
        state.rng,
        lk["vacinas_em_dia"]["base_true"],
        linear_delta(signals, lk["vacinas_em_dia"]["logit_delta"]),
        lk["vacinas_em_dia"]["null_rate"],
    )

    # 9) avaliacao_pre_natal (ordinal)
    av_cfg = lk["avaliacao_pre_natal"]
    rec["avaliacao_pre_natal"] = sample_ordinal(
        state.rng,
        tuple(av_cfg["base"].keys()),
        av_cfg["base"],
        av_cfg["severity"],
        signals[av_cfg["context"]],
        av_cfg["strength"],
    )
