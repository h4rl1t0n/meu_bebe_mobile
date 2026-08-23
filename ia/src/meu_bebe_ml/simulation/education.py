"""Geração da dimensão Educação (6 variáveis de Q_full)."""

from __future__ import annotations

from .random_utils import linear_delta, sample_boolean, sample_multiselect, sample_ordinal
from .state import SimulationState


def generate(state: SimulationState) -> None:
    cfg = state.config["education"]
    signals = state.signals()
    rec = state.record

    # 1) escolaridade (ordinal; adversidade alimenta demais campos)
    esc_cfg = cfg["escolaridade"]
    escolaridade = sample_ordinal(
        state.rng,
        tuple(esc_cfg["base"].keys()),
        esc_cfg["base"],
        esc_cfg["severity"],
        signals[esc_cfg["context"]],
        esc_cfg["strength"],
    )
    rec["escolaridade"] = escolaridade
    state.escolaridade_adv = esc_cfg["severity"][escolaridade]

    # 2) estuda_atualmente (base condicionada à escolaridade)
    rec["estuda_atualmente"] = sample_boolean(
        state.rng,
        cfg["estuda_atualmente"]["base_by_escolaridade"][escolaridade],
        linear_delta(signals, cfg["estuda_atualmente"]["logit_delta"]),
    )

    # 3) situacao_estudos_gestacao (OUT-TEMPORAL)
    if rec["estuda_atualmente"]:
        rec["situacao_estudos_gestacao"] = "nao_interrompeu"
    else:
        sit_cfg = cfg["situacao_estudos_gestacao"]
        interrompeu = sample_boolean(
            state.rng,
            sit_cfg["interrompeu_base"],
            linear_delta(signals, sit_cfg["logit_delta"]),
        )
        rec["situacao_estudos_gestacao"] = "interrompeu" if interrompeu else "nao_estudava"

    # 4) dificuldades_educacao (multiselect; "trabalho" reforçado se empregada)
    dif_cfg = cfg["dificuldades_educacao"]
    items = [c for c in dif_cfg["base"].keys()]
    delta_map: dict[str, float] = {}
    for item in items:
        delta = linear_delta(signals, dif_cfg["logit_delta"].get(item, {}))
        if state.record.get("empregado") is True:
            delta += dif_cfg["empregado_boost"].get(item, 0.0)
        delta_map[item] = delta
    rec["dificuldades_educacao"] = sample_multiselect(
        state.rng, items, dif_cfg["base"], delta_map, dif_cfg["exclusive"]
    )

    # 5) entende_orientacoes_saude
    rec["entende_orientacoes_saude"] = sample_boolean(
        state.rng,
        cfg["entende_orientacoes_saude"]["base_true"],
        linear_delta(signals, cfg["entende_orientacoes_saude"]["logit_delta"]),
    )

    # 6) fez_curso_qualificacao_profissional
    fez_cfg = cfg["fez_curso_qualificacao_profissional"]
    fez_delta = linear_delta(signals, fez_cfg["logit_delta"])
    if state.record.get("empregado") is True:
        fez_delta += fez_cfg["empregado_boost"]
    rec["fez_curso_qualificacao_profissional"] = sample_boolean(
        state.rng, fez_cfg["base_true"], fez_delta
    )
