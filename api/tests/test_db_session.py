"""Testes da Session factory + dependency ``get_session`` (FASE 8B).

Política congelada: uma ``Session`` por request; a dependency faz ``yield`` e
fecha em ``finally``; NÃO faz commit automático nem esconde rollback.
"""

from __future__ import annotations

from unittest import mock

import pytest
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from meu_bebe_api.db.session import build_session_factory, get_session


class _FakeState:
    def __init__(self, factory: sessionmaker[Session] | None) -> None:
        self.session_factory = factory


class _FakeApp:
    def __init__(self, factory: sessionmaker[Session] | None) -> None:
        self.state = _FakeState(factory)


class _FakeRequest:
    def __init__(self, factory: sessionmaker[Session] | None) -> None:
        self.app = _FakeApp(factory)


def test_build_session_factory_none_when_no_engine() -> None:
    assert build_session_factory(None) is None


def test_build_session_factory_returns_sessionmaker(unreachable_engine: Engine) -> None:
    factory = build_session_factory(unreachable_engine)
    assert factory is not None
    assert isinstance(factory, sessionmaker)


def test_get_session_raises_when_no_factory() -> None:
    """Sem ``session_factory`` no ``app.state``, a dependency falha de forma
    explícita (nunca devolve uma sessão inválida)."""
    gen = get_session(_FakeRequest(None))  # type: ignore[arg-type]
    with pytest.raises(RuntimeError, match="session_factory"):
        next(gen)


def test_get_session_yields_a_session(unreachable_engine: Engine) -> None:
    factory = build_session_factory(unreachable_engine)
    gen = get_session(_FakeRequest(factory))  # type: ignore[arg-type]
    session = next(gen)
    assert isinstance(session, Session)
    gen.close()


def test_get_session_closes_in_finally(unreachable_engine: Engine) -> None:
    """O ``close()`` acontece no ``finally`` — inclusive ao encerrar o generator."""
    factory = build_session_factory(unreachable_engine)
    gen = get_session(_FakeRequest(factory))  # type: ignore[arg-type]
    session = next(gen)

    with mock.patch.object(session, "close", wraps=session.close) as spy:
        gen.close()
        spy.assert_called_once()


def test_get_session_closes_even_on_exception(unreachable_engine: Engine) -> None:
    """Mesmo se o corpo levantar, o ``finally`` fecha a sessão."""
    factory = build_session_factory(unreachable_engine)
    gen = get_session(_FakeRequest(factory))  # type: ignore[arg-type]
    session = next(gen)

    with mock.patch.object(session, "close", wraps=session.close) as spy:
        with pytest.raises(ValueError):
            gen.throw(ValueError("erro simulado"))
        spy.assert_called_once()


def test_get_session_does_not_commit_automatically(unreachable_engine: Engine) -> None:
    """A dependency NÃO executa commit: apenas fornece e fecha a sessão."""
    factory = build_session_factory(unreachable_engine)
    gen = get_session(_FakeRequest(factory))  # type: ignore[arg-type]
    session = next(gen)
    with mock.patch.object(session, "commit") as commit_spy:
        gen.close()
        commit_spy.assert_not_called()
