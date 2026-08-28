"""Subpacote SOM — Self-Organizing Map mínimo para análise exploratória DSS.

FASE IA-SOM. O SOM agrupa registros por semelhança de perfil DSS (features
numéricas derivadas de ``X_MODEL``), sem ver o target nem o Random Forest.
"""

from __future__ import annotations

from .normalization import SomMinMaxNormalizer, som_scale_mask
from .som import SOMConfig, SelfOrganizingMap

__all__ = [
    "SOMConfig",
    "SelfOrganizingMap",
    "SomMinMaxNormalizer",
    "som_scale_mask",
]
