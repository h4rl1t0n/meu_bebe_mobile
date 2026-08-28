"""Testes de integração de PLANO DE PARTO com PostgreSQL REAL (FASE 8H).

Cobre: singleton por gestação (GET inexistente → 404, PUT cria, GET retorna,
PUT atualiza mantendo o MESMO id), ownership entre usuárias (A/B), gestação
inexistente/alheia, rejeição de IDs proibidos, enums inválidos, strings vazias,
booleanos, opcionais (posicao_preferida/outra_posicao), observações vazias,
timestamps, a AUSÊNCIA de DELETE, e regressões de auth/8D/8G. Banco dedicado
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


def _plano_payload(**overrides) -> dict:
    payload = {
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
    payload.update(overrides)
    return payload


# Os 28 campos FUNCIONAIS do plano (exclui id/gestacao_id/created_at/updated_at):
# 7 expectativas + 5 momento + 6 nascimento + 9 alívio da dor + 1 observações.
_PLANO_FIELD_NAMES = {
    "acompanhante",
    "raspar_pelos_intimos",
    "lavagem_intestinal",
    "ambiente_pouca_luz",
    "ouvir_musica",
    "beber_liquidos",
    "registrar_fotos_videos",
    "via_parto",
    "anestesia",
    "corte_vaginal",
    "posicao_preferida",
    "outra_posicao",
    "quem_corta_cordao",
    "coleta_celulas_tronco",
    "contato_pele_a_pele",
    "amamentar_primeira_hora",
    "restricoes_amamentacao",
    "primeiro_banho",
    "quer_alivio_dor",
    "massagem",
    "exercicios_bola",
    "exercicios_respiracao",
    "banho_chuveiro",
    "banho_banheira",
    "acupuntura",
    "acupressao",
    "outro_metodo",
    "observacoes",
}


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


def _plano_base(gestacao_id: str) -> str:
    return f"/api/v1/gestacoes/{gestacao_id}/plano-de-parto"


# ------------------------------------------------------------- GET inexistente
def test_plano_get_inexistente_404(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.get(_plano_base(gid), headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "PLANO_PARTO_NOT_FOUND")


# ---------------------------------------------------------------- PUT cria
def test_plano_put_creates_200(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.put(_plano_base(gid), json=_plano_payload(), headers=_bearer(access))
    assert r.status_code == 200
    body = r.json()
    assert body["acompanhante"] == "sim"
    assert body["via_parto"] == "vaginal"
    assert body["posicao_preferida"] == "deitada"
    assert body["outra_posicao"] is None
    assert body["quem_corta_cordao"] == "acompanhante"
    assert body["coleta_celulas_tronco"] is False
    assert body["massagem"] is True
    assert body["observacoes"] == "Quero um parto tranquilo."
    assert body["id"]
    assert body["created_at"] and body["updated_at"]
    # Nunca ecoa o vínculo nem IDs proibidos.
    assert "gestacao_id" not in body
    assert "user_id" not in body
    assert "gestante_id" not in body


# -------------------------------------------------------------- GET retorna
def test_plano_get_returns_after_put(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    created = client.put(_plano_base(gid), json=_plano_payload(), headers=_bearer(access)).json()
    r = client.get(_plano_base(gid), headers=_bearer(access))
    assert r.status_code == 200
    assert r.json()["id"] == created["id"]
    assert r.json()["via_parto"] == "vaginal"


# ------------------------------------------------- PUT atualiza (mesmo id)
def test_plano_put_updates_same_id(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    created = client.put(_plano_base(gid), json=_plano_payload(), headers=_bearer(access)).json()
    updated = client.put(
        _plano_base(gid),
        json=_plano_payload(via_parto="cesarea", anestesia="nao", observacoes="Parto cesárea."),
        headers=_bearer(access),
    ).json()
    assert updated["id"] == created["id"]
    assert updated["via_parto"] == "cesarea"
    assert updated["anestesia"] == "nao"
    assert updated["observacoes"] == "Parto cesárea."
    # os demais campos não tocados foram preservados (full update do payload)
    assert updated["acompanhante"] == "sim"


# -------------------------------------------------- singleton (sem duplicar)
def test_plano_upsert_is_singleton_no_duplicate(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    first = client.put(_plano_base(gid), json=_plano_payload(), headers=_bearer(access)).json()
    second = client.put(
        _plano_base(gid), json=_plano_payload(via_parto="cesarea"), headers=_bearer(access)
    ).json()
    assert second["id"] == first["id"]  # mesmo singleton, nunca um segundo plano
    got = client.get(_plano_base(gid), headers=_bearer(access)).json()
    assert got["id"] == first["id"]


# --------------------------------------------------------------- ownership
def test_plano_ownership_between_users_404(client_engine) -> None:
    client, _ = client_engine
    access_a, gid_a = _register_and_setup_gestacao(client)
    client.put(_plano_base(gid_a), json=_plano_payload(), headers=_bearer(access_a))

    access_b, _ = _register_and_setup_gestacao(client)
    assert client.get(_plano_base(gid_a), headers=_bearer(access_b)).status_code == 404
    assert client.put(_plano_base(gid_a), json=_plano_payload(), headers=_bearer(access_b)).status_code == 404
    # o dono segue enxergando o plano
    assert client.get(_plano_base(gid_a), headers=_bearer(access_a)).status_code == 200


def test_plano_gestacao_inexistente_404(client_engine) -> None:
    client, _ = client_engine
    access, _ = _register_and_setup_gestacao(client)
    r = client.get(_plano_base(str(uuid.uuid4())), headers=_bearer(access))
    assert r.status_code == 404
    _flat_error(r.json(), "PREGNANCY_NOT_FOUND")


# ------------------------------------------------------------ IDs proibidos
def test_plano_rejects_forbidden_ids_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    for forbidden in ("gestacao_id", "user_id", "id", "gestante_id", "created_at", "updated_at"):
        r = client.put(
            _plano_base(gid),
            json=_plano_payload(**{forbidden: str(uuid.uuid4())}),
            headers=_bearer(access),
        )
        assert r.status_code == 422, forbidden
        assert r.json()["code"] == "VALIDATION_ERROR"


# --------------------------------------------------------- enums inválidos
def test_plano_rejects_invalid_enum_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    for override in (
        {"via_parto": "domiciliar"},          # fora de BirthWay
        {"anestesia": "talvez"},              # fora de TriState
        {"quem_corta_cordao": "enfermeiro"},  # fora de ActorChoice
        {"posicao_preferida": "pendurada"},   # fora de Position
    ):
        r = client.put(_plano_base(gid), json=_plano_payload(**override), headers=_bearer(access))
        assert r.status_code == 422, override
        assert r.json()["code"] == "VALIDATION_ERROR"


# ----------------------------------------------------- enum vazio / espaços
def test_plano_rejects_empty_enum_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    for override in ({"via_parto": ""}, {"via_parto": "   "}):
        r = client.put(_plano_base(gid), json=_plano_payload(**override), headers=_bearer(access))
        assert r.status_code == 422, override
        assert r.json()["code"] == "VALIDATION_ERROR"


# -------------------------------------------------------------- booleanos
def test_plano_rejects_bool_wrong_type_422(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    # "sim"/"verdadeiro" não são strings bool reconhecidas; None não é aceito num
    # bool OBRIGATÓRIO. (int 0/1 e "true"/"false" são coercidos por Pydantic
    # laxo — comportamento idêntico ao do contrato VACINA.)
    for override in (
        {"coleta_celulas_tronco": "sim"},
        {"restricoes_amamentacao": "verdadeiro"},
        {"massagem": None},
    ):
        r = client.put(_plano_base(gid), json=_plano_payload(**override), headers=_bearer(access))
        assert r.status_code == 422, override
        assert r.json()["code"] == "VALIDATION_ERROR"

    # bool ausente (obrigatório) também é 422.
    payload = _plano_payload()
    del payload["outro_metodo"]
    r = client.put(_plano_base(gid), json=payload, headers=_bearer(access))
    assert r.status_code == 422
    assert r.json()["code"] == "VALIDATION_ERROR"


# ------------------------------------------------- opcionais (null/vazio)
def test_plano_optional_fields_null_and_whitespace(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    # posicao_preferida ausente + outra_posicao vazia → ambos null (lição da 8F)
    r = client.put(
        _plano_base(gid),
        json=_plano_payload(posicao_preferida=None, outra_posicao="   "),
        headers=_bearer(access),
    )
    assert r.status_code == 200
    body = r.json()
    assert body["posicao_preferida"] is None
    assert body["outra_posicao"] is None


def test_plano_outra_posicao_persists_when_position_is_outra(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.put(
        _plano_base(gid),
        json=_plano_payload(posicao_preferida="outra", outra_posicao="De cócoras"),
        headers=_bearer(access),
    )
    assert r.status_code == 200
    body = r.json()
    assert body["posicao_preferida"] == "outra"
    assert body["outra_posicao"] == "De cócoras"


# ------------------------------------------------ observações vazias (TEXT)
def test_plano_observacoes_allows_empty(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    r = client.put(
        _plano_base(gid),
        json=_plano_payload(observacoes="   "),
        headers=_bearer(access),
    )
    assert r.status_code == 200
    assert r.json()["observacoes"] == ""  # strip; vazio permitido ("sem observações")


# -------------------------------------------- round-trip exaustivo (28 campos)
def test_plano_parto_round_trip_all_fields(client_engine) -> None:
    """PUT com os 28 campos (valores não-default) → GET: nada perdido/trocado.

    Envia uma combinação variada de enums/booleanos/texto e compara campo a campo
    os 28 valores funcionais retornados pelo GET. Os metadados (id/created_at/
    updated_at) existem mas NÃO entram na contagem dos 28.
    """
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)

    sent = {
        # Expectativas (7) — tri-state variado
        "acompanhante": "sim",
        "raspar_pelos_intimos": "nao",
        "lavagem_intestinal": "nao_sei",
        "ambiente_pouca_luz": "sim",
        "ouvir_musica": "nao",
        "beber_liquidos": "nao_sei",
        "registrar_fotos_videos": "sim",
        # Momento do parto (5) — via cesárea + posição "outra" com texto real
        "via_parto": "cesarea",
        "anestesia": "nao_sei",
        "corte_vaginal": "sim",
        "posicao_preferida": "outra",
        "outra_posicao": "De cócoras apoiada na banqueta",
        # Nascimento (6) — atores distintos + booleanos misturados
        "quem_corta_cordao": "eu",
        "coleta_celulas_tronco": True,
        "contato_pele_a_pele": "nao",
        "amamentar_primeira_hora": "nao_sei",
        "restricoes_amamentacao": True,
        "primeiro_banho": "acompanhante",
        # Alívio da dor (9) — enum sim + 8 booleanos misturados
        "quer_alivio_dor": "sim",
        "massagem": True,
        "exercicios_bola": False,
        "exercicios_respiracao": True,
        "banho_chuveiro": True,
        "banho_banheira": False,
        "acupuntura": False,
        "acupressao": True,
        "outro_metodo": False,
        # Observações (1) — texto real
        "observacoes": "Quero pouca luz e música calma.",
    }

    # O payload tem EXATAMENTE os 28 campos funcionais (nem mais, nem menos).
    assert set(sent) == _PLANO_FIELD_NAMES

    base = _plano_base(gid)
    put = client.put(base, json=sent, headers=_bearer(access))
    assert put.status_code == 200
    created = put.json()

    got = client.get(base, headers=_bearer(access))
    assert got.status_code == 200
    body = got.json()

    # A resposta tem exatamente os 28 campos funcionais + 3 metadados.
    expected_response_keys = _PLANO_FIELD_NAMES | {"id", "created_at", "updated_at"}
    assert set(created) == expected_response_keys
    assert set(body) == expected_response_keys

    # PUT → GET: os 28 valores enviados retornam idênticos (campo a campo).
    for field in _PLANO_FIELD_NAMES:
        assert body[field] == sent[field], field

    # Metadados presentes e coerentes (fora da contagem dos 28).
    assert body["id"] == created["id"]
    assert body["created_at"] and body["updated_at"]


# -------------------------------------------------------------- timestamps
def test_plano_timestamps(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    created = client.put(_plano_base(gid), json=_plano_payload(), headers=_bearer(access)).json()
    updated = client.put(
        _plano_base(gid), json=_plano_payload(via_parto="cesarea"), headers=_bearer(access)
    ).json()
    assert updated["id"] == created["id"]
    assert datetime.fromisoformat(updated["created_at"]) == datetime.fromisoformat(created["created_at"])
    assert datetime.fromisoformat(updated["updated_at"]) != datetime.fromisoformat(created["updated_at"])


# --------------------------------------------------- sem DELETE (sem rota)
def test_plano_no_delete_route_405(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    client.put(_plano_base(gid), json=_plano_payload(), headers=_bearer(access))
    r = client.delete(_plano_base(gid), headers=_bearer(access))
    assert r.status_code == 405


# -------------------------------------------------------------- regressões
def test_regression_auth_8d_8g_coexist(client_engine) -> None:
    client, _ = client_engine
    access, gid = _register_and_setup_gestacao(client)
    assert client.get("/api/v1/auth/me", headers=_bearer(access)).status_code == 200
    assert client.get("/api/v1/gestantes/me", headers=_bearer(access)).status_code == 200
    assert client.get(f"/api/v1/gestacoes/{gid}", headers=_bearer(access)).status_code == 200
    # plano de parto convive com medicamento/vacina da gestação
    assert client.put(_plano_base(gid), json=_plano_payload(), headers=_bearer(access)).status_code == 200
    assert (
        client.post(
            f"/api/v1/gestacoes/{gid}/medicamentos",
            json={"nome": "Ácido fólico", "dose": "5mg", "frequencia": "1 vez ao dia"},
            headers=_bearer(access),
        ).status_code
        == 201
    )
    assert (
        client.post(
            f"/api/v1/gestacoes/{gid}/vacinas",
            json={"nome": "dTpa", "aplicada": False},
            headers=_bearer(access),
        ).status_code
        == 201
    )
