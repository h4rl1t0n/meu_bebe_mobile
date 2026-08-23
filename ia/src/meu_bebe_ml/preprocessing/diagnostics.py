"""Loader e diagnósticos do dataset sintético para o preprocessing v1.

* :func:`load_x_y` — carrega ``dataset_synthetic_v1.jsonl`` e separa
  ``X_raw`` (exatamente as 34 colunas ``X_MODEL``) de ``y``
  (``descontinuou_pre_natal``). Nenhum campo fora de ``X_MODEL`` entra em
  ``X_raw``.
* :func:`check_structural_nulls` — valida que os nulls de ``X_MODEL`` estão
  apenas onde o schema prevê (estruturais), sem null inesperado.

Estas funções NÃO calculam métricas preditivas e NÃO usam ``M_sim``/IV-DSS.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd

from ..schema import constants

_DATASET_PATH = (
    Path(__file__).resolve().parents[3] / "data" / "processed" / "dataset_synthetic_v1.jsonl"
)


def _load_records(path: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    with open(path, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line:
                records.append(json.loads(line))
    return records


def load_x_y(path: Path | None = None) -> tuple[pd.DataFrame, np.ndarray]:
    """Carrega o dataset e separa ``X_raw`` (34 colunas) de ``y``."""
    records = _load_records(path or _DATASET_PATH)
    x_cols = list(constants.X_MODEL)
    X_raw = pd.DataFrame([{k: r[k] for k in x_cols} for r in records], columns=x_cols)
    y = np.asarray([r["descontinuou_pre_natal"] for r in records], dtype=np.int64)
    return X_raw, y


# Campos com null estrutural e o gatilho que o justifica.
_STRUCTURAL_BY_EMPREGADO_FALSE = (
    "tipo_emprego",
    "trabalho_permite_pre_natal",
    "ambiente_trabalho_seguro",
    "tem_pausas_descanso",
    "beneficios_trabalho",
)
_STRUCTURAL_DESTINO_LIXO = ("destino_lixo_sem_coleta",)


def _is_null(v: Any) -> bool:
    if v is None:
        return True
    if isinstance(v, (list, tuple, dict, set, str, bool, int)):
        return False
    if isinstance(v, float):
        return bool(np.isnan(v))
    return False


def check_structural_nulls(X_raw: pd.DataFrame) -> dict[str, Any]:
    """Valida nulls estruturais de ``X_raw`` e devolve um diagnóstico.

    Regras esperadas (schema DSS 1.13):
      * ``tipo_emprego``/``trabalho_permite_pre_natal``/``ambiente_trabalho_seguro``/
        ``tem_pausas_descanso``/``beneficios_trabalho`` — null somente com
        ``empregado == False``;
      * ``destino_lixo_sem_coleta`` — null somente com
        ``frequencia_coleta_lixo == "regular"``;
      * demais campos X_MODEL — nenhum null.
    """
    n = len(X_raw)
    structural_counts: dict[str, int] = {}
    violations: list[str] = []

    empregado = X_raw["empregado"]
    for name in _STRUCTURAL_BY_EMPREGADO_FALSE:
        null_mask = X_raw[name].isna()
        structural_counts[name] = int(null_mask.sum())
        # null em linha com empregado == True é violação.
        bad = (null_mask & (empregado == True)).sum()  # noqa: E712
        if bad:
            violations.append(f"{name}: {int(bad)} null com empregado==True")

    freq = X_raw["frequencia_coleta_lixo"]
    null_mask = X_raw["destino_lixo_sem_coleta"].isna()
    structural_counts["destino_lixo_sem_coleta"] = int(null_mask.sum())
    bad = (null_mask & (freq != "regular")).sum()
    if bad:
        violations.append(
            f"destino_lixo_sem_coleta: {int(bad)} null com coleta != regular"
        )

    # Demais campos: null inesperado.
    unexpected: dict[str, int] = {}
    structural_all = set(_STRUCTURAL_BY_EMPREGADO_FALSE) | set(_STRUCTURAL_DESTINO_LIXO)
    for col in constants.X_MODEL:
        if col in structural_all:
            continue
        n_null = int(X_raw[col].isna().sum())
        if n_null:
            unexpected[col] = n_null
            violations.append(f"{col}: {n_null} null inesperado")

    return {
        "n_rows": n,
        "structural_null_counts": structural_counts,
        "unexpected_null_counts": unexpected,
        "violations": violations,
        "ok": not violations,
    }
