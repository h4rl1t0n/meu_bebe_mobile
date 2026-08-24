"""Testes unitários de ``ml/artifact.py`` (paths, manifest, SHA, compat)."""

from __future__ import annotations

import json

import pytest

from meu_bebe_api.ml import artifact
from meu_bebe_api.ml.artifact import (
    ModelManifest,
    check_compatibility,
    load_manifest,
    resolve_artifact_path,
    sha256_file,
    verify_integrity,
)
from meu_bebe_api.ml.errors import (
    ModelCompatibilityError,
    ModelIntegrityError,
    ModelManifestError,
)


def _make_manifest(**library_overrides) -> ModelManifest:
    libraries = {
        "python": "3.14.5",
        "scikit_learn": "1.9.0",
        "joblib": "1.5.3",
        "numpy": "2.5.2",
        "pandas": "3.0.5",
        "scipy": "1.18.1",
    }
    libraries.update(library_overrides)
    return ModelManifest(
        model_name="random_forest",
        model_class="RandomForestClassifier",
        schema_version="1.13",
        n_features=96,
        threshold=0.5,
        model_file_hash_sha256="a" * 64,
        library_versions=libraries,
        raw={},
    )


def _matching_runtime() -> dict[str, str]:
    return {
        "python": "3.14.5",
        "scikit_learn": "1.9.0",
        "joblib": "1.5.3",
        "numpy": "2.5.2",
        "pandas": "3.0.5",
        "scipy": "1.18.1",
    }


# ---------------------------------------------------------------------------
# sha256_file
# ---------------------------------------------------------------------------


def test_sha256_file_known_content(tmp_path):
    f = tmp_path / "a.txt"
    f.write_bytes(b"hello")
    assert sha256_file(f) == (
        "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
    )


# ---------------------------------------------------------------------------
# resolve_artifact_path
# ---------------------------------------------------------------------------


def test_resolve_artifact_path_absolute_and_cwd_independent(tmp_path, monkeypatch):
    rel = "../ia/artifacts/models/selected_model_v1.joblib"
    p1 = resolve_artifact_path(rel)
    assert p1.is_absolute()
    assert p1.name == "selected_model_v1.joblib"

    monkeypatch.chdir(tmp_path)
    p2 = resolve_artifact_path(rel)
    assert p1 == p2


def test_resolve_artifact_path_keeps_absolute_paths(tmp_path):
    abs_path = tmp_path / "x.joblib"  # tmp_path já é um caminho absoluto real
    assert resolve_artifact_path(abs_path) == abs_path


# ---------------------------------------------------------------------------
# load_manifest
# ---------------------------------------------------------------------------


def test_load_manifest_requires_essential_fields(tmp_path):
    raw = {
        "model_name": "random_forest",
        "model_class": "RandomForestClassifier",
        "schema_version": "1.13",
        "n_features": 96,
        # "model_file_hash_sha256" AUSENTE de propósito
        "library_versions": {},
    }
    f = tmp_path / "manifest.json"
    f.write_text(json.dumps(raw), encoding="utf-8")

    with pytest.raises(ModelManifestError):
        load_manifest(f)


def test_load_manifest_missing_file(tmp_path):
    with pytest.raises(ModelManifestError):
        load_manifest(tmp_path / "nao_existe.json")


def test_load_manifest_ok(tmp_path):
    raw = {
        "model_name": "random_forest",
        "model_class": "RandomForestClassifier",
        "schema_version": "1.13",
        "n_features": 96,
        "threshold": 0.5,
        "model_file_hash_sha256": "b" * 64,
        "library_versions": {"scikit_learn": "1.9.0"},
    }
    f = tmp_path / "manifest.json"
    f.write_text(json.dumps(raw), encoding="utf-8")

    m = load_manifest(f)
    assert m.model_name == "random_forest"
    assert m.n_features == 96
    assert m.threshold == 0.5
    assert m.model_file_hash_sha256 == "b" * 64


# ---------------------------------------------------------------------------
# verify_integrity
# ---------------------------------------------------------------------------


def test_verify_integrity_mismatch_raises(tmp_path):
    f = tmp_path / "m.joblib"
    f.write_bytes(b"dados")
    with pytest.raises(ModelIntegrityError):
        verify_integrity(f, "0" * 64)


def test_verify_integrity_match_returns_hash(tmp_path):
    f = tmp_path / "m.joblib"
    f.write_bytes(b"dados")
    expected = sha256_file(f)
    assert verify_integrity(f, expected) == expected


# ---------------------------------------------------------------------------
# check_compatibility (igualdade exata, FAIL-CLOSED)
# ---------------------------------------------------------------------------


def test_check_compatibility_ok(monkeypatch):
    monkeypatch.setattr(artifact, "runtime_library_versions", _matching_runtime)
    check_compatibility(_make_manifest())  # não levanta


def test_check_compatibility_fail_closed_on_sklearn_mismatch(monkeypatch):
    wrong = _matching_runtime()
    wrong["scikit_learn"] = "9.9.9"
    monkeypatch.setattr(artifact, "runtime_library_versions", lambda: wrong)

    with pytest.raises(ModelCompatibilityError):
        check_compatibility(_make_manifest())


def test_check_compatibility_fail_closed_on_missing_manifest_version(monkeypatch):
    monkeypatch.setattr(artifact, "runtime_library_versions", _matching_runtime)
    manifest = _make_manifest()
    del manifest.library_versions["joblib"]  # type: ignore[attr-defined]

    with pytest.raises(ModelCompatibilityError):
        check_compatibility(manifest)
