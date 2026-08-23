"""Invariantes estruturais e de condicionalidade do schema DSS 1.13.

Funções puras que recebem um registro (``dict``) e retornam listas de mensagens
de violação (``str``). Uma lista vazia significa que a invariante é satisfeita.

Estas invariantes refletem as regras do formulário Flutter (validators e
controllers), registradas em ``docs/planejamento_dataset_sintetico.md`` §3.
"""

from __future__ import annotations

from typing import Any, Callable, Iterable

# ---------------------------------------------------------------------------
# Códigos de ausência mutuamente exclusivos por campo multiselect.
#
# Fonte: Flutter (catalog + controllers) e docs §15. Cada código de ausência
# ("sem_*" / "nenhum_dos_listados") não coexiste com itens positivos da mesma
# lista. `sem_cuidados` é confirmado pelo código Flutter (`CuidadoVetor`,
# comentário "semCuidados é mutuamente exclusiva") embora a lista explícita do
# §15 do doc omita esse caso — ver README.
# ---------------------------------------------------------------------------
EXCLUSIVE_OF: dict[str, str] = {
    "dificuldades_educacao": "sem_dificuldades",
    "beneficios_trabalho": "sem_beneficios",
    "cuidados_vetores": "sem_cuidados",
    "servicos_pre_natal": "nenhum_dos_listados",
    "dificuldades_saude": "sem_dificuldades",
    "itens_residencia": "nenhum_dos_listados",
    "melhorias_desejadas": "sem_melhorias",
    "alimentos_consumidos": "nenhum_dos_listados",
}

# Campos numéricos que devem ser >= 1.
_MINIMUM_ONE_INT_FIELDS: tuple[str, ...] = (
    "numero_pessoas",
    "numero_comodos",
    "numero_dormitorios",
)

# Campos booleanos cujo valor deve estar em {true, false} (não nulo quando
# obrigatórios). Usado pelo validador genérico; mantido aqui por clareza.
_BOOL_FIELDS: frozenset[str] = frozenset()


def _is_int(value: Any) -> bool:
    """`True` se `value` é um int Python (não bool)."""
    return isinstance(value, int) and not isinstance(value, bool)


# ---------------------------------------------------------------------------
# Invariantes numéricas (Habitação)
# ---------------------------------------------------------------------------

def check_minimum_ones(record: dict[str, Any]) -> list[str]:
    """``numero_pessoas``, ``numero_comodos`` e ``numero_dormitorios`` >= 1."""
    errors: list[str] = []
    for field in _MINIMUM_ONE_INT_FIELDS:
        value = record.get(field)
        if value is None:
            continue  # ausência é tratada pelo validador de obrigatoriedade
        if not _is_int(value):
            errors.append(f"{field} deve ser inteiro, recebido {type(value).__name__}")
            continue
        if value < 1:
            errors.append(f"{field} deve ser >= 1, recebido {value}")
    return errors


def check_dormitorios_leq_comodos(record: dict[str, Any]) -> list[str]:
    """``numero_dormitorios`` <= ``numero_comodos``."""
    dormitorios = record.get("numero_dormitorios")
    comodos = record.get("numero_comodos")
    if not (_is_int(dormitorios) and _is_int(comodos)):
        return []  # tipos inválidos já reportados em check_minimum_ones
    if dormitorios > comodos:
        return [
            f"numero_dormitorios ({dormitorios}) deve ser <= "
            f"numero_comodos ({comodos})"
        ]
    return []


# ---------------------------------------------------------------------------
# Invariantes de condicionalidade (empregado)
# ---------------------------------------------------------------------------

def check_empregado_conditionals(record: dict[str, Any]) -> list[str]:
    """Regras de `empregado` (Trabalho e Renda), conforme docs §3.1.

    - ``empregado == true``  -> `tipo_emprego` e `beneficios_trabalho`
      obrigatórios e não vazios; `motivo_desemprego` não aplicável (null).
    - ``empregado == false`` -> `tipo_emprego` e `beneficios_trabalho` não
      aplicáveis (`null`, e NÃO `[]`); `motivo_desemprego` obrigatório.
    - ``empregado == null``  -> ainda não respondido (não valida condicionais).
    """
    errors: list[str] = []
    empregado = record.get("empregado")
    if empregado is None:
        return errors

    tipo_emprego = record.get("tipo_emprego")
    beneficios = record.get("beneficios_trabalho")
    motivo = record.get("motivo_desemprego")

    if empregado is True:
        if tipo_emprego is None:
            errors.append("empregado == true exige tipo_emprego")
        if not beneficios:  # None ou lista vazia
            errors.append("empregado == true exige beneficios_trabalho não vazio")
        if motivo is not None:
            errors.append("empregado == true: motivo_desemprego deve ser null")
    elif empregado is False:
        if tipo_emprego is not None:
            errors.append("empregado == false: tipo_emprego deve ser null")
        if beneficios is not None:
            errors.append("empregado == false: beneficios_trabalho deve ser null")
        if motivo is None:
            errors.append("empregado == false exige motivo_desemprego")

    return errors


# ---------------------------------------------------------------------------
# Invariantes de condicionalidade (coleta de lixo)
# ---------------------------------------------------------------------------

def check_coleta_conditionals(record: dict[str, Any]) -> list[str]:
    """Regras de `frequencia_coleta_lixo`, conforme docs §3.2.

    - ``regular``    -> `destino_lixo_sem_coleta` não aplicável (null).
    - ``irregular``  -> `destino_lixo_sem_coleta` obrigatório; pode conter
      `aguarda_proxima_coleta`.
    - ``nao_possui`` -> `destino_lixo_sem_coleta` obrigatório;
      `aguarda_proxima_coleta` proibido.
    """
    errors: list[str] = []
    frequencia = record.get("frequencia_coleta_lixo")
    destino = record.get("destino_lixo_sem_coleta")

    if frequencia == "regular":
        if destino is not None:
            errors.append(
                "frequencia_coleta_lixo == regular: destino_lixo_sem_coleta "
                "deve ser null"
            )
    elif frequencia in ("irregular", "nao_possui"):
        if destino is None:
            errors.append(
                f"frequencia_coleta_lixo == {frequencia}: "
                "destino_lixo_sem_coleta é obrigatório"
            )
        elif frequencia == "nao_possui" and destino == "aguarda_proxima_coleta":
            errors.append(
                "frequencia_coleta_lixo == nao_possui: "
                "'aguarda_proxima_coleta' é proibido"
            )
    # frequencia null -> ainda não respondido (não valida condicionais)

    return errors


# ---------------------------------------------------------------------------
# Exclusividade de multiselect
# ---------------------------------------------------------------------------

def check_multiselect_exclusivity(record: dict[str, Any]) -> list[str]:
    """Valida que códigos de ausência não coexistam com itens positivos."""
    errors: list[str] = []
    for field, exclusive_code in EXCLUSIVE_OF.items():
        value = record.get(field)
        if not isinstance(value, list):
            continue
        if exclusive_code in value and len(value) > 1:
            errors.append(
                f"{field}: '{exclusive_code}' não coexiste com outros códigos "
                f"(recebido {value})"
            )
    return errors


# ---------------------------------------------------------------------------
# Agregação
# ---------------------------------------------------------------------------

def check_invariants(record: dict[str, Any]) -> list[str]:
    """Executa todas as invariantes estruturais/condicionais sobre o registro.

    Retorna a lista concatenada de mensagens de violação. Não valida tipos de
    campo nem categorias — isso é responsabilidade de
    ``schema.validator.validate_record``.
    """
    checks: Iterable[Callable[[dict[str, Any]], list[str]]] = (
        check_minimum_ones,
        check_dormitorios_leq_comodos,
        check_empregado_conditionals,
        check_coleta_conditionals,
        check_multiselect_exclusivity,
    )
    errors: list[str] = []
    for check in checks:
        errors.extend(check(record))
    return errors
