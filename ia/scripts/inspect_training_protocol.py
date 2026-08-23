"""Inspeção dos artefatos do protocolo de treinamento (FASE 3F-A).

Lê ``train_test_split_v1.csv``, ``cv_folds_v1.csv`` e seus manifests, valida os
invariantes do split/folds e imprime um resumo. NÃO treina modelo e NÃO calcula
métrica preditiva real.

Uso::

    python scripts/inspect_training_protocol.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from meu_bebe_ml.training import load_folds_table, load_split_table, load_training_config

try:  # garantir saída UTF-8 em terminais Windows
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:  # pragma: no cover
    pass

_IA_ROOT = Path(__file__).resolve().parents[1]
_CONFIG_PATH = _IA_ROOT / "configs" / "training_protocol_v1.yaml"
_SPLIT_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1.csv"
_SPLIT_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1_manifest.json"
_FOLDS_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1.csv"
_FOLDS_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1_manifest.json"


def main() -> None:
    cfg = load_training_config(_CONFIG_PATH)

    split = load_split_table(_SPLIT_PATH)
    folds = load_folds_table(_FOLDS_PATH)

    with open(_SPLIT_MANIFEST_PATH, "r", encoding="utf-8") as fh:
        split_manifest = json.load(fh)
    with open(_FOLDS_MANIFEST_PATH, "r", encoding="utf-8") as fh:
        folds_manifest = json.load(fh)

    train = set(split.loc[split["split"] == "train", "row_index"])
    test = set(split.loc[split["split"] == "test", "row_index"])
    fold_rows = set(folds["row_index"])
    fold_ids = set(folds["validation_fold"])

    checks = {
        "5000 row_index": len(split) == 5000,
        "4000 train": len(train) == 4000,
        "1000 test": len(test) == 1000,
        "sem row_index duplicado": len(split["row_index"]) == len(set(split["row_index"])),
        "train/test disjuntos": not (train & test),
        "train + test = tudo": (train | test) == set(range(5000)),
        "folds: 4000 linhas": len(folds) == 4000,
        "folds: todos no train": fold_rows <= train,
        "folds: nenhum no test": not (fold_rows & test),
        "fold ids em {0..4}": fold_ids <= {0, 1, 2, 3, 4},
        "folds: cada row exatamente 1 fold": len(folds) == len(fold_rows),
        "folds: uniao == train": fold_rows == train,
    }

    print("=== Invariantes do protocolo ===")
    for name, ok in checks.items():
        print(f"  [{'OK' if ok else 'FALHA'}] {name}")
    all_ok = all(checks.values())

    # Distribuição de classes por fold.
    print("\n=== Distribuição por fold ===")
    for fid in sorted(fold_ids):
        rows = set(folds.loc[folds["validation_fold"] == fid, "row_index"])
        print(f"  fold {fid}: {len(rows)} linhas")

    print("\n=== Manifests ===")
    print(f"  split  hash = {split_manifest.get('split_file_hash_sha256')}")
    print(f"  folds  hash = {folds_manifest.get('folds_file_hash_sha256')}")
    print(f"  dataset hash = {split_manifest.get('dataset_hash_sha256')}")
    print(f"  random_state = {split_manifest.get('random_state')}")
    print(f"  n_splits     = {folds_manifest.get('n_splits')}")

    if not all_ok:
        raise SystemExit(1)
    print("\n[OK] todos os invariantes conferem.")


if __name__ == "__main__":
    main()
