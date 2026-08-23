"""Split principal congelado (80% treino / 20% teste, estratificado).

O split opera sobre ``row_index`` (posição original da linha no
``dataset_synthetic_v1.jsonl``). NÃO embaralha nem recria IDs permanentes.

A REGRA DE OURO DO TEST SET (seção 10) aplica-se integralmente: o TEST não é
usado para qualquer decisão de modelo/hiperparâmetro/threshold/feature nesta
fase nem nas seguintes; ele é aberto uma única vez, na Fase 3F-B, somente após
a seleção do candidato exclusivamente via TRAIN + CV.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split

from .config import TrainingProtocolConfig, sha256_file


@dataclass(frozen=True)
class SplitResult:
    """Resultado do split principal (congelado e determinístico)."""

    n_total: int
    train_idx: tuple[int, ...]
    test_idx: tuple[int, ...]


def compute_split(
    y: np.ndarray,
    *,
    test_size: float,
    random_state: int,
    shuffle: bool,
    stratify: bool,
) -> SplitResult:
    """Calcula o split único 80/20 estratificado sobre índices de linha.

    ``row_index`` é ``np.arange(len(y))`` (posição original no JSONL). O split
    usa ``stratify=y`` para preservar a proporção das classes.
    """
    y = np.asarray(y)
    n = len(y)
    idx = np.arange(n, dtype=np.int64)

    stratify_arg = y if stratify else None
    train_idx, test_idx = train_test_split(
        idx,
        test_size=test_size,
        random_state=random_state,
        shuffle=shuffle,
        stratify=stratify_arg,
    )

    return SplitResult(
        n_total=n,
        train_idx=tuple(int(i) for i in np.sort(train_idx)),
        test_idx=tuple(int(i) for i in np.sort(test_idx)),
    )


def build_split_table(result: SplitResult) -> pd.DataFrame:
    """Monta o ``DataFrame`` ``row_index,split`` ordenado por ``row_index``."""
    n = result.n_total
    split = np.full(n, "test", dtype=object)
    split[list(result.train_idx)] = "train"
    return pd.DataFrame(
        {"row_index": np.arange(n, dtype=np.int64), "split": split}
    )


def _class_counts(y: np.ndarray, idx: tuple[int, ...]) -> dict[str, int]:
    sel = y[list(idx)]
    return {"Y0": int((sel == 0).sum()), "Y1": int((sel == 1).sum())}


def build_split_manifest(
    cfg: TrainingProtocolConfig,
    result: SplitResult,
    y: np.ndarray,
    *,
    dataset_hash: str,
    preprocessing_config_hash: str,
    split_hash: str,
) -> dict[str, Any]:
    """Monta o manifest do split (``train_test_split_v1_manifest.json``)."""
    total = _class_counts(y, tuple(range(result.n_total)))
    train = _class_counts(y, result.train_idx)
    test = _class_counts(y, result.test_idx)
    n_train = len(result.train_idx)
    n_test = len(result.test_idx)

    return {
        "protocol_version": cfg.version,
        "schema_version": cfg.schema_version,
        "preprocessing_version": cfg.preprocessing_version,
        "dataset_hash_sha256": dataset_hash,
        "preprocessing_config_hash_sha256": preprocessing_config_hash,
        "random_state": cfg.split.random_state,
        "test_size": cfg.split.test_size,
        "stratified": cfg.split.stratified,
        "shuffle": cfg.split.shuffle,
        "total_rows": result.n_total,
        "train_rows": n_train,
        "test_rows": n_test,
        "class_counts_total": total,
        "class_counts_train": train,
        "class_counts_test": test,
        "split_file_hash_sha256": split_hash,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


def write_split_artifacts(
    result: SplitResult,
    y: np.ndarray,
    *,
    split_path: Path,
    manifest_path: Path,
    cfg: TrainingProtocolConfig,
    dataset_path: Path,
    preprocessing_config_path: Path,
) -> dict[str, Any]:
    """Escreve ``train_test_split_v1.csv`` + manifest e devolve o manifest."""
    table = build_split_table(result)
    split_path.parent.mkdir(parents=True, exist_ok=True)
    table.to_csv(split_path, index=False)

    manifest = build_split_manifest(
        cfg,
        result,
        y,
        dataset_hash=sha256_file(dataset_path),
        preprocessing_config_hash=sha256_file(preprocessing_config_path),
        split_hash=sha256_file(split_path),
    )
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    with open(manifest_path, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, ensure_ascii=False, indent=2)
    return manifest


def load_split_table(split_path: Path) -> pd.DataFrame:
    """Carrega o CSV congelado ``row_index,split``."""
    return pd.read_csv(split_path)
