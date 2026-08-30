"""Testes HTTP do ``POST /api/v1/risk-estimate`` (FASE 4C) com runtime FAKE.

O fake representa apenas a INTERFACE do ``ModelRuntime`` (não simula sklearn);
assim os testes HTTP não carregam o modelo real.
"""

from __future__ import annotations

import copy

from fastapi.testclient import TestClient

from conftest import make_valid_payload
from meu_bebe_api.config import Settings
from meu_bebe_api.contracts.risk_estimate import (
    EXPERIMENTAL_ESTIMATE_NOTICE,
    EXPERIMENTAL_TARGET,
)
from meu_bebe_api.main import create_app
from meu_bebe_api.ml.runtime import ModelMetadata

_MODEL_NOT_READY_BODY = {
    "error": {
        "code": "MODEL_NOT_READY",
        "message": "Modelo de inferência indisponível.",
        "details": [],
    }
}
_INFERENCE_ERROR_BODY = {
    "error": {
        "code": "INFERENCE_ERROR",
        "message": "Não foi possível calcular a estimativa.",
        "details": [],
    }
}


class FakeRuntime:
    """Stub mínimo da interface do ``ModelRuntime``."""

    def __init__(self, *, ready=True, probability=0.321, raise_exc=None):
        self._ready = ready
        self._probability = probability
        self._raise_exc = raise_exc
        self.predict_calls = 0
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
        return self._ready

    @property
    def metadata(self):
        return self._metadata if self._ready else None

    def load(self):
        pass

    def predict_probability(self, payload):
        self.predict_calls += 1
        if self._raise_exc is not None:
            raise self._raise_exc
        return self._probability


def _make_client(runtime, *, docs_enabled=True) -> TestClient:
    settings = Settings(
        model_load_on_startup=False, app_docs_enabled=docs_enabled, _env_file=None
    )
    return TestClient(create_app(settings, runtime=runtime))


def _collect_keys(value) -> set[str]:
    """Coleta (recursivamente) todas as chaves de um JSON/objeto Python."""
    keys: set[str] = set()
    if isinstance(value, dict):
        for key, sub in value.items():
            keys.add(key)
            keys.update(_collect_keys(sub))
    elif isinstance(value, list):
        for item in value:
            keys.update(_collect_keys(item))
    return keys


# ---------------------------------------------------------------------------
# 200 — sucesso
# ---------------------------------------------------------------------------


def test_200_with_fake_runtime():
    runtime = FakeRuntime(probability=0.321)
    with _make_client(runtime) as c:
        resp = c.post("/api/v1/risk-estimate", json=make_valid_payload())

    assert resp.status_code == 200
    body = resp.json()
    assert body["result"]["target"] == EXPERIMENTAL_TARGET
    assert body["result"]["probability"] == 0.321
    assert body["model"] == {
        "name": "random_forest",
        "schema_version": "1.13",
        "raw_feature_count": 34,
        "transformed_feature_count": 96,
    }
    assert body["notice"] == EXPERIMENTAL_ESTIMATE_NOTICE
    assert runtime.predict_calls == 1


def test_probability_preserved_without_rounding():
    value = 0.321987654321
    runtime = FakeRuntime(probability=value)
    with _make_client(runtime) as c:
        body = c.post("/api/v1/risk-estimate", json=make_valid_payload()).json()

    assert body["result"]["probability"] == value


def test_determinism_http():
    runtime = FakeRuntime(probability=0.222)
    with _make_client(runtime) as c:
        b1 = c.post("/api/v1/risk-estimate", json=make_valid_payload()).json()
        b2 = c.post("/api/v1/risk-estimate", json=make_valid_payload()).json()

    assert b1 == b2
    assert b1["result"]["probability"] == b2["result"]["probability"]


# ---------------------------------------------------------------------------
# Campos proibidos na resposta de sucesso (§67)
# ---------------------------------------------------------------------------


def test_success_has_no_forbidden_fields():
    runtime = FakeRuntime(probability=0.321)
    with _make_client(runtime) as c:
        body = c.post("/api/v1/risk-estimate", json=make_valid_payload()).json()

    keys = _collect_keys(body)
    forbidden = {
        "threshold",
        "class",
        "predicted_class",
        "classification",
        "risk_level",
        "risk_category",
        "abandona",
        "diagnosis",
        "recommendation",
        "feature_importance",
        "shap",
        "features",
        "questionnaire",
        "input",
    }
    assert keys.isdisjoint(forbidden)


def test_success_does_not_echo_input():
    runtime = FakeRuntime(probability=0.321)
    with _make_client(runtime) as c:
        resp = c.post("/api/v1/risk-estimate", json=make_valid_payload())

    # Nenhuma resposta individual do questionário deve ser ecoada.
    assert "medio_completo" not in resp.text
    assert "rede_publica" not in resp.text
    assert "questionnaire" not in resp.text


# ---------------------------------------------------------------------------
# 503 — modelo não pronto
# ---------------------------------------------------------------------------


def test_503_when_runtime_not_ready():
    runtime = FakeRuntime(ready=False)
    with _make_client(runtime) as c:
        resp = c.post("/api/v1/risk-estimate", json=make_valid_payload())

    assert resp.status_code == 503
    assert resp.json() == _MODEL_NOT_READY_BODY
    assert runtime.predict_calls == 0


# ---------------------------------------------------------------------------
# 500 — falha inesperada de inferência
# ---------------------------------------------------------------------------


def test_500_when_predict_raises():
    runtime = FakeRuntime(ready=True, raise_exc=RuntimeError("falha interna secreta"))
    with _make_client(runtime) as c:
        resp = c.post("/api/v1/risk-estimate", json=make_valid_payload())

    assert resp.status_code == 500
    assert resp.json() == _INFERENCE_ERROR_BODY
    # Sanitização: sem texto da exception, sem stack, sem payload.
    assert "falha interna secreta" not in resp.text
    assert "RuntimeError" not in resp.text
    assert "Traceback" not in resp.text
    assert "medio_completo" not in resp.text


# ---------------------------------------------------------------------------
# 422 — validação (runtime NÃO chamado)
# ---------------------------------------------------------------------------


def _post_invalid(runtime, mutate) -> int:
    payload = copy.deepcopy(make_valid_payload())
    mutate(payload)
    with _make_client(runtime) as c:
        resp = c.post("/api/v1/risk-estimate", json=payload)
    return resp


def test_422_missing_required_field():
    runtime = FakeRuntime(ready=True)
    resp = _post_invalid(runtime, lambda p: p.pop("educacao"))
    assert resp.status_code == 422
    assert resp.json()["code"] == "VALIDATION_ERROR"
    assert runtime.predict_calls == 0


def test_422_invalid_enum():
    runtime = FakeRuntime(ready=True)
    resp = _post_invalid(
        runtime, lambda p: p["educacao"].__setitem__("escolaridade", "inventado")
    )
    assert resp.status_code == 422
    assert resp.json()["code"] == "VALIDATION_ERROR"
    assert runtime.predict_calls == 0


def test_422_extra_field():
    runtime = FakeRuntime(ready=True)
    resp = _post_invalid(
        runtime, lambda p: p["educacao"].__setitem__("campo_extra", True)
    )
    assert resp.status_code == 422
    assert resp.json()["code"] == "VALIDATION_ERROR"
    assert runtime.predict_calls == 0


def test_422_structural_invariant():
    runtime = FakeRuntime(ready=True)
    resp = _post_invalid(
        runtime,
        lambda p: (
            p["habitacao"].__setitem__("numero_dormitorios", 10),
            p["habitacao"].__setitem__("numero_comodos", 5),
        ),
    )
    assert resp.status_code == 422
    assert resp.json()["code"] == "VALIDATION_ERROR"
    assert runtime.predict_calls == 0


# ---------------------------------------------------------------------------
# 422 — campos obrigatórios da inferência nulos (FASE 9G-FIX2)
# ---------------------------------------------------------------------------
# O contrato de PERSISTÊNCIA aceita null (questionário incompleto), mas a
# INFERÊNCIA exige os campos do X_MODEL. Estes testes garantem que null NÃO
# chega ao Random Forest: a rota rejeita com 422 no boundary e o runtime NÃO é
# chamado (defesa em profundidade além do Flutter).


def _loc_of(resp, *path: str) -> bool:
    """True se algum detalhe de validação aponta para o `loc` informado."""
    locs = [tuple(d.get("loc", ())) for d in resp.json().get("details", [])]
    return tuple(path) in locs


def test_422_cadastrada_ubs_null_blocks_inference():
    runtime = FakeRuntime(ready=True)
    resp = _post_invalid(
        runtime, lambda p: p["saude"].__setitem__("cadastrada_ubs", None)
    )
    assert resp.status_code == 422
    assert resp.json()["code"] == "VALIDATION_ERROR"
    assert _loc_of(resp, "body", "saude", "cadastrada_ubs")
    assert runtime.predict_calls == 0


def test_422_recebe_beneficio_social_null_blocks_inference():
    runtime = FakeRuntime(ready=True)
    resp = _post_invalid(
        runtime, lambda p: p["trabalho"].__setitem__("recebe_beneficio_social", None)
    )
    assert resp.status_code == 422
    assert resp.json()["code"] == "VALIDATION_ERROR"
    assert _loc_of(resp, "body", "trabalho", "recebe_beneficio_social")
    assert runtime.predict_calls == 0


def test_200_cadastrada_ubs_false_is_valid_answer():
    """``false`` ("Não") é resposta válida — NÃO é confundida com null."""
    runtime = FakeRuntime(probability=0.5)
    payload = copy.deepcopy(make_valid_payload())
    payload["saude"]["cadastrada_ubs"] = False
    with _make_client(runtime) as c:
        resp = c.post("/api/v1/risk-estimate", json=payload)

    assert resp.status_code == 200
    assert runtime.predict_calls == 1


def test_200_recebe_beneficio_social_false_is_valid_answer():
    """``false`` ("Não") é resposta válida — NÃO é confundida com null."""
    runtime = FakeRuntime(probability=0.5)
    payload = copy.deepcopy(make_valid_payload())
    payload["trabalho"]["recebe_beneficio_social"] = False
    with _make_client(runtime) as c:
        resp = c.post("/api/v1/risk-estimate", json=payload)

    assert resp.status_code == 200
    assert runtime.predict_calls == 1


# ---------------------------------------------------------------------------
# OpenAPI
# ---------------------------------------------------------------------------


def test_openapi_documents_risk_estimate():
    runtime = FakeRuntime(ready=True)
    with _make_client(runtime) as c:
        schema = c.get("/openapi.json").json()

    paths = schema["paths"]
    assert "/api/v1/risk-estimate" in paths
    op = paths["/api/v1/risk-estimate"]["post"]

    # Request body é DssPayload (direto, sem wrapper).
    body_schema = op["requestBody"]["content"]["application/json"]["schema"]
    assert body_schema.get("$ref") == "#/components/schemas/DssPayload"
    dss = schema["components"]["schemas"]["DssPayload"]
    for dim in ("educacao", "trabalho", "saneamento", "saude", "habitacao", "alimentacao"):
        assert dim in dss["properties"]

    # Respostas documentadas.
    for status in ("200", "422", "500", "503"):
        assert status in op["responses"]

    # 200 usa RiskEstimateResponse.
    ok_schema = op["responses"]["200"]["content"]["application/json"]["schema"]
    assert ok_schema.get("$ref") == "#/components/schemas/RiskEstimateResponse"


def test_no_aliases_in_openapi():
    runtime = FakeRuntime(ready=True)
    with _make_client(runtime) as c:
        paths = c.get("/openapi.json").json()["paths"]

    for alias in ("/predict", "/prediction", "/predictions", "/inference",
                  "/estimate", "/classify", "/api/v1/predict"):
        assert alias not in paths


# ---------------------------------------------------------------------------
# Docs disabled — endpoint funcional continua existindo
# ---------------------------------------------------------------------------


def test_docs_disabled_endpoint_still_works():
    runtime = FakeRuntime(probability=0.5)
    with _make_client(runtime, docs_enabled=False) as c:
        assert c.get("/docs").status_code == 404
        assert c.get("/redoc").status_code == 404
        assert c.get("/openapi.json").status_code == 404
        resp = c.post("/api/v1/risk-estimate", json=make_valid_payload())
        assert resp.status_code == 200
        assert resp.json()["result"]["probability"] == 0.5
