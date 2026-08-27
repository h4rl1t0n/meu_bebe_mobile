"""Testes de integração de HISTÓRICO OBSTÉTRICO com PostgreSQL REAL (FASE 8E).

Cobre: UPSERT via PUT (criar/atualizar o singleton), GET, 404 sem histórico,
404 sem perfil, 401 sem token, rejeição de ``gestante_id``/``user_id`` no body,
validação de contagem negativa, ownership entre usuárias, timestamps,
``updated_at`` muda após update, 1—1 (uma única linha) e regressão de auth/8D/DSS.
Banco dedicado ``meu_bebe_test``; nunca SQLite.
"""

from __future__ import annotations

import uuid
from datetime import datetime

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text

from meu_bebe_api.config import Settings
from meu_bebe_api.contracts.historico_obstetrico import HistoricoObstetricoWrite
from meu_bebe_api.db.base import Base
from meu_bebe_api.db.session import build_session_factory
from meu_bebe_api.domain.services import HistoricoObstetricoService
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


def _historico_payload(**overrides) -> dict:
    payload = {
        "pregnancy_number": 2,
        "given_birth_number": 1,
        "abortions_number": 0,
    }
    payload.update(overrides)
    return payload


def _register_and_create_gestante(client, email=None):
    """Registra um USER e cria o perfil de GESTANTE; retorna (access, gestante)."""
    access = _register(client, email=email).json()["access_token"]
    r = client.post("/api/v1/gestantes/me", json=_gestante_payload(), headers=_bearer(access))
    assert r.status_code == 201
    return access, r.json()


def _put_historico(client, access, payload=None):
    return client.put(
        "/api/v1/gestantes/me/historico-obstetrico",
        json=payload if payload is not None else _historico_payload(),
        headers=_bearer(access),
    )


# ------------------------------------------------------------ HISTÓRICO (CRUD)
def test_historico_put_creates_200(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    r = _put_historico(client, access)
    assert r.status_code == 200
    body = r.json()
    assert body["pregnancy_number"] == 2
    assert body["given_birth_number"] == 1
    assert body["abortions_number"] == 0
    assert "gestante_id" not in body
    assert "user_id" not in body
    assert body["id"]
    assert body["created_at"] and body["updated_at"]


def test_historico_get_returns_200(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    created = _put_historico(client, access).json()
    r = client.get("/api/v1/gestantes/me/historico-obstetrico", headers=_bearer(access))
    assert r.status_code == 200
    assert r.json()["id"] == created["id"]
    assert r.json()["pregnancy_number"] == 2


def test_historico_second_put_updates_same_singleton(client_engine) -> None:
    client, engine = client_engine
    access, gestante = _register_and_create_gestante(client)
    gestante_id = gestante["id"]
    first = _put_historico(client, access).json()
    second = _put_historico(
        client,
        access,
        _historico_payload(pregnancy_number=3, given_birth_number=2, abortions_number=1),
    ).json()
    # UPSERT: mesmo id (não cria uma 2ª linha), campos atualizados.
    assert second["id"] == first["id"]
    assert second["pregnancy_number"] == 3
    assert second["given_birth_number"] == 2
    assert second["abortions_number"] == 1
    # 1—1 no banco: exatamente UMA linha PARA ESTA gestante.
    with engine.begin() as conn:
        count = conn.execute(
            text("SELECT count(*) FROM historicos_obstetricos WHERE gestante_id = :g"),
            {"g": uuid.UUID(gestante_id)},
        ).scalar_one()
    assert count == 1


def test_historico_get_without_history_404(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    r = client.get("/api/v1/gestantes/me/historico-obstetrico", headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "OBSTETRIC_HISTORY_NOT_FOUND")


def test_historico_without_profile_404(client_engine) -> None:
    client, _ = client_engine
    access = _register(client).json()["access_token"]
    r = client.get("/api/v1/gestantes/me/historico-obstetrico", headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "PROFILE_NOT_FOUND")


def test_historico_without_token_401(client_engine) -> None:
    client, _ = client_engine
    assert client.get("/api/v1/gestantes/me/historico-obstetrico").status_code == 401
    assert (
        client.put("/api/v1/gestantes/me/historico-obstetrico", json=_historico_payload()).status_code
        == 401
    )


# ------------------------------------------------------------------ VALIDAÇÃO
def test_historico_rejects_gestante_id_in_body_422(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    r = _put_historico(client, access, _historico_payload(gestante_id=str(uuid.uuid4())))
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


def test_historico_rejects_user_id_in_body_422(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    r = _put_historico(client, access, _historico_payload(user_id=str(uuid.uuid4())))
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


def test_historico_rejects_negative_count_422(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    r = _put_historico(client, access, _historico_payload(pregnancy_number=-1))
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


# ------------------------------------------------------------------ OWNERSHIP
def test_historico_ownership_isolated_between_users(client_engine) -> None:
    client, _ = client_engine
    access_a, _ = _register_and_create_gestante(client, email="owner-a@example.com")
    assert _put_historico(client, access_a).status_code == 200

    access_b, _ = _register_and_create_gestante(client, email="owner-b@example.com")
    # B não vê histórico algum (o de A é de outra gestante → 404 indistinto).
    r = client.get("/api/v1/gestantes/me/historico-obstetrico", headers=_bearer(access_b))
    assert r.status_code == 404
    _flat_error(r.json(), "OBSTETRIC_HISTORY_NOT_FOUND")

    # A continua vendo o próprio histórico.
    assert client.get("/api/v1/gestantes/me/historico-obstetrico", headers=_bearer(access_a)).status_code == 200


# ------------------------------------------------------------- TIMESTAMPS
def test_historico_timestamps_and_updated_at_changes(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    first = _put_historico(client, access).json()
    second = _put_historico(client, access, _historico_payload(pregnancy_number=4)).json()
    assert second["id"] == first["id"]
    # O offset da serialização varia (UTC no objeto em memória vs. tz local ao
    # reler do DB), então compara o INSTANTE, não a string.
    assert datetime.fromisoformat(second["created_at"]) == datetime.fromisoformat(
        first["created_at"]
    )
    assert datetime.fromisoformat(second["updated_at"]) != datetime.fromisoformat(
        first["updated_at"]
    )


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

    assert client.get("/api/v1/auth/me", headers=_bearer(access)).status_code == 200
    assert client.post("/api/v1/auth/refresh", json={"refresh_token": refresh}).status_code == 200
    assert client.post("/api/v1/auth/logout", json={"refresh_token": refresh}).status_code == 204


# ---------------------------------------------------------- REGRESSÃO 8D
def test_gestante_8d_regression_still_works(client_engine) -> None:
    client, _ = client_engine
    access, gestante = _register_and_create_gestante(client)
    assert client.get("/api/v1/gestantes/me", headers=_bearer(access)).status_code == 200
    assert client.post("/api/v1/gestacoes", json={"data_ultima_menstruacao": "2025-01-10"}, headers=_bearer(access)).status_code == 201
    # histórico continua independente e funciona ao lado de GESTANTE/GESTAÇÃO.
    assert _put_historico(client, access).status_code == 200


# ---------------------------------------------------------- REGRESSÃO DSS
def test_dss_regression_health_and_risk_estimate(client_engine) -> None:
    client, _ = client_engine
    assert client.get("/health").status_code == 200
    r = client.post("/api/v1/risk-estimate", json=make_valid_payload())
    assert r.status_code == 503
    assert r.json()["error"]["code"] == "MODEL_NOT_READY"


# ------------------------------------------------- RECUPERAÇÃO DE CORRIDA (8E-FIX)
def test_historico_upsert_recovers_from_unique_race(client_engine) -> None:
    """``find``→``None`` obsoleto + INSERT conflita no UNIQUE(gestante_id) →
    rollback → re-busca do singleton vencedor → payload aplicado a ele.

    Determinístico: a linha "vencedora" é pré-inserida e o ``find`` do service é
    forçado a retornar ``None`` na 1ª chamada, reproduzindo a corrida sem
    concorrência real. Prova: sucesso, id preservado, ``created_at`` preservado,
    payload aplicado e exatamente UMA linha para a gestante.
    """
    client, engine = client_engine
    access, gestante = _register_and_create_gestante(client)
    gestante_id = uuid.UUID(gestante["id"])

    # Linha "vencedora" (como se outra requisição tivesse commitado entre o find
    # e o INSERT desta requisição).
    winner_id = uuid.uuid4()
    with engine.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO historicos_obstetricos "
                "(id, gestante_id, pregnancy_number, given_birth_number, "
                "abortions_number, created_at, updated_at) "
                "VALUES (:id, :g, 2, 1, 0, now(), now())"
            ),
            {"id": winner_id, "g": gestante_id},
        )
    with engine.begin() as conn:
        created_before = conn.execute(
            text("SELECT created_at FROM historicos_obstetricos WHERE id = :id"),
            {"id": winner_id},
        ).scalar_one()

    # Service com Session real; 1ª leitura simulada como obsoleta (None).
    session = build_session_factory(engine)()
    service = HistoricoObstetricoService(session)
    real_find = service._historico.find_by_gestante_id
    state = {"calls": 0}

    def stale_then_real(gid):
        state["calls"] += 1
        if state["calls"] == 1:
            return None  # leitura obsoleta da corrida
        return real_find(gid)  # recuperação acha o vencedor

    service._historico.find_by_gestante_id = stale_then_real  # type: ignore[method-assign]

    try:
        result = service.upsert(
            gestante_id,
            HistoricoObstetricoWrite(
                pregnancy_number=3, given_birth_number=2, abortions_number=1
            ),
        )
    finally:
        session.close()

    # id e created_at do vencedor preservados; payload aplicado.
    assert result.id == winner_id
    assert result.created_at == created_before
    assert result.pregnancy_number == 3
    assert result.given_birth_number == 2
    assert result.abortions_number == 1

    # Permanece exatamente UMA linha para a gestante.
    with engine.begin() as conn:
        count = conn.execute(
            text("SELECT count(*) FROM historicos_obstetricos WHERE gestante_id = :g"),
            {"g": gestante_id},
        ).scalar_one()
    assert count == 1


def test_historico_rejects_id_in_body_422(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_create_gestante(client)
    r = _put_historico(client, access, _historico_payload(id=str(uuid.uuid4())))
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"
