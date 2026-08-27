"""Testes HTTP de HISTÓRICO OBSTÉTRICO SEM banco (FASE 8E) — fail-closed.

Sem PostgreSQL real, verificam:
- ``JWT_SECRET`` ausente → 503 ``AUTH_NOT_CONFIGURED`` (auth inerte).
- ``DATABASE_URL`` ausente (com secret) → 503 ``DATABASE_UNAVAILABLE``.
- Existência das rotas (503 em vez de 404): o router está registrado.
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


_HISTORICO = {
    "pregnancy_number": 2,
    "given_birth_number": 1,
    "abortions_number": 0,
}


def test_historico_get_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.get("/api/v1/gestantes/me/historico-obstetrico")
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_historico_put_auth_not_configured_503() -> None:
    with _client(_not_configured()) as c:
        r = c.put("/api/v1/gestantes/me/historico-obstetrico", json=_HISTORICO)
    assert r.status_code == 503
    _assert_nested_503(r.json(), "AUTH_NOT_CONFIGURED")


def test_historico_put_database_unavailable_503() -> None:
    with _client(_db_unavailable()) as c:
        r = c.put("/api/v1/gestantes/me/historico-obstetrico", json=_HISTORICO)
    assert r.status_code == 503
    _assert_nested_503(r.json(), "DATABASE_UNAVAILABLE")


def test_historico_endpoints_exist_not_404() -> None:
    """Sem config, as rotas respondem 503 (não 404): router registrado."""
    with _client(_not_configured()) as c:
        assert c.get("/api/v1/gestantes/me/historico-obstetrico").status_code == 503
        assert (
            c.put("/api/v1/gestantes/me/historico-obstetrico", json=_HISTORICO).status_code
            == 503
        )
