"""Prepara o protocolo experimental de treinamento (FASE 3F-A).

Este script NÃO treina nenhum modelo nem calcula desempenho preditivo real.
Ele apenas:

  1. verifica o SHA-256 do ``dataset_synthetic_v1.jsonl`` contra o manifest
     DGM (PARE em caso de divergência);
  2. cria o split principal 80/20 estratificado (seed 42) e o congela em CSV;
  3. cria os 5 folds de StratifiedKFold DENTRO do treino e os congela em CSV;
  4. grava os manifests (split/folds) e o relatório do protocolo.

Uso::

    python scripts/prepare_training_protocol.py
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np

try:  # garantir saída UTF-8 em terminais Windows
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:  # pragma: no cover
    pass

from meu_bebe_ml.preprocessing import load_x_y
from meu_bebe_ml.training import (
    build_folds_manifest,
    compute_folds,
    compute_split,
    load_training_config,
    sha256_file,
    write_folds_artifacts,
    write_split_artifacts,
)
from meu_bebe_ml.training.folds import build_folds_table
from meu_bebe_ml.training.split import build_split_table

_IA_ROOT = Path(__file__).resolve().parents[1]
_CONFIG_PATH = _IA_ROOT / "configs" / "training_protocol_v1.yaml"
_PREPROCESSING_CONFIG_PATH = _IA_ROOT / "configs" / "preprocessing_v1.yaml"
_DATASET_PATH = _IA_ROOT / "data" / "processed" / "dataset_synthetic_v1.jsonl"
_DGM_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "dgm_v1_manifest.json"
_SPLIT_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1.csv"
_SPLIT_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1_manifest.json"
_FOLDS_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1.csv"
_FOLDS_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1_manifest.json"
_REPORT_PATH = _IA_ROOT / "artifacts" / "metrics" / "training_protocol_report_v1.json"


def _verify_dataset_hash() -> str:
    """Compara o hash do dataset com o registrado no manifest DGM."""
    dataset_hash = sha256_file(_DATASET_PATH)

    if not _DGM_MANIFEST_PATH.exists():
        print(f"[AVISO] manifest DGM ausente: {_DGM_MANIFEST_PATH} — prosseguindo sem conferência")
        return dataset_hash

    with open(_DGM_MANIFEST_PATH, "r", encoding="utf-8") as fh:
        dgm = json.load(fh)
    expected = dgm.get("hashes_sha256", {}).get("dataset_synthetic_v1.jsonl")
    if expected is None:
        print("[AVISO] manifest DGM não registra hash do dataset — prosseguindo")
        return dataset_hash
    if dataset_hash != expected:
        print(
            "[ERRO] hash do dataset divergente do manifest DGM. PARE.\n"
            f"  atual   = {dataset_hash}\n"
            f"  esperado= {expected}"
        )
        sys.exit(1)
    print(f"[OK] dataset hash confere: {dataset_hash}")
    return dataset_hash


def _build_report(
    cfg,
    dataset_hash: str,
    preprocessing_config_hash: str,
    protocol_config_hash: str,
    y: np.ndarray,
    train_idx: tuple[int, ...],
    test_idx: tuple[int, ...],
    folds_row_index: tuple[int, ...],
    folds_of: tuple[int, ...],
    split_manifest: dict[str, Any],
    folds_manifest: dict[str, Any],
) -> dict[str, Any]:
    def counts(idx) -> dict[str, int]:
        sel = y[list(idx)]
        return {"Y0": int((sel == 0).sum()), "Y1": int((sel == 1).sum())}

    y_by_row = {r: int(y[r]) for r in folds_row_index}
    fold_class_counts = {}
    for fold_id in range(cfg.cross_validation.n_splits):
        rows = [r for r, f in zip(folds_row_index, folds_of) if f == fold_id]
        fold_class_counts[str(fold_id)] = {
            "Y0": sum(1 for r in rows if y_by_row[r] == 0),
            "Y1": sum(1 for r in rows if y_by_row[r] == 1),
        }

    total = counts(tuple(range(len(y))))
    train = counts(train_idx)
    test = counts(test_idx)
    n_train = len(train_idx)
    n_test = len(test_idx)

    def rate(c: dict[str, int]) -> float:
        return round(c["Y1"] / (c["Y0"] + c["Y1"]), 6) if (c["Y0"] + c["Y1"]) else 0.0

    return {
        "protocol_version": cfg.version,
        "schema_version": cfg.schema_version,
        "preprocessing_version": cfg.preprocessing_version,
        "target_name": cfg.target_name,
        "dataset_hash_sha256": dataset_hash,
        "preprocessing_config_hash_sha256": preprocessing_config_hash,
        "training_protocol_config_hash_sha256": protocol_config_hash,
        "n_rows": int(len(y)),
        "train_rows": n_train,
        "test_rows": n_test,
        "class_counts_total": total,
        "class_counts_train": train,
        "class_counts_test": test,
        "positive_rate_total": rate(total),
        "positive_rate_train": rate(train),
        "positive_rate_test": rate(test),
        "fold_sizes": {str(k): int(v) for k, v in folds_manifest["fold_sizes"].items()},
        "fold_class_counts": fold_class_counts,
        "models": list(cfg.models),
        "hyperparameters": {
            name: dict(cfg.model_params[name]) for name in cfg.models
        },
        "imbalance_strategy": dict(cfg.imbalance_strategy),
        "metrics": {
            "threshold": cfg.metrics_threshold,
            "thresholded": list(cfg.metrics_thresholded),
            "threshold_independent": list(cfg.metrics_threshold_independent),
            "calibration": list(cfg.metrics_calibration),
        },
        "decision_threshold": cfg.decision_threshold,
        "model_selection_rule": {
            "source": cfg.selection_source,
            "primary_metric": cfg.selection_primary_metric,
            "tiebreak": list(cfg.selection_tiebreak),
        },
        "library_versions": _library_versions(),
        "hashes_sha256": {
            "dataset_synthetic_v1.jsonl": dataset_hash,
            "preprocessing_v1.yaml": preprocessing_config_hash,
            "training_protocol_v1.yaml": protocol_config_hash,
            "train_test_split_v1.csv": split_manifest["split_file_hash_sha256"],
            "cv_folds_v1.csv": folds_manifest["folds_file_hash_sha256"],
        },
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "note": "Nenhum modelo foi treinado; nenhuma métrica preditiva real foi calculada nesta fase.",
    }


def _library_versions() -> dict[str, str]:
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
    }


def main() -> None:
    cfg = load_training_config(_CONFIG_PATH)

    # 1) Verificação de hash do dataset (anti-divergência).
    dataset_hash = _verify_dataset_hash()

    # 2) Loader (X_MODEL 34 + y). X não é usado aqui (não há fit/preprocess).
    X_raw, y = load_x_y()
    n = len(y)
    print(f"[OK] dataset carregado: N={n}")
    if n != 5000:
        print(f"[ERRO] N esperado 5000, obtido {n}. PARE.")
        sys.exit(1)
    if set(np.unique(y)) != {0, 1}:
        print(f"[ERRO] target não binário 0/1. PARE.")
        sys.exit(1)

    # 3) Split principal.
    split = compute_split(
        y,
        test_size=cfg.split.test_size,
        random_state=cfg.split.random_state,
        shuffle=cfg.split.shuffle,
        stratify=cfg.split.stratified,
    )
    split_manifest = write_split_artifacts(
        split,
        y,
        split_path=_SPLIT_PATH,
        manifest_path=_SPLIT_MANIFEST_PATH,
        cfg=cfg,
        dataset_path=_DATASET_PATH,
        preprocessing_config_path=_PREPROCESSING_CONFIG_PATH,
    )
    print(
        f"[OK] split: train={len(split.train_idx)} test={len(split.test_idx)} "
        f"-> {_SPLIT_PATH}"
    )

    # 4) Folds DENTRO do treino.
    train_row_index = np.asarray(split.train_idx, dtype=np.int64)
    train_y = y[train_row_index]
    folds = compute_folds(
        train_row_index,
        train_y,
        n_splits=cfg.cross_validation.n_splits,
        random_state=cfg.cross_validation.random_state,
        shuffle=cfg.cross_validation.shuffle,
    )
    folds_manifest = write_folds_artifacts(
        folds,
        y,
        folds_path=_FOLDS_PATH,
        manifest_path=_FOLDS_MANIFEST_PATH,
        cfg=cfg,
        split_path=_SPLIT_PATH,
    )
    print(f"[OK] folds: 5 folds sobre {len(train_row_index)} treino -> {_FOLDS_PATH}")

    # 5) Relatório do protocolo (SEM métricas preditivas reais).
    report = _build_report(
        cfg,
        dataset_hash,
        sha256_file(_PREPROCESSING_CONFIG_PATH),
        sha256_file(_CONFIG_PATH),
        y,
        split.train_idx,
        split.test_idx,
        folds.train_row_index,
        folds.fold_of,
        split_manifest,
        folds_manifest,
    )
    _REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(_REPORT_PATH, "w", encoding="utf-8") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)
    print(f"[OK] relatório do protocolo -> {_REPORT_PATH}")

    # Sanidade final (nunca fit de modelo).
    assert build_split_table(split).shape[0] == n
    assert build_folds_table(folds).shape[0] == len(train_row_index)

    print("\nResumo do protocolo:")
    print(f"  N total         = {report['n_rows']}")
    print(f"  train / test    = {report['train_rows']} / {report['test_rows']}")
    print(f"  Y=0/Y=1 total   = {report['class_counts_total']['Y0']} / {report['class_counts_total']['Y1']}")
    print(f"  Y=0/Y=1 train   = {report['class_counts_train']['Y0']} / {report['class_counts_train']['Y1']}")
    print(f"  Y=0/Y=1 test    = {report['class_counts_test']['Y0']} / {report['class_counts_test']['Y1']}")
    print(f"  folds sizes     = {report['fold_sizes']}")
    print(f"  modelos         = {report['models']}")
    print("  (nenhum modelo treinado; nenhuma métrica preditiva real calculada)")


if __name__ == "__main__":
    main()
