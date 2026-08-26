"""Testes de integração de auth com PostgreSQL REAL (FASE 8C).

Matriz da seção 20.1: REGISTER / LOGIN / ACCESS / REFRESH / LOGOUT / MÚLTIPLAS
SESSÕES / ME / SEGURANÇA / REGRESSÃO DSS. Banco dedicado ``meu_bebe_test``;
nunca SQLite. Pula explicitamente se ``TEST_DATABASE_URL`` indisponível.
"""

from __future__ import annotations

import logging
import uuid
from datetime import datetime, timedelta, timezone

import jwt
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

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
def auth_client():
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


# ------------------------------------------------------------------ REGISTER
def test_register_success_normalized_and_argon2id(auth_client) -> None:
    client, engine = auth_client
    r = _register(client, email="  Foo@Example.COM ")
    assert r.status_code == 201
    body = r.json()
    assert body["user"]["email"] == "foo@example.com"
    assert body["user"]["is_active"] is True
    assert body["access_token"]
    assert body["refresh_token"]
    assert "password_hash" not in body["user"]
    assert "password" not in body["user"]
    with engine.connect() as conn:
        ph = conn.execute(
            text("SELECT password_hash FROM users WHERE email = :e"),
            {"e": "foo@example.com"},
        ).scalar()
    assert ph.startswith("$argon2id$")


def test_register_password_too_short_422(auth_client) -> None:
    client, _ = auth_client
    r = _register(client, password="1234567")
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


def test_register_password_too_long_422(auth_client) -> None:
    client, _ = auth_client
    r = _register(client, password="x" * 129)
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


def test_register_invalid_email_422(auth_client) -> None:
    client, _ = auth_client
    r = _register(client, email="nao-e-um-email")
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


def test_register_duplicate_email_409(auth_client) -> None:
    client, _ = auth_client
    email = _unique_email()
    assert _register(client, email=email).status_code == 201
    r = _register(client, email=email)
    assert r.status_code == 409
    _flat_error(r.json(), "DUPLICATE_EMAIL")


def test_register_unique_constraint_at_db_level(auth_client) -> None:
    client, engine = auth_client
    email = _unique_email()
    _register(client, email=email)
    with pytest.raises(IntegrityError):
        with engine.begin() as conn:
            conn.execute(
                text(
                    "INSERT INTO users (id, email, password_hash, is_active, created_at, updated_at) "
                    "VALUES (:id, :e, 'x', true, now(), now())"
                ),
                {"id": str(uuid.uuid4()), "e": email},
            )


# -------------------------------------------------------------------- LOGIN
def test_login_success(auth_client) -> None:
    client, _ = auth_client
    email = _unique_email()
    _register(client, email=email, password="senha-forte-123")
    r = client.post("/api/v1/auth/login", json={"email": email, "password": "senha-forte-123"})
    assert r.status_code == 200
    body = r.json()
    assert body["user"]["email"] == email
    assert body["access_token"]
    assert body["refresh_token"]


def test_login_anti_enumeration(auth_client) -> None:
    client, _ = auth_client
    email = _unique_email()
    _register(client, email=email, password="senha-correta-123")
    r1 = client.post(
        "/api/v1/auth/login",
        json={"email": "inexistente@example.com", "password": "qualquer"},
    )
    r2 = client.post("/api/v1/auth/login", json={"email": email, "password": "senha-errada"})
    assert r1.status_code == 401 and r2.status_code == 401
    _flat_error(r1.json(), "INVALID_CREDENTIALS")
    _flat_error(r2.json(), "INVALID_CREDENTIALS")
    assert r1.json()["message"] == r2.json()["message"]


def test_login_inactive_user_403(auth_client) -> None:
    client, engine = auth_client
    email = _unique_email()
    _register(client, email=email)
    with engine.begin() as conn:
        conn.execute(text("UPDATE users SET is_active = false WHERE email = :e"), {"e": email})
    r = client.post("/api/v1/auth/login", json={"email": email, "password": "senha-forte-123"})
    assert r.status_code == 403
    _flat_error(r.json(), "ACCOUNT_INACTIVE")


# ------------------------------------------------------- ACCESS TOKEN / ME
def test_me_with_valid_access(auth_client) -> None:
    client, _ = auth_client
    email = _unique_email()
    access = _register(client, email=email).json()["access_token"]
    resp = client.get("/api/v1/auth/me", headers=_bearer(access))
    assert resp.status_code == 200
    body = resp.json()
    assert body["email"] == email
    assert "password_hash" not in body
    assert "password" not in body


def test_me_without_token_401(auth_client) -> None:
    client, _ = auth_client
    r = client.get("/api/v1/auth/me")
    assert r.status_code == 401
    _flat_error(r.json(), "UNAUTHORIZED")


def test_me_with_refresh_token_401(auth_client) -> None:
    client, _ = auth_client
    refresh = _register(client).json()["refresh_token"]
    resp = client.get("/api/v1/auth/me", headers=_bearer(refresh))
    assert resp.status_code == 401
    _flat_error(resp.json(), "UNAUTHORIZED")


def test_me_with_expired_access_401(auth_client) -> None:
    client, _ = auth_client
    uid = _register(client).json()["user"]["id"]
    now = datetime.now(timezone.utc)
    expired = jwt.encode(
        {
            "sub": uid,
            "type": "access",
            "iat": now - timedelta(hours=1),
            "exp": now - timedelta(seconds=1),
        },
        TEST_JWT_SECRET,
        algorithm="HS256",
    )
    resp = client.get("/api/v1/auth/me", headers=_bearer(expired))
    assert resp.status_code == 401
    _flat_error(resp.json(), "TOKEN_EXPIRED")


def test_me_with_nonexistent_sub_401(auth_client) -> None:
    client, _ = auth_client
    now = datetime.now(timezone.utc)
    ghost = jwt.encode(
        {"sub": str(uuid.uuid4()), "type": "access", "iat": now, "exp": now + timedelta(minutes=5)},
        TEST_JWT_SECRET,
        algorithm="HS256",
    )
    resp = client.get("/api/v1/auth/me", headers=_bearer(ghost))
    assert resp.status_code == 401
    _flat_error(resp.json(), "UNAUTHORIZED")


# ------------------------------------------------------------------ REFRESH
def test_refresh_rotates_and_revokes_old(auth_client) -> None:
    client, _ = auth_client
    old_refresh = _register(client).json()["refresh_token"]
    resp = client.post("/api/v1/auth/refresh", json={"refresh_token": old_refresh})
    assert resp.status_code == 200
    new_refresh = resp.json()["refresh_token"]
    assert new_refresh != old_refresh
    assert resp.json()["access_token"]
    # reuso do antigo → revogado
    r2 = client.post("/api/v1/auth/refresh", json={"refresh_token": old_refresh})
    assert r2.status_code == 401
    _flat_error(r2.json(), "TOKEN_REVOKED")
    # o novo continua válido
    assert client.post("/api/v1/auth/refresh", json={"refresh_token": new_refresh}).status_code == 200


def test_refresh_with_access_token_401(auth_client) -> None:
    client, _ = auth_client
    access = _register(client).json()["access_token"]
    resp = client.post("/api/v1/auth/refresh", json={"refresh_token": access})
    assert resp.status_code == 401
    _flat_error(resp.json(), "TOKEN_INVALID")


def test_refresh_expired_401(auth_client) -> None:
    client, _ = auth_client
    now = datetime.now(timezone.utc)
    expired = jwt.encode(
        {
            "sub": str(uuid.uuid4()),
            "type": "refresh",
            "jti": str(uuid.uuid4()),
            "iat": now - timedelta(days=1),
            "exp": now - timedelta(seconds=1),
        },
        TEST_JWT_SECRET,
        algorithm="HS256",
    )
    resp = client.post("/api/v1/auth/refresh", json={"refresh_token": expired})
    assert resp.status_code == 401
    _flat_error(resp.json(), "TOKEN_EXPIRED")


# ------------------------------------------------------------------- LOGOUT
def test_logout_revokes_session_and_access_remains(auth_client) -> None:
    client, _ = auth_client
    r = _register(client)
    refresh = r.json()["refresh_token"]
    access = r.json()["access_token"]
    assert client.post("/api/v1/auth/logout", json={"refresh_token": refresh}).status_code == 204
    r2 = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh})
    assert r2.status_code == 401
    _flat_error(r2.json(), "TOKEN_REVOKED")
    # access continua válido até expirar (limitação documentada; sem blacklist)
    me = client.get("/api/v1/auth/me", headers=_bearer(access))
    assert me.status_code == 200


def test_logout_idempotent(auth_client) -> None:
    client, _ = auth_client
    refresh = _register(client).json()["refresh_token"]
    assert client.post("/api/v1/auth/logout", json={"refresh_token": refresh}).status_code == 204
    assert client.post("/api/v1/auth/logout", json={"refresh_token": refresh}).status_code == 204


# -------------------------------------------------------- MÚLTIPLAS SESSÕES
def test_multiple_sessions_independent(auth_client) -> None:
    client, _ = auth_client
    email = _unique_email()
    refresh1 = _register(client, email=email).json()["refresh_token"]
    refresh2 = client.post(
        "/api/v1/auth/login", json={"email": email, "password": "senha-forte-123"}
    ).json()["refresh_token"]
    assert refresh1 != refresh2
    # logout da sessão 1 não revoga a 2
    client.post("/api/v1/auth/logout", json={"refresh_token": refresh1})
    assert client.post("/api/v1/auth/refresh", json={"refresh_token": refresh1}).status_code == 401
    assert client.post("/api/v1/auth/refresh", json={"refresh_token": refresh2}).status_code == 200


# -------------------------------------------------------------- ME (escopo)
def test_me_returns_only_own_user(auth_client) -> None:
    client, _ = auth_client
    _register(client, email="user-a@example.com")
    _register(client, email="user-b@example.com")
    # registra de novo para obter um token da user-a (ou loga)
    access_a = client.post(
        "/api/v1/auth/login", json={"email": "user-a@example.com", "password": "senha-forte-123"}
    ).json()["access_token"]
    me = client.get("/api/v1/auth/me", headers=_bearer(access_a))
    assert me.status_code == 200
    assert me.json()["email"] == "user-a@example.com"


# ---------------------------------------------------------------- SEGURANÇA
def test_no_secrets_in_logs(auth_client, caplog) -> None:
    client, _ = auth_client
    password = "SUPER-SECRETA-123"
    email = _unique_email()
    with caplog.at_level(logging.DEBUG):
        _register(client, email=email, password=password)
        client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert password not in caplog.text
    assert TEST_JWT_SECRET not in caplog.text


# ---------------------------------------------------------- REGRESSÃO DSS
def test_health_and_risk_estimate_unaffected_by_auth(auth_client) -> None:
    client, _ = auth_client
    assert client.get("/health").status_code == 200
    # /risk-estimate NÃO exige auth: sem token responde 503 MODEL_NOT_READY
    # (modelo não carregado no fixture), nunca 401/403 de autenticação.
    r = client.post("/api/v1/risk-estimate", json=make_valid_payload())
    assert r.status_code == 503
    assert r.json()["error"]["code"] == "MODEL_NOT_READY"
