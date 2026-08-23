"""Testes da análise de sensibilidade metodológica (FASE 3G-B2).

Cobrem as duas trilhas independentes (3G-B2A conjunto de variáveis e 3G-B2B taxa
média de probabilidade simulada): validação da config, métricas por fold, delta
descritivo entre X_model e X_sens (sem teste de hipótese), geração determinística
dos cenários sintéticos (CRN), monotonicidade alpha/p/Y, DataFrame de desfechos
anti-leakage, descritores relativos por cenário, e guarda anti-TEST/recalibração.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
import pytest

from meu_bebe_ml.evaluation import (
    FEATURE_SET_COUNT_KEYS,
    FEATURE_SET_METRIC_KEYS,
    SENSITIVITY_OUTCOME_COLUMNS,
    build_sensitivity_outcomes_dataframe,
    feature_set_deltas,
    fold_metrics,
    generate_sensitivity_outcomes,
    load_methodological_sensitivity_config,
    per_fold_metrics,
    scenario_fold_metrics,
    scenario_monotonicity,
    scenario_pooled_metrics,
)

_IA_ROOT = Path(__file__).resolve().parents[1]
_MODULE = _IA_ROOT / "src" / "meu_bebe_ml" / "evaluation" / "methodological_sensitivity.py"
_RUN_SCRIPT = _IA_ROOT / "scripts" / "run_methodological_sensitivity.py"
_CONFIG_PATH = _IA_ROOT / "configs" / "methodological_sensitivity_v1.yaml"

_TARGETS = (0.15, 0.25, 0.35)


# ---------------------------------------------------------------------------
# Config (validação de decisões proibidas)
# ---------------------------------------------------------------------------

def test_load_config_rejects_selection_enabled():
    raw = {
        "version": "1.0", "analysis_type": "x", "model": "random_forest",
        "n_expected": 4000, "n_folds": 5,
        "tracks": {
            "feature_set": {"enabled": True, "baseline": "X_model", "sensitivity": "X_sens"},
            "outcome_base_rate": {"enabled": True, "target_mean_probabilities": [0.15, 0.25, 0.35]},
        },
        "evaluation": {"source": "TRAIN_OOF", "folds": "frozen_v1", "threshold_reference": 0.50},
        "selection": {"enabled": True},
        "test_usage": {"allowed": False},
        "recalibration": {"enabled": False},
        "monte_carlo": {"noise_seed": 4241, "outcome_seed": 4242, "noise_sd": 0.50},
    }
    import tempfile, yaml

    with tempfile.NamedTemporaryFile("w", suffix=".yaml", delete=False, encoding="utf-8") as fh:
        yaml.safe_dump(raw, fh)
        path = Path(fh.name)
    try:
        with pytest.raises(ValueError):
            load_methodological_sensitivity_config(path)
    finally:
        path.unlink()


def test_load_config_rejects_wrong_targets():
    import tempfile, yaml

    raw = {
        "version": "1.0", "analysis_type": "x", "model": "random_forest",
        "n_expected": 4000, "n_folds": 5,
        "tracks": {
            "feature_set": {"enabled": True, "baseline": "X_model", "sensitivity": "X_sens"},
            "outcome_base_rate": {"enabled": True, "target_mean_probabilities": [0.1, 0.2, 0.3]},
        },
        "evaluation": {"source": "TRAIN_OOF", "folds": "frozen_v1", "threshold_reference": 0.50},
        "selection": {"enabled": False},
        "test_usage": {"allowed": False},
        "recalibration": {"enabled": False},
        "monte_carlo": {"noise_seed": 4241, "outcome_seed": 4242, "noise_sd": 0.50},
    }
    with tempfile.NamedTemporaryFile("w", suffix=".yaml", delete=False, encoding="utf-8") as fh:
        yaml.safe_dump(raw, fh)
        path = Path(fh.name)
    try:
        with pytest.raises(ValueError):
            load_methodological_sensitivity_config(path)
    finally:
        path.unlink()


def test_load_real_config_frozen_flags():
    cfg = load_methodological_sensitivity_config(_CONFIG_PATH)
    assert cfg.model == "random_forest"
    assert cfg.selection_enabled is False
    assert cfg.test_usage_allowed is False
    assert cfg.recalibration_enabled is False
    assert cfg.target_mean_probabilities == _TARGETS
    assert cfg.noise_seed == 4241
    assert cfg.outcome_seed == 4242
    assert cfg.noise_sd == 0.50
    assert cfg.n_expected == 4000
    assert cfg.n_folds == 5


# ---------------------------------------------------------------------------
# fold_metrics / per_fold_metrics
# ---------------------------------------------------------------------------

def test_fold_metrics_known_values():
    y = np.array([0, 0, 1, 1])
    p = np.array([0.1, 0.2, 0.8, 0.9])
    m = fold_metrics(y, p, threshold=0.50)
    assert m["n"] == 4
    assert m["y0"] == 2
    assert m["y1"] == 2
    assert m["prevalence"] == pytest.approx(0.5)
    assert m["tn"] == 2 and m["fp"] == 0 and m["fn"] == 0 and m["tp"] == 2
    assert m["accuracy"] == pytest.approx(1.0)
    assert m["precision"] == pytest.approx(1.0)
    assert m["recall"] == pytest.approx(1.0)
    assert m["specificity"] == pytest.approx(1.0)
    assert m["f1"] == pytest.approx(1.0)
    assert m["balanced_accuracy"] == pytest.approx(1.0)
    assert m["roc_auc"] == pytest.approx(1.0)
    assert m["pr_auc"] == pytest.approx(1.0)
    assert m["brier"] == pytest.approx(0.025)


def test_per_fold_metrics_returns_5_folds():
    rng = np.random.default_rng(7)
    n = 40
    folds = np.repeat(np.arange(5), 8)
    y = np.tile(np.array([0, 0, 0, 0, 1, 1, 1, 1]), 5)
    p = rng.random(n)
    rows = per_fold_metrics(folds, y, p, n_folds=5)
    assert [r["fold"] for r in rows] == [0, 1, 2, 3, 4]
    for r in rows:
        assert r["n"] == 8
        assert r["y0"] == 4 and r["y1"] == 4


def test_per_fold_metrics_missing_fold_raises():
    folds = np.array([0, 1, 2, 3])
    y = np.array([0, 1, 0, 1])
    p = np.array([0.1, 0.9, 0.2, 0.8])
    with pytest.raises(ValueError):
        per_fold_metrics(folds, y, p, n_folds=5)


# ---------------------------------------------------------------------------
# feature_set_deltas (3G-B2A — sem teste de hipótese)
# ---------------------------------------------------------------------------

def _metric_row(fold: int, roc_auc: float, accuracy: float, tp: int) -> dict:
    return {"fold": fold, "roc_auc": roc_auc, "accuracy": accuracy, "tp": tp}


def test_feature_set_deltas_summary():
    baseline = [_metric_row(0, 0.60, 0.70, 5), _metric_row(1, 0.62, 0.72, 6)]
    sensitivity = [_metric_row(0, 0.61, 0.68, 4), _metric_row(1, 0.64, 0.73, 7)]
    d = feature_set_deltas(baseline, sensitivity, metric_keys=("roc_auc", "accuracy", "tp"))
    per_fold = {r["fold"]: r for r in d["per_fold"]}
    assert per_fold[0]["roc_auc"] == pytest.approx(0.01)
    assert per_fold[0]["accuracy"] == pytest.approx(-0.02)
    assert per_fold[0]["tp"] == pytest.approx(-1.0)
    assert per_fold[1]["tp"] == pytest.approx(1.0)
    s = d["summary"]
    assert s["roc_auc"]["mean"] == pytest.approx(0.015)
    assert s["accuracy"]["mean"] == pytest.approx(-0.005)
    assert s["tp"]["min"] == pytest.approx(-1.0)
    assert s["tp"]["max"] == pytest.approx(1.0)
    assert s["tp"]["range"] == pytest.approx(2.0)
    # std com ddof=1
    assert s["roc_auc"]["std"] == pytest.approx(np.std([0.01, 0.02], ddof=1))


def test_feature_set_deltas_mismatched_folds_raise():
    baseline = [_metric_row(0, 0.6, 0.7, 5)]
    sensitivity = [_metric_row(1, 0.6, 0.7, 5)]
    with pytest.raises(ValueError):
        feature_set_deltas(baseline, sensitivity)


def test_feature_set_keys_frozen():
    assert set(FEATURE_SET_METRIC_KEYS) == {
        "roc_auc", "pr_auc", "brier", "accuracy", "precision", "recall",
        "specificity", "f1", "balanced_accuracy",
    }
    assert FEATURE_SET_COUNT_KEYS == ("tn", "fp", "fn", "tp")


# ---------------------------------------------------------------------------
# generate_sensitivity_outcomes (3G-B2B — CRN, determinismo, calibração)
# ---------------------------------------------------------------------------

def _outcomes(n: int = 200):
    linear = np.zeros(n)
    return generate_sensitivity_outcomes(
        linear,
        noise_seed=4241,
        outcome_seed=4242,
        noise_sd=0.50,
        target_mean_probabilities=_TARGETS,
    )


def test_generate_outcomes_achieved_mean_and_binary_y():
    outcomes = _outcomes()
    assert set(outcomes) == set(_TARGETS)
    for t in _TARGETS:
        o = outcomes[t]
        assert o.target_mean_probability == t
        assert abs(o.achieved_mean_probability - t) < 1e-10
        assert o.realized_prevalence == pytest.approx(float(o.y.mean()))
        assert set(np.unique(o.y)).issubset({0, 1})
        assert o.p_true.shape == (200,)
        assert o.y.shape == (200,)


def test_generate_outcomes_deterministic():
    a = _outcomes()
    b = _outcomes()
    for t in _TARGETS:
        assert a[t].alpha == b[t].alpha
        assert np.array_equal(a[t].y, b[t].y)
        assert np.array_equal(a[t].p_true, b[t].p_true)


def test_generate_outcomes_empty_raises():
    with pytest.raises(ValueError):
        generate_sensitivity_outcomes(
            np.array([]), noise_seed=1, outcome_seed=2, noise_sd=0.5,
            target_mean_probabilities=_TARGETS,
        )


def test_scenario_monotonicity_all_true():
    mono = scenario_monotonicity(_outcomes())
    assert mono == {
        "alpha_strictly_increasing": True,
        "p_non_decreasing": True,
        "y_non_decreasing": True,
    }


def test_scenario_monotonicity_wrong_targets_raise():
    outcomes = generate_sensitivity_outcomes(
        np.zeros(50), noise_seed=1, outcome_seed=2, noise_sd=0.5,
        target_mean_probabilities=(0.15, 0.25),
    )
    with pytest.raises(ValueError):
        scenario_monotonicity(outcomes)


# ---------------------------------------------------------------------------
# build_sensitivity_outcomes_dataframe (anti-leakage)
# ---------------------------------------------------------------------------

def test_outcomes_dataframe_no_folds_no_leakage():
    outcomes = _outcomes(50)
    df = build_sensitivity_outcomes_dataframe(np.arange(50), outcomes)
    assert list(df.columns) == list(SENSITIVITY_OUTCOME_COLUMNS)
    assert len(df) == 50
    for forbidden in ("U_sens", "V_sens", "p_true", "alpha", "linear_component"):
        assert forbidden not in df.columns


def test_outcomes_dataframe_with_folds():
    outcomes = _outcomes(50)
    folds = np.repeat(np.arange(5), 10)
    df = build_sensitivity_outcomes_dataframe(np.arange(50), outcomes, folds=folds)
    assert list(df.columns) == ["row_index", "fold", "y_sens_15", "y_sens_25", "y_sens_35"]
    assert set(df["fold"]) == {0, 1, 2, 3, 4}
    assert len(df) == 50


# ---------------------------------------------------------------------------
# Métricas por cenário (descritores relativos)
# ---------------------------------------------------------------------------

def test_scenario_pooled_metrics_keys_and_values():
    y = np.array([0, 1, 0, 1])
    p = np.array([0.1, 0.9, 0.2, 0.8])
    m = scenario_pooled_metrics(y, p)
    assert m["prevalence"] == pytest.approx(0.5)
    assert m["roc_auc"] == pytest.approx(1.0)
    assert m["pr_auc"] == pytest.approx(1.0)
    assert m["baseline_brier"] == pytest.approx(0.25)
    assert m["pr_auc_minus_prevalence"] == pytest.approx(0.5)
    assert m["pr_auc_over_prevalence"] == pytest.approx(2.0)
    assert set(m) == {
        "n", "prevalence", "roc_auc", "pr_auc", "brier", "baseline_brier",
        "relative_brier_improvement", "pr_auc_minus_prevalence", "pr_auc_over_prevalence",
    }


def test_scenario_pooled_pr_over_prevalence_none_when_zero():
    y = np.zeros(10)
    p = np.full(10, 0.2)
    m = scenario_pooled_metrics(y, p)
    assert m["prevalence"] == 0.0
    assert m["pr_auc_over_prevalence"] is None


def test_scenario_fold_metrics_returns_5_folds():
    rng = np.random.default_rng(11)
    n = 40
    folds = np.repeat(np.arange(5), 8)
    y = np.tile(np.array([0, 0, 0, 0, 1, 1, 1, 1]), 5)
    p = rng.random(n)
    rows = scenario_fold_metrics(folds, y, p, n_folds=5)
    assert [r["fold"] for r in rows] == [0, 1, 2, 3, 4]
    for r in rows:
        assert "baseline_brier" in r
        assert "relative_brier_improvement" in r
        assert "pr_auc_minus_prevalence" in r
        assert r["pr_auc_over_prevalence"] is not None  # prevalência > 0 aqui


# ---------------------------------------------------------------------------
# Guarda anti-TEST / anti-recalibração / anti-seleção
# ---------------------------------------------------------------------------

def test_module_never_references_test_or_recalibration():
    src = _MODULE.read_text(encoding="utf-8")
    assert "test_predictions_selected_v1" not in src
    assert ".fit(" not in src  # módulo é de funções puras; não treina/recalibra nada
    assert "from sklearn.calibration" not in src
    assert "IsotonicRegression" not in src
    assert "class_weight" not in src  # RF congelado; params não são definidos aqui


def test_run_script_never_references_test_predictions():
    src = _RUN_SCRIPT.read_text(encoding="utf-8")
    assert "test_predictions_selected_v1" not in src


# ---------------------------------------------------------------------------
# Consistência com os artefatos gerados (se presentes)
# ---------------------------------------------------------------------------

_JSON = _IA_ROOT / "artifacts" / "metrics" / "methodological_sensitivity_v1.json"
_OUTCOMES_CSV = _IA_ROOT / "data" / "processed" / "sensitivity_outcomes_v1.csv"
_OOF_X_SENS_CSV = _IA_ROOT / "data" / "processed" / "cv_oof_predictions_x_sens_v1.csv"


@pytest.mark.skipif(not _JSON.exists(), reason="artefatos ainda não gerados")
def test_artifacts_consistency():
    import json

    report = json.loads(_JSON.read_text(encoding="utf-8"))
    assert report["model"] == "random_forest"
    assert report["guards"]["test_used"] is False
    assert report["guards"]["recalibration_performed"] is False
    assert report["guards"]["selection_performed"] is False
    assert report["guards"]["noise_or_latent_leaked_in_outcomes_csv"] is False

    mono = report["outcome_base_rate_track"]["monotonicity"]
    assert all(mono.values())

    alphas = []
    for name in ("sensitivity_y_15", "sensitivity_y_25", "sensitivity_y_35"):
        sc = report["outcome_base_rate_track"]["scenarios"][name]
        assert abs(sc["achieved_mean_probability"] - sc["target_mean_probability"]) < 1e-10
        alphas.append(sc["alpha"])
    assert alphas[0] < alphas[1] < alphas[2]


@pytest.mark.skipif(not _OUTCOMES_CSV.exists(), reason="artefatos ainda não gerados")
def test_outcomes_csv_anti_leakage():
    df = pd.read_csv(_OUTCOMES_CSV)
    assert len(df) == 4000
    assert list(df.columns) == ["row_index", "fold", "y_sens_15", "y_sens_25", "y_sens_35"]
    # Y monotônico por linha (mesmo V_sens; p15 <= p25 <= p35)
    assert (df["y_sens_15"] <= df["y_sens_25"]).all()
    assert (df["y_sens_25"] <= df["y_sens_35"]).all()


@pytest.mark.skipif(not _OOF_X_SENS_CSV.exists(), reason="artefatos ainda não gerados")
def test_oof_x_sens_csv_shape():
    df = pd.read_csv(_OOF_X_SENS_CSV)
    assert len(df) == 4000
    assert set(df.columns) == {
        "row_index", "validation_fold", "y_true", "random_forest_probability", "y_pred_050",
    }
    assert df["random_forest_probability"].between(0.0, 1.0).all()
    assert set(df["y_pred_050"]).issubset({0, 1})
