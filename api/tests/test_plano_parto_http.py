"""Testes HTTP de PLANO DE PARTO SEM banco (FASE 8H) — fail-closed.

Sem PostgreSQL real, verificam:
- ``JWT_SECRET`` ausente → 503 ``AUTH_NOT_CONFIGURED`` (auth inerte).
- ``DATABASE_URL`` ausente (com secret) → 503 ``DATABASE_UNAVAILABLE``.
- Existência das rotas (503 em vez de 404): o router está registrado.

O plano de parto é um SINGLETON por gestação: exatamente 2 rotas (GET e PUT),
sem POST e sem DELETE (o app nunca remove o plano).
"""

from __future__ import annotations

import uuid

from fastapi.testclient import TestClient

from meu_bebe_api.config import Settings
from meu_bebe_api.main import create_app

from tests._auth_test_support import TEST_JWT_SECRET
from tests.conftest import UNREACHABLE_DATABASE_URL

_PLANO = {
    "acompanhante": "sim",
    "raspar_pelos_intimos": "nao",
    "lavagem_intestinal": "nao",
    "ambiente_pouca_luz": "nao_sei",
    "ouvir_musica": "sim",
    "beber_liquidos": "sim",
    "registrar_fotos_videos": "nao",
    "via_parto": "vaginal",
    "anestesia": "sim",
    "corte_vaginal": "nao",
    "posicao_preferida": "deitada",
    "outra_posicao": None,
    "quem_corta_cordao": "acompanhante",
    "coleta_celulas_tronco": False,
    "contato_pele_a_pele": "sim",
    "amamentar_primeira_hora": "sim",
    "restricoes_amamentacao": False,
    "primeiro_banho": "eu",
    "quer_alivio_dor": "sim",
    "massagem": True,
    "exercicios_bola": False,
    "exercicios_respiracao": True,
    "banho_chuveiro": False,
    "banho_banheira": False,
    "acupuntura": False,
    "acupressao": False,
    "outro_metodo": False,
    "observacoes": "Quero um parto tranquilo.",
}


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


def test_plano_parto_routes_auth_not_configured_503() -> None:
    base = f"/api/v1/gestacoes/{_id()}/plano-de-parto"
    with _client(_not_configured()) as c:
        assert c.get(base).status_code == 503
        assert c.put(base, json=_PLANO).status_code == 503


def test_plano_parto_database_unavailable_503() -> None:
    with _client(_db_unavailable()) as c:
        r = c.get(f"/api/v1/gestacoes/{_id()}/plano-de-parto")
    assert r.status_code == 503
    _assert_nested_503(r.json(), "DATABASE_UNAVAILABLE")


def test_plano_parto_endpoints_exist_not_404() -> None:
    """Sem config, as rotas respondem 503 (não 404): router registrado."""
    base = f"/api/v1/gestacoes/{_id()}/plano-de-parto"
    with _client(_not_configured()) as c:
        assert c.get(base).status_code == 503
        assert c.put(base, json=_PLANO).status_code == 503
