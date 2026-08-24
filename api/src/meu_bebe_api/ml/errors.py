"""Exceções próprias do runtime de ML (FASE 4B).

Cada exceção carrega um ``code`` estável que é usado SOMENTE internamente (log
e estado ``last_error_code``). Nenhum ``code``/``message`` destes vaza para o
HTTP: ``/ready`` responde apenas ``MODEL_NOT_READY`` (sem detalhes).
"""

from __future__ import annotations


class ModelError(Exception):
    """Base de todas as falhas do runtime de ML."""

    code: str = "MODEL_ERROR"


class ModelArtifactNotFoundError(ModelError):
    """Artefato (joblib) inexistente ou não é um arquivo regular."""

    code = "MODEL_ARTIFACT_NOT_FOUND"


class ModelManifestError(ModelError):
    """Manifest ausente, ilegível ou com campos obrigatórios faltando."""

    code = "MODEL_MANIFEST_ERROR"


class ModelIntegrityError(ModelError):
    """SHA-256 do joblib diverge do registrado no manifest."""

    code = "MODEL_INTEGRITY_ERROR"


class ModelCompatibilityError(ModelError):
    """Versão de biblioteca ou schema incompatível (FAIL-CLOSED)."""

    code = "MODEL_COMPATIBILITY_ERROR"


class ModelStructureError(ModelError):
    """Objeto desserializado com estrutura inesperada."""

    code = "MODEL_STRUCTURE_ERROR"


class ModelNotReadyError(ModelError):
    """Tentativa de predição com o runtime fora do estado READY."""

    code = "MODEL_NOT_READY"
