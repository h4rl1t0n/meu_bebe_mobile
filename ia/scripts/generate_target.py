"""Gera o desfecho sintético Y e os artefatos da FASE 3C.

Lê ``data/raw/q_full_v1.jsonl`` + ``data/audit/q_full_generation_audit_v1.csv``
(ambos congelados na FASE 3B) e produz:

* ``data/processed/dataset_synthetic_v1.jsonl`` — Q_full (48) + ``descontinuou_pre_natal``;
* ``data/audit/dgm_audit_v1.csv`` — M_sim do DGM (g_*, interações, U, eta, p_true, Y);
* ``data/processed/dgm_v1_manifest.json`` — metadados, alpha, hashes e validação.

NÃO regenera Q_full. Os dados são ignorados pelo Git (política em ``ia/.gitignore``).

Uso::

    python scripts/generate_target.py
"""

from __future__ import annotations

import hashlib
import json
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd

from meu_bebe_ml.schema import constants
from meu_bebe_ml.schema.validator import load_schema, validate_record
from meu_bebe_ml.simulation import (
    build_audit_dataframe,
    build_observed_dataset,
    generate_target,
    load_generator_config,
    load_simulation_config,
)

_IA_ROOT = Path(__file__).resolve().parents[1]

_RAW_DIR = _IA_ROOT / "data" / "raw"
_AUDIT_DIR = _IA_ROOT / "data" / "audit"
_PROCESSED_DIR = _IA_ROOT / "data" / "processed"
_CONFIGS_DIR = _IA_ROOT / "configs"

_Q_FULL_PATH = _RAW_DIR / "q_full_v1.jsonl"
_Q_FULL_AUDIT_PATH = _AUDIT_DIR / "q_full_generation_audit_v1.csv"
_SIM_CONFIG_PATH = _CONFIGS_DIR / "simulation_v1.yaml"

_DATASET_PATH = _PROCESSED_DIR / "dataset_synthetic_v1.jsonl"
_DGM_AUDIT_PATH = _AUDIT_DIR / "dgm_audit_v1.csv"
_MANIFEST_PATH = _PROCESSED_DIR / "dgm_v1_manifest.json"

DGM_VERSION = "1.0"
RNG_STRATEGY = (
    "numpy.random.SeedSequence(master_seed).spawn(2) -> [ruído U, Bernoulli Y]; "
    "streams independentes do RNG que gerou Q_full (FASE 3B)"
)


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def _load_q_full(path: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    with open(path, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line:
                records.append(json.loads(line))
    return records


def _load_audit(path: Path, n: int) -> pd.DataFrame:
    """Carrega o audit da FASE 3B, ordena por row_index e valida o alinhamento."""
    audit = pd.read_csv(path)
    audit = audit.sort_values("row_index").reset_index(drop=True)
    if list(audit["row_index"]) != list(range(n)):
        raise RuntimeError("row_index do audit da FASE 3B não alinhado (0..n-1)")
    return audit


def main() -> None:
    sim_config = load_simulation_config()
    gen_config = load_generator_config()
    spec = load_schema()

    seed = int(sim_config["seed"])
    noise_sd = float(sim_config["noise_sd"])
    target_rate = float(sim_config["target_positive_rate"])

    print(f"Carregando Q_full e M_sim da FASE 3B...")
    records = _load_q_full(_Q_FULL_PATH)
    n = len(records)
    audit = _load_audit(_Q_FULL_AUDIT_PATH, n)
    print(f"  {n} registros carregados")

    # Validação: nenhum Q_full deve ter sido corrompido na persistência.
    n_invalid = sum(1 for r in records if validate_record(r, spec))
    if n_invalid != 0:
        raise RuntimeError(f"{n_invalid} registros Q_full inválidos — abortando.")
    print(f"  {n - n_invalid}/{n} Q_full válidos no schema")

    latent_income_bands = audit["latent_income_band"].tolist()
    income_masked = [bool(x) for x in audit["income_was_masked"].tolist()]

    print(f"Gerando Y (seed={seed}, target={target_rate}, noise_sd={noise_sd})...")
    t0 = time.perf_counter()
    result = generate_target(
        records,
        latent_income_bands,
        income_masked=income_masked,
        seed=seed,
        sim_config=sim_config,
    )
    elapsed = time.perf_counter() - t0

    mean_p_true = float(np.mean(result.p_true))
    pos_count = int(result.Y.sum())
    pos_rate = pos_count / n
    print(f"  alpha={result.alpha:.8f}  mean(p_true)={mean_p_true:.8f}")
    print(f"  Y=1: {pos_count} ({pos_rate:.2%})  em {elapsed:.2f}s")

    # 1) Dataset observado (Q_full + target)
    dataset = build_observed_dataset(records, result.Y)
    _PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    _AUDIT_DIR.mkdir(parents=True, exist_ok=True)
    with open(_DATASET_PATH, "w", encoding="utf-8") as fh:
        for row in dataset:
            fh.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(f"  escrito: {_DATASET_PATH}")

    # 2) Auditoria do DGM
    audit_df = build_audit_dataframe(result)
    audit_df.to_csv(_DGM_AUDIT_PATH, index=False)
    print(f"  escrito: {_DGM_AUDIT_PATH}")

    # 3) Manifesto
    manifest = {
        "dgm_version": DGM_VERSION,
        "schema_version": sim_config.get("schema_version"),
        "generator_version": gen_config.get("version"),
        "seed": seed,
        "rng_strategy": RNG_STRATEGY,
        "n_samples": n,
        "target_positive_rate": target_rate,
        "noise_sd": noise_sd,
        "alpha": result.alpha,
        "mean_p_true": mean_p_true,
        "realized_positive_count": pos_count,
        "realized_positive_rate": pos_rate,
        "min_p_true": float(np.min(result.p_true)),
        "max_p_true": float(np.max(result.p_true)),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "generation_elapsed_seconds": round(elapsed, 4),
        "validation": {
            "q_full_valid_records": n - n_invalid,
            "q_full_invalid_records": n_invalid,
            "dataset_keys": list(constants.Q_FULL) + ["descontinuou_pre_natal"],
        },
        "dgm_config": sim_config["dgmgm"],
        "hashes_sha256": {
            "q_full_v1.jsonl": _sha256(_Q_FULL_PATH),
            "q_full_generation_audit_v1.csv": _sha256(_Q_FULL_AUDIT_PATH),
            "simulation_v1.yaml": _sha256(_SIM_CONFIG_PATH),
            "dataset_synthetic_v1.jsonl": _sha256(_DATASET_PATH),
            "dgm_audit_v1.csv": _sha256(_DGM_AUDIT_PATH),
        },
    }
    with open(_MANIFEST_PATH, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, ensure_ascii=False, indent=2)
    print(f"  escrito: {_MANIFEST_PATH}")


if __name__ == "__main__":
    main()
