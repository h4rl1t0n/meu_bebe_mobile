"""Testes HTTP de CONSULTA/EXAME SEM banco (FASE 8F) — fail-closed.

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


_CONSULTA = {
    "titulo": "Pré-natal",
    "data_consulta": "2025-06-15",
    "descricao": "Consulta de rotina",
}

_EXAME = {
    "titulo": "Ultrassonografia",
    "data_exame": "2025-06-15",
    "descricao": "Primeira USG",
    "categoria": "ultrassom",
}


def _gestacao_id() -> str:
    return str(uuid.uuid4())


def test_consulta_routes_auth_not_configured_503() -> None:
    gid = _gestacao_id()
    base = f"/api/v1/gestacoes/{gid}/consultas"
    with _client(_not_configured()) as c:
        assert c.get(base).status_code == 503
        assert c.post(base, json=_CONSULTA).status_code == 503
        assert c.get(f"{base}/{_gestacao_id()}").status_code == 503
        assert c.put(f"{base}/{_gestacao_id()}", json=_CONSULTA).status_code == 503
        assert c.delete(f"{base}/{_gestacao_id()}").status_code == 503


def test_exame_routes_auth_not_configured_503() -> None:
    gid = _gestacao_id()
    base = f"/api/v1/gestacoes/{gid}/exames"
    with _client(_not_configured()) as c:
        assert c.get(base).status_code == 503
        assert c.post(base, json=_EXAME).status_code == 503
        assert c.get(f"{base}/{_gestacao_id()}").status_code == 503
        assert c.put(f"{base}/{_gestacao_id()}", json=_EXAME).status_code == 503
        assert c.delete(f"{base}/{_gestacao_id()}").status_code == 503


def test_consulta_database_unavailable_503() -> None:
    with _client(_db_unavailable()) as c:
        r = c.get(f"/api/v1/gestacoes/{_gestacao_id()}/consultas")
    assert r.status_code == 503
    _assert_nested_503(r.json(), "DATABASE_UNAVAILABLE")


def test_exame_database_unavailable_503() -> None:
    with _client(_db_unavailable()) as c:
        r = c.get(f"/api/v1/gestacoes/{_gestacao_id()}/exames")
    assert r.status_code == 503
    _assert_nested_503(r.json(), "DATABASE_UNAVAILABLE")


def test_endpoints_exist_not_404() -> None:
    """Sem config, as rotas respondem 503 (não 404): routers registrados."""
    gid = _gestacao_id()
    with _client(_not_configured()) as c:
        assert c.get(f"/api/v1/gestacoes/{gid}/consultas").status_code == 503
        assert c.get(f"/api/v1/gestacoes/{gid}/exames").status_code == 503
        assert (
            c.post(f"/api/v1/gestacoes/{gid}/consultas", json=_CONSULTA).status_code
            == 503
        )
        assert (
            c.post(f"/api/v1/gestacoes/{gid}/exames", json=_EXAME).status_code
            == 503
        )
