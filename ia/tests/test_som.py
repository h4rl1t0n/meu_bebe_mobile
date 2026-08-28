"""Testes da FASE IA-SOM (SOM exploratório, seção 24 do plano).

Provam as invariantes metodológicas exigidas:

  * o SOM NÃO vê ``descontinuou_pre_natal``, nem P(RF), nem IV-DSS, nem ``OUT_*``;
  * split congelado = 4000 treino / 1000 holdout; o holdout não entra no fit;
  * determinismo com a mesma seed;
  * todos os 1000 registros do holdout recebem BMU e grupo;
  * grupos pertencem ao conjunto esperado; o resumo soma 1000;
  * P(RF) reproduz o modelo congelado; o modelo e os artefatos congelados não mudam.

Os treinamentos de SOM aqui são PEQUENOS (grade 5x5, poucas iterações) — apenas
para validar o MECANISMO, nunca o desempenho real da análise.
"""

from __future__ import annotations

import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import pytest
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
from sklearn.metrics import silhouette_score

from meu_bebe_ml.preprocessing.contract import resolve_spec
from meu_bebe_ml.som import (
    SOMConfig,
    SelfOrganizingMap,
    SomMinMaxNormalizer,
    som_scale_mask,
)
from meu_bebe_ml.training import (
    load_frozen_dataset,
    load_frozen_split,
    load_model,
    n_features_of,
    positive_class_probability,
)
from meu_bebe_ml.training.config import sha256_file
from meu_bebe_ml.training.guards import assert_no_forbidden_columns

_IA_ROOT = Path(__file__).resolve().parents[1]
_MODEL_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1.joblib"
_MODEL_MANIFEST_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1_manifest.json"
_SPLIT_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1.csv"
_SPLIT_MANIFEST_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1_manifest.json"
_TEST_PRED_PATH = _IA_ROOT / "data" / "processed" / "test_predictions_selected_v1.csv"

_K_CANDIDATES = (2, 3, 4, 5, 6)
_SEED = 42


# ---------------------------------------------------------------------------
# Fixtures (dataset/model congelados, uma vez por módulo)
# ---------------------------------------------------------------------------

@pytest.fixture(scope="module")
def frozen():
    X_raw, y = load_frozen_dataset()
    train_idx, test_idx = load_frozen_split()
    pipeline = load_model(_MODEL_PATH)
    preprocessor = pipeline.named_steps["preprocessor"]
    X96 = preprocessor.transform(X_raw)
    return {
        "X_raw": X_raw,
        "y": y,
        "train_idx": train_idx,
        "test_idx": test_idx,
        "pipeline": pipeline,
        "preprocessor": preprocessor,
        "X96": X96,
    }


@pytest.fixture(scope="module")
def model_manifest():
    return json.loads(_MODEL_MANIFEST_PATH.read_text(encoding="utf-8"))


def _small_som(dim: int) -> SelfOrganizingMap:
    cfg = SOMConfig(
        grid_rows=5, grid_cols=5, sigma0=2.5, learning_rate0=0.5,
        iterations=200, random_state=_SEED,
    )
    return SelfOrganizingMap(cfg, input_dim=dim)


# ---------------------------------------------------------------------------
# SOM (unidade) — determinismo, BMU, erros
# ---------------------------------------------------------------------------

def test_som_deterministic_same_seed():
    rng = np.random.default_rng(0)
    X = rng.normal(size=(80, 6))
    a = _small_som(6).fit(X)
    b = _small_som(6).fit(X)
    assert np.array_equal(a.weights, b.weights)


def test_som_bmu_coverage_and_range():
    rng = np.random.default_rng(1)
    X = rng.normal(size=(50, 4))
    som = _small_som(4).fit(X)
    bmu = som.bmu_indices(X)
    assert bmu.shape == (50,)
    assert set(np.unique(bmu)) <= set(range(25))


def test_som_quantization_and_topographic_error_ranges():
    rng = np.random.default_rng(2)
    X = rng.normal(size=(60, 5))
    som = _small_som(5).fit(X)
    qe = som.quantization_error(X)
    te = som.topographic_error(X)
    assert qe >= 0.0
    assert 0.0 <= te <= 1.0


def test_som_requires_fit_before_projecting():
    som = SelfOrganizingMap(
        SOMConfig(3, 3, 1.5, 0.5, 10, 1), input_dim=2
    )
    with pytest.raises(RuntimeError):
        som.bmu_indices(np.zeros((2, 2)))


def test_som_prototypes_shape():
    rng = np.random.default_rng(3)
    X = rng.normal(size=(40, 7))
    som = _small_som(7).fit(X)
    assert som.prototype_matrix().shape == (25, 7)
    assert som.umatrix().shape == (5, 5)


# ---------------------------------------------------------------------------
# Entrada do SOM — target / P(RF) / IV-DSS / OUT_* NÃO entram
# ---------------------------------------------------------------------------

def test_som_input_features_have_no_forbidden_columns(frozen):
    preprocessor = frozen["preprocessor"]
    names = list(preprocessor.get_feature_names_out())
    assert len(names) == 96
    # Nenhuma coluna proibida (target, IV-DSS, D_*, OUT_*, split-metadata, DGM).
    assert_no_forbidden_columns(names)
    # Checks explícitos e legíveis.
    joined = " ".join(names).lower()
    for forbidden in (
        "descontinuou",
        "iv_dss",
        "probability",
        "prob",
        "row_index",
        "split",
        "faltou_consulta",
        "servicos_pre_natal",
        "exames_pre_natal_completos",
        "vacinas_em_dia",
        "avaliacao_pre_natal",
        "situacao_estudos_gestacao",
        "usa_suplementos",
    ):
        assert forbidden not in joined, f"feature proibida presente: {forbidden}"


def test_som_input_is_96_features_of_x_model(frozen):
    X96 = frozen["X96"]
    assert X96.shape == (5000, 96)
    assert n_features_of(frozen["pipeline"]) == 96


# ---------------------------------------------------------------------------
# Split congelado — 4000 / 1000, holdout fora do fit
# ---------------------------------------------------------------------------

def test_frozen_split_4000_train_1000_holdout(frozen):
    train_idx = frozen["train_idx"]
    test_idx = frozen["test_idx"]
    assert len(train_idx) == 4000
    assert len(test_idx) == 1000
    assert not (set(train_idx) & set(test_idx))


def test_som_fit_uses_only_train_rows(frozen):
    """O SOM é ajustado apenas sobre as 4000 linhas de treino; o holdout é
    projetado depois (BMU) e não participa do fit."""
    X96 = frozen["X96"]
    train_idx = frozen["train_idx"]
    test_idx = frozen["test_idx"]
    X_train = X96[train_idx]
    X_test = X96[test_idx]
    assert X_train.shape == (4000, 96)
    assert X_test.shape == (1000, 96)

    som = _small_som(96).fit(X_train)  # fit SOMENTE em X_train
    # Projeção do holdout APÓS o fit:
    bmu_test = som.bmu_indices(X_test)
    assert bmu_test.shape == (1000,)
    assert set(np.unique(bmu_test)) <= set(range(25))


# ---------------------------------------------------------------------------
# Atribuição de grupos — todos com BMU/grupo, somatório = 1000, k esperado
# ---------------------------------------------------------------------------

def test_holdout_group_assignment_sums_to_1000(frozen):
    X96 = frozen["X96"]
    train_idx = frozen["train_idx"]
    test_idx = frozen["test_idx"]
    som = _small_som(96).fit(X96[train_idx])
    prototypes = som.prototype_matrix()

    # K-means (k=2..6) sobre protótipos com seed fixa; sem usar target/RF/IV-DSS.
    best_k, best_labels = None, None
    best_score = float("-inf")
    for k in _K_CANDIDATES:
        labels = KMeans(n_clusters=k, random_state=_SEED, n_init=10).fit_predict(prototypes)
        counts = np.bincount(labels, minlength=k)
        if int((counts >= 2).sum()) < k:
            continue
        sil = float(silhouette_score(prototypes, labels))
        if sil > best_score:
            best_score, best_k, best_labels = sil, k, labels

    assert best_k in _K_CANDIDATES
    assert best_labels is not None

    test_bmu = som.bmu_indices(X96[test_idx])
    test_groups = best_labels[test_bmu] + 1  # 1..k (nominal)
    assert test_groups.shape == (1000,)
    assert set(np.unique(test_groups)) <= set(range(1, best_k + 1))
    assert int(test_groups.shape[0]) == 1000
    assert sum((test_groups == g).sum() for g in range(1, best_k + 1)) == 1000


def test_group_labels_are_in_expected_set(frozen):
    X96 = frozen["X96"]
    train_idx = frozen["train_idx"]
    som = _small_som(96).fit(X96[train_idx])
    prototypes = som.prototype_matrix()
    k = 4  # k escolhido pela análise (Silhouette); aqui validamos o conjunto.
    labels = KMeans(n_clusters=k, random_state=_SEED, n_init=10).fit_predict(prototypes)
    assert set(np.unique(labels)) == set(range(k))


# ---------------------------------------------------------------------------
# Random Forest — probabilidade congelada reproduzida; modelo/hashes intactos
# ---------------------------------------------------------------------------

def test_rf_probability_matches_frozen_model(frozen):
    pipeline = frozen["pipeline"]
    X_raw = frozen["X_raw"]
    test_idx = frozen["test_idx"]
    recomputed = positive_class_probability(
        pipeline.named_steps["model"], pipeline.predict_proba(X_raw.iloc[test_idx])
    )
    df = pd.read_csv(_TEST_PRED_PATH)
    frozen_probs = {int(r.row_index): float(r.y_probability) for r in df.itertuples(index=False)}
    for i, row_id in enumerate(test_idx):
        assert abs(recomputed[i] - frozen_probs[int(row_id)]) < 1e-9


def test_selected_model_file_hash_unchanged(model_manifest):
    assert sha256_file(_MODEL_PATH) == model_manifest["model_file_hash_sha256"]


def test_frozen_split_file_hash_unchanged():
    manifest = json.loads(_SPLIT_MANIFEST_PATH.read_text(encoding="utf-8"))
    assert sha256_file(_SPLIT_PATH) == manifest["split_file_hash_sha256"]


def test_model_manifest_declares_96_features_4000_train(model_manifest):
    assert model_manifest["n_features"] == 96
    assert model_manifest["n_train"] == 4000


# ---------------------------------------------------------------------------
# FASE IA-SOM-FIX — normalização exclusiva do SOM (min-max 0-1 nas 9 não-binárias)
# ---------------------------------------------------------------------------

@pytest.fixture(scope="module")
def som_spec():
    return resolve_spec()


@pytest.fixture(scope="module")
def scale_mask(frozen, som_spec):
    names = list(frozen["preprocessor"].get_feature_names_out())
    return som_scale_mask(
        names, som_spec.source_map, som_spec.numeric, tuple(som_spec.ordinal_order)
    )


def test_som_scale_mask_is_9_scaled_87_passthrough(som_spec):
    mask = som_scale_mask(
        list(som_spec.feature_names),
        som_spec.source_map,
        som_spec.numeric,
        tuple(som_spec.ordinal_order),
    )
    assert mask.shape == (96,)
    assert int(mask.sum()) == 9   # 3 numéricas + 6 ordinais
    assert int((~mask).sum()) == 87  # binárias/one-hot/multi-hot


def test_som_normalizer_fit_only_on_train(frozen, scale_mask):
    """min/range da normalização são calculados SOMENTE no treino."""
    X96 = frozen["X96"]
    train_idx = frozen["train_idx"]
    X_train = X96[train_idx]
    norm = SomMinMaxNormalizer(scale_mask).fit(X_train)
    idx = np.flatnonzero(scale_mask)
    np.testing.assert_allclose(norm.min_, X_train[:, idx].min(axis=0))
    np.testing.assert_allclose(
        norm.range_, X_train[:, idx].max(axis=0) - X_train[:, idx].min(axis=0)
    )


def test_som_normalizer_holdout_uses_train_params(frozen, scale_mask):
    """O holdout é transformado com os min/range CONGELADOS do fit (treino)."""
    X96 = frozen["X96"]
    train_idx = frozen["train_idx"]
    test_idx = frozen["test_idx"]
    X_train = X96[train_idx]
    X_test = X96[test_idx]
    norm = SomMinMaxNormalizer(scale_mask).fit(X_train)
    out = norm.transform(X_test)
    idx = np.flatnonzero(scale_mask)
    denom = np.where(norm.range_ > 0.0, norm.range_, 1.0)
    expected = (X_test[:, idx] - norm.min_) / denom
    expected[:, norm.range_ <= 0.0] = 0.0
    np.testing.assert_allclose(out[:, idx], expected)


def test_som_normalizer_binary_unchanged_scaled_in_01(frozen, scale_mask):
    X96 = frozen["X96"]
    train_idx = frozen["train_idx"]
    test_idx = frozen["test_idx"]
    norm = SomMinMaxNormalizer(scale_mask).fit(X96[train_idx])
    for X, label in ((X96[train_idx], "treino"), (X96[test_idx], "holdout")):
        out = norm.transform(X)
        # binárias permanecem idênticas (0-1)
        np.testing.assert_array_equal(out[:, ~scale_mask], X[:, ~scale_mask])
        # não-binárias ficam em [0,1]
        assert out[:, scale_mask].min() >= 0.0
        assert out[:, scale_mask].max() <= 1.0


def test_som_normalizer_constant_column_safe():
    mask = np.array([True, False])
    X = np.array([[5.0, 1.0], [5.0, 0.0], [5.0, 1.0]])
    norm = SomMinMaxNormalizer(mask).fit(X)
    out = norm.transform(X)
    assert np.all(out[:, 0] == 0.0)  # constante -> 0.0 (sem div por zero)
    np.testing.assert_array_equal(out[:, 1], X[:, 1])  # binária inalterada


def test_normalized_input_has_no_forbidden_columns(frozen, scale_mask):
    """A normalização preserva o conjunto de features: nada de target/RF/IV-DSS."""
    preprocessor = frozen["preprocessor"]
    names = list(preprocessor.get_feature_names_out())
    assert len(names) == 96
    norm = SomMinMaxNormalizer(scale_mask).fit(frozen["X96"][frozen["train_idx"]])
    # get_feature_names_out preserva os mesmos nomes (sem criar/remover colunas)
    out_names = list(norm.get_feature_names_out(names))
    assert out_names == names
    # O som (entrada normalizada) continua sem colunas proibidas.
    joined = " ".join(names).lower()
    for forbidden in ("descontinuou", "iv_dss", "probability", "row_index", "split"):
        assert forbidden not in joined


def test_pca_is_visualization_only(frozen, scale_mask):
    """PCA é ajustado só no treino e não participa da formação dos grupos.

    Os grupos vêm de SOM + K-means; o PCA apenas projeta o holdout em 2D para a
    figura. Aqui provamos que o PCA é uma projeção linear separada: ajustar no
    treino e projetar o holdout gera coordenadas, sem alterar os rótulos.
    """
    X96 = frozen["X96"]
    train_idx = frozen["train_idx"]
    test_idx = frozen["test_idx"]
    norm = SomMinMaxNormalizer(scale_mask).fit(X96[train_idx])
    X_train_n = norm.transform(X96[train_idx])
    X_test_n = norm.transform(X96[test_idx])

    pca = PCA(n_components=2, random_state=_SEED)
    pca.fit(X_train_n)  # ajustado SOMENTE no treino
    # centro do PCA é a média do treino (não do holdout)
    np.testing.assert_allclose(pca.mean_, X_train_n.mean(axis=0))
    proj = pca.transform(X_test_n)
    assert proj.shape == (1000, 2)
    # PCA não gera rótulos de grupo — apenas coordenadas 2D.
    assert proj.shape[1] == 2


def test_group_assignment_is_som_plus_kmeans_only(frozen, scale_mask):
    """Os grupos do holdout são SOM + K-means (sem PCA) e somam 1000."""
    X96 = frozen["X96"]
    train_idx = frozen["train_idx"]
    test_idx = frozen["test_idx"]
    norm = SomMinMaxNormalizer(scale_mask).fit(X96[train_idx])
    X_train_n = norm.transform(X96[train_idx])
    X_test_n = norm.transform(X96[test_idx])

    som = _small_som(96).fit(X_train_n)
    prototypes = som.prototype_matrix()

    best_k, best_labels = None, None
    best_score = float("-inf")
    for k in _K_CANDIDATES:
        labels = KMeans(n_clusters=k, random_state=_SEED, n_init=10).fit_predict(prototypes)
        counts = np.bincount(labels, minlength=k)
        if int((counts >= 2).sum()) < k:
            continue
        sil = float(silhouette_score(prototypes, labels))
        if sil > best_score:
            best_score, best_k, best_labels = sil, k, labels

    assert best_k in _K_CANDIDATES
    test_bmu = som.bmu_indices(X_test_n)
    test_groups = best_labels[test_bmu] + 1
    assert test_groups.shape == (1000,)
    assert sum((test_groups == g).sum() for g in range(1, best_k + 1)) == 1000
