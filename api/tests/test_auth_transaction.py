"""Testes de transação (FASE 8C) — repository sem commit; service commit/rollback.

Sem banco: usam ``mock`` para verificar a política congelada na 8B (seção 16 do
plano): repository NÃO committa; o service é dono de ``commit``/``rollback``.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone
from unittest import mock

import pytest
from sqlalchemy.exc import IntegrityError, OperationalError

from meu_bebe_api.auth.errors import AuthError
from meu_bebe_api.auth.service import AuthService
from meu_bebe_api.config import Settings
from meu_bebe_api.models.auth_refresh_session import AuthRefreshSession
from meu_bebe_api.models.user import User
from meu_bebe_api.repositories.auth_refresh_session_repository import (
    AuthRefreshSessionRepository,
)
from meu_bebe_api.repositories.user_repository import UserRepository


def _settings() -> Settings:
    return Settings(jwt_secret="x" * 40, _env_file=None)


def test_user_repository_add_does_not_commit() -> None:
    session = mock.MagicMock()
    repo = UserRepository(session)
    user = User(email="a@b.com", password_hash="hash")
    repo.add(user)
    session.add.assert_called_once_with(user)
    session.commit.assert_not_called()
    session.flush.assert_not_called()


def test_refresh_session_repository_revoke_does_not_commit() -> None:
    session = mock.MagicMock()
    repo = AuthRefreshSessionRepository(session)
    sess = AuthRefreshSession(
        user_id=uuid.uuid4(), jti=uuid.uuid4(), expires_at=datetime.now(timezone.utc)
    )
    now = datetime.now(timezone.utc)
    repo.revoke(sess, now)
    assert sess.revoked_at == now
    session.commit.assert_not_called()


def test_service_register_commits_on_success() -> None:
    session = mock.MagicMock()
    session.scalar.return_value = None  # find_by_email → sem duplicado
    service = AuthService(_settings(), session)
    result = service.register("a@b.com", "senha-forte")
    session.commit.assert_called_once()
    assert result.user.email == "a@b.com"
    assert result.access_token
    assert result.refresh_token


def test_service_register_rolls_back_on_integrity_error() -> None:
    session = mock.MagicMock()
    session.scalar.return_value = None
    session.commit.side_effect = IntegrityError("INSERT", {}, Exception("dup"))
    service = AuthService(_settings(), session)
    with pytest.raises(AuthError) as exc_info:
        service.register("a@b.com", "senha-forte")
    assert exc_info.value.code == "DUPLICATE_EMAIL"
    session.rollback.assert_called()


def test_service_register_rolls_back_on_operational_error() -> None:
    session = mock.MagicMock()
    session.scalar.return_value = None
    session.commit.side_effect = OperationalError("SELECT", {}, Exception("conn"))
    service = AuthService(_settings(), session)
    with pytest.raises(AuthError) as exc_info:
        service.register("a@b.com", "senha-forte")
    assert exc_info.value.code == "DATABASE_UNAVAILABLE"
    session.rollback.assert_called()
