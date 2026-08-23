"""Contrato de dados DSS 1.13: constantes, validador e invariantes."""

from .constants import (
    DESCRIPTIVE,
    DIMENSIONS,
    OUT_LEAKAGE,
    OUT_TEMPORAL,
    Q_FULL,
    SCHEMA_VERSION,
    SENSITIVITY,
    VARIABLE_TO_DIMENSION,
    X_MODEL,
    X_SENS,
    dimension_of,
    ml_class_of,
)
from .validator import SchemaSpec, load_schema, validate_record

__all__ = [
    "DESCRIPTIVE",
    "DIMENSIONS",
    "OUT_LEAKAGE",
    "OUT_TEMPORAL",
    "Q_FULL",
    "SCHEMA_VERSION",
    "SENSITIVITY",
    "VARIABLE_TO_DIMENSION",
    "X_MODEL",
    "X_SENS",
    "dimension_of",
    "ml_class_of",
    "SchemaSpec",
    "load_schema",
    "validate_record",
]
