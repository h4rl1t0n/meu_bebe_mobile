"""Testes da interpretabilidade pós-hoc por permutation importance OOF (FASE 3H).

Cobrem: validação da config (decisões proibidas rejeitadas), permutação de
variáveis brutas e de grupos (preservação das demais colunas, integridade dos
valores brutos), determinismo do RNG por SeedSequence, métricas e convenção de
sinal dos deltas (positivo = deterioração; negativos permitidos), agregação
(mean dos repeats dentro do fold; mean/std/min/max dos fold means), ranking
descendente com desempate, guarda anti-TEST, e validação dos inputs diretos do
DGM.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
import pytest

from meu_bebe_ml.evaluation import (
    FEATURE_SUMMARY_COLUMNS,
    REPEAT_COLUMNS,
    SECONDARY_METRICS,
    STRUCTURAL_GROUPS,
    PRIMARY_METRIC,
    aggregate_fold_means,
    aggregate_repeats_within_fold,
    assert_no_test_rows,
    baseline_metrics,
    is_direct_dgm_input,
    load_interpretability_config,
    metric_deltas,
    permutation_indices,
    permutation_seed_sequence,
    permute_raw_feature,
    permute_raw_group,
    rank_features_descending,
    summarize_dgm_context,
    validate_direct_dgm_inputs,
)

_IA_ROOT = Path(__file__).resolve().parents[1]
_MODULE = _IA_ROOT / "src" / "meu_bebe_ml" / "evaluation" / "interpretability.py"
_RUN_SCRIPT = _IA_ROOT / "scripts" / "run_interpretability_analysis.py"
_INSPECT_SCRIPT = _IA_ROOT / "scripts" / "inspect_interpretability.py"
_CONFIG_PATH = _IA_ROOT / "configs" / "interpretability_v1.yaml"

_EXPECTED_DIRECT = frozenset(
    {
        "escolaridade",
        "faixa_renda",
        "distancia_ubs",
        "dificuldades_saude",
        "empregado",
        "trabalho_permite_pre_natal",
        "deixou_de_comer_falta_dinheiro",
        "numero_pessoas",
        "numero_dormitorios",
    }
)


# ---------------------------------------------------------------------------
# Config (validação de decisões proibidas)
# ---------------------------------------------------------------------------

def _write_config(overrides: dict) -> Path:
    import tempfile

    import yaml

    base = {
        "version": "1.0",
        "analysis_type": "secondary_posthoc_interpretability",
        "model": "random_forest",
        "feature_set": "X_model",
        "source": "TRAIN_OOF",
        "n_expected": 4000,
        "folds": 5,
        "permutation": {"n_repeats": 20, "seed": 314159},
        "primary_importance_metric": "pr_auc",
        "secondary_metrics": ["roc_auc", "brier"],
        "test_usage": {"allowed": False},
        "model_selection": {"enabled": False},
        "feature_selection": {"enabled": False},
        "recalibration": {"enabled": False},
    }
    base.update(overrides)
    fh = tempfile.NamedTemporaryFile("w", suffix=".yaml", delete=False, encoding="utf-8")
    yaml.safe_dump(base, fh)
    fh.close()
    return Path(fh.name)


def test_load_config_rejects_test_usage():
    path = _write_config({"test_usage": {"allowed": True}})
    try:
        with pytest.raises(ValueError):
            load_interpretability_config(path)
    finally:
        path.unlink()


def test_load_config_rejects_selection_and_recalibration():
    for overrides in (
        {"model_selection": {"enabled": True}},
        {"feature_selection": {"enabled": True}},
        {"recalibration": {"enabled": True}},
    ):
        path = _write_config(overrides)
        try:
            with pytest.raises(ValueError):
                load_interpretability_config(path)
        finally:
            path.unlink()


def test_load_real_config_frozen_flags():
    cfg = load_interpretability_config(_CONFIG_PATH)
    assert cfg.version == "1.0"
    assert cfg.analysis_type == "secondary_posthoc_interpretability"
    assert cfg.model == "random_forest"
    assert cfg.feature_set == "X_model"
    assert cfg.source == "TRAIN_OOF"
    assert cfg.n_expected == 4000
    assert cfg.n_folds == 5
    assert cfg.n_repeats == 20
    assert cfg.permutation_seed == 314159
    assert cfg.primary_importance_metric == "pr_auc"
    assert cfg.secondary_metrics == ("roc_auc", "brier")
    assert cfg.test_usage_allowed is False
    assert cfg.model_selection_enabled is False
    assert cfg.feature_selection_enabled is False
    assert cfg.recalibration_enabled is False


def test_frozen_constants():
    assert PRIMARY_METRIC == "pr_auc"
    assert SECONDARY_METRICS == ("roc_auc", "brier")
    assert len(REPEAT_COLUMNS) == 13
    assert len(FEATURE_SUMMARY_COLUMNS) == 14
    assert [g[0] for g in STRUCTURAL_GROUPS] == [
        "WORK_STRUCTURAL", "WASTE_STRUCTURAL", "HOUSING_COUNTS",
    ]


# ---------------------------------------------------------------------------
# RNG determinístico (SeedSequence — NÃO hash())
# ---------------------------------------------------------------------------

def test_permutation_indices_deterministic_and_valid():
    n = 100
    a = permutation_indices(n, base_seed=314159, fold=0, slot=0, repeat=0)
    b = permutation_indices(n, base_seed=314159, fold=0, slot=0, repeat=0)
    assert np.array_equal(a, b)
    assert sorted(a.tolist()) == list(range(n))


def test_permutation_indices_distinct_across_args():
    n = 100
    a = permutation_indices(n, base_seed=314159, fold=0, slot=0, repeat=0)
    c = permutation_indices(n, base_seed=314159, fold=0, slot=1, repeat=0)
    d = permutation_indices(n, base_seed=314159, fold=0, slot=0, repeat=1)
    e = permutation_indices(n, base_seed=314159, fold=1, slot=0, repeat=0)
    assert not np.array_equal(a, c)
    assert not np.array_equal(a, d)
    assert not np.array_equal(a, e)


def test_permutation_indices_negative_n_raises():
    with pytest.raises(ValueError):
        permutation_indices(-1, base_seed=1, fold=0, slot=0, repeat=0)


def test_seed_sequence_uses_spawn_key():
    # Mesma terna (base_seed, fold, slot, repeat) -> mesmo SeedSequence.
    a = permutation_seed_sequence(314159, 2, 33, 19)
    b = permutation_seed_sequence(314159, 2, 33, 19)
    assert a.entropy == b.entropy
    assert a.spawn_key == b.spawn_key


# ---------------------------------------------------------------------------
# Permutação de variáveis brutas (preserva integridade)
# ---------------------------------------------------------------------------

def test_permute_raw_feature_preserves_other_columns_and_multiset():
    X = pd.DataFrame(
        {
            "a": [1, 2, 3, 4],
            "b": [[1, 2], [3], [4, 5], [6]],
            "c": ["x", "y", "z", "w"],
        }
    )
    perm = np.array([3, 0, 2, 1])
    Xp = permute_raw_feature(X, "b", perm)
    assert Xp["a"].tolist() == [1, 2, 3, 4]
    assert Xp["c"].tolist() == ["x", "y", "z", "w"]
    assert Xp["b"].tolist() == [[6], [1, 2], [4, 5], [3]]
    # original intacto (nenhum objeto de lista mutado)
    assert X["b"].tolist() == [[1, 2], [3], [4, 5], [6]]


def test_permute_raw_feature_preserves_nulls():
    X = pd.DataFrame({"a": [1.0, None, 3.0], "b": [10, 20, 30]})
    perm = np.array([1, 2, 0])
    Xp = permute_raw_feature(X, "a", perm)
    # null preservado (None vira NaN numa Series float; o valor ausente continua ausente)
    assert pd.isna(Xp["a"].tolist()[0])
    assert Xp["a"].tolist()[1] == pytest.approx(3.0)
    assert Xp["a"].tolist()[2] == pytest.approx(1.0)
    assert Xp["b"].tolist() == [10, 20, 30]


def test_permute_raw_feature_unknown_column_raises():
    X = pd.DataFrame({"a": [1, 2, 3]})
    with pytest.raises(ValueError):
        permute_raw_feature(X, "zzz", np.array([0, 1, 2]))


def test_permute_raw_feature_wrong_perm_length_raises():
    X = pd.DataFrame({"a": [1, 2, 3]})
    with pytest.raises(ValueError):
        permute_raw_feature(X, "a", np.array([0, 1]))


def test_permute_raw_group_applies_same_perm_and_preserves_outside():
    X = pd.DataFrame(
        {
            "a": [1, 2, 3, 4],
            "b": [10, 20, 30, 40],
            "c": [100, 200, 300, 400],
        }
    )
    perm = np.array([3, 0, 2, 1])
    Xp = permute_raw_group(X, ["a", "b"], perm)
    assert Xp["a"].tolist() == [4, 1, 3, 2]
    assert Xp["b"].tolist() == [40, 10, 30, 20]
    assert Xp["c"].tolist() == [100, 200, 300, 400]


# ---------------------------------------------------------------------------
# Métricas e convenção de sinal dos deltas
# ---------------------------------------------------------------------------

def test_baseline_metrics_keys():
    m = baseline_metrics(np.array([0, 1]), np.array([0.1, 0.9]))
    assert set(m) == {"pr_auc", "roc_auc", "brier"}


def test_metric_deltas_sign_convention():
    y = np.array([0, 0, 1, 1])
    bp = np.array([0.1, 0.2, 0.8, 0.9])  # ranking correto
    pp = np.array([0.8, 0.9, 0.1, 0.2])  # ranking invertido (pior)
    b = baseline_metrics(y, bp)
    p = baseline_metrics(y, pp)
    d = metric_deltas(y, bp, pp)
    assert d["delta_pr_auc"] == pytest.approx(b["pr_auc"] - p["pr_auc"])
    assert d["delta_roc_auc"] == pytest.approx(b["roc_auc"] - p["roc_auc"])
    assert d["delta_brier"] == pytest.approx(p["brier"] - b["brier"])
    # permutado é pior -> deltas positivos (deterioração)
    assert d["delta_pr_auc"] > 0
    assert d["delta_roc_auc"] > 0
    assert d["delta_brier"] > 0


def test_metric_deltas_allow_negative():
    # permutado "melhor" por acaso -> deltas negativos são permitidos (não truncar)
    y = np.array([0, 1, 0, 1])
    bp = np.array([0.6, 0.4, 0.2, 0.5])  # ranking imperfeito
    pp = np.array([0.1, 0.9, 0.2, 0.8])  # ranking perfeito (melhor)
    d = metric_deltas(y, bp, pp)
    assert d["delta_pr_auc"] < 0
    assert d["delta_roc_auc"] < 0
    assert d["delta_brier"] < 0


# ---------------------------------------------------------------------------
# Agregação
# ---------------------------------------------------------------------------

def test_aggregate_repeats_within_fold():
    assert aggregate_repeats_within_fold([0.1, 0.2, 0.3]) == pytest.approx(0.2)
    with pytest.raises(ValueError):
        aggregate_repeats_within_fold([])


def test_aggregate_fold_means():
    s = aggregate_fold_means([1.0, 2.0, 3.0, 4.0, 5.0])
    assert s["mean"] == pytest.approx(3.0)
    assert s["std"] == pytest.approx(np.std([1.0, 2.0, 3.0, 4.0, 5.0], ddof=1))
    assert s["min"] == pytest.approx(1.0)
    assert s["max"] == pytest.approx(5.0)
    with pytest.raises(ValueError):
        aggregate_fold_means([])


def test_rank_features_descending_with_tiebreak():
    values = [0.5, 0.5, 0.3]
    tiebreak = [0.1, 0.2, 0.0]
    ranks = rank_features_descending(values, tiebreak)
    # ordem: idx1 (0.5, 0.2) -> idx0 (0.5, 0.1) -> idx2 (0.3)
    assert ranks == [2, 1, 3]


def test_rank_features_descending_tiebreak_by_index():
    values = [0.4, 0.4, 0.4]
    ranks = rank_features_descending(values)
    assert ranks == [1, 2, 3]


def test_rank_features_descending_empty():
    assert rank_features_descending([]) == []


# ---------------------------------------------------------------------------
# Guarda anti-TEST + inputs diretos do DGM
# ---------------------------------------------------------------------------

def test_assert_no_test_rows_ok_and_rejects_outside():
    assert_no_test_rows([1, 2, 3], [0, 1, 2, 3, 4])  # não levanta
    with pytest.raises(ValueError):
        assert_no_test_rows([1, 2, 5], [0, 1, 2, 3, 4])
    with pytest.raises(ValueError):
        assert_no_test_rows([], [0, 1, 2])


def test_validate_direct_dgm_inputs_matches_expected():
    assert validate_direct_dgm_inputs() == _EXPECTED_DIRECT


def test_is_direct_dgm_input():
    assert is_direct_dgm_input("escolaridade") is True
    assert is_direct_dgm_input("faixa_renda") is True
    assert is_direct_dgm_input("transporte_publico") is False


def test_summarize_dgm_context():
    ranked = ["escolaridade", "empregado", "distancia_ubs", "outro_a", "outro_b",
              "faixa_renda", "outro_c", "outro_d", "outro_e", "numero_pessoas",
              "resto_1", "resto_2"]
    ctx = summarize_dgm_context(ranked, _EXPECTED_DIRECT)
    assert ctx["direct_raw_inputs"] == sorted(_EXPECTED_DIRECT)
    assert ctx["top5_overlap"] == 3  # escolaridade, empregado, distancia_ubs
    assert ctx["top10_overlap"] == 5  # + faixa_renda (pos 6), numero_pessoas (pos 10)
    assert ctx["positions"]["escolaridade"] == 1
    assert ctx["positions"]["numero_pessoas"] == 10


# ---------------------------------------------------------------------------
# Guarda de não-referência (anti-TEST / anti-impurity / anti-SHAP)
# ---------------------------------------------------------------------------

def test_module_never_references_forbidden_artifacts_or_methods():
    src = _MODULE.read_text(encoding="utf-8")
    for token in (
        "test_predictions_selected_v1",
        "final_test_results_v1",
        ".feature_importances_",  # uso real via atributo; docstring (``...``) não casa
        "import shap",
        "from shap",
        "LogisticRegression",
        "XGBClassifier",
        ".fit(",
        "IsotonicRegression",
    ):
        assert token not in src, f"token proibido {token!r} presente no módulo"


def test_run_script_never_references_test_or_impurity():
    src = _RUN_SCRIPT.read_text(encoding="utf-8")
    for token in (
        "test_predictions_selected_v1",
        "final_test_results_v1",
        ".feature_importances_",
        "import shap",
        "from shap",
    ):
        assert token not in src, f"token proibido {token!r} presente no script"


def test_inspect_script_reads_only():
    src = _INSPECT_SCRIPT.read_text(encoding="utf-8")
    assert ".fit(" not in src
    assert "predict_proba" not in src


# ---------------------------------------------------------------------------
# Consistência com os artefatos gerados (se presentes)
# ---------------------------------------------------------------------------

_JSON = _IA_ROOT / "artifacts" / "metrics" / "interpretability_v1.json"
_REPEATS_CSV = _IA_ROOT / "artifacts" / "metrics" / "permutation_importance_repeats_v1.csv"
_FEATURES_CSV = _IA_ROOT / "artifacts" / "metrics" / "permutation_importance_features_v1.csv"
_GROUPS_CSV = _IA_ROOT / "artifacts" / "metrics" / "permutation_importance_groups_v1.csv"


@pytest.mark.skipif(not _JSON.exists(), reason="artefatos ainda não gerados")
def test_artifacts_consistency():
    import json

    report = json.loads(_JSON.read_text(encoding="utf-8"))
    md = report["metadata"]
    assert md["model"] == "random_forest"
    assert md["feature_set"] == "X_model"
    assert md["source"] == "TRAIN_OOF"
    assert md["repeats"] == 20
    assert md["permutation_seed"] == 314159
    assert md["primary_metric"] == "pr_auc"

    assert report["baseline_reproduction"]["max_probability_difference"] <= 1e-12

    g = report["guards"]
    assert g["test_used"] is False
    assert g["primary_model_modified"] is False
    assert g["feature_selection_performed"] is False
    assert g["recalibration_performed"] is False
    assert g["tuning_performed"] is False
    assert g["impurity_importance_used"] is False
    assert g["shap_used"] is False
    assert all(g["input_hashes_unchanged"].values())

    ranking = report["feature_importance"]["ranking"]
    assert len(ranking) == 34
    assert len(set(ranking)) == 34
    assert report["dgm_context"]["direct_raw_inputs"] == sorted(_EXPECTED_DIRECT)


@pytest.mark.skipif(not _REPEATS_CSV.exists(), reason="artefatos ainda não gerados")
def test_repeats_csv_shape_and_integrity():
    df = pd.read_csv(_REPEATS_CSV)
    assert len(df) == 34 * 5 * 20  # 3400
    assert list(df.columns) == list(REPEAT_COLUMNS)
    assert not df.isna().any().any()
    # deltas coerentes com baseline/permuted por definição
    assert np.allclose(
        df["delta_pr_auc"], df["baseline_pr_auc"] - df["permuted_pr_auc"]
    )
    assert np.allclose(
        df["delta_roc_auc"], df["baseline_roc_auc"] - df["permuted_roc_auc"]
    )
    assert np.allclose(df["delta_brier"], df["permuted_brier"] - df["baseline_brier"])


@pytest.mark.skipif(not _FEATURES_CSV.exists(), reason="artefatos ainda não gerados")
def test_features_csv_shape():
    df = pd.read_csv(_FEATURES_CSV)
    assert len(df) == 34
    assert list(df.columns) == list(FEATURE_SUMMARY_COLUMNS)
    assert set(df["feature"]) == set(
        load_interpretability_config(_CONFIG_PATH).feature_set
    ) or len(set(df["feature"])) == 34
    assert df["overall_rank_pr_auc"].tolist() == sorted(df["overall_rank_pr_auc"].tolist())


@pytest.mark.skipif(not _GROUPS_CSV.exists(), reason="artefatos ainda não gerados")
def test_groups_csv_shape():
    df = pd.read_csv(_GROUPS_CSV)
    # 3 grupos × (5 folds + 1 aggregate) = 18 linhas
    assert len(df) == 18
    assert set(df["group"]) == {"WORK_STRUCTURAL", "WASTE_STRUCTURAL", "HOUSING_COUNTS"}
