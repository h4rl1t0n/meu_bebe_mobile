"""Testes unitários para o módulo de explicabilidade local (XAI) do RandomForest."""

from __future__ import annotations

from pathlib import Path
import joblib
import pandas as pd
import pytest

from meu_bebe_ml.explainability.local_xai import (
    FEATURE_LABELS_PT_BR,
    LocalFactorContribution,
    explain_prediction_rf,
    map_transformed_to_raw,
)
from meu_bebe_ml.schema.constants import X_MODEL

_MODEL_PATH = (
    Path(__file__).resolve().parents[1] / "artifacts" / "models" / "selected_model_v1.joblib"
)


@pytest.fixture(scope="module")
def loaded_pipeline():
    assert _MODEL_PATH.is_file(), f"Artefato do modelo não encontrado: {_MODEL_PATH}"
    return joblib.load(_MODEL_PATH)


def test_feature_labels_cover_all_x_model():
    """Garante que todas as 34 variáveis de X_MODEL possuem rótulo em português definido."""
    for feat in X_MODEL:
        assert feat in FEATURE_LABELS_PT_BR, f"Faltando rótulo PT-BR para a variável {feat}"
        assert len(FEATURE_LABELS_PT_BR[feat]) > 0


def test_map_transformed_to_raw(loaded_pipeline):
    """Garante que todas as features transformadas mapeiam para uma variável válida de X_MODEL."""
    pre = loaded_pipeline.named_steps["preprocessor"]
    transformed_names = list(pre.get_feature_names_out())
    assert len(transformed_names) == 96

    raw_mapping = map_transformed_to_raw(transformed_names)
    assert len(raw_mapping) == 96

    raw_set = set(X_MODEL)
    for raw_name in raw_mapping:
        assert raw_name in raw_set, f"Mapeamento inválido para {raw_name}"


def test_explain_prediction_rf_matches_predict_proba(loaded_pipeline):
    """Testa decomposição matemática de caminhos de árvore e integridade com predict_proba."""
    from conftest import make_valid_record

    pre = loaded_pipeline.named_steps["preprocessor"]
    rf = loaded_pipeline.named_steps["model"]

    rec = make_valid_record()
    x_raw = pd.DataFrame([{k: rec[k] for k in X_MODEL}])

    prob_direct = rf.predict_proba(pre.transform(x_raw))[0, 1]
    prob_explained, bias, factors = explain_prediction_rf(
        preprocessor=pre,
        rf_model=rf,
        x_raw=x_raw,
        top_k=6,
    )

    # Probabilidade deve bater exatamente
    assert abs(prob_direct - prob_explained) < 1e-4
    assert 0.0 <= prob_explained <= 1.0
    assert 0.0 <= bias <= 1.0

    # Fatores retornados
    assert len(factors) > 0
    assert len(factors) <= 6

    for factor in factors:
        assert isinstance(factor, LocalFactorContribution)
        assert factor.feature in X_MODEL
        assert factor.label == FEATURE_LABELS_PT_BR[factor.feature]
        assert factor.direction in ("increases_risk", "decreases_risk")
        if factor.contribution > 0:
            assert factor.direction == "increases_risk"
        else:
            assert factor.direction == "decreases_risk"

        d = factor.to_dict()
        assert "feature" in d
        assert "label" in d
        assert "contribution" in d
        assert "direction" in d
        assert "description" in d


def test_explain_prediction_serialization(loaded_pipeline):
    """Testa serialização JSON-compatible dos fatores locais."""
    from conftest import make_valid_record

    pre = loaded_pipeline.named_steps["preprocessor"]
    rf = loaded_pipeline.named_steps["model"]

    rec = make_valid_record()
    x_raw = pd.DataFrame([{k: rec[k] for k in X_MODEL}])

    _, _, factors = explain_prediction_rf(pre, rf, x_raw, top_k=5)
    dicts = [f.to_dict() for f in factors]

    assert isinstance(dicts, list)
    for item in dicts:
        assert isinstance(item["contribution"], float)
        assert isinstance(item["label"], str)
