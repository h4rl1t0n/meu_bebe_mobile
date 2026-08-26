"""Testes HTTP de GESTANTE/GESTAÇÃO SEM banco (FASE 8D) — fail-closed.

Sem PostgreSQL real, verificam:
- ``JWT_SECRET`` ausente → 503 ``AUTH_NOT_CONFIGURED`` (auth inerte).
- ``DATABASE_URL`` ausente (com secret) → 503 ``DATABASE_UNAVAILABLE``.
- Existência das rotas (503 em vez de 404): os routers estão registrados.
"""

from __future__ import annotations

import uuid

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


def _db_unavailable() -> Settings:
    return Settings(
        jwt_secret=TEST_JWT_SECRET,
        database_url=None,
        model_load_on_startup=False,
        _env_file=None,
    )


def _assert_nested_503(body: dict, code: str) -> None:
    assert set(body) == {"error"}
    assert set(body["error"]) == {"code", "message", "details"}
    assert body["error"]["code"] == code
    assert body["error"]["details"] == []


_GESTANTE = {
    "nome": "Maria da Silva",
    "data_nascimento": "1990-05-20",
    "cpf": "12345678900",
    "cns": "123456789012345",
}


def _gestacao() -> dict:
    return {"data_ultima_menstruacao": "2025-01-10"}


# ------------------------------------------------------------------ gestantes
def test_gestante_post_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.post("/api/v1/gestantes/me", json=_GESTANTE)
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_gestante_get_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.get("/api/v1/gestantes/me")
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_gestante_put_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.put("/api/v1/gestantes/me", json=_GESTANTE)
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_gestante_post_database_unavailable_503() -> None:
    with _client(_db_unavailable()) as c:
        r = c.post("/api/v1/gestantes/me", json=_GESTANTE)
    assert r.status_code == 503
    _assert_nested_503(r.json(), "DATABASE_UNAVAILABLE")


# ------------------------------------------------------------------- gestações
def test_gestacao_post_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.post("/api/v1/gestacoes", json=_gestacao())
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_gestacao_list_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.get("/api/v1/gestacoes")
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_gestacao_atual_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.get("/api/v1/gestacoes/atual")
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_gestacao_get_by_id_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.get(f"/api/v1/gestacoes/{uuid.uuid4()}")
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_gestacao_put_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.put(f"/api/v1/gestacoes/{uuid.uuid4()}", json=_gestacao())
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_gestacao_post_database_unavailable_503() -> None:
    with _client(_db_unavailable()) as c:
        r = c.post("/api/v1/gestacoes", json=_gestacao())
    assert r.status_code == 503
    _assert_nested_503(r.json(), "DATABASE_UNAVAILABLE")


# --------------------------------------------------------- existência de rotas
def test_gestante_gestacao_endpoints_exist_not_404() -> None:
    """Sem config, as rotas respondem 503 (não 404): routers registrados."""
    with _client(_not_configured()) as c:
        assert c.post("/api/v1/gestantes/me", json=_GESTANTE).status_code == 503
        assert c.get("/api/v1/gestantes/me").status_code == 503
        assert c.put("/api/v1/gestantes/me", json=_GESTANTE).status_code == 503
        assert c.post("/api/v1/gestacoes", json=_gestacao()).status_code == 503
        assert c.get("/api/v1/gestacoes").status_code == 503
        assert c.get("/api/v1/gestacoes/atual").status_code == 503
        assert c.get(f"/api/v1/gestacoes/{uuid.uuid4()}").status_code == 503
        assert c.put(f"/api/v1/gestacoes/{uuid.uuid4()}", json=_gestacao()).status_code == 503
