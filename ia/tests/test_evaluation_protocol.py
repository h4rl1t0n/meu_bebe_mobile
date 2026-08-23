"""Testes da regra de seleção do modelo e da regra de ouro (seções 10, 21, 22).

Validam que a seleção usa mean PR-AUC como critério principal e Recall/F1 como
desempates, exatamente na ordem congelada, sem participação do TEST.
"""

from __future__ import annotations

import pytest

from meu_bebe_ml.evaluation import (
    SELECTION_PRIMARY_METRIC,
    SELECTION_TIEBREAK,
    select_best_model,
)
from meu_bebe_ml.training import load_training_config


def test_selection_rule_matches_config() -> None:
    cfg = load_training_config()
    assert cfg.selection_primary_metric == SELECTION_PRIMARY_METRIC == "mean_pr_auc"
    assert tuple(cfg.selection_tiebreak) == SELECTION_TIEBREAK == ("mean_recall", "mean_f1")


def test_select_by_primary_metric() -> None:
    candidates = [
        {"name": "A", "mean_pr_auc": 0.7, "mean_recall": 0.9, "mean_f1": 0.9},
        {"name": "B", "mean_pr_auc": 0.8, "mean_recall": 0.1, "mean_f1": 0.1},
    ]
    assert select_best_model(candidates) == "B"  # maior PR-AUC vence


def test_select_tiebreak_recall() -> None:
    candidates = [
        {"name": "A", "mean_pr_auc": 0.7, "mean_recall": 0.6, "mean_f1": 0.9},
        {"name": "B", "mean_pr_auc": 0.7, "mean_recall": 0.8, "mean_f1": 0.1},
    ]
    assert select_best_model(candidates) == "B"  # empate PR-AUC -> recall


def test_select_tiebreak_f1() -> None:
    candidates = [
        {"name": "A", "mean_pr_auc": 0.7, "mean_recall": 0.8, "mean_f1": 0.5},
        {"name": "B", "mean_pr_auc": 0.7, "mean_recall": 0.8, "mean_f1": 0.6},
    ]
    assert select_best_model(candidates) == "B"  # empate PR-AUC e recall -> F1


def test_select_empty_raises() -> None:
    with pytest.raises(ValueError):
        select_best_model([])


def test_select_missing_key_raises() -> None:
    with pytest.raises(ValueError):
        select_best_model([{"name": "A", "mean_pr_auc": 0.7}])


def test_golden_rule_documented() -> None:
    """A regra de ouro do test set está explicitada no docstring do protocolo."""
    import meu_bebe_ml.evaluation.protocol as protocol

    doc = protocol.__doc__
    assert doc is not None
    assert "REGRA DE OURO DO TEST SET" in doc
    assert "TRAIN + CV" in doc
