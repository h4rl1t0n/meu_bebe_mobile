"""Análise secundária exploratória de thresholds — FASE 3G-A.

Usa EXCLUSIVAMENTE as predições out-of-fold do TREINAMENTO
(``data/processed/cv_oof_predictions_v1.csv``, 4000 registros; somente
``row_index``, ``y_true`` e ``random_forest_probability``) para descrever o
comportamento do threshold do Random Forest selecionado.

Este script NÃO:
  * abre o TEST nem o arquivo de predições do TEST;
  * treina, recalibra, ajusta hiperparâmetro nem faz threshold tuning;
  * seleciona um threshold operacional (mantém 0.50 como primário).

Saídas:
  * ``artifacts/metrics/threshold_metrics_oof_v1.csv``  (46 thresholds)
  * ``artifacts/metrics/threshold_analysis_v1.json``    (resumo + hashes)
  * ``artifacts/figures/oof_*_v1.png``                  (5 figuras)

Uso::

    python scripts/analyze_oof_thresholds.py
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
    build_threshold_grid,
    compute_threshold_table,
    find_exploratory_max_f1,
    load_threshold_config,
    select_reference_rows,
    summarize_analysis,
    validate_oof_train_only,
)
from meu_bebe_ml.training import load_frozen_split, sha256_file

_IA_ROOT = Path(__file__).resolve().parents[1]
_CONFIG_PATH = _IA_ROOT / "configs" / "threshold_analysis_v1.yaml"
_OOF_PATH = _IA_ROOT / "data" / "processed" / "cv_oof_predictions_v1.csv"
_SPLIT_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1.csv"
_FOLDS_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1.csv"

_OUT_CSV = _IA_ROOT / "artifacts" / "metrics" / "threshold_metrics_oof_v1.csv"
_OUT_JSON = _IA_ROOT / "artifacts" / "metrics" / "threshold_analysis_v1.json"
_FIGURES_DIR = _IA_ROOT / "artifacts" / "figures"

_PROB_COL = "random_forest_probability"

# Colunas do CSV (seção 13) — ordem exata, sem a coluna redundante "n".
_CSV_COLUMNS = [
    "threshold", "tn", "fp", "fn", "tp", "accuracy", "precision", "recall",
    "specificity", "f1", "negative_predictive_value", "false_positive_rate",
    "false_negative_rate", "balanced_accuracy", "predicted_positive_count",
    "predicted_positive_rate",
]


def _validate_oof(oof: pd.DataFrame, train_idx: np.ndarray, test_idx: np.ndarray) -> None:
    """Validações da seção 9 sobre o OOF (4000 registros, só TRAIN, binário, etc.)."""
    print("\n[validação do OOF]")
    n_expected = 4000
    if len(oof) != n_expected:
        raise ValueError(f"OOF tem {len(oof)} linhas; esperado {n_expected}")
    if len(oof) != oof["row_index"].nunique():
        raise ValueError("OOF contém row_index duplicado")

    row_index = oof["row_index"].to_numpy(dtype=np.int64)
    validate_oof_train_only(row_index, train_idx, test_idx)
    if set(row_index.tolist()) != set(train_idx.tolist()):
        raise ValueError("OOF não cobre exatamente o TRAIN congelado (4000 registros)")

    y = oof["y_true"]
    labels = set(y.unique())
    if not labels <= {0, 1}:
        raise ValueError(f"y_true não é binário: {sorted(labels)!r}")
    if y.isna().any():
        raise ValueError("y_true contém valores ausentes")

    p = oof[_PROB_COL]
    if p.isna().any():
        raise ValueError(f"{_PROB_COL} contém valores ausentes")
    pv = p.to_numpy()
    if not np.all(np.isfinite(pv)):
        raise ValueError(f"{_PROB_COL} contém valores não finitos")
    if np.any(pv < 0.0) or np.any(pv > 1.0):
        raise ValueError(f"{_PROB_COL} deve estar em [0, 1]")

    y0 = int((y == 0).sum())
    y1 = int((y == 1).sum())
    if (y0, y1) != (3023, 977):
        raise ValueError(f"divergência de prevalência: y0={y0}, y1={y1} != (3023, 977)")

    print(f"  n={len(oof)}  row_index únicos={oof['row_index'].nunique()}  "
          f"só TRAIN=OK  sem TEST=OK")
    print(f"  y0={y0}  y1={y1}  probs finitas em [0,1]=OK")


def _verify_50_coherence(oof: pd.DataFrame) -> None:
    """Seção 11: o threshold 0.50 no OOF concatenado deve bater com a soma dos 5 folds."""
    print("\n[coerência 0.50 vs folds]")
    y = oof["y_true"].to_numpy()
    p = oof[_PROB_COL].to_numpy()
    pred = (p >= 0.50).astype(int)

    def cm(yy, pp):
        tn = int(((yy == 0) & (pp == 0)).sum())
        fp = int(((yy == 0) & (pp == 1)).sum())
        fn = int(((yy == 1) & (pp == 0)).sum())
        tp = int(((yy == 1) & (pp == 1)).sum())
        return tn, fp, fn, tp

    concat = cm(y, pred)
    fold_sum = [0, 0, 0, 0]
    for fold_id in range(5):
        rows = oof[oof["validation_fold"] == fold_id]
        ff = cm(rows["y_true"].to_numpy(), (rows[_PROB_COL].to_numpy() >= 0.50).astype(int))
        for i in range(4):
            fold_sum[i] += ff[i]
    if tuple(fold_sum) != concat:
        raise ValueError(f"matriz 0.50 concatenada {concat} != soma dos folds {tuple(fold_sum)}")

    recall_concat = concat[3] / (concat[3] + concat[2]) if (concat[3] + concat[2]) else 0.0
    print(f"  0.50 concat TN/FP/FN/TP = {concat}  (recall={recall_concat:.6f})")
    print(f"  0.50 soma dos 5 folds = {tuple(fold_sum)}  -> coerente=OK")


# ---------------------------------------------------------------------------
# Figuras
# ---------------------------------------------------------------------------

def _style(ax, title: str, ylabel: str) -> None:
    ax.set_title(title)
    ax.set_xlabel("threshold")
    ax.set_ylabel(ylabel)
    ax.grid(True, alpha=0.3)


def _mark_primary(ax, primary: float, ymax: float) -> None:
    ax.axvline(primary, color="0.35", linestyle="--", linewidth=1.1)
    ax.annotate(
        f"{primary:.2f} (primário)", xy=(primary, ymax * 0.02),
        xytext=(primary + 0.012, ymax * 0.18), rotation=0, fontsize=8,
        va="bottom",
    )


def _line_figure(thresholds, values, ylabel, title, filename, primary):
    ymax = max(values) if values else 1.0
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.plot(thresholds, values, marker="o", markersize=3, linewidth=1.2)
    _mark_primary(ax, primary, ymax)
    _style(ax, title, ylabel)
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / filename, dpi=150)
    plt.close(fig)


def _generate_figures(table, config):
    thresholds = [r["threshold"] for r in table]
    primary = config.primary_threshold_reference
    _FIGURES_DIR.mkdir(parents=True, exist_ok=True)

    _line_figure(thresholds, [r["recall"] for r in table],
                 "recall (sensibilidade)", "Sensibilidade (recall) por threshold — OOF TREINAMENTO",
                 "oof_recall_by_threshold_v1.png", primary)
    _line_figure(thresholds, [r["precision"] for r in table],
                 "precision (PPV)", "Precisão (PPV) por threshold — OOF TREINAMENTO",
                 "oof_precision_by_threshold_v1.png", primary)
    _line_figure(thresholds, [r["f1"] for r in table],
                 "F1", "F1 por threshold — OOF TREINAMENTO",
                 "oof_f1_by_threshold_v1.png", primary)
    _line_figure(thresholds, [r["predicted_positive_rate"] for r in table],
                 "taxa de preditos positivos", "Taxa de preditos positivos por threshold — OOF TREINAMENTO",
                 "oof_predicted_positive_rate_by_threshold_v1.png", primary)

    # Trade-off sensibilidade × precisão (duas curvas no mesmo eixo).
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.plot(thresholds, [r["recall"] for r in table], marker="o", markersize=3,
            linewidth=1.2, label="recall (sensibilidade)")
    ax.plot(thresholds, [r["precision"] for r in table], marker="s", markersize=3,
            linewidth=1.2, label="precision (PPV)")
    _mark_primary(ax, primary, 1.0)
    ax.set_title("Trade-off sensibilidade × precisão por threshold — OOF TREINAMENTO")
    ax.set_xlabel("threshold")
    ax.set_ylabel("valor da métrica")
    ax.legend()
    ax.grid(True, alpha=0.3)
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "oof_precision_recall_threshold_tradeoff_v1.png", dpi=150)
    plt.close(fig)

    # F1: destaca o MAIOR F1 observado no grid (exploratório, não "ótimo").
    max_f1 = find_exploratory_max_f1(table)
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.plot(thresholds, [r["f1"] for r in table], marker="o", markersize=3, linewidth=1.2)
    ax.scatter([max_f1["threshold"]], [max_f1["f1"]], color="C1", zorder=5)
    ax.annotate(
        f"maior F1 no grid (exploratório): {max_f1['threshold']:.2f}",
        xy=(max_f1["threshold"], max_f1["f1"]),
        xytext=(max_f1["threshold"] - 0.10, max_f1["f1"] + 0.02),
        fontsize=8, arrowprops=dict(arrowstyle="->", lw=0.8),
    )
    _mark_primary(ax, primary, max(r["f1"] for r in table))
    _style(ax, "F1 por threshold — OOF TREINAMENTO", "F1")
    fig.tight_layout()
    fig.savefig(_FIGURES_DIR / "oof_f1_by_threshold_v1.png", dpi=150)
    plt.close(fig)

    print("\n[figuras] geradas em artifacts/figures/:")
    for name in (
        "oof_recall_by_threshold_v1.png",
        "oof_precision_by_threshold_v1.png",
        "oof_f1_by_threshold_v1.png",
        "oof_precision_recall_threshold_tradeoff_v1.png",
        "oof_predicted_positive_rate_by_threshold_v1.png",
    ):
        print(f"  - {name}")


def main() -> None:
    print("=" * 72)
    print("FASE 3G-A — ANÁLISE SECUNDÁRIA EXPLORATÓRIA DE THRESHOLDS (OOF TRAIN)")
    print("=" * 72)

    config = load_threshold_config(_CONFIG_PATH)
    print(f"\n[config] model={config.model}  source={config.source}  "
          f"primary={config.primary_threshold_reference:.2f}  "
          f"grid={config.grid_start:.2f}..{config.grid_stop:.2f} (step {config.grid_step:.2f})")

    # ------------------------------------------------------------------
    # 1. Hashes dos insumos congelados
    # ------------------------------------------------------------------
    input_hashes = {
        "cv_oof_predictions_v1.csv": sha256_file(_OOF_PATH),
        "train_test_split_v1.csv": sha256_file(_SPLIT_PATH),
        "cv_folds_v1.csv": sha256_file(_FOLDS_PATH),
        "threshold_analysis_v1.yaml": sha256_file(_CONFIG_PATH),
    }
    print("\n[hashes dos insumos]")
    for name, h in input_hashes.items():
        print(f"  {name}: {h}")

    # ------------------------------------------------------------------
    # 2. Split congelado + OOF (somente TRAIN)
    # ------------------------------------------------------------------
    train_idx, test_idx = load_frozen_split(_SPLIT_PATH)
    oof = pd.read_csv(_OOF_PATH)
    _validate_oof(oof, train_idx, test_idx)

    y = oof["y_true"].to_numpy()
    p = oof[_PROB_COL].to_numpy()

    # ------------------------------------------------------------------
    # 3. Grade + tabela de métricas
    # ------------------------------------------------------------------
    grid = build_threshold_grid(config.grid_start, config.grid_stop, config.grid_step)
    if len(grid) != 46:
        raise ValueError(f"grade com {len(grid)} thresholds; esperado 46")
    table = compute_threshold_table(y, p, grid)

    _verify_50_coherence(oof)

    # ------------------------------------------------------------------
    # 4. CSV (seção 13)
    # ------------------------------------------------------------------
    _OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    pd.DataFrame(table)[_CSV_COLUMNS].to_csv(_OUT_CSV, index=False)
    print(f"\n[csv] {_OUT_CSV.name} ({len(table)} thresholds)")

    # ------------------------------------------------------------------
    # 5. JSON (seção 14)
    # ------------------------------------------------------------------
    summary = summarize_analysis(table, config, y, p)
    summary["input_hashes"] = input_hashes
    summary["timestamp"] = datetime.now(timezone.utc).isoformat()

    _OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    with open(_OUT_JSON, "w", encoding="utf-8") as fh:
        json.dump(summary, fh, ensure_ascii=False, indent=2)
    print(f"[json] {_OUT_JSON.name}")

    print("\n[resumo]")
    print(f"  n={summary['n']}  y0={summary['y0']}  y1={summary['y1']}  "
          f"positive_rate={summary['positive_rate']:.6f}")
    print(f"  prob min/max/mean/std = "
          f"{summary['probability']['min']:.4f}/{summary['probability']['max']:.4f}/"
          f"{summary['probability']['mean']:.4f}/{summary['probability']['std']:.4f}")
    print(f"  exploratory_max_f1_threshold = {summary['exploratory_max_f1_threshold']:.2f}  "
          f"(f1={summary['exploratory_max_f1']:.6f})")
    print(f"  operational_threshold_selected = {summary['operational_threshold_selected']}  "
          f"selected_new_threshold = {summary['selected_new_threshold']!r}")

    print("\n[métricas nos thresholds de referência]")
    refs = select_reference_rows(table, config.reference_thresholds)
    print("  threshold | recall | precision | f1    | specificity | pred+ rate")
    for r in refs:
        print(f"  {r['threshold']:9.2f} | {r['recall']:.4f} | {r['precision']:.4f} | "
              f"{r['f1']:.4f} | {r['specificity']:.4f} | {r['predicted_positive_rate']:.4f}")

    # ------------------------------------------------------------------
    # 6. Figuras (seções 15–19)
    # ------------------------------------------------------------------
    _generate_figures(table, config)

    print("\n" + "=" * 72)
    print("FIM — análise exploratória concluída. Threshold primário mantido em 0.50.")
    print("Nenhum threshold operacional foi selecionado; o TEST não foi aberto.")
    print("=" * 72)


if __name__ == "__main__":
    main()
