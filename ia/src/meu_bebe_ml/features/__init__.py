"""Seleção determinística de campos (Q_full -> X_model / X_sens)."""

from .selectors import list_x_model, list_x_sens, select_x_model, select_x_sens

__all__ = ["select_x_model", "select_x_sens", "list_x_model", "list_x_sens"]
