"""Inspeção legível dos artefatos da análise de sensibilidade metodológica (FASE 3G-B2).

Não recalcula nada; apenas LÊ os artefatos produzidos por
``run_methodological_sensitivity.py`` e imprime um resumo verificado, útil para a
revisão humana. Também confere a guarda anti-leakage do CSV de desfechos
sintéticos e a presença das 5 figuras.

Uso::

    python scripts/inspect_methodological_sensitivity.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import pandas as pd

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:  # pragma: no cover
    pass

_IA_ROOT = Path(__file__).resolve().parents[1]

_METRICS_JSON = _IA_ROOT / "artifacts" / "metrics" / "methodological_sensitivity_v1.json"
_FEATURE_CSV = _IA_ROOT / "artifacts" / "metrics" / "feature_set_sensitivity_v1.csv"
_OUTCOME_CSV = _IA_ROOT / "artifacts" / "metrics" / "outcome_rate_sensitivity_v1.csv"
_OOF_X_SENS = _IA_ROOT / "data" / "processed" / "cv_oof_predictions_x_sens_v1.csv"
_OUTCOMES = _IA_ROOT / "data" / "processed" / "sensitivity_outcomes_v1.csv"
_FIGURES_DIR = _IA_ROOT / "artifacts" / "figures"

_FIGURES = (
    "feature_set_sensitivity_metrics_v1.png",
    "feature_set_sensitivity_threshold_metrics_v1.png",
    "outcome_rate_sensitivity_auc_v1.png",
    "outcome_rate_sensitivity_brier_v1.png",
    "outcome_rate_sensitivity_threshold_v1.png",
)

_FORBIDDEN = ("U_sens", "V_sens", "p_true", "linear_component", "alpha")


def _load_json(path: Path) -> dict[str, Any]:
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def _divider(title: str) -> None:
    print("\n" + "=" * 78)
    print(title)
    print("=" * 78)


def main() -> None:
    report = _load_json(_METRICS_JSON)
    print(f"Análise: {report['analysis_type']}  versão={report['analysis_version']}  "
          f"modelo={report['model']}  n={report['n_expected']}  folds={report['n_folds']}")
    print(f"fonte={report['evaluation_source']}  threshold={report['threshold_reference']}")

    _divider("GUARDAS (decisões proibidas / anti-leakage)")
    for k, v in report["guards"].items():
        print(f"  {k:36s} = {v}")

    _divider("TRILHA B2A — sensibilidade ao conjunto de variáveis")
    fs = report["feature_set_track"]
    print(f"  baseline={fs['baseline']}  sensibilidade={fs['sensitivity']}")
    print(f"  variáveis adicionadas={fs['invariant_added']}  subconjunto={fs['invariant_subset']}")
    print("  delta (sensibilidade − baseline) por métrica [mean ± std | min, max]:")
    for k, s in fs["deltas"]["summary"].items():
        print(f"    {k:18s} {s['mean']:+.6f} ± {s['std']:.6f}  "
              f"[{s['min']:+.6f}, {s['max']:+.6f}]")

    _divider("TRILHA B2B — sensibilidade à taxa média de probabilidade simulada")
    ob = report["outcome_base_rate_track"]
    print(f"  seeds: noise={ob['noise_seed']}  outcome={ob['outcome_seed']}  noise_sd={ob['noise_sd']}")
    print(f"  monotonicidade: {ob['monotonicity']}")
    for name, sc in ob["scenarios"].items():
        pm = sc["pooled_metrics"]
        print(f"\n  [{name}]")
        print(f"    alvo={sc['target_mean_probability']:.2f}  "
              f"alpha={sc['alpha']:.6f}  "
              f"mean(p)={sc['achieved_mean_probability']:.10f}  "
              f"prevalência realizada={sc['realized_prevalence']:.4f}")
        print(f"    p_true range=[{sc['p_true_min']:.6f}, {sc['p_true_max']:.6f}]  "
              f"mean={sc['p_true_mean']:.6f}")
        print(f"    pooled: prevalence={pm['prevalence']:.4f}  "
              f"roc_auc={pm['roc_auc']:.4f}  pr_auc={pm['pr_auc']:.4f}  "
              f"brier={pm['brier']:.4f}  baseline_brier={pm['baseline_brier']:.4f}")
        print(f"      pr_auc−prev={pm['pr_auc_minus_prevalence']:+.4f}  "
              f"pr_auc/prev={pm['pr_auc_over_prevalence']:.4f}  "
              f"rel_brier={pm['relative_brier_improvement']:+.4f}")

    _divider("ARTEFATOS (CSVs + figuras)")
    oof = pd.read_csv(_OOF_X_SENS)
    print(f"  {_OOF_X_SENS.name}: {len(oof)} linhas  colunas={list(oof.columns)}")
    outcomes = pd.read_csv(_OUTCOMES)
    print(f"  {_OUTCOMES.name}: {len(outcomes)} linhas  colunas={list(outcomes.columns)}")
    leaked = [c for c in _FORBIDDEN if c in outcomes.columns]
    print(f"  anti-leakage do CSV de desfechos: {'OK (sem colunas proibidas)' if not leaked else f'VAZAMENTO {leaked}'}")

    feat = pd.read_csv(_FEATURE_CSV)
    print(f"  {_FEATURE_CSV.name}: {len(feat)} linhas  colunas={list(feat.columns)}")
    out = pd.read_csv(_OUTCOME_CSV)
    print(f"  {_OUTCOME_CSV.name}: {len(out)} linhas  colunas={list(out.columns)}")

    missing = [f for f in _FIGURES if not (_FIGURES_DIR / f).exists()]
    for f in _FIGURES:
        mark = "OK" if (_FIGURES_DIR / f).exists() else "FALTA"
        print(f"  figura {f:52s} [{mark}]")
    if missing:
        print(f"  [ERRO] figuras ausentes: {missing}")
        sys.exit(1)

    _divider("FIM")
    print("Inspeção concluída. Nenhum cálculo realizado; artefatos apenas lidos.")


if __name__ == "__main__":
    main()
