"""Diagnóstico da geração do desfecho sintético Y (FASE 3C).

Lê ``data/audit/dgm_audit_v1.csv`` (e o audit da FASE 3B para os Z_*) e produz
``artifacts/metrics/dgm_report_v1.json`` com:

* alpha, distribuições de linear/U/eta/p_true, quantis de p_true;
* contagem e proporção de Y=1 / Y=0;
* frequência dos g_* e das interações;
* correlação dos g_* entre si e com p_true;
* distribuição de p_true por Y=0/Y=1 (apenas diagnóstico).

As correlações NÃO são efeitos epidemiológicos: são resultados experimentais
condicionados ao DGM sintético.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd

from meu_bebe_ml.simulation import G_FACTOR_NAMES, INTERACTION_NAMES

_IA_ROOT = Path(__file__).resolve().parents[1]

_DGM_AUDIT_PATH = _IA_ROOT / "data" / "audit" / "dgm_audit_v1.csv"
_Q_FULL_AUDIT_PATH = _IA_ROOT / "data" / "audit" / "q_full_generation_audit_v1.csv"
_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "dgm_v1_manifest.json"
_REPORT_PATH = _IA_ROOT / "artifacts" / "metrics" / "dgm_report_v1.json"

_QUANTILES = (0.01, 0.05, 0.25, 0.50, 0.75, 0.95, 0.99)


def _freqs(series: pd.Series) -> dict[str, int]:
    return {str(k): int(v) for k, v in series.value_counts(dropna=False).items()}


def _stats(series: pd.Series) -> dict[str, float]:
    return {
        "mean": round(float(series.mean()), 6),
        "sd": round(float(series.std()), 6),
        "min": round(float(series.min()), 6),
        "max": round(float(series.max()), 6),
    }


def main() -> None:
    audit = pd.read_csv(_DGM_AUDIT_PATH)
    n = len(audit)

    # alpha é metadado global (não é coluna por linha): vem do manifest.
    with open(_MANIFEST_PATH, "r", encoding="utf-8") as fh:
        manifest = json.load(fh)

    p_true = audit["p_true"].to_numpy(dtype=float)
    Y = audit["Y"].to_numpy(dtype=int)

    report: dict[str, Any] = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "n_records": n,
        "alpha": manifest.get("alpha"),
    }

    report["linear_component"] = _stats(audit["linear_component"])
    report["U"] = _stats(audit["U"])
    report["eta"] = _stats(audit["eta"])
    report["p_true"] = _stats(pd.Series(p_true))
    report["p_true_quantiles"] = {
        f"{int(q * 100):02d}%": round(float(np.quantile(p_true, q)), 6)
        for q in _QUANTILES
    }

    pos_count = int(Y.sum())
    report["Y"] = {
        "count_0": int(n - pos_count),
        "count_1": pos_count,
        "rate_1": round(pos_count / n, 6),
    }

    report["g_frequencies"] = {name: _freqs(audit[name]) for name in G_FACTOR_NAMES}
    report["interaction_frequencies"] = {
        name: _freqs(audit[name]) for name in INTERACTION_NAMES
    }

    # Correlação dos g_* entre si.
    g_corr = audit[list(G_FACTOR_NAMES)].corr().round(4)
    report["g_correlation_matrix"] = {
        "columns": list(G_FACTOR_NAMES),
        "matrix": g_corr.values.tolist(),
    }

    # Correlação de cada g_* com p_true.
    report["g_correlation_with_p_true"] = {
        name: round(float(audit[name].corr(pd.Series(p_true))), 4)
        for name in G_FACTOR_NAMES
    }

    # p_true por Y=0/Y=1 (diagnóstico apenas).
    report["p_true_by_Y"] = {
        "Y=0": _stats(pd.Series(p_true[Y == 0])),
        "Y=1": _stats(pd.Series(p_true[Y == 1])),
    }

    # Correlação entre U e Z_* (Z_* no audit da FASE 3B).
    try:
        qfull_audit = pd.read_csv(_Q_FULL_AUDIT_PATH).sort_values("row_index")
        z_cols = ["Z_SES", "Z_LAB", "Z_TERR", "Z_INFRA", "Z_SERV"]
        report["U_vs_Z_correlation"] = {
            z: round(float(audit["U"].corr(qfull_audit[z].reset_index(drop=True))), 4)
            for z in z_cols
        }
    except Exception as exc:  # pragma: no cover - reporta e segue
        report["U_vs_Z_correlation"] = {"error": str(exc)}

    _REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(_REPORT_PATH, "w", encoding="utf-8") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)
    print(f"Relatório escrito em: {_REPORT_PATH}")

    print(f"\nRegistros: {n}")
    print(f"mean(p_true): {report['p_true']['mean']}")
    print(f"Y=1: {pos_count} ({pos_count / n:.2%})  |  Y=0: {n - pos_count}")
    print(f"U: mean={report['U']['mean']}, sd={report['U']['sd']}")
    print("Correlação g_* com p_true:")
    for k, v in report["g_correlation_with_p_true"].items():
        print(f"  {k}: {v}")


if __name__ == "__main__":
    main()
