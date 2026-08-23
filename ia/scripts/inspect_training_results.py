"""Inspeção dos artefatos da FASE 3F-B.

Lê ``cv_results_v1.json``, ``final_test_results_v1.json``, o CSV de OOF, as
predições do TEST, o manifest do modelo e as figuras, e valida os invariantes do
protocolo executado (anti-leakage, cobertura do OOF, threshold 0.50, unicidade
da avaliação no TEST). NÃO treina modelo e NÃO recalcula nada.

Uso::

    python scripts/inspect_training_results.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd

try:  # garantir saída UTF-8 em terminais Windows
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:  # pragma: no cover
    pass

from meu_bebe_ml.training import (
    OOF_PROBABILITY_COLUMN,
    load_frozen_split,
    load_model,
    read_json,
)

_IA_ROOT = Path(__file__).resolve().parents[1]
_SPLIT_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1.csv"
_OOF_PATH = _IA_ROOT / "data" / "processed" / "cv_oof_predictions_v1.csv"
_CV_RESULTS_PATH = _IA_ROOT / "artifacts" / "metrics" / "cv_results_v1.json"
_TEST_RESULTS_PATH = _IA_ROOT / "artifacts" / "metrics" / "final_test_results_v1.json"
_TEST_PREDICTIONS_PATH = _IA_ROOT / "data" / "processed" / "test_predictions_selected_v1.csv"
_MODEL_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1.joblib"
_MODEL_MANIFEST_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1_manifest.json"
_FIGURES_DIR = _IA_ROOT / "artifacts" / "figures"

_FIGURES = (
    "selected_model_roc_v1.png",
    "selected_model_pr_v1.png",
    "selected_model_confusion_matrix_v1.png",
    "selected_model_calibration_v1.png",
)


def main() -> None:
    checks: dict[str, bool] = {}

    train_idx, test_idx = load_frozen_split(_SPLIT_PATH)
    test_set = set(int(i) for i in test_idx)
    train_set = set(int(i) for i in train_idx)

    # --- OOF ---
    oof = pd.read_csv(_OOF_PATH)
    prob_cols = list(OOF_PROBABILITY_COLUMN.values())
    checks["oof: 4000 linhas"] = len(oof) == 4000
    checks["oof: sem row_index duplicado"] = len(oof) == len(set(oof["row_index"]))
    checks["oof: apenas TRAIN (sem TEST)"] = set(oof["row_index"]) == train_set
    checks["oof: 3 colunas de prob"] = all(c in oof.columns for c in prob_cols)
    checks["oof: prob em [0,1]"] = all(oof[c].between(0.0, 1.0).all() for c in prob_cols)
    checks["oof: y_true binario"] = set(oof["y_true"].unique()) <= {0, 1}

    # --- CV results ---
    cv = read_json(_CV_RESULTS_PATH)
    models = cv["models"]
    checks["cv: 3 modelos"] = set(models) == {"logistic_regression", "random_forest", "xgboost"}
    checks["cv: 5 folds por modelo"] = all(len(models[m]["fold_metrics"]) == 5 for m in models)
    checks["cv: threshold 0.50"] = abs(cv["threshold"] - 0.50) < 1e-9
    selected = cv["selection"]["selected_model"]
    checks["cv: selecionado entre os 3"] = selected in models

    # --- TEST results + predições ---
    test_res = read_json(_TEST_RESULTS_PATH)
    preds = pd.read_csv(_TEST_PREDICTIONS_PATH)
    checks["test: 1000 predições"] = len(preds) == 1000
    checks["test: apenas TEST"] = set(preds["row_index"]) == test_set
    checks["test: prob em [0,1]"] = preds["y_probability"].between(0.0, 1.0).all()
    checks["test: y_pred == prob>=0.5"] = np.array_equal(
        preds["y_pred"].to_numpy(), (preds["y_probability"] >= 0.50).astype(int).to_numpy()
    )
    checks["test: modelo == selecionado"] = test_res["selected_model"] == selected
    checks["test: threshold 0.50"] = abs(test_res["threshold"] - 0.50) < 1e-9
    # matriz de confusão consistente com as contagens do relatório
    cm = preds[["y_true", "y_pred"]]
    tn = int(((cm["y_true"] == 0) & (cm["y_pred"] == 0)).sum())
    fp = int(((cm["y_true"] == 0) & (cm["y_pred"] == 1)).sum())
    fn = int(((cm["y_true"] == 1) & (cm["y_pred"] == 0)).sum())
    tp = int(((cm["y_true"] == 1) & (cm["y_pred"] == 1)).sum())
    checks["test: tn/fp/fn/tp consistentes"] = (
        tn, fp, fn, tp
    ) == (test_res["tn"], test_res["fp"], test_res["fn"], test_res["tp"])

    # --- modelo serializado ---
    manifest = read_json(_MODEL_MANIFEST_PATH)
    checks["model: nome == selecionado"] = manifest["model_name"] == selected
    pipeline = load_model(_MODEL_PATH)
    checks["model: joblib carregável"] = pipeline is not None
    checks["model: n_features == 96"] = manifest["n_features"] == 96

    # --- figuras ---
    checks["figures: 4 PNGs presentes"] = all(
        (_FIGURES_DIR / f).exists() for f in _FIGURES
    )

    print("=== Invariantes dos resultados da FASE 3F-B ===")
    for name, ok in checks.items():
        print(f"  [{'OK' if ok else 'FALHA'}] {name}")

    print("\n=== Resumo ===")
    print(f"  modelo selecionado = {selected}")
    print(f"  seleção reason     = {cv['selection']['reason']}")
    print(f"  TEST pr_auc        = {test_res['pr_auc']:.6f}")
    print(f"  TEST roc_auc       = {test_res['roc_auc']:.6f}")
    print(f"  TEST accuracy      = {test_res['accuracy']:.6f}")
    print(f"  TEST recall        = {test_res['recall']:.6f}")

    if not all(checks.values()):
        raise SystemExit(1)
    print("\n[OK] todos os invariantes conferem.")


if __name__ == "__main__":
    main()
