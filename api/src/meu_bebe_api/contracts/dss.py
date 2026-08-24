"""Contrato de dados DSS 1.13 — modelos Pydantic v2 (FASE 4A).

Espelho fiel do payload canônico produzido pelo Flutter
(``FormularioData.toMap()``) e do schema congelado
``ia/configs/schema_v1_13.yaml``. Os códigos canônicos foram derivados dos
catálogos Flutter (``lib/app/modules/formulario/catalog/*_options.dart``) e
conferidos contra o schema Python congelado (``ia/src/meu_bebe_ml/schema``).

Regras de contrato:

- 48 variáveis observadas, agrupadas nas 6 dimensões canônicas do JSON:
  ``educacao``, ``trabalho``, ``saneamento``, ``saude``, ``habitacao``,
  ``alimentacao`` — mais ``schema_version`` no envelope.
- Chave ausente -> erro; chave presente com ``null`` -> aceito somente quando
  o campo é declarado ``| None`` (sem default ``None``).
- Booleanos: ``StrictBool`` (``true``/``false``/``null``; nunca ``1``/``"true"``).
- Categóricos: ``Enum`` de códigos canônicos snake_case (nunca rótulos).
- Múltipla escolha: ``list[Enum]``; ``[]`` = não respondido. ``null`` NÃO é
  aceito exceto em ``beneficios_trabalho`` (null estrutural).
- ``extra = "forbid"`` em todos os modelos.
- Exclusividade: código exclusivo presente -> deve ser o único da lista.
- Null estrutural: campos condicionais anuláveis (ver validators).
"""

from __future__ import annotations

from enum import Enum
from typing import Literal

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    StrictBool,
    StrictInt,
    model_validator,
)

# ---------------------------------------------------------------------------
# Versão do contrato de dados (SEPARADA da versão do serviço — ver __init__).
# ---------------------------------------------------------------------------

DSS_SCHEMA_VERSION: str = "1.13"


# ---------------------------------------------------------------------------
# Códigos canônicos (categóricos e múltipla escolha)
# ---------------------------------------------------------------------------
# Um Enum por pergunta. O valor é o próprio código snake_case (idêntico ao
# nome do membro); o rótulo exibido ao usuário NÃO faz parte do contrato.


class Escolaridade(str, Enum):
    sem_instrucao = "sem_instrucao"
    fundamental_incompleto = "fundamental_incompleto"
    fundamental_completo = "fundamental_completo"
    medio_incompleto = "medio_incompleto"
    medio_completo = "medio_completo"
    superior_incompleto = "superior_incompleto"
    superior_completo = "superior_completo"


class SituacaoEstudosGestacao(str, Enum):
    nao_estudava = "nao_estudava"
    nao_interrompeu = "nao_interrompeu"
    interrompeu = "interrompeu"


class DificuldadeEducacao(str, Enum):
    falta_dinheiro = "falta_dinheiro"
    distancia = "distancia"
    falta_transporte = "falta_transporte"
    falta_vagas = "falta_vagas"
    gravidez = "gravidez"
    trabalho = "trabalho"
    cuidado_filhos = "cuidado_filhos"
    sem_dificuldades = "sem_dificuldades"
    outro = "outro"


class TipoEmprego(str, Enum):
    clt = "clt"
    autonomo = "autonomo"
    informal = "informal"


class FaixaRenda(str, Enum):
    ate_1_sm = "ate_1_sm"
    entre_1_2_sm = "entre_1_2_sm"
    entre_2_3_sm = "entre_2_3_sm"
    mais_3_sm = "mais_3_sm"
    nao_informar = "nao_informar"


class BeneficioTrabalho(str, Enum):
    auxilio_maternidade = "auxilio_maternidade"
    vale_transporte = "vale_transporte"
    vale_alimentacao = "vale_alimentacao"
    sem_beneficios = "sem_beneficios"


class MotivoDesemprego(str, Enum):
    dificuldade_encontrar_vaga = "dificuldade_encontrar_vaga"
    problemas_saude = "problemas_saude"
    cuidado_casa_filhos = "cuidado_casa_filhos"
    gestacao = "gestacao"
    opcao_propria = "opcao_propria"
    outro = "outro"


class ImpactoGestacaoTrabalho(str, Enum):
    nao_afetou = "nao_afetou"
    reduziu_jornada = "reduziu_jornada"
    afastamento_temporario = "afastamento_temporario"
    demitida = "demitida"
    pediu_demissao = "pediu_demissao"
    outro = "outro"


class FonteAgua(str, Enum):
    rede_publica = "rede_publica"
    poco_nascente = "poco_nascente"
    cisterna = "cisterna"
    carro_pipa = "carro_pipa"
    outra = "outra"


class EsgotamentoSanitario(str, Enum):
    rede_coletora = "rede_coletora"
    ceu_aberto = "ceu_aberto"
    fossa_septica = "fossa_septica"
    outro = "outro"


class FrequenciaColetaLixo(str, Enum):
    regular = "regular"
    irregular = "irregular"
    nao_possui = "nao_possui"


class DestinoLixoSemColeta(str, Enum):
    aguarda_proxima_coleta = "aguarda_proxima_coleta"
    queima = "queima"
    enterra = "enterra"
    terreno_baldio = "terreno_baldio"
    outro = "outro"


class CuidadoVetor(str, Enum):
    elimina_agua_parada = "elimina_agua_parada"
    mantem_reservatorios_tampados = "mantem_reservatorios_tampados"
    usa_repelente = "usa_repelente"
    usa_mosquiteiro_telas = "usa_mosquiteiro_telas"
    mantem_ambiente_limpo = "mantem_ambiente_limpo"
    usa_inseticida = "usa_inseticida"
    sem_cuidados = "sem_cuidados"
    outro = "outro"


class DistanciaUBS(str, Enum):
    muito_proxima = "muito_proxima"
    razoavelmente_proxima = "razoavelmente_proxima"
    distante = "distante"


class AcessoUBS(str, Enum):
    a_pe = "a_pe"
    transporte_publico = "transporte_publico"
    carro_moto = "carro_moto"
    outro = "outro"


class ServicoPreNatal(str, Enum):
    consulta_medica = "consulta_medica"
    consulta_enfermagem = "consulta_enfermagem"
    grupo_gestantes = "grupo_gestantes"
    nenhum_dos_listados = "nenhum_dos_listados"


class AvaliacaoPreNatal(str, Enum):
    excelente = "excelente"
    bom = "bom"
    regular = "regular"
    ruim = "ruim"
    pessimo = "pessimo"


class DificuldadeSaude(str, Enum):
    dificuldade_agendamento = "dificuldade_agendamento"
    demora_atendimento = "demora_atendimento"
    distancia = "distancia"
    falta_transporte = "falta_transporte"
    horario_incompativel = "horario_incompativel"
    falta_profissional = "falta_profissional"
    falta_exames = "falta_exames"
    sem_dificuldades = "sem_dificuldades"
    outro = "outro"


class TipoMoradia(str, Enum):
    casa = "casa"
    apartamento = "apartamento"
    comodo_unico = "comodo_unico"
    outro = "outro"


class MaterialMoradia(str, Enum):
    alvenaria = "alvenaria"
    madeira = "madeira"
    mista = "mista"
    outro = "outro"


class ItemResidencia(str, Enum):
    agua_encanada = "agua_encanada"
    banheiro_interno = "banheiro_interno"
    cozinha_separada = "cozinha_separada"
    nenhum_dos_listados = "nenhum_dos_listados"


class SegurancaResidencia(str, Enum):
    muito_segura = "muito_segura"
    segura = "segura"
    regular = "regular"
    insegura = "insegura"
    muito_insegura = "muito_insegura"


class MelhoriaMoradia(str, Enum):
    ampliacao_espaco = "ampliacao_espaco"
    reforma_estrutura = "reforma_estrutura"
    melhorar_banheiro = "melhorar_banheiro"
    melhorar_ventilacao = "melhorar_ventilacao"
    melhorar_instalacao_eletrica = "melhorar_instalacao_eletrica"
    melhorar_abastecimento_agua = "melhorar_abastecimento_agua"
    melhorar_seguranca = "melhorar_seguranca"
    sem_melhorias = "sem_melhorias"
    outro = "outro"


class RefeicoesPorDia(str, Enum):
    uma_duas = "uma_duas"
    tres = "tres"
    quatro_mais = "quatro_mais"


class AlimentoConsumido(str, Enum):
    frutas_verduras = "frutas_verduras"
    carnes = "carnes"
    leite_derivados = "leite_derivados"
    feijao_leguminosas = "feijao_leguminosas"
    nenhum_dos_listados = "nenhum_dos_listados"


class FonteAlimentos(str, Enum):
    supermercado_feira = "supermercado_feira"
    horta_propria = "horta_propria"
    doacoes = "doacoes"
    cesta_basica = "cesta_basica"
    outro = "outro"


class AvaliacaoAlimentacao(str, Enum):
    muito_boa = "muito_boa"
    boa = "boa"
    regular = "regular"
    ruim = "ruim"


# ---------------------------------------------------------------------------
# Helpers de validação cruzada
# ---------------------------------------------------------------------------


def _check_exclusive(values: list, exclusive: Enum, field: str) -> None:
    """Rejeita a presença do código exclusivo combinado com outros códigos."""
    if len(values) > 1 and exclusive in values:
        raise ValueError(
            f"campo {field!r}: o código exclusivo {exclusive.value!r} "
            "não pode ser combinado com outros códigos"
        )


# ---------------------------------------------------------------------------
# Dimensões
# ---------------------------------------------------------------------------


class EducacaoModel(BaseModel):
    model_config = ConfigDict(extra="forbid")

    estuda_atualmente: StrictBool | None
    escolaridade: Escolaridade | None
    situacao_estudos_gestacao: SituacaoEstudosGestacao | None
    dificuldades_educacao: list[DificuldadeEducacao]
    entende_orientacoes_saude: StrictBool | None
    fez_curso_qualificacao_profissional: StrictBool | None

    @model_validator(mode="after")
    def _check_exclusivity(self) -> "EducacaoModel":
        _check_exclusive(
            self.dificuldades_educacao,
            DificuldadeEducacao.sem_dificuldades,
            "dificuldades_educacao",
        )
        return self


class TrabalhoModel(BaseModel):
    model_config = ConfigDict(extra="forbid")

    empregado: StrictBool | None
    tipo_emprego: TipoEmprego | None
    faixa_renda: FaixaRenda | None
    trabalho_permite_pre_natal: StrictBool | None
    ambiente_trabalho_seguro: StrictBool | None
    tem_pausas_descanso: StrictBool | None
    beneficios_trabalho: list[BeneficioTrabalho] | None
    motivo_desemprego: MotivoDesemprego | None
    recebe_beneficio_social: StrictBool | None
    impacto_gestacao_trabalho: ImpactoGestacaoTrabalho | None

    @model_validator(mode="after")
    def _check_structural_and_exclusivity(self) -> "TrabalhoModel":
        if self.empregado is True:
            if self.tipo_emprego is None:
                raise ValueError(
                    "campo 'tipo_emprego' é obrigatório quando empregado=true"
                )
            if self.beneficios_trabalho is None or len(self.beneficios_trabalho) == 0:
                raise ValueError(
                    "campo 'beneficios_trabalho' deve ser uma lista não vazia "
                    "quando empregado=true"
                )
        if self.empregado is False and self.motivo_desemprego is None:
            raise ValueError(
                "campo 'motivo_desemprego' é obrigatório quando empregado=false"
            )
        if self.beneficios_trabalho is not None:
            _check_exclusive(
                self.beneficios_trabalho,
                BeneficioTrabalho.sem_beneficios,
                "beneficios_trabalho",
            )
        return self


class SaneamentoModel(BaseModel):
    model_config = ConfigDict(extra="forbid")

    fonte_agua: FonteAgua | None
    interrupcoes_agua: StrictBool | None
    esgotamento_sanitario: EsgotamentoSanitario | None
    frequencia_coleta_lixo: FrequenciaColetaLixo | None
    destino_lixo_sem_coleta: DestinoLixoSemColeta | None
    problema_saude_agua: StrictBool | None
    cuidados_vetores: list[CuidadoVetor]

    @model_validator(mode="after")
    def _check_structural_and_exclusivity(self) -> "SaneamentoModel":
        if (
            self.frequencia_coleta_lixo is not None
            and self.frequencia_coleta_lixo != FrequenciaColetaLixo.regular
            and self.destino_lixo_sem_coleta is None
        ):
            raise ValueError(
                "campo 'destino_lixo_sem_coleta' é obrigatório quando "
                "frequencia_coleta_lixo != 'regular'"
            )
        _check_exclusive(
            self.cuidados_vetores,
            CuidadoVetor.sem_cuidados,
            "cuidados_vetores",
        )
        return self


class SaudeModel(BaseModel):
    model_config = ConfigDict(extra="forbid")

    distancia_ubs: DistanciaUBS | None
    faltou_consulta: StrictBool | None
    acesso_ubs: AcessoUBS | None
    cadastrada_ubs: StrictBool | None
    servicos_pre_natal: list[ServicoPreNatal]
    exames_pre_natal_completos: StrictBool | None
    vacinas_em_dia: StrictBool | None
    avaliacao_pre_natal: AvaliacaoPreNatal | None
    dificuldades_saude: list[DificuldadeSaude]

    @model_validator(mode="after")
    def _check_exclusivity(self) -> "SaudeModel":
        _check_exclusive(
            self.servicos_pre_natal,
            ServicoPreNatal.nenhum_dos_listados,
            "servicos_pre_natal",
        )
        _check_exclusive(
            self.dificuldades_saude,
            DificuldadeSaude.sem_dificuldades,
            "dificuldades_saude",
        )
        return self


class HabitacaoModel(BaseModel):
    model_config = ConfigDict(extra="forbid")

    tipo_moradia: TipoMoradia | None
    material_moradia: MaterialMoradia | None
    numero_pessoas: StrictInt = Field(ge=1)
    numero_comodos: StrictInt = Field(ge=1)
    numero_dormitorios: StrictInt = Field(ge=1)
    itens_residencia: list[ItemResidencia]
    seguranca_residencia: SegurancaResidencia | None
    melhorias_desejadas: list[MelhoriaMoradia]
    facil_acesso_saude: StrictBool | None

    @model_validator(mode="after")
    def _check_invariants_and_exclusivity(self) -> "HabitacaoModel":
        if self.numero_dormitorios > self.numero_comodos:
            raise ValueError(
                "campo 'numero_dormitorios' não pode ser maior que "
                "'numero_comodos'"
            )
        _check_exclusive(
            self.itens_residencia,
            ItemResidencia.nenhum_dos_listados,
            "itens_residencia",
        )
        _check_exclusive(
            self.melhorias_desejadas,
            MelhoriaMoradia.sem_melhorias,
            "melhorias_desejadas",
        )
        return self


class AlimentacaoModel(BaseModel):
    model_config = ConfigDict(extra="forbid")

    refeicoes_por_dia: RefeicoesPorDia | None
    deixou_de_comer_falta_dinheiro: StrictBool | None
    alimentos_consumidos: list[AlimentoConsumido]
    fonte_alimentos: list[FonteAlimentos]
    mudanca_alimentacao_gestacao: StrictBool | None
    usa_suplementos: StrictBool | None
    avaliacao_alimentacao: AvaliacaoAlimentacao | None

    @model_validator(mode="after")
    def _check_exclusivity(self) -> "AlimentacaoModel":
        _check_exclusive(
            self.alimentos_consumidos,
            AlimentoConsumido.nenhum_dos_listados,
            "alimentos_consumidos",
        )
        return self


# ---------------------------------------------------------------------------
# Envelope (payload canônico do Flutter)
# ---------------------------------------------------------------------------


class DssPayload(BaseModel):
    """Payload canônico aninhado e versionado (``FormularioData.toMap()``)."""

    model_config = ConfigDict(extra="forbid")

    schema_version: Literal["1.13"]
    educacao: EducacaoModel
    trabalho: TrabalhoModel
    saneamento: SaneamentoModel
    saude: SaudeModel
    habitacao: HabitacaoModel
    alimentacao: AlimentacaoModel
