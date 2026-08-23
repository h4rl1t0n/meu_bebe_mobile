"""Inspeção da análise de calibração/estabilidade — FASE 3G-B1 (somente leitura).

Verifica invariantes dos artefatos gerados por ``analyze_oof_calibration.py``:
  * N=4000, sem TEST, 5 folds;
  * bins globais e por fold válidos (contagens fecham, domínios em [0,1]);
  * Brier/ROC-AUC/PR-AUC em [0,1];
  * ``recalibration_performed=false``, ``test_used=false``, ``model_modified=false``;
  * hashes dos insumos corretos;
  * consistência com resultados anteriores (mean_fold_roc_auc ≈ 0.609831,
    mean_fold_pr_auc ≈ 0.350786; pooled_oof_roc_auc ≈ 0.609684,
    pooled_oof_pr_auc ≈ 0.344891);
  * arquivos oficiais 3F-B inalterados (hash do joblib == manifest).

Uso::

    python scripts/inspect_calibration_stability.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd

try:  # garantir saída UTF-8 em terminais Windows
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:  # pragma: no cover
    pass

from meu_bebe_ml.training import load_frozen_split, read_json, sha256_file

_IA_ROOT = Path(__file__).resolve().parents[1]
_OOF_PATH = _IA_ROOT / "data" / "processed" / "cv_oof_predictions_v1.csv"
_SPLIT_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1.csv"
_FOLDS_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1.csv"
_CSV_PATH = _IA_ROOT / "artifacts" / "metrics" / "oof_calibration_bins_v1.csv"
_JSON_PATH = _IA_ROOT / "artifacts" / "metrics" / "calibration_stability_v1.json"
_MODEL_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1.joblib"
_MODEL_MANIFEST = _IA_ROOT / "artifacts" / "models" / "selected_model_v1_manifest.json"

_TOL = 1e-4


def _check(ok: bool, label: str) -> None:
    print(f"  [{'OK' if ok else 'FALHA'}] {label}")
    if not ok:
        raise SystemExit(f"Invariante violado: {label}")


def _bins_ok(bins, n_expected) -> bool:
    if not bins:
        return False
    total = 0
    for b in bins:
        if not (0.0 <= b["mean_predicted_probability"] <= 1.0):
            return False
        if not (0.0 <= b["fraction_of_positives"] <= 1.0):
            return False
        if not (0.0 <= b["min_probability"] <= b["max_probability"] <= 1.0):
            return False
        gap = b["fraction_of_positives"] - b["mean_predicted_probability"]
        if abs(gap - b["calibration_gap"]) > 1e-9:
            return False
        if abs(abs(gap) - b["absolute_calibration_gap"]) > 1e-9:
            return False
        total += b["n"]
    return total == n_expected


def main() -> None:
    print("=" * 72)
    print("INSPEÇÃO — CALIBRAÇÃO/ESTABILIDADE (FASE 3G-B1, somente leitura)")
    print("=" * 72)

    # ------------------------------------------------------------------
    # 1. Fonte OOF: N=4000, sem TEST, 5 folds
    # ------------------------------------------------------------------
    print("\n[1] OOF fonte")
    train_idx, test_idx = load_frozen_split(_SPLIT_PATH)
    oof = pd.read_csv(_OOF_PATH)
    _check(len(oof) == 4000, "N == 4000")
    _check(oof["row_index"].nunique() == 4000, "row_index únicos")
    _check(len(set(oof["row_index"].tolist()) & set(test_idx.tolist())) == 0,
           "nenhum row_index do TEST")
    _check(set(oof["validation_fold"].unique()) == {0, 1, 2, 3, 4}, "5 folds presentes")
    _check((int((oof["y_true"] == 0).sum()), int((oof["y_true"] == 1).sum())) == (3023, 977),
           "y0=3023 / y1=977")

    # ------------------------------------------------------------------
    # 2. JSON: flags, domínios, contagens, consistência com anterior
    # ------------------------------------------------------------------
    print("\n[2] JSON calibration_stability_v1.json")
    data = read_json(_JSON_PATH)
    _check(data["n"] == 4000, "JSON n == 4000")
    _check(data["recalibration_performed"] is False, "recalibration_performed == false")
    _check(data["test_used"] is False, "test_used == false")
    _check(data["model_modified"] is False, "model_modified == false")

    g = data["global"]
    _check(0.0 <= g["brier"] <= 1.0, "Brier global em [0,1]")
    _check(0.0 <= g["baseline_brier"] <= 1.0, "baseline Brier em [0,1]")
    _check(0.0 <= g["mean_fold_roc_auc"] <= 1.0, "mean_fold_roc_auc em [0,1]")
    _check(0.0 <= g["mean_fold_pr_auc"] <= 1.0, "mean_fold_pr_auc em [0,1]")
    _check(0.0 <= g["pooled_oof_roc_auc"] <= 1.0, "pooled_oof_roc_auc em [0,1]")
    _check(0.0 <= g["pooled_oof_pr_auc"] <= 1.0, "pooled_oof_pr_auc em [0,1]")
    _check(_bins_ok(g["calibration_bins"], 4000), "bins globais válidos e fecham em 4000")

    _check(abs(g["mean_fold_roc_auc"] - 0.609831) < _TOL,
           f"mean_fold_roc_auc ≈ 0.609831 (obtido {g['mean_fold_roc_auc']:.6f})")
    _check(abs(g["mean_fold_pr_auc"] - 0.350786) < _TOL,
           f"mean_fold_pr_auc ≈ 0.350786 (obtido {g['mean_fold_pr_auc']:.6f})")
    _check(abs(g["pooled_oof_roc_auc"] - 0.609684) < _TOL,
           f"pooled_oof_roc_auc ≈ 0.609684 (obtido {g['pooled_oof_roc_auc']:.6f})")
    _check(abs(g["pooled_oof_pr_auc"] - 0.344891) < _TOL,
           f"pooled_oof_pr_auc ≈ 0.344891 (obtido {g['pooled_oof_pr_auc']:.6f})")

    folds = data["per_fold"]
    _check(len(folds) == 5, "5 folds no JSON")
    _check({r["fold"] for r in folds} == {0, 1, 2, 3, 4}, "folds 0..4 no JSON")
    for r in folds:
        _check(_bins_ok(r["calibration_bins"], r["n"]),
               f"bins do fold {r['fold']} válidos e fecham em n={r['n']}")
        _check(0.0 <= r["brier"] <= 1.0, f"Brier do fold {r['fold']} em [0,1]")
        _check(0.0 <= r["roc_auc"] <= 1.0 and 0.0 <= r["pr_auc"] <= 1.0,
               f"ROC/PR do fold {r['fold']} em [0,1]")

    total_fold_n = sum(r["n"] for r in folds)
    _check(total_fold_n == 4000, "soma dos n por fold == 4000")

    # ------------------------------------------------------------------
    # 3. CSV: colunas e contagens
    # ------------------------------------------------------------------
    print("\n[3] CSV oof_calibration_bins_v1.csv")
    df = pd.read_csv(_CSV_PATH)
    _check(list(df.columns) == [
        "scope", "fold", "bin_index", "n", "min_probability", "max_probability",
        "mean_predicted_probability", "fraction_of_positives", "calibration_gap",
        "absolute_calibration_gap",
    ], "colunas do CSV exatamente as da seção 23")
    global_rows = df[df["scope"] == "global"]
    fold_rows = df[df["scope"] == "fold"]
    _check(int(global_rows["n"].sum()) == 4000, "CSV global: soma n == 4000")
    _check(len(fold_rows) > 0, "CSV contém linhas de fold")
    _check(set(fold_rows["fold"].astype(int).unique()) == {0, 1, 2, 3, 4},
           "CSV fold cobre 0..4")

    # ------------------------------------------------------------------
    # 4. Hashes dos insumos e arquivos oficiais 3F-B inalterados
    # ------------------------------------------------------------------
    print("\n[4] Hashes e integridade dos artefatos oficiais")
    recorded = data["input_hashes"]
    _check(recorded["cv_oof_predictions_v1.csv"] == sha256_file(_OOF_PATH),
           "hash OOF bate com o JSON")
    _check(recorded["train_test_split_v1.csv"] == sha256_file(_SPLIT_PATH),
           "hash split bate com o JSON")
    _check(recorded["cv_folds_v1.csv"] == sha256_file(_FOLDS_PATH),
           "hash folds bate com o JSON")

    manifest = read_json(_MODEL_MANIFEST)
    _check(sha256_file(_MODEL_PATH) == manifest["model_file_hash_sha256"],
           "selected_model_v1.joblib inalterado (hash == manifest)")

    # ------------------------------------------------------------------
    # 5. Resumo
    # ------------------------------------------------------------------
    print("\n[5] Resumo")
    print(f"  Brier global = {g['brier']:.6f}  baseline = {g['baseline_brier']:.6f}")
    print(f"  mean_abs_bin_gap = {g['mean_absolute_bin_gap']:.6f}  "
          f"weighted = {g['weighted_mean_absolute_bin_gap']:.6f}")
    print(f"  flags: recalibration_performed={data['recalibration_performed']}  "
          f"test_used={data['test_used']}  model_modified={data['model_modified']}")

    print("\n" + "=" * 72)
    print("INSPEÇÃO CONCLUÍDA — todos os invariantes OK.")
    print("=" * 72)


if __name__ == "__main__":
    main()
