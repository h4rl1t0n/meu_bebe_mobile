"""Execução da FASE 3F-B: CV, seleção e avaliação final no TEST (protocolo congelado).

Este módulo EXECUTA o protocolo pré-especificado na FASE 3F-A — ele NÃO cria,
altera ou "melhora" nada. Regras congeladas que ele implementa, sem qualquer
decisão baseada nos resultados:

  * CV manual sobre ``cv_folds_v1.csv`` (5 folds congelados, DENTRO dos 4000
    TRAIN) — ``StratifiedKFold`` NÃO é chamado novamente aqui;
  * os MESMOS folds valem para Logistic Regression, Random Forest e XGBoost;
  * ``scale_pos_weight`` do XGBoost é calculado a partir do ``y`` do fit corrente
    (fold de treino ou os 4000 TRAIN no fit final), nunca do TEST;
  * métricas congeladas com threshold = 0.50;
  * seleção do modelo por mean PR-AUC → mean Recall → mean F1 (empate total → erro);
  * fit final do modelo selecionado APENAS nos 4000 TRAIN (preprocessor + modelo);
  * TEST avaliado UMA única vez, somente do modelo selecionado, após a seleção.

REGRA DE OURO DO TEST SET (seção 10): o TEST não participa de nenhuma decisão;
é aberto uma única vez, depois da seleção via TRAIN + CV exclusivamente.
"""

from __future__ import annotations

import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd

from ..evaluation import (
    average_precision,
    brier_score,
    calibration_curve_quantiles,
    compute_binary_metrics,
    pr_auc,
    roc_auc,
)
from ..preprocessing import load_x_y
from .config import MODEL_ORDER, load_training_config, sha256_file
from .folds import load_folds_table
from .guards import assert_x_is_x_model_only, y_is_binary
from .models import (
    build_logistic_pipeline,
    build_random_forest_pipeline,
    build_xgboost_pipeline,
    model_class_of,
)
from .split import load_split_table

_IA_ROOT = Path(__file__).resolve().parents[3]

_CONFIG_PATH = _IA_ROOT / "configs" / "training_protocol_v1.yaml"
_PREPROCESSING_CONFIG_PATH = _IA_ROOT / "configs" / "preprocessing_v1.yaml"
_DATASET_PATH = _IA_ROOT / "data" / "processed" / "dataset_synthetic_v1.jsonl"
_DGM_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "dgm_v1_manifest.json"
_SPLIT_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1.csv"
_SPLIT_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1_manifest.json"
_FOLDS_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1.csv"
_FOLDS_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "cv_folds_v1_manifest.json"

# Saídas da FASE 3F-B (artefatos produzidos por scripts, não por este módulo em si).
_OOF_PATH = _IA_ROOT / "data" / "processed" / "cv_oof_predictions_v1.csv"
_CV_RESULTS_PATH = _IA_ROOT / "artifacts" / "metrics" / "cv_results_v1.json"
_TEST_RESULTS_PATH = _IA_ROOT / "artifacts" / "metrics" / "final_test_results_v1.json"
_TEST_PREDICTIONS_PATH = _IA_ROOT / "data" / "processed" / "test_predictions_selected_v1.csv"
_MODEL_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1.joblib"
_MODEL_MANIFEST_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1_manifest.json"
_FIGURES_DIR = _IA_ROOT / "artifacts" / "figures"

# Colunas de probabilidade OOF por nome canônico do modelo (seção 8).
OOF_PROBABILITY_COLUMN: dict[str, str] = {
    "logistic_regression": "logistic_probability",
    "random_forest": "random_forest_probability",
    "xgboost": "xgboost_probability",
}

MODEL_DISPLAY_NAME: dict[str, str] = {
    "logistic_regression": "Logistic Regression",
    "random_forest": "Random Forest",
    "xgboost": "XGBoost",
}

# Métricas contínuas agregadas (mean/std) sobre os folds.
CV_METRIC_KEYS: tuple[str, ...] = (
    "accuracy",
    "precision",
    "recall",
    "f1",
    "roc_auc",
    "pr_auc",
    "brier_score",
)

SELECTION_KEYS: tuple[str, ...] = ("mean_pr_auc", "mean_recall", "mean_f1")


# ---------------------------------------------------------------------------
# Carregamento dos artefatos congelados
# ---------------------------------------------------------------------------

def load_frozen_dataset(
    *,
    dataset_path: Path = _DATASET_PATH,
) -> tuple[pd.DataFrame, np.ndarray]:
    """Carrega ``X_raw`` (34 colunas X_MODEL) e ``y``, com guard anti-leakage."""
    X_raw, y = load_x_y(dataset_path)
    assert_x_is_x_model_only(X_raw)
    y = np.asarray(y, dtype=np.int64)
    if not y_is_binary(y):
        raise ValueError("target não é binário 0/1")
    return X_raw, y


def load_frozen_split(
    split_path: Path = _SPLIT_PATH,
) -> tuple[np.ndarray, np.ndarray]:
    """Carrega o split congelado e devolve ``(train_idx, test_idx)`` ordenados."""
    table = load_split_table(split_path)
    train_idx = np.sort(
        table.loc[table["split"] == "train", "row_index"].to_numpy(dtype=np.int64)
    )
    test_idx = np.sort(
        table.loc[table["split"] == "test", "row_index"].to_numpy(dtype=np.int64)
    )
    return train_idx, test_idx


def load_frozen_folds(folds_path: Path = _FOLDS_PATH) -> pd.DataFrame:
    """Carrega o CSV congelado ``row_index,validation_fold`` (4000 linhas)."""
    return load_folds_table(folds_path)


def fold_splits(
    folds_df: pd.DataFrame,
    n_splits: int = 5,
) -> list[tuple[np.ndarray, np.ndarray]]:
    """Devolve, para cada ``validation_fold``, ``(train_rows, val_rows)``.

    ``train_rows`` = todas as linhas de treino cujo fold é diferente; ``val_rows``
    = as linhas daquele fold. NÃO recria os folds — apenas lê o CSV congelado.
    """
    splits: list[tuple[np.ndarray, np.ndarray]] = []
    for fold_id in range(n_splits):
        val_rows = np.sort(
            folds_df.loc[
                folds_df["validation_fold"] == fold_id, "row_index"
            ].to_numpy(dtype=np.int64)
        )
        train_rows = np.sort(
            folds_df.loc[
                folds_df["validation_fold"] != fold_id, "row_index"
            ].to_numpy(dtype=np.int64)
        )
        splits.append((train_rows, val_rows))
    return splits


# ---------------------------------------------------------------------------
# Métricas / agregação
# ---------------------------------------------------------------------------

def compute_full_metrics(
    y_true: np.ndarray,
    y_probability: np.ndarray,
    threshold: float = 0.50,
) -> dict[str, Any]:
    """Métricas completas no threshold principal + contagens da matriz de confusão."""
    m = compute_binary_metrics(y_true, y_probability, threshold)
    cm = m["confusion_matrix"]  # [[TN, FP], [FN, TP]]
    tn, fp = cm[0]
    fn, tp = cm[1]
    return {
        "threshold": float(threshold),
        "accuracy": m["accuracy"],
        "precision": m["precision"],
        "recall": m["recall"],
        "f1": m["f1"],
        "tn": int(tn),
        "fp": int(fp),
        "fn": int(fn),
        "tp": int(tp),
        "roc_auc": roc_auc(y_true, y_probability),
        "pr_auc": pr_auc(y_true, y_probability),
        "brier_score": brier_score(y_true, y_probability),
    }


def aggregate_fold_metrics(
    fold_metrics: list[dict[str, Any]],
) -> dict[str, dict[str, float]]:
    """Calcula mean/std (amostral, ddof=1) das métricas contínuas dos folds."""
    means: dict[str, float] = {}
    stds: dict[str, float] = {}
    for key in CV_METRIC_KEYS:
        vals = [float(fm[key]) for fm in fold_metrics]
        means[key] = float(np.mean(vals))
        stds[key] = float(np.std(vals, ddof=1))
    return {"mean_metrics": means, "std_metrics": stds}


# ---------------------------------------------------------------------------
# Seleção do modelo (regra congelada PR-AUC → Recall → F1)
# ---------------------------------------------------------------------------

def select_model_with_reason(
    cv_summaries: dict[str, dict[str, float]],
    tol: float = 1e-12,
) -> tuple[str, str, list[dict[str, Any]], bool]:
    """Seleciona o modelo pela regra congelada e devolve ``(name, reason, ranking, tiebreak_used)``.

    ``cv_summaries`` mapeia nome do modelo → ``{mean_pr_auc, mean_recall, mean_f1}``.
    Empate numérico (dentro de ``tol``) no primary é desempatado por Recall e
    depois F1; empate total nos três critérios levanta ``RuntimeError`` (PARE).
    """
    names = list(cv_summaries)
    if not names:
        raise ValueError("nenhum modelo para seleção")
    for name in names:
        missing = [k for k in SELECTION_KEYS if k not in cv_summaries[name]]
        if missing:
            raise ValueError(f"modelo {name!r} sem as chaves de seleção {missing!r}")

    vals = {n: {k: float(cv_summaries[n][k]) for k in SELECTION_KEYS} for n in names}
    ranked = sorted(
        names,
        key=lambda n: tuple(vals[n][k] for k in SELECTION_KEYS),
        reverse=True,
    )
    winner = ranked[0]
    runner_up = ranked[1] if len(ranked) > 1 else None

    def close(a: float, b: float) -> bool:
        return abs(a - b) <= tol

    if runner_up is not None and all(
        close(vals[winner][k], vals[runner_up][k]) for k in SELECTION_KEYS
    ):
        raise RuntimeError(
            f"EMPATE TOTAL na seleção entre {winner!r} e {runner_up!r} nas três "
            f"métricas {SELECTION_KEYS!r}. PARE e reporte o empate."
        )

    tiebreak_used = False
    if runner_up is not None and close(
        vals[winner]["mean_pr_auc"], vals[runner_up]["mean_pr_auc"]
    ):
        tiebreak_used = True
        if close(vals[winner]["mean_recall"], vals[runner_up]["mean_recall"]):
            reason = (
                f"{winner} selecionado: empate em mean PR-AUC "
                f"({vals[winner]['mean_pr_auc']:.6f}) e mean Recall "
                f"({vals[winner]['mean_recall']:.6f}); desempatado por maior mean F1 "
                f"({vals[winner]['mean_f1']:.6f} vs {vals[runner_up]['mean_f1']:.6f})."
            )
        else:
            reason = (
                f"{winner} selecionado: empate em mean PR-AUC "
                f"({vals[winner]['mean_pr_auc']:.6f}); desempatado por maior mean Recall "
                f"({vals[winner]['mean_recall']:.6f} vs {vals[runner_up]['mean_recall']:.6f})."
            )
    else:
        reason = (
            f"{winner} selecionado por maior mean PR-AUC "
            f"({vals[winner]['mean_pr_auc']:.6f}); sem empate numérico."
        )

    ranking = [{"model": n, **vals[n]} for n in ranked]
    return winner, reason, ranking, tiebreak_used


# ---------------------------------------------------------------------------
# Cross-validation (loop manual sobre os folds congelados)
# ---------------------------------------------------------------------------

def _build_pipeline(model_name: str, y_fit: np.ndarray | None = None):
    if model_name == "logistic_regression":
        return build_logistic_pipeline()
    if model_name == "random_forest":
        return build_random_forest_pipeline()
    if model_name == "xgboost":
        return build_xgboost_pipeline(y_fit=y_fit)
    raise KeyError(f"modelo desconhecido: {model_name!r}")


def run_cv_for_model(
    model_name: str,
    X_raw: pd.DataFrame,
    y: np.ndarray,
    fold_splits_: list[tuple[np.ndarray, np.ndarray]],
    threshold: float = 0.50,
) -> tuple[dict[int, dict[str, Any]], list[dict[str, Any]], float, list[float]]:
    """Executa o CV de 5 folds para um modelo e devolve ``(oof, fold_metrics, duration, scale_weights)``.

    ``oof`` mapeia ``row_index`` → ``{row_index, validation_fold, y_true, <model>_probability}``.
    ``scale_weights`` só é preenchido para XGBoost (um valor por fold).
    """
    y = np.asarray(y)
    oof: dict[int, dict[str, Any]] = {}
    fold_metrics: list[dict[str, Any]] = []
    scale_weights: list[float] = []
    col = OOF_PROBABILITY_COLUMN[model_name]

    start = time.perf_counter()
    for fold_id, (train_rows, val_rows) in enumerate(fold_splits_):
        y_fit = y[train_rows] if model_name == "xgboost" else None
        pipe = _build_pipeline(model_name, y_fit)
        if model_name == "xgboost":
            scale_weights.append(
                float(pipe.named_steps["model"].get_params()["scale_pos_weight"])
            )
        pipe.fit(X_raw.iloc[train_rows], y[train_rows])
        proba = pipe.predict_proba(X_raw.iloc[val_rows])[:, 1]

        fold_metrics.append(
            {"fold": int(fold_id), **compute_full_metrics(y[val_rows], proba, threshold)}
        )
        for row, p in zip(val_rows, proba):
            oof[int(row)] = {
                "row_index": int(row),
                "validation_fold": int(fold_id),
                "y_true": int(y[int(row)]),
                col: float(p),
            }
        del pipe

    duration = time.perf_counter() - start
    return oof, fold_metrics, duration, scale_weights


def merge_oof(
    oof_by_model: dict[str, dict[int, dict[str, Any]]],
) -> pd.DataFrame:
    """Junta os OOF dos três modelos em um DataFrame (uma linha por row_index).

    Colunas: ``row_index, validation_fold, y_true, logistic_probability,
    random_forest_probability, xgboost_probability``.
    """
    merged: dict[int, dict[str, Any]] = {}
    for model_name, oof in oof_by_model.items():
        col = OOF_PROBABILITY_COLUMN[model_name]
        for row, entry in oof.items():
            if row not in merged:
                merged[row] = {
                    "row_index": entry["row_index"],
                    "validation_fold": entry["validation_fold"],
                    "y_true": entry["y_true"],
                }
            if (
                merged[row]["validation_fold"] != entry["validation_fold"]
                or merged[row]["y_true"] != entry["y_true"]
            ):
                raise ValueError(
                    f"inconsistência de OOF na row {row}: os modelos divergem em "
                    f"validation_fold/y_true"
                )
            merged[row][col] = entry[col]

    columns = ["row_index", "validation_fold", "y_true", *OOF_PROBABILITY_COLUMN.values()]
    return pd.DataFrame([merged[r] for r in sorted(merged)], columns=columns)


def validate_oof_coverage(
    oof_df: pd.DataFrame,
    train_rows: np.ndarray,
    prob_cols: tuple[str, ...] = tuple(OOF_PROBABILITY_COLUMN.values()),
) -> None:
    """Garante que cada linha de treino tem exatamente 1 OOF e as 3 probabilidades."""
    rows = set(oof_df["row_index"].to_numpy())
    expected = set(int(r) for r in train_rows)
    if rows != expected:
        raise ValueError(
            f"OOF cobre {len(rows)} linhas, esperado {len(expected)} (cada TRAIN exatamente 1)"
        )
    for col in prob_cols:
        missing = int(oof_df[col].isna().sum())
        if missing:
            raise ValueError(f"OOF com {missing} valores ausentes em {col!r}")
        if not oof_df[col].between(0.0, 1.0).all():
            raise ValueError(f"OOF com probabilidade fora de [0,1] em {col!r}")


# ---------------------------------------------------------------------------
# Fit final + avaliação no TEST
# ---------------------------------------------------------------------------

def fit_final_model(model_name: str, X_train: pd.DataFrame, y_train: np.ndarray):
    """Ajusta um pipeline NOVO nos 4000 TRAIN (preprocessor + modelo)."""
    y_train = np.asarray(y_train, dtype=np.int64)
    y_fit = y_train if model_name == "xgboost" else None
    pipe = _build_pipeline(model_name, y_fit)
    pipe.fit(X_train, y_train)
    return pipe


def evaluate_final_test(
    selected_name: str,
    fitted_pipeline,
    X_test: pd.DataFrame,
    y_test: np.ndarray,
    threshold: float = 0.50,
    n_bins: int = 10,
) -> dict[str, Any]:
    """Avalia SOMENTE o modelo selecionado, UMA única vez, nos 1000 TEST."""
    y_test = np.asarray(y_test, dtype=np.int64)
    proba = fitted_pipeline.predict_proba(X_test)[:, 1]
    pred = (proba >= threshold).astype(int)
    prob_true, prob_pred = calibration_curve_quantiles(y_test, proba, n_bins=n_bins)

    result = compute_full_metrics(y_test, proba, threshold)
    result.update(
        {
            "selected_model": selected_name,
            "display_name": MODEL_DISPLAY_NAME[selected_name],
            "n_test": int(len(y_test)),
            "average_precision": average_precision(y_test, proba),
            "calibration_curve": {
                "prob_true": prob_true.tolist(),
                "prob_pred": prob_pred.tolist(),
            },
            "y_pred": pred.tolist(),
            "y_probability": proba.tolist(),
        }
    )
    return result


def assert_pipeline_model_is(pipeline, selected_name: str) -> None:
    """Garante que o passo ``model`` do pipeline é da classe congelada do modelo."""
    expected = model_class_of(selected_name)
    actual = pipeline.named_steps["model"]
    if not isinstance(actual, expected):
        raise ValueError(
            f"pipeline tem modelo {type(actual).__name__!r}, esperado {expected.__name__!r}"
        )


def positive_class_index(estimator) -> int:
    """Índice da classe positiva (1) nas ``classes_`` do estimador, validando ``[0, 1]``.

    PROTEÇÃO anti-silêncio: nunca assumir que a coluna 1 de ``predict_proba`` é a
    classe positiva sem conferir ``classes_``. Levanta ``ValueError`` se as classes
    não forem exatamente ``[0, 1]``.
    """
    classes = [int(c) for c in np.asarray(estimator.classes_).ravel()]
    if classes != [0, 1]:
        raise ValueError(
            f"classes_ inesperadas para problema binário 0/1: {estimator.classes_!r}"
        )
    return classes.index(1)


def positive_class_probability(estimator, proba: np.ndarray) -> np.ndarray:
    """Probabilidade da classe positiva extraída via ``classes_`` (nunca hardcoded)."""
    proba = np.asarray(proba)
    if proba.ndim != 2:
        raise ValueError(f"proba deve ser 2D (n_amostras, n_classes); recebido {proba.ndim}D")
    return proba[:, positive_class_index(estimator)]


# ---------------------------------------------------------------------------
# Serialização do modelo
# ---------------------------------------------------------------------------

def save_model(pipeline, model_path: Path) -> None:
    model_path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(pipeline, model_path)


def load_model(model_path: Path):
    return joblib.load(model_path)


def n_features_of(pipeline) -> int:
    """Número de features numéricas produzidas pelo preprocessor fitado (96)."""
    return int(len(pipeline.named_steps["preprocessor"].get_feature_names_out()))


def build_model_manifest(
    *,
    selected_name: str,
    pipeline,
    model_path: Path,
    dataset_hash: str,
    split_hash: str,
    folds_hash: str,
    protocol_hash: str,
    preprocessing_hash: str,
    n_train: int,
    class_counts_train: dict[str, int],
    scale_pos_weight: float | None,
    threshold: float,
) -> dict[str, Any]:
    """Monta o manifest do modelo serializado."""
    return {
        "model_name": selected_name,
        "display_name": MODEL_DISPLAY_NAME[selected_name],
        "model_class": model_class_of(selected_name).__name__,
        "protocol_version": "1.0",
        "schema_version": _schema_version(),
        "preprocessing_version": "1.0",
        "fit_scope": "TRAIN apenas (4000 registros); TEST nunca usado no fit",
        "n_train": int(n_train),
        "class_counts_train": class_counts_train,
        "n_features": n_features_of(pipeline),
        "scale_pos_weight": scale_pos_weight,
        "threshold": float(threshold),
        "dataset_hash_sha256": dataset_hash,
        "split_file_hash_sha256": split_hash,
        "folds_file_hash_sha256": folds_hash,
        "training_protocol_config_hash_sha256": protocol_hash,
        "preprocessing_config_hash_sha256": preprocessing_hash,
        "model_file_hash_sha256": sha256_file(model_path),
        "library_versions": _library_versions(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "note": "Modelo selecionado por mean PR-AUC → mean Recall → mean F1 via "
        "CV 5-fold congelado; ajustado nos 4000 TRAIN; avaliado uma vez nos 1000 TEST.",
    }


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

def _schema_version() -> str:
    from ..schema.constants import SCHEMA_VERSION

    return SCHEMA_VERSION


def _library_versions() -> dict[str, str]:
    import matplotlib
    import numpy as np
    import pandas as pd
    import scipy
    import sklearn
    import xgboost

    return {
        "python": sys.version.split()[0],
        "numpy": np.__version__,
        "pandas": pd.__version__,
        "scipy": scipy.__version__,
        "scikit_learn": sklearn.__version__,
        "xgboost": xgboost.__version__,
        "matplotlib": matplotlib.__version__,
        "joblib": joblib.__version__,
    }


def read_json(path: Path) -> dict[str, Any]:
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)
