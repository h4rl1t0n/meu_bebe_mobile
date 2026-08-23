"""Gera o cenário principal de Q_full (N=5000, seed=42).

Saídas (todas sob ``ia/``):

* ``data/raw/q_full_v1.jsonl`` — 48 variáveis canônicas por linha;
* ``data/audit/q_full_generation_audit_v1.csv`` — M_sim de auditoria;
* ``data/raw/q_full_v1_manifest.json`` — metadados, hashes e validação.

Nunca mistura os arquivos. Os dados gerados são ignorados pelo Git (política
em ``ia/.gitignore``).

Uso::

    python scripts/generate_q_full.py
"""

from __future__ import annotations

import hashlib
import json
import time
from datetime import datetime, timezone
from pathlib import Path

from meu_bebe_ml.schema import constants
from meu_bebe_ml.schema.validator import load_schema, validate_record
from meu_bebe_ml.simulation import generate_q_full, load_generator_config, load_simulation_config

_IA_ROOT = Path(__file__).resolve().parents[1]

_RAW_DIR = _IA_ROOT / "data" / "raw"
_AUDIT_DIR = _IA_ROOT / "data" / "audit"
_CONFIGS_DIR = _IA_ROOT / "configs"

_Q_FULL_PATH = _RAW_DIR / "q_full_v1.jsonl"
_AUDIT_PATH = _AUDIT_DIR / "q_full_generation_audit_v1.csv"
_MANIFEST_PATH = _RAW_DIR / "q_full_v1_manifest.json"

_SCHEMA_PATH = _CONFIGS_DIR / "schema_v1_13.yaml"
_GENERATOR_CONFIG_PATH = _CONFIGS_DIR / "generator_q_full_v1.yaml"
_SIM_CONFIG_PATH = _CONFIGS_DIR / "simulation_v1.yaml"


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> None:
    config = load_generator_config()
    sim_config = load_simulation_config()
    spec = load_schema()

    n = int(config["n_samples"])
    seed = int(config["seed"])

    print(f"Gerando {n} registros (seed={seed})...")
    t0 = time.perf_counter()
    records, m_sim = generate_q_full(n_samples=n, seed=seed, config=config, sim_config=sim_config)
    elapsed = time.perf_counter() - t0

    # Validação explícita (reforço; generate_q_full já falha se inválido).
    n_invalid = sum(1 for r in records if validate_record(r, spec))
    if n_invalid != 0:
        raise RuntimeError(f"{n_invalid} registros inválidos — abortando sem salvar.")
    print(f"  {len(records)}/{n} válidos em {elapsed:.2f}s")

    # 1) Q_full (JSONL, somente as 48 chaves canônicas)
    _RAW_DIR.mkdir(parents=True, exist_ok=True)
    _AUDIT_DIR.mkdir(parents=True, exist_ok=True)
    with open(_Q_FULL_PATH, "w", encoding="utf-8") as fh:
        for r in records:
            ordered = {k: r[k] for k in constants.Q_FULL}
            fh.write(json.dumps(ordered, ensure_ascii=False) + "\n")
    print(f"  escrito: {_Q_FULL_PATH}")

    # 2) Auditoria M_sim
    m_sim.to_csv(_AUDIT_PATH, index=False)
    print(f"  escrito: {_AUDIT_PATH}")

    # 3) Manifesto
    manifest = {
        "generator_version": config.get("version"),
        "schema_version": config.get("schema_version"),
        "seed": seed,
        "n_samples": n,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "generation_elapsed_seconds": round(elapsed, 4),
        "validation": {"valid_records": len(records), "invalid_records": n_invalid},
        "config_used": {
            "generator": config,
            "simulation_z_correlation_matrix": sim_config["z_correlation_matrix"],
        },
        "hashes_sha256": {
            "generator_q_full_v1.yaml": _sha256(_GENERATOR_CONFIG_PATH),
            "simulation_v1.yaml": _sha256(_SIM_CONFIG_PATH),
            "schema_v1_13.yaml": _sha256(_SCHEMA_PATH),
            "q_full_v1.jsonl": _sha256(_Q_FULL_PATH),
            "q_full_generation_audit_v1.csv": _sha256(_AUDIT_PATH),
        },
    }
    with open(_MANIFEST_PATH, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, ensure_ascii=False, indent=2)
    print(f"  escrito: {_MANIFEST_PATH}")


if __name__ == "__main__":
    main()
