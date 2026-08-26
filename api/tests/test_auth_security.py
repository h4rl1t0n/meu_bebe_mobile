"""Testes de segurança pura (FASE 8C) — hash + JWT, sem banco.

Cobrem PASSWORD HASHING e o contrato de tokens (seção 20.1): Argon2id PHC,
``verify`` em tempo constante (sem exceção), separação estrita access/refresh.
"""

from __future__ import annotations

import uuid

import pytest

from meu_bebe_api.auth.errors import AuthError
from meu_bebe_api.auth.security import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    decode_refresh_token,
    hash_password,
    normalize_email,
    verify_password,
)
from meu_bebe_api.config import Settings

SECRET = "s" * 40


def _settings(**kwargs) -> Settings:
    return Settings(jwt_secret=SECRET, _env_file=None, **kwargs)


def test_hash_is_argon2id_phc() -> None:
    h = hash_password("senha-forte")
    assert h.startswith("$argon2id$")


def test_verify_password_correct_and_wrong() -> None:
    h = hash_password("senha-forte")
    assert verify_password("senha-forte", h) is True
    assert verify_password("senha-errada", h) is False


def test_verify_malformed_hash_returns_false() -> None:
    assert verify_password("qualquer", "nao-e-um-phc") is False


def test_hash_is_not_deterministic() -> None:
    assert hash_password("senha-forte") != hash_password("senha-forte")


def test_normalize_email() -> None:
    assert normalize_email("  Foo@Example.COM ") == "foo@example.com"


def test_access_token_roundtrip() -> None:
    s = _settings()
    uid = uuid.uuid4()
    assert decode_access_token(s, create_access_token(s, uid)) == uid


def test_refresh_token_roundtrip_and_jti() -> None:
    s = _settings()
    uid = uuid.uuid4()
    rt = create_refresh_token(s, uid)
    assert decode_refresh_token(s, rt.token) == rt.jti
    assert rt.expires_at.tzinfo is not None


def test_access_token_rejects_refresh_type() -> None:
    s = _settings()
    uid = uuid.uuid4()
    refresh = create_refresh_token(s, uid)
    with pytest.raises(AuthError) as exc_info:
        decode_access_token(s, refresh.token)
    assert exc_info.value.code == "UNAUTHORIZED"


def test_refresh_token_rejects_access_type() -> None:
    s = _settings()
    uid = uuid.uuid4()
    access = create_access_token(s, uid)
    with pytest.raises(AuthError) as exc_info:
        decode_refresh_token(s, access)
    assert exc_info.value.code == "TOKEN_INVALID"


def test_expired_access_token_raises_token_expired() -> None:
    s = _settings(access_token_ttl_seconds=-1)
    uid = uuid.uuid4()
    token = create_access_token(s, uid)
    with pytest.raises(AuthError) as exc_info:
        decode_access_token(s, token)
    assert exc_info.value.code == "TOKEN_EXPIRED"


def test_invalid_token_raises_token_invalid() -> None:
    s = _settings()
    with pytest.raises(AuthError) as exc_info:
        decode_access_token(s, "abc.def.ghi")
    assert exc_info.value.code == "TOKEN_INVALID"
