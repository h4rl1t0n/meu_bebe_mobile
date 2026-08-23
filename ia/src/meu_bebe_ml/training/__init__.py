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
    "CrossValidationConfig",
    "FoldsResult",
    "MODEL_ORDER",
    "SplitConfig",
    "SplitResult",
    "TrainingProtocolConfig",
    "assert_no_forbidden_columns",
    "assert_x_is_x_model_only",
    "build_folds_manifest",
    "build_folds_table",
    "build_logistic_pipeline",
    "build_random_forest_pipeline",
    "build_split_manifest",
    "build_split_table",
    "build_xgboost_pipeline",
    "compute_folds",
    "compute_scale_pos_weight",
    "compute_split",
    "forbidden_tokens",
    "load_folds_table",
    "load_split_table",
    "load_training_config",
    "model_class_of",
    "sha256_file",
    "write_folds_artifacts",
    "write_split_artifacts",
    "y_is_binary",
]
