"""FASE 4D — Contrato Flutter ↔ API via fixture canônica.

Garante que o JSON canônico que o Flutter produz (``FormularioData.toMap()``)
é exatamente o que a API aceita e consome. A fixture
``tests/fixtures/flutter_dss_payload_v1_13.json`` representa o payload
aninhado + versionado do Flutter — NÃO o ``toFlatMap()`` (que é apenas a visão
interna ``dimensao.campo`` do Flutter, nunca o contrato HTTP).
"""

from __future__ import annotations

import json
from pathlib import Path

from fastapi.testclient import TestClient

from meu_bebe_api.config import Settings
from meu_bebe_api.contracts.dss import (
    DSS_SCHEMA_VERSION,
    AlimentacaoModel,
    DssPayload,
    EducacaoModel,
    HabitacaoModel,
    SaneamentoModel,
    SaudeModel,
    TrabalhoModel,
)
from meu_bebe_api.contracts.risk_estimate import (
    EXPERIMENTAL_ESTIMATE_NOTICE,
    EXPERIMENTAL_TARGET,
)
from meu_bebe_api.main import create_app
from meu_bebe_api.ml.runtime import ModelMetadata

_FIXTURE_PATH = Path(__file__).parent / "fixtures" / "flutter_dss_payload_v1_13.json"

_DIMENSION_FIELDS = {
    "educacao": 6,
    "trabalho": 10,
    "saneamento": 7,
    "saude": 9,
    "habitacao": 9,
    "alimentacao": 7,
}
_DIMENSION_MODELS = {
    "educacao": EducacaoModel,
    "trabalho": TrabalhoModel,
    "saneamento": SaneamentoModel,
    "saude": SaudeModel,
    "habitacao": HabitacaoModel,
    "alimentacao": AlimentacaoModel,
}


class FakeRuntime:
    """Stub mínimo da interface do ``ModelRuntime`` (só HTTP, sem sklearn)."""

    def __init__(self, probability: float = 0.321):
        self._probability = probability
        self._metadata = ModelMetadata(
            name="random_forest",
            raw_feature_count=34,
            transformed_feature_count=96,
            schema_version="1.13",
            positive_class_index=1,
            artifact_sha256="0" * 64,
        )

    @property
    def is_ready(self):
        return True

    @property
    def metadata(self):
        return self._metadata

    def load(self):
        pass

    def predict_probability(self, payload):
        return self._probability


def _load_fixture() -> dict:
    return json.loads(_FIXTURE_PATH.read_text(encoding="utf-8"))


# ---------------------------------------------------------------------------
# Fixture canônica: parse Pydantic
# ---------------------------------------------------------------------------


def test_fixture_is_valid_dss_payload():
    payload = DssPayload.model_validate(_load_fixture())
    assert payload.schema_version == DSS_SCHEMA_VERSION == "1.13"


def test_fixture_has_exactly_six_dimensions():
    fixture = _load_fixture()
    assert set(fixture.keys()) == {
        "schema_version",
        "educacao",
        "trabalho",
        "saneamento",
        "saude",
        "habitacao",
        "alimentacao",
    }


def test_fixture_dimension_field_counts_match_contract():
    for dim, expected in _DIMENSION_FIELDS.items():
        assert len(_load_fixture()[dim]) == expected, dim


def test_fixture_total_is_48_variables():
    total = sum(len(_load_fixture()[dim]) for dim in _DIMENSION_FIELDS)
    assert total == 48


def test_fixture_dimension_field_names_match_contract_models():
    for dim, model in _DIMENSION_MODELS.items():
        assert set(_load_fixture()[dim].keys()) == set(model.model_fields), dim


def test_fixture_does_not_contain_flat_map_keys():
    """A fixture é aninhada; nunca usa a visão ``dimensao.campo`` do Flutter."""
    fixture = _load_fixture()
    for key in fixture.keys():
        assert "." not in key
    assert "escolaridade" not in fixture  # chave de campo não aparece no topo


# ---------------------------------------------------------------------------
# Round-trip Pydantic (payload -> modelo -> payload)
# ---------------------------------------------------------------------------


def test_fixture_round_trips_through_pydantic():
    original = _load_fixture()
    model = DssPayload.model_validate(original)
    serialized = model.model_dump(mode="json")
    assert serialized == original


def test_fixture_round_trips_through_flutter_shape():
    """O dump JSON do DssPayload preserva as 6 dimensões e a versão no topo."""
    model = DssPayload.model_validate(_load_fixture())
    dump = model.model_dump(mode="json")
    assert dump["schema_version"] == "1.13"
    for dim in _DIMENSION_FIELDS:
        assert isinstance(dump[dim], dict)


# ---------------------------------------------------------------------------
# Fixture sobre HTTP (fake runtime) — 200
# ---------------------------------------------------------------------------


def test_fixture_over_http_fake_runtime():
    runtime = FakeRuntime(probability=0.444)
    app = create_app(
        Settings(model_load_on_startup=False, _env_file=None), runtime=runtime
    )
    with TestClient(app) as c:
        resp = c.post("/api/v1/risk-estimate", json=_load_fixture())

    assert resp.status_code == 200
    body = resp.json()
    assert body["result"]["target"] == EXPERIMENTAL_TARGET
    assert body["result"]["probability"] == 0.444
    assert body["model"]["schema_version"] == "1.13"
    assert body["notice"] == EXPERIMENTAL_ESTIMATE_NOTICE


# ---------------------------------------------------------------------------
# Fixture sobre o modelo REAL (≤1e-12)
# ---------------------------------------------------------------------------


def test_fixture_over_http_real_model_matches_runtime(real_runtime):
    payload = DssPayload.model_validate(_load_fixture())
    app = create_app(
        Settings(model_load_on_startup=False, _env_file=None), runtime=real_runtime
    )
    with TestClient(app) as c:
        resp = c.post(
            "/api/v1/risk-estimate", json=_load_fixture()
        )

    assert resp.status_code == 200
    proba = resp.json()["result"]["probability"]

    expected = real_runtime.predict_probability(payload)
    assert isinstance(proba, float)
    assert 0.0 <= proba <= 1.0
    assert abs(proba - expected) <= 1e-12
