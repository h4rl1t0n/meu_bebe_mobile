"""Testes de integração de AVALIAÇÃO DSS com PostgreSQL REAL (FASE 8I).

Cobre: POST 201 (snapshot imutável), GET lista/GET item, append-only (vários
snapshots sem sobrescrever), ordenação ``created_at`` DESC, ownership A/B,
gestação inexistente/alheia, avaliação inexistente, outra gestação (mesma
usuária), IDs proibidos, timestamp do servidor, round-trip das 48 variáveis, a
AUSÊNCIA de target/probabilidade/classe/threshold/recomendação, o
``/risk-estimate`` INTACTO (stateless/sem auth), rejeições de contrato
(extra/schema/tipo/bool) e regressões de auth/8D/8G. Banco ``meu_bebe_test``;
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

_DIMENSIONS = {"educacao", "trabalho", "saneamento", "saude", "habitacao", "alimentacao"}


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


def _register_and_setup_gestacao(client, email=None):
    """Registra USER, cria GESTANTE e GESTAÇÃO ativa; retorna (access, gestacao_id)."""
    access = _register(client, email=email).json()["access_token"]
    r = client.post("/api/v1/gestantes/me", json=_gestante_payload(), headers=_bearer(access))
    assert r.status_code == 201
    r = client.post("/api/v1/gestacoes", json=_gestacao_payload(), headers=_bearer(access))
    assert r.status_code == 201
    return access, r.json()["id"]


def _base(gestacao_id: str) -> str:
    return f"/api/v1/gestacoes/{gestacao_id}/avaliacoes-dss"


# ---------------------------------------------------------------- POST cria
def test_avaliacao_dss_post_201(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.post(_base(gid), json=make_valid_payload(), headers=_bearer(access))
    assert r.status_code == 201
    body = r.json()
    assert body["schema_version"] == "1.13"
    assert body["id"]
    assert body["created_at"]
    assert set(body["respostas"]) == _DIMENSIONS
    # Nunca ecoa o vínculo nem IDs proibidos.
    for forbidden in ("gestacao_id", "user_id", "gestante_id"):
        assert forbidden not in body


# ------------------------------------------------------- GET lista + item
def test_avaliacao_dss_get_list_and_item(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    created = client.post(_base(gid), json=make_valid_payload(), headers=_bearer(access)).json()

    lista = client.get(_base(gid), headers=_bearer(access))
    assert lista.status_code == 200
    assert [a["id"] for a in lista.json()] == [created["id"]]

    item = client.get(f"{_base(gid)}/{created['id']}", headers=_bearer(access))
    assert item.status_code == 200
    body = item.json()
    assert body["id"] == created["id"]
    assert body["schema_version"] == created["schema_version"]
    assert body["respostas"] == created["respostas"]
    # Mesmo INSTANTE (o offset da serialização varia: POST "Z" vs. GET "-04:00").
    assert datetime.fromisoformat(body["created_at"]) == datetime.fromisoformat(
        created["created_at"]
    )


# ------------------------------------------ append-only: múltiplos snapshots
def test_avaliacao_dss_append_only_multiple_snapshots(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    base = _base(gid)

    first = client.post(base, json=make_valid_payload(), headers=_bearer(access)).json()

    second_payload = make_valid_payload()
    second_payload["habitacao"]["numero_pessoas"] = 6
    second = client.post(base, json=second_payload, headers=_bearer(access)).json()

    # Append-only: o segundo NUNCA sobrescreve o primeiro.
    assert second["id"] != first["id"]

    lista = client.get(base, headers=_bearer(access)).json()
    assert [a["id"] for a in lista] == [second["id"], first["id"]]

    # O primeiro snapshot segue intacto (o histórico é preservado).
    got_first = client.get(f"{base}/{first['id']}", headers=_bearer(access)).json()
    assert got_first["respostas"]["habitacao"]["numero_pessoas"] == 3
    assert got_first["id"] == first["id"]


# --------------------------------------------- ordenação: created_at DESC
def test_avaliacao_dss_ordering_created_at_desc(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    base = _base(gid)

    first = client.post(base, json=make_valid_payload(), headers=_bearer(access)).json()
    second = client.post(base, json=make_valid_payload(), headers=_bearer(access)).json()

    lista = client.get(base, headers=_bearer(access)).json()
    # Mais recente primeiro: ordem determinística por created_at DESC.
    assert [a["id"] for a in lista] == [second["id"], first["id"]]
    ts = [datetime.fromisoformat(a["created_at"]) for a in lista]
    assert ts[0] >= ts[1]


# --------------------------------------------------------------- ownership
def test_avaliacao_dss_ownership_between_users_404(client_engine) -> None:
    client, _ = client_engine
    access_a, gid_a = _register_and_setup_gestacao(client)
    av = client.post(_base(gid_a), json=make_valid_payload(), headers=_bearer(access_a)).json()

    access_b, _ = _register_and_setup_gestacao(client)

    # USER B não lista/cria/obtém na gestação de A (indistinto de inexistente).
    assert client.get(_base(gid_a), headers=_bearer(access_b)).status_code == 404
    assert client.post(_base(gid_a), json=make_valid_payload(), headers=_bearer(access_b)).status_code == 404
    assert client.get(f"{_base(gid_a)}/{av['id']}", headers=_bearer(access_b)).status_code == 404

    # O dono segue enxergando.
    assert client.get(f"{_base(gid_a)}/{av['id']}", headers=_bearer(access_a)).status_code == 200


# -------------------------------------------------------- gestação inexistente
def test_avaliacao_dss_gestacao_inexistente_404(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_setup_gestacao(client)
    r = client.get(_base(str(uuid.uuid4())), headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "PREGNANCY_NOT_FOUND")


# -------------------------------------------------------- avaliação inexistente
def test_avaliacao_dss_avaliacao_inexistente_404(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.get(f"{_base(gid)}/{uuid.uuid4()}", headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "AVALIACAO_DSS_NOT_FOUND")


# --------------------------------------------- outra gestação (mesma usuária)
def test_avaliacao_dss_outra_gestacao_404(client_engine) -> None:
    """Avaliação da gestação A não é acessível sob a gestação B (mesma usuária)."""
    client, _ = client_engine
    access, gid_a = _register_and_setup_gestacao(client)
    av = client.post(_base(gid_a), json=make_valid_payload(), headers=_bearer(access)).json()

    # Encerra A e cria B (mesma usuária → duas gestações).
    r = client.put(
        f"/api/v1/gestacoes/{gid_a}",
        json=_gestacao_payload(ended_at="2025-06-30T12:00:00Z"),
        headers=_bearer(access),
    )
    assert r.status_code == 200
    r2 = client.post("/api/v1/gestacoes", json=_gestacao_payload(), headers=_bearer(access))
    assert r2.status_code == 201
    gid_b = r2.json()["id"]

    # A avaliação de A NÃO vaza para B (id + gestacao_id escopados).
    assert client.get(f"{_base(gid_b)}/{av['id']}", headers=_bearer(access)).status_code == 404
    # A segue acessível pela sua própria gestação.
    assert client.get(f"{_base(gid_a)}/{av['id']}", headers=_bearer(access)).status_code == 200


# ------------------------------------------------------------ IDs proibidos
def test_avaliacao_dss_rejects_forbidden_ids_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    for forbidden in ("gestacao_id", "user_id", "id", "gestante_id", "created_at"):
        r = client.post(
            _base(gid),
            json={**make_valid_payload(), forbidden: str(uuid.uuid4())},
            headers=_bearer(access),
        )
        assert r.status_code == 422, forbidden
        assert r.json()["code"] == "VALIDATION_ERROR"


# -------------------------------------------------------- timestamp servidor
def test_avaliacao_dss_timestamp_is_server_generated(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    created = client.post(_base(gid), json=make_valid_payload(), headers=_bearer(access)).json()
    ts = datetime.fromisoformat(created["created_at"])
    assert ts.tzinfo is not None  # TIMESTAMPTZ → timezone-aware
    # "created_at" não pode vir do cliente (rejeitado como ID proibido acima).


# ------------------------------------------------ round-trip exaustivo (48 vars)
def test_avaliacao_dss_round_trip_full_48(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    sent = make_valid_payload()
    base = _base(gid)

    created = client.post(base, json=sent, headers=_bearer(access)).json()
    assert created["schema_version"] == sent["schema_version"]

    # respostas = envelope SEM schema_version (as 6 dimensões / 48 variáveis).
    expected_respostas = {k: v for k, v in sent.items() if k != "schema_version"}
    assert created["respostas"] == expected_respostas
    assert sum(len(v) for v in expected_respostas.values()) == 48

    # Resposta tem EXATAMENTE os 4 campos (id/schema_version/respostas/created_at).
    assert set(created) == {"id", "schema_version", "respostas", "created_at"}

    # GET retorna o snapshot idêntico (nada perdido/trocado), exceto o offset de
    # ``created_at`` na serialização (mesmo instante).
    got = client.get(f"{base}/{created['id']}", headers=_bearer(access))
    assert got.status_code == 200
    body = got.json()
    assert body["id"] == created["id"]
    assert body["schema_version"] == created["schema_version"]
    assert body["respostas"] == created["respostas"]
    assert set(body) == {"id", "schema_version", "respostas", "created_at"}
    assert datetime.fromisoformat(body["created_at"]) == datetime.fromisoformat(
        created["created_at"]
    )


# ------------------------------- ausência de target/probabilidade/classe/risco
def test_avaliacao_dss_has_no_target_or_risk_fields(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    created = client.post(_base(gid), json=make_valid_payload(), headers=_bearer(access)).json()

    top = set(created)
    respostas = created["respostas"]

    # Nenhum artefato da IA (target/probabilidade/classe/threshold/recomendação).
    for banned in (
        "descontinuou_pre_natal",
        "target",
        "probability",
        "probabilidade",
        "risk_class",
        "classe_risco",
        "threshold",
        "recomendacao",
        "recommendation",
        "iv_dss",
    ):
        assert banned not in top, banned
        for dim in respostas.values():
            assert banned not in dim, banned

    # respostas é EXATAMENTE as 6 dimensões — nada além do questionário.
    assert set(respostas) == _DIMENSIONS


# --------------------------------------------------- /risk-estimate INTACTO
def test_risk_estimate_unchanged_stateless_no_auth(client_engine) -> None:
    """O /risk-estimate permanece stateless e SEM autenticação (não 401/404)."""
    client, _ = client_engine
    # Sem token algum → NÃO é 401 (permanece público); sem modelo → 503.
    r = client.post("/api/v1/risk-estimate", json=make_valid_payload())
    assert r.status_code == 503
    assert r.json()["error"]["code"] == "MODEL_NOT_READY"


# --------------------------------------- rejeições de contrato (HTTP → 422)
def test_avaliacao_dss_contract_rejections_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    base = _base(gid)

    # Campo extra no envelope (extra="forbid").
    extra = {**make_valid_payload(), "campo_extra": 1}
    # schema_version incompatível.
    wrong_schema = make_valid_payload()
    wrong_schema["schema_version"] = "1.12"
    # Tipo inválido (bool estrito rejeita string).
    bad_type = make_valid_payload()
    bad_type["educacao"]["estuda_atualmente"] = "true"
    # Lista obrigatória rejeita null.
    null_list = make_valid_payload()
    null_list["educacao"]["dificuldades_educacao"] = None

    for bad in (extra, wrong_schema, bad_type, null_list):
        r = client.post(base, json=bad, headers=_bearer(access))
        assert r.status_code == 422
        assert r.json()["code"] == "VALIDATION_ERROR"


def test_avaliacao_dss_accepts_nullable_beneficios_and_empty_list(client_engine) -> None:
    """Desempregada (beneficios_trabalho null) e lista vazia são snapshots válidos."""
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)

    payload = make_valid_payload()
    payload["trabalho"]["empregado"] = False
    payload["trabalho"]["tipo_emprego"] = None
    payload["trabalho"]["beneficios_trabalho"] = None
    payload["trabalho"]["motivo_desemprego"] = "gestacao"
    payload["educacao"]["dificuldades_educacao"] = []

    r = client.post(_base(gid), json=payload, headers=_bearer(access))
    assert r.status_code == 201
    assert r.json()["respostas"]["trabalho"]["beneficios_trabalho"] is None
    assert r.json()["respostas"]["educacao"]["dificuldades_educacao"] == []


# -------------------------------------------------------------- regressões
def test_regression_auth_8d_8g_coexist(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    assert client.get("/api/v1/auth/me", headers=_bearer(access)).status_code == 200
    assert client.get("/api/v1/gestantes/me", headers=_bearer(access)).status_code == 200
    assert client.get(f"/api/v1/gestacoes/{gid}", headers=_bearer(access)).status_code == 200
    # Avaliação DSS convive com plano/medicamento/vacina da gestação.
    assert client.post(_base(gid), json=make_valid_payload(), headers=_bearer(access)).status_code == 201
    assert (
        client.post(
            f"/api/v1/gestacoes/{gid}/medicamentos",
            json={"nome": "Ácido fólico", "dose": "5mg", "frequencia": "1 vez ao dia"},
            headers=_bearer(access),
        ).status_code
        == 201
    )
