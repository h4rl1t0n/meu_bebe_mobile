"""Testes HTTP de auth SEM banco (FASE 8C) — indisponibilidade controlada.

Verificam o comportamento fail-closed (plano §17.3) sem PostgreSQL real:
- ``JWT_SECRET`` ausente → 503 ``AUTH_NOT_CONFIGURED`` (auth inerte).
- ``DATABASE_URL`` ausente (com secret presente) → 503 ``DATABASE_UNAVAILABLE``.
- Formato de envelope de erro nested para 5xx e existência das rotas.
"""

from __future__ import annotations

from fastapi.testclient import TestClient

from meu_bebe_api.config import Settings
from meu_bebe_api.main import create_app

from tests._auth_test_support import TEST_JWT_SECRET
from tests.conftest import UNREACHABLE_DATABASE_URL


def _client(settings: Settings) -> TestClient:
    return TestClient(create_app(settings))


def _not_configured() -> Settings:
    return Settings(
        jwt_secret=None,
        database_url=UNREACHABLE_DATABASE_URL,
        model_load_on_startup=False,
        _env_file=None,
    )


def _assert_nested_503(body: dict, code: str) -> None:
    assert set(body) == {"error"}
    assert set(body["error"]) == {"code", "message", "details"}
    assert body["error"]["code"] == code
    assert body["error"]["details"] == []


def test_register_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.post(
            "/api/v1/auth/register",
            json={"email": "a@b.com", "password": "12345678"},
        )
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_login_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.post(
            "/api/v1/auth/login",
            json={"email": "a@b.com", "password": "12345678"},
        )
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_refresh_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.post("/api/v1/auth/refresh", json={"refresh_token": "x"})
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_logout_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.post("/api/v1/auth/logout", json={"refresh_token": "x"})
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_me_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.get("/api/v1/auth/me")
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_register_database_unavailable_503() -> None:
    settings = Settings(
        jwt_secret=TEST_JWT_SECRET,
        database_url=None,
        model_load_on_startup=False,
        _env_file=None,
    )
    with _client(settings) as c:
        r = c.post(
            "/api/v1/auth/register",
            json={"email": "a@b.com", "password": "12345678"},
        )
    assert r.status_code == 503
    _assert_nested_503(r.json(), "DATABASE_UNAVAILABLE")


def test_auth_endpoints_exist_not_404() -> None:
    """Sem config, as rotas respondem 503 (não 404): o router está registrado."""
    with _client(_not_configured()) as c:
        assert (
            c.post("/api/v1/auth/register", json={"email": "a@b.com", "password": "12345678"}).status_code
            == 503
        )
        assert (
            c.post("/api/v1/auth/login", json={"email": "a@b.com", "password": "12345678"}).status_code
            == 503
        )
        assert c.post("/api/v1/auth/refresh", json={"refresh_token": "x"}).status_code == 503
        assert c.post("/api/v1/auth/logout", json={"refresh_token": "x"}).status_code == 503
        assert c.get("/api/v1/auth/me").status_code == 503
