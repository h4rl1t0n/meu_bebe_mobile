"""Testes do probe de disponibilidade do PostgreSQL (FASE 8B).

O probe é uma função de infraestrutura (``SELECT 1``) separada de ``/health`` e
``/ready``; retorna um bool controlado e NUNCA levanta exceção.
"""

from __future__ import annotations

from sqlalchemy.engine import Engine

from meu_bebe_api.db.probe import probe_database


def test_probe_none_engine_returns_false() -> None:
    """Persistência inerte (sem engine) → indisponível (controlado)."""
    assert probe_database(None) is False


def test_probe_unreachable_database_returns_false(unreachable_engine: Engine) -> None:
    """PostgreSQL indisponível → ``False``, sem levantar exceção."""
    assert probe_database(unreachable_engine) is False


def test_probe_result_is_controlled_bool() -> None:
    """O resultado é sempre um bool (nunca exceção, nunca dado sensível)."""
    assert isinstance(probe_database(None), bool)
