"""Subpacote de interpretabilidade e explicabilidade (XAI)."""

from .local_xai import (
    FEATURE_LABELS_PT_BR,
    LocalFactorContribution,
    explain_prediction_rf,
    map_transformed_to_raw,
)

__all__ = [
    "FEATURE_LABELS_PT_BR",
    "LocalFactorContribution",
    "explain_prediction_rf",
    "map_transformed_to_raw",
]
