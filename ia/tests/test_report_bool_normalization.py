"""Testes da normalização booleana do relatório (true/false/null).

Garante que a serialização do diagnóstico usa a semântica do contrato
(``true``/``false``/``null``) em vez do artefato de dtype do pandas
(``1.0``/``0.0``/``nan``), sem alterar ``q_full_v1.jsonl``.
"""

from __future__ import annotations

import importlib.util
from pathlib import Path

import numpy as np
import pandas as pd
import pytest

_SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "inspect_q_full.py"


@pytest.fixture(scope="module")
def bool_distribution():
    spec = importlib.util.spec_from_file_location("inspect_q_full", str(_SCRIPT))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod._bool_distribution


def test_nullable_bool_keys_are_semantic(bool_distribution):
    # Simula o artefato do pd.read_json: True→1.0, False→0.0, null→NaN.
    series = pd.Series([1.0, 0.0, np.nan, 1.0, 1.0, 0.0, 0.0, np.nan, 1.0, 0.0])
    dist = bool_distribution(series, len(series))
    assert set(dist.keys()) == {"true", "false", "null"}
    assert dist["true"]["count"] == 4
    assert dist["false"]["count"] == 4
    assert dist["null"]["count"] == 2
    assert dist["true"]["pct"] == 40.0


def test_non_null_bool_omits_null_key(bool_distribution):
    # bool sem null (ex.: estuda_atualmente) não gera a chave 'null'.
    series = pd.Series([True, False, True, True])
    dist = bool_distribution(series, len(series))
    assert set(dist.keys()) == {"true", "false"}
    assert dist["true"]["count"] == 3
    assert dist["false"]["count"] == 1


def test_counts_sum_to_total(bool_distribution):
    series = pd.Series([True, False, np.nan, True, np.nan, False])
    dist = bool_distribution(series, len(series))
    assert sum(v["count"] for v in dist.values()) == len(series)
