"""Seleção determinística de campos (Q_full -> X_model / X_sens).

Este módulo realiza **somente** a seleção de campos do questionário. Ele NÃO faz
one-hot, multi-hot, imputação, normalização nem qualquer transformação
estatística — essas etapas pertencem ao pré-processamento (fase posterior).

``X_model`` = 34 features ML-IN (modelo principal).
``X_sens``  = 34 ML-IN + 2 SENSIBILIDADE (36, experimento secundário 34 vs 36).
"""

from __future__ import annotations

from typing import Any

from ..schema.constants import X_MODEL, X_SENS


def select_x_model(record: dict[str, Any]) -> dict[str, Any]:
    """Extrai de ``Q_full`` apenas as 34 features ML-IN (``X_model``).

    Preserva os valores originais (sem transformação). Campos ausentes no
    registro de entrada são ignorados — a integridade é responsabilidade do
    validador de schema.
    """
    return {name: record[name] for name in X_MODEL if name in record}


def select_x_sens(record: dict[str, Any]) -> dict[str, Any]:
    """Extrai de ``Q_full`` as 36 features do experimento de sensibilidade.

    Equivale a ``select_x_model`` + as 2 variáveis SENSIBILIDADE.
    """
    return {name: record[name] for name in X_SENS if name in record}


def list_x_model() -> list[str]:
    """Retorna a lista (ordenada) das 34 features ML-IN."""
    return list(X_MODEL)


def list_x_sens() -> list[str]:
    """Retorna a lista (ordenada) das 36 features do experimento de sensibilidade."""
    return list(X_SENS)
