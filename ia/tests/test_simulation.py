"""Testes da configuração congelada do cenário de simulação (DGM).

Valida ``configs/simulation_v1.yaml`` SEM implementar o DGM, sem gerar fatores
``Z`` e sem gerar dataset. Apenas garante que o registro congelado dos
parâmetros é íntegro e utilizável numa futura geração normal multivariada.

A checagem de positividade semidefinida usa decomposição de Cholesky em Python
puro (sem ``numpy``/``scipy``), dentro de tolerância numérica.
"""

from __future__ import annotations

import math
from pathlib import Path
from typing import Any

import yaml

_CONFIG_PATH = (
    Path(__file__).resolve().parents[1] / "configs" / "simulation_v1.yaml"
)


def _load() -> dict[str, Any]:
    with open(_CONFIG_PATH, "r", encoding="utf-8") as fh:
        return yaml.safe_load(fh)


def _cholesky(matrix: list[list[float]], tol: float = 1e-9) -> list[list[float]] | None:
    """Cholesky em Python puro.

    Retorna a matriz ``L`` (triangular inferior) se ``matrix`` for positiva
    semidefinida dentro de ``tol``; retorna ``None`` caso contrário.
    """
    n = len(matrix)
    L: list[list[float]] = [[0.0] * n for _ in range(n)]
    for i in range(n):
        for j in range(i + 1):
            s = matrix[i][j] - sum(L[i][k] * L[j][k] for k in range(j))
            if i == j:
                if s < -tol:
                    return None
                L[i][j] = math.sqrt(s) if s > tol else 0.0
            else:
                if L[j][j] == 0.0:
                    if abs(s) > tol:
                        return None
                    L[i][j] = 0.0
                else:
                    L[i][j] = s / L[j][j]
    return L


def _coefficients() -> dict[str, float]:
    cfg = _load()
    dgm = cfg["dgmgm"]
    result: dict[str, float] = {}
    for factor in dgm["g_factors"]:
        result[factor["name"]] = float(factor["coefficient"])
    for inter in dgm["interactions"]:
        result[inter["name"]] = float(inter["coefficient"])
    return result


# ---------------------------------------------------------------------------
# Planejamento principal
# ---------------------------------------------------------------------------

def test_seed_is_42() -> None:
    assert _load()["seed"] == 42


def test_n_samples_is_5000() -> None:
    assert _load()["n_samples"] == 5000


def test_target_positive_rate_is_025() -> None:
    assert _load()["target_positive_rate"] == 0.25


def test_noise_sd_is_050() -> None:
    assert _load()["noise_sd"] == 0.50


def test_schema_version_is_113() -> None:
    assert _load()["schema_version"] == "1.13"


# ---------------------------------------------------------------------------
# Coeficientes congelados do DGM
# ---------------------------------------------------------------------------

_EXPECTED_COEFFICIENTS: dict[str, float] = {
    "g_escolaridade": 0.50,
    "g_renda": 0.55,
    "g_distancia": 0.45,
    "g_transporte": 0.55,
    "g_organizacao": 0.40,
    "g_trabalho": 0.40,
    "g_privacao_alimentar": 0.30,
    "g_adensamento": 0.25,
    "I1": 0.30,
    "I2": 0.35,
}


def test_exactly_10_frozen_coefficients() -> None:
    assert len(_coefficients()) == 10


def test_coefficient_names_exact() -> None:
    assert set(_coefficients().keys()) == set(_EXPECTED_COEFFICIENTS.keys())


def test_coefficient_values_exact() -> None:
    assert _coefficients() == _EXPECTED_COEFFICIENTS


# ---------------------------------------------------------------------------
# Fatores latentes Z
# ---------------------------------------------------------------------------

def test_exactly_five_z_factors() -> None:
    cfg = _load()
    factors = cfg["latent_factors"]
    assert len(factors) == 5
    assert factors == ["Z_SES", "Z_LAB", "Z_TERR", "Z_INFRA", "Z_SERV"]


# ---------------------------------------------------------------------------
# Matriz de correlação Z
# ---------------------------------------------------------------------------

def test_z_matrix_is_5x5() -> None:
    matrix = _load()["z_correlation_matrix"]
    assert len(matrix) == 5
    assert all(len(row) == 5 for row in matrix)


def test_z_matrix_is_symmetric() -> None:
    matrix = _load()["z_correlation_matrix"]
    for i in range(5):
        for j in range(5):
            assert matrix[i][j] == matrix[j][i], f"assimétrica em ({i},{j})"


def test_z_matrix_diagonal_is_one() -> None:
    matrix = _load()["z_correlation_matrix"]
    for i in range(5):
        assert matrix[i][i] == 1.0, f"diagonal[{i}] != 1"


def test_z_matrix_is_positive_semidefinite() -> None:
    """Matriz válida para geração normal multivariada (Cholesky, tol numérica)."""
    matrix = _load()["z_correlation_matrix"]
    L = _cholesky(matrix)
    assert L is not None, "matriz não é positiva semidefinida"


def test_z_matrix_values_exact() -> None:
    """Confere os valores congelados da matriz conceitual (§12 do doc)."""
    expected = [
        [1.00, 0.45, 0.25, 0.45, 0.10],
        [0.45, 1.00, 0.20, 0.25, 0.10],
        [0.25, 0.20, 1.00, 0.20, 0.25],
        [0.45, 0.25, 0.20, 1.00, 0.10],
        [0.10, 0.10, 0.25, 0.10, 1.00],
    ]
    assert _load()["z_correlation_matrix"] == expected
