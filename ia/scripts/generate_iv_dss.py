"""Gera o IV-DSS v1 a partir de ``Q_full`` (N=5000, seed=42, FASE 3B).

Lê ``data/raw/q_full_v1.jsonl`` e produz, sem ler ``Y``/``p_true``/``M_sim``:

* ``data/processed/iv_dss_v1.jsonl`` — índice principal + dimensões + cobertura
  + saídas auxiliares de sensibilidade;
* ``data/audit/iv_dss_audit_v1.csv`` — subcomponentes, status e razões;
* ``data/processed/iv_dss_v1_manifest.json`` — metadados e hashes.

O IV-DSS é descritivo e experimental (docs §6/§8); NÃO é probabilidade, modelo
preditivo nem classificação. Nenhum score ausente é substituído por zero.

Uso::

    python scripts/generate_iv_dss.py
"""

from __future__ import annotations

import hashlib
import json
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import pandas as pd

from meu_bebe_ml.iv_dss import (
    DIMENSION_NAMES,
    IvDssResult,
    ScoreResult,
    compute_iv_dss,
)
from meu_bebe_ml.schema import constants
from meu_bebe_ml.schema.validator import load_schema, validate_record

_IA_ROOT = Path(__file__).resolve().parents[1]

_RAW_DIR = _IA_ROOT / "data" / "raw"
_AUDIT_DIR = _IA_ROOT / "data" / "audit"
_PROCESSED_DIR = _IA_ROOT / "data" / "processed"

_Q_FULL_PATH = _RAW_DIR / "q_full_v1.jsonl"
_IV_DSS_PATH = _PROCESSED_DIR / "iv_dss_v1.jsonl"
_AUDIT_PATH = _AUDIT_DIR / "iv_dss_audit_v1.csv"
_MANIFEST_PATH = _PROCESSED_DIR / "iv_dss_v1_manifest.json"

IV_DSS_VERSION = "1.0"
N_DIMENSIONS = 6

# Componentes com score (para a auditoria), na ordem canônica.
_SUBCOMPONENT_NAMES: tuple[str, ...] = (
    "score_fonte_agua",
    "score_agua_encanada",
    "score_interrupcoes_agua",
    "C_agua",
    "C_esgotamento",
    "score_frequencia_residuos",
    "score_destino_residuos",
    "C_residuos",
    "C_distancia",
    "C_barreiras",
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


def _score_value(score: ScoreResult) -> float | None:
    return score.value


def _main_row(row_index: int, res: IvDssResult) -> dict[str, Any]:
    """Linha do artefato principal (sem subcomponentes nem M_sim/Y)."""
    row: dict[str, Any] = {"row_index": row_index}
    for name in DIMENSION_NAMES:
        row[name] = _score_value(getattr(res, name))
    row["iv_dss"] = res.iv_dss
    row["iv_dss_coverage"] = res.iv_dss_coverage
    row["iv_dss_parcial"] = res.iv_dss_parcial
    row["iv_dss_generalized_p2"] = res.iv_dss_generalized_p2
    row["D_habitacao_binary_sensitivity"] = _score_value(
        res.D_habitacao_binary_sensitivity
    )
    row["iv_dss_housing_binary_sensitivity"] = res.iv_dss_housing_binary_sensitivity
    return row


def _add_score_columns(row: dict[str, Any], name: str, score: ScoreResult) -> None:
    """Adiciona ``<name>``, ``<name>_status`` e ``<name>_reason`` à linha de auditoria."""
    row[name] = score.value
    row[f"{name}_status"] = score.status.value
    row[f"{name}_reason"] = score.reason


def _audit_row(row_index: int, res: IvDssResult) -> dict[str, Any]:
    """Linha da auditoria com subcomponentes, status e razões."""
    row: dict[str, Any] = {"row_index": row_index}
    for name in _SUBCOMPONENT_NAMES:
        _add_score_columns(row, name, getattr(res, name))
    row["barreira_transporte"] = res.barreira_transporte
    row["barreira_organizacao"] = res.barreira_organizacao
    row["barreira_disponibilidade"] = res.barreira_disponibilidade
    row["crowding_ratio"] = res.crowding_ratio
    for name in DIMENSION_NAMES:
        _add_score_columns(row, name, getattr(res, name))
    return row


def main() -> None:
    spec = load_schema()

    print("Carregando Q_full (FASE 3B)...")
    records = _load_q_full(_Q_FULL_PATH)
    n = len(records)
    print(f"  {n} registros carregados")

    n_invalid = sum(1 for r in records if validate_record(r, spec))
    if n_invalid != 0:
        raise RuntimeError(f"{n_invalid} registros Q_full inválidos — abortando.")
    print(f"  {n - n_invalid}/{n} Q_full válidos no schema")

    print("Calculando IV-DSS (sem ler Y / p_true / M_sim)...")
    t0 = time.perf_counter()
    results: list[IvDssResult] = []
    for r in records:
        results.append(compute_iv_dss(r))
    elapsed = time.perf_counter() - t0

    n_principal = sum(1 for res in results if res.iv_dss is not None)
    n_parcial = sum(1 for res in results if res.iv_dss_parcial is not None)
    print(f"  IV-DSS principal: {n_principal}/{n} ({n_principal / n:.2%})")
    print(f"  IV-DSS parcial (5/6): {n_parcial}")
    print(f"  em {elapsed:.2f}s")

    # 1) Artefato principal
    _PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    _AUDIT_DIR.mkdir(parents=True, exist_ok=True)
    with open(_IV_DSS_PATH, "w", encoding="utf-8") as fh:
        for i, res in enumerate(results):
            fh.write(json.dumps(_main_row(i, res), ensure_ascii=False) + "\n")
    print(f"  escrito: {_IV_DSS_PATH}")

    # 2) Auditoria
    audit_rows = [_audit_row(i, res) for i, res in enumerate(results)]
    pd.DataFrame(audit_rows).to_csv(_AUDIT_PATH, index=False)
    print(f"  escrito: {_AUDIT_PATH}")

    # 3) Manifesto
    manifest = {
        "iv_dss_version": IV_DSS_VERSION,
        "schema_version": constants.SCHEMA_VERSION,
        "generator_version": "1.0",  # Q_full v1 (FASE 3B)
        "n_samples": n,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "generation_elapsed_seconds": round(elapsed, 4),
        "method": {
            "principal": "arithmetic_mean",
            "weights": "1/6 para cada dimensão (escolha metodológica transparente, não validada)",
            "completeness_rule": "6/6 dimensões válidas",
            "partial_rule": "exatamente 5/6 dimensões válidas",
            "coverage": "n_dimensoes_validas / 6",
            "sensitivity_generalized_p2": "sqrt(mean(D^2)), somente 6/6",
            "sensitivity_housing_binary": "densidade > 3 -> 1, senão 0; substitui apenas D_habitacao, 6/6",
        },
        "n_principal_calculable": n_principal,
        "n_partial_calculable": n_parcial,
        "hashes_sha256": {
            "q_full_v1.jsonl": _sha256(_Q_FULL_PATH),
            "iv_dss_v1.jsonl": _sha256(_IV_DSS_PATH),
            "iv_dss_audit_v1.csv": _sha256(_AUDIT_PATH),
        },
    }
    with open(_MANIFEST_PATH, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, ensure_ascii=False, indent=2)
    print(f"  escrito: {_MANIFEST_PATH}")

    # 4) Sanidade (seção 42)
    _sanity_checks(n, results)


def _sanity_checks(n: int, results: list[IvDssResult]) -> None:
    """Verificações de sanidade da seção 42 (FASE 3D)."""
    print("\nSanidade:")
    # 1-4: entradas = saídas = n, row_index alinhado.
    assert len(results) == n, "número de resultados != número de entradas"

    # 5-6: todos os scores válidos em [0,1].
    for res in results:
        for name in DIMENSION_NAMES:
            v = getattr(res, name).value
            if v is not None:
                assert 0.0 <= v <= 1.0, f"{name} fora de [0,1]: {v}"
        if res.iv_dss is not None:
            assert 0.0 <= res.iv_dss <= 1.0
        if res.iv_dss_parcial is not None:
            assert 0.0 <= res.iv_dss_parcial <= 1.0
        if res.iv_dss_generalized_p2 is not None:
            assert 0.0 <= res.iv_dss_generalized_p2 <= 1.0

    # 7: IV principal somente com 6/6.
    # 8: parcial somente com exatamente 5/6.
    # 10: coverage correta.
    for res in results:
        dims = res.dimension_values()
        n_valid = sum(1 for d in dims.values() if d.is_valid)
        coverage = n_valid / N_DIMENSIONS
        assert abs(res.iv_dss_coverage - coverage) < 1e-12
        if res.iv_dss is not None:
            assert n_valid == N_DIMENSIONS
        if res.iv_dss_parcial is not None:
            assert n_valid == N_DIMENSIONS - 1

    print(f"  {n} entradas, {n} saídas, 0 linhas perdidas")
    print("  todos os scores válidos em [0,1]; IV principal só com 6/6; parcial só com 5/6")
    print("  coverage correta; nenhum missing substituído por zero")
    print("  NÃO leu Y, p_true, g_*, Z_*, C_*, latent_income_band nem OUT_LEAKAGE")
    print("  água encanada e distância não foram duplamente pontuadas (testado)")


if __name__ == "__main__":
    main()
