"""Testes HTTP de AVALIAÇÃO DSS SEM banco (FASE 8I) — fail-closed.

Sem PostgreSQL real, verificam:
- ``JWT_SECRET`` ausente → 503 ``AUTH_NOT_CONFIGURED`` (auth inerte).
- ``DATABASE_URL`` ausente (com secret) → 503 ``DATABASE_UNAVAILABLE``.
- Existência das rotas (503 em vez de 404): o router está registrado.

A avaliação DSS é APPEND-ONLY por gestação: exatamente 3 rotas (POST, GET lista,
GET item). NÃO há PUT (imutável) nem DELETE — o app nunca edita/remove snapshots.
"""

from __future__ import annotations

import uuid

from fastapi.testclient import TestClient

from meu_bebe_api.config import Settings
from meu_bebe_api.main import create_app

from tests._auth_test_support import TEST_JWT_SECRET
from tests.conftest import UNREACHABLE_DATABASE_URL, make_valid_payload


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


def _id() -> str:
    return str(uuid.uuid4())


def test_avaliacoes_dss_routes_auth_not_configured_503() -> None:
    base = f"/api/v1/gestacoes/{_id()}/avaliacoes-dss"
    with _client(_not_configured()) as c:
        assert c.get(base).status_code == 503
        assert c.post(base, json=make_valid_payload()).status_code == 503
        assert c.get(f"{base}/{_id()}").status_code == 503


def test_avaliacoes_dss_database_unavailable_503() -> None:
    with _client(_db_unavailable()) as c:
        r = c.get(f"/api/v1/gestacoes/{_id()}/avaliacoes-dss")
    assert r.status_code == 503
    _assert_nested_503(r.json(), "DATABASE_UNAVAILABLE")


def test_avaliacoes_dss_endpoints_exist_not_404() -> None:
    """Sem config, as rotas respondem 503 (não 404): router registrado."""
    base = f"/api/v1/gestacoes/{_id()}/avaliacoes-dss"
    with _client(_not_configured()) as c:
        assert c.get(base).status_code == 503
        assert c.post(base, json=make_valid_payload()).status_code == 503
        assert c.get(f"{base}/{_id()}").status_code == 503
