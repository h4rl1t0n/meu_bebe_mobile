"""Folds de cross-validation congelados (StratifiedKFold, 5 folds).

Os folds são definidos DENTRO APENAS dos 4000 registros de treino. Cada registro
do treino participa exatamente uma vez como validation (fold 0..4) e nas outras
quatro como training. Nenhum registro do TEST entra nos folds.

Os mesmos folds são usados por Logistic Regression, Random Forest e XGBoost —
garantindo comparabilidade justa na Fase 3F-B.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
from sklearn.model_selection import StratifiedKFold

from .config import TrainingProtocolConfig, sha256_file


@dataclass(frozen=True)
class FoldsResult:
    """Atribuição de validation_fold para cada registro de treino."""

    train_row_index: tuple[int, ...]
    fold_of: tuple[int, ...]


def compute_folds(
    train_row_index: np.ndarray,
    train_y: np.ndarray,
    *,
    n_splits: int,
    random_state: int,
    shuffle: bool,
) -> FoldsResult:
    """Atribui um ``validation_fold`` (0..n_splits-1) a cada linha de treino.

    ``StratifiedKFold.split`` é chamado com ``y = train_y`` (estratificação);
    ``X`` é um vetor dummy — a divisão depende apenas de ``y`` e dos índices.
    """
    train_row_index = np.asarray(train_row_index, dtype=np.int64)
    train_y = np.asarray(train_y)
    n = len(train_y)

    if len(train_row_index) != n:
        raise ValueError("train_row_index e train_y têm tamanhos diferentes")

    skf = StratifiedKFold(n_splits=n_splits, shuffle=shuffle, random_state=random_state)
    fold_of = np.full(n, -1, dtype=np.int64)
    dummy = np.zeros(n)
    for fold_id, (_, val_idx) in enumerate(skf.split(dummy, train_y)):
        fold_of[val_idx] = fold_id

    if int((fold_of < 0).sum()) != 0:
        raise ValueError("nem todo registro de treino recebeu um validation_fold")

    return FoldsResult(
        train_row_index=tuple(int(i) for i in train_row_index),
        fold_of=tuple(int(i) for i in fold_of),
    )


def build_folds_table(result: FoldsResult) -> pd.DataFrame:
    """Monta ``row_index,validation_fold`` ordenado por ``row_index``."""
    df = pd.DataFrame(
        {
            "row_index": list(result.train_row_index),
            "validation_fold": list(result.fold_of),
        }
    )
    return df.sort_values("row_index").reset_index(drop=True)


def _fold_class_counts(
    y_by_row: dict[int, int], rows: tuple[int, ...]
) -> dict[str, int]:
    return {
        "Y0": sum(1 for r in rows if y_by_row[r] == 0),
        "Y1": sum(1 for r in rows if y_by_row[r] == 1),
    }


def build_folds_manifest(
    cfg: TrainingProtocolConfig,
    result: FoldsResult,
    y: np.ndarray,
    *,
    split_hash: str,
    folds_hash: str,
) -> dict[str, Any]:
    """Monta o manifest dos folds (``cv_folds_v1_manifest.json``)."""
    # y é o vetor COMPLETO (N=5000); indexa por row_index.
    y_by_row = {r: int(y[r]) for r in result.train_row_index}

    fold_sizes: dict[str, int] = {}
    fold_counts: dict[str, dict[str, int]] = {}
    for fold_id in range(cfg.cross_validation.n_splits):
        rows = tuple(
            r for r, f in zip(result.train_row_index, result.fold_of) if f == fold_id
        )
        fold_sizes[str(fold_id)] = len(rows)
        fold_counts[str(fold_id)] = _fold_class_counts(y_by_row, rows)

    return {
        "protocol_version": cfg.version,
        "schema_version": cfg.schema_version,
        "preprocessing_version": cfg.preprocessing_version,
        "split_file_hash_sha256": split_hash,
        "n_splits": cfg.cross_validation.n_splits,
        "shuffle": cfg.cross_validation.shuffle,
        "random_state": cfg.cross_validation.random_state,
        "fold_sizes": fold_sizes,
        "fold_class_counts": fold_counts,
        "folds_file_hash_sha256": folds_hash,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


def write_folds_artifacts(
    result: FoldsResult,
    y: np.ndarray,
    *,
    folds_path: Path,
    manifest_path: Path,
    cfg: TrainingProtocolConfig,
    split_path: Path,
) -> dict[str, Any]:
    """Escreve ``cv_folds_v1.csv`` + manifest e devolve o manifest."""
    table = build_folds_table(result)
    folds_path.parent.mkdir(parents=True, exist_ok=True)
    table.to_csv(folds_path, index=False)

    manifest = build_folds_manifest(
        cfg,
        result,
        y,
        split_hash=sha256_file(split_path),
        folds_hash=sha256_file(folds_path),
    )
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    with open(manifest_path, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, ensure_ascii=False, indent=2)
    return manifest


def load_folds_table(folds_path: Path) -> pd.DataFrame:
    """Carrega o CSV congelado ``row_index,validation_fold``."""
    return pd.read_csv(folds_path)
