"""Testes dos invariantes dos folds de cross-validation (seções 7, 8, 9).

Os 5 folds de ``StratifiedKFold`` são definidos DENTRO dos 4000 registros de
treino; nenhum registro do TEST participa. Estes testes usam o dataset real
apenas para validar a partição — NÃO calculam métrica preditiva.
"""

from __future__ import annotations

import numpy as np
import pytest

from meu_bebe_ml.preprocessing import load_x_y
from meu_bebe_ml.training import compute_folds, compute_split, load_training_config


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


@pytest.fixture(scope="module")
def folds(data, split):
    _, y = data
    cfg = load_training_config()
    train_row = np.asarray(split.train_idx, dtype=np.int64)
    return compute_folds(
        train_row,
        y[train_row],
        n_splits=cfg.cross_validation.n_splits,
        random_state=cfg.cross_validation.random_state,
        shuffle=cfg.cross_validation.shuffle,
    )


def test_folds_exactly_4000_row_index(folds) -> None:
    assert len(folds.train_row_index) == 4000
    assert len(folds.fold_of) == 4000


def test_folds_all_belong_to_train(split, folds) -> None:
    assert set(folds.train_row_index) <= set(split.train_idx)


def test_folds_none_in_test(split, folds) -> None:
    assert set(folds.train_row_index) & set(split.test_idx) == set()


def test_folds_ids_only_0_to_4(folds) -> None:
    assert set(folds.fold_of) == {0, 1, 2, 3, 4}


def test_folds_each_row_exactly_one_fold(folds) -> None:
    assert len(folds.fold_of) == len(folds.train_row_index)
    # fold_of já tem exatamente um valor por linha (não -1).
    assert all(f in {0, 1, 2, 3, 4} for f in folds.fold_of)


def test_folds_union_equals_train(split, folds) -> None:
    # união dos 5 validation folds == conjunto de treino.
    assert set(folds.train_row_index) == set(split.train_idx)


def test_folds_mutually_disjoint(folds) -> None:
    by_fold = {f: [] for f in range(5)}
    for row, f in zip(folds.train_row_index, folds.fold_of):
        by_fold[f].append(row)
    for f in range(5):
        for g in range(5):
            if f != g:
                assert set(by_fold[f]) & set(by_fold[g]) == set()


def test_folds_stratification_coherent(data, split, folds) -> None:
    _, y = data
    train_rate = float((y[list(split.train_idx)] == 1).mean())
    by_fold = {f: [] for f in range(5)}
    for row, f in zip(folds.train_row_index, folds.fold_of):
        by_fold[f].append(row)
    for f in range(5):
        rows = np.asarray(by_fold[f], dtype=np.int64)
        fold_rate = float((y[rows] == 1).mean())
        assert abs(fold_rate - train_rate) < 0.03


def test_folds_deterministic(data, split, folds) -> None:
    _, y = data
    cfg = load_training_config()
    train_row = np.asarray(split.train_idx, dtype=np.int64)
    again = compute_folds(
        train_row,
        y[train_row],
        n_splits=cfg.cross_validation.n_splits,
        random_state=cfg.cross_validation.random_state,
        shuffle=cfg.cross_validation.shuffle,
    )
    assert again.train_row_index == folds.train_row_index
    assert again.fold_of == folds.fold_of
