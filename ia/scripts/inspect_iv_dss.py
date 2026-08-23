"""Inspeção descritiva do IV-DSS v1 e produção de ``iv_dss_report_v1.json``.

Lê ``data/processed/iv_dss_v1.jsonl`` (índice + dimensões) e
``data/audit/iv_dss_audit_v1.csv`` (status e razões) e escreve
``artifacts/metrics/iv_dss_report_v1.json`` com estatísticas descritivas:

* por dimensão — N válido/ausente, média, desvio, min/max, quantis
  1/5/25/50/75/95/99%;
* IV-DSS principal — mesmas estatísticas;
* distribuição de cobertura (0/6 .. 6/6);
* contagem de IV-DSS parcial (exatamente 5/6);
* causas de ausência (status/reason) por dimensão;
* média generalizada p=2 e sensibilidade binária de Habitação.

É somente leitura/descrição — NÃO altera dados, NÃO treina modelos, NÃO usa Y.

Uso::

    python scripts/inspect_iv_dss.py
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import pandas as pd

_IA_ROOT = Path(__file__).resolve().parents[1]
_PROCESSED_DIR = _IA_ROOT / "data" / "processed"
_AUDIT_DIR = _IA_ROOT / "data" / "audit"
_METRICS_DIR = _IA_ROOT / "artifacts" / "metrics"

_IV_DSS_PATH = _PROCESSED_DIR / "iv_dss_v1.jsonl"
_AUDIT_PATH = _AUDIT_DIR / "iv_dss_audit_v1.csv"
_REPORT_PATH = _METRICS_DIR / "iv_dss_report_v1.json"

DIMENSIONS = (
    "D_educacao",
    "D_trabalho",
    "D_saneamento",
    "D_acesso",
    "D_habitacao",
    "D_alimentacao",
)

_QUANTILES = (0.01, 0.05, 0.25, 0.50, 0.75, 0.95, 0.99)


def _series_stats(s: pd.Series) -> dict[str, Any]:
    """Estatísticas de uma série numérica com NaN = ausente."""
    valid = s.dropna()
    quantiles = {}
    if len(valid):
        for q in _QUANTILES:
            quantiles[f"p{int(q * 100):02d}"] = float(valid.quantile(q))
    return {
        "n_valid": int(valid.notna().sum()),
        "n_missing": int(s.isna().sum()),
        "mean": float(valid.mean()) if len(valid) else None,
        "sd": float(valid.std(ddof=1)) if len(valid) > 1 else None,
        "min": float(valid.min()) if len(valid) else None,
        "max": float(valid.max()) if len(valid) else None,
        "quantiles": quantiles,
    }


def _reason_counts(audit: pd.DataFrame, name: str) -> dict[str, int]:
    """Contagens de status (e razão agregada) por dimensão/componente."""
    status_col = f"{name}_status"
    reason_col = f"{name}_reason"
    out: dict[str, int] = {}
    if status_col in audit.columns:
        out["status"] = (
            audit[status_col].astype(str).value_counts().to_dict()
        )
    if reason_col in audit.columns:
        out["reason"] = (
            audit[reason_col].astype(str).value_counts().to_dict()
        )
    return out


def main() -> None:
    print("Lendo artefatos do IV-DSS v1...")
    df = pd.read_json(_IV_DSS_PATH, lines=True)
    audit = pd.read_csv(_AUDIT_PATH, dtype=str)
    n = int(len(df))
    print(f"  {n} linhas")

    # --- Dimensões ----------------------------------------------------------
    dimensions: dict[str, Any] = {}
    for name in DIMENSIONS:
        dimensions[name] = _series_stats(df[name])
        dimensions[name]["causes"] = _reason_counts(audit, name)

    # --- IV-DSS principal ---------------------------------------------------
    principal = _series_stats(df["iv_dss"])

    # --- Cobertura ----------------------------------------------------------
    coverage = df["iv_dss_coverage"]
    coverage_dist: dict[str, int] = {}
    for v in sorted(coverage.unique()):
        coverage_dist[f"{int(round(v * 6))}/6"] = int((coverage == v).sum())

    # --- Parcial (exatamente 5/6) -------------------------------------------
    n_parcial = int(df["iv_dss_parcial"].notna().sum())
    parcial = _series_stats(df["iv_dss_parcial"])

    # --- Sensibilidade: média generalizada p=2 ------------------------------
    generalized_p2 = _series_stats(df["iv_dss_generalized_p2"])

    # --- Sensibilidade binária de Habitação ---------------------------------
    housing_binary = _series_stats(df["D_habitacao_binary_sensitivity"])
    housing_binary_iv = _series_stats(df["iv_dss_housing_binary_sensitivity"])

    report = {
        "artifact": "iv_dss_v1",
        "n_samples": n,
        "n_principal_calculable": principal["n_valid"],
        "n_partial_calculable": n_parcial,
        "dimensions": dimensions,
        "iv_dss_principal": principal,
        "coverage_distribution": coverage_dist,
        "iv_dss_parcial": parcial,
        "iv_dss_generalized_p2": generalized_p2,
        "D_habitacao_binary_sensitivity": housing_binary,
        "iv_dss_housing_binary_sensitivity": housing_binary_iv,
    }

    _METRICS_DIR.mkdir(parents=True, exist_ok=True)
    with open(_REPORT_PATH, "w", encoding="utf-8") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)
    print(f"  escrito: {_REPORT_PATH}")

    # --- Resumo em console ---------------------------------------------------
    print("\nResumo do IV-DSS v1:")
    print(f"  N total                       = {n}")
    print(f"  IV-DSS principal (6/6)        = {principal['n_valid']} "
          f"({principal['n_valid'] / n:.2%})")
    print(f"  IV-DSS parcial (exatamente 5/6) = {n_parcial}")
    print(f"  IV-DSS média  (principal)     = {principal['mean']:.6f}")
    print(f"  IV-DSS desvio (principal)     = {principal['sd']:.6f}")
    print(f"  IV-DSS min/max (principal)    = {principal['min']:.4f} / {principal['max']:.4f}")
    print(f"  generalized p2 (6/6)          = média {generalized_p2['mean']:.6f}")
    print("\n  Cobertura (n_valid/6):")
    for k in sorted(coverage_dist, key=lambda x: int(x.split('/')[0])):
        print(f"    {k}: {coverage_dist[k]}")
    print("\n  Dimensões (N válido / média):")
    for name in DIMENSIONS:
        d = dimensions[name]
        print(f"    {name:12s} {d['n_valid']:5d}  média={d['mean']}")


if __name__ == "__main__":
    main()
