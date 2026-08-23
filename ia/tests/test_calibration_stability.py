"""Testes da análise diagnóstica de calibração/estabilidade (FASE 3G-B1).

Cobrem (seções 27–29): validação de probabilidades/tamanhos, classe única
quando a métrica exige ambas, Brier e baseline Brier conhecidos, gap de
calibração, mean/weighted mean absolute bin gap, resumos por classe e por fold,
presença de todos os folds, fold desconhecido -> erro, baseline por fold usando
apenas a training portion, nenhuma função requer TEST, determinismo e
consistência com resultados anteriores (N=4000, y0/y1, ROC-AUC, PR-AUC).
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
import pytest
from sklearn.calibration import calibration_curve

from meu_bebe_ml.evaluation import (
    CalibrationStabilityConfig,
    brier_and_baseline,
    calibration_bins,
    calibration_in_the_large,
    distribution_by_class,
    mean_absolute_bin_gap,
    per_fold_diagnostics,
    probability_summary,
    pr_auc,
    roc_auc,
    stability_summary,
    summarize_calibration,
    training_prevalence,
    validate_folds_present,
    weighted_mean_absolute_bin_gap,
)

_IA_ROOT = Path(__file__).resolve().parents[1]
_OOF_PATH = _IA_ROOT / "data" / "processed" / "cv_oof_predictions_v1.csv"
_MODULE = _IA_ROOT / "src" / "meu_bebe_ml" / "evaluation" / "calibration_stability.py"
_ANALYZE_SCRIPT = _IA_ROOT / "scripts" / "analyze_oof_calibration.py"


def _config() -> CalibrationStabilityConfig:
    return CalibrationStabilityConfig(
        version="1.0",
        analysis_type="secondary_diagnostic",
        model="random_forest",
        source="OOF_TRAIN",
        n_expected=4000,
        n_folds=5,
        n_bins=10,
        strategy="quantile",
        recalibration_enabled=False,
        test_usage_allowed=False,
        primary_threshold_reference=0.50,
    )


# ---------------------------------------------------------------------------
# Validação de entradas (seção 27)
# ---------------------------------------------------------------------------

def test_invalid_probability_raises():
    with pytest.raises(ValueError):
        calibration_bins(np.array([0, 1]), np.array([0.4, 1.5]))


def test_nan_probability_raises():
    with pytest.raises(ValueError):
        calibration_bins(np.array([0, 1]), np.array([0.4, np.nan]))


def test_length_mismatch_raises():
    with pytest.raises(ValueError):
        brier_and_baseline(np.array([0, 1]), np.array([0.4]), 0.5)


def test_single_class_roc_auc_is_undefined():
    # roc_auc_score do sklearn NÃO levanta erro com classe única: devolve NaN
    # (com aviso). O diagnóstico deve ser tratado como "indefinido", nunca como
    # um score válido.
    import warnings

    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        val = roc_auc(np.array([0, 0, 0]), np.array([0.1, 0.2, 0.3]))
    assert np.isnan(val)


def test_invalid_baseline_probability_raises():
    with pytest.raises(ValueError):
        brier_and_baseline(np.array([0, 1]), np.array([0.4, 0.6]), 1.7)


# ---------------------------------------------------------------------------
# Brier e baseline Brier conhecidos (seção 8, 27)
# ---------------------------------------------------------------------------

def test_known_brier_and_baseline():
    y = np.array([0, 1, 0, 1])
    p = np.array([0.2, 0.8, 0.3, 0.7])
    r = brier_and_baseline(y, p, baseline_probability=0.5)
    assert r["brier_model"] == pytest.approx(0.065)
    assert r["brier_baseline"] == pytest.approx(0.25)
    assert r["brier_difference"] == pytest.approx(0.065 - 0.25)
    assert r["brier_relative_improvement"] == pytest.approx((0.25 - 0.065) / 0.25)


# ---------------------------------------------------------------------------
# Bins de calibração e gaps (seções 6, 14, 27)
# ---------------------------------------------------------------------------

def test_calibration_gap_uniform_bins():
    y = np.array([0, 1])
    p = np.array([0.4, 0.6])
    bins = calibration_bins(y, p, n_bins=2, strategy="uniform")
    assert len(bins) == 2
    b0, b1 = bins
    assert b0["mean_predicted_probability"] == pytest.approx(0.4)
    assert b0["fraction_of_positives"] == pytest.approx(0.0)
    assert b0["calibration_gap"] == pytest.approx(-0.4)
    assert b0["absolute_calibration_gap"] == pytest.approx(0.4)
    assert b1["calibration_gap"] == pytest.approx(0.4)


def test_calibration_bins_match_sklearn():
    rng = np.random.default_rng(1)
    y = rng.integers(0, 2, size=300)
    p = rng.random(300)
    bins = calibration_bins(y, p, n_bins=5, strategy="quantile")
    prob_true, prob_pred = calibration_curve(y, p, n_bins=5, strategy="quantile")
    assert [b["fraction_of_positives"] for b in bins] == pytest.approx(list(prob_true))
    assert [b["mean_predicted_probability"] for b in bins] == pytest.approx(list(prob_pred))


def test_mean_and_weighted_gap():
    bins = [
        {"n": 1, "calibration_gap": 0.5},
        {"n": 3, "calibration_gap": 0.1},
    ]
    assert mean_absolute_bin_gap(bins) == pytest.approx(0.3)
    assert weighted_mean_absolute_bin_gap(bins) == pytest.approx(0.2)


def test_empty_bins_gap_is_zero():
    assert mean_absolute_bin_gap([]) == 0.0
    assert weighted_mean_absolute_bin_gap([]) == 0.0


# ---------------------------------------------------------------------------
# Resumos por classe e por fold (seções 10, 16, 27)
# ---------------------------------------------------------------------------

def test_probability_summary_keys_and_values():
    s = probability_summary(np.array([0.1, 0.2, 0.3, 0.4, 0.5]))
    assert s["n"] == 5
    assert s["mean_probability"] == pytest.approx(0.3)
    assert s["median_probability"] == pytest.approx(0.3)
    assert s["min_probability"] == pytest.approx(0.1)
    assert s["max_probability"] == pytest.approx(0.5)
    assert s["q25"] == pytest.approx(np.quantile([0.1, 0.2, 0.3, 0.4, 0.5], 0.25))
    assert set(s) == {
        "n", "mean_probability", "std_probability", "min_probability",
        "max_probability", "median_probability", "q05", "q25", "q50", "q75", "q95",
    }


def test_distribution_by_class():
    y = np.array([0, 0, 1, 1])
    p = np.array([0.1, 0.2, 0.8, 0.9])
    d = distribution_by_class(y, p)
    assert d["y0"]["n"] == 2
    assert d["y1"]["n"] == 2
    assert d["y0"]["mean_probability"] == pytest.approx(0.15)
    assert d["y1"]["mean_probability"] == pytest.approx(0.85)


# ---------------------------------------------------------------------------
# Folds (seções 10–13, 27)
# ---------------------------------------------------------------------------

def test_validate_folds_present_ok():
    validate_folds_present(np.array([0, 1, 2, 3, 4]), n_folds=5)


def test_validate_folds_present_missing_raises():
    with pytest.raises(ValueError):
        validate_folds_present(np.array([0, 1, 2, 3]), n_folds=5)


def test_validate_folds_present_unknown_raises():
    with pytest.raises(ValueError):
        validate_folds_present(np.array([0, 1, 2, 3, 9]), n_folds=5)


def test_training_prevalence_uses_other_folds_only():
    folds = np.array([0, 0, 1, 1])
    y = np.array([0, 1, 1, 0])
    # training portion do fold 0 = folds 1 -> y[2:4] = [1, 0] -> prev 0.5
    assert training_prevalence(folds, y, fold_id=0) == pytest.approx(0.5)
    assert training_prevalence(folds, y, fold_id=1) == pytest.approx(0.5)


def test_per_fold_diagnostics_returns_5_folds():
    rng = np.random.default_rng(2)
    n = 40
    folds = np.repeat(np.arange(5), 8)
    # cada fold com 4 zeros e 4 uns -> sempre ambas as classes (roc_auc exige).
    y = np.tile(np.array([0, 0, 0, 0, 1, 1, 1, 1]), 5)
    p = rng.random(n)
    rows = per_fold_diagnostics(folds, y, p)
    assert [r["fold"] for r in rows] == [0, 1, 2, 3, 4]
    for r in rows:
        assert r["n"] == 8
        assert r["y0"] == 4
        assert r["y1"] == 4
        assert 0.0 <= r["brier"] <= 1.0
        assert 0.0 <= r["roc_auc"] <= 1.0
        assert 0.0 <= r["pr_auc"] <= 1.0
        assert len(r["calibration_bins"]) <= 5


def test_per_fold_baseline_uses_training_portion():
    # cada fold tem a mesma prevalência observada, mas o baseline usa o resto.
    folds = np.array([0, 0, 1, 1, 2, 2, 3, 3, 4, 4])
    y = np.array([1, 0, 1, 0, 1, 0, 1, 0, 1, 0])  # prev 0.5 em todo lugar
    p = np.full(10, 0.5)
    rows = per_fold_diagnostics(folds, y, p)
    for r in rows:
        # training portion (8 registros) também tem 4 positivos -> prev 0.5
        assert r["training_prevalence_used_for_baseline"] == pytest.approx(0.5)
        assert r["baseline_brier"] == pytest.approx(0.25)  # (0.5 - y)^2 = 0.25


def test_stability_summary_metrics():
    rows = [
        {"brier": 0.1, "roc_auc": 0.6, "pr_auc": 0.3, "mean_probability": 0.25,
         "observed_positive_rate": 0.2, "calibration_in_the_large_difference": 0.05},
        {"brier": 0.3, "roc_auc": 0.8, "pr_auc": 0.5, "mean_probability": 0.35,
         "observed_positive_rate": 0.4, "calibration_in_the_large_difference": -0.05},
    ]
    s = stability_summary(rows)
    assert set(s) == {
        "brier", "roc_auc", "pr_auc", "mean_probability",
        "observed_positive_rate", "calibration_in_the_large_difference",
    }
    assert s["brier"]["mean"] == pytest.approx(0.2)
    assert s["brier"]["min"] == pytest.approx(0.1)
    assert s["brier"]["max"] == pytest.approx(0.3)
    assert s["brier"]["range"] == pytest.approx(0.2)


# ---------------------------------------------------------------------------
# Determinismo e flags (seções 24, 27)
# ---------------------------------------------------------------------------

def test_summarize_is_deterministic_and_flags_false():
    rng = np.random.default_rng(3)
    n = 40
    folds = np.repeat(np.arange(5), 8)
    # cada fold com 4 zeros e 4 uns -> sempre ambas as classes (roc_auc exige).
    y = np.tile(np.array([0, 0, 0, 0, 1, 1, 1, 1]), 5)
    p = rng.random(n)
    cfg = _config()
    s1 = summarize_calibration(cfg, folds, y, p)
    s2 = summarize_calibration(cfg, folds, y, p)
    assert s1 == s2
    assert s1["recalibration_performed"] is False
    assert s1["test_used"] is False
    assert s1["model_modified"] is False
    assert s1["n"] == 40


# ---------------------------------------------------------------------------
# Anti-TEST (seção 28)
# ---------------------------------------------------------------------------

def test_module_never_references_test_or_recalibration():
    src = _MODULE.read_text(encoding="utf-8")
    assert "test_predictions_selected_v1" not in src
    assert "predict_proba" not in src
    assert "CalibratedClassifierCV" not in src
    assert "IsotonicRegression" not in src
    assert ".fit(" not in src


def test_analyze_script_never_references_test_predictions():
    src = _ANALYZE_SCRIPT.read_text(encoding="utf-8")
    assert "test_predictions_selected_v1" not in src


# ---------------------------------------------------------------------------
# Consistência com resultados anteriores (seção 29)
# ---------------------------------------------------------------------------

def test_consistency_with_previous_results():
    oof = pd.read_csv(_OOF_PATH)
    y = oof["y_true"].to_numpy()
    p = oof["random_forest_probability"].to_numpy()

    assert len(oof) == 4000
    assert int((y == 0).sum()) == 3023
    assert int((y == 1).sum()) == 977
    assert p.mean() == pytest.approx(0.24607, abs=1e-3)

    folds = oof["validation_fold"].to_numpy(dtype=np.int64)
    cfg = _config()
    summary = summarize_calibration(cfg, folds, y, p)

    g = summary["global"]
    # MÉDIA DOS FOLDS — métrica canônica da seleção (FASE 3F-B).
    assert g["mean_fold_roc_auc"] == pytest.approx(0.609831, abs=1e-4)
    assert g["mean_fold_pr_auc"] == pytest.approx(0.350786, abs=1e-4)
    # POOLED OOF — AUC sobre as 4000 predições concatenadas (transparência).
    assert g["pooled_oof_roc_auc"] == pytest.approx(0.609684, abs=1e-4)
    assert g["pooled_oof_pr_auc"] == pytest.approx(0.344891, abs=1e-4)
    # As duas noções NÃO coincidem (pooled ≠ média dos folds) — transparência.
    assert g["mean_fold_roc_auc"] != pytest.approx(g["pooled_oof_roc_auc"], abs=1e-5)
    assert g["mean_fold_pr_auc"] != pytest.approx(g["pooled_oof_pr_auc"], abs=1e-5)
