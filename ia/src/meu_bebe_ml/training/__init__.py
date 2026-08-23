"""Protocolo experimental de treinamento e avaliação (FASE 3F-A).

Congela split, folds de cross-validation, hiperparâmetros iniciais, métricas e
regra de seleção ANTES de qualquer resultado preditivo real. NENHUM modelo é
treinado no dataset principal nesta fase.

REGRA DE OURO DO TEST SET: o TEST (1000 registros) não participa de nenhuma
decisão (modelo, hiperparâmetro, threshold, feature, preprocessing, calibração,
class_weight). É aberto uma única vez, na Fase 3F-B, após a seleção do candidato
usando exclusivamente TRAIN + CV.
"""

from __future__ import annotations

from .config import (
    MODEL_ORDER,
    CrossValidationConfig,
    SplitConfig,
    TrainingProtocolConfig,
    load_training_config,
    sha256_file,
)
from .execution import (
    CV_METRIC_KEYS,
    MODEL_DISPLAY_NAME,
    OOF_PROBABILITY_COLUMN,
    SELECTION_KEYS,
    aggregate_fold_metrics,
    assert_pipeline_model_is,
    build_model_manifest,
    compute_full_metrics,
    evaluate_final_test,
    fit_final_model,
    fold_splits,
    load_frozen_dataset,
    load_frozen_folds,
    load_frozen_split,
    load_model,
    merge_oof,
    n_features_of,
    positive_class_index,
    positive_class_probability,
    read_json,
    run_cv_for_model,
    save_model,
    select_model_with_reason,
    validate_oof_coverage,
)
from .folds import (
    FoldsResult,
    build_folds_manifest,
    build_folds_table,
    compute_folds,
    load_folds_table,
    write_folds_artifacts,
)
from .guards import (
    assert_no_forbidden_columns,
    assert_x_is_x_model_only,
    forbidden_tokens,
    y_is_binary,
)
from .models import (
    build_logistic_pipeline,
    build_random_forest_pipeline,
    build_xgboost_pipeline,
    compute_scale_pos_weight,
    model_class_of,
)
from .split import (
    SplitResult,
    build_split_manifest,
    build_split_table,
    compute_split,
    load_split_table,
    write_split_artifacts,
)

__all__ = [
    "CV_METRIC_KEYS",
    "CrossValidationConfig",
    "FoldsResult",
    "MODEL_DISPLAY_NAME",
    "MODEL_ORDER",
    "OOF_PROBABILITY_COLUMN",
    "SELECTION_KEYS",
    "FoldsResult",
    "MODEL_ORDER",
    "SplitConfig",
    "SplitResult",
    "TrainingProtocolConfig",
    "aggregate_fold_metrics",
    "assert_no_forbidden_columns",
    "assert_pipeline_model_is",
    "assert_x_is_x_model_only",
    "build_folds_manifest",
    "build_folds_table",
    "build_logistic_pipeline",
    "build_model_manifest",
    "build_random_forest_pipeline",
    "build_split_manifest",
    "build_split_table",
    "build_xgboost_pipeline",
    "compute_folds",
    "compute_full_metrics",
    "compute_scale_pos_weight",
    "compute_split",
    "evaluate_final_test",
    "fit_final_model",
    "fold_splits",
    "forbidden_tokens",
    "load_folds_table",
    "load_frozen_dataset",
    "load_frozen_folds",
    "load_frozen_split",
    "load_model",
    "load_split_table",
    "load_training_config",
    "merge_oof",
    "model_class_of",
    "n_features_of",
    "positive_class_index",
    "positive_class_probability",
    "read_json",
    "run_cv_for_model",
    "save_model",
    "select_model_with_reason",
    "sha256_file",
    "validate_oof_coverage",
    "write_folds_artifacts",
    "write_split_artifacts",
    "y_is_binary",
]
