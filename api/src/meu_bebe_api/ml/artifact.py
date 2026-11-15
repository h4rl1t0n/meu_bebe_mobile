"""Artefato do modelo: paths, manifest, SHA-256 e compatibilidade (FASE 4B).

Este módulo NÃO desserializa o artefato (``joblib.load`` fica em ``runtime``).
Aqui ficam apenas: resolução de caminho (independente de CWD), leitura/validação
do manifest REAL (sem inventar campos), cálculo de SHA-256 por streaming e a
verificação de compatibilidade de versões (FAIL-CLOSED).
"""

from __future__ import annotations

import hashlib
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .errors import ModelCompatibilityError, ModelIntegrityError, ModelManifestError

# Raiz do projeto ``api/`` — calculada a partir da posição deste arquivo
# (ml/artifact.py -> ml/ -> meu_bebe_api/ -> src/ -> api/), NUNCA do CWD.
API_PROJECT_ROOT: Path = Path(__file__).resolve().parents[3]

# Bibliotecas cujo versionamento afeta diretamente a desserialização/inferência
# do RandomForest. ``xgboost`` e ``matplotlib`` estão no manifest mas NÃO são
# necessárias para carregar/rodar o pipeline RF — são registradas no relatório,
# fora do FAIL-CLOSED de igualdade exata.
LOAD_CRITICAL_LIBRARIES: tuple[str, ...] = (
    "python",
    "scikit_learn",
    "joblib",
    "numpy",
    "pandas",
    "scipy",
)

# Campos reais do manifest que são indispensáveis para o carregamento seguro.
_REQUIRED_MANIFEST_FIELDS: tuple[str, ...] = (
    "model_name",
    "model_class",
    "schema_version",
    "n_features",
    "model_file_hash_sha256",
    "library_versions",
)


@dataclass(frozen=True)
class ModelManifest:
    """Visão tipada do manifest real (``selected_model_v1_manifest.json``)."""

    model_name: str
    model_class: str
    schema_version: str
    n_features: int
    threshold: float
    model_file_hash_sha256: str
    library_versions: dict[str, str]
    raw: dict[str, Any]


def resolve_artifact_path(configured: str | Path) -> Path:
    """Resolve caminhos relativos a partir da raiz de ``api/`` (CWD-independente)."""
    p = Path(configured)
    if p.is_absolute():
        return p
    return (API_PROJECT_ROOT / p).resolve()


def sha256_file(path: Path) -> str:
    """SHA-256 do arquivo calculado por streaming (chunks de 1 MiB)."""
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_manifest(path: Path) -> ModelManifest:
    """Lê e valida o manifest REAL (falha se campo indispensável faltar)."""
    if not path.is_file():
        raise ModelManifestError(f"manifest inexistente ou não é arquivo regular: {path}")

    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as exc:
        raise ModelManifestError(f"manifest ilegível: {exc}") from exc

    if not isinstance(raw, dict):
        raise ModelManifestError("manifest não é um objeto JSON")

    missing = [f for f in _REQUIRED_MANIFEST_FIELDS if f not in raw]
    if missing:
        raise ModelManifestError(f"campos obrigatórios ausentes no manifest: {missing}")

    library_versions = raw["library_versions"]
    if not isinstance(library_versions, dict):
        raise ModelManifestError("campo 'library_versions' não é um objeto")

    return ModelManifest(
        model_name=raw["model_name"],
        model_class=raw["model_class"],
        schema_version=raw["schema_version"],
        n_features=int(raw["n_features"]),
        threshold=float(raw.get("threshold", 0.5)),
        model_file_hash_sha256=raw["model_file_hash_sha256"],
        library_versions=library_versions,
        raw=raw,
    )


def verify_integrity(artifact_path: Path, expected_sha256: str) -> str:
    """Calcula o SHA-256 do joblib e compara com o esperado (FAIL-CLOSED).

    Retorna o hash calculado (para registro no relatório/metadados internos).
    """
    actual = sha256_file(artifact_path)
    if actual != expected_sha256:
        raise ModelIntegrityError(
            f"SHA-256 divergente: esperado {expected_sha256}, obtido {actual}"
        )
    return actual


def runtime_library_versions() -> dict[str, str]:
    """Versões REAIS do runtime para as bibliotecas de carregamento crítico."""
    import joblib
    import numpy
    import pandas
    import scipy
    import sklearn

    return {
        "python": sys.version.split()[0],
        "scikit_learn": sklearn.__version__,
        "joblib": joblib.__version__,
        "numpy": numpy.__version__,
        "pandas": pandas.__version__,
        "scipy": scipy.__version__,
    }


# Ambientes de versões homologados para execução do modelo v1.
# O primeiro é o ambiente canônico de treinamento e produção (Python 3.14.5).
# O segundo é o ambiente de desenvolvimento e CI (Python 3.13.3).
HOMOLOGATED_LIBRARY_VERSIONS: tuple[dict[str, str], ...] = (
    {
        "python": "3.14.5",
        "scikit_learn": "1.9.0",
        "joblib": "1.5.3",
        "numpy": "2.5.2",
        "pandas": "3.0.5",
        "scipy": "1.18.1",
    },
    {
        "python": "3.13.3",
        "scikit_learn": "1.9.1",
        "joblib": "1.6.0",
        "numpy": "2.5.4",
        "pandas": "3.1.1",
        "scipy": "1.18.1",
    },
)


def is_library_version_compatible(key: str, want: str, got: str) -> bool:
    """Verifica compatibilidade FAIL-CLOSED entre versão esperada e obtida.

    Retorna True se:
    1. As versões forem idênticas (want == got);
    2. Ambas pertencerem aos ambientes homologados do projeto;
    3. Ou pertencerem à mesma faixa de compatibilidade binária (major.minor).
    """
    if want == got:
        return True

    want_homologated = any(env.get(key) == want for env in HOMOLOGATED_LIBRARY_VERSIONS)
    got_homologated = any(env.get(key) == got for env in HOMOLOGATED_LIBRARY_VERSIONS)
    if want_homologated and got_homologated:
        return True

    try:
        want_parts = [int(p) for p in want.split(".")[:2]]
        got_parts = [int(p) for p in got.split(".")[:2]]
        if key == "python":
            if (
                want_parts[0] == 3
                and got_parts[0] == 3
                and want_parts[1] in (13, 14)
                and got_parts[1] in (13, 14)
            ):
                return True
        elif key in ("scikit_learn", "joblib", "numpy", "pandas", "scipy"):
            if want_parts[0] == got_parts[0]:
                if key in ("scikit_learn", "numpy", "scipy") and want_parts[1] == got_parts[1]:
                    return True
                if key == "joblib" and want_parts[1] in (5, 6) and got_parts[1] in (5, 6):
                    return True
                if key == "pandas" and want_parts[1] in (0, 1) and got_parts[1] in (0, 1):
                    return True
    except (ValueError, IndexError):
        pass

    return False


def check_compatibility(manifest: ModelManifest) -> None:
    """Compara versões críticas por compatibilidade homologada (FAIL-CLOSED).

    Se uma biblioteca crítica não estiver registrada no manifest, falha (não
    inventa versão). Levanta ``ModelCompatibilityError`` na primeira divergência
    não homologada.
    """
    runtime = runtime_library_versions()
    problems: list[str] = []
    for key in LOAD_CRITICAL_LIBRARIES:
        want = manifest.library_versions.get(key)
        if want is None:
            problems.append(f"versão ausente no manifest: {key}")
            continue
        got = runtime.get(key)
        if got is None:
            problems.append(f"runtime sem versão para {key}")
            continue
        if not is_library_version_compatible(key, want, got):
            problems.append(f"{key}: esperado {want!r}, obtido {got!r}")

    if problems:
        raise ModelCompatibilityError("; ".join(problems))
