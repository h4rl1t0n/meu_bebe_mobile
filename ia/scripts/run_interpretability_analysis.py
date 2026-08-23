"""Executa a interpretabilidade pós-hoc por permutation importance OOF (FASE 3H).

Análise SECUNDÁRIA, DESCRITIVA e NÃO causal: mede a perda de desempenho do Random
Forest congelado após permutar cada variável BRUTA de ``X_MODEL`` nas porções de
validação out-of-fold (métrica primária PR-AUC; secundárias ROC-AUC e Brier).

Fluxo (protocolo §42/§43):

    validar artefatos congelados
        -> carregar dados TRAIN-only
        -> carregar folds congelados
        -> para cada fold:
               fit do pipeline X_model + RF congelado (UMA vez)
               -> reproduzir as OOF congeladas (tolerância <= 1e-12)
               -> métricas baseline
               -> permutações de variáveis brutas
               -> permutações de grupos estruturais
        -> agregar
        -> contexto descritivo do DGM
        -> salvar CSV/JSON/figuras

REGRA DE OURO DO TEST SET: o TEST NÃO é aberto. Nenhuma seleção de modelo/feature/
threshold, nenhum tuning, nenhuma recalibração, nenhum ``feature_importances_``.

Saídas:
  * ``artifacts/metrics/permutation_importance_repeats_v1.csv``
  * ``artifacts/metrics/permutation_importance_features_v1.csv``
  * ``artifacts/metrics/permutation_importance_groups_v1.csv``
  * ``artifacts/metrics/interpretability_v1.json``
  * 4 figuras em ``artifacts/figures/``

Uso::

    python scripts/run_interpretability_analysis.py
"""

from __future__ import annotations

import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

try:  # garantir saída UTF-8 em terminais Windows
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:  # pragma: no cover
    pass

from meu_bebe_ml.evaluation import (
    FEATURE_SUMMARY_COLUMNS,
    REPEAT_COLUMNS,
    GROUP_SLOT_OFFSET,
    SECONDARY_METRICS,
    STRUCTURAL_GROUPS,
    InterpretabilityConfig,
    aggregate_fold_means,
    baseline_metrics,
    is_direct_dgm_input,
    load_interpretability_config,
    metric_deltas,
    permutation_indices,
    permute_raw_feature,
    permute_raw_group,
    rank_features_descending,
    summarize_dgm_context,
    validate_direct_dgm_inputs,
)
from meu_bebe_ml.schema import constants
from meu_bebe_ml.training import (
    build_random_forest_pipeline,
    fold_splits,
    load_frozen_dataset,
    load_frozen_folds,
    load_frozen_split,
    n_features_of,
    positive_class_probability,
    read_json,
    sha256_file,
)

_IA_ROOT = Path(__file__).resolve().parents[1]

_CONFIG_PATH = _IA_ROOT / "configs" / "interpretability_v1.yaml"
_DATASET_PATH = _IA_ROOT / "data" / "processed" / "dataset_synthetic_v1.jsonl"
_DGM_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "dgm_v1_manifest.json"
_SPLIT_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1.csv"
_SPLIT_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1_manifest.json"
_FOLDS_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1.csv"
_FOLDS_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1_manifest.json"
_OOF_PATH = _IA_ROOT / "data" / "processed" / "cv_oof_predictions_v1.csv"
_MODEL_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1.joblib"
_MODEL_MANIFEST_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1_manifest.json"

# Artifacts (sem manifest com hash próprio) cujos hashes são registrados antes/depois.
_HASH_ONLY_PATHS = {
    "cv_oof_predictions_v1.csv": _OOF_PATH,
    "cv_results_v1.json": _IA_ROOT / "artifacts" / "metrics" / "cv_results_v1.json",
    "threshold_analysis_v1.json": _IA_ROOT / "artifacts" / "metrics" / "threshold_analysis_v1.json",
    "calibration_stability_v1.json": _IA_ROOT / "artifacts" / "metrics" / "calibration_stability_v1.json",
    "methodological_sensitivity_v1.json": _IA_ROOT / "artifacts" / "metrics" / "methodological_sensitivity_v1.json",
}

# Saídas desta fase.
_REPEATS_CSV = _IA_ROOT / "artifacts" / "metrics" / "permutation_importance_repeats_v1.csv"
_FEATURES_CSV = _IA_ROOT / "artifacts" / "metrics" / "permutation_importance_features_v1.csv"
_GROUPS_CSV = _IA_ROOT / "artifacts" / "metrics" / "permutation_importance_groups_v1.csv"
_JSON_PATH = _IA_ROOT / "artifacts" / "metrics" / "interpretability_v1.json"
_FIGURES_DIR = _IA_ROOT / "artifacts" / "figures"

_PROB_COL = "random_forest_probability"
_TOL = 1e-12
_EXPECTED_N_FEATURES = 96


# ---------------------------------------------------------------------------
# Pré-condições
# ---------------------------------------------------------------------------

def _verify_manifest_hash(name: str, file_path: Path, manifest_path: Path, key_path: str) -> str:
    """Confere o hash de um artefato congelado contra seu manifest (PARE se divergir)."""
    file_hash = sha256_file(file_path)
    if manifest_path.exists():
        manifest = read_json(manifest_path)
        expected: Any = manifest
        for part in key_path.split("."):
            if not isinstance(expected, dict) or part not in expected:
                expected = None
                break
            expected = expected[part]
        if expected and file_hash != expected:
            print(f"[ERRO] hash de {name} divergente. PARE.\n  atual={file_hash}\n  esperado={expected}")
            sys.exit(1)
    print(f"[OK] {name}: {file_hash}")
    return file_hash


def _verify_selected_model() -> None:
    manifest = read_json(_MODEL_MANIFEST_PATH)
    selected = manifest.get("model_name")
    if selected != "random_forest":
        print(f"[ERRO] selected_model={selected!r} != random_forest. PARE.")
        sys.exit(1)
    print("[OK] selected_model == random_forest (congelado; nenhuma seleção aqui)")


_FROZEN_PREFIXES = ("ia/data/", "ia/artifacts/")
_FROZEN_CONFIGS = {
    "ia/configs/schema_v1_13.yaml",
    "ia/configs/simulation_v1.yaml",
    "ia/configs/preprocessing_v1.yaml",
    "ia/configs/training_protocol_v1.yaml",
    "ia/configs/threshold_analysis_v1.yaml",
    "ia/configs/calibration_stability_v1.yaml",
    "ia/configs/generator_q_full_v1.yaml",
    "ia/configs/methodological_sensitivity_v1.yaml",
}


def _verify_frozen_artifacts_unmodified() -> None:
    """Pré-condição: artefatos CONGELADOS (data/, artifacts/, configs anteriores)
    não podem estar modificados no working tree. Arquivos novos da própria fase
    3H são esperados e NÃO bloqueiam."""
    import subprocess

    try:
        out = subprocess.run(
            ["git", "status", "--short"],
            cwd=_IA_ROOT.parent,  # repo root => paths saem com prefixo "ia/..." (casa com _FROZEN_PREFIXES)
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        print("[AVISO] git indisponível; pré-condição de artefatos congelados não verificada via git")
        return

    lines = [ln for ln in out.stdout.splitlines() if ln.strip()]
    statuses: dict[str, str] = {}
    for ln in lines:
        code = ln[:2]
        path = ln[3:].strip()
        statuses[path] = code

    frozen_modified: list[str] = []
    for path, code in statuses.items():
        if code.strip() == "??":
            continue
        if path.startswith(_FROZEN_PREFIXES) or path in _FROZEN_CONFIGS:
            frozen_modified.append(f"{path} [{code.strip()}]")

    if frozen_modified:
        print("[ERRO] artefato CONGELADO modificado no working tree. PARE.")
        for item in frozen_modified:
            print(f"  - {item}")
        sys.exit(1)

    print("[OK] artefatos congelados (data/, artifacts/, configs de fases anteriores) inalterados")


# ---------------------------------------------------------------------------
# Figuras
# ---------------------------------------------------------------------------

def _figure_pr_auc_top15(summary: pd.DataFrame) -> None:
    top = summary.sort_values("mean_delta_pr_auc", ascending=False).head(15)
    features = top["feature"].to_numpy()
    means = top["mean_delta_pr_auc"].to_numpy()
    stds = top["std_fold_delta_pr_auc"].to_numpy()

    fig, ax = plt.subplots(figsize=(10, 6))
    y = np.arange(len(features))[::-1]
    ax.barh(y, means, xerr=stds, capsize=3, color="tab:blue", alpha=0.85)
    ax.set_yticks(y)
    ax.set_yticklabels(features, fontsize=8)
    ax.set_xlabel("mean delta PR-AUC (perda após permutação)")
    ax.set_title("Permutation importance (PR-AUC) — top 15 variáveis brutas")
    ax.axvline(0.0, color="0.3", linewidth=1.0)
    ax.grid(axis="x", alpha=0.3)
    ax.text(
        0.99, 0.01,
        "erro = desvio-padrão entre os cinco folds; não representa intervalo de confiança",
        transform=ax.transAxes, ha="right", va="bottom", fontsize=7, color="0.35",
    )
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "permutation_importance_pr_auc_top15_v1.png", dpi=150)
    plt.close(fig)


def _figure_by_fold_heatmap(fold_means: pd.DataFrame) -> None:
    top15 = (
        fold_means.groupby("feature")["delta_pr_auc"]
        .mean()
        .sort_values(ascending=False)
        .head(15)
        .index.to_numpy()
    )
    features = list(top15)[::-1]
    folds = [0, 1, 2, 3, 4]
    matrix = np.empty((len(features), len(folds)))
    for i, f in enumerate(features):
        for j, fd in enumerate(folds):
            val = fold_means.loc[
                (fold_means["feature"] == f) & (fold_means["fold"] == fd), "delta_pr_auc"
            ]
            matrix[i, j] = float(val.iloc[0])

    fig, ax = plt.subplots(figsize=(7, 7))
    im = ax.imshow(matrix, aspect="auto", cmap="viridis")
    ax.set_xticks(np.arange(len(folds)))
    ax.set_xticklabels([f"fold {f}" for f in folds])
    ax.set_yticks(np.arange(len(features)))
    ax.set_yticklabels(features, fontsize=8)
    ax.set_xlabel("fold")
    ax.set_title("Mean delta PR-AUC por fold (top 15 globais)")
    fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "permutation_importance_by_fold_v1.png", dpi=150)
    plt.close(fig)


def _figure_dgm_context(summary: pd.DataFrame) -> None:
    top = summary.sort_values("mean_delta_pr_auc", ascending=False).head(15)
    features = top["feature"].to_numpy()
    means = top["mean_delta_pr_auc"].to_numpy()
    direct = top["is_direct_dgm_input"].to_numpy()

    colors = ["tab:orange" if bool(d) else "tab:blue" for d in direct]
    fig, ax = plt.subplots(figsize=(10, 6))
    y = np.arange(len(features))[::-1]
    ax.barh(y, means, color=colors, alpha=0.85)
    ax.set_yticks(y)
    ax.set_yticklabels(features, fontsize=8)
    ax.set_xlabel("mean delta PR-AUC (perda após permutação)")
    ax.set_title("Permutation importance (PR-AUC) — contexto dos inputs diretos do DGM")
    ax.axvline(0.0, color="0.3", linewidth=1.0)
    ax.grid(axis="x", alpha=0.3)
    from matplotlib.patches import Patch

    ax.legend(
        handles=[
            Patch(color="tab:orange", label="input direto do DGM"),
            Patch(color="tab:blue", label="outra variável X_MODEL"),
        ],
        fontsize=8,
    )
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "permutation_importance_dgm_context_v1.png", dpi=150)
    plt.close(fig)


def _figure_groups(group_summary: list[dict[str, Any]]) -> None:
    names = [g["group"] for g in group_summary]
    means = [g["mean_delta_pr_auc"] for g in group_summary]
    stds = [g["std_fold_delta_pr_auc"] for g in group_summary]

    fig, ax = plt.subplots(figsize=(8, 5))
    x = np.arange(len(names))
    ax.bar(x, means, yerr=stds, capsize=5, color="tab:green", alpha=0.85)
    ax.axhline(0.0, color="0.3", linewidth=1.0)
    ax.set_xticks(x)
    ax.set_xticklabels(names, fontsize=9)
    ax.set_ylabel("mean delta PR-AUC (perda após permutação conjunta)")
    ax.set_title("Grouped permutation importance — grupos estruturais (mean ± SD entre folds)")
    ax.grid(axis="y", alpha=0.3)
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "permutation_importance_structural_groups_v1.png", dpi=150)
    plt.close(fig)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    t_start = time.perf_counter()
    print("=" * 78)
    print("FASE 3H — INTERPRETABILIDADE PÓS-HOC POR PERMUTATION IMPORTANCE OOF")
    print("=" * 78)

    config = load_interpretability_config(_CONFIG_PATH)
    print(f"\n[config] version={config.version}  model={config.model}  "
          f"feature_set={config.feature_set}  source={config.source}")
    print(f"  n_expected={config.n_expected}  folds={config.n_folds}  "
          f"n_repeats={config.n_repeats}  seed={config.permutation_seed}")
    print(f"  primary={config.primary_importance_metric}  "
          f"secondary={list(config.secondary_metrics)}")

    # ------------------------------------------------------------------
    # 0. Pré-condições (hashes congelados, modelo congelado, git limpo)
    # ------------------------------------------------------------------
    print("\n[0] pré-condições")
    _verify_frozen_artifacts_unmodified()
    _verify_selected_model()

    before_hashes: dict[str, str] = {}
    dataset_hash = _verify_manifest_hash(
        "dataset", _DATASET_PATH, _DGM_MANIFEST_PATH, "hashes_sha256.dataset_synthetic_v1.jsonl"
    )
    split_hash = _verify_manifest_hash(
        "split", _SPLIT_PATH, _SPLIT_MANIFEST_PATH, "split_file_hash_sha256"
    )
    folds_hash = _verify_manifest_hash(
        "folds", _FOLDS_PATH, _FOLDS_MANIFEST_PATH, "folds_file_hash_sha256"
    )
    model_hash = _verify_manifest_hash(
        "model", _MODEL_PATH, _MODEL_MANIFEST_PATH, "model_file_hash_sha256"
    )
    for name, path in _HASH_ONLY_PATHS.items():
        before_hashes[name] = sha256_file(path)
        print(f"[OK] {name}: {before_hashes[name]}")
    config_hash = sha256_file(_CONFIG_PATH)

    # ------------------------------------------------------------------
    # 1. Insumos congelados (TRAIN-only)
    # ------------------------------------------------------------------
    print("\n[1] carregamento dos insumos congelados")
    X_raw, y_full = load_frozen_dataset(dataset_path=_DATASET_PATH)
    assert X_raw.shape == (5000, 34)
    assert list(X_raw.columns) == list(constants.X_MODEL)

    train_idx, test_idx = load_frozen_split(_SPLIT_PATH)
    assert len(train_idx) == 4000 and len(test_idx) == 1000

    y_train = y_full[train_idx]
    y0 = int((y_train == 0).sum())
    y1 = int((y_train == 1).sum())
    assert y0 == 3023 and y1 == 977
    print(f"  TRAIN N={len(train_idx)}  Y0={y0}  Y1={y1}  (TEST não carregado)")

    # Anti-TEST: todos os row_index analisados pertencem ao TRAIN congelado.
    from meu_bebe_ml.evaluation.interpretability import assert_no_test_rows

    assert_no_test_rows(train_idx, train_idx)

    folds_df = load_frozen_folds(_FOLDS_PATH)
    assert len(folds_df) == 4000
    assert set(folds_df["validation_fold"]) == {0, 1, 2, 3, 4}
    fold_splits_ = fold_splits(folds_df, n_splits=5)

    oof = pd.read_csv(_OOF_PATH)
    assert len(oof) == 4000
    assert list(oof.columns) == [
        "row_index", "validation_fold", "y_true", "logistic_probability",
        "random_forest_probability", "xgboost_probability",
    ]
    assert np.array_equal(oof["row_index"].to_numpy(dtype=np.int64), train_idx)
    assert np.array_equal(oof["y_true"].to_numpy(dtype=np.int64), y_train)
    frozen_prob = oof.set_index("row_index")[_PROB_COL]

    # 34 raw features; nenhuma X_sens entra na análise principal.
    features = list(constants.X_MODEL)
    assert len(features) == 34
    assert not (set(constants.SENSITIVITY) & set(features))
    print(f"  X_MODEL = {len(features)} variáveis brutas; X_sens excluída")

    # Valida o mapeamento dos inputs diretos do DGM (PARE se divergir).
    direct_inputs = validate_direct_dgm_inputs()
    print(f"  inputs diretos do DGM: {sorted(direct_inputs)}")

    # ------------------------------------------------------------------
    # 2. Loop dos folds: fit único + reprodução OOF + permutações
    # ------------------------------------------------------------------
    print("\n[2] loop dos folds congelados (fit único por fold + permutações)")
    repeat_records: list[dict[str, Any]] = []
    group_records: list[dict[str, Any]] = []
    fold_baselines: list[dict[str, Any]] = []
    all_y: list[np.ndarray] = []
    all_p: list[np.ndarray] = []
    max_abs_diff = 0.0

    base_seed = config.permutation_seed
    n_repeats = config.n_repeats

    for fold_id, (train_rows, val_rows) in enumerate(fold_splits_):
        pipe = build_random_forest_pipeline()
        pipe.fit(X_raw.iloc[train_rows], y_full[train_rows])
        n_feat = n_features_of(pipe)
        assert n_feat == _EXPECTED_N_FEATURES, f"fold {fold_id}: {n_feat} features != 96"

        model_step = pipe.named_steps["model"]
        X_val = X_raw.iloc[val_rows]
        y_val = y_full[val_rows]
        proba = pipe.predict_proba(X_val)
        p_val = positive_class_probability(model_step, proba)

        # Reprodução exata das OOF congeladas.
        frozen_val = frozen_prob.loc[val_rows].to_numpy(dtype=float)
        diff = np.abs(p_val - frozen_val)
        fold_max = float(diff.max())
        max_abs_diff = max(max_abs_diff, fold_max)
        if fold_max > _TOL:
            print(f"[ERRO] fold {fold_id}: OOF não reproduzida (max diff={fold_max:.3e} > {_TOL}). PARE.")
            sys.exit(1)

        base_m = baseline_metrics(y_val, p_val)
        fold_baselines.append({"fold": fold_id, "n": int(len(val_rows)), **base_m})
        all_y.append(y_val)
        all_p.append(p_val)

        # --- permutação de variáveis brutas ---
        for fi, feature in enumerate(features):
            direct = is_direct_dgm_input(feature)
            for repeat in range(n_repeats):
                perm = permutation_indices(
                    len(val_rows), base_seed=base_seed, fold=fold_id, slot=fi, repeat=repeat
                )
                X_perm = permute_raw_feature(X_val, feature, perm)
                p_perm = positive_class_probability(model_step, pipe.predict_proba(X_perm))
                d = metric_deltas(y_val, p_val, p_perm)
                repeat_records.append(
                    {
                        "feature": feature,
                        "fold": fold_id,
                        "repeat": repeat,
                        "baseline_pr_auc": base_m["pr_auc"],
                        "permuted_pr_auc": base_m["pr_auc"] - d["delta_pr_auc"],
                        "delta_pr_auc": d["delta_pr_auc"],
                        "baseline_roc_auc": base_m["roc_auc"],
                        "permuted_roc_auc": base_m["roc_auc"] - d["delta_roc_auc"],
                        "delta_roc_auc": d["delta_roc_auc"],
                        "baseline_brier": base_m["brier"],
                        "permuted_brier": base_m["brier"] + d["delta_brier"],
                        "delta_brier": d["delta_brier"],
                        "is_direct_dgm_input": direct,
                    }
                )

        # --- permutação conjunta de grupos estruturais ---
        for gi, (gname, gfields) in enumerate(STRUCTURAL_GROUPS):
            for repeat in range(n_repeats):
                perm = permutation_indices(
                    len(val_rows),
                    base_seed=base_seed,
                    fold=fold_id,
                    slot=GROUP_SLOT_OFFSET + gi,
                    repeat=repeat,
                )
                X_perm = permute_raw_group(X_val, gfields, perm)
                p_perm = positive_class_probability(model_step, pipe.predict_proba(X_perm))
                d = metric_deltas(y_val, p_val, p_perm)
                group_records.append(
                    {
                        "group": gname,
                        "fold": fold_id,
                        "repeat": repeat,
                        "delta_pr_auc": d["delta_pr_auc"],
                        "delta_roc_auc": d["delta_roc_auc"],
                        "delta_brier": d["delta_brier"],
                    }
                )

        del pipe
        print(f"  fold {fold_id}: fit ok, OOF reproduzida (max diff={fold_max:.3e}), "
              f"baseline pr_auc={base_m['pr_auc']:.6f}")

    print(f"\n  [reprodução] max |prob reconstruída − OOF congelada| = {max_abs_diff:.3e} "
          f"(tolerância {_TOL})")
    if max_abs_diff > _TOL:
        print("[ERRO] reprodução OOF fora da tolerância. PARE.")
        sys.exit(1)

    # ------------------------------------------------------------------
    # 3. Baselines (mean-fold + pooled OOF)
    # ------------------------------------------------------------------
    mean_fold = {
        k: float(np.mean([b[k] for b in fold_baselines]))
        for k in ("pr_auc", "roc_auc", "brier")
    }
    pooled_y = np.concatenate(all_y)
    pooled_p = np.concatenate(all_p)
    pooled_oof = baseline_metrics(pooled_y, pooled_p)
    pooled_oof["n"] = int(len(pooled_y))
    print("\n[3] baselines")
    print(f"  mean-fold PR-AUC   = {mean_fold['pr_auc']:.6f}")
    print(f"  pooled OOF PR-AUC  = {pooled_oof['pr_auc']:.6f}")
    print(f"  mean-fold ROC-AUC  = {mean_fold['roc_auc']:.6f}")
    print(f"  pooled OOF ROC-AUC = {pooled_oof['roc_auc']:.6f}")
    print(f"  OOF Brier          = {pooled_oof['brier']:.6f}")

    # ------------------------------------------------------------------
    # 4. Artefato CSV de repeats + agregação por feature
    # ------------------------------------------------------------------
    repeats_df = pd.DataFrame(repeat_records, columns=REPEAT_COLUMNS)
    assert len(repeats_df) == 34 * 5 * n_repeats, len(repeats_df)
    assert not repeats_df.isna().any().any()
    assert not np.isinf(repeats_df.select_dtypes(include=np.number).to_numpy()).any()
    _REPEATS_CSV.parent.mkdir(parents=True, exist_ok=True)
    repeats_df.to_csv(_REPEATS_CSV, index=False)
    print(f"\n[4] {_REPEATS_CSV.name}: {len(repeats_df)} linhas "
          f"(34 × 5 × {n_repeats})")

    # Média dos repeats DENTRO de cada fold (por feature × fold × métrica).
    fold_means = (
        repeats_df.groupby(["feature", "fold"])[
            ["delta_pr_auc", "delta_roc_auc", "delta_brier"]
        ]
        .mean()
        .reset_index()
    )
    fold_mean_map = {
        (row.feature, int(row.fold)): float(row.delta_pr_auc)
        for row in fold_means.itertuples(index=False)
    }

    # Resumo por feature (média dos 5 fold means; std ENTRE folds).
    feature_summaries: list[dict[str, Any]] = []
    mean_pr_by_feature: dict[str, float] = {}
    mean_roc_by_feature: dict[str, float] = {}
    for f in features:
        fm = fold_means[fold_means["feature"] == f]
        pr_sum = aggregate_fold_means(fm["delta_pr_auc"].to_numpy())
        roc_sum = aggregate_fold_means(fm["delta_roc_auc"].to_numpy())
        brier_sum = aggregate_fold_means(fm["delta_brier"].to_numpy())
        mean_pr_by_feature[f] = pr_sum["mean"]
        mean_roc_by_feature[f] = roc_sum["mean"]
        feature_summaries.append(
            {
                "feature": f,
                "is_direct_dgm_input": bool(is_direct_dgm_input(f)),
                "mean_delta_pr_auc": pr_sum["mean"],
                "std_fold_delta_pr_auc": pr_sum["std"],
                "min_fold_delta_pr_auc": pr_sum["min"],
                "max_fold_delta_pr_auc": pr_sum["max"],
                "mean_delta_roc_auc": roc_sum["mean"],
                "std_fold_delta_roc_auc": roc_sum["std"],
                "mean_delta_brier": brier_sum["mean"],
                "std_fold_delta_brier": brier_sum["std"],
            }
        )

    # Ranks por fold (mean delta PR-AUC de cada fold) + rank global.
    fold_rank_lists: dict[str, list[int]] = {f: [] for f in features}
    for fold_id in range(config.n_folds):
        fold_pr = [fold_mean_map[(f, fold_id)] for f in features]
        ranks = rank_features_descending(fold_pr)
        for i, f in enumerate(features):
            fold_rank_lists[f].append(ranks[i])

    overall_ranks = rank_features_descending(
        [mean_pr_by_feature[f] for f in features],
        [mean_roc_by_feature[f] for f in features],
    )
    for i, f in enumerate(features):
        ranks = np.asarray(fold_rank_lists[f])
        feature_summaries[i]["median_fold_rank_pr_auc"] = int(np.median(ranks))
        feature_summaries[i]["min_fold_rank_pr_auc"] = int(ranks.min())
        feature_summaries[i]["max_fold_rank_pr_auc"] = int(ranks.max())
        feature_summaries[i]["overall_rank_pr_auc"] = int(overall_ranks[i])

    features_df = pd.DataFrame(feature_summaries, columns=FEATURE_SUMMARY_COLUMNS)
    features_df = features_df.sort_values("overall_rank_pr_auc")
    features_df.to_csv(_FEATURES_CSV, index=False)
    print(f"  {_FEATURES_CSV.name}: {len(features_df)} linhas")

    ranking = features_df["feature"].to_numpy().tolist()
    print("\n  ranking completo (mean delta PR-AUC, desc):")
    for i, row in enumerate(features_df.itertuples(index=False), start=1):
        dgm = "*" if row.is_direct_dgm_input else " "
        print(f"    {i:2d}. {row.feature:32s} {row.mean_delta_pr_auc:+.6f}  {dgm}")

    # ------------------------------------------------------------------
    # 5. Grouped structural sensitivity
    # ------------------------------------------------------------------
    groups_df_raw = pd.DataFrame(group_records)
    groups_df_raw = groups_df_raw.groupby(["group", "fold"])[
        ["delta_pr_auc", "delta_roc_auc", "delta_brier"]
    ].mean().reset_index()

    group_csv_rows: list[dict[str, Any]] = []
    group_summary: list[dict[str, Any]] = []
    for gname, gfields in STRUCTURAL_GROUPS:
        gm = groups_df_raw[groups_df_raw["group"] == gname]
        pr_sum = aggregate_fold_means(gm["delta_pr_auc"].to_numpy())
        roc_sum = aggregate_fold_means(gm["delta_roc_auc"].to_numpy())
        brier_sum = aggregate_fold_means(gm["delta_brier"].to_numpy())
        members = ";".join(gfields)
        for fold_id in range(config.n_folds):
            row = gm[gm["fold"] == fold_id]
            group_csv_rows.append(
                {
                    "group": gname,
                    "fold": fold_id,
                    "members": members,
                    "mean_delta_pr_auc": float(row["delta_pr_auc"].iloc[0]),
                    "mean_delta_roc_auc": float(row["delta_roc_auc"].iloc[0]),
                    "mean_delta_brier": float(row["delta_brier"].iloc[0]),
                }
            )
        group_csv_rows.append(
            {
                "group": gname,
                "fold": "aggregate",
                "members": members,
                "mean_delta_pr_auc": pr_sum["mean"],
                "mean_delta_roc_auc": roc_sum["mean"],
                "mean_delta_brier": brier_sum["mean"],
            }
        )
        group_summary.append(
            {
                "group": gname,
                "members": list(gfields),
                "mean_delta_pr_auc": pr_sum["mean"],
                "std_fold_delta_pr_auc": pr_sum["std"],
                "mean_delta_roc_auc": roc_sum["mean"],
                "std_fold_delta_roc_auc": roc_sum["std"],
                "mean_delta_brier": brier_sum["mean"],
                "std_fold_delta_brier": brier_sum["std"],
            }
        )

    groups_csv = pd.DataFrame(
        group_csv_rows,
        columns=[
            "group", "fold", "members", "mean_delta_pr_auc",
            "mean_delta_roc_auc", "mean_delta_brier",
        ],
    )
    groups_csv.to_csv(_GROUPS_CSV, index=False)
    print(f"\n[5] {_GROUPS_CSV.name}: {len(groups_csv)} linhas")
    for g in group_summary:
        print(f"    {g['group']:18s} mean delta PR-AUC = {g['mean_delta_pr_auc']:+.6f} "
              f"± {g['std_fold_delta_pr_auc']:.6f}")

    # ------------------------------------------------------------------
    # 6. Contexto descritivo do DGM
    # ------------------------------------------------------------------
    dgm_context = summarize_dgm_context(ranking, direct_inputs)
    print("\n[6] contexto dos inputs diretos do DGM (descritivo)")
    print(f"  top5_overlap = {dgm_context['top5_overlap']}  "
          f"top10_overlap = {dgm_context['top10_overlap']}")
    print(f"  positions = {dgm_context['positions']}")

    # ------------------------------------------------------------------
    # 7. Figuras
    # ------------------------------------------------------------------
    print("\n[7] figuras")
    _FIGURES_DIR.mkdir(parents=True, exist_ok=True)
    _figure_pr_auc_top15(features_df)
    _figure_by_fold_heatmap(fold_means)
    _figure_dgm_context(features_df)
    _figure_groups(group_summary)
    for name in (
        "permutation_importance_pr_auc_top15_v1.png",
        "permutation_importance_by_fold_v1.png",
        "permutation_importance_dgm_context_v1.png",
        "permutation_importance_structural_groups_v1.png",
    ):
        print(f"  - {name}")

    # ------------------------------------------------------------------
    # 8. JSON final
    # ------------------------------------------------------------------
    after_hashes = {name: sha256_file(path) for name, path in _HASH_ONLY_PATHS.items()}
    hashes_unchanged = {name: (before_hashes[name] == after_hashes[name]) for name in before_hashes}
    if not all(hashes_unchanged.values()):
        print("[ERRO] hash de artefato congelado mudou durante a execução. PARE.")
        sys.exit(1)

    report = {
        "metadata": {
            "analysis_version": config.version,
            "analysis_type": config.analysis_type,
            "model": config.model,
            "feature_set": config.feature_set,
            "source": config.source,
            "n": config.n_expected,
            "folds": config.n_folds,
            "repeats": config.n_repeats,
            "permutation_seed": config.permutation_seed,
            "primary_metric": config.primary_importance_metric,
        },
        "baseline_reproduction": {
            "max_probability_difference": max_abs_diff,
            "tolerance": _TOL,
            "per_fold_metrics": fold_baselines,
            "mean_fold_metrics": mean_fold,
            "pooled_oof_metrics": pooled_oof,
        },
        "feature_importance": {
            "ranking": ranking,
            "feature_summaries": [
                {k: (bool(v) if isinstance(v, (bool, np.bool_)) else v) for k, v in s.items()}
                for s in feature_summaries
            ],
        },
        "structural_group_sensitivity": {
            "groups": [
                {"group": g["group"], "members": g["members"]} for g in group_summary
            ],
            "summaries": group_summary,
        },
        "dgm_context": dgm_context,
        "limitations": {
            "marginal_permutation_dependency_breaking": (
                "A permutação marginal quebra a associação entre a variável permutada e as "
                "demais, podendo gerar combinações pouco frequentes ou estruturalmente "
                "implausíveis (ex.: empregado × tipo_emprego)."
            ),
            "correlated_predictors": (
                "Permutation importance pode subestimar ou distribuir importância entre "
                "preditores correlacionados/redundantes; uma variável não usada no DGM pode "
                "apresentar importância positiva por carregar informação correlacionada."
            ),
            "no_effect_direction": (
                "Permutation importance não informa direção de efeito, magnitude causal nem "
                "proteção/risco de categorias."
            ),
            "no_causal_interpretation": (
                "Esta é uma análise de dependência do desempenho do modelo, NÃO causal."
            ),
            "synthetic_only": (
                "Cenário sintético experimental; sem interpretação epidemiológica/clínica."
            ),
        },
        "guards": {
            "test_used": False,
            "primary_model_modified": False,
            "feature_selection_performed": False,
            "recalibration_performed": False,
            "tuning_performed": False,
            "api_created": False,
            "impurity_importance_used": False,
            "shap_used": False,
            "input_hashes_unchanged": hashes_unchanged,
        },
        "library_versions": _library_versions(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "note": (
            "Análise SECUNDÁRIA de interpretabilidade pós-hoc (permutation importance OOF). "
            "TEST não usado; nenhuma seleção de modelo/feature/threshold; nenhum tuning; "
            "nenhuma recalibração; o experimento principal permanece congelado."
        ),
    }

    _JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(_JSON_PATH, "w", encoding="utf-8") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)
    print(f"\n[json] {_JSON_PATH.name}")

    elapsed = time.perf_counter() - t_start
    print("\n" + "=" * 78)
    print(f"FIM — interpretabilidade pós-hoc concluída ({elapsed:.1f}s). TEST não aberto; "
          "nenhum commit.")
    print("=" * 78)


def _library_versions() -> dict[str, str]:
    import joblib
    import matplotlib
    import numpy as np
    import pandas as pd
    import scipy
    import sklearn
    import xgboost

    return {
        "python": sys.version.split()[0],
        "numpy": np.__version__,
        "pandas": pd.__version__,
        "scipy": scipy.__version__,
        "scikit_learn": sklearn.__version__,
        "xgboost": xgboost.__version__,
        "matplotlib": matplotlib.__version__,
        "joblib": joblib.__version__,
    }


if __name__ == "__main__":
    main()
