"""Figuras diagnósticas do modelo selecionado (FASE 3F-B).

Gera os 4 PNGs exigidos pelas seções 17–20 do protocolo:

  * curva ROC (threshold-independente);
  * curva Precision-Recall (threshold-independente);
  * matriz de confusão no threshold 0.50;
  * curva de calibração (10 bins, quantile).

Estas figuras são DIAGNÓSTICOS do modelo já selecionado avaliado no TEST. Nada
aqui altera o modelo, o threshold nem qualquer decisão congelada.
"""

from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
from sklearn.metrics import (  # noqa: E402
    confusion_matrix,
    precision_recall_curve,
    roc_auc_score,
    roc_curve,
)


def save_roc_curve(
    y_true: np.ndarray,
    y_probability: np.ndarray,
    path: Path,
    title: str = "Curva ROC — modelo selecionado (TEST)",
) -> None:
    fpr, tpr, _ = roc_curve(y_true, y_probability)
    auc = roc_auc_score(y_true, y_probability)

    fig, ax = plt.subplots(figsize=(6, 6))
    ax.plot(fpr, tpr, color="tab:blue", lw=2, label=f"ROC (AUC = {auc:.4f})")
    ax.plot([0, 1], [0, 1], color="gray", lw=1, linestyle="--", label="aleatório")
    ax.set_xlabel("False Positive Rate")
    ax.set_ylabel("True Positive Rate")
    ax.set_title(title)
    ax.legend(loc="lower right")
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def save_pr_curve(
    y_true: np.ndarray,
    y_probability: np.ndarray,
    path: Path,
    title: str = "Curva Precision-Recall — modelo selecionado (TEST)",
) -> None:
    precision, recall, _ = precision_recall_curve(y_true, y_probability)
    # PR-AUC canônica = auc(recall, precision) (mesma definição congelada).
    from ..evaluation import pr_auc

    area = pr_auc(y_true, y_probability)

    fig, ax = plt.subplots(figsize=(6, 6))
    ax.plot(recall, precision, color="tab:green", lw=2, label=f"PR (AUC = {area:.4f})")
    ax.set_xlabel("Recall")
    ax.set_ylabel("Precision")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.set_title(title)
    ax.legend(loc="upper right")
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def save_confusion_matrix(
    y_true: np.ndarray,
    y_pred: np.ndarray,
    path: Path,
    threshold: float = 0.50,
    title: str = "Matriz de confusão — modelo selecionado (TEST)",
) -> None:
    cm = confusion_matrix(y_true, y_pred, labels=[0, 1])  # [[TN, FP], [FN, TP]]

    fig, ax = plt.subplots(figsize=(5, 5))
    im = ax.imshow(cm, interpolation="nearest", cmap="Blues")
    ax.set_xticks([0, 1])
    ax.set_yticks([0, 1])
    ax.set_xticklabels(["Predito 0", "Predito 1"])
    ax.set_yticklabels(["Real 0", "Real 1"])
    for i in range(2):
        for j in range(2):
            ax.text(j, i, str(cm[i, j]), ha="center", va="center", fontsize=20)
    ax.set_xlabel("Predição")
    ax.set_ylabel("Real")
    ax.set_title(f"{title}\n(threshold = {threshold:.2f})")
    fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    fig.tight_layout()
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def save_calibration_curve(
    prob_true: np.ndarray,
    prob_pred: np.ndarray,
    path: Path,
    title: str = "Curva de calibração — modelo selecionado (TEST)",
) -> None:
    fig, ax = plt.subplots(figsize=(6, 6))
    ax.plot(prob_pred, prob_true, "s-", color="tab:orange", lw=2, label="modelo")
    ax.plot([0, 1], [0, 1], color="gray", lw=1, linestyle="--", label="perfeitamente calibrado")
    ax.set_xlabel("Probabilidade média prevista")
    ax.set_ylabel("Fração de positivos")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.set_title(title)
    ax.legend(loc="upper left")
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)
