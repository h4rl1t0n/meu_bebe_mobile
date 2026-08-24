"""FASE 4D — Congelamento do contrato HTTP do ``POST /api/v1/risk-estimate``.

Cobre as propriedades de transporte (método, status, content-type) e a
estatelessness do endpoint, além de uma matriz consolidada das quatro respostas
possíveis (200 / 422 / 500 / 503). O objetivo é CONGELAR o contrato para a
integração futura do Flutter (Dio) — sem implementar o cliente.
"""

from __future__ import annotations

import copy
from pathlib import Path

from fastapi.testclient import TestClient

from meu_bebe_api.config import Settings
from meu_bebe_api.contracts.risk_estimate import (
    EXPERIMENTAL_ESTIMATE_NOTICE,
    EXPERIMENTAL_TARGET,
)
from meu_bebe_api.main import create_app
from meu_bebe_api.ml.runtime import ModelMetadata

_FIXTURE_PATH = Path(__file__).parent / "fixtures" / "flutter_dss_payload_v1_13.json"


class FakeRuntime:
    """Stub mínimo da interface do ``ModelRuntime``."""

    def __init__(self, *, ready=True, probability=0.321, raise_exc=None):
        self._ready = ready
        self._probability = probability
        self._raise_exc = raise_exc
        self.predict_calls = 0
        self.received: list = []
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
        self.received.append(payload)
        if self._raise_exc is not None:
            raise self._raise_exc
        return self._probability


def _make_client(runtime) -> TestClient:
    return TestClient(
        create_app(Settings(model_load_on_startup=False, _env_file=None), runtime=runtime)
    )


def _fixture() -> dict:
    import json

    return json.loads(_FIXTURE_PATH.read_text(encoding="utf-8"))


_URL = "/api/v1/risk-estimate"


# ---------------------------------------------------------------------------
# Content-Type: toda resposta é application/json
# ---------------------------------------------------------------------------


def test_200_content_type_is_json():
    with _make_client(FakeRuntime(probability=0.2)) as c:
        resp = c.post(_URL, json=_fixture())
    assert resp.status_code == 200
    assert resp.headers["content-type"].startswith("application/json")


def test_422_content_type_is_json():
    payload = _fixture()
    payload["educacao"]["escolaridade"] = "inventado"
    with _make_client(FakeRuntime(ready=True)) as c:
        resp = c.post(_URL, json=payload)
    assert resp.status_code == 422
    assert resp.headers["content-type"].startswith("application/json")


def test_503_content_type_is_json():
    with _make_client(FakeRuntime(ready=False)) as c:
        resp = c.post(_URL, json=_fixture())
    assert resp.status_code == 503
    assert resp.headers["content-type"].startswith("application/json")


def test_500_content_type_is_json():
    with _make_client(FakeRuntime(ready=True, raise_exc=RuntimeError("x"))) as c:
        resp = c.post(_URL, json=_fixture())
    assert resp.status_code == 500
    assert resp.headers["content-type"].startswith("application/json")


# ---------------------------------------------------------------------------
# Método HTTP: apenas POST (GET/PUT/DELETE/PATCH -> 405)
# ---------------------------------------------------------------------------


def test_get_returns_405():
    runtime = FakeRuntime(ready=True)
    with _make_client(runtime) as c:
        resp = c.get(_URL)
    assert resp.status_code == 405
    assert runtime.predict_calls == 0


def test_put_returns_405():
    runtime = FakeRuntime(ready=True)
    with _make_client(runtime) as c:
        resp = c.put(_URL, json=_fixture())
    assert resp.status_code == 405
    assert runtime.predict_calls == 0


def test_delete_returns_405():
    runtime = FakeRuntime(ready=True)
    with _make_client(runtime) as c:
        resp = c.delete(_URL)
    assert resp.status_code == 405
    assert runtime.predict_calls == 0


# ---------------------------------------------------------------------------
# Corpo ausente / JSON malformado -> 422 (runtime NÃO chamado)
# ---------------------------------------------------------------------------


def test_post_without_body_returns_422():
    runtime = FakeRuntime(ready=True)
    with _make_client(runtime) as c:
        resp = c.post(_URL, headers={"content-type": "application/json"})
    assert resp.status_code == 422
    assert resp.json()["code"] == "VALIDATION_ERROR"
    assert runtime.predict_calls == 0


def test_post_malformed_json_returns_422():
    runtime = FakeRuntime(ready=True)
    with _make_client(runtime) as c:
        resp = c.post(
            _URL,
            content=b"{isto nao e json",
            headers={"content-type": "application/json"},
        )
    assert resp.status_code == 422
    assert resp.json()["code"] == "VALIDATION_ERROR"
    assert runtime.predict_calls == 0


# ---------------------------------------------------------------------------
# Stateless: cada request é independente (sem estado/persistência entre eles)
# ---------------------------------------------------------------------------


def test_stateless_between_requests():
    runtime = FakeRuntime(probability=0.5)
    payload_a = _fixture()
    payload_b = copy.deepcopy(payload_a)
    payload_b["educacao"]["escolaridade"] = "superior_completo"

    with _make_client(runtime) as c:
        assert c.post(_URL, json=payload_a).status_code == 200
        assert c.post(_URL, json=payload_b).status_code == 200

    # A API repassa cada corpo intacto e de forma independente (sem misturar).
    assert len(runtime.received) == 2
    assert runtime.received[0].educacao.escolaridade == "medio_incompleto"
    assert runtime.received[1].educacao.escolaridade == "superior_completo"


# ---------------------------------------------------------------------------
# Matriz consolidada de respostas (congelamento do contrato)
# ---------------------------------------------------------------------------


def test_response_matrix_200():
    with _make_client(FakeRuntime(probability=0.222)) as c:
        resp = c.post(_URL, json=_fixture())
    body = resp.json()
    assert resp.status_code == 200
    assert body["result"]["target"] == EXPERIMENTAL_TARGET
    assert body["result"]["probability"] == 0.222
    assert body["model"] == {
        "name": "random_forest",
        "schema_version": "1.13",
        "raw_feature_count": 34,
        "transformed_feature_count": 96,
    }
    assert body["notice"] == EXPERIMENTAL_ESTIMATE_NOTICE
    assert set(body.keys()) == {"result", "model", "notice"}


def test_response_matrix_422():
    payload = _fixture()
    payload["habitacao"]["numero_comodos"] = 1
    payload["habitacao"]["numero_dormitorios"] = 5
    with _make_client(FakeRuntime(ready=True)) as c:
        resp = c.post(_URL, json=payload)
    assert resp.status_code == 422
    body = resp.json()
    # Formato PLANO (congelado FASE 4A), sem wrapper "error".
    assert set(body.keys()) == {"code", "message", "details"}
    assert body["code"] == "VALIDATION_ERROR"
    assert body["message"] == "Requisição inválida"
    assert isinstance(body["details"], list) and body["details"]


def test_response_matrix_503():
    with _make_client(FakeRuntime(ready=False)) as c:
        resp = c.post(_URL, json=_fixture())
    assert resp.status_code == 503
    assert resp.json() == {
        "error": {
            "code": "MODEL_NOT_READY",
            "message": "Modelo de inferência indisponível.",
            "details": [],
        }
    }


def test_response_matrix_500():
    with _make_client(FakeRuntime(ready=True, raise_exc=RuntimeError("secreto"))) as c:
        resp = c.post(_URL, json=_fixture())
    assert resp.status_code == 500
    body = resp.json()
    assert body == {
        "error": {
            "code": "INFERENCE_ERROR",
            "message": "Não foi possível calcular a estimativa.",
            "details": [],
        }
    }
    # Sanitização: a mensagem interna nunca vaza.
    assert "secreto" not in resp.text
