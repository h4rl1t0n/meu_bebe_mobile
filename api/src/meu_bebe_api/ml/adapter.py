"""Adaptador ``DssPayload`` -> registro plano -> DataFrame X_MODEL (FASE 4B).

NÃO duplica preprocessing nem a lista de features: reutiliza os helpers
canônicos do pacote ``meu_bebe_ml`` (``schema.constants.X_MODEL`` e
``features.selectors.select_x_model``). O adaptador apenas achata o payload
aninhado (6 dimensões) em um registro plano e seleciona as 34 features do
modelo na ordem canônica.
"""

from __future__ import annotations

from typing import Any

import pandas as pd

from meu_bebe_ml.features.selectors import select_x_model
from meu_bebe_ml.schema.constants import X_MODEL

from ..contracts.dss import DssPayload

# Dimensões canônicas do envelope JSON (ordem de ``FormularioData.toMap()``).
_DIMENSIONS: tuple[str, ...] = (
    "educacao",
    "trabalho",
    "saneamento",
    "saude",
    "habitacao",
    "alimentacao",
)


def flatten_q_full(payload: DssPayload) -> dict[str, Any]:
    """Achata o payload aninhado em um registro plano ``Q_FULL`` (48 chaves)."""
    data = payload.model_dump(mode="json")
    flat: dict[str, Any] = {}
    for dim in _DIMENSIONS:
        flat.update(data[dim])
    return flat


def to_x_model_dataframe(payload: DssPayload) -> pd.DataFrame:
    """Converte ``DssPayload`` em um DataFrame 1x34 na ordem canônica X_MODEL.

    Usa o mesmo padrão de construção da IA (lista de dicionários + ``columns=``)
    para que listas de múltipla escolha permaneçam como células (object dtype),
    exatamente como no treino.
    """
    flat = flatten_q_full(payload)
    x_row = select_x_model(flat)

    missing = [name for name in X_MODEL if name not in x_row]
    if missing:
        raise ValueError(f"features X_MODEL ausentes após seleção: {missing}")
    extra = [name for name in x_row if name not in X_MODEL]
    if extra:
        raise ValueError(f"features inesperadas após seleção: {extra}")

    return pd.DataFrame([x_row], columns=list(X_MODEL))
