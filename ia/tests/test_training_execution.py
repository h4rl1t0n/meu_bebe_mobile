"""Testes da infraestrutura de execução da FASE 3F-B (seção 26).

Cobrem, com fixtures pequenas (sem repetir o CV pesado dos 3 modelos no dataset
principal): split/folds congelados, folds corretos, agregação mean/std, seleção
do modelo (PR-AUC → Recall → F1 e empate total → erro), junção/cobertura do OOF,
métricas completas, serialização joblib (round-trip) e a avaliação no TEST.

Qualquer treinamento aqui é pequeno (subconjunto de ~600 linhas, Logistic
Regression) — apenas para validar o MECANISMO, não o desempenho real.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
import pytest

from meu_bebe_ml.training import (
    aggregate_fold_metrics,
    assert_pipeline_model_is,
    build_xgboost_pipeline,
    compute_full_metrics,
    evaluate_final_test,
    fit_final_model,
    fold_splits,
    load_frozen_dataset,
    load_frozen_folds,
    load_frozen_split,
    load_model,
    merge_oof,
    n_features_of,
    positive_class_index,
    positive_class_probability,
    save_model,
    select_model_with_reason,
    validate_oof_coverage,
)

_PROB_COLS = (
    "logistic_probability",
    "random_forest_probability",
    "xgboost_probability",
)


# ---------------------------------------------------------------------------
# Fixtures (carregam o dataset real uma única vez por módulo)
# ---------------------------------------------------------------------------

@pytest.fixture(scope="module")
def x_y():
    return load_frozen_dataset()


@pytest.fixture(scope="module")
def lr_pipe(x_y):
    X_raw, y = x_y
    return fit_final_model("logistic_regression", X_raw.iloc[:600], y[:600])


# ---------------------------------------------------------------------------
# Split / folds congelados
# ---------------------------------------------------------------------------

def test_load_frozen_split_shapes_and_classes(x_y):
    _, y = x_y
    train_idx, test_idx = load_frozen_split()
    assert len(train_idx) == 4000
    assert len(test_idx) == 1000
    assert not (set(train_idx) & set(test_idx))
    assert set(train_idx) | set(test_idx) == set(range(5000))

    y_train = y[train_idx]
    y_test = y[test_idx]
    assert (y_train == 0).sum() == 3023
    assert (y_train == 1).sum() == 977
    assert (y_test == 0).sum() == 756
    assert (y_test == 1).sum() == 244


def test_load_frozen_folds_coverage():
    folds = load_frozen_folds()
    assert len(folds) == 4000
    assert set(folds["validation_fold"]) == {0, 1, 2, 3, 4}
    assert len(folds) == len(set(folds["row_index"]))  # cada row exatamente 1 fold


def test_fold_splits_partition_train():
    train_idx, test_idx = load_frozen_split()
    folds = load_frozen_folds()
    splits = fold_splits(folds, n_splits=5)

    assert len(splits) == 5
    val_rows = []
    for fold_id, (train_rows, val) in enumerate(splits):
        assert len(val) == 800
        assert len(train_rows) == 3200
        # fold de validação nunca toca o TEST
        assert not (set(val) & set(test_idx))
        assert not (set(train_rows) & set(test_idx))
        val_rows.extend(val)

    # a união das validações particiona exatamente o TRAIN (cada linha 1x)
    assert sorted(val_rows) == sorted(train_idx)


# ---------------------------------------------------------------------------
# Métricas completas + agregação
# ---------------------------------------------------------------------------

def test_compute_full_metrics_tn_fp_fn_tp():
    y = np.array([0, 1, 0, 1])
    p = np.array([0.9, 0.9, 0.1, 0.1])  # pred [1,1,0,0]
    m = compute_full_metrics(y, p)
    assert (m["tn"], m["fp"], m["fn"], m["tp"]) == (1, 1, 1, 1)
    assert m["threshold"] == 0.50
    assert "roc_auc" in m and "pr_auc" in m and "brier_score" in m


def test_aggregate_fold_metrics_mean_std():
    fm = [
        {"fold": 0, "accuracy": 0.8, "precision": 0.7, "recall": 0.6, "f1": 0.65,
         "roc_auc": 0.9, "pr_auc": 0.5, "brier_score": 0.2},
        {"fold": 1, "accuracy": 0.9, "precision": 0.8, "recall": 0.7, "f1": 0.75,
         "roc_auc": 0.95, "pr_auc": 0.6, "brier_score": 0.1},
    ]
    agg = aggregate_fold_metrics(fm)
    assert agg["mean_metrics"]["accuracy"] == pytest.approx(0.85)
    assert agg["mean_metrics"]["pr_auc"] == pytest.approx(0.55)
    assert agg["std_metrics"]["accuracy"] == pytest.approx(np.std([0.8, 0.9], ddof=1))
    assert set(agg["mean_metrics"]) == {
        "accuracy", "precision", "recall", "f1", "roc_auc", "pr_auc", "brier_score",
    }


# ---------------------------------------------------------------------------
# Seleção do modelo
# ---------------------------------------------------------------------------

def test_select_highest_pr_auc():
    s = {
        "A": {"mean_pr_auc": 0.7, "mean_recall": 0.9, "mean_f1": 0.9},
        "B": {"mean_pr_auc": 0.8, "mean_recall": 0.1, "mean_f1": 0.1},
    }
    name, reason, ranking, tiebreak_used = select_model_with_reason(s)
    assert name == "B"
    assert not tiebreak_used
    assert ranking[0]["model"] == "B"


def test_select_tiebreak_recall():
    s = {
        "A": {"mean_pr_auc": 0.7, "mean_recall": 0.6, "mean_f1": 0.9},
        "B": {"mean_pr_auc": 0.7, "mean_recall": 0.8, "mean_f1": 0.1},
    }
    name, _, _, tiebreak_used = select_model_with_reason(s)
    assert name == "B"
    assert tiebreak_used


def test_select_tiebreak_f1():
    s = {
        "A": {"mean_pr_auc": 0.7, "mean_recall": 0.8, "mean_f1": 0.5},
        "B": {"mean_pr_auc": 0.7, "mean_recall": 0.8, "mean_f1": 0.6},
    }
    name, _, _, tiebreak_used = select_model_with_reason(s)
    assert name == "B"
    assert tiebreak_used


def test_select_total_tie_raises():
    s = {
        "A": {"mean_pr_auc": 0.7, "mean_recall": 0.8, "mean_f1": 0.6},
        "B": {"mean_pr_auc": 0.7, "mean_recall": 0.8, "mean_f1": 0.6},
    }
    with pytest.raises(RuntimeError):
        select_model_with_reason(s)


def test_select_empty_raises():
    with pytest.raises(ValueError):
        select_model_with_reason({})


def test_select_missing_key_raises():
    with pytest.raises(ValueError):
        select_model_with_reason({"A": {"mean_pr_auc": 0.7}})


# ---------------------------------------------------------------------------
# OOF (junção + cobertura)
# ---------------------------------------------------------------------------

def _entry(row, fold, y_true, col, prob):
    return {"row_index": row, "validation_fold": fold, "y_true": y_true, col: prob}


def test_merge_oof():
    oof = {
        "logistic_regression": {
            0: _entry(0, 0, 0, "logistic_probability", 0.1),
            1: _entry(1, 1, 1, "logistic_probability", 0.9),
        },
        "random_forest": {
            0: _entry(0, 0, 0, "random_forest_probability", 0.2),
            1: _entry(1, 1, 1, "random_forest_probability", 0.8),
        },
        "xgboost": {
            0: _entry(0, 0, 0, "xgboost_probability", 0.3),
            1: _entry(1, 1, 1, "xgboost_probability", 0.7),
        },
    }
    df = merge_oof(oof)
    assert list(df.columns) == ["row_index", "validation_fold", "y_true", *_PROB_COLS]
    assert len(df) == 2
    assert df.loc[df["row_index"] == 1, "xgboost_probability"].iloc[0] == pytest.approx(0.7)


def test_merge_oof_inconsistent_raises():
    oof = {
        "logistic_regression": {
            0: _entry(0, 0, 0, "logistic_probability", 0.1),
        },
        "random_forest": {
            0: _entry(0, 0, 1, "random_forest_probability", 0.2),  # y_true diverge
        },
    }
    with pytest.raises(ValueError):
        merge_oof(oof)


def _oof_df(rows):
    return pd.DataFrame(
        {
            "row_index": [r for r, _ in rows],
            "validation_fold": [f for _, f in rows],
            "y_true": [0] * len(rows),
            "logistic_probability": [0.5] * len(rows),
            "random_forest_probability": [0.5] * len(rows),
            "xgboost_probability": [0.5] * len(rows),
        }
    )


def test_validate_oof_coverage_ok():
    df = _oof_df([(0, 0), (1, 1), (2, 2)])
    validate_oof_coverage(df, np.array([0, 1, 2]))


def test_validate_oof_coverage_missing_raises():
    df = _oof_df([(0, 0), (1, 1)])
    with pytest.raises(ValueError):
        validate_oof_coverage(df, np.array([0, 1, 2]))


# ---------------------------------------------------------------------------
# Fit final + serialização + avaliação no TEST (mecanismo)
# ---------------------------------------------------------------------------

def test_final_pipeline_has_96_features(lr_pipe):
    assert n_features_of(lr_pipe) == 96


def test_assert_pipeline_model_is(lr_pipe):
    assert_pipeline_model_is(lr_pipe, "logistic_regression")
    with pytest.raises(ValueError):
        assert_pipeline_model_is(lr_pipe, "random_forest")


def test_final_pipeline_serialization_roundtrip(x_y, lr_pipe, tmp_path):
    X_raw, _ = x_y
    path = tmp_path / "model.joblib"
    save_model(lr_pipe, path)
    loaded = load_model(path)

    proba = loaded.predict_proba(X_raw.iloc[600:650])[:, 1]
    assert proba.shape == (50,)
    assert np.all(proba >= 0.0) and np.all(proba <= 1.0)
    assert_pipeline_model_is(loaded, "logistic_regression")


def test_evaluate_final_test_consistent(x_y, lr_pipe):
    X_raw, y = x_y
    X_test = X_raw.iloc[600:650]
    y_test = y[600:650]

    res = evaluate_final_test("logistic_regression", lr_pipe, X_test, y_test, threshold=0.50)

    assert res["selected_model"] == "logistic_regression"
    assert res["n_test"] == 50
    assert len(res["y_probability"]) == 50
    assert len(res["y_pred"]) == 50
    proba = np.asarray(res["y_probability"])
    pred = np.asarray(res["y_pred"])
    assert np.all(proba >= 0.0) and np.all(proba <= 1.0)
    assert np.array_equal(pred, (proba >= 0.50).astype(int))

    tn = int(((y_test == 0) & (pred == 0)).sum())
    fp = int(((y_test == 0) & (pred == 1)).sum())
    fn = int(((y_test == 1) & (pred == 0)).sum())
    tp = int(((y_test == 1) & (pred == 1)).sum())
    assert (res["tn"], res["fp"], res["fn"], res["tp"]) == (tn, fp, fn, tp)
    assert "calibration_curve" in res
    assert "average_precision" in res


def test_xgboost_final_scale_pos_weight_from_train_only(x_y):
    _, y = x_y
    train_idx, _ = load_frozen_split()
    y_train = y[train_idx]
    pipe = build_xgboost_pipeline(y_fit=y_train)
    spw = pipe.named_steps["model"].get_params()["scale_pos_weight"]

    n_neg = int((y_train == 0).sum())
    n_pos = int((y_train == 1).sum())
    assert n_neg == 3023 and n_pos == 977
    assert spw == pytest.approx(n_neg / n_pos)


# ---------------------------------------------------------------------------
# Classe positiva (proteção anti-silêncio na coluna de predict_proba)
# ---------------------------------------------------------------------------

def test_positive_class_index_derives_from_classes(x_y, lr_pipe):
    X_raw, _ = x_y
    model = lr_pipe.named_steps["model"]

    assert positive_class_index(model) == 1
    proba = lr_pipe.predict_proba(X_raw.iloc[:10])
    # a prob. da classe positiva via classes_ == predict_proba[:, 1]
    assert np.array_equal(positive_class_probability(model, proba), proba[:, 1])
    assert positive_class_probability(model, proba).shape == (10,)


def test_positive_class_index_rejects_non_binary():
    class _Fake:
        classes_ = [0, 2]

    with pytest.raises(ValueError):
        positive_class_index(_Fake())


def test_positive_class_probability_rejects_1d():
    class _Fake:
        classes_ = [0, 1]

    with pytest.raises(ValueError):
        positive_class_probability(_Fake(), np.array([0.1, 0.9]))
