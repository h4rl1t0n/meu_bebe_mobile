"""Inspeção legível dos artefatos da interpretabilidade pós-hoc (FASE 3H).

NÃO recalcula nada; apenas LÊ os artefatos produzidos por
``run_interpretability_analysis.py`` e imprime um resumo verificado, útil para a
revisão humana. Confere as invariantes de guarda (TEST não usado, nenhuma
seleção/recalibração/tuning, reprodução OOF dentro da tolerância) e a presença
dos CSVs e das 4 figuras.

Uso::

    python scripts/inspect_interpretability.py
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

_METRICS_JSON = _IA_ROOT / "artifacts" / "metrics" / "interpretability_v1.json"
_REPEATS_CSV = _IA_ROOT / "artifacts" / "metrics" / "permutation_importance_repeats_v1.csv"
_FEATURES_CSV = _IA_ROOT / "artifacts" / "metrics" / "permutation_importance_features_v1.csv"
_GROUPS_CSV = _IA_ROOT / "artifacts" / "metrics" / "permutation_importance_groups_v1.csv"
_FIGURES_DIR = _IA_ROOT / "artifacts" / "figures"

_FIGURES = (
    "permutation_importance_pr_auc_top15_v1.png",
    "permutation_importance_by_fold_v1.png",
    "permutation_importance_dgm_context_v1.png",
    "permutation_importance_structural_groups_v1.png",
)

_TOL = 1e-12


def _load_json(path: Path) -> dict[str, Any]:
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def _divider(title: str) -> None:
    print("\n" + "=" * 78)
    print(title)
    print("=" * 78)


def main() -> None:
    report = _load_json(_METRICS_JSON)
    md = report["metadata"]
    print(f"Análise: {md['analysis_type']}  versão={md['analysis_version']}  "
          f"modelo={md['model']}")
    print(f"feature_set={md['feature_set']}  fonte={md['source']}  n={md['n']}  "
          f"folds={md['folds']}  repeats={md['repeats']}  seed={md['permutation_seed']}")
    print(f"métrica primária={md['primary_metric']}")

    _divider("GUARDAS (decisões proibidas)")
    for k, v in report["guards"].items():
        print(f"  {k:36s} = {v}")

    _divider("REPRODUÇÃO OOF (baseline)")
    br = report["baseline_reproduction"]
    print(f"  max |prob reconstruída − OOF congelada| = {br['max_probability_difference']:.3e}  "
          f"(tolerância {br['tolerance']})")
    ok = br["max_probability_difference"] <= _TOL
    print(f"  dentro da tolerância: {'SIM' if ok else 'NÃO (PARE)'}")
    print(f"  mean-fold PR-AUC   = {br['mean_fold_metrics']['pr_auc']:.6f}")
    print(f"  pooled OOF PR-AUC  = {br['pooled_oof_metrics']['pr_auc']:.6f}")
    print(f"  mean-fold ROC-AUC  = {br['mean_fold_metrics']['roc_auc']:.6f}")
    print(f"  pooled OOF ROC-AUC = {br['pooled_oof_metrics']['roc_auc']:.6f}")
    print(f"  OOF Brier          = {br['pooled_oof_metrics']['brier']:.6f}")
    for row in br["per_fold_metrics"]:
        print(f"    fold {row['fold']}: n={row['n']}  pr_auc={row['pr_auc']:.6f}  "
              f"roc_auc={row['roc_auc']:.6f}  brier={row['brier']:.6f}")

    _divider("RANKING (importância preditiva — mean delta PR-AUC)")
    ranking = report["feature_importance"]["ranking"]
    summaries = {s["feature"]: s for s in report["feature_importance"]["feature_summaries"]}
    for rank, feat in enumerate(ranking, start=1):
        s = summaries[feat]
        dgm = "*" if s["is_direct_dgm_input"] else " "
        print(f"  {rank:2d}. {feat:32s} {s['mean_delta_pr_auc']:+.6f} ± "
              f"{s['std_fold_delta_pr_auc']:.6f}  {dgm}")

    _divider("CONTEXTO DOS INPUTS DIRETOS DO DGM")
    dc = report["dgm_context"]
    print(f"  inputs diretos ({len(dc['direct_raw_inputs'])}): "
          f"{', '.join(dc['direct_raw_inputs'])}")
    print(f"  top-5 overlap  = {dc['top5_overlap']}")
    print(f"  top-10 overlap = {dc['top10_overlap']}")
    print(f"  posições: {dc['positions']}")

    _divider("GRUPOS ESTRUTURAIS (permutação conjunta)")
    for g in report["structural_group_sensitivity"]["summaries"]:
        print(f"  {g['group']:18s} members={g['members']}")
        print(f"      mean delta PR-AUC = {g['mean_delta_pr_auc']:+.6f} ± "
              f"{g['std_fold_delta_pr_auc']:.6f}")

    _divider("ARTEFATOS (CSVs + figuras)")
    repeats = pd.read_csv(_REPEATS_CSV)
    feat = pd.read_csv(_FEATURES_CSV)
    groups = pd.read_csv(_GROUPS_CSV)
    print(f"  {_REPEATS_CSV.name}: {len(repeats)} linhas  colunas={len(repeats.columns)}")
    print(f"      (esperado: 3400 = 34 × 5 × 20)")
    print(f"  {_FEATURES_CSV.name}: {len(feat)} linhas  colunas={len(feat.columns)}")
    print(f"  {_GROUPS_CSV.name}: {len(groups)} linhas  colunas={len(groups.columns)}")

    has_nan = bool(repeats.isna().any().any()) or bool(feat.isna().any().any())
    print(f"  NaN/ausente nos CSVs: {'PRESENTE (invariante violada)' if has_nan else 'nenhum'}")

    missing = [f for f in _FIGURES if not (_FIGURES_DIR / f).exists()]
    for f in _FIGURES:
        mark = "OK" if (_FIGURES_DIR / f).exists() else "FALTA"
        print(f"  figura {f:52s} [{mark}]")
    if missing:
        print(f"  [ERRO] figuras ausentes: {missing}")
        sys.exit(1)

    _divider("LIMITAÇÕES")
    for k, v in report["limitations"].items():
        print(f"  [{k}] {v}")

    _divider("FIM")
    print("Inspeção concluída. Nenhum cálculo realizado; artefatos apenas lidos.")


if __name__ == "__main__":
    main()
