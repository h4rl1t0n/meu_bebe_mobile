"""``ModelRuntime`` — estado, carregamento idempotente e inferência interna.

Ordem obrigatória do carregamento (FASE 4B):

(1) resolver path -> (2) confirmar arquivo regular -> (3) validar manifest ->
(4) validar compatibilidade -> (5) calcular SHA-256 -> (6) comparar SHA ->
(7) SÓ ENTÃO ``joblib.load`` -> (8) validar objeto -> (9) marcar READY.

O hash é verificado ANTES de qualquer ``joblib.load`` (nunca depois). Nenhum
``fit``/``fit_transform`` é executado (sem retreinamento).
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from enum import Enum
from pathlib import Path

import joblib
import numpy as np

from meu_bebe_ml.preprocessing.contract import resolve_spec
from meu_bebe_ml.schema.constants import X_MODEL

from ..config import Settings, get_settings
from ..contracts.dss import DSS_SCHEMA_VERSION, DssPayload
from .adapter import to_x_model_dataframe
from .artifact import (
    ModelManifest,
    check_compatibility,
    load_manifest,
    resolve_artifact_path,
    verify_integrity,
)
from .errors import (
    ModelArtifactNotFoundError,
    ModelCompatibilityError,
    ModelError,
    ModelNotReadyError,
    ModelStructureError,
)

logger = logging.getLogger(__name__)


class RuntimeState(str, Enum):
    NOT_LOADED = "not_loaded"
    READY = "ready"
    ERROR = "error"


@dataclass(frozen=True)
class ModelMetadata:
    """Metadados internos do modelo carregado (NUNCA expostos via HTTP)."""

    name: str
    raw_feature_count: int
    transformed_feature_count: int
    schema_version: str
    positive_class_index: int
    artifact_sha256: str


class ModelRuntime:
    """Estado + carregamento + inferência interna do modelo DSS 1.13."""

    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()
        self._state = RuntimeState.NOT_LOADED
        self._pipeline: object | None = None
        self._metadata: ModelMetadata | None = None
        self._last_error_code: str | None = None
        self._loaded_artifact_path: Path | None = None

    # ------------------------------------------------------------------
    # Estado
    # ------------------------------------------------------------------

    @property
    def state(self) -> RuntimeState:
        return self._state

    @property
    def is_ready(self) -> bool:
        return self._state is RuntimeState.READY

    @property
    def metadata(self) -> ModelMetadata | None:
        return self._metadata

    @property
    def last_error_code(self) -> str | None:
        return self._last_error_code

    # ------------------------------------------------------------------
    # Carregamento
    # ------------------------------------------------------------------

    def load(self) -> None:
        """Carrega o modelo de forma idempotente e FAIL-CLOSED.

        Se já estiver READY com o mesmo artefato, não recarrega. Em falha,
        marca estado ERROR e re-levanta a exceção (sanitizada) — o app continua
        de pé (a liveness não depende do modelo).
        """
        artifact_path = resolve_artifact_path(self._settings.model_artifact_path)
        manifest_path = resolve_artifact_path(self._settings.model_manifest_path)

        if self.is_ready and self._loaded_artifact_path == artifact_path:
            return

        self._state = RuntimeState.NOT_LOADED
        self._pipeline = None
        self._metadata = None
        self._last_error_code = None
        self._loaded_artifact_path = None

        try:
            self._do_load(artifact_path, manifest_path)
        except ModelError as exc:
            self._state = RuntimeState.ERROR
            self._last_error_code = exc.code
            logger.error("falha ao carregar o modelo: %s", exc)
            raise

    def _do_load(self, artifact_path: Path, manifest_path: Path) -> None:
        # (1) path já resolvido + (2) confirmar arquivo regular.
        if not artifact_path.is_file():
            raise ModelArtifactNotFoundError(
                f"artefato inexistente ou não é arquivo regular: {artifact_path}"
            )

        # (3) validar manifest REAL.
        manifest = load_manifest(manifest_path)

        # Schema do manifest deve bater com o contrato da API.
        if manifest.schema_version != DSS_SCHEMA_VERSION:
            raise ModelCompatibilityError(
                f"schema_version do manifest {manifest.schema_version!r} "
                f"!= contrato {DSS_SCHEMA_VERSION!r}"
            )

        # (4) compatibilidade de bibliotecas (igualdade exata, FAIL-CLOSED).
        check_compatibility(manifest)

        # (5)+(6) integridade: SHA-256 ANTES de qualquer desserialização.
        actual_sha = verify_integrity(artifact_path, manifest.model_file_hash_sha256)

        # (7) SÓ ENTÃO desserializar.
        try:
            pipeline = joblib.load(artifact_path)
        except Exception as exc:  # noqa: BLE001 — qualquer falha vira erro próprio
            raise ModelStructureError(f"joblib.load falhou: {exc}") from exc

        # (8) validar a estrutura do objeto carregado.
        metadata = self._validate_pipeline(pipeline, manifest, actual_sha)

        # (9) marcar READY.
        self._pipeline = pipeline
        self._metadata = metadata
        self._loaded_artifact_path = artifact_path
        self._state = RuntimeState.READY

    def _validate_pipeline(
        self, pipeline: object, manifest: ModelManifest, actual_sha: str
    ) -> ModelMetadata:
        from sklearn.compose import ColumnTransformer
        from sklearn.ensemble import RandomForestClassifier
        from sklearn.pipeline import Pipeline

        if not isinstance(pipeline, Pipeline):
            raise ModelStructureError("artefato não é um sklearn Pipeline")

        steps = dict(pipeline.steps)
        if set(steps) != {"preprocessor", "model"}:
            raise ModelStructureError(f"steps inesperados: {sorted(steps)}")

        pre = steps["preprocessor"]
        model = steps["model"]
        if not isinstance(pre, ColumnTransformer):
            raise ModelStructureError("step 'preprocessor' não é ColumnTransformer")
        if not isinstance(model, RandomForestClassifier):
            raise ModelStructureError("step 'model' não é RandomForestClassifier")

        # Classes [0,1] + busca da classe positiva (nunca hardcode [:,1]).
        classes = list(getattr(model, "classes_", []))
        if classes != [0, 1]:
            raise ModelStructureError(f"classes_ inesperadas: {classes}")
        positive_class_index = classes.index(1)

        # Número de features transformadas (deve bater com o manifest e com o
        # contrato canônico de preprocessing exposto por meu_bebe_ml).
        try:
            out_names = list(pre.get_feature_names_out())
        except Exception as exc:  # noqa: BLE001
            raise ModelStructureError(f"get_feature_names_out falhou: {exc}") from exc

        if len(out_names) != manifest.n_features:
            raise ModelStructureError(
                f"features transformadas {len(out_names)} != manifest {manifest.n_features}"
            )
        canonical_names = list(resolve_spec().feature_names)
        if out_names != canonical_names:
            raise ModelStructureError("features transformadas divergem do contrato canônico")

        # Features brutas: 34 (X_MODEL). Se o preprocessor expuser
        # feature_names_in_, conferir; se não, registrar ausência (não inventar).
        raw_count = len(X_MODEL)
        if hasattr(pre, "feature_names_in_"):
            pre_in = list(pre.feature_names_in_)
            if pre_in != list(X_MODEL):
                raise ModelStructureError("feature_names_in_ diverge de X_MODEL")

        if manifest.model_name != "random_forest":
            raise ModelStructureError(f"model_name inesperado: {manifest.model_name!r}")

        return ModelMetadata(
            name=manifest.model_name,
            raw_feature_count=raw_count,
            transformed_feature_count=len(out_names),
            schema_version=manifest.schema_version,
            positive_class_index=positive_class_index,
            artifact_sha256=actual_sha,
        )

    # ------------------------------------------------------------------
    # Inferência interna (sem threshold — não classifica)
    # ------------------------------------------------------------------

    def predict_probability(self, payload: DssPayload) -> float:
        """Probabilidade da classe positiva (``float`` em [0,1]).

        NÃO aplica threshold nem classifica — a decisão binária fica para a
        FASE 4C. Exige estado READY.
        """
        if not self.is_ready or self._pipeline is None or self._metadata is None:
            raise ModelNotReadyError("modelo não está READY")

        x_df = to_x_model_dataframe(payload)
        proba = self._pipeline.predict_proba(x_df)  # shape (1, 2)
        value = float(proba[0, self._metadata.positive_class_index])

        if not np.isfinite(value) or not (0.0 <= value <= 1.0):
            raise ModelError(f"probabilidade inválida produzida pelo modelo: {value!r}")

        return value
