"""Executa a análise de sensibilidade metodológica (FASE 3G-B2) — análise SECUNDÁRIA.

Duas trilhas independentes, que NÃO substituem o experimento principal congelado:

  * **3G-B2A — sensibilidade ao conjunto de variáveis.** Compara o baseline
    ``X_model`` (34 variáveis / 96 features) com o conjunto de variáveis de
    sensibilidade ``X_sens`` (36 = X_model + ``problema_saude_agua`` +
    ``facil_acesso_saude`` / 98 features). O modelo é o Random Forest congelado
    (params congelados). A avaliação usa EXCLUSIVAMENTE o OOF do TREINAMENTO
    (4000 registros) e os 5 folds congelados. O baseline X_model NÃO é
    retreinado — apenas lê ``cv_oof_predictions_v1.csv``.

  * **3G-B2B — sensibilidade à taxa média de probabilidade simulada.** Gera
    cenários sintéticos experimentais com taxa média de probabilidade alvo de
    15 % / 25 % / 35 % (NÃO são prevalências reais), alterando APENAS o
    intercepto ``alpha`` (coeficientes/transformações/interações/forma
    logística/ruído congelados). Realização secundária com números aleatórios
    comuns (CRN): mesmo ``U_sens`` (seed 4241) e mesmo ``V_sens`` (seed 4242).

REGRA DE OURO DO TEST SET: o TEST NÃO é aberto. Nenhuma seleção de modelo nem
recalibração ocorre aqui.

Saídas:
  * ``data/processed/cv_oof_predictions_x_sens_v1.csv``  (OOF do X_sens)
  * ``data/processed/sensitivity_outcomes_v1.csv``       (Y_sens 15/25/35)
  * ``artifacts/metrics/methodological_sensitivity_v1.json``
  * ``artifacts/metrics/feature_set_sensitivity_v1.csv``
  * ``artifacts/metrics/outcome_rate_sensitivity_v1.csv``
  * 5 figuras em ``artifacts/figures/``

Uso::

    python scripts/run_methodological_sensitivity.py
"""

from __future__ import annotations

import json
import sys
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
    FEATURE_SET_COUNT_KEYS,
    FEATURE_SET_METRIC_KEYS,
    build_sensitivity_outcomes_dataframe,
    feature_set_deltas,
    generate_sensitivity_outcomes,
    load_methodological_sensitivity_config,
    per_fold_metrics,
    scenario_fold_metrics,
    scenario_monotonicity,
    scenario_pooled_metrics,
)
from meu_bebe_ml.preprocessing import build_x_sens_preprocessor
from meu_bebe_ml.schema import constants
from meu_bebe_ml.training import (
    build_random_forest_pipeline,
    fold_splits,
    load_frozen_folds,
    load_frozen_split,
    read_json,
    sha256_file,
)

_IA_ROOT = Path(__file__).resolve().parents[1]

_CONFIG_PATH = _IA_ROOT / "configs" / "methodological_sensitivity_v1.yaml"
_DATASET_PATH = _IA_ROOT / "data" / "processed" / "dataset_synthetic_v1.jsonl"
_DGM_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "dgm_v1_manifest.json"
_DGM_AUDIT_PATH = _IA_ROOT / "data" / "audit" / "dgm_audit_v1.csv"
_SPLIT_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1.csv"
_SPLIT_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1_manifest.json"
_FOLDS_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1.csv"
_FOLDS_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1_manifest.json"
_OOF_PATH = _IA_ROOT / "data" / "processed" / "cv_oof_predictions_v1.csv"
_MODEL_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1.joblib"
_MODEL_MANIFEST_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1_manifest.json"

# Saídas desta fase.
_OOF_X_SENS_PATH = _IA_ROOT / "data" / "processed" / "cv_oof_predictions_x_sens_v1.csv"
_OUTCOMES_PATH = _IA_ROOT / "data" / "processed" / "sensitivity_outcomes_v1.csv"
_METRICS_JSON_PATH = _IA_ROOT / "artifacts" / "metrics" / "methodological_sensitivity_v1.json"
_FEATURE_CSV_PATH = _IA_ROOT / "artifacts" / "metrics" / "feature_set_sensitivity_v1.csv"
_OUTCOME_CSV_PATH = _IA_ROOT / "artifacts" / "metrics" / "outcome_rate_sensitivity_v1.csv"
_FIGURES_DIR = _IA_ROOT / "artifacts" / "figures"

_PROB_COL = "random_forest_probability"
_THRESHOLD = 0.50
_TARGETS = (0.15, 0.25, 0.35)

# Nome dos cenários B2B (deixa claro que o 25% é o CONTROLE DE SENSIBILIDADE,
# distinto do ``primary_y_25`` do experimento principal).
_SCENARIO_LABEL = {
    0.15: "sensitivity_y_15",
    0.25: "sensitivity_y_25",
    0.35: "sensitivity_y_35",
}


def _load_records(path: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    with open(path, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line:
                records.append(json.loads(line))
    return records


def _verify_manifest_hash(name: str, file_path: Path, manifest_path: Path, key_path: str) -> str:
    """Confere o hash de um artefato congelado contra seu manifest (PARE se divergir).

    ``key_path`` pode ser um caminho aninhado separado por pontos (ex.:``
    "hashes_sha256.dataset_synthetic_v1.jsonl"``), percorrendo o JSON do manifest.
    """
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
    """Garante que o modelo congelado é random_forest (não há seleção nesta fase)."""
    manifest = read_json(_MODEL_MANIFEST_PATH)
    selected = manifest.get("model_name")
    if selected != "random_forest":
        print(f"[ERRO] selected_model={selected!r} != random_forest. PARE.")
        sys.exit(1)
    print(f"[OK] selected_model == random_forest (congelado; nenhuma seleção aqui)")


_FROZEN_PREFIXES = ("ia/data/", "ia/artifacts/")
_FROZEN_CONFIGS = {
    "ia/configs/schema_v1_13.yaml",
    "ia/configs/simulation_v1.yaml",
    "ia/configs/preprocessing_v1.yaml",
    "ia/configs/training_protocol_v1.yaml",
    "ia/configs/threshold_analysis_v1.yaml",
    "ia/configs/calibration_stability_v1.yaml",
    "ia/configs/generator_q_full_v1.yaml",
}


def _verify_frozen_artifacts_unmodified() -> None:
    """Pré-condição: os artefatos CONGELADOS (data/, artifacts/, configs de fases
    anteriores) não podem estar modificados no working tree.

    Arquivos novos da própria fase 3G-B2 (``methodological_sensitivity_v1.yaml``,
    ``src/meu_bebe_ml/evaluation/methodological_sensitivity.py`` e os scripts) e
    as edições de ``src/`` que implementam o suporte a X_sens são esperados e
    NÃO bloqueiam. A integridade byte-a-byte dos insumos congelados também é
    verificada pelos hashes sha256 contra os manifests (a seguir).
    """
    import subprocess

    try:
        out = subprocess.run(
            ["git", "status", "--short"], cwd=_IA_ROOT, capture_output=True, text=True
        )
    except FileNotFoundError:
        print("[AVISO] git indisponível; pré-condição de artefatos congelados não verificada via git")
        return

    lines = [ln for ln in out.stdout.splitlines() if ln.strip()]
    # `git status --short` emite "XY path"; o path começa no índice 3.
    statuses: dict[str, str] = {}
    for ln in lines:
        code = ln[:2]
        path = ln[3:].strip()
        statuses[path] = code

    frozen_modified: list[str] = []
    for path, code in statuses.items():
        # "??" (untracked) nunca é uma modificação de artefato congelado.
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
    for ln in lines:
        print(f"  [status] {ln}")


def _run_x_sens_cv(
    X_sens_raw: pd.DataFrame,
    y: np.ndarray,
    fold_splits_: list[tuple[np.ndarray, np.ndarray]],
) -> dict[int, float]:
    """CV de 5 folds do Random Forest congelado sobre X_sens (36 -> 98 features).

    NÃO retreina o baseline X_model; apenas o preprocessor X_sens + RF congelado.
    """
    oof: dict[int, float] = {}
    for fold_id, (train_rows, val_rows) in enumerate(fold_splits_):
        pipe = build_random_forest_pipeline(preprocessor=build_x_sens_preprocessor())
        pipe.fit(X_sens_raw.iloc[train_rows], y[train_rows])
        proba = pipe.predict_proba(X_sens_raw.iloc[val_rows])[:, 1]
        for row, p in zip(val_rows, proba):
            oof[int(row)] = float(p)
        del pipe
    return oof


# ---------------------------------------------------------------------------
# Figuras
# ---------------------------------------------------------------------------

def _figure_feature_set_metrics(deltas: dict[str, Any]) -> None:
    keys = FEATURE_SET_METRIC_KEYS
    means = [deltas["summary"][k]["mean"] for k in keys]
    stds = [deltas["summary"][k]["std"] for k in keys]

    fig, ax = plt.subplots(figsize=(9, 5))
    x = np.arange(len(keys))
    ax.bar(x, means, yerr=stds, capsize=3, color="tab:blue", alpha=0.85)
    ax.axhline(0.0, color="0.3", linewidth=1.0)
    ax.set_xticks(x)
    ax.set_xticklabels(keys, rotation=30, ha="right", fontsize=8)
    ax.set_ylabel("diferença observada (X_sens − X_model)")
    ax.set_title("Sensibilidade ao conjunto de variáveis — métricas contínuas (mean ± std)")
    ax.grid(axis="y", alpha=0.3)
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "feature_set_sensitivity_metrics_v1.png", dpi=150)
    plt.close(fig)


def _figure_feature_set_threshold_metrics(deltas: dict[str, Any]) -> None:
    keys = (
        "accuracy", "precision", "recall", "specificity", "f1", "balanced_accuracy",
        "tn", "fp", "fn", "tp",
    )
    means = [deltas["summary"][k]["mean"] for k in keys]
    stds = [deltas["summary"][k]["std"] for k in keys]

    fig, ax = plt.subplots(figsize=(9, 5))
    x = np.arange(len(keys))
    ax.bar(x, means, yerr=stds, capsize=3, color="tab:orange", alpha=0.85)
    ax.axhline(0.0, color="0.3", linewidth=1.0)
    ax.set_xticks(x)
    ax.set_xticklabels(keys, rotation=30, ha="right", fontsize=8)
    ax.set_ylabel("diferença observada (X_sens − X_model)")
    ax.set_title("Sensibilidade ao conjunto de variáveis — métricas @0.50 (mean ± std)")
    ax.grid(axis="y", alpha=0.3)
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "feature_set_sensitivity_threshold_metrics_v1.png", dpi=150)
    plt.close(fig)


def _figure_outcome_rate_auc(pooled_by_target: dict[float, dict[str, Any]]) -> None:
    targets = list(_TARGETS)
    rocs = [pooled_by_target[t]["roc_auc"] for t in targets]
    prs = [pooled_by_target[t]["pr_auc"] for t in targets]

    fig, ax = plt.subplots(figsize=(7, 5))
    ax.plot(targets, rocs, marker="o", lw=1.5, label="ROC-AUC (pooled OOF)")
    ax.plot(targets, prs, marker="s", lw=1.5, label="PR-AUC (pooled OOF)")
    ax.set_xlabel("taxa média de probabilidade simulada (alvo)")
    ax.set_ylabel("AUC")
    ax.set_xticks(targets)
    ax.set_xticklabels([f"{t:.0%}" for t in targets])
    ax.set_title("Sensibilidade à taxa média de probabilidade simulada — AUC")
    ax.legend()
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "outcome_rate_sensitivity_auc_v1.png", dpi=150)
    plt.close(fig)


def _figure_outcome_rate_brier(pooled_by_target: dict[float, dict[str, Any]]) -> None:
    targets = list(_TARGETS)
    brier = [pooled_by_target[t]["brier"] for t in targets]
    baseline = [pooled_by_target[t]["baseline_brier"] for t in targets]

    fig, ax = plt.subplots(figsize=(7, 5))
    ax.plot(targets, brier, marker="o", lw=1.5, label="Brier do modelo")
    ax.plot(targets, baseline, marker="s", lw=1.5, label="Brier baseline (prevalência constante)")
    ax.set_xlabel("taxa média de probabilidade simulada (alvo)")
    ax.set_ylabel("Brier")
    ax.set_xticks(targets)
    ax.set_xticklabels([f"{t:.0%}" for t in targets])
    ax.set_title("Sensibilidade à taxa média de probabilidade simulada — Brier")
    ax.legend()
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "outcome_rate_sensitivity_brier_v1.png", dpi=150)
    plt.close(fig)


def _figure_outcome_rate_threshold(scenario_folds: dict[float, list[dict[str, Any]]]) -> None:
    # Métricas @0.50 agregadas por cenário (mean dos 5 folds congelados).
    keys = ("accuracy", "precision", "recall", "specificity", "f1", "balanced_accuracy")
    targets = list(_TARGETS)
    fig, ax = plt.subplots(figsize=(8, 5))
    for k in keys:
        ax.plot(
            targets,
            [float(np.mean([fm[k] for fm in scenario_folds[t]])) for t in targets],
            marker="o", markersize=3, lw=1.2, label=k,
        )
    ax.set_xlabel("taxa média de probabilidade simulada (alvo)")
    ax.set_ylabel("métrica @0.50 (mean dos folds)")
    ax.set_xticks(targets)
    ax.set_xticklabels([f"{t:.0%}" for t in targets])
    ax.set_title("Sensibilidade à taxa média de probabilidade simulada — métricas @0.50")
    ax.legend(fontsize=7, ncol=2)
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "outcome_rate_sensitivity_threshold_v1.png", dpi=150)
    plt.close(fig)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    print("=" * 78)
    print("FASE 3G-B2 — ANÁLISE DE SENSIBILIDADE METODOLÓGICA (análise secundária)")
    print("=" * 78)

    config = load_methodological_sensitivity_config(_CONFIG_PATH)
    print(f"\n[config] version={config.version}  model={config.model}  "
          f"n_expected={config.n_expected}  n_folds={config.n_folds}")
    print(f"  feature_set.enabled={config.feature_set_enabled}  "
          f"outcome_base_rate.enabled={config.outcome_base_rate_enabled}")
    print(f"  targets={list(config.target_mean_probabilities)}  "
          f"noise_seed={config.noise_seed}  outcome_seed={config.outcome_seed}")

    # ------------------------------------------------------------------
    # 0. Pré-condições (hashes congelados, modelo congelado, git limpo)
    # ------------------------------------------------------------------
    print("\n[0] pré-condições")
    _verify_frozen_artifacts_unmodified()
    _verify_selected_model()
    dataset_hash = _verify_manifest_hash(
        "dataset", _DATASET_PATH, _DGM_MANIFEST_PATH, "hashes_sha256.dataset_synthetic_v1.jsonl"
    )
    _verify_manifest_hash(
        "dgm_audit", _DGM_AUDIT_PATH, _DGM_MANIFEST_PATH, "hashes_sha256.dgm_audit_v1.csv"
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
    config_hash = sha256_file(_CONFIG_PATH)

    # ------------------------------------------------------------------
    # 1. Insumos congelados (split, folds, OOF, dataset, dgm_audit)
    # ------------------------------------------------------------------
    print("\n[1] carregamento dos insumos congelados")
    train_idx, test_idx = load_frozen_split(_SPLIT_PATH)
    assert len(train_idx) == 4000 and len(test_idx) == 1000
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
    # OOF cobre exatamente o TRAIN, em ordem crescente de row_index.
    assert np.array_equal(oof["row_index"].to_numpy(dtype=np.int64), train_idx)

    y_oof = oof["y_true"].to_numpy(dtype=np.int64)
    folds_arr = oof["validation_fold"].to_numpy(dtype=np.int64)
    p_base = oof[_PROB_COL].to_numpy(dtype=float)

    full_records = _load_records(_DATASET_PATH)
    assert len(full_records) == 5000
    full_df = pd.DataFrame(full_records)
    X_sens_raw = full_df[list(constants.X_SENS)].copy()
    y_full = full_df["descontinuou_pre_natal"].to_numpy(dtype=np.int64)
    assert X_sens_raw.shape == (5000, 36)
    assert set(constants.X_SENS) - set(constants.X_MODEL) == {
        "problema_saude_agua", "facil_acesso_saude"
    }
    assert set(constants.X_MODEL).issubset(set(constants.X_SENS))

    dgm_audit = pd.read_csv(_DGM_AUDIT_PATH)
    assert len(dgm_audit) == 5000
    linear_all = dgm_audit["linear_component"].to_numpy(dtype=float)
    linear_train = linear_all[train_idx]  # ordem crescente de row_index == ordem do OOF
    assert linear_train.shape == (4000,)

    print(f"  split TRAIN={len(train_idx)} TEST={len(test_idx)}; OOF={len(oof)}; "
          f"X_sens={X_sens_raw.shape[1]} colunas")
    print(f"  X_sens − X_model = {sorted(set(constants.X_SENS) - set(constants.X_MODEL))}")

    # ==================================================================
    # TRILHA B2A — sensibilidade ao conjunto de variáveis (X_model vs X_sens)
    # ==================================================================
    print("\n" + "=" * 78)
    print("TRILHA B2A — SENSIBILIDADE AO CONJUNTO DE VARIÁVEIS (X_model vs X_sens)")
    print("=" * 78)

    print("\n[2a] CV de 5 folds do Random Forest congelado sobre X_sens")
    oof_x_sens = _run_x_sens_cv(X_sens_raw, y_full, fold_splits_)
    p_sens = np.asarray([oof_x_sens[int(r)] for r in train_idx], dtype=float)
    assert p_sens.shape == (4000,)

    baseline_rows = per_fold_metrics(folds_arr, y_oof, p_base, n_folds=5, threshold=_THRESHOLD)
    sens_rows = per_fold_metrics(folds_arr, y_oof, p_sens, n_folds=5, threshold=_THRESHOLD)
    deltas = feature_set_deltas(baseline_rows, sens_rows)
    count_deltas = feature_set_deltas(
        baseline_rows, sens_rows, metric_keys=FEATURE_SET_COUNT_KEYS
    )
    deltas["summary"].update(count_deltas["summary"])

    # OOF X_sens (artefato) — espelha o schema do OOF congelado.
    oof_x_sens_df = pd.DataFrame(
        {
            "row_index": train_idx,
            "validation_fold": folds_arr,
            "y_true": y_oof,
            "random_forest_probability": p_sens,
            "y_pred_050": (p_sens >= _THRESHOLD).astype(int),
        }
    )
    _OOF_X_SENS_PATH.parent.mkdir(parents=True, exist_ok=True)
    oof_x_sens_df.to_csv(_OOF_X_SENS_PATH, index=False)
    print(f"  [csv] {_OOF_X_SENS_PATH.name}")

    print("\n[2a] diferença observada (X_sens − X_model) por métrica (mean ± std)")
    for k in FEATURE_SET_METRIC_KEYS:
        s = deltas["summary"][k]
        print(f"    {k:18s} mean={s['mean']:+.6f}  std={s['std']:.6f}  "
              f"[{s['min']:+.6f}, {s['max']:+.6f}]")
    for k in FEATURE_SET_COUNT_KEYS:
        s = deltas["summary"][k]
        print(f"    {k:18s} mean={s['mean']:+.4f}  std={s['std']:.4f}  "
              f"[{s['min']:+.4f}, {s['max']:+.4f}]")

    # CSV long de B2A (fold, metric, baseline, sensitivity, delta).
    b2a_rows: list[dict[str, Any]] = []
    for fold_id in range(5):
        b = baseline_rows[fold_id]
        s = sens_rows[fold_id]
        for k in list(FEATURE_SET_METRIC_KEYS) + list(FEATURE_SET_COUNT_KEYS):
            b2a_rows.append(
                {
                    "fold": fold_id,
                    "metric": k,
                    "baseline": b[k],
                    "sensitivity": s[k],
                    "delta": float(s[k]) - float(b[k]),
                }
            )
    _FEATURE_CSV_PATH.parent.mkdir(parents=True, exist_ok=True)
    pd.DataFrame(b2a_rows).to_csv(_FEATURE_CSV_PATH, index=False)
    print(f"  [csv] {_FEATURE_CSV_PATH.name}")

    # ==================================================================
    # TRILHA B2B — sensibilidade à taxa média de probabilidade simulada
    # ==================================================================
    print("\n" + "=" * 78)
    print("TRILHA B2B — SENSIBILIDADE À TAXA MÉDIA DE PROBABILIDADE SIMULADA")
    print("=" * 78)

    print("\n[2b] geração dos cenários sintéticos experimentais (CRN)")
    outcomes = generate_sensitivity_outcomes(
        linear_train,
        noise_seed=config.noise_seed,
        outcome_seed=config.outcome_seed,
        noise_sd=config.noise_sd,
        target_mean_probabilities=config.target_mean_probabilities,
    )
    mono = scenario_monotonicity(outcomes)
    print(f"  monotonicidade: {mono}")
    if not all(mono.values()):
        print("[ERRO] violação de monotonicidade entre os cenários. PARE.")
        sys.exit(1)

    # Artefato sensitivity_outcomes_v1.csv (anti-leakage: sem U_sens/V_sens/p_true).
    outcomes_df = build_sensitivity_outcomes_dataframe(train_idx, outcomes, folds=folds_arr)
    for forbidden in ("U_sens", "V_sens", "p_true", "alpha", "linear_component"):
        assert forbidden not in outcomes_df.columns, f"vazamento: {forbidden} no CSV"
    _OUTCOMES_PATH.parent.mkdir(parents=True, exist_ok=True)
    outcomes_df.to_csv(_OUTCOMES_PATH, index=False)
    print(f"  [csv] {_OUTCOMES_PATH.name}  colunas={list(outcomes_df.columns)}")

    # Métricas por cenário (por fold + pooled) avaliadas com as probs OOF congeladas.
    print("\n[2b] métricas por cenário (probs OOF do Random Forest congelado)")
    scenario_folds: dict[float, list[dict[str, Any]]] = {}
    pooled_by_target: dict[float, dict[str, Any]] = {}
    for t in _TARGETS:
        o = outcomes[t]
        print(
            f"  cenário {_SCENARIO_LABEL[t]:18s} alvo={t:.2f}  alpha={o.alpha:.6f}  "
            f"mean(p)={o.achieved_mean_probability:.10f}  prevalência realizada={o.realized_prevalence:.4f}"
        )
        folds_metrics = scenario_fold_metrics(folds_arr, o.y, p_base, n_folds=5, threshold=_THRESHOLD)
        pooled = scenario_pooled_metrics(o.y, p_base, threshold=_THRESHOLD)
        scenario_folds[t] = folds_metrics
        pooled_by_target[t] = pooled
        print(
            f"    pooled: prevalence={pooled['prevalence']:.4f}  "
            f"roc_auc={pooled['roc_auc']:.4f}  pr_auc={pooled['pr_auc']:.4f}  "
            f"brier={pooled['brier']:.4f}  baseline_brier={pooled['baseline_brier']:.4f}"
        )

    # CSV long de B2B: linhas por fold (métricas completas @0.50) + linha pooled
    # (fold = "pooled", apenas os descritores pooled ROC-AUC/PR-AUC/Brier + relativos).
    fold_cols = [
        "prevalence", "roc_auc", "pr_auc", "brier", "baseline_brier",
        "relative_brier_improvement", "pr_auc_minus_prevalence", "pr_auc_over_prevalence",
        "accuracy", "precision", "recall", "specificity", "f1", "balanced_accuracy",
        "tn", "fp", "fn", "tp",
    ]
    pooled_cols = [
        "prevalence", "roc_auc", "pr_auc", "brier", "baseline_brier",
        "relative_brier_improvement", "pr_auc_minus_prevalence", "pr_auc_over_prevalence",
    ]
    b2b_rows: list[dict[str, Any]] = []
    for t in _TARGETS:
        o = outcomes[t]
        for fm in scenario_folds[t]:
            b2b_rows.append(
                {
                    "scenario": _SCENARIO_LABEL[t],
                    "target_mean_probability": t,
                    "fold": fm["fold"],
                    "alpha": o.alpha,
                    "achieved_mean_probability": o.achieved_mean_probability,
                    **{c: fm[c] for c in fold_cols},
                }
            )
        pm = pooled_by_target[t]
        b2b_rows.append(
            {
                "scenario": _SCENARIO_LABEL[t],
                "target_mean_probability": t,
                "fold": "pooled",
                "alpha": o.alpha,
                "achieved_mean_probability": o.achieved_mean_probability,
                **{c: pm[c] for c in pooled_cols},
            }
        )
    _OUTCOME_CSV_PATH.parent.mkdir(parents=True, exist_ok=True)
    pd.DataFrame(b2b_rows).to_csv(_OUTCOME_CSV_PATH, index=False)
    print(f"  [csv] {_OUTCOME_CSV_PATH.name}")

    # ------------------------------------------------------------------
    # Figuras
    # ------------------------------------------------------------------
    print("\n[figuras]")
    _FIGURES_DIR.mkdir(parents=True, exist_ok=True)
    _figure_feature_set_metrics(deltas)
    _figure_feature_set_threshold_metrics(deltas)
    _figure_outcome_rate_auc(pooled_by_target)
    _figure_outcome_rate_brier(pooled_by_target)
    _figure_outcome_rate_threshold(scenario_folds)
    for name in (
        "feature_set_sensitivity_metrics_v1.png",
        "feature_set_sensitivity_threshold_metrics_v1.png",
        "outcome_rate_sensitivity_auc_v1.png",
        "outcome_rate_sensitivity_brier_v1.png",
        "outcome_rate_sensitivity_threshold_v1.png",
    ):
        print(f"  - {name}")

    # ------------------------------------------------------------------
    # JSON final (com guarda anti-leakage e p-stats)
    # ------------------------------------------------------------------
    scenarios_json = {}
    for t in _TARGETS:
        o = outcomes[t]
        scenarios_json[_SCENARIO_LABEL[t]] = {
            "target_mean_probability": t,
            "alpha": o.alpha,
            "achieved_mean_probability": o.achieved_mean_probability,
            "realized_prevalence": o.realized_prevalence,
            "p_true_min": float(np.min(o.p_true)),
            "p_true_max": float(np.max(o.p_true)),
            "p_true_mean": float(np.mean(o.p_true)),
            "pooled_metrics": pooled_by_target[t],
            "per_fold_metrics": scenario_folds[t],
        }

    report = {
        "analysis_version": config.version,
        "analysis_type": config.analysis_type,
        "model": config.model,
        "n_expected": config.n_expected,
        "n_folds": config.n_folds,
        "threshold_reference": config.threshold_reference,
        "evaluation_source": config.evaluation_source,
        "evaluation_folds": config.evaluation_folds,
        "input_hashes": {
            "dataset_synthetic_v1.jsonl": dataset_hash,
            "dgm_audit_v1.csv": sha256_file(_DGM_AUDIT_PATH),
            "train_test_split_v1.csv": split_hash,
            "cv_folds_v1.csv": folds_hash,
            "cv_oof_predictions_v1.csv": sha256_file(_OOF_PATH),
            "selected_model_v1.joblib": model_hash,
            "methodological_sensitivity_v1.yaml": config_hash,
        },
        "feature_set_track": {
            "baseline": config.feature_set_baseline,
            "sensitivity": config.feature_set_sensitivity,
            "invariant_added": sorted(set(constants.X_SENS) - set(constants.X_MODEL)),
            "invariant_subset": bool(set(constants.X_MODEL).issubset(set(constants.X_SENS))),
            "baseline_per_fold": baseline_rows,
            "sensitivity_per_fold": sens_rows,
            "deltas": deltas,
        },
        "outcome_base_rate_track": {
            "noise_seed": config.noise_seed,
            "outcome_seed": config.outcome_seed,
            "noise_sd": config.noise_sd,
            "monotonicity": mono,
            "scenarios": scenarios_json,
        },
        # Guarda anti-leakage / decisões proibidas.
        "guards": {
            "test_used": False,
            "test_rows": 0,
            "recalibration_performed": False,
            "selection_performed": False,
            "model_modified": False,
            "sensitivity_outcomes_columns": list(outcomes_df.columns),
            "noise_or_latent_leaked_in_outcomes_csv": False,
        },
        "library_versions": _library_versions(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "note": "Análise SECUNDÁRIA de sensibilidade metodológica. TEST não usado; "
        "nenhuma seleção/recalibração; experimento principal permanece congelado. "
        "Cenários 15/25/35 são taxas médias de probabilidade simulada (NÃO prevalências reais); "
        "o cenário 25% é o controle de sensibilidade (sensitivity_y_25), distinto do primary_y_25.",
    }

    _METRICS_JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(_METRICS_JSON_PATH, "w", encoding="utf-8") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)
    print(f"\n[json] {_METRICS_JSON_PATH.name}")

    print("\n" + "=" * 78)
    print("FIM — análise de sensibilidade metodológica concluída (análise secundária).")
    print("O TEST não foi aberto; nenhuma seleção/recalibração; nenhum commit.")
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
