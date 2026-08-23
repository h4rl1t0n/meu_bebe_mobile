"""Preprocessing v1 de ``X_MODEL`` (34 variáveis) para machine learning.

FASE 3E. Codifica as 34 variáveis brutas de ``X_MODEL`` em 96 features
numéricas, compatíveis com scikit-learn, com vocabulário/ordem CONGELADOS do
schema DSS 1.13. NÃO usa ``Y``, ``M_sim``, IV-DSS nem ``OUT_*``; NÃO imputa,
NÃO escala, NÃO faz feature selection e NÃO cria features dependentes do target.
"""

from __future__ import annotations

from .builder import build_x_model_preprocessor
from .config import (
    GROUP_ORDER,
    MultiselectField,
    NominalField,
    OrdinalField,
    PreprocessingConfig,
    load_preprocessing_config,
)
from .contract import (
    NOT_APPLICABLE_FEATURE_SUFFIX,
    ResolvedSpec,
    resolve_spec,
)
from .diagnostics import check_structural_nulls, load_x_y
from .transformers import (
    BooleanRequiredEncoder,
    MultiSelectBinarizerTransformer,
    NominalOneHotEncoder,
    NumericEncoder,
    OrdinalFeatureEncoder,
    StructuralBooleanEncoder,
)

__all__ = [
    "BooleanRequiredEncoder",
    "GROUP_ORDER",
    "MultiSelectBinarizerTransformer",
    "MultiselectField",
    "NOT_APPLICABLE_FEATURE_SUFFIX",
    "NominalField",
    "NominalOneHotEncoder",
    "NumericEncoder",
    "OrdinalFeatureEncoder",
    "OrdinalField",
    "PreprocessingConfig",
    "ResolvedSpec",
    "StructuralBooleanEncoder",
    "build_x_model_preprocessor",
    "check_structural_nulls",
    "load_preprocessing_config",
    "load_x_y",
    "resolve_spec",
]
