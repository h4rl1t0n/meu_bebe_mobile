"""Testes de integração de CONSULTA/EXAME com PostgreSQL REAL (FASE 8F).

Cobre: CRUD de lista aninhada em GESTAÇÃO, ownership entre usuárias (A/B),
gestação inexistente/alheia, rejeição de IDs proibidos no body (``gestacao_id``,
``user_id``, ``id``), validações, timestamps, a 1ª ultrassonografia como EXAME
(``categoria="ultrassom"``) e regressões de auth/8D/8E/DSS. Banco dedicado
``meu_bebe_test``; nunca SQLite.
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


def _consulta_payload(**overrides) -> dict:
    payload = {
        "titulo": "Pré-natal",
        "data_consulta": "2025-06-15",
        "descricao": "Consulta de rotina",
    }
    payload.update(overrides)
    return payload


def _exame_payload(**overrides) -> dict:
    payload = {
        "titulo": "Ultrassonografia",
        "data_exame": "2025-06-15",
        "descricao": "Primeira USG",
        "categoria": "ultrassom",
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


def _consulta_base(gestacao_id: str) -> str:
    return f"/api/v1/gestacoes/{gestacao_id}/consultas"


def _exame_base(gestacao_id: str) -> str:
    return f"/api/v1/gestacoes/{gestacao_id}/exames"


# ------------------------------------------------------------ CONSULTA (CRUD)
def test_consulta_create_201(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.post(_consulta_base(gid), json=_consulta_payload(), headers=_bearer(access))
    assert r.status_code == 201
    body = r.json()
    assert body["titulo"] == "Pré-natal"
    assert body["data_consulta"] == "2025-06-15"
    assert body["descricao"] == "Consulta de rotina"
    assert body["id"]
    assert body["created_at"] and body["updated_at"]
    # Nunca ecoa o vínculo nem IDs proibidos.
    assert "gestacao_id" not in body
    assert "user_id" not in body
    assert "gestante_id" not in body


def test_consulta_list_and_get(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    c1 = client.post(_consulta_base(gid), json=_consulta_payload(data_consulta="2025-06-15"), headers=_bearer(access)).json()
    c2 = client.post(_consulta_base(gid), json=_consulta_payload(titulo="Retorno", data_consulta="2025-07-01"), headers=_bearer(access)).json()

    r = client.get(_consulta_base(gid), headers=_bearer(access))
    assert r.status_code == 200
    ids = [c["id"] for c in r.json()]
    assert ids == [c1["id"], c2["id"]]  # ordenado por data

    got = client.get(f"{_consulta_base(gid)}/{c1['id']}", headers=_bearer(access))
    assert got.status_code == 200
    assert got.json()["id"] == c1["id"]
    assert got.json()["titulo"] == "Pré-natal"


def test_consulta_update_200(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    created = client.post(_consulta_base(gid), json=_consulta_payload(), headers=_bearer(access)).json()
    r = client.put(
        f"{_consulta_base(gid)}/{created['id']}",
        json=_consulta_payload(titulo="Retorno", data_consulta="2025-07-01", descricao="Revisão"),
        headers=_bearer(access),
    )
    assert r.status_code == 200
    body = r.json()
    assert body["id"] == created["id"]
    assert body["titulo"] == "Retorno"
    assert body["data_consulta"] == "2025-07-01"
    assert body["descricao"] == "Revisão"


def test_consulta_delete_204_then_404(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    created = client.post(_consulta_base(gid), json=_consulta_payload(), headers=_bearer(access)).json()
    r = client.delete(f"{_consulta_base(gid)}/{created['id']}", headers=_bearer(access))
    assert r.status_code == 204
    assert client.get(f"{_consulta_base(gid)}/{created['id']}", headers=_bearer(access)).status_code == 404
    assert client.delete(f"{_consulta_base(gid)}/{created['id']}", headers=_bearer(access)).status_code == 404


def test_consulta_inexistente_404(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.get(f"{_consulta_base(gid)}/{uuid.uuid4()}", headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "CONSULTA_NOT_FOUND")


def test_consulta_gestacao_inexistente_404(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_setup_gestacao(client)
    r = client.get(_consulta_base(str(uuid.uuid4())), headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "PREGNANCY_NOT_FOUND")


def test_consulta_ownership_between_users_404(client_engine) -> None:
    client, _ = client_engine
    access_a, gid_a = _register_and_setup_gestacao(client)
    consulta_a = client.post(_consulta_base(gid_a), json=_consulta_payload(), headers=_bearer(access_a)).json()

    # B tem a PRÓPRIA gestação; tentar ler A via a gestação de A → 404 (alheia).
    access_b, gid_b = _register_and_setup_gestacao(client)
    assert client.get(_consulta_base(gid_a), headers=_bearer(access_b)).status_code == 404
    # B também não vê a consulta de A sob a SUA gestação (id pertence a A).
    assert client.get(f"{_consulta_base(gid_b)}/{consulta_a['id']}", headers=_bearer(access_b)).status_code == 404
    # A continua vendo a própria consulta.
    assert client.get(f"{_consulta_base(gid_a)}/{consulta_a['id']}", headers=_bearer(access_a)).status_code == 200


def test_consulta_rejects_forbidden_ids_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    for forbidden in ("gestacao_id", "user_id", "id", "gestante_id"):
        r = client.post(
            _consulta_base(gid),
            json=_consulta_payload(**{forbidden: str(uuid.uuid4())}),
            headers=_bearer(access),
        )
        assert r.status_code == 422, forbidden
        assert r.json()["code"] == "VALIDATION_ERROR"


def test_consulta_validation_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    # data inválida
    r = client.post(_consulta_base(gid), json=_consulta_payload(data_consulta="15/06/2025"), headers=_bearer(access))
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"
    # campo obrigatório ausente
    payload = _consulta_payload()
    del payload["titulo"]
    r = client.post(_consulta_base(gid), json=payload, headers=_bearer(access))
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


def test_consulta_rejects_empty_and_whitespace_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    for override in ({"titulo": ""}, {"titulo": "   "}, {"descricao": ""}, {"descricao": "   "}):
        r = client.post(
            _consulta_base(gid),
            json=_consulta_payload(**override),
            headers=_bearer(access),
        )
        assert r.status_code == 422, override
        assert r.json()["code"] == "VALIDATION_ERROR"


def test_consulta_trims_valid_strings(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.post(
        _consulta_base(gid),
        json=_consulta_payload(
            titulo=" Consulta de rotina ",
            descricao=" Avaliação mensal ",
        ),
        headers=_bearer(access),
    )
    assert r.status_code == 201
    body = r.json()
    assert body["titulo"] == "Consulta de rotina"
    assert body["descricao"] == "Avaliação mensal"


def test_consulta_timestamps(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    created = client.post(_consulta_base(gid), json=_consulta_payload(), headers=_bearer(access)).json()
    updated = client.put(
        f"{_consulta_base(gid)}/{created['id']}",
        json=_consulta_payload(titulo="Retorno"),
        headers=_bearer(access),
    ).json()
    assert updated["id"] == created["id"]
    assert datetime.fromisoformat(updated["created_at"]) == datetime.fromisoformat(created["created_at"])
    assert datetime.fromisoformat(updated["updated_at"]) != datetime.fromisoformat(created["updated_at"])


# ---------------------------------------------------------------- EXAME (CRUD)
def test_exame_create_201(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.post(_exame_base(gid), json=_exame_payload(), headers=_bearer(access))
    assert r.status_code == 201
    body = r.json()
    assert body["titulo"] == "Ultrassonografia"
    assert body["data_exame"] == "2025-06-15"
    assert body["descricao"] == "Primeira USG"
    assert body["categoria"] == "ultrassom"
    assert body["id"]
    assert body["created_at"] and body["updated_at"]
    assert "gestacao_id" not in body
    assert "user_id" not in body


def test_exame_create_sem_categoria_201(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    payload = {k: v for k, v in _exame_payload().items() if k != "categoria"}
    r = client.post(_exame_base(gid), json=payload, headers=_bearer(access))
    assert r.status_code == 201
    assert r.json()["categoria"] is None


def test_exame_primeira_ultrassonografia(client_engine) -> None:
    """A 1ª USG legada é um EXAME com ``categoria="ultrassom"`` (sem campo em GESTAÇÃO)."""
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.post(
        _exame_base(gid),
        json=_exame_payload(titulo="Primeira ultrassonografia", data_exame="2025-03-01", categoria="ultrassom"),
        headers=_bearer(access),
    )
    assert r.status_code == 201
    body = r.json()
    assert body["categoria"] == "ultrassom"
    # A gestação NÃO ganhou ``data_primeira_ultrassom`` (decisão congelada).
    gestacao = client.get(f"/api/v1/gestacoes/{gid}", headers=_bearer(access)).json()
    assert "data_primeira_ultrassom" not in gestacao
    assert "first_ultrasound" not in gestacao


def test_exame_list_get_update_delete(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    e1 = client.post(_exame_base(gid), json=_exame_payload(data_exame="2025-06-15"), headers=_bearer(access)).json()
    e2 = client.post(_exame_base(gid), json=_exame_payload(titulo="Hemograma", data_exame="2025-07-01", categoria=None), headers=_bearer(access)).json()

    r = client.get(_exame_base(gid), headers=_bearer(access))
    assert r.status_code == 200
    assert [e["id"] for e in r.json()] == [e1["id"], e2["id"]]

    updated = client.put(
        f"{_exame_base(gid)}/{e1['id']}",
        json=_exame_payload(titulo="Ultrassom morfológico", data_exame="2025-08-01", categoria="ultrassom"),
        headers=_bearer(access),
    )
    assert updated.status_code == 200
    assert updated.json()["titulo"] == "Ultrassom morfológico"

    assert client.delete(f"{_exame_base(gid)}/{e1['id']}", headers=_bearer(access)).status_code == 204
    assert client.get(f"{_exame_base(gid)}/{e1['id']}", headers=_bearer(access)).status_code == 404


def test_exame_inexistente_404(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.get(f"{_exame_base(gid)}/{uuid.uuid4()}", headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "EXAME_NOT_FOUND")


def test_exame_ownership_between_users_404(client_engine) -> None:
    client, _ = client_engine
    access_a, gid_a = _register_and_setup_gestacao(client)
    exame_a = client.post(_exame_base(gid_a), json=_exame_payload(), headers=_bearer(access_a)).json()
    access_b, gid_b = _register_and_setup_gestacao(client)
    assert client.get(_exame_base(gid_a), headers=_bearer(access_b)).status_code == 404
    assert client.get(f"{_exame_base(gid_b)}/{exame_a['id']}", headers=_bearer(access_b)).status_code == 404
    assert client.get(f"{_exame_base(gid_a)}/{exame_a['id']}", headers=_bearer(access_a)).status_code == 200


def test_exame_rejects_forbidden_ids_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    for forbidden in ("gestacao_id", "user_id", "id", "gestante_id"):
        r = client.post(
            _exame_base(gid),
            json=_exame_payload(**{forbidden: str(uuid.uuid4())}),
            headers=_bearer(access),
        )
        assert r.status_code == 422, forbidden
        assert r.json()["code"] == "VALIDATION_ERROR"


def test_exame_validation_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.post(_exame_base(gid), json=_exame_payload(data_exame="not-a-date"), headers=_bearer(access))
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"
    payload = _exame_payload()
    del payload["descricao"]
    r = client.post(_exame_base(gid), json=payload, headers=_bearer(access))
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


def test_exame_rejects_empty_and_whitespace_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    for override in ({"titulo": ""}, {"titulo": "   "}, {"descricao": ""}, {"descricao": "   "}):
        r = client.post(
            _exame_base(gid),
            json=_exame_payload(**override),
            headers=_bearer(access),
        )
        assert r.status_code == 422, override
        assert r.json()["code"] == "VALIDATION_ERROR"


def test_exame_trims_valid_strings(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.post(
        _exame_base(gid),
        json=_exame_payload(
            titulo=" Exame de rotina ",
            descricao=" Avaliação mensal ",
        ),
        headers=_bearer(access),
    )
    assert r.status_code == 201
    body = r.json()
    assert body["titulo"] == "Exame de rotina"
    assert body["descricao"] == "Avaliação mensal"


# -------------------------------------------------------------- REGRESSÕES
def test_auth_regression_register_login_me_refresh_logout(client_engine) -> None:
    client, _ = client_engine
    email = _unique_email()
    reg = _register(client, email=email)
    assert reg.status_code == 201
    login = client.post("/api/v1/auth/login", json={"email": email, "password": "senha-forte-123"})
    assert login.status_code == 200
    access = login.json()["access_token"]
    refresh = login.json()["refresh_token"]
    assert client.get("/api/v1/auth/me", headers=_bearer(access)).status_code == 200
    assert client.post("/api/v1/auth/refresh", json={"refresh_token": refresh}).status_code == 200
    assert client.post("/api/v1/auth/logout", json={"refresh_token": refresh}).status_code == 204


def test_8d_regression_gestante_gestacao(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    assert client.get("/api/v1/gestantes/me", headers=_bearer(access)).status_code == 200
    assert client.get(f"/api/v1/gestacoes/{gid}", headers=_bearer(access)).status_code == 200
    # consulta/exame convivem com a gestação já criada.
    assert client.post(_consulta_base(gid), json=_consulta_payload(), headers=_bearer(access)).status_code == 201


def test_8e_regression_historico_obstetrico(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_setup_gestacao(client)
    r = client.put(
        "/api/v1/gestantes/me/historico-obstetrico",
        json={"pregnancy_number": 2, "given_birth_number": 1, "abortions_number": 0},
        headers=_bearer(access),
    )
    assert r.status_code == 200
    assert client.get("/api/v1/gestantes/me/historico-obstetrico", headers=_bearer(access)).status_code == 200


def test_dss_regression_health_and_risk_estimate(client_engine) -> None:
    client, _ = client_engine
    assert client.get("/health").status_code == 200
    r = client.post("/api/v1/risk-estimate", json=make_valid_payload())
    assert r.status_code == 503
    assert r.json()["error"]["code"] == "MODEL_NOT_READY"
