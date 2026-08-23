"""Dimensão Habitação do IV-DSS.

Utiliza SOMENTE a densidade ``numero_pessoas / numero_dormitorios``, mapeada em
três faixas (docs §8.5):

* ``densidade <= 2``     -> 0.0
* ``2 < densidade <= 3`` -> 0.5
* ``densidade > 3``      -> 1.0

NÃO utiliza ``tipo_moradia``, ``material_moradia``, ``itens_residencia``,
``seguranca_residencia``, ``melhorias_desejadas`` nem ``numero_comodos``.
``agua_encanada`` (dentro de ``itens_residencia``) já é pontuada em
Saneamento e NÃO é contada novamente aqui.

A sensibilidade binária (``densidade > 3 -> 1``, senão ``0``) é uma análise
auxiliar e NÃO substitui a versão principal 0 / 0.5 / 1.
"""

from __future__ import annotations

from typing import Any, Mapping

from .types import ScoreResult, missing, valid


def crowding_ratio(numero_pessoas: int | None, numero_dormitorios: int | None) -> float | None:
    """Razão pessoas/dormitórios; ``None`` se algum valor ausente ou inválido."""
    if numero_pessoas is None or numero_dormitorios is None:
        return None
    if not isinstance(numero_dormitorios, int) or numero_dormitorios < 1:
        return None
    if not isinstance(numero_pessoas, int) or numero_pessoas < 1:
        return None
    return numero_pessoas / numero_dormitorios


def _density_score(densidade: float) -> float:
    """Mapeia a densidade nas faixas principais 0 / 0.5 / 1."""
    if densidade <= 2.0:
        return 0.0
    if densidade <= 3.0:
        return 0.5
    return 1.0


def score_habitacao_from_ratio(densidade: float | None) -> ScoreResult:
    """Score principal de Habitação a partir da densidade."""
    if densidade is None:
        return missing("densidade (numero_pessoas / numero_dormitorios) não calculável")
    return valid(_density_score(densidade))


def D_habitacao(record: Mapping[str, Any]) -> ScoreResult:
    """Dimensão Habitação = score da densidade."""
    densidade = crowding_ratio(record.get("numero_pessoas"), record.get("numero_dormitorios"))
    return score_habitacao_from_ratio(densidade)


def score_habitacao_binary_from_ratio(densidade: float | None) -> ScoreResult:
    """Sensibilidade binária de Habitação: ``densidade > 3 -> 1``, senão ``0``."""
    if densidade is None:
        return missing("densidade (numero_pessoas / numero_dormitorios) não calculável")
    return valid(1.0 if densidade > 3.0 else 0.0)


def D_habitacao_binary_sensitivity(record: Mapping[str, Any]) -> ScoreResult:
    """Sensibilidade binária de Habitação (marcada como SENSIBILIDADE)."""
    densidade = crowding_ratio(record.get("numero_pessoas"), record.get("numero_dormitorios"))
    return score_habitacao_binary_from_ratio(densidade)
