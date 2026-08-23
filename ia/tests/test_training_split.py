"""Testes dos invariantes do split principal (seções 4, 5, 6, 32).

O split é 80/20 estratificado sobre ``row_index`` (posição original no JSONL),
com ``random_state=42`` e ``shuffle=True``. Estes testes usam o dataset real
apenas para validar a partição — NÃO calculam métrica preditiva.
"""

from __future__ import annotations

import numpy as np
import pytest

from meu_bebe_ml.preprocessing import load_x_y
from meu_bebe_ml.schema import constants
from meu_bebe_ml.training import compute_split, load_training_config


@pytest.fixture(scope="module")
def data():
    X_raw, y = load_x_y()
    return X_raw, y


@pytest.fixture(scope="module")
def split(data):
    _, y = data
    cfg = load_training_config()
    return compute_split(
        y,
        test_size=cfg.split.test_size,
        random_state=cfg.split.random_state,
        shuffle=cfg.split.shuffle,
        stratify=cfg.split.stratified,
    )


def test_split_exactly_5000_row_index(data) -> None:
    _, y = data
    assert len(y) == 5000


def test_split_exactly_4000_train(split) -> None:
    assert len(split.train_idx) == 4000


def test_split_exactly_1000_test(split) -> None:
    assert len(split.test_idx) == 1000


def test_split_no_duplicate_row_index(split) -> None:
    all_idx = list(split.train_idx) + list(split.test_idx)
    assert len(all_idx) == len(set(all_idx))


def test_split_train_test_disjoint(split) -> None:
    assert set(split.train_idx) & set(split.test_idx) == set()


def test_split_union_all_records(split) -> None:
    assert set(split.train_idx) | set(split.test_idx) == set(range(5000))


def test_split_same_seed_same_split(data, split) -> None:
    _, y = data
    cfg = load_training_config()
    again = compute_split(
        y,
        test_size=cfg.split.test_size,
        random_state=cfg.split.random_state,
        shuffle=cfg.split.shuffle,
        stratify=cfg.split.stratified,
    )
    assert again.train_idx == split.train_idx
    assert again.test_idx == split.test_idx


def test_split_different_seed_different_split(data) -> None:
    _, y = data
    cfg = load_training_config()
    a = compute_split(
        y,
        test_size=cfg.split.test_size,
        random_state=42,
        shuffle=cfg.split.shuffle,
        stratify=cfg.split.stratified,
    )
    b = compute_split(
        y,
        test_size=cfg.split.test_size,
        random_state=43,
        shuffle=cfg.split.shuffle,
        stratify=cfg.split.stratified,
    )
    assert a.train_idx != b.train_idx


def test_split_stratification_preserved(data, split) -> None:
    _, y = data
    total_rate = float((y == 1).mean())
    train_y = y[list(split.train_idx)]
    test_y = y[list(split.test_idx)]
    train_rate = float((train_y == 1).mean())
    test_rate = float((test_y == 1).mean())
    # estratificação preserva a proporção (pequena tolerância).
    assert abs(train_rate - total_rate) < 0.01
    assert abs(test_rate - total_rate) < 0.01


def test_split_target_not_in_x(data) -> None:
    X_raw, _ = data
    assert "descontinuou_pre_natal" not in X_raw.columns
    assert set(X_raw.columns) == set(constants.X_MODEL)


def test_split_metadata_never_features(data, split) -> None:
    """row_index/split/validation_fold NUNCA aparecem em X_model."""
    X_raw, _ = data
    cols = set(X_raw.columns)
    for meta in ("row_index", "split", "validation_fold"):
        assert meta not in cols
    # e o split opera sobre índices, não sobre colunas de X.
    assert len(split.train_idx) + len(split.test_idx) == len(X_raw)
