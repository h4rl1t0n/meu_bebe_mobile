"""Validador do contrato de dados DSS 1.13.

Carrega a especificação de ``configs/schema_v1_13.yaml`` e valida registros
(``dict`` de chaves JSON -> valores) contra o contrato congelado. NÃO gera dados.

Um registro válido deve:
  * conter exatamente as 48 chaves de ``Q_FULL`` (nem a mais, nem a menos);
  * ter valores dos tipos canônicos corretos (``bool`` / ``str`` /
    ``list[str]`` / ``int``);
  * usar somente códigos de categoria válidos;
  * respeitar obrigatoriedade, condicionalidades e exclusividades.

A função principal é :func:`validate_record`, que retorna uma lista de
mensagens de violação (vazia = válido).
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml

from . import invariants
from .constants import Q_FULL, SCHEMA_VERSION

# Caminho do arquivo de schema relativo a este módulo.
_SCHEMA_YAML_PATH = (
    Path(__file__).resolve().parents[3] / "configs" / "schema_v1_13.yaml"
)

# Tipos canônicos aceitos no YAML.
_TYPES = ("bool", "categorical", "multiselect", "int")


class SchemaSpec:
    """Especificação carregada do schema YAML (imutável em uso)."""

    def __init__(self, raw: dict[str, Any]) -> None:
        self.version: str = raw["schema_version"]
        self.variables: dict[str, dict[str, Any]] = {}
        self._dimensions: dict[str, list[str]] = {}

        for dim_key, dim in raw["dimensions"].items():
            names: list[str] = []
            for var in dim["variables"]:
                name = var["name"]
                names.append(name)
                self.variables[name] = {
                    "dimension": dim_key,
                    "type": var["type"],
                    "ml_class": var["ml_class"],
                    "required": bool(var.get("required", False)),
                    "conditional": var.get("conditional"),
                    "exclusive": var.get("exclusive"),
                    "categories": tuple(var.get("categories", [])),
                }
            self._dimensions[dim_key] = names

    def names(self) -> tuple[str, ...]:
        """Todos os nomes de variáveis na ordem do YAML."""
        ordered: list[str] = []
        for names in self._dimensions.values():
            ordered.extend(names)
        return tuple(ordered)


def load_schema(path: Path | None = None) -> SchemaSpec:
    """Carrega e devolve a especificação do schema (1.13)."""
    schema_path = path or _SCHEMA_YAML_PATH
    with open(schema_path, "r", encoding="utf-8") as fh:
        raw = yaml.safe_load(fh)
    spec = SchemaSpec(raw)
    if spec.version != SCHEMA_VERSION:
        raise ValueError(
            f"schema YAML version {spec.version!r} != constants.SCHEMA_VERSION "
            f"{SCHEMA_VERSION!r}"
        )
    return spec


# ---------------------------------------------------------------------------
# Validação de chaves
# ---------------------------------------------------------------------------

def validate_keys(record: dict[str, Any]) -> list[str]:
    """Valida que o registro tenha exatamente as 48 chaves de ``Q_FULL``."""
    errors: list[str] = []
    expected = set(Q_FULL)
    actual = set(record.keys())

    missing = expected - actual
    unknown = actual - expected

    if missing:
        errors.append(f"chaves ausentes: {sorted(missing)}")
    if unknown:
        errors.append(f"chaves desconhecidas: {sorted(unknown)}")
    return errors


# ---------------------------------------------------------------------------
# Validação de valores
# ---------------------------------------------------------------------------

def _validate_value(name: str, value: Any, spec: SchemaSpec) -> list[str]:
    """Valida o valor de uma única variável contra o tipo e as categorias."""
    errors: list[str] = []
    var = spec.variables[name]
    vtype = var["type"]
    categories = var["categories"]

    if vtype == "bool":
        if value is not None and not isinstance(value, bool):
            errors.append(
                f"{name} deve ser bool (ou null), recebido {type(value).__name__}"
            )
    elif vtype == "categorical":
        if value is not None:
            if not isinstance(value, str):
                errors.append(
                    f"{name} deve ser str (ou null), recebido {type(value).__name__}"
                )
            elif value not in categories:
                errors.append(f"{name}: categoria inválida {value!r}")
    elif vtype == "multiselect":
        if value is None:
            # `null` é permitido quando não aplicável (ex.: beneficios_trabalho
            # com empregado == false); a obrigatoriedade/condicionalidade é
            # validada separadamente em validate_required e nas invariantes.
            return errors
        if not isinstance(value, list):
            errors.append(
                f"{name} deve ser list[str], recebido {type(value).__name__}"
            )
            return errors
        for code in value:
            if not isinstance(code, str):
                errors.append(
                    f"{name}: código deve ser str, recebido {type(code).__name__}"
                )
            elif code not in categories:
                errors.append(f"{name}: código inválido {code!r}")
    elif vtype == "int":
        if not isinstance(value, int) or isinstance(value, bool):
            errors.append(
                f"{name} deve ser int, recebido {type(value).__name__}"
            )
    else:  # pragma: no cover - tipos validados na carga
        errors.append(f"{name}: tipo desconhecido {vtype!r}")
    return errors


def validate_values(record: dict[str, Any], spec: SchemaSpec) -> list[str]:
    """Valida tipos e categorias de todos os valores do registro."""
    errors: list[str] = []
    for name in spec.names():
        if name in record:
            errors.extend(_validate_value(name, record[name], spec))
    return errors


# ---------------------------------------------------------------------------
# Validação de obrigatoriedade
# ---------------------------------------------------------------------------

def validate_required(record: dict[str, Any], spec: SchemaSpec) -> list[str]:
    """Valida que campos obrigatórios estejam preenchidos.

    ``bool``/``categorical`` obrigatórios não podem ser ``null``; ``multiselect``
    obrigatórios não podem ser vazios; ``int`` não pode ser ``null``.
    """
    errors: list[str] = []
    for name, var in spec.variables.items():
        if not var["required"]:
            continue
        value = record.get(name)
        if var["type"] == "multiselect":
            if not value:  # None ou []
                errors.append(f"{name} é obrigatório (lista não vazia)")
        elif value is None:
            errors.append(f"{name} é obrigatório")
    return errors


# ---------------------------------------------------------------------------
# Validação completa
# ---------------------------------------------------------------------------

def validate_record(
    record: dict[str, Any], spec: SchemaSpec | None = None
) -> list[str]:
    """Valida um registro completo contra o schema DSS 1.13.

    Retorna uma lista de mensagens de violação (``str``). Lista vazia = registro
    válido. Ordem das verificações: chaves -> tipos/categorias ->
    obrigatoriedade -> invariantes estruturais/condicionais.
    """
    if spec is None:
        spec = load_schema()

    errors: list[str] = []
    errors.extend(validate_keys(record))
    errors.extend(validate_values(record, spec))
    errors.extend(validate_required(record, spec))
    errors.extend(invariants.check_invariants(record))
    return errors
