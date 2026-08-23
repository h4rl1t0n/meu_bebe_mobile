"""Inspeção/diagnóstico do preprocessing v1 e produção de ``preprocessing_report_v1.json``.

Lê ``configs/preprocessing_v1.yaml`` + ``data/processed/dataset_synthetic_v1.jsonl``,
constrói o ``ColumnTransformer`` (NÃO ajustado de forma definitiva; o fit aqui é
apenas diagnóstico, sem split, sem serialização de produção), transforma os 5000
registros e escreve ``artifacts/metrics/preprocessing_report_v1.json``.

NÃO calcula correlação com Y, feature importance, AUC, accuracy, precision,
recall nem F1. NÃO usa M_sim nem IV-DSS.

Uso::

    python scripts/inspect_preprocessing.py
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

import numpy as np

from meu_bebe_ml.preprocessing import (
    build_x_model_preprocessor,
    check_structural_nulls,
    load_x_y,
    resolve_spec,
)

_IA_ROOT = Path(__file__).resolve().parents[1]
_CONFIG_PATH = _IA_ROOT / "configs" / "preprocessing_v1.yaml"
_DATASET_PATH = _IA_ROOT / "data" / "processed" / "dataset_synthetic_v1.jsonl"
_REPORT_PATH = _IA_ROOT / "artifacts" / "metrics" / "preprocessing_report_v1.json"

TARGET_NAME = "descontinuou_pre_natal"


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def _group_output_counts(spec) -> dict[str, int]:
    return {
        "boolean_required": len(spec.boolean_required),
        "boolean_structural": len(spec.boolean_structural) * 2,
        "numeric": len(spec.numeric),
        "ordinal": len(spec.ordinal_order),
        "nominal": sum(len(cats) for _, cats in spec.nominal),
        "multiselect": sum(len(cats) for _, cats in spec.multiselect),
    }


def main() -> None:
    import sklearn

    spec = resolve_spec()
    X_raw, y = load_x_y()

    print("Construindo preprocessor (fit de diagnóstico, sem split)...")
    pre = build_x_model_preprocessor(spec)
    Xt = pre.fit_transform(X_raw)
    names = list(pre.get_feature_names_out())

    structural = check_structural_nulls(X_raw)

    nao_informar_count = int((X_raw["faixa_renda"] == "nao_informar").sum())

    # Colunas constantes no dataset principal (apenas reportar).
    constant_columns = [
        name for name, col in zip(names, Xt.T) if float(np.std(col)) == 0.0
    ]

    report: dict[str, Any] = {
        "preprocessing_version": spec.config.version,
        "schema_version": spec.config.schema_version,
        "feature_set": spec.config.feature_set,
        "n_rows": int(len(X_raw)),
        "raw_feature_count": spec.config.raw_feature_count,
        "transformed_feature_count": int(Xt.shape[1]),
        "dtype": str(Xt.dtype),
        "shape": list(Xt.shape),
        "nan_count": int(np.isnan(Xt).sum()),
        "inf_count": int(np.isinf(Xt).sum()),
        "feature_names": names,
        "output_per_group": _group_output_counts(spec),
        "structural_nulls_by_raw_field": structural["structural_null_counts"],
        "unexpected_null_counts": structural["unexpected_null_counts"],
        "faixa_renda_nao_informar_count": nao_informar_count,
        "target_name": TARGET_NAME,
        "y_0_count": int((y == 0).sum()),
        "y_1_count": int((y == 1).sum()),
        "constant_columns": constant_columns,
        "scikit_learn_version": sklearn.__version__,
        "hashes_sha256": {
            "preprocessing_v1.yaml": _sha256(_CONFIG_PATH),
            "dataset_synthetic_v1.jsonl": _sha256(_DATASET_PATH),
        },
        "notes": [
            "encoding-only: sem imputação, sem scaling, sem feature selection",
            "nenhuma estatística do dataset usada para encoding (categorias/ordens congeladas)",
            "fit executado apenas para diagnóstico; não é preprocessor treinado final",
        ],
    }

    _REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(_REPORT_PATH, "w", encoding="utf-8") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)
    print(f"escrito: {_REPORT_PATH}")

    print("\nResumo do preprocessing v1:")
    print(f"  versão               = {report['preprocessing_version']}")
    print(f"  n_rows               = {report['n_rows']}")
    print(f"  raw features         = {report['raw_feature_count']}")
    print(f"  transformed features = {report['transformed_feature_count']}")
    print(f"  dtype                = {report['dtype']}")
    print(f"  shape                = {report['shape']}")
    print(f"  NaN                  = {report['nan_count']}")
    print(f"  Inf                  = {report['inf_count']}")
    print(f"  faixa_renda=nao_informar = {report['faixa_renda_nao_informar_count']}")
    print(f"  Y=0 / Y=1            = {report['y_0_count']} / {report['y_1_count']}")
    print(f"  constant columns     = {len(constant_columns)} {constant_columns}")
    print(f"  structural nulls     = {report['structural_nulls_by_raw_field']}")
    print(f"  output por grupo     = {report['output_per_group']}")
    print(f"  scikit-learn         = {report['scikit_learn_version']}")


if __name__ == "__main__":
    main()
