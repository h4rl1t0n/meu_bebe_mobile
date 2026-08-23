"""Testes da análise secundária exploratória de thresholds (FASE 3G-A).

Cobrem (seções 24–26 e 29): validação de threshold/prob/tamanho, definições
corretas das métricas (recall/specificity/precision/NPV/F1/balanced accuracy/
predicted positive rate), grade de 46 thresholds (0.05..0.50), ordem
determinística, thresholds de referência no intervalo, exploratory max-F1 sem
alterar o threshold primário, ``selected_new_threshold`` sempre ``None``, guarda
anti-TEST e reprodutibilidade (sem RNG).
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pytest

from meu_bebe_ml.evaluation import (
    ThresholdAnalysisConfig,
    build_threshold_grid,
    compute_threshold_metrics,
    compute_threshold_table,
    find_exploratory_max_f1,
    load_threshold_config,
    summarize_analysis,
    validate_oof_train_only,
)

_IA_ROOT = Path(__file__).resolve().parents[1]
_ANALYZE_SCRIPT = _IA_ROOT / "scripts" / "analyze_oof_thresholds.py"


def _config() -> ThresholdAnalysisConfig:
    return ThresholdAnalysisConfig(
        version="1.0",
        analysis_type="secondary_exploratory",
        source="OOF TRAIN",
        model="random_forest",
        n_expected=4000,
        primary_threshold_reference=0.50,
        grid_start=0.05,
        grid_stop=0.50,
        grid_step=0.01,
        reference_thresholds=(0.10, 0.20, 0.30, 0.40, 0.50),
        selection_enabled=False,
    )


# ---------------------------------------------------------------------------
# Validação de entradas (seção 24)
# ---------------------------------------------------------------------------

def test_invalid_threshold_below_zero_raises():
    with pytest.raises(ValueError):
        compute_threshold_metrics(np.array([0, 1]), np.array([0.4, 0.6]), threshold=-0.1)


def test_invalid_threshold_above_one_raises():
    with pytest.raises(ValueError):
        compute_threshold_metrics(np.array([0, 1]), np.array([0.4, 0.6]), threshold=1.5)


def test_probability_outside_range_raises():
    with pytest.raises(ValueError):
        compute_threshold_metrics(np.array([0, 1]), np.array([0.4, 1.5]), threshold=0.5)


def test_length_mismatch_raises():
    with pytest.raises(ValueError):
        compute_threshold_metrics(np.array([0, 1]), np.array([0.4]), threshold=0.5)


# ---------------------------------------------------------------------------
# Definições das métricas (seções 5 e 6)
# ---------------------------------------------------------------------------

def test_known_confusion_matrix_balanced():
    y = np.array([0, 1, 0, 1])
    p = np.array([0.9, 0.9, 0.1, 0.1])  # pred [1,1,0,0]
    m = compute_threshold_metrics(y, p, threshold=0.50)
    assert (m["tn"], m["fp"], m["fn"], m["tp"]) == (1, 1, 1, 1)
    assert m["n"] == 4
    assert m["accuracy"] == pytest.approx(0.5)
    assert m["recall"] == pytest.approx(0.5)
    assert m["specificity"] == pytest.approx(0.5)
    assert m["precision"] == pytest.approx(0.5)
    assert m["negative_predictive_value"] == pytest.approx(0.5)
    assert m["f1"] == pytest.approx(0.5)
    assert m["false_positive_rate"] == pytest.approx(0.5)
    assert m["false_negative_rate"] == pytest.approx(0.5)
    assert m["balanced_accuracy"] == pytest.approx(0.5)
    assert m["predicted_positive_count"] == 2
    assert m["predicted_positive_rate"] == pytest.approx(0.5)


def test_known_confusion_matrix_perfect():
    y = np.array([0, 0, 1, 1])
    p = np.array([0.1, 0.2, 0.8, 0.9])  # pred [0,0,1,1]
    m = compute_threshold_metrics(y, p, threshold=0.50)
    assert (m["tn"], m["fp"], m["fn"], m["tp"]) == (2, 0, 0, 2)
    assert m["recall"] == pytest.approx(1.0)
    assert m["specificity"] == pytest.approx(1.0)
    assert m["precision"] == pytest.approx(1.0)
    assert m["negative_predictive_value"] == pytest.approx(1.0)
    assert m["f1"] == pytest.approx(1.0)
    assert m["false_positive_rate"] == pytest.approx(0.0)
    assert m["false_negative_rate"] == pytest.approx(0.0)
    assert m["balanced_accuracy"] == pytest.approx(1.0)
    assert m["predicted_positive_count"] == 2


def test_zero_division_returns_zero():
    # Nenhum predito positivo -> precision/f1/fpr zero; recall/fnr dependem.
    y = np.array([0, 0, 1, 1])
    p = np.array([0.1, 0.2, 0.3, 0.4])  # threshold 0.5 -> pred [0,0,0,0]
    m = compute_threshold_metrics(y, p, threshold=0.50)
    assert (m["tp"], m["fp"]) == (0, 0)
    assert m["precision"] == pytest.approx(0.0)
    assert m["f1"] == pytest.approx(0.0)
    assert m["false_positive_rate"] == pytest.approx(0.0)
    assert m["recall"] == pytest.approx(0.0)


def test_return_keys_complete():
    m = compute_threshold_metrics(np.array([0, 1]), np.array([0.4, 0.6]))
    assert set(m) == {
        "threshold", "n", "tn", "fp", "fn", "tp", "accuracy", "precision",
        "recall", "specificity", "f1", "negative_predictive_value",
        "false_positive_rate", "false_negative_rate", "balanced_accuracy",
        "predicted_positive_count", "predicted_positive_rate",
    }


# ---------------------------------------------------------------------------
# Grade de thresholds (seções 7 e 24)
# ---------------------------------------------------------------------------

def test_grid_has_46_thresholds_first_last():
    grid = build_threshold_grid()
    assert len(grid) == 46
    assert grid[0] == pytest.approx(0.05)
    assert grid[-1] == pytest.approx(0.50)


def test_grid_strictly_increasing_deterministic():
    grid = build_threshold_grid()
    assert all(a < b for a, b in zip(grid, grid[1:]))
    assert grid == build_threshold_grid()  # determinístico


def test_grid_rejects_bad_params():
    with pytest.raises(ValueError):
        build_threshold_grid(step=0.0)
    with pytest.raises(ValueError):
        build_threshold_grid(start=0.9, stop=0.1)


def test_reference_thresholds_in_interval():
    cfg = _config()
    grid = build_threshold_grid(cfg.grid_start, cfg.grid_stop, cfg.grid_step)
    for t in cfg.reference_thresholds:
        assert cfg.grid_start <= t <= cfg.grid_stop
        assert any(abs(t - g) < 1e-9 for g in grid)


# ---------------------------------------------------------------------------
# exploratory max-F1 (seções 21, 24)
# ---------------------------------------------------------------------------

def test_find_exploratory_max_f1_selects_grid_max():
    y = np.array([0, 0, 1, 1])
    p = np.array([0.1, 0.2, 0.8, 0.9])
    table = compute_threshold_table(y, p, build_threshold_grid(0.1, 0.9, 0.2))
    best = find_exploratory_max_f1(table)
    # com separação perfeita, F1=1 em qualquer threshold entre 0.2 e 0.8
    assert best["f1"] == pytest.approx(1.0)
    assert best["threshold"] == pytest.approx(0.3)  # menor threshold entre os empatados


def test_summarize_keeps_primary_and_no_selection():
    cfg = _config()
    y = np.array([0, 0, 1, 1])
    p = np.array([0.1, 0.2, 0.8, 0.9])
    table = compute_threshold_table(
        y, p, build_threshold_grid(cfg.grid_start, cfg.grid_stop, cfg.grid_step)
    )
    summary = summarize_analysis(table, cfg, y, p)
    assert summary["primary_threshold_reference"] == pytest.approx(0.50)
    assert summary["primary_threshold"] == pytest.approx(0.50)
    assert summary["operational_threshold_selected"] is False
    assert summary["selected_new_threshold"] is None
    assert summary["n"] == 4
    assert summary["y0"] == 2 and summary["y1"] == 2
    assert summary["positive_rate"] == pytest.approx(0.5)


# ---------------------------------------------------------------------------
# Guarda anti-TEST (seção 25)
# ---------------------------------------------------------------------------

def test_validate_oof_train_only_accepts_pure_train():
    validate_oof_train_only(
        np.array([0, 1, 2]), np.array([0, 1, 2, 3]), np.array([4, 5])
    )


def test_validate_oof_train_only_rejects_test_index():
    with pytest.raises(ValueError):
        validate_oof_train_only(
            np.array([0, 4]), np.array([0, 1, 2, 3]), np.array([4, 5])
        )


def test_validate_oof_train_only_rejects_outside_train():
    with pytest.raises(ValueError):
        validate_oof_train_only(
            np.array([0, 9]), np.array([0, 1, 2, 3]), np.array([4, 5])
        )


def test_analyze_script_never_references_test_predictions():
    src = _ANALYZE_SCRIPT.read_text(encoding="utf-8")
    assert "test_predictions_selected_v1" not in src
    assert "test_predictions_selected_v1.csv" not in src


# ---------------------------------------------------------------------------
# Repro­dutibilidade (seção 26) — sem RNG
# ---------------------------------------------------------------------------

def test_compute_table_is_deterministic():
    rng = np.random.default_rng(0)
    y = rng.integers(0, 2, size=200)
    p = rng.random(200)
    grid = build_threshold_grid()
    t1 = compute_threshold_table(y, p, grid)
    t2 = compute_threshold_table(y, p, grid)
    assert t1 == t2


# ---------------------------------------------------------------------------
# Monotonicidade (seção 29)
# ---------------------------------------------------------------------------

def test_monotonicity_of_counts_rates_recall_fpr_specificity():
    y = np.array([0, 0, 1, 1])
    p = np.array([0.3, 0.6, 0.4, 0.7])
    table = compute_threshold_table(y, p, build_threshold_grid(0.1, 0.9, 0.1))
    ppc = [r["predicted_positive_count"] for r in table]
    ppr = [r["predicted_positive_rate"] for r in table]
    recall = [r["recall"] for r in table]
    fpr = [r["false_positive_rate"] for r in table]
    specificity = [r["specificity"] for r in table]

    assert all(a >= b for a, b in zip(ppc, ppc[1:]))      # não-crescente
    assert all(a >= b for a, b in zip(ppr, ppr[1:]))
    assert all(a >= b for a, b in zip(recall, recall[1:]))
    assert all(a >= b for a, b in zip(fpr, fpr[1:]))
    assert all(a <= b for a, b in zip(specificity, specificity[1:]))  # não-decrescente


# ---------------------------------------------------------------------------
# Config real (committed) — valida seleção desativada e grade
# ---------------------------------------------------------------------------

def test_load_threshold_config_selection_disabled():
    cfg = load_threshold_config()
    assert cfg.model == "random_forest"
    assert cfg.selection_enabled is False
    assert cfg.primary_threshold_reference == pytest.approx(0.50)
    assert len(build_threshold_grid(cfg.grid_start, cfg.grid_stop, cfg.grid_step)) == 46
