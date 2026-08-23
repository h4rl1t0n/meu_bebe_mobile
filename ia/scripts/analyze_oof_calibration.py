"""Análise secundária diagnóstica de calibração e estabilidade — FASE 3G-B1.

Usa EXCLUSIVAMENTE as predições out-of-fold do TREINAMENTO
(``data/processed/cv_oof_predictions_v1.csv``, 4000 registros; somente
``row_index``, ``validation_fold``, ``y_true`` e ``random_forest_probability``)
para caracterizar descritivamente a calibração e a estabilidade das
probabilidades do Random Forest selecionado.

Este script NÃO:
  * abre o TEST nem o arquivo de predições do TEST;
  * recalibra (Platt / isotonic / CalibratedClassifierCV);
  * treina, retreina, ajusta hiperparâmetro nem seleciona threshold;
  * gera modelo recalibrado.

Saídas:
  * ``artifacts/metrics/oof_calibration_bins_v1.csv``     (bins global + por fold)
  * ``artifacts/metrics/calibration_stability_v1.json``   (resumo + hashes)
  * ``artifacts/figures/oof_calibration_*_v1.png`` e afins (5 figuras)

Uso::

    python scripts/analyze_oof_calibration.py
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

try:  # garantir saída UTF-8 em terminais Windows
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:  # pragma: no cover
    pass

from meu_bebe_ml.evaluation import (
    calibration_bins,
    load_calibration_config,
    summarize_calibration,
)
from meu_bebe_ml.training import load_frozen_split, sha256_file
from meu_bebe_ml.evaluation.threshold_analysis import validate_oof_train_only

_IA_ROOT = Path(__file__).resolve().parents[1]
_CONFIG_PATH = _IA_ROOT / "configs" / "calibration_stability_v1.yaml"
_OOF_PATH = _IA_ROOT / "data" / "processed" / "cv_oof_predictions_v1.csv"
_SPLIT_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1.csv"
_FOLDS_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1.csv"

_OUT_CSV = _IA_ROOT / "artifacts" / "metrics" / "oof_calibration_bins_v1.csv"
_OUT_JSON = _IA_ROOT / "artifacts" / "metrics" / "calibration_stability_v1.json"
_FIGURES_DIR = _IA_ROOT / "artifacts" / "figures"

_PROB_COL = "random_forest_probability"

_CSV_COLUMNS = [
    "scope", "fold", "bin_index", "n", "min_probability", "max_probability",
    "mean_predicted_probability", "fraction_of_positives", "calibration_gap",
    "absolute_calibration_gap",
]


def _validate_oof(oof: pd.DataFrame, train_idx: np.ndarray, test_idx: np.ndarray) -> None:
    """Validações da seção 5 sobre o OOF (N=4000, único, só TRAIN, binário, folds)."""
    print("\n[validação do OOF]")
    n_expected = 4000
    if len(oof) != n_expected:
        raise ValueError(f"OOF tem {len(oof)} linhas; esperado {n_expected}")
    if len(oof) != oof["row_index"].nunique():
        raise ValueError("OOF contém row_index duplicado")

    row_index = oof["row_index"].to_numpy(dtype=np.int64)
    validate_oof_train_only(row_index, train_idx, test_idx)
    if set(row_index.tolist()) != set(train_idx.tolist()):
        raise ValueError("OOF não cobre exatamente o TRAIN congelado")

    folds = oof["validation_fold"].to_numpy(dtype=np.int64)
    if set(folds.tolist()) != {0, 1, 2, 3, 4}:
        raise ValueError(f"validation_fold inesperado: {sorted(set(folds.tolist()))!r}")
    if len(oof) != oof.groupby("validation_fold").size().sum():
        raise ValueError("registros por fold inconsistentes")

    y = oof["y_true"]
    if not set(y.unique()) <= {0, 1} or y.isna().any():
        raise ValueError("y_true inválido (não binário ou com ausentes)")

    p = oof[_PROB_COL]
    if p.isna().any():
        raise ValueError(f"{_PROB_COL} contém NaN")
    pv = p.to_numpy()
    if np.any(~np.isfinite(pv)) or np.any(pv < 0.0) or np.any(pv > 1.0):
        raise ValueError(f"{_PROB_COL} deve ser finito e em [0, 1]")

    y0 = int((y == 0).sum())
    y1 = int((y == 1).sum())
    if (y0, y1) != (3023, 977):
        raise ValueError(f"prevalência divergente: y0={y0}, y1={y1} != (3023, 977)")

    print(f"  N={len(oof)}  row_index únicos=4000  só TRAIN=OK  sem TEST=OK")
    print(f"  y0={y0}  y1={y1}  folds={sorted(set(folds.tolist()))}  probs finitas em [0,1]=OK")


def _library_versions() -> dict[str, str]:
    import sklearn

    return {
        "python": sys.version.split()[0],
        "numpy": np.__version__,
        "pandas": pd.__version__,
        "scikit-learn": sklearn.__version__,
    }


# ---------------------------------------------------------------------------
# Figuras
# ---------------------------------------------------------------------------

def _diagonal(ax) -> None:
    lims = [0.0, 1.0]
    ax.plot(lims, lims, "k--", linewidth=1, label="diagonal (calibração perfeita)")
    ax.set_xlim(lims)
    ax.set_ylim(lims)


def _fig_calibration_global(summary) -> None:
    bins = summary["global"]["calibration_bins"]
    x = [b["mean_predicted_probability"] for b in bins]
    y = [b["fraction_of_positives"] for b in bins]
    fig, ax = plt.subplots(figsize=(7, 7))
    ax.plot(x, y, "o-", linewidth=1.4, color="C0")
    _diagonal(ax)
    ax.set_xlabel("mean predicted probability")
    ax.set_ylabel("fraction of positives")
    ax.set_title("Reliability diagram global — OOF TREINAMENTO (10 bins)")
    ax.grid(True, alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "oof_calibration_global_v1.png", dpi=150)
    plt.close(fig)


def _fig_calibration_by_fold(summary) -> None:
    fig, ax = plt.subplots(figsize=(7, 7))
    _diagonal(ax)
    for row in summary["per_fold"]:
        bins = row["calibration_bins"]
        x = [b["mean_predicted_probability"] for b in bins]
        y = [b["fraction_of_positives"] for b in bins]
        ax.plot(x, y, "o-", linewidth=1.2, label=f"fold {row['fold']}")
    ax.set_xlabel("mean predicted probability")
    ax.set_ylabel("fraction of positives")
    ax.set_title("Calibração por fold — OOF TREINAMENTO (5 bins/fold)")
    ax.grid(True, alpha=0.3)
    ax.legend(fontsize=8)
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "oof_calibration_by_fold_v1.png", dpi=150)
    plt.close(fig)


def _fig_brier_by_fold(summary) -> None:
    folds = [r["fold"] for r in summary["per_fold"]]
    brier = [r["brier"] for r in summary["per_fold"]]
    baseline = [r["baseline_brier"] for r in summary["per_fold"]]
    x = np.arange(len(folds))
    width = 0.35
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.bar(x - width / 2, brier, width, label="Brier Random Forest")
    ax.bar(x + width / 2, baseline, width, label="Brier baseline constante")
    ax.set_xticks(x)
    ax.set_xticklabels([f"{f}" for f in folds])
    ax.set_xlabel("fold")
    ax.set_ylabel("Brier score")
    ax.set_title("Brier por fold — RF vs baseline constante (OOF TREINAMENTO)")
    ax.legend()
    ax.grid(True, alpha=0.3, axis="y")
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "oof_brier_by_fold_v1.png", dpi=150)
    plt.close(fig)


def _fig_distribution_by_class(oof: pd.DataFrame) -> None:
    y = oof["y_true"].to_numpy()
    p = oof[_PROB_COL].to_numpy()
    fig, ax = plt.subplots(figsize=(8, 5))
    bins = np.linspace(0.0, 1.0, 41)
    ax.hist(p[y == 0], bins=bins, alpha=0.55, label="y_true=0", density=True, color="C0")
    ax.hist(p[y == 1], bins=bins, alpha=0.55, label="y_true=1", density=True, color="C1")
    ax.set_xlabel("random_forest_probability")
    ax.set_ylabel("densidade")
    ax.set_title("Distribuição das probabilidades OOF por classe (cenário sintético)")
    ax.legend()
    ax.grid(True, alpha=0.3)
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "oof_probability_distribution_by_class_v1.png", dpi=150)
    plt.close(fig)


def _fig_probability_by_fold(oof: pd.DataFrame) -> None:
    folds = sorted(oof["validation_fold"].unique())
    means = [oof.loc[oof["validation_fold"] == f, _PROB_COL].mean() for f in folds]
    stds = [oof.loc[oof["validation_fold"] == f, _PROB_COL].std(ddof=1) for f in folds]
    global_mean = oof[_PROB_COL].mean()
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.bar([str(f) for f in folds], means, yerr=stds, capsize=5, color="C0")
    ax.axhline(global_mean, color="C1", linestyle="--", linewidth=1,
               label=f"média global ({global_mean:.4f})")
    ax.set_xlabel("fold")
    ax.set_ylabel("mean probability (±std)")
    ax.set_title("Probabilidade média por fold — OOF TREINAMENTO")
    ax.legend()
    ax.grid(True, alpha=0.3, axis="y")
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "oof_probability_by_fold_v1.png", dpi=150)
    plt.close(fig)


def _build_bins_csv(summary) -> pd.DataFrame:
    rows = []
    for b in summary["global"]["calibration_bins"]:
        rows.append({"scope": "global", "fold": "", **b})
    for fr in summary["per_fold"]:
        for b in fr["calibration_bins"]:
            rows.append({"scope": "fold", "fold": str(fr["fold"]), **b})
    return pd.DataFrame(rows)[_CSV_COLUMNS]


def main() -> None:
    print("=" * 72)
    print("FASE 3G-B1 — CALIBRAÇÃO E ESTABILIDADE DAS PROBABILIDADES OOF (diagnóstico)")
    print("=" * 72)

    config = load_calibration_config(_CONFIG_PATH)
    print(f"\n[config] model={config.model}  source={config.source}  "
          f"n_bins={config.n_bins} ({config.strategy})  "
          f"recalibration={config.recalibration_enabled}  test_usage={config.test_usage_allowed}")

    # 1. Hashes dos insumos congelados
    input_hashes = {
        "cv_oof_predictions_v1.csv": sha256_file(_OOF_PATH),
        "train_test_split_v1.csv": sha256_file(_SPLIT_PATH),
        "cv_folds_v1.csv": sha256_file(_FOLDS_PATH),
        "calibration_stability_v1.yaml": sha256_file(_CONFIG_PATH),
    }
    print("\n[hashes dos insumos]")
    for name, h in input_hashes.items():
        print(f"  {name}: {h}")

    # 2. Split congelado + OOF (somente TRAIN)
    train_idx, test_idx = load_frozen_split(_SPLIT_PATH)
    oof = pd.read_csv(_OOF_PATH)
    _validate_oof(oof, train_idx, test_idx)

    y = oof["y_true"].to_numpy()
    p = oof[_PROB_COL].to_numpy()
    folds = oof["validation_fold"].to_numpy(dtype=np.int64)

    # 3. Resumo determinístico (calibração global, Brier, folds, estabilidade)
    summary = summarize_calibration(config, folds, y, p)

    # 4. CSV de bins (seção 23)
    _OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    bins_df = _build_bins_csv(summary)
    bins_df.to_csv(_OUT_CSV, index=False)
    print(f"\n[csv] {_OUT_CSV.name} ({len(bins_df)} linhas: "
          f"{len(summary['global']['calibration_bins'])} global + "
          f"{sum(len(fr['calibration_bins']) for fr in summary['per_fold'])} fold)")

    # 5. JSON (seção 24)
    summary["input_hashes"] = input_hashes
    summary["versions"] = _library_versions()
    summary["timestamp"] = datetime.now(timezone.utc).isoformat()

    _OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    with open(_OUT_JSON, "w", encoding="utf-8") as fh:
        json.dump(summary, fh, ensure_ascii=False, indent=2)
    print(f"[json] {_OUT_JSON.name}")

    # 6. Resumo impresso
    g = summary["global"]
    citl = summary["calibration_in_the_large"]
    print("\n[resumo global OOF]")
    print(f"  N={summary['n']}  y0={summary['y0']}  y1={summary['y1']}  "
          f"positive_rate={summary['observed_positive_rate']:.6f}")
    print(f"  probability: mean={summary['probability']['mean_probability']:.6f}  "
          f"std={summary['probability']['std_probability']:.6f}  "
          f"min={summary['probability']['min_probability']:.4f}  "
          f"max={summary['probability']['max_probability']:.4f}")
    print(f"  mean predicted = {citl['mean_predicted_probability']:.6f}  "
          f"observed rate = {citl['observed_positive_rate']:.6f}  "
          f"diff = {citl['calibration_in_the_large_difference']:.6f}")
    print(f"  Brier = {g['brier']:.6f}  baseline = {g['baseline_brier']:.6f}  "
          f"diff = {g['brier_difference']:.6f}  rel.improv = {g['brier_relative_improvement']:.6f}")
    print(f"  mean fold ROC-AUC = {g['mean_fold_roc_auc']:.6f}  "
          f"mean fold PR-AUC = {g['mean_fold_pr_auc']:.6f}")
    print(f"  pooled OOF ROC-AUC = {g['pooled_oof_roc_auc']:.6f}  "
          f"pooled OOF PR-AUC = {g['pooled_oof_pr_auc']:.6f}")
    print(f"  mean_abs_bin_gap = {g['mean_absolute_bin_gap']:.6f}  "
          f"weighted = {g['weighted_mean_absolute_bin_gap']:.6f}")

    print("\n[bins globais (10)]")
    print("  bin | n    | mean pred | frac pos | gap")
    for b in g["calibration_bins"]:
        print(f"  {b['bin_index']:3d} | {b['n']:4d} | {b['mean_predicted_probability']:.4f} | "
              f"{b['fraction_of_positives']:.4f} | {b['calibration_gap']:+.4f}")

    print("\n[por fold]")
    print("  fold | n   | prev  | mean p | Brier | base Brier | ROC-AUC | PR-AUC | diff")
    for r in summary["per_fold"]:
        print(f"  {r['fold']:4d} | {r['n']:4d} | {r['observed_positive_rate']:.4f} | "
              f"{r['mean_probability']:.4f} | {r['brier']:.4f} | {r['baseline_brier']:.4f} | "
              f"{r['roc_auc']:.4f} | {r['pr_auc']:.4f} | {r['calibration_in_the_large_difference']:+.4f}")

    print(f"\n[flags] recalibration_performed={summary['recalibration_performed']}  "
          f"test_used={summary['test_used']}  model_modified={summary['model_modified']}")

    # 7. Figuras (seções 18–22)
    _FIGURES_DIR.mkdir(parents=True, exist_ok=True)
    _fig_calibration_global(summary)
    _fig_calibration_by_fold(summary)
    _fig_brier_by_fold(summary)
    _fig_distribution_by_class(oof)
    _fig_probability_by_fold(oof)
    print("\n[figuras] geradas em artifacts/figures/:")
    for name in (
        "oof_calibration_global_v1.png",
        "oof_calibration_by_fold_v1.png",
        "oof_brier_by_fold_v1.png",
        "oof_probability_distribution_by_class_v1.png",
        "oof_probability_by_fold_v1.png",
    ):
        print(f"  - {name}")

    print("\n" + "=" * 72)
    print("FIM — diagnóstico concluído. Nenhum modelo recalibrado; TEST intocado.")
    print("=" * 72)


if __name__ == "__main__":
    main()
