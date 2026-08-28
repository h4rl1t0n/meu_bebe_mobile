"""Testes de integração de MEDICAMENTO/VACINA com PostgreSQL REAL (FASE 8G).

Cobre: CRUD de lista aninhada em GESTAÇÃO, ownership entre usuárias (A/B),
gestação inexistente/alheia, rejeição de IDs proibidos no body, validações,
timestamps, toggle de ``aplicada`` (o ``used`` do Flutter), a AUSÊNCIA de DELETE
em vacina, e regressões leves de auth/8D. Banco dedicado ``meu_bebe_test``;
nunca SQLite.
"""

from __future__ import annotations

import uuid
from datetime import datetime

import pytest
from fastapi.testclient import TestClient

from meu_bebe_api.config import Settings
from meu_bebe_api.db.base import Base
from meu_bebe_api.main import create_app

from tests._auth_test_support import (
    TEST_JWT_SECRET,
    build_test_engine,
    get_test_database_url,
    postgres_ready,
    reset_schema,
)
from tests.conftest import make_valid_payload


def _require_postgres() -> str:
    if not postgres_ready():
        pytest.skip("TEST_DATABASE_URL não definida / PostgreSQL indisponível")
    return get_test_database_url()


@pytest.fixture(scope="module")
def client_engine():
    url = _require_postgres()
    engine = build_test_engine()
    reset_schema(engine)
    Base.metadata.create_all(engine)
    settings = Settings(
        database_url=url,
        jwt_secret=TEST_JWT_SECRET,
        model_load_on_startup=False,
        _env_file=None,
    )
    app = create_app(settings)
    with TestClient(app) as client:
        yield client, engine
    Base.metadata.drop_all(engine)
    engine.dispose()


def _unique_email() -> str:
    return f"user-{uuid.uuid4().hex}@example.com"


def _register(client, email=None, password="senha-forte-123"):
    email = email or _unique_email()
    return client.post("/api/v1/auth/register", json={"email": email, "password": password})


def _bearer(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def _flat_error(body: dict, code: str) -> None:
    assert set(body) == {"code", "message", "details"}
    assert body["code"] == code
    assert body["details"] == []


def _gestante_payload(**overrides) -> dict:
    payload = {
        "nome": "Maria da Silva",
        "nome_social": None,
        "data_nascimento": "1990-05-20",
        "cpf": "12345678900",
        "cns": "123456789012345",
    }
    payload.update(overrides)
    return payload


def _medicamento_payload(**overrides) -> dict:
    payload = {
        "nome": "Ácido fólico",
        "dose": "5mg",
        "frequencia": "1 vez ao dia",
    }
    payload.update(overrides)
    return payload


def _vacina_payload(**overrides) -> dict:
    payload = {
        "nome": "dTpa",
        "aplicada": False,
    }
    payload.update(overrides)
    return payload


def _register_and_setup_gestacao(client, email=None):
    """Registra USER, cria GESTANTE e GESTAÇÃO ativa; retorna (access, gestacao_id)."""
    access = _register(client, email=email).json()["access_token"]
    r = client.post("/api/v1/gestantes/me", json=_gestante_payload(), headers=_bearer(access))
    assert r.status_code == 201
    r = client.post(
        "/api/v1/gestacoes",
        json={"data_ultima_menstruacao": "2025-01-10"},
        headers=_bearer(access),
    )
    assert r.status_code == 201
    return access, r.json()["id"]


def _medicamento_base(gestacao_id: str) -> str:
    return f"/api/v1/gestacoes/{gestacao_id}/medicamentos"


def _vacina_base(gestacao_id: str) -> str:
    return f"/api/v1/gestacoes/{gestacao_id}/vacinas"


# ------------------------------------------------------------ MEDICAMENTO (CRUD)
def test_medicamento_create_201(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.post(_medicamento_base(gid), json=_medicamento_payload(), headers=_bearer(access))
    assert r.status_code == 201
    body = r.json()
    assert body["nome"] == "Ácido fólico"
    assert body["dose"] == "5mg"
    assert body["frequencia"] == "1 vez ao dia"
    assert body["id"]
    assert body["created_at"] and body["updated_at"]
    # Nunca ecoa o vínculo nem IDs proibidos.
    assert "gestacao_id" not in body
    assert "user_id" not in body
    assert "gestante_id" not in body


def test_medicamento_list_ordered_by_nome(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    m1 = client.post(_medicamento_base(gid), json=_medicamento_payload(nome="Zinco"), headers=_bearer(access)).json()
    m2 = client.post(_medicamento_base(gid), json=_medicamento_payload(nome="Ácido fólico"), headers=_bearer(access)).json()

    r = client.get(_medicamento_base(gid), headers=_bearer(access))
    assert r.status_code == 200
    ids = [m["id"] for m in r.json()]
    assert ids == [m2["id"], m1["id"]]  # ordenado alfabeticamente por nome

    got = client.get(f"{_medicamento_base(gid)}/{m1['id']}", headers=_bearer(access))
    assert got.status_code == 200
    assert got.json()["id"] == m1["id"]
    assert got.json()["nome"] == "Zinco"


def test_medicamento_update_200(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    created = client.post(_medicamento_base(gid), json=_medicamento_payload(), headers=_bearer(access)).json()
    r = client.put(
        f"{_medicamento_base(gid)}/{created['id']}",
        json=_medicamento_payload(nome="Sulfato ferroso", dose="40mg", frequencia="2 vezes ao dia"),
        headers=_bearer(access),
    )
    assert r.status_code == 200
    body = r.json()
    assert body["id"] == created["id"]
    assert body["nome"] == "Sulfato ferroso"
    assert body["dose"] == "40mg"
    assert body["frequencia"] == "2 vezes ao dia"


def test_medicamento_delete_204_then_404(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    created = client.post(_medicamento_base(gid), json=_medicamento_payload(), headers=_bearer(access)).json()
    r = client.delete(f"{_medicamento_base(gid)}/{created['id']}", headers=_bearer(access))
    assert r.status_code == 204
    assert client.get(f"{_medicamento_base(gid)}/{created['id']}", headers=_bearer(access)).status_code == 404
    assert client.delete(f"{_medicamento_base(gid)}/{created['id']}", headers=_bearer(access)).status_code == 404


def test_medicamento_inexistente_404(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.get(f"{_medicamento_base(gid)}/{uuid.uuid4()}", headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "MEDICAMENTO_NOT_FOUND")


def test_medicamento_gestacao_inexistente_404(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_setup_gestacao(client)
    r = client.get(_medicamento_base(str(uuid.uuid4())), headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "PREGNANCY_NOT_FOUND")


def test_medicamento_ownership_between_users_404(client_engine) -> None:
    client, _ = client_engine
    access_a, gid_a = _register_and_setup_gestacao(client)
    medicamento_a = client.post(_medicamento_base(gid_a), json=_medicamento_payload(), headers=_bearer(access_a)).json()

    access_b, gid_b = _register_and_setup_gestacao(client)
    assert client.get(_medicamento_base(gid_a), headers=_bearer(access_b)).status_code == 404
    assert client.get(f"{_medicamento_base(gid_b)}/{medicamento_a['id']}", headers=_bearer(access_b)).status_code == 404
    assert client.get(f"{_medicamento_base(gid_a)}/{medicamento_a['id']}", headers=_bearer(access_a)).status_code == 200


def test_medicamento_rejects_forbidden_ids_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    for forbidden in ("gestacao_id", "user_id", "id", "gestante_id"):
        r = client.post(
            _medicamento_base(gid),
            json=_medicamento_payload(**{forbidden: str(uuid.uuid4())}),
            headers=_bearer(access),
        )
        assert r.status_code == 422, forbidden
        assert r.json()["code"] == "VALIDATION_ERROR"


def test_medicamento_validation_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    # campo obrigatório ausente
    payload = _medicamento_payload()
    del payload["dose"]
    r = client.post(_medicamento_base(gid), json=payload, headers=_bearer(access))
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


def test_medicamento_rejects_empty_and_whitespace_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    for override in (
        {"nome": ""}, {"nome": "   "},
        {"dose": ""}, {"dose": "   "},
        {"frequencia": ""}, {"frequencia": "   "},
    ):
        r = client.post(
            _medicamento_base(gid),
            json=_medicamento_payload(**override),
            headers=_bearer(access),
        )
        assert r.status_code == 422, override
        assert r.json()["code"] == "VALIDATION_ERROR"


def test_medicamento_trims_valid_strings(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.post(
        _medicamento_base(gid),
        json=_medicamento_payload(
            nome=" Ácido fólico ",
            dose=" 5mg ",
            frequencia=" 1 vez ao dia ",
        ),
        headers=_bearer(access),
    )
    assert r.status_code == 201
    body = r.json()
    assert body["nome"] == "Ácido fólico"
    assert body["dose"] == "5mg"
    assert body["frequencia"] == "1 vez ao dia"


def test_medicamento_timestamps(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    created = client.post(_medicamento_base(gid), json=_medicamento_payload(), headers=_bearer(access)).json()
    updated = client.put(
        f"{_medicamento_base(gid)}/{created['id']}",
        json=_medicamento_payload(nome="Sulfato ferroso"),
        headers=_bearer(access),
    ).json()
    assert updated["id"] == created["id"]
    assert datetime.fromisoformat(updated["created_at"]) == datetime.fromisoformat(created["created_at"])
    assert datetime.fromisoformat(updated["updated_at"]) != datetime.fromisoformat(created["updated_at"])


# ---------------------------------------------------------------- VACINA (CRUD)
def test_vacina_create_201(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.post(_vacina_base(gid), json=_vacina_payload(), headers=_bearer(access))
    assert r.status_code == 201
    body = r.json()
    assert body["nome"] == "dTpa"
    assert body["aplicada"] is False
    assert body["id"]
    assert body["created_at"] and body["updated_at"]
    assert "gestacao_id" not in body
    assert "user_id" not in body


def test_vacina_toggle_aplicada(client_engine) -> None:
    """O checklist alterna ``aplicada`` (o ``used`` do Flutter) via PUT."""
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    created = client.post(_vacina_base(gid), json=_vacina_payload(nome="HB_1"), headers=_bearer(access)).json()
    assert created["aplicada"] is False

    toggled = client.put(
        f"{_vacina_base(gid)}/{created['id']}",
        json=_vacina_payload(nome="HB_1", aplicada=True),
        headers=_bearer(access),
    )
    assert toggled.status_code == 200
    assert toggled.json()["aplicada"] is True

    got = client.get(f"{_vacina_base(gid)}/{created['id']}", headers=_bearer(access))
    assert got.status_code == 200
    assert got.json()["aplicada"] is True


def test_vacina_list_ordered_by_creation(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    v1 = client.post(_vacina_base(gid), json=_vacina_payload(nome="HB_1"), headers=_bearer(access)).json()
    v2 = client.post(_vacina_base(gid), json=_vacina_payload(nome="dTpa"), headers=_bearer(access)).json()

    r = client.get(_vacina_base(gid), headers=_bearer(access))
    assert r.status_code == 200
    ids = [v["id"] for v in r.json()]
    assert ids == [v1["id"], v2["id"]]  # ordem de criação


def test_vacina_inexistente_404(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.get(f"{_vacina_base(gid)}/{uuid.uuid4()}", headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "VACINA_NOT_FOUND")


def test_vacina_ownership_between_users_404(client_engine) -> None:
    client, _ = client_engine
    access_a, gid_a = _register_and_setup_gestacao(client)
    vacina_a = client.post(_vacina_base(gid_a), json=_vacina_payload(), headers=_bearer(access_a)).json()
    access_b, gid_b = _register_and_setup_gestacao(client)
    assert client.get(_vacina_base(gid_a), headers=_bearer(access_b)).status_code == 404
    assert client.get(f"{_vacina_base(gid_b)}/{vacina_a['id']}", headers=_bearer(access_b)).status_code == 404
    assert client.get(f"{_vacina_base(gid_a)}/{vacina_a['id']}", headers=_bearer(access_a)).status_code == 200


def test_vacina_rejects_forbidden_ids_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    for forbidden in ("gestacao_id", "user_id", "id", "gestante_id"):
        r = client.post(
            _vacina_base(gid),
            json=_vacina_payload(**{forbidden: str(uuid.uuid4())}),
            headers=_bearer(access),
        )
        assert r.status_code == 422, forbidden
        assert r.json()["code"] == "VALIDATION_ERROR"


def test_vacina_validation_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    # aplicada ausente (bool obrigatório)
    payload = _vacina_payload()
    del payload["aplicada"]
    r = client.post(_vacina_base(gid), json=payload, headers=_bearer(access))
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"
    # aplicada de tipo errado (não-string não-bool)
    r = client.post(_vacina_base(gid), json=_vacina_payload(aplicada="sim"), headers=_bearer(access))
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


def test_vacina_rejects_empty_and_whitespace_nome_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    for override in ({"nome": ""}, {"nome": "   "}):
        r = client.post(
            _vacina_base(gid),
            json=_vacina_payload(**override),
            headers=_bearer(access),
        )
        assert r.status_code == 422, override
        assert r.json()["code"] == "VALIDATION_ERROR"


def test_vacina_no_delete_route_405(client_engine) -> None:
    """Vacina NÃO tem DELETE: o Flutter não remove vacina (checklist)."""
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    created = client.post(_vacina_base(gid), json=_vacina_payload(), headers=_bearer(access)).json()
    r = client.delete(f"{_vacina_base(gid)}/{created['id']}", headers=_bearer(access))
    assert r.status_code == 405


# -------------------------------------------------------------- REGRESSÕES
def test_regression_auth_and_8d_coexist(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    assert client.get("/api/v1/auth/me", headers=_bearer(access)).status_code == 200
    assert client.get("/api/v1/gestantes/me", headers=_bearer(access)).status_code == 200
    assert client.get(f"/api/v1/gestacoes/{gid}", headers=_bearer(access)).status_code == 200
    # medicamento/vacina convivem com a gestação já criada.
    assert client.post(_medicamento_base(gid), json=_medicamento_payload(), headers=_bearer(access)).status_code == 201
    assert client.post(_vacina_base(gid), json=_vacina_payload(), headers=_bearer(access)).status_code == 201


def test_dss_regression_health_and_risk_estimate(client_engine) -> None:
    client, _ = client_engine
    assert client.get("/health").status_code == 200
    r = client.post("/api/v1/risk-estimate", json=make_valid_payload())
    assert r.status_code == 503
    assert r.json()["error"]["code"] == "MODEL_NOT_READY"
