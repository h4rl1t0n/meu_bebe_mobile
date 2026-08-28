"""Self-Organizing Map (SOM) mínimo, em NumPy puro, para análise exploratória.

FASE IA-SOM — análise exploratória de perfis DSS (NÃO é modelo preditivo).

Este módulo implementa uma rede de Kohonen 2D determinística, com seed fixa,
usada apenas para AGRUPAR registros por semelhança de perfil DSS. Regras
metodológicas que ele NÃO viola:

  * o SOM NÃO vê o target ``descontinuou_pre_natal``, nem a probabilidade do
    Random Forest, nem o IV-DSS, nem variáveis ``OUT_*`` (leakage/temporal) —
    apenas as features numéricas derivadas de ``X_MODEL`` (34 -> 96) pela
    mesma transformação congelada usada no Random Forest;
  * o ajuste usa somente o conjunto de TREINO (4000 registros); o holdout
    (1000) é apenas PROJETADO (BMU/grupo), nunca usado no fit;
  * nenhuma dependência externa nova é introduzida (numpy/scikit-learn já
    existem na stack congelada).

A API expõe: fit, projeção (BMU), erro de quantização e erro topográfico.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np


@dataclass(frozen=True)
class SOMConfig:
    """Configuração de uma grade SOM (pequena, justificável e registrada)."""

    grid_rows: int
    grid_cols: int
    sigma0: float
    learning_rate0: float
    iterations: int
    random_state: int

    @property
    def n_neurons(self) -> int:
        return self.grid_rows * self.grid_cols


class SelfOrganizingMap:
    """Kohonen SOM 2D com vizinhança gaussiana e decaimento exponencial."""

    def __init__(self, config: SOMConfig, input_dim: int) -> None:
        if config.grid_rows <= 0 or config.grid_cols <= 0:
            raise ValueError("grid deve ter dimensões positivas")
        if input_dim <= 0:
            raise ValueError("input_dim deve ser positivo")
        self.config = config
        self.input_dim = input_dim
        # Pesos: (grid_rows, grid_cols, input_dim). Inicializados no fit.
        self.weights: np.ndarray | None = None

    # ------------------------------------------------------------------ fit
    def fit(self, X: np.ndarray) -> "SelfOrganizingMap":
        """Treina o SOM sobre ``X`` (n, input_dim). Determinístico pela seed."""
        X = np.asarray(X, dtype=float)
        if X.ndim != 2 or X.shape[1] != self.input_dim:
            raise ValueError(
                f"X deve ser 2D com {self.input_dim} colunas; recebido {X.shape}"
            )
        n = X.shape[0]
        rng = np.random.default_rng(self.config.random_state)

        rows, cols = self.config.grid_rows, self.config.grid_cols
        # Inicialização: pesos = amostras reais de treino (reprodutível).
        init_idx = rng.integers(0, n, size=(rows, cols))
        self.weights = X[init_idx].astype(float).copy()

        # Coordenadas da grade (para vizinhança).
        rr = np.arange(rows, dtype=float)[:, None]  # (rows, 1)
        cc = np.arange(cols, dtype=float)[None, :]  # (1, cols)

        sigma0 = self.config.sigma0
        lr0 = self.config.learning_rate0
        iterations = self.config.iterations

        # Constantes de tempo do decaimento exponencial.
        tau_sigma = iterations / np.log(sigma0) if sigma0 > 1.0 else iterations
        tau_lr = iterations

        for t in range(iterations):
            sigma = sigma0 * np.exp(-t / tau_sigma)
            lr = lr0 * np.exp(-t / tau_lr)

            x = X[int(rng.integers(0, n))]
            diff = self.weights - x  # (rows, cols, dim)
            dist = np.sqrt((diff * diff).sum(axis=-1))  # (rows, cols)

            bmu = np.unravel_index(int(np.argmin(dist)), (rows, cols))
            d2 = (rr - bmu[0]) ** 2 + (cc - bmu[1]) ** 2  # (rows, cols)
            h = np.exp(-d2 / (2.0 * sigma * sigma))  # (rows, cols)

            self.weights -= lr * h[..., None] * diff

        return self

    # ---------------------------------------------------------------- projeção
    def _distances(self, X: np.ndarray) -> np.ndarray:
        """Distância euclidiana de cada amostra a cada neurônio: (n, n_neurons)."""
        if self.weights is None:
            raise RuntimeError("SOM não ajustado: chame fit() antes")
        X = np.asarray(X, dtype=float)
        w = self.weights.reshape(-1, self.input_dim)  # (n_neurons, dim)
        diff = X[:, None, :] - w[None, :, :]  # (n, n_neurons, dim)
        return np.sqrt((diff * diff).sum(axis=-1))

    def bmu_indices(self, X: np.ndarray) -> np.ndarray:
        """Índice linear (0..n_neurons-1) do BMU de cada amostra: (n,)."""
        return np.argmin(self._distances(X), axis=1)

    def bmu_coords(self, X: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
        """Coordenadas (linha, coluna) do BMU de cada amostra."""
        flat = self.bmu_indices(X)
        return np.unravel_index(flat, (self.config.grid_rows, self.config.grid_cols))

    def quantization_error(self, X: np.ndarray) -> float:
        """Erro de quantização: média da distância de cada amostra ao seu BMU."""
        dist = self._distances(X)
        return float(np.mean(dist[np.arange(dist.shape[0]), np.argmin(dist, axis=1)]))

    def topographic_error(self, X: np.ndarray) -> float:
        """Erro topográfico: fração em que 1º e 2º BMU NÃO são vizinhos.

        Vizinhos = distância de Chebyshev == 1 (inclui diagonais) na grade.
        """
        dist = self._distances(X)
        n = dist.shape[0]
        # Os dois menores índices por linha (argpartition preserva ordem só até k).
        part = np.argpartition(dist, 1, axis=1)[:, :2]
        first_flat = part[:, 0]
        second_flat = part[:, 1]
        first = np.unravel_index(first_flat, (self.config.grid_rows, self.config.grid_cols))
        second = np.unravel_index(second_flat, (self.config.grid_rows, self.config.grid_cols))
        dr = np.abs(np.asarray(first[0]) - np.asarray(second[0]))
        dc = np.abs(np.asarray(first[1]) - np.asarray(second[1]))
        chebyshev = np.maximum(dr, dc)
        return float(np.mean(chebyshev != 1))

    # ---------------------------------------------------------------- grade
    def prototype_matrix(self) -> np.ndarray:
        """Pesos achatados: (n_neurons, input_dim), ordem linear das linhas."""
        if self.weights is None:
            raise RuntimeError("SOM não ajustado: chame fit() antes")
        return self.weights.reshape(-1, self.input_dim)

    def umatrix(self) -> np.ndarray:
        """Matriz-U (U-Matrix): distância média de cada neurônio aos vizinhos.

        Vizinhança de 8 (Chebyshev == 1), com bordas usando só vizinhos válidos.
        Devolve (grid_rows, grid_cols) com valores não negativos.
        """
        if self.weights is None:
            raise RuntimeError("SOM não ajustado: chame fit() antes")
        rows, cols = self.config.grid_rows, self.config.grid_cols
        w = self.weights
        out = np.zeros((rows, cols), dtype=float)
        for r in range(rows):
            for c in range(cols):
                acc = 0.0
                cnt = 0
                for dr in (-1, 0, 1):
                    for dc in (-1, 0, 1):
                        if dr == 0 and dc == 0:
                            continue
                        rr, cc = r + dr, c + dc
                        if 0 <= rr < rows and 0 <= cc < cols:
                            acc += float(np.linalg.norm(w[r, c] - w[rr, cc]))
                            cnt += 1
                out[r, c] = acc / cnt if cnt else 0.0
        return out
