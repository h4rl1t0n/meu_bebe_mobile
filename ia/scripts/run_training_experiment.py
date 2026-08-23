"""Executa o protocolo congelado da FASE 3F-A (FASE 3F-B).

Fluxo (sem nenhuma decisão baseada em resultados — apenas EXECUTA o congelado):

  1. valida hashes dos artefatos congelados (dataset/split/folds/configs);
  2. carrega X_MODEL (34) + y e o split congelado (4000/1000);
  3. carrega os 5 folds congelados (NÃO recria StratifiedKFold);
  4. roda CV manual de Logistic Regression, Random Forest e XGBoost;
  5. agrega mean/std das métricas por fold;
  6. seleciona o modelo por mean PR-AUC → mean Recall → mean F1;
  7. ajusta o selecionado nos 4000 TRAIN (preprocessor + modelo);
  8. avalia o selecionado UMA única vez nos 1000 TEST;
  9. grava relatórios, OOF, predições do TEST, modelo serializado e 4 figuras.

Uso::

    python scripts/run_training_experiment.py
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
    MODEL_ORDER,
    aggregate_fold_metrics,
    assert_pipeline_model_is,
    build_model_manifest,
    evaluate_final_test,
    fit_final_model,
    fold_splits,
    load_frozen_dataset,
    load_frozen_folds,
    load_frozen_split,
    load_training_config,
    merge_oof,
    n_features_of,
    read_json,
    run_cv_for_model,
    save_model,
    select_model_with_reason,
    sha256_file,
    validate_oof_coverage,
)
from meu_bebe_ml.training.plotting import (
    save_calibration_curve,
    save_confusion_matrix,
    save_pr_curve,
    save_roc_curve,
)

_IA_ROOT = Path(__file__).resolve().parents[1]
_CONFIG_PATH = _IA_ROOT / "configs" / "training_protocol_v1.yaml"
_PREPROCESSING_CONFIG_PATH = _IA_ROOT / "configs" / "preprocessing_v1.yaml"
_DATASET_PATH = _IA_ROOT / "data" / "processed" / "dataset_synthetic_v1.jsonl"
_DGM_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "dgm_v1_manifest.json"
_SPLIT_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1.csv"
_SPLIT_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1_manifest.json"
_FOLDS_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1.csv"
_FOLDS_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1_manifest.json"

_OOF_PATH = _IA_ROOT / "data" / "processed" / "cv_oof_predictions_v1.csv"
_CV_RESULTS_PATH = _IA_ROOT / "artifacts" / "metrics" / "cv_results_v1.json"
_TEST_RESULTS_PATH = _IA_ROOT / "artifacts" / "metrics" / "final_test_results_v1.json"
_TEST_PREDICTIONS_PATH = _IA_ROOT / "data" / "processed" / "test_predictions_selected_v1.csv"
_MODEL_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1.joblib"
_MODEL_MANIFEST_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1_manifest.json"
_FIGURES_DIR = _IA_ROOT / "artifacts" / "figures"


def _verify_dataset_hash() -> str:
    dataset_hash = sha256_file(_DATASET_PATH)
    if not _DGM_MANIFEST_PATH.exists():
        print(f"[AVISO] manifest DGM ausente: {_DGM_MANIFEST_PATH}")
        return dataset_hash
    dgm = read_json(_DGM_MANIFEST_PATH)
    expected = dgm.get("hashes_sha256", {}).get("dataset_synthetic_v1.jsonl")
    if expected is None:
        print("[AVISO] manifest DGM não registra hash do dataset")
        return dataset_hash
    if dataset_hash != expected:
        print(
            "[ERRO] hash do dataset divergente do manifest DGM. PARE.\n"
            f"  atual   = {dataset_hash}\n  esperado= {expected}"
        )
        sys.exit(1)
    print(f"[OK] dataset hash confere: {dataset_hash}")
    return dataset_hash


def _verify_frozen_manifest_hash(name: str, file_path: Path, manifest_path: Path, key: str) -> str:
    file_hash = sha256_file(file_path)
    if manifest_path.exists():
        manifest = read_json(manifest_path)
        expected = manifest.get(key)
        if expected and file_hash != expected:
            print(
                f"[ERRO] hash de {name} divergente do manifest. PARE.\n"
                f"  atual   = {file_hash}\n  esperado= {expected}"
            )
            sys.exit(1)
    print(f"[OK] {name} hash confere: {file_hash}")
    return file_hash


def _class_counts(y: np.ndarray, idx: np.ndarray) -> dict[str, int]:
    sel = y[idx]
    return {"Y0": int((sel == 0).sum()), "Y1": int((sel == 1).sum())}


def main() -> None:
    cfg = load_training_config(_CONFIG_PATH)
    threshold = float(cfg.metrics_threshold)
    n_splits = int(cfg.cross_validation.n_splits)

    print("=== FASE 3F-B: treinamento, CV, seleção e avaliação no TEST ===\n")

    # 1) Validação dos artefatos congelados.
    dataset_hash = _verify_dataset_hash()
    split_hash = _verify_frozen_manifest_hash(
        "split", _SPLIT_PATH, _SPLIT_MANIFEST_PATH, "split_file_hash_sha256"
    )
    folds_hash = _verify_frozen_manifest_hash(
        "folds", _FOLDS_PATH, _FOLDS_MANIFEST_PATH, "folds_file_hash_sha256"
    )
    protocol_hash = sha256_file(_CONFIG_PATH)
    preprocessing_hash = sha256_file(_PREPROCESSING_CONFIG_PATH)

    # 2) Loader.
    X_raw, y = load_frozen_dataset(dataset_path=_DATASET_PATH)
    n = len(y)
    print(f"[OK] dataset carregado: N={n}, X_MODEL={X_raw.shape[1]} colunas")
    if n != 5000:
        print(f"[ERRO] N esperado 5000, obtido {n}. PARE.")
        sys.exit(1)

    # 3) Split congelado.
    train_idx, test_idx = load_frozen_split(_SPLIT_PATH)
    assert len(train_idx) == 4000 and len(test_idx) == 1000, "split inesperado"
    train_counts = _class_counts(y, train_idx)
    test_counts = _class_counts(y, test_idx)
    print(
        f"[OK] split: TRAIN={len(train_idx)} TEST={len(test_idx)}; "
        f"TRAIN Y0/Y1={train_counts['Y0']}/{train_counts['Y1']}; "
        f"TEST Y0/Y1={test_counts['Y0']}/{test_counts['Y1']}"
    )

    # 4) Folds congelados.
    folds_df = load_frozen_folds(_FOLDS_PATH)
    assert len(folds_df) == 4000, "folds deve ter 4000 linhas"
    assert set(folds_df["validation_fold"]) == set(range(n_splits)), "folds não são 0..4"
    fold_splits_ = fold_splits(folds_df, n_splits=n_splits)
    print(f"[OK] folds: {n_splits} folds congelados carregados (sem recriar StratifiedKFold)")

    # 5) CV manual dos 3 modelos (mesmos folds).
    print("\n--- Cross-validation (5 folds) ---")
    oof_by_model = {}
    summaries: dict[str, dict[str, float]] = {}
    fold_metrics_by_model = {}
    durations = {}
    scale_weights_by_model = {}

    for model_name in MODEL_ORDER:
        oof, fold_metrics, duration, scale_weights = run_cv_for_model(
            model_name, X_raw, y, fold_splits_, threshold=threshold
        )
        agg = aggregate_fold_metrics(fold_metrics)
        oof_by_model[model_name] = oof
        fold_metrics_by_model[model_name] = fold_metrics
        durations[model_name] = duration
        scale_weights_by_model[model_name] = scale_weights
        summaries[model_name] = {
            "mean_pr_auc": agg["mean_metrics"]["pr_auc"],
            "mean_recall": agg["mean_metrics"]["recall"],
            "mean_f1": agg["mean_metrics"]["f1"],
        }
        print(
            f"  [{model_name}] mean PR-AUC={summaries[model_name]['mean_pr_auc']:.6f} "
            f"mean Recall={summaries[model_name]['mean_recall']:.6f} "
            f"mean F1={summaries[model_name]['mean_f1']:.6f} "
            f"({duration:.1f}s)"
        )

    # 6) OOF unificado.
    oof_df = merge_oof(oof_by_model)
    validate_oof_coverage(oof_df, train_idx)
    print(f"[OK] OOF: {len(oof_df)} linhas (cada TRAIN exatamente 1), 3 colunas de prob.")

    # 7) Seleção do modelo.
    selected_name, reason, ranking, tiebreak_used = select_model_with_reason(summaries)
    print(f"\n[SELEÇÃO] {reason}")

    # 8) Fit final do selecionado nos 4000 TRAIN (nunca nos 5000).
    print(f"\n--- Fit final: {selected_name} nos 4000 TRAIN ---")
    X_train = X_raw.iloc[train_idx]
    final_pipeline = fit_final_model(selected_name, X_train, y[train_idx])
    assert_pipeline_model_is(final_pipeline, selected_name)
    scale_pos_weight_final = (
        float(final_pipeline.named_steps["model"].get_params()["scale_pos_weight"])
        if selected_name == "xgboost"
        else None
    )
    n_features = n_features_of(final_pipeline)
    print(f"[OK] pipeline final fitado nos 4000 TRAIN; features={n_features}")

    # 9) Avaliação UMA única vez no TEST.
    print(f"\n--- Avaliação final: {selected_name} nos 1000 TEST (uma vez) ---")
    X_test = X_raw.iloc[test_idx]
    test_result = evaluate_final_test(selected_name, final_pipeline, X_test, y[test_idx], threshold=threshold)
    print(
        f"  accuracy={test_result['accuracy']:.6f} precision={test_result['precision']:.6f} "
        f"recall={test_result['recall']:.6f} f1={test_result['f1']:.6f} "
        f"roc_auc={test_result['roc_auc']:.6f} pr_auc={test_result['pr_auc']:.6f}"
    )

    # 10) Serialização do modelo + manifest.
    save_model(final_pipeline, _MODEL_PATH)
    model_manifest = build_model_manifest(
        selected_name=selected_name,
        pipeline=final_pipeline,
        model_path=_MODEL_PATH,
        dataset_hash=dataset_hash,
        split_hash=split_hash,
        folds_hash=folds_hash,
        protocol_hash=protocol_hash,
        preprocessing_hash=preprocessing_hash,
        n_train=len(train_idx),
        class_counts_train=train_counts,
        scale_pos_weight=scale_pos_weight_final,
        threshold=threshold,
    )
    _MODEL_MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(_MODEL_MANIFEST_PATH, "w", encoding="utf-8") as fh:
        json.dump(model_manifest, fh, ensure_ascii=False, indent=2)
    print(f"[OK] modelo serializado -> {_MODEL_PATH}")

    # 11) Escrita dos relatórios JSON.
    cv_report = {
        "protocol_version": cfg.version,
        "schema_version": cfg.schema_version,
        "preprocessing_version": cfg.preprocessing_version,
        "target_name": cfg.target_name,
        "n_splits": n_splits,
        "threshold": threshold,
        "dataset_hash_sha256": dataset_hash,
        "split_file_hash_sha256": split_hash,
        "folds_file_hash_sha256": folds_hash,
        "training_protocol_config_hash_sha256": protocol_hash,
        "preprocessing_config_hash_sha256": preprocessing_hash,
        "models": {
            name: {
                "display_name": name,
                "mean_metrics": aggregate_fold_metrics(fold_metrics_by_model[name])["mean_metrics"],
                "std_metrics": aggregate_fold_metrics(fold_metrics_by_model[name])["std_metrics"],
                "fold_metrics": fold_metrics_by_model[name],
                "duration_seconds": durations[name],
                **(
                    {"scale_pos_weight_folds": scale_weights_by_model[name]}
                    if name == "xgboost"
                    else {}
                ),
            }
            for name in MODEL_ORDER
        },
        "selection": {
            "primary_metric": cfg.selection_primary_metric,
            "tiebreak": list(cfg.selection_tiebreak),
            "selected_model": selected_name,
            "selected_display_name": selected_name,
            "tiebreak_used": tiebreak_used,
            "ranking": ranking,
            "reason": reason,
        },
        "library_versions": _library_versions(),
        "timestamp": _timestamp(),
        "note": "CV 5-fold manual sobre folds congelados; seleção por PR-AUC→Recall→F1; "
        "TEST NÃO participou de nenhuma decisão.",
    }
    _CV_RESULTS_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(_CV_RESULTS_PATH, "w", encoding="utf-8") as fh:
        json.dump(cv_report, fh, ensure_ascii=False, indent=2)
    print(f"[OK] relatório CV -> {_CV_RESULTS_PATH}")

    # 12) OOF CSV.
    _OOF_PATH.parent.mkdir(parents=True, exist_ok=True)
    oof_df.to_csv(_OOF_PATH, index=False)
    print(f"[OK] OOF CSV -> {_OOF_PATH}")

    # 13) Predições do TEST (somente do selecionado) + relatório TEST.
    test_pred_df = pd.DataFrame(
        {
            "row_index": test_idx,
            "y_true": y[test_idx],
            "y_probability": test_result["y_probability"],
            "y_pred": test_result["y_pred"],
        }
    )
    _TEST_PREDICTIONS_PATH.parent.mkdir(parents=True, exist_ok=True)
    test_pred_df.to_csv(_TEST_PREDICTIONS_PATH, index=False)

    test_report = {
        "selected_model": selected_name,
        "selected_display_name": selected_name,
        "threshold": threshold,
        "n_test": test_result["n_test"],
        "class_counts_test": test_counts,
        "accuracy": test_result["accuracy"],
        "precision": test_result["precision"],
        "recall": test_result["recall"],
        "f1": test_result["f1"],
        "tn": test_result["tn"],
        "fp": test_result["fp"],
        "fn": test_result["fn"],
        "tp": test_result["tp"],
        "roc_auc": test_result["roc_auc"],
        "pr_auc": test_result["pr_auc"],
        "average_precision": test_result["average_precision"],
        "brier_score": test_result["brier_score"],
        "calibration_curve": test_result["calibration_curve"],
        "model_file_hash_sha256": model_manifest["model_file_hash_sha256"],
        "dataset_hash_sha256": dataset_hash,
        "library_versions": _library_versions(),
        "timestamp": _timestamp(),
        "note": "Avaliação UMA única vez no TEST, somente do modelo selecionado, "
        "após a seleção via TRAIN + CV.",
    }
    _TEST_RESULTS_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(_TEST_RESULTS_PATH, "w", encoding="utf-8") as fh:
        json.dump(test_report, fh, ensure_ascii=False, indent=2)
    print(f"[OK] relatório TEST -> {_TEST_RESULTS_PATH}")
    print(f"[OK] predições TEST -> {_TEST_PREDICTIONS_PATH}")

    # 14) Figuras (diagnóstico do selecionado no TEST).
    _FIGURES_DIR.mkdir(parents=True, exist_ok=True)
    save_roc_curve(y[test_idx], test_result["y_probability"], _FIGURES_DIR / "selected_model_roc_v1.png")
    save_pr_curve(y[test_idx], test_result["y_probability"], _FIGURES_DIR / "selected_model_pr_v1.png")
    save_confusion_matrix(
        y[test_idx],
        np.asarray(test_result["y_pred"]),
        _FIGURES_DIR / "selected_model_confusion_matrix_v1.png",
        threshold=threshold,
    )
    save_calibration_curve(
        np.asarray(test_result["calibration_curve"]["prob_true"]),
        np.asarray(test_result["calibration_curve"]["prob_pred"]),
        _FIGURES_DIR / "selected_model_calibration_v1.png",
    )
    print(f"[OK] figuras -> {_FIGURES_DIR}")

    # 15) Resumo final.
    print("\n=== Resumo ===")
    print(f"  modelos avaliados      = {', '.join(MODEL_ORDER)}")
    for name in MODEL_ORDER:
        s = summaries[name]
        print(f"    {name:22s} PR-AUC={s['mean_pr_auc']:.6f}  Recall={s['mean_recall']:.6f}  F1={s['mean_f1']:.6f}")
    print(f"  modelo selecionado     = {selected_name}")
    print(f"  TEST accuracy          = {test_result['accuracy']:.6f}")
    print(f"  TEST roc_auc           = {test_result['roc_auc']:.6f}")
    print(f"  TEST pr_auc            = {test_result['pr_auc']:.6f}")
    print("\n[OK] FASE 3F-B concluída. Nenhum commit foi feito.")


def _library_versions() -> dict[str, str]:
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
    }


def _timestamp() -> str:
    from datetime import datetime, timezone

    return datetime.now(timezone.utc).isoformat()


if __name__ == "__main__":
    main()
