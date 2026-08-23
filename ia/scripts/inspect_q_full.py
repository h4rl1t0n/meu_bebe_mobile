"""Diagnóstico da população sintética de Q_full.

Lê ``data/raw/q_full_v1.jsonl`` + ``data/audit/q_full_generation_audit_v1.csv``
e produz ``artifacts/metrics/q_full_generation_report_v1.json`` com:

* frequência/porcentagem de cada categoria;
* true/false dos booleanos e nulls por campo;
* frequência das opções de multiselect;
* estatísticas de número de pessoas/cômodos/dormitórios e adensamento observado
  (APENAS diagnóstico, sem implementar IV-DSS);
* proporções relevantes e matriz de correlação amostral dos Z_*.

As frequências NÃO são prevalências — são resultados experimentais condicionados
aos fatores latentes Z.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd

from meu_bebe_ml.schema.validator import load_schema

_IA_ROOT = Path(__file__).resolve().parents[1]

_Q_FULL_PATH = _IA_ROOT / "data" / "raw" / "q_full_v1.jsonl"
_AUDIT_PATH = _IA_ROOT / "data" / "audit" / "q_full_generation_audit_v1.csv"
_REPORT_PATH = _IA_ROOT / "artifacts" / "metrics" / "q_full_generation_report_v1.json"


def _pct(count: int, total: int) -> float:
    return round(100.0 * count / total, 2) if total else 0.0


def _distribution(series: pd.Series, total: int) -> dict[str, dict[str, float]]:
    counts = series.value_counts(dropna=False)
    return {
        str(k): {"count": int(v), "pct": _pct(int(v), total)}
        for k, v in counts.items()
    }


def _bool_distribution(series: pd.Series, total: int) -> dict[str, dict[str, float]]:
    """Distribuição booleana com chaves semânticas ``true``/``false``/``null``.

    ``pd.read_json`` lê colunas ``bool?`` com null como ``float64``
    (``True→1.0``, ``False→0.0``, ``null→NaN``). Normaliza as chaves para a
    semântica do contrato SEM tocar em ``q_full_v1.jsonl`` (cujos dados já
    estão corretos).
    """

    def _norm(v: Any) -> str:
        if pd.isna(v):
            return "null"
        return "true" if bool(v) else "false"

    counts = series.map(_norm).value_counts()
    return {
        k: {"count": int(counts.get(k, 0)), "pct": _pct(int(counts.get(k, 0)), total)}
        for k in ("true", "false", "null")
        if k in counts.index
    }


def main() -> None:
    spec = load_schema()
    records = pd.read_json(_Q_FULL_PATH, lines=True)
    audit = pd.read_csv(_AUDIT_PATH)
    total = len(records)

    report: dict[str, Any] = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "n_records": total,
    }

    # --- Categóricas e booleanas -------------------------------------------
    categoricals: dict[str, Any] = {}
    booleans: dict[str, Any] = {}
    nulls: dict[str, int] = {}
    for name, var in spec.variables.items():
        series = records[name]
        null_count = int(series.isna().sum())
        if var["type"] == "categorical":
            categoricals[name] = _distribution(series, total)
        elif var["type"] == "bool":
            booleans[name] = _bool_distribution(series, total)
        if null_count:
            nulls[name] = null_count
    report["categoricals"] = categoricals
    report["booleans"] = booleans
    report["nulls_by_field"] = nulls

    # --- Multiselects -------------------------------------------------------
    multiselects: dict[str, Any] = {}
    for name, var in spec.variables.items():
        if var["type"] != "multiselect":
            continue
        exploded = records[name].explode().dropna()
        counts = exploded.value_counts()
        multiselects[name] = {
            str(k): int(v) for k, v in counts.items()
        }
    report["multiselects"] = multiselects

    # --- Estatísticas habitacionais e adensamento (diagnóstico) --------------
    def _stats(col: str) -> dict[str, float]:
        s = records[col]
        return {
            "mean": round(float(s.mean()), 3),
            "std": round(float(s.std()), 3),
            "min": int(s.min()),
            "max": int(s.max()),
        }

    dens_dorm = records["numero_pessoas"] / records["numero_dormitorios"]
    dens_comodo = records["numero_pessoas"] / records["numero_comodos"]
    report["housing_stats"] = {
        "numero_pessoas": _stats("numero_pessoas"),
        "numero_comodos": _stats("numero_comodos"),
        "numero_dormitorios": _stats("numero_dormitorios"),
        "adensamento_pessoas_por_dormitorio": {
            "mean": round(float(dens_dorm.mean()), 3),
            "median": round(float(dens_dorm.median()), 3),
            "max": round(float(dens_dorm.max()), 3),
        },
        "adensamento_pessoas_por_comodo": {
            "mean": round(float(dens_comodo.mean()), 3),
            "median": round(float(dens_comodo.median()), 3),
            "max": round(float(dens_comodo.max()), 3),
        },
    }

    # --- Proporções relevantes ---------------------------------------------
    report["faixa_renda_nao_informar_rate"] = round(
        float((records["faixa_renda"] == "nao_informar").mean()), 4
    )
    report["empregado_true_rate"] = round(float(records["empregado"].mean()), 4)
    report["distancia_ubs_distribution"] = _distribution(
        records["distancia_ubs"], total
    )
    report["deixou_de_comer_falta_dinheiro_rate"] = round(
        float(records["deixou_de_comer_falta_dinheiro"].mean()), 4
    )

    # --- Dificuldades de saúde (proporção de registros com cada uma) ---------
    difficulties = [
        "dificuldade_agendamento",
        "demora_atendimento",
        "distancia",
        "falta_transporte",
        "horario_incompativel",
        "falta_profissional",
        "falta_exames",
        "outro",
    ]
    report["dificuldades_saude_rates"] = {
        d: round(float(records["dificuldades_saude"].apply(lambda x: d in x).mean()), 4)
        for d in difficulties
    }

    # --- Correlação amostral dos cinco Z_* -----------------------------------
    z_cols = ["Z_SES", "Z_LAB", "Z_TERR", "Z_INFRA", "Z_SERV"]
    z_corr = audit[z_cols].corr().round(4)
    report["z_correlation_sample"] = {
        "columns": z_cols,
        "matrix": z_corr.values.tolist(),
    }

    _REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(_REPORT_PATH, "w", encoding="utf-8") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)
    print(f"Relatório escrito em: {_REPORT_PATH}")

    # Resumo breve no console
    print(f"\nRegistros: {total}")
    print(f"nao_informar: {report['faixa_renda_nao_informar_rate']:.2%}")
    print(f"empregado=true: {report['empregado_true_rate']:.2%}")
    print(f"deixou_de_comer: {report['deixou_de_comer_falta_dinheiro_rate']:.2%}")
    print(f"nulls por campo: {nulls or 'nenhum'}")
    print("Correlação Z amostral:")
    print(z_corr.to_string())


if __name__ == "__main__":
    main()
