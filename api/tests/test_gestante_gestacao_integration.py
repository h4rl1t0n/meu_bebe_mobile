"""Testes de integração de GESTANTE/GESTAÇÃO com PostgreSQL REAL (FASE 8D).

Matriz da seção 21: CRUD de perfil, ownership, gestação ativa única,
transição ``ended_at`` (encerrar / proibir reabertura), validações, regressão
de auth e regressão DSS. Banco dedicado ``meu_bebe_test``; nunca SQLite.
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
        "cpf": "123.456.789-00",
        "cns": "123456789012345",
    }
    payload.update(overrides)
    return payload


def _gestacao_payload(**overrides) -> dict:
    payload = {
        "data_ultima_menstruacao": "2025-01-10",
        "local_pre_natal": "UBS Centro",
        "profissional_pre_natal": "Dra. Ana",
        "contato_local_pre_natal": "(92) 99999-0000",
        "ended_at": None,
    }
    payload.update(overrides)
    return payload


def _gestacao_payload_no_ended_at(**overrides) -> dict:
    """Payload SEM a propriedade ``ended_at`` (para testar campo AUSENTE)."""
    payload = _gestacao_payload(**overrides)
    payload.pop("ended_at")
    return payload


def _register_and_create_gestante(client, email=None):
    """Registra um USER e cria o perfil de GESTANTE; retorna (access, gestante)."""
    access = _register(client, email=email).json()["access_token"]
    r = client.post("/api/v1/gestantes/me", json=_gestante_payload(), headers=_bearer(access))
    assert r.status_code == 201
    return access, r.json()


# ------------------------------------------------------------------- GESTANTE
def test_gestante_create_201_normalizes_and_hides_user_id(client_engine) -> None:
    client, _ = client_engine
    access, body = _register_and_create_gestante(client)
    assert body["nome"] == "Maria da Silva"
    assert body["nome_social"] is None
    assert body["data_nascimento"] == "1990-05-20"
    # CPF/CNS normalizados para dígitos.
    assert body["cpf"] == "12345678900"
    assert body["cns"] == "123456789012345"
    assert "user_id" not in body
    assert "password" not in body
    assert body["id"]
    assert body["created_at"] and body["updated_at"]


def test_gestante_get_me_200(client_engine) -> None:
    client, _ = client_engine
    access, created = _register_and_create_gestante(client)
    r = client.get("/api/v1/gestantes/me", headers=_bearer(access))
    assert r.status_code == 200
    assert r.json()["id"] == created["id"]


def test_gestante_put_me_200_full_update(client_engine) -> None:
    client, _ = client_engine
    access, created = _register_and_create_gestante(client)
    r = client.put(
        "/api/v1/gestantes/me",
        json=_gestante_payload(nome="  Maria Souza  ", nome_social="Mari"),
        headers=_bearer(access),
    )
    assert r.status_code == 200
    body = r.json()
    assert body["id"] == created["id"]
    assert body["nome"] == "Maria Souza"
    assert body["nome_social"] == "Mari"


def test_gestante_create_duplicate_409(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    r = client.post("/api/v1/gestantes/me", json=_gestante_payload(), headers=_bearer(access))
    assert r.status_code == 409
    _flat_error(r.json(), "PROFILE_ALREADY_EXISTS")


def test_gestante_me_without_token_401(client_engine) -> None:
    client, _ = client_engine
    assert client.post("/api/v1/gestantes/me", json=_gestante_payload()).status_code == 401
    assert client.get("/api/v1/gestantes/me").status_code == 401
    assert client.put("/api/v1/gestantes/me", json=_gestante_payload()).status_code == 401


def test_gestante_get_me_without_profile_404(client_engine) -> None:
    client, _ = client_engine
    access = _register(client).json()["access_token"]
    r = client.get("/api/v1/gestantes/me", headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "PROFILE_NOT_FOUND")


def test_gestante_create_rejects_user_id_in_body_422(client_engine) -> None:
    client, _ = client_engine
    access = _register(client).json()["access_token"]
    r = client.post(
        "/api/v1/gestantes/me",
        json=_gestante_payload(user_id=str(uuid.uuid4())),
        headers=_bearer(access),
    )
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


def test_gestante_create_future_date_422(client_engine) -> None:
    client, _ = client_engine
    access = _register(client).json()["access_token"]
    r = client.post(
        "/api/v1/gestantes/me",
        json=_gestante_payload(data_nascimento="2999-01-01"),
        headers=_bearer(access),
    )
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


def test_gestante_create_invalid_cpf_422(client_engine) -> None:
    client, _ = client_engine
    access = _register(client).json()["access_token"]
    r = client.post(
        "/api/v1/gestantes/me",
        json=_gestante_payload(cpf="123"),
        headers=_bearer(access),
    )
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


def test_gestante_create_invalid_cns_422(client_engine) -> None:
    client, _ = client_engine
    access = _register(client).json()["access_token"]
    r = client.post(
        "/api/v1/gestantes/me",
        json=_gestante_payload(cns="12345678"),
        headers=_bearer(access),
    )
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


def test_gestante_create_blank_nome_422(client_engine) -> None:
    client, _ = client_engine
    access = _register(client).json()["access_token"]
    r = client.post(
        "/api/v1/gestantes/me",
        json=_gestante_payload(nome="   "),
        headers=_bearer(access),
    )
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


# ------------------------------------------------------------------- GESTAÇÃO
def test_gestacao_create_and_get_atual_and_list(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    r = client.post("/api/v1/gestacoes", json=_gestacao_payload(), headers=_bearer(access))
    assert r.status_code == 201
    gestacao = r.json()
    assert gestacao["ended_at"] is None
    assert gestacao["data_ultima_menstruacao"] == "2025-01-10"
    assert "gestante_id" not in gestacao

    atual = client.get("/api/v1/gestacoes/atual", headers=_bearer(access))
    assert atual.status_code == 200
    assert atual.json()["id"] == gestacao["id"]

    lista = client.get("/api/v1/gestacoes", headers=_bearer(access))
    assert lista.status_code == 200
    assert [g["id"] for g in lista.json()] == [gestacao["id"]]

    detalhe = client.get(f"/api/v1/gestacoes/{gestacao['id']}", headers=_bearer(access))
    assert detalhe.status_code == 200
    assert detalhe.json()["id"] == gestacao["id"]


def test_gestacao_put_updates_fields(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    gid = client.post("/api/v1/gestacoes", json=_gestacao_payload(), headers=_bearer(access)).json()["id"]
    r = client.put(
        f"/api/v1/gestacoes/{gid}",
        json=_gestacao_payload(local_pre_natal="UBS Norte", profissional_pre_natal="Dr. João"),
        headers=_bearer(access),
    )
    assert r.status_code == 200
    body = r.json()
    assert body["id"] == gid
    assert body["local_pre_natal"] == "UBS Norte"
    assert body["profissional_pre_natal"] == "Dr. João"
    assert body["ended_at"] is None


def test_gestacao_second_active_409(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    assert client.post("/api/v1/gestacoes", json=_gestacao_payload(), headers=_bearer(access)).status_code == 201
    r = client.post("/api/v1/gestacoes", json=_gestacao_payload(), headers=_bearer(access))
    assert r.status_code == 409
    _flat_error(r.json(), "ACTIVE_PREGNANCY_ALREADY_EXISTS")


def test_gestacao_encerrar_then_create_nova(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    g1 = client.post("/api/v1/gestacoes", json=_gestacao_payload(), headers=_bearer(access)).json()

    # Encerra G1 via PUT com ended_at.
    r = client.put(
        f"/api/v1/gestacoes/{g1['id']}",
        json=_gestacao_payload(ended_at="2025-06-30T12:00:00Z"),
        headers=_bearer(access),
    )
    assert r.status_code == 200
    assert r.json()["ended_at"] is not None

    # Nova gestação ativa é permitida após encerrar.
    r2 = client.post("/api/v1/gestacoes", json=_gestacao_payload(), headers=_bearer(access))
    assert r2.status_code == 201
    assert r2.json()["ended_at"] is None

    # A "atual" passa a ser a nova.
    atual = client.get("/api/v1/gestacoes/atual", headers=_bearer(access))
    assert atual.status_code == 200
    assert atual.json()["id"] == r2.json()["id"]

    # A lista agora tem 2, em ordem de criação.
    lista = client.get("/api/v1/gestacoes", headers=_bearer(access))
    assert [g["id"] for g in lista.json()] == [g1["id"], r2.json()["id"]]


def test_gestacao_reopen_prohibited_409(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    gid = client.post("/api/v1/gestacoes", json=_gestacao_payload(), headers=_bearer(access)).json()["id"]
    client.put(
        f"/api/v1/gestacoes/{gid}",
        json=_gestacao_payload(ended_at="2025-06-30T12:00:00Z"),
        headers=_bearer(access),
    )
    # Tentativa de reabrir (ended_at -> null) é proibida.
    r = client.put(
        f"/api/v1/gestacoes/{gid}",
        json=_gestacao_payload(ended_at=None),
        headers=_bearer(access),
    )
    assert r.status_code == 409
    _flat_error(r.json(), "PREGNANCY_REOPEN_NOT_ALLOWED")


def test_gestacao_encerrada_put_without_ended_at_preserves_ended_at(client_engine) -> None:
    """CASO 1: encerrada + PUT SEM ``ended_at`` → 200, preserva o encerramento."""
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    gid = client.post("/api/v1/gestacoes", json=_gestacao_payload(), headers=_bearer(access)).json()["id"]
    encerrada = client.put(
        f"/api/v1/gestacoes/{gid}",
        json=_gestacao_payload(ended_at="2025-06-30T12:00:00Z"),
        headers=_bearer(access),
    ).json()
    assert encerrada["ended_at"] is not None

    r = client.put(
        f"/api/v1/gestacoes/{gid}",
        json=_gestacao_payload_no_ended_at(local_pre_natal="UBS Norte", profissional_pre_natal="Dr. João"),
        headers=_bearer(access),
    )
    assert r.status_code == 200
    body = r.json()
    assert body["local_pre_natal"] == "UBS Norte"
    assert body["profissional_pre_natal"] == "Dr. João"
    # ended_at AUSENTE → preserva o valor original (não vira null). O offset da
    # serialização varia (UTC no objeto em memória vs. tz local ao reler do DB),
    # então compara o INSTANTE, não a string.
    assert body["ended_at"] is not None
    assert datetime.fromisoformat(body["ended_at"]) == datetime.fromisoformat(
        encerrada["ended_at"]
    )


def test_gestacao_ativa_put_without_ended_at_stays_active(client_engine) -> None:
    """CASO 3: ativa + PUT SEM ``ended_at`` → permanece ativa."""
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    gid = client.post("/api/v1/gestacoes", json=_gestacao_payload(), headers=_bearer(access)).json()["id"]
    r = client.put(
        f"/api/v1/gestacoes/{gid}",
        json=_gestacao_payload_no_ended_at(local_pre_natal="UBS Sul"),
        headers=_bearer(access),
    )
    assert r.status_code == 200
    body = r.json()
    assert body["ended_at"] is None
    assert body["local_pre_natal"] == "UBS Sul"


def test_gestacao_not_found_404(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    ghost = str(uuid.uuid4())
    assert client.get(f"/api/v1/gestacoes/{ghost}", headers=_bearer(access)).status_code == 404
    assert client.put(f"/api/v1/gestacoes/{ghost}", json=_gestacao_payload(), headers=_bearer(access)).status_code == 404


def test_gestacao_atual_sem_gestacao_404(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    r = client.get("/api/v1/gestacoes/atual", headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "PREGNANCY_NOT_FOUND")


def test_gestacao_sem_perfil_404(client_engine) -> None:
    client, _ = client_engine
    access = _register(client).json()["access_token"]
    r = client.get("/api/v1/gestacoes/atual", headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "PROFILE_NOT_FOUND")


def test_gestacao_rejects_gestante_id_in_body_422(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    r = client.post(
        "/api/v1/gestacoes",
        json=_gestacao_payload(gestante_id=str(uuid.uuid4())),
        headers=_bearer(access),
    )
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


def test_gestacao_future_dum_422(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    r = client.post(
        "/api/v1/gestacoes",
        json=_gestacao_payload(data_ultima_menstruacao="2999-01-01"),
        headers=_bearer(access),
    )
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


# ------------------------------------------------------------------ OWNERSHIP
def test_ownership_another_user_cannot_read_or_write(client_engine) -> None:
    client, _ = client_engine
    access_a, _ = _register_and_create_gestante(client, email="owner-a@example.com")
    gid_a = client.post("/api/v1/gestacoes", json=_gestacao_payload(), headers=_bearer(access_a)).json()["id"]

    access_b, _ = _register_and_create_gestante(client, email="owner-b@example.com")

    # USER B não lê a gestação de A (indistinto de inexistente → 404).
    r_get = client.get(f"/api/v1/gestacoes/{gid_a}", headers=_bearer(access_b))
    assert r_get.status_code == 404
    _flat_error(r_get.json(), "PREGNANCY_NOT_FOUND")

    # USER B não edita a gestação de A.
    r_put = client.put(f"/api/v1/gestacoes/{gid_a}", json=_gestacao_payload(), headers=_bearer(access_b))
    assert r_put.status_code == 404
    _flat_error(r_put.json(), "PREGNANCY_NOT_FOUND")

    # A continua enxergando a própria gestação.
    assert client.get(f"/api/v1/gestacoes/{gid_a}", headers=_bearer(access_a)).status_code == 200


# ---------------------------------------------------------- REGRESSÃO AUTH
def test_auth_regression_register_login_me_refresh_logout(client_engine) -> None:
    client, _ = client_engine
    email = _unique_email()
    reg = _register(client, email=email)
    assert reg.status_code == 201
    assert reg.json()["user"]["email"] == email

    login = client.post("/api/v1/auth/login", json={"email": email, "password": "senha-forte-123"})
    assert login.status_code == 200
    access = login.json()["access_token"]
    refresh = login.json()["refresh_token"]

    me = client.get("/api/v1/auth/me", headers=_bearer(access))
    assert me.status_code == 200

    refreshed = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh})
    assert refreshed.status_code == 200

    assert client.post("/api/v1/auth/logout", json={"refresh_token": refresh}).status_code == 204


# ---------------------------------------------------------- REGRESSÃO DSS
def test_dss_regression_health_and_risk_estimate(client_engine) -> None:
    client, _ = client_engine
    assert client.get("/health").status_code == 200
    r = client.post("/api/v1/risk-estimate", json=make_valid_payload())
    assert r.status_code == 503
    assert r.json()["error"]["code"] == "MODEL_NOT_READY"
