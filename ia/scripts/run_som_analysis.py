"""FASE IA-SOM-FIX — pipeline SOM exploratório (com normalização exclusiva do SOM).

Correção metodológica da FASE IA-SOM: o SOM usa distância euclidiana, então as
9 features não-binárias (3 numéricas + 6 ordinais) são normalizadas para [0,1]
(min-max) EXCLUSIVAMENTE para o SOM — o Random Forest e o pipeline congelado
permanecem absolutamente intactos. As 87 features binárias/one-hot/multi-hot
são mantidas em 0-1.

Fluxo (IMPLEMENTAR -> EXECUTAR -> GERAR ARTIFACTS -> TESTAR -> RELATAR):

  1. valida o hash do modelo Random Forest congelado (NÃO altera o modelo);
  2. carrega ``X_MODEL`` (34) + ``y``, split congelado (4000/1000) e o
     preprocessor já ajustado (extraído do pipeline congelado);
  3. transforma 34 -> 96 features (MESMA transformação do RF) e confirma que a
     probabilidade do RF reproduz o CSV congelado (NÃO retreina);
  4. normalização SOM (min-max 0-1) SOMENTE nas 9 features não-binárias, com
     parâmetros calculados SOMENTE no treino e aplicados ao holdout;
  5. treina o SOM SOMENTE nos 4000 TRAIN NORMALIZADOS (grades 5x5/7x7/10x10),
     escolhendo por erro de quantização + erro topográfico (dados de treino);
  6. roda K-means (k=2..6) sobre os protótipos e escolhe k por Silhouette
     (sem usar target/RF/IV-DSS);
  7. projeta o holdout (1000) -> BMU -> grupo SOM; junta target, RF e IV-DSS
     APENAS DEPOIS da atribuição (pós-hoc);
  8. resume por grupo (n, % holdout, P(RF) média/mediana/dispersão, IV-DSS
     média/mediana, proporção do target sintético, cobertura IV-DSS);
  9. caracteriza grupos pelas variáveis DSS (descritivo, sem causalidade);
 10. gera figuras (U-Matrix, mapa de grupos, P(RF)/IV-DSS/target por grupo e
     PCA 2D do holdout — PCA é SÓ visualização) + artefatos em ``artifacts/som/``;
 11. registra análise de sensibilidade (SEM vs COM normalização) em
     ``som_sensitivity_v1.json``;
 12. imprime o resultado principal e o veredito.

O SOM NÃO vê ``descontinuou_pre_natal``, nem P(RF), nem IV-DSS, nem ``OUT_*``.
O holdout não participa do fit (nem da normalização). Nada aqui altera o modelo
congelado, o ``/api/v1/risk-estimate``, o Flutter, a API ou o PostgreSQL.

Uso::

    python scripts/run_som_analysis.py
"""

from __future__ import annotations

import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
from sklearn.metrics import silhouette_score

try:  # garantir saída UTF-8 em terminais Windows
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:  # pragma: no cover
    pass

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

from meu_bebe_ml.preprocessing import load_x_y
from meu_bebe_ml.preprocessing.contract import resolve_spec
from meu_bebe_ml.schema import constants
from meu_bebe_ml.som import (
    SOMConfig,
    SelfOrganizingMap,
    SomMinMaxNormalizer,
    som_scale_mask,
)
from meu_bebe_ml.training.config import sha256_file
from meu_bebe_ml.training.execution import (
    load_frozen_dataset,
    load_frozen_split,
    n_features_of,
    positive_class_probability,
)

_IA_ROOT = Path(__file__).resolve().parents[1]

# ---------------------------------------------------------------------------
# Caminhos congelados (somente leitura)
# ---------------------------------------------------------------------------
_DATASET_PATH = _IA_ROOT / "data" / "processed" / "dataset_synthetic_v1.jsonl"
_SPLIT_PATH = _IA_ROOT / "data" / "processed" / "train_test_split_v1.csv"
_MODEL_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1.joblib"
_MODEL_MANIFEST_PATH = _IA_ROOT / "artifacts" / "models" / "selected_model_v1_manifest.json"
_TEST_PRED_PATH = _IA_ROOT / "data" / "processed" / "test_predictions_selected_v1.csv"
_IV_DSS_PATH = _IA_ROOT / "data" / "processed" / "iv_dss_v1.jsonl"

# ---------------------------------------------------------------------------
# Saídas (artifacts/som/)
# ---------------------------------------------------------------------------
_OUT_DIR = _IA_ROOT / "artifacts" / "som"
_FIG_DIR = _OUT_DIR / "figures"

SOM_VERSION = "2.0"  # v2 = normalização SOM (min-max 0-1 nas 9 não-binárias)
GRID_CANDIDATES: tuple[tuple[int, int], ...] = ((5, 5), (7, 7), (10, 10))
K_CANDIDATES: tuple[int, ...] = (2, 3, 4, 5, 6)
SEED = 42
ITERATIONS = 3000
LEARNING_RATE0 = 0.5

# Dimensões do IV-DSS na ordem canônica (para caracterização descritiva).
_DIM_NAMES = (
    "D_educacao",
    "D_trabalho",
    "D_saneamento",
    "D_acesso",
    "D_habitacao",
    "D_alimentacao",
)


# ---------------------------------------------------------------------------
# Carregamento / validação
# ---------------------------------------------------------------------------

def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    with open(path, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line:
                records.append(json.loads(line))
    return records


def _sigma0_for(grid: tuple[int, int]) -> float:
    """Raio inicial da vizinhança proporcional à maior dimensão da grade."""
    return max(grid) / 2.0


def _verify_frozen_model_hash() -> dict[str, Any]:
    """Confirma que o joblib congelado não foi alterado (vs manifest)."""
    manifest = json.loads(_MODEL_MANIFEST_PATH.read_text(encoding="utf-8"))
    expected = manifest["model_file_hash_sha256"]
    actual = sha256_file(_MODEL_PATH)
    if actual != expected:
        raise RuntimeError(
            f"hash do modelo divergiu: manifest={expected} arquivo={actual}. PARE."
        )
    return manifest


def _load_rf_probabilities(test_idx: np.ndarray) -> dict[int, float]:
    """Mapa row_index -> P(RF) congelada (classe positiva), do CSV congelado."""
    df = pd.read_csv(_TEST_PRED_PATH)
    probs: dict[int, float] = {}
    for row in df.itertuples(index=False):
        probs[int(row.row_index)] = float(row.y_probability)
    missing = [int(i) for i in test_idx if int(i) not in probs]
    if missing:
        raise ValueError(f"holdout sem P(RF) congelada: {len(missing)} registros")
    return probs


def _load_iv_dss() -> dict[int, dict[str, Any]]:
    """Mapa row_index -> registro IV-DSS (dimensões sempre presentes; índice pode ser null)."""
    out: dict[int, dict[str, Any]] = {}
    for rec in _read_jsonl(_IV_DSS_PATH):
        out[int(rec["row_index"])] = rec
    return out


# ---------------------------------------------------------------------------
# SOM
# ---------------------------------------------------------------------------

def _train_som(X_train: np.ndarray, grid: tuple[int, int]) -> SelfOrganizingMap:
    cfg = SOMConfig(
        grid_rows=grid[0],
        grid_cols=grid[1],
        sigma0=_sigma0_for(grid),
        learning_rate0=LEARNING_RATE0,
        iterations=ITERATIONS,
        random_state=SEED,
    )
    som = SelfOrganizingMap(cfg, input_dim=X_train.shape[1])
    som.fit(X_train)
    return som


def _choose_grid(X_train: np.ndarray) -> tuple[SelfOrganizingMap, dict[str, Any]]:
    """Treina uma grade por candidato e escolhe por (quant_err, topo_err) lexicográfico."""
    sweep: list[dict[str, Any]] = []
    best: SelfOrganizingMap | None = None
    best_key: tuple[float, float] | None = None
    best_grid: tuple[int, int] | None = None

    for grid in GRID_CANDIDATES:
        som = _train_som(X_train, grid)
        qe = som.quantization_error(X_train)
        te = som.topographic_error(X_train)
        sweep.append(
            {
                "grid": f"{grid[0]}x{grid[1]}",
                "grid_rows": grid[0],
                "grid_cols": grid[1],
                "n_neurons": grid[0] * grid[1],
                "sigma0": _sigma0_for(grid),
                "learning_rate0": LEARNING_RATE0,
                "iterations": ITERATIONS,
                "seed": SEED,
                "quantization_error": qe,
                "topographic_error": te,
            }
        )
        key = (qe, te)
        if best_key is None or key < best_key:
            best_key = key
            best = som
            best_grid = grid

    assert best is not None and best_grid is not None
    reason = (
        "grade escolhida por menor erro de quantização, desempatando por menor "
        "erro topográfico (lexicográfico sobre dados de treino)."
    )
    choice = {
        "chosen_grid": f"{best_grid[0]}x{best_grid[1]}",
        "rule": reason,
        "grid_sweep": sweep,
    }
    return best, choice


def _chosen_sweep(grid_choice: dict[str, Any]) -> dict[str, Any]:
    return next(
        s for s in grid_choice["grid_sweep"] if s["grid"] == grid_choice["chosen_grid"]
    )


# ---------------------------------------------------------------------------
# K-means sobre protótipos
# ---------------------------------------------------------------------------

def _choose_k(som: SelfOrganizingMap) -> tuple[np.ndarray, dict[str, Any]]:
    """K-means (seed fixa) sobre os protótipos; escolhe k por Silhouette."""
    prototypes = som.prototype_matrix()  # (n_neurons, dim)
    n_neurons = prototypes.shape[0]
    results: list[dict[str, Any]] = []
    best_k: int | None = None
    best_score: float = float("-inf")
    best_labels: np.ndarray | None = None

    for k in K_CANDIDATES:
        if k >= n_neurons:
            results.append({"k": k, "silhouette": None, "note": "k >= n_neurons"})
            continue
        km = KMeans(n_clusters=k, random_state=SEED, n_init=10)
        labels = km.fit_predict(prototypes)
        # Silhouette só é definida se todo cluster tem >= 2 membros.
        counts = np.bincount(labels, minlength=k)
        sil: float | None
        if int((counts >= 2).sum()) < k:
            sil = None
        else:
            sil = float(silhouette_score(prototypes, labels))
        results.append({"k": k, "silhouette": sil})
        if sil is not None and sil > best_score:
            best_score = sil
            best_k = k
            best_labels = labels

    if best_k is None or best_labels is None:
        raise RuntimeError("nenhum k com Silhouette definida. PARE.")
    choice = {
        "chosen_k": best_k,
        "rule": "maior Silhouette sobre os protótipos; empate numérico -> menor k.",
        "k_sweep": results,
        "seed": SEED,
        "kmeans_n_init": 10,
    }
    return best_labels, choice


# ---------------------------------------------------------------------------
# Holdout / resumo / convergência
# ---------------------------------------------------------------------------

def _build_holdout(
    test_idx: np.ndarray,
    test_groups: np.ndarray,
    bmu_neuron: np.ndarray,
    bmu_row: np.ndarray,
    bmu_col: np.ndarray,
    y: np.ndarray,
    rf_prob: np.ndarray,
    iv_dss: dict[int, dict[str, Any]],
) -> pd.DataFrame:
    holdout = pd.DataFrame(
        {
            "row_index": test_idx,
            "bmu_neuron": bmu_neuron,
            "som_group": test_groups,
            "y_true": y[test_idx],
            "rf_probability": rf_prob,
        }
    )
    holdout["iv_dss"] = holdout["row_index"].map(
        lambda r: iv_dss[int(r)].get("iv_dss")
    )
    holdout["iv_dss_coverage"] = holdout["row_index"].map(
        lambda r: iv_dss[int(r)].get("iv_dss_coverage")
    )
    holdout["bmu_row"] = bmu_row
    holdout["bmu_col"] = bmu_col
    return holdout


def _group_summary_rows(
    holdout: pd.DataFrame,
    k: int,
    characterization: dict[int, dict[str, Any]] | None = None,
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for g in range(1, k + 1):
        sub = holdout[holdout["som_group"] == g]
        n = int(len(sub))
        rf_vals = sub["rf_probability"].to_numpy(dtype=float)
        iv_vals = sub["iv_dss"].dropna().to_numpy(dtype=float)
        row: dict[str, Any] = {
            "grupo": g,
            "n": n,
            "pct_holdout": n / len(holdout),
            "rf_prob_mean": float(np.mean(rf_vals)),
            "rf_prob_median": float(np.median(rf_vals)),
            "rf_prob_std": float(np.std(rf_vals, ddof=1)) if n > 1 else 0.0,
            "iv_dss_mean": float(np.mean(iv_vals)) if len(iv_vals) else None,
            "iv_dss_median": float(np.median(iv_vals)) if len(iv_vals) else None,
            "iv_dss_n_calculable": int(len(iv_vals)),
            "iv_dss_n_not_calculable": int(sub["iv_dss"].isna().sum()),
            "target_positive_proportion": float(sub["y_true"].mean()),
        }
        if characterization is not None:
            row["predominant_characteristics"] = characterization[g][
                "predominant_characteristics"
            ]
        rows.append(row)
    return rows


def _convergence(rows: list[dict[str, Any]]) -> dict[str, Any]:
    def gmax(key: str) -> dict[str, Any]:
        return max(
            rows,
            key=lambda r: (r[key] if r[key] is not None else float("-inf")),
        )

    g_iv = gmax("iv_dss_mean")
    g_rf = gmax("rf_prob_mean")
    g_tg = gmax("target_positive_proportion")
    same = g_iv["grupo"] == g_rf["grupo"] == g_tg["grupo"]
    return {
        "max_iv_dss_group": int(g_iv["grupo"]),
        "max_iv_dss_mean": g_iv["iv_dss_mean"],
        "max_rf_prob_group": int(g_rf["grupo"]),
        "max_rf_prob_mean": g_rf["rf_prob_mean"],
        "max_target_group": int(g_tg["grupo"]),
        "max_target_positive_proportion": g_tg["target_positive_proportion"],
        "convergence": bool(same),
    }


def _distribution(rows: list[dict[str, Any]]) -> dict[str, int]:
    return {f"grupo_{r['grupo']}": int(r["n"]) for r in rows}


# ---------------------------------------------------------------------------
# Caracterização descritiva
# ---------------------------------------------------------------------------

def _characterize_groups(
    group_ids: np.ndarray,
    k: int,
    holdout_records: pd.DataFrame,
    iv_dss: dict[int, dict[str, Any]],
) -> dict[int, dict[str, Any]]:
    """Perfil descritivo por grupo: médias das 6 dimensões + modos/médias brutas."""
    chars: dict[int, dict[str, Any]] = {}
    numeric_cols = ["numero_pessoas", "numero_comodos", "numero_dormitorios"]

    for g in range(1, k + 1):
        rows = holdout_records[holdout_records["som_group"] == g]
        row_ids = rows["row_index"].astype(int).tolist()

        dim_means: dict[str, float] = {}
        for d in _DIM_NAMES:
            vals = [iv_dss[rid][d] for rid in row_ids if iv_dss[rid].get(d) is not None]
            dim_means[d] = float(np.mean(vals)) if vals else float("nan")

        # Predominância: 3 dimensões com maior média.
        top_dims = sorted(
            ((d, v) for d, v in dim_means.items() if not np.isnan(v)),
            key=lambda kv: kv[1],
            reverse=True,
        )[:3]

        # Perfil bruto: moda para categóricas, média para numéricas.
        raw_profile: dict[str, Any] = {}
        for col in constants.X_MODEL:
            col_vals = rows[col]
            if col in numeric_cols:
                raw_profile[col] = float(np.mean(col_vals.to_numpy(dtype=float)))
            else:
                modes = col_vals.mode(dropna=True)
                raw_profile[col] = str(modes.iloc[0]) if len(modes) else None

        chars[g] = {
            "grupo": g,
            "dimension_means": dim_means,
            "top_dims": [{"dimension": d, "mean": round(v, 4)} for d, v in top_dims],
            "predominant_characteristics": ", ".join(
                f"{d} ({v:.3f})" for d, v in top_dims
            ),
            "raw_profile": raw_profile,
        }
    return chars


# ---------------------------------------------------------------------------
# Figuras
# ---------------------------------------------------------------------------

def _save_figures(
    som: SelfOrganizingMap,
    group_map: np.ndarray,  # (rows, cols) labels 1..k
    k: int,
    group_summary: pd.DataFrame,
    holdout: pd.DataFrame,
) -> list[str]:
    """Gera as 5 figuras em alta resolução; devolve os caminhos."""
    _FIG_DIR.mkdir(parents=True, exist_ok=True)
    paths: list[str] = []

    # 1) U-Matrix
    fig, ax = plt.subplots(figsize=(7, 6))
    um = som.umatrix()
    im = ax.imshow(um, cmap="viridis", origin="upper")
    ax.set_title("SOM — U-Matrix (distâncias entre neurônios vizinhos)")
    ax.set_xlabel("neurônio (coluna)")
    ax.set_ylabel("neurônio (linha)")
    fig.colorbar(im, ax=ax, label="distância média aos vizinhos")
    p = _FIG_DIR / "umatrix_v1.png"
    fig.savefig(p, dpi=200, bbox_inches="tight")
    plt.close(fig)
    paths.append(str(p))

    # 2) Grupos sobre o SOM
    fig, ax = plt.subplots(figsize=(7, 6))
    cmap = plt.get_cmap("tab10", k)
    im = ax.imshow(group_map, cmap=cmap, vmin=1, vmax=k, origin="upper")
    ax.set_title(f"SOM — grupos (K-means, k={k}) sobre os neurônios")
    ax.set_xlabel("neurônio (coluna)")
    ax.set_ylabel("neurônio (linha)")
    cbar = fig.colorbar(im, ax=ax, ticks=range(1, k + 1))
    cbar.set_label("grupo SOM (rótulo nominal)")
    rows, cols = group_map.shape
    for r in range(rows):
        for c in range(cols):
            ax.text(c, r, f"{int(group_map[r, c])}", ha="center", va="center",
                    color="white", fontsize=8)
    p = _FIG_DIR / "groups_map_v1.png"
    fig.savefig(p, dpi=200, bbox_inches="tight")
    plt.close(fig)
    paths.append(str(p))

    # 3) P(RF) por grupo (boxplot)
    fig, ax = plt.subplots(figsize=(7, 5))
    data = [holdout.loc[holdout["som_group"] == g, "rf_probability"].to_numpy()
            for g in range(1, k + 1)]
    ax.boxplot(data, tick_labels=[f"Grupo {g}" for g in range(1, k + 1)])
    ax.set_title("P(RF) por grupo SOM (holdout)")
    ax.set_xlabel("grupo SOM")
    ax.set_ylabel("probabilidade estimada pelo Random Forest")
    p = _FIG_DIR / "rf_prob_by_group_v1.png"
    fig.savefig(p, dpi=200, bbox_inches="tight")
    plt.close(fig)
    paths.append(str(p))

    # 4) IV-DSS por grupo (boxplot) — lembrete: IV-DSS != P(RF)
    fig, ax = plt.subplots(figsize=(7, 5))
    data = [holdout.loc[holdout["som_group"] == g, "iv_dss"].dropna().to_numpy()
            for g in range(1, k + 1)]
    ax.boxplot(data, tick_labels=[f"Grupo {g}" for g in range(1, k + 1)])
    ax.set_title("IV-DSS por grupo SOM (holdout) — IV-DSS ≠ P(RF)")
    ax.set_xlabel("grupo SOM")
    ax.set_ylabel("IV-DSS (índice descritivo)")
    p = _FIG_DIR / "iv_dss_by_group_v1.png"
    fig.savefig(p, dpi=200, bbox_inches="tight")
    plt.close(fig)
    paths.append(str(p))

    # 5) Proporção do target sintético por grupo
    fig, ax = plt.subplots(figsize=(7, 5))
    props = [float(holdout.loc[holdout["som_group"] == g, "y_true"].mean())
             for g in range(1, k + 1)]
    ax.bar([f"Grupo {g}" for g in range(1, k + 1)], props, color="#4c72b0")
    ax.set_title("Proporção do target sintético por grupo SOM (pós-formação)")
    ax.set_xlabel("grupo SOM")
    ax.set_ylabel("proporção do target sintético (y=1)")
    ax.set_ylim(0.0, 1.0)
    for i, v in enumerate(props):
        ax.text(i, v + 0.01, f"{v:.3f}", ha="center", fontsize=9)
    p = _FIG_DIR / "target_proportion_by_group_v1.png"
    fig.savefig(p, dpi=200, bbox_inches="tight")
    plt.close(fig)
    paths.append(str(p))

    return paths


def _save_pca_figure(
    X_train_norm: np.ndarray,
    X_test_norm: np.ndarray,
    test_groups: np.ndarray,
    k: int,
) -> tuple[str, dict[str, Any]]:
    """PCA 2D SOMENTE para visualização. PCA NÃO define os grupos.

    PCA ajustado somente no treino (normalizado); holdout projetado e colorido
    pelo ``som_group`` (que vem de SOM + K-means, não do PCA).
    """
    pca = PCA(n_components=2, random_state=SEED)
    pca.fit(X_train_norm)
    proj = pca.transform(X_test_norm)

    fig, ax = plt.subplots(figsize=(8, 6))
    cmap = plt.get_cmap("tab10", k)
    scatter = ax.scatter(
        proj[:, 0], proj[:, 1], c=test_groups, cmap=cmap, vmin=1, vmax=k,
        s=18, alpha=0.75, edgecolors="none",
    )
    ax.set_title(
        "Projeção bidimensional dos registros do holdout segundo os "
        "agrupamentos identificados pelo SOM"
    )
    ax.set_xlabel("Componente principal 1")
    ax.set_ylabel("Componente principal 2")
    cbar = fig.colorbar(scatter, ax=ax, ticks=range(1, k + 1))
    cbar.set_label("grupo SOM (rótulo nominal)")
    p = _FIG_DIR / "som_holdout_pca_groups_v1.png"
    fig.savefig(p, dpi=200, bbox_inches="tight")
    plt.close(fig)

    meta = {
        "role": "visualização apenas; SOM + K-means definem os grupos",
        "n_components": 2,
        "fit_scope": "PCA ajustado SOMENTE no treino (4000); holdout projetado",
        "explained_variance_ratio": [float(x) for x in pca.explained_variance_ratio_],
    }
    return str(p), meta


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    t_start = time.perf_counter()
    _OUT_DIR.mkdir(parents=True, exist_ok=True)
    _FIG_DIR.mkdir(parents=True, exist_ok=True)

    # 1) Hash do modelo congelado (NÃO altera).
    model_manifest = _verify_frozen_model_hash()

    # 2) Dados congelados.
    X_raw, y = load_frozen_dataset(dataset_path=_DATASET_PATH)
    train_idx, test_idx = load_frozen_split(_SPLIT_PATH)
    pipeline = joblib.load(_MODEL_PATH)
    preprocessor = pipeline.named_steps["preprocessor"]

    # 3) 34 -> 96 features (mesma transformação do RF).
    X96 = preprocessor.transform(X_raw)
    n_feat = n_features_of(pipeline)
    assert X96.shape == (5000, n_feat) and n_feat == 96, (
        f"esperado (5000, 96); recebido {X96.shape}"
    )
    X_train = X96[train_idx]
    X_test = X96[test_idx]
    feature_names = list(preprocessor.get_feature_names_out())
    assert len(feature_names) == 96

    # 3b) P(RF) do modelo congelado reproduz o CSV congelado (não retreina).
    rf_proba_recomputed = positive_class_probability(
        pipeline.named_steps["model"], pipeline.predict_proba(X_raw.iloc[test_idx])
    )
    frozen_probs = _load_rf_probabilities(test_idx)
    for i, row_id in enumerate(test_idx):
        expected = frozen_probs[int(row_id)]
        if abs(rf_proba_recomputed[i] - expected) > 1e-9:
            raise RuntimeError(
                f"P(RF) recomputada divergiu do CSV congelado na row {row_id}. PARE."
            )
    # Usamos a probabilidade congelada do CSV como fonte de verdade pós-hoc.
    rf_prob = np.array([frozen_probs[int(i)] for i in test_idx], dtype=float)
    iv_dss = _load_iv_dss()

    # 4) Normalização SOM (min-max 0-1) EXCLUSIVA das 9 não-binárias; fit no treino.
    spec = resolve_spec()
    scale_mask = som_scale_mask(
        feature_names, spec.source_map, spec.numeric, tuple(spec.ordinal_order)
    )
    assert int(scale_mask.sum()) == 9, "esperado 9 features normalizadas (3 + 6)"
    scaled_fields = [
        str(name) for name, m in zip(feature_names, scale_mask) if bool(m)
    ]
    normalizer = SomMinMaxNormalizer(scale_mask).fit(X_train)
    X_train_norm = normalizer.transform(X_train)
    X_test_norm = normalizer.transform(X_test)

    # 5) Sensibilidade: versão SEM normalização (grade oficial reproduzida).
    som_raw, grid_raw = _choose_grid(X_train)
    proto_raw, k_raw = _choose_k(som_raw)
    k_raw_val = int(k_raw["chosen_k"])
    bmu_raw = som_raw.bmu_indices(X_test)
    groups_raw = proto_raw[bmu_raw] + 1
    r_raw, c_raw = som_raw.bmu_coords(X_test)
    holdout_raw = _build_holdout(
        test_idx, groups_raw, bmu_raw, r_raw, c_raw, y, rf_prob, iv_dss
    )
    rows_raw = _group_summary_rows(holdout_raw, k_raw_val)
    conv_raw = _convergence(rows_raw)
    sweep_raw = _chosen_sweep(grid_raw)

    # 6) Treino do SOM (somente TRAIN NORMALIZADO) + escolha da grade.
    som, grid_choice = _choose_grid(X_train_norm)

    # 7) K-means sobre protótipos + escolha de k.
    proto_labels, k_choice = _choose_k(som)
    k = int(k_choice["chosen_k"])

    # 8) Projeção do holdout -> BMU -> grupo (pós-hoc junta target/RF/IV-DSS).
    test_bmu = som.bmu_indices(X_test_norm)
    test_groups = proto_labels[test_bmu] + 1  # 1..k (nominal)
    bmu_r, bmu_c = som.bmu_coords(X_test_norm)
    holdout = _build_holdout(
        test_idx, test_groups, test_bmu, bmu_r, bmu_c, y, rf_prob, iv_dss
    )

    # 9) Caracterização descritiva (variáveis DSS brutas dos registros do holdout).
    raw_test = X_raw.iloc[test_idx].reset_index(drop=True)
    raw_test["row_index"] = test_idx
    holdout_full = holdout.merge(raw_test, on="row_index", how="left")
    characterization = _characterize_groups(test_groups, k, holdout_full, iv_dss)

    # 10) Resumo por grupo (com características predominantes).
    summary_rows = _group_summary_rows(holdout, k, characterization)
    group_summary = pd.DataFrame(summary_rows)
    assert int(group_summary["n"].sum()) == 1000, "group_summary deve somar 1000"
    conv_norm = _convergence(summary_rows)

    # 11) Figuras (5 clássicas + PCA de visualização).
    group_map = proto_labels.reshape(som.config.grid_rows, som.config.grid_cols) + 1
    figure_paths = _save_figures(som, group_map, k, group_summary, holdout)
    pca_path, pca_meta = _save_pca_figure(X_train_norm, X_test_norm, test_groups, k)
    figure_paths.append(pca_path)

    # 12) Artefatos.
    normalization = {
        "method": "min-max 0-1",
        "applied_to": "9 features não-binárias (3 numéricas + 6 ordinais)",
        "scaled_fields": scaled_fields,
        "n_scaled": int(scale_mask.sum()),
        "n_passthrough": int((~scale_mask).sum()),
        "binary_passthrough": (
            "87 features binárias/one-hot/multi-hot mantidas em 0-1 (sem alteração)"
        ),
        "fit_scope": "SOMENTE TREINO (4000); holdout usa os mesmos min/range",
        "constant_handling": "coluna com range 0 no treino -> 0.0",
    }
    final_config = {
        "som_version": SOM_VERSION,
        "schema_version": constants.SCHEMA_VERSION,
        "grid": grid_choice["chosen_grid"],
        "grid_rows": som.config.grid_rows,
        "grid_cols": som.config.grid_cols,
        "sigma0": som.config.sigma0,
        "learning_rate0": som.config.learning_rate0,
        "iterations": som.config.iterations,
        "seed": som.config.random_state,
        "input": (
            "96 features numéricas derivadas de X_MODEL (34), mesma transformação "
            "do RF; SOM usa entrada normalizada (min-max 0-1 nas 9 não-binárias)"
        ),
        "normalization": normalization,
        "fit_scope": "SOMENTE TREINO (4000); holdout (1000) apenas projetado",
        "excluded_from_input": [
            "descontinuou_pre_natal",
            "P(Random Forest)",
            "IV-DSS (e dimensões D_*)",
            "OUT_LEAKAGE",
            "OUT_TEMPORAL",
            "DESCRIPTIVE",
            "SENSITIVITY",
        ],
        "k": k,
        "kmeans_seed": SEED,
    }
    chosen_sweep = _chosen_sweep(grid_choice)
    metrics = {
        "chosen_grid": chosen_sweep["grid"],
        "quantization_error": chosen_sweep["quantization_error"],
        "topographic_error": chosen_sweep["topographic_error"],
        "config": {
            "grid": chosen_sweep["grid"],
            "sigma0": chosen_sweep["sigma0"],
            "learning_rate0": chosen_sweep["learning_rate0"],
            "iterations": chosen_sweep["iterations"],
            "seed": chosen_sweep["seed"],
        },
        "normalization": normalization,
        "grid_sweep": grid_choice["grid_sweep"],
        "note": "Métricas do SOM não são comparáveis a ROC-AUC/PR-AUC do RF.",
    }

    # Escrever CSVs/JSONs.
    holdout.to_csv(_OUT_DIR / "som_holdout_assignments_v1.csv", index=False)
    group_summary.to_csv(_OUT_DIR / "som_group_summary_v1.csv", index=False)

    def _dump_json(name: str, obj: Any) -> None:
        (_OUT_DIR / name).write_text(
            json.dumps(obj, ensure_ascii=False, indent=2), encoding="utf-8"
        )

    _dump_json("som_config_v1.json", final_config)
    _dump_json("som_metrics_v1.json", metrics)
    _dump_json("som_k_choice_v1.json", k_choice)
    _dump_json(
        "som_group_summary_v1.json",
        {
            "k": k,
            "n_holdout_total": 1000,
            "groups": summary_rows,
            "characterization": {
                str(g): characterization[g] for g in range(1, k + 1)
            },
            "note": "Grupo SOM é rótulo nominal. IV-DSS é descritivo; P(RF) é "
            "probabilidade estimada pelo modelo congelado; target é a variável "
            "sintética observada pós-formação.",
        },
    )

    # Análise de sensibilidade (SEM vs COM normalização).
    sensitivity = {
        "som_version": SOM_VERSION,
        "purpose": (
            "Sensibilidade metodológica: entrada SEM normalização vs COM "
            "normalização (min-max 0-1 nas 9 features não-binárias)."
        ),
        "without_normalization": {
            "chosen_grid": sweep_raw["grid"],
            "quantization_error": sweep_raw["quantization_error"],
            "topographic_error": sweep_raw["topographic_error"],
            "chosen_k": k_raw_val,
            "silhouette_k_sweep": k_raw["k_sweep"],
            "distribution": _distribution(rows_raw),
            "convergence": conv_raw,
        },
        "with_normalization": {
            "chosen_grid": chosen_sweep["grid"],
            "quantization_error": chosen_sweep["quantization_error"],
            "topographic_error": chosen_sweep["topographic_error"],
            "chosen_k": k,
            "silhouette_k_sweep": k_choice["k_sweep"],
            "distribution": _distribution(summary_rows),
            "convergence": conv_norm,
        },
        "comparison": {
            "same_grid": bool(sweep_raw["grid"] == chosen_sweep["grid"]),
            "same_k": bool(k_raw_val == k),
            "convergence_preserved": bool(
                conv_raw["convergence"] and conv_norm["convergence"]
            ),
            "note": (
                "O SOM com normalização é o resultado OFICIAL. A versão sem "
                "normalização é reproduzida aqui apenas para sensibilidade."
            ),
        },
    }
    _dump_json("som_sensitivity_v1.json", sensitivity)

    manifest = {
        "som_version": SOM_VERSION,
        "schema_version": constants.SCHEMA_VERSION,
        "random_forest_model_file_hash_sha256": model_manifest["model_file_hash_sha256"],
        "random_forest_model_unchanged": True,
        "n_train": int(len(train_idx)),
        "n_holdout": int(len(test_idx)),
        "n_features": int(n_feat),
        "input_normalization": (
            "min-max 0-1 SOMENTE nas 9 features não-binárias (3 numéricas + 6 "
            "ordinais), fit no treino; 87 binárias/one-hot/multi-hot mantidas em 0-1"
        ),
        "chosen_grid": grid_choice["chosen_grid"],
        "chosen_k": k,
        "quantization_error": metrics["quantization_error"],
        "topographic_error": metrics["topographic_error"],
        "pca": pca_meta,
        "figures": {Path(p).name: p for p in figure_paths},
        "artifact_files": sorted(p.name for p in _OUT_DIR.iterdir() if p.is_file()),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "note": "Análise exploratória sobre dataset sintético; sem validade "
        "populacional nem clínica; o SOM NÃO substitui o Random Forest.",
    }
    _dump_json("som_manifest_v1.json", manifest)

    elapsed = time.perf_counter() - t_start

    # 13) Resultado principal (resumo impresso).
    print("=" * 78)
    print("FASE IA-SOM-FIX — RESULTADO (entrada normalizada para o SOM)")
    print("=" * 78)
    print(f"tempo_total_segundos      : {elapsed:.2f}")
    print(f"normalizacao              : min-max 0-1 nas {int(scale_mask.sum())} "
          f"não-binárias; {int((~scale_mask).sum())} binárias mantidas")
    print(f"grade_escolhida           : {grid_choice['chosen_grid']}")
    print(f"k_escolhido               : {k}")
    print(f"erro_quantizacao          : {metrics['quantization_error']:.6f}")
    print(f"erro_topografico          : {metrics['topographic_error']:.6f}")
    print(f"n_grupos                  : {k}")
    print(f"holdout_total             : 1000")
    print("--- resumo por grupo ---")
    print(group_summary.to_string(index=False))
    print("--- silhueta (k=2..6) ---")
    for row in k_choice["k_sweep"]:
        sil = row["silhouette"]
        sil_s = f"{sil:.6f}" if sil is not None else "indefinida"
        print(f"  k={row['k']}: silhouette={sil_s}")
    print("--- sensibilidade (SEM vs COM normalização) ---")
    print(f"  sem normalizacao: grade={sweep_raw['grid']} k={k_raw_val} "
          f"dist={_distribution(rows_raw)} conv={conv_raw['convergence']}")
    print(f"  com normalizacao: grade={chosen_sweep['grid']} k={k} "
          f"dist={_distribution(summary_rows)} conv={conv_norm['convergence']}")
    print("--- veredito ---")
    print("APROVAR PARA COMMIT" if _self_check(k, group_summary) else "CORRIGIR IMPLEMENTAÇÃO")
    print("=" * 78)


def _self_check(k: int, group_summary: pd.DataFrame) -> bool:
    """Checagem mínima de sanidade antes do veredito."""
    if int(group_summary["n"].sum()) != 1000:
        return False
    if set(group_summary["grupo"].astype(int)) != set(range(1, k + 1)):
        return False
    return True


if __name__ == "__main__":
    main()
