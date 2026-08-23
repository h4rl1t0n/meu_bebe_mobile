"""Auditoria de sanidade da FASE 3F-B (SOMENTE LEITURA).

Audita o resultado do Random Forest selecionado (TP=0 no threshold 0.50) sem
alterar NENHUM artefato oficial, sem refazer seleção, sem tuning e sem
recalibração. Recomputa independentemente PR-AUC/ROC-AUC/Brier e verifica
determinismo em uma segunda execução controlada EM MEMÓRIA (sem escrever nada).

Uso::

    python scripts/audit_training_results.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.metrics import auc, precision_recall_curve, roc_auc_score

try:  # garantir saída UTF-8 em terminais Windows
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:  # pragma: no cover
    pass

from meu_bebe_ml.training import (
    MODEL_ORDER,
    aggregate_fold_metrics,
    evaluate_final_test,
    fit_final_model,
    fold_splits,
    load_frozen_dataset,
    load_frozen_folds,
    load_frozen_split,
    load_model,
    read_json,
    run_cv_for_model,
    select_model_with_reason,
)

_IA_ROOT = Path(__file__).resolve().parents[1]
_SPLIT_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1.csv"
_FOLDS_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1.csv"
_OOF_PATH = _IA_ROOT / "data" / "processed" / "cv_oof_predictions_v1.csv"
_CV_RESULTS_PATH = _IA_ROOT / "artifacts" / "metrics" / "cv_results_v1.json"
_TEST_RESULTS_PATH = _IA_ROOT / "artifacts" / "metrics" / "final_test_results_v1.json"
_TEST_PREDICTIONS_PATH = _IA_ROOT / "data" / "processed" / "test_predictions_selected_v1.csv"
_MODEL_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1.joblib"

_QUANTILES = (0.01, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.99)


def _fmt(x: float) -> str:
    return f"{x:.6f}"


def _quantile_report(p: np.ndarray) -> dict[str, float]:
    return {
        "min": float(p.min()),
        "max": float(p.max()),
        "mean": float(p.mean()),
        "std": float(p.std(ddof=1)),
        **{f"q{int(q * 100):02d}": float(np.quantile(p, q)) for q in _QUANTILES},
    }


def _print_quantiles(name: str, p: np.ndarray) -> None:
    r = _quantile_report(p)
    print(f"\n  [{name}] n={len(p)}")
    print(f"    min={r['min']:.6f}  max={r['max']:.6f}  mean={r['mean']:.6f}  std={r['std']:.6f}")
    qs = "  ".join(f"q{q * 100:02.0f}={r[f'q{int(q*100):02d}']:.6f}" for q in _QUANTILES)
    print(f"    {qs}")


def main() -> None:
    print("=" * 72)
    print("AUDITORIA DE SANIDADE — FASE 3F-B (somente leitura)")
    print("=" * 72)

    cv = read_json(_CV_RESULTS_PATH)
    test_res = read_json(_TEST_RESULTS_PATH)
    test_pred = pd.read_csv(_TEST_PREDICTIONS_PATH)
    oof = pd.read_csv(_OOF_PATH)
    train_idx, test_idx = load_frozen_split(_SPLIT_PATH)
    folds_df = load_frozen_folds(_FOLDS_PATH)
    splits = fold_splits(folds_df, n_splits=5)

    X_raw, y = load_frozen_dataset()
    pipeline = load_model(_MODEL_PATH)
    model = pipeline.named_steps["model"]

    # ------------------------------------------------------------------
    # 1. CLASSE POSITIVA
    # ------------------------------------------------------------------
    print("\n[1] CLASSE POSITIVA")
    classes = list(model.classes_)
    pos_idx = classes.index(1)
    print(f"  model.classes_ = {classes}")
    print(f"  índice da classe 1 (positiva) = {pos_idx}")
    assert classes == [0, 1], f"classes_ inesperadas: {classes}"

    X_test = X_raw.iloc[test_idx]
    recomputed_proba = pipeline.predict_proba(X_test)[:, pos_idx]
    saved_proba = test_pred["y_probability"].to_numpy()
    max_diff = float(np.max(np.abs(recomputed_proba - saved_proba)))
    print(f"  proba recomputada via classes_ == y_probability salva? max|diff| = {max_diff:.3e}")
    print(f"  [{'OK' if max_diff < 1e-9 else 'FALHA'}] predict_proba[:, {pos_idx}] é a prob. usada")

    # ------------------------------------------------------------------
    # 2. THRESHOLD
    # ------------------------------------------------------------------
    print("\n[2] THRESHOLD 0.50")
    y_test = y[test_idx]
    y_prob = saved_proba
    y_pred = (y_prob >= 0.50).astype(int)
    saved_y_pred = test_pred["y_pred"].to_numpy()
    print(f"  y_pred == (y_probability >= 0.50)? {bool(np.array_equal(y_pred, saved_y_pred))}")

    n_ge = int((y_prob >= 0.50).sum())
    n_gt = int((y_prob > 0.50).sum())
    ge_idx = np.where(y_prob >= 0.50)[0]
    gt_idx = np.where(y_prob > 0.50)[0]
    print(f"  p >= 0.50 : {n_ge}  (y_true: {y_test[ge_idx].tolist()})")
    print(f"  p >  0.50 : {n_gt}  (y_true: {y_test[gt_idx].tolist()})")
    fp = int(((y_test == 0) & (y_pred == 1)).sum())
    tp = int(((y_test == 1) & (y_pred == 1)).sum())
    print(f"  => FP={fp}  TP={tp}  (explica TP=0/FP=1 do relatório)")

    # ------------------------------------------------------------------
    # 3. DISTRIBUIÇÃO DAS PROBABILIDADES TEST
    # ------------------------------------------------------------------
    print("\n[3] DISTRIBUIÇÃO DAS PROBABILIDADES — TEST (N=1000)")
    _print_quantiles("todos", y_prob)
    print("  separado por y_true (diagnóstico):")
    for label, mask in (("y_true=0", y_test == 0), ("y_true=1", y_test == 1)):
        p = y_prob[mask]
        r = _quantile_report(p)
        print(
            f"    [{label}] n={len(p)} mean={r['mean']:.6f} median={r['q50']:.6f} "
            f"max={r['max']:.6f} q75={r['q75']:.6f} q90={r['q90']:.6f}"
        )

    # ------------------------------------------------------------------
    # 4. DISTRIBUIÇÃO OOF DO RANDOM FOREST (TRAIN)
    # ------------------------------------------------------------------
    print("\n[4] DISTRIBUIÇÃO OOF — RANDOM FOREST (TRAIN N=4000)")
    oof_rf = oof["random_forest_probability"].to_numpy()
    oof_y = oof["y_true"].to_numpy()
    oof_ge = oof_rf >= 0.50
    n_oof_ge = int(oof_ge.sum())
    n_oof_tp = int((oof_ge & (oof_y == 1)).sum())
    print(f"  p >= 0.50 : {n_oof_ge}")
    print(f"  TP entre p>=0.50 : {n_oof_tp}")
    _print_quantiles("OOF RF", oof_rf)
    recall_cv = cv["models"]["random_forest"]["mean_metrics"]["recall"]
    print(f"  => Recall médio CV RF = {recall_cv:.6f} decorre da escassez de p>=0.50 "
          f"(só {n_oof_ge}/4000 acima de 0.50)")

    # ------------------------------------------------------------------
    # 5. MATRIZ DE CONFUSÃO POR FOLD (RF, threshold 0.50)
    # ------------------------------------------------------------------
    print("\n[5] MATRIZ DE CONFUSÃO POR FOLD — RANDOM FOREST (threshold 0.50)")
    print("  fold |   TN |  FP |  FN | TP")
    for fold_id in range(5):
        rows = oof[oof["validation_fold"] == fold_id]
        yy = rows["y_true"].to_numpy()
        pp = (rows["random_forest_probability"].to_numpy() >= 0.50).astype(int)
        tn = int(((yy == 0) & (pp == 0)).sum())
        fp = int(((yy == 0) & (pp == 1)).sum())
        fn = int(((yy == 1) & (pp == 0)).sum())
        tp = int(((yy == 1) & (pp == 1)).sum())
        print(f"  {fold_id:4d} | {tn:4d} | {fp:3d} | {fn:3d} | {tp:2d}")

    # ------------------------------------------------------------------
    # 6. PR-AUC (recomputação independente)
    # ------------------------------------------------------------------
    print("\n[6] PR-AUC (recomputação independente com OOF salva)")
    official_mean_pr = cv["models"]["random_forest"]["mean_metrics"]["pr_auc"]
    fold_pr = []
    for fold_id in range(5):
        rows = oof[oof["validation_fold"] == fold_id]
        yy = rows["y_true"].to_numpy()
        pp = rows["random_forest_probability"].to_numpy()
        precision, recall, _ = precision_recall_curve(yy, pp)
        fold_pr.append(float(auc(recall, precision)))
    recomputed_mean_pr = float(np.mean(fold_pr))
    print(f"  oficial (mean of folds) = {official_mean_pr:.6f}")
    print(f"  recomputado (sklearn)   = {recomputed_mean_pr:.6f}")
    print(f"  |diff| = {abs(official_mean_pr - recomputed_mean_pr):.3e}  "
          f"[{'OK' if abs(official_mean_pr - recomputed_mean_pr) < 1e-9 else 'FALHA'}]")
    print(f"  folds individuais = {[f'{v:.6f}' for v in fold_pr]}")

    # ------------------------------------------------------------------
    # 7. ROC-AUC (recomputação independente)
    # ------------------------------------------------------------------
    print("\n[7] ROC-AUC (recomputação independente com OOF salva)")
    official_mean_roc = cv["models"]["random_forest"]["mean_metrics"]["roc_auc"]
    fold_roc = []
    for fold_id in range(5):
        rows = oof[oof["validation_fold"] == fold_id]
        fold_roc.append(roc_auc_score(rows["y_true"].to_numpy(), rows["random_forest_probability"].to_numpy()))
    recomputed_mean_roc = float(np.mean(fold_roc))
    print(f"  oficial (mean of folds) = {official_mean_roc:.6f}")
    print(f"  recomputado (sklearn)   = {recomputed_mean_roc:.6f}")
    print(f"  |diff| = {abs(official_mean_roc - recomputed_mean_roc):.3e}  "
          f"[{'OK' if abs(official_mean_roc - recomputed_mean_roc) < 1e-9 else 'FALHA'}]")

    # ------------------------------------------------------------------
    # 8. BRIER E BASELINE
    # ------------------------------------------------------------------
    print("\n[8] BRIER E BASELINE (prevalência do TRAIN)")
    brier_model = test_res["brier_score"]
    prevalence_train = float((y[train_idx] == 1).mean())
    baseline_brier = float(np.mean((y_test - prevalence_train) ** 2))
    print(f"  prevalência TRAIN (baseline const.) = {prevalence_train:.6f}")
    print(f"  Brier modelo (TEST)                 = {brier_model:.6f}")
    print(f"  Brier baseline (prev. TRAIN no TEST)= {baseline_brier:.6f}")

    # ------------------------------------------------------------------
    # 9. CALIBRAÇÃO
    # ------------------------------------------------------------------
    print("\n[9] CALIBRAÇÃO (10 bins, diagnóstico)")
    cb = test_res["calibration_curve"]
    print("  bin | mean_pred_prob | frac_positives")
    for i, (pp, ft) in enumerate(zip(cb["prob_pred"], cb["prob_true"])):
        print(f"  {i:3d} | {pp:14.6f} | {ft:14.6f}")
    mean_pred = float(y_prob.mean())
    obs_rate = 244 / 1000
    print(f"  mean predicted probability (TEST) = {mean_pred:.6f}")
    print(f"  244/1000 observado                = {obs_rate:.6f}")
    print("  (diagnóstico de calibração no cenário sintético; não conclusivo sobre má calibração)")

    # ------------------------------------------------------------------
    # 10. CLASS WEIGHT E PARÂMETROS DO RF
    # ------------------------------------------------------------------
    print("\n[10] PARÂMETROS EFETIVOS DO RANDOM FOREST FINAL")
    params = model.get_params()
    for key in (
        "class_weight", "n_estimators", "random_state", "max_features",
        "criterion", "max_depth", "min_samples_split", "min_samples_leaf", "n_jobs",
    ):
        print(f"  {key} = {params.get(key)!r}")

    # ------------------------------------------------------------------
    # 11. DETERMINISMO (segunda execução controlada EM MEMÓRIA)
    # ------------------------------------------------------------------
    print("\n[11] DETERMINISMO — segunda execução controlada (em memória, sem escrever)")
    oof_by_model2 = {}
    summaries2 = {}
    for name in MODEL_ORDER:
        o2, fm2, _, _ = run_cv_for_model(name, X_raw, y, splits, threshold=0.50)
        agg2 = aggregate_fold_metrics(fm2)
        oof_by_model2[name] = o2
        summaries2[name] = {
            "mean_pr_auc": agg2["mean_metrics"]["pr_auc"],
            "mean_recall": agg2["mean_metrics"]["recall"],
            "mean_f1": agg2["mean_metrics"]["f1"],
        }
    selected2, _, _, _ = select_model_with_reason(summaries2)
    print(f"  selected_model (re-execução) = {selected2}")
    print(f"  selected_model (oficial)     = {cv['selection']['selected_model']}")

    for name in MODEL_ORDER:
        d_pr = abs(summaries2[name]["mean_pr_auc"] - cv["models"][name]["mean_metrics"]["pr_auc"])
        print(f"  [{name}] |Δ PR-AUC| = {d_pr:.3e}")

    # probabilidades TEST do RF (re-execução)
    pipe2 = fit_final_model("random_forest", X_raw.iloc[train_idx], y[train_idx])
    proba2 = pipe2.predict_proba(X_test)[:, list(pipe2.named_steps["model"].classes_).index(1)]
    d_prob = float(np.max(np.abs(proba2 - saved_proba)))
    res2 = evaluate_final_test("random_forest", pipe2, X_test, y_test, threshold=0.50)
    print(f"  max|Δ proba TEST RF| = {d_prob:.3e}")
    print(f"  TEST metrics re-execução: acc={res2['accuracy']:.6f} roc={res2['roc_auc']:.6f} "
          f"pr={res2['pr_auc']:.6f} tp={res2['tp']}")
    print("  (diferenças < 1e-6 consideradas deterministas)")

    # ------------------------------------------------------------------
    # 12. BASELINE CLASSIFICATÓRIO TRIVIAL
    # ------------------------------------------------------------------
    print("\n[12] BASELINE CLASSIFICATÓRIO TRIVIAL (referência)")
    trivial_acc = (y_test == 0).mean()
    print(f"  sempre-0 no TEST: accuracy = 756/1000 = {trivial_acc:.6f}")
    print(f"  RF accuracy no threshold 0.50 = {test_res['accuracy']:.6f}")
    print("  (apenas referência: accuracy do RF não representa ganho classificatório)")

    # ------------------------------------------------------------------
    # 13. RESULTADO PRINCIPAL
    # ------------------------------------------------------------------
    print("\n[13] RESULTADO PRINCIPAL — NÃO ALTERAR")
    print(f"  TP=0 e Recall=0/F1=0 no threshold 0.50 é o resultado REAL do protocolo congelado.")
    print(f"  Modelo selecionado mantido: {cv['selection']['selected_model']}.")

    print("\n" + "=" * 72)
    print("FIM DA AUDITORIA — nenhum artefato oficial foi modificado.")
    print("=" * 72)


if __name__ == "__main__":
    main()
