"""Testes do lifecycle do Engine/SessionFactory (FASE 8B-AUDIT-FIX L-1).

Garantem o encerramento explícito dos recursos de persistência:
- engine existente → ``engine.dispose()`` é chamado no shutdown;
- ausência de Engine (``DATABASE_URL=None``) → shutdown permanece seguro.

Não exigem PostgreSQL real: usam ``mock``/spy sobre ``build_engine``.
"""

from __future__ import annotations

import asyncio
from unittest import mock

from meu_bebe_api.config import Settings
from meu_bebe_api.main import create_app
from tests.conftest import UNREACHABLE_DATABASE_URL


def _run_lifespan(app) -> None:
    """Executa o lifespan (startup → yield → shutdown) de forma síncrona."""

    async def scenario() -> None:
        async with app.router.lifespan_context(app):
            pass

    asyncio.run(scenario())


def test_lifespan_disposes_engine_on_shutdown() -> None:
    """L-1: engine existente → ``dispose()`` é chamado exatamente uma vez."""
    fake_engine = mock.MagicMock()
    settings = Settings(
        database_url=UNREACHABLE_DATABASE_URL,
        model_load_on_startup=False,
        _env_file=None,
    )
    app = create_app(settings)

    with mock.patch(
        "meu_bebe_api.main.build_engine", return_value=fake_engine
    ), mock.patch(
        "meu_bebe_api.main.build_session_factory", return_value=mock.MagicMock()
    ):
        _run_lifespan(app)

    fake_engine.dispose.assert_called_once()


def test_lifespan_without_engine_shutdown_is_safe() -> None:
    """L-1: sem Engine (``DATABASE_URL=None``) o shutdown NÃO falha."""
    settings = Settings(model_load_on_startup=False, _env_file=None)
    app = create_app(settings)

    with mock.patch(
        "meu_bebe_api.main.build_engine", return_value=None
    ), mock.patch(
        "meu_bebe_api.main.build_session_factory", return_value=None
    ):
        _run_lifespan(app)  # não deve levantar exceção
