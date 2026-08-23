"""Inspeção da análise de thresholds — FASE 3G-A (SOMENTE LEITURA).

Verifica invariantes dos artefatos gerados por ``analyze_oof_thresholds.py``:
  * OOF fonte com 4000 registros, apenas TRAIN (sem TEST), y0=3023/y1=977;
  * JSON com 46 thresholds, 0.50 presente, primary=0.50,
    ``operational_threshold_selected=false`` e ``selected_new_threshold=null``;
  * todas as métricas em domínios válidos;
  * monotonicidade: predicted_positive_count, predicted_positive_rate, recall e
    false_positive_rate NÃO aumentam; specificity NÃO diminui (precisão/F1/
    accuracy/NPV NÃO precisam ser monótonos).

Uso::

    python scripts/inspect_threshold_analysis.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd

try:  # garantir saída UTF-8 em terminais Windows
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:  # pragma: no cover
    pass

from meu_bebe_ml.training import load_frozen_split, read_json

_IA_ROOT = Path(__file__).resolve().parents[1]
_OOF_PATH = _IA_ROOT / "data" / "processed" / "cv_oof_predictions_v1.csv"
_SPLIT_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1.csv"
_CSV_PATH = _IA_ROOT / "artifacts" / "metrics" / "threshold_metrics_oof_v1.csv"
_JSON_PATH = _IA_ROOT / "artifacts" / "metrics" / "threshold_analysis_v1.json"

_PROB_COL = "random_forest_probability"

# Métricas que devem permanecer em [0, 1].
_UNIT_METRICS = (
    "accuracy", "precision", "recall", "specificity", "f1",
    "negative_predictive_value", "false_positive_rate", "false_negative_rate",
    "balanced_accuracy", "predicted_positive_rate",
)
_COUNT_METRICS = ("tn", "fp", "fn", "tp", "predicted_positive_count")


def _check(ok: bool, label: str) -> None:
    print(f"  [{'OK' if ok else 'FALHA'}] {label}")
    if not ok:
        raise SystemExit(f"Invariante violado: {label}")


def main() -> None:
    print("=" * 72)
    print("INSPEÇÃO — ANÁLISE DE THRESHOLDS (FASE 3G-A, somente leitura)")
    print("=" * 72)

    # ------------------------------------------------------------------
    # 1. Fonte OOF: só TRAIN, 4000 registros, prevalência correta
    # ------------------------------------------------------------------
    print("\n[1] OOF fonte (cv_oof_predictions_v1.csv)")
    train_idx, test_idx = load_frozen_split(_SPLIT_PATH)
    oof = pd.read_csv(_OOF_PATH)
    _check(len(oof) == 4000, "OOF tem 4000 registros")
    _check(oof["row_index"].nunique() == 4000, "row_index únicos (4000)")
    _check(len(set(oof["row_index"].tolist()) & set(test_idx.tolist())) == 0,
           "nenhum row_index pertence ao TEST")
    _check(set(oof["row_index"].tolist()) == set(train_idx.tolist()),
           "row_index cobre exatamente o TRAIN congelado")
    _check((int((oof["y_true"] == 0).sum()), int((oof["y_true"] == 1).sum())) == (3023, 977),
           "prevalência y0=3023 / y1=977")

    # ------------------------------------------------------------------
    # 2. JSON: estrutura e campos
    # ------------------------------------------------------------------
    print("\n[2] JSON threshold_analysis_v1.json")
    data = read_json(_JSON_PATH)
    _check(data["n"] == 4000, "JSON n == 4000")
    _check(data["y0"] == 3023 and data["y1"] == 977, "JSON y0/y1 corretos")
    _check(data["primary_threshold_reference"] == 0.50, "primary_threshold_reference == 0.50")
    _check(data["primary_threshold"] == 0.50, "primary_threshold == 0.50")
    _check(data["operational_threshold_selected"] is False,
           "operational_threshold_selected == false")
    _check(data["selected_new_threshold"] is None, "selected_new_threshold == null")

    grid = data["threshold_grid"]
    _check(len(grid) == 46, "grade com 46 thresholds")
    _check(abs(grid[0] - 0.05) < 1e-9 and abs(grid[-1] - 0.50) < 1e-9,
           "grade inicia em 0.05 e termina em 0.50")
    _check(any(abs(t - 0.50) < 1e-9 for t in grid), "threshold 0.50 presente na grade")

    # ------------------------------------------------------------------
    # 3. Tabela CSV: 46 linhas, domínios e monotonicidade
    # ------------------------------------------------------------------
    print("\n[3] CSV threshold_metrics_oof_v1.csv")
    df = pd.read_csv(_CSV_PATH)
    _check(len(df) == 46, "CSV tem 46 linhas (uma por threshold)")
    _check(list(df.columns) == [
        "threshold", "tn", "fp", "fn", "tp", "accuracy", "precision", "recall",
        "specificity", "f1", "negative_predictive_value", "false_positive_rate",
        "false_negative_rate", "balanced_accuracy", "predicted_positive_count",
        "predicted_positive_rate",
    ], "colunas do CSV exatamente as da seção 13")

    t = df["threshold"].to_numpy()
    _check(np.all(np.diff(t) > 0), "thresholds estritamente crescentes")
    _check(abs(t[0] - 0.05) < 1e-9 and abs(t[-1] - 0.50) < 1e-9, "CSV 0.05..0.50")

    for m in _UNIT_METRICS:
        _check(df[m].between(0.0, 1.0).all(), f"métrica {m} em [0,1]")
    for m in _COUNT_METRICS:
        _check(df[m].astype(int).ge(0).all(), f"contagem {m} >= 0")

    # n interno (soma da matriz) deve ser 4000 em todas as linhas.
    row_n = df["tn"] + df["fp"] + df["fn"] + df["tp"]
    _check((row_n == 4000).all(), "tn+fp+fn+tp == 4000 em todas as linhas")

    # Monotonicidade (seção 29) — permitida igualdade.
    for col in ("predicted_positive_count", "predicted_positive_rate", "recall",
                "false_positive_rate"):
        _check(np.all(np.diff(df[col].to_numpy()) <= 0), f"{col} é não-crescente")
    _check(np.all(np.diff(df["specificity"].to_numpy()) >= 0),
           "specificity é não-decrescente")

    # ------------------------------------------------------------------
    # 4. Resumo final
    # ------------------------------------------------------------------
    max_f1_row = df.loc[df["f1"].idxmax()]
    print("\n[4] Resumo")
    print(f"  exploratory_max_f1_threshold (JSON) = {data['exploratory_max_f1_threshold']:.2f}")
    print(f"  exploratory_max_f1 (JSON)           = {data['exploratory_max_f1']:.6f}")
    print(f"  max F1 no CSV = {max_f1_row['f1']:.6f} em threshold {max_f1_row['threshold']:.2f}")
    print(f"  threshold primário mantido = 0.50; TEST intocado; "
          f"selected_new_threshold = null")

    print("\n" + "=" * 72)
    print("INSPEÇÃO CONCLUÍDA — todos os invariantes OK.")
    print("=" * 72)


if __name__ == "__main__":
    main()
