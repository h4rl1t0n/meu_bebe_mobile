"""Testes do contrato de erro (envelope padronizado)."""

from __future__ import annotations

from conftest import make_valid_payload


def test_validation_error_format(client_with_validation_route):
    payload = make_valid_payload()
    payload["educacao"]["escolaridade"] = "codigo_inventado"

    resp = client_with_validation_route.post("/_test/validate", json=payload)

    assert resp.status_code == 422
    body = resp.json()
    assert body["code"] == "VALIDATION_ERROR"
    assert body["message"] == "Requisição inválida"
    assert isinstance(body["details"], list)
    assert body["details"]


def test_validation_error_details_shape_and_no_input_leak(client_with_validation_route):
    payload = make_valid_payload()
    payload["educacao"]["escolaridade"] = "valor_pessoal_secreto"

    body = client_with_validation_route.post(
        "/_test/validate", json=payload
    ).json()

    for detail in body["details"]:
        assert set(detail.keys()) == {"loc", "msg", "type"}
        assert isinstance(detail["loc"], list)
        assert isinstance(detail["msg"], str)
        assert isinstance(detail["type"], str)
        # Nenhum valor rejeitado (input) nem body bruto pode vazar.
        assert "input" not in detail
        assert "valor_pessoal_secreto" not in str(detail)


def test_missing_key_returns_422(client_with_validation_route):
    payload = make_valid_payload()
    del payload["educacao"]

    resp = client_with_validation_route.post("/_test/validate", json=payload)
    assert resp.status_code == 422
    assert resp.json()["code"] == "VALIDATION_ERROR"


def test_not_found_error_format(client):
    # /api/v1 fica reservado: /api/v1/health deve retornar 404 com o envelope.
    resp = client.get("/api/v1/health")
    assert resp.status_code == 404
    body = resp.json()
    assert body["code"] == "NOT_FOUND"
    assert body["message"] == "Recurso não encontrado"
    assert body["details"] == []


def test_health_has_no_error_wrapper(client):
    # O caminho feliz NÃO usa o envelope de erro.
    assert "code" not in client.get("/health").json()
