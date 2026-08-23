# Planejamento do Dataset Sintético — DSS Pré-natal

> **Documento de planejamento metodológico (nível técnico).**
> Este documento **não** gera, treina nem implementa nada: é a especificação
> técnica que antecede a etapa de geração do dataset sintético e do modelo de ML.
>
> ⚠️ **Dado sintético não representa dados clínicos reais e não deve ser
> interpretado como evidência de prevalência ou desempenho clínico real.**
>
> **Fonte de verdade do contrato de dados:** o código Flutter
> (`lib/app/modules/formulario/`). O schema DSS foi versionado durante a
> estabilização do instrumento; **`schema_version = 1.13`** é o contrato
> consolidado (congelado) utilizado nas próximas etapas.

---

## 1. Contrato de dados — Schema DSS 1.13

O contrato separa três coisas que não podem ser confundidas:

1. **chave JSON** — o identificador da variável (ex.: `escolaridade`);
2. **código canônico** — o valor estável em `snake_case` (ex.: `medio_completo`);
3. **label** — texto exibido na UI (ex.: "Ensino Médio Completo").

Os **labels são somente de UI** e **não** fazem parte do dataset canônico: eles
podem mudar sem afetar o dataset. O **código canônico** é estável e é o que entra
como valor de feature.

O schema contém **6 dimensões** e **48 variáveis**:

- Educação
- Trabalho e Renda
- Saneamento
- Saúde
- Habitação
- Alimentação

> **Schema congelado.** Não alterar nomes de campos, códigos, listas, tipos
> (`bool?`, `String?`, `List<String>`, `int`), regras de formulário, `toMap`,
> `fromMap`, `toFlatMap`, controllers, páginas, validators ou testes Flutter.
> Novos campos (idade gestacional em T0, IV-DSS, fatores `Z_*`/`g_*`, target,
> `p_true`, escore latente) **não** pertencem ao Flutter.

### 1.1 Tipos canônicos

| Tipo                | Semântica                                                                                             |
| ------------------- | ----------------------------------------------------------------------------------------------------- |
| `String?` categórica| armazena o **código** (nunca o label). `null` = não respondido / não aplicável (conforme o campo).     |
| `List<String>`      | múltipla escolha de **códigos**. `[]` = não respondido (inválido no formulário final).                 |
| `bool?`             | `true` = Sim; `false` = Não; `null` = não respondido (nunca confundido com "Não").                     |
| `int`               | valor numérico (Habitação).                                                                            |

### 1.2 Ausência de resposta

- **`bool?`:** `true` = Sim, `false` = Não, `null` = não respondido. Em campos
  condicionais, `null` também pode significar **"não aplicável"**, conforme a
  regra do campo.
- **`List<String>` obrigatória:** `[]` = ainda não respondido/inválido no
  formulário final.
- **Respostas explícitas de ausência** usam códigos canônicos quando existentes:
  `sem_dificuldades`, `sem_cuidados`, `sem_melhorias`, `sem_beneficios`,
  `nenhum_dos_listados`.

> **Não** converter `bool` em `0/1` no Flutter. A conversão analítica
> (`bool → int`) pertence ao pré-processamento em Python.

---

## 2. Dicionário de variáveis (48)

Legenda de tipos: `C` = categórica (`String?`, código); `L` = múltipla escolha
(`List<String>`, códigos); `B` = booleana (`bool?`); `N` = numérica (`int`).
A coluna **ML** refere-se à classificação consolidada da seção 5.

### 2.1 Educação (6)

| Chave JSON                         | Tipo | ML | Categorias (códigos) |
| ---------------------------------- | ---- | --- | -------------------- |
| `estuda_atualmente`                | B    | IN | — |
| `escolaridade`                     | C    | IN | `sem_instrucao`, `fundamental_incompleto`, `fundamental_completo`, `medio_incompleto`, `medio_completo`, `superior_incompleto`, `superior_completo` |
| `situacao_estudos_gestacao`        | C    | OUT-TEMPORAL | `nao_estudava`, `nao_interrompeu`, `interrompeu` |
| `dificuldades_educacao`            | L    | IN | `falta_dinheiro`, `distancia`, `falta_transporte`, `falta_vagas`, `gravidez`, `trabalho`, `cuidado_filhos`, `sem_dificuldades`, `outro` |
| `entende_orientacoes_saude`        | B    | IN | — |
| `fez_curso_qualificacao_profissional` | B | IN | — |

### 2.2 Trabalho e Renda (10)

| Chave JSON                    | Tipo | ML | Categorias (códigos) |
| ----------------------------- | ---- | --- | -------------------- |
| `empregado`                   | B    | IN | — |
| `tipo_emprego`                | C    | IN | `clt`, `autonomo`, `informal` |
| `faixa_renda`                 | C    | IN | `ate_1_sm`, `entre_1_2_sm`, `entre_2_3_sm`, `mais_3_sm`, `nao_informar` |
| `trabalho_permite_pre_natal`  | B    | IN | — |
| `ambiente_trabalho_seguro`    | B    | IN | — |
| `tem_pausas_descanso`         | B    | IN | — |
| `beneficios_trabalho`         | L    | IN | `auxilio_maternidade`, `vale_transporte`, `vale_alimentacao`, `sem_beneficios` |
| `motivo_desemprego`           | C    | OUT-TEMPORAL | `dificuldade_encontrar_vaga`, `problemas_saude`, `cuidado_casa_filhos`, `gestacao`, `opcao_propria`, `outro` |
| `recebe_beneficio_social`     | B    | IN | — |
| `impacto_gestacao_trabalho`   | C    | OUT-TEMPORAL | `nao_afetou`, `reduziu_jornada`, `afastamento_temporario`, `demitida`, `pediu_demissao`, `outro` |

### 2.3 Saneamento (7)

| Chave JSON                 | Tipo | ML | Categorias (códigos) |
| -------------------------- | ---- | --- | -------------------- |
| `fonte_agua`               | C    | IN | `rede_publica`, `poco_nascente`, `cisterna`, `carro_pipa`, `outra` |
| `interrupcoes_agua`        | B    | IN | — |
| `esgotamento_sanitario`    | C    | IN | `rede_coletora`, `ceu_aberto`, `fossa_septica`, `outro` |
| `frequencia_coleta_lixo`   | C    | IN | `regular`, `irregular`, `nao_possui` |
| `destino_lixo_sem_coleta`  | C    | IN | `aguarda_proxima_coleta`, `queima`, `enterra`, `terreno_baldio`, `outro` |
| `problema_saude_agua`      | B    | SENSIBILIDADE | — |
| `cuidados_vetores`         | L    | DESCRITIVA | `elimina_agua_parada`, `mantem_reservatorios_tampados`, `usa_repelente`, `usa_mosquiteiro_telas`, `mantem_ambiente_limpo`, `usa_inseticida`, `sem_cuidados`, `outro` |

### 2.4 Saúde (9)

| Chave JSON                   | Tipo | ML | Categorias (códigos) |
| ---------------------------- | ---- | --- | -------------------- |
| `distancia_ubs`              | C    | IN | `muito_proxima`, `razoavelmente_proxima`, `distante` |
| `faltou_consulta`            | B    | OUT-LEAKAGE | — |
| `acesso_ubs`                 | C    | IN | `a_pe`, `transporte_publico`, `carro_moto`, `outro` |
| `cadastrada_ubs`             | B    | IN | — |
| `servicos_pre_natal`         | L    | OUT-LEAKAGE | `consulta_medica`, `consulta_enfermagem`, `grupo_gestantes`, `nenhum_dos_listados` |
| `exames_pre_natal_completos` | B    | OUT-LEAKAGE | — |
| `vacinas_em_dia`             | B    | OUT-LEAKAGE | — |
| `avaliacao_pre_natal`        | C    | OUT-LEAKAGE | `excelente`, `bom`, `regular`, `ruim`, `pessimo` |
| `dificuldades_saude`         | L    | IN | `dificuldade_agendamento`, `demora_atendimento`, `distancia`, `falta_transporte`, `horario_incompativel`, `falta_profissional`, `falta_exames`, `sem_dificuldades`, `outro` |

### 2.5 Habitação (9)

| Chave JSON              | Tipo | ML | Categorias (códigos) |
| ----------------------- | ---- | --- | -------------------- |
| `tipo_moradia`          | C    | IN | `casa`, `apartamento`, `comodo_unico`, `outro` |
| `material_moradia`      | C    | IN | `alvenaria`, `madeira`, `mista`, `outro` |
| `numero_pessoas`        | N    | IN | — |
| `numero_comodos`        | N    | IN | — |
| `numero_dormitorios`    | N    | IN | — |
| `itens_residencia`      | L    | IN | `agua_encanada`, `banheiro_interno`, `cozinha_separada`, `nenhum_dos_listados` |
| `seguranca_residencia`  | C    | IN | `muito_segura`, `segura`, `regular`, `insegura`, `muito_insegura` |
| `melhorias_desejadas`   | L    | DESCRITIVA | `ampliacao_espaco`, `reforma_estrutura`, `melhorar_banheiro`, `melhorar_ventilacao`, `melhorar_instalacao_eletrica`, `melhorar_abastecimento_agua`, `melhorar_seguranca`, `sem_melhorias`, `outro` |
| `facil_acesso_saude`    | B    | SENSIBILIDADE | — |

### 2.6 Alimentação (7)

| Chave JSON                          | Tipo | ML | Categorias (códigos) |
| ----------------------------------- | ---- | --- | -------------------- |
| `refeicoes_por_dia`                 | C    | IN | `uma_duas`, `tres`, `quatro_mais` |
| `deixou_de_comer_falta_dinheiro`    | B    | IN | — |
| `alimentos_consumidos`              | L    | IN | `frutas_verduras`, `carnes`, `leite_derivados`, `feijao_leguminosas`, `nenhum_dos_listados` |
| `fonte_alimentos`                   | L    | IN | `supermercado_feira`, `horta_propria`, `doacoes`, `cesta_basica`, `outro` |
| `mudanca_alimentacao_gestacao`      | B    | OUT-TEMPORAL | — |
| `usa_suplementos`                   | B    | OUT-TEMPORAL | — |
| `avaliacao_alimentacao`             | C    | IN | `muito_boa`, `boa`, `regular`, `ruim` |

---

## 3. Condicionalidades

### 3.1 `empregado` (Trabalho e Renda)

- `empregado = null` → ainda não respondeu; nenhum bloco (emprego/desemprego) é
  exibido e os campos condicionais não são aplicáveis.
- `empregado = true` → `tipo_emprego`, `trabalho_permite_pre_natal`,
  `ambiente_trabalho_seguro`, `tem_pausas_descanso`, `beneficios_trabalho`.
- `empregado = false` → `motivo_desemprego`.

`faixa_renda`, `recebe_beneficio_social` e `impacto_gestacao_trabalho` são
**independentes** da condição `empregado`.

- `beneficios_trabalho`: obrigatório e não vazio quando `empregado == true`;
  `sem_beneficios` é resposta válida (exclusiva); `null` quando
  `empregado == false` ou não respondido.

### 3.2 `frequencia_coleta_lixo` (Saneamento)

- `regular` → `destino_lixo_sem_coleta` **não aplicável** (`null`).
- `irregular` → `destino_lixo_sem_coleta` **obrigatório**; pode incluir
  `aguarda_proxima_coleta`.
- `nao_possui` → `destino_lixo_sem_coleta` **obrigatório**;
  `aguarda_proxima_coleta` **proibido**.

> **Não** inventar condicionais além das documentadas acima.

---

## 4. População, T0 e horizonte temporal

**População-alvo do modelo:** gestantes que **já iniciaram** o acompanhamento
pré-natal. Não existe campo `iniciou_pre_natal` no formulário — isso faz parte do
**critério de inclusão** da população, não de uma variável coletada.

**T0** = instante em que a gestante conclui o questionário DSS e os dados são
enviados à API para inferência.

```text
início do pré-natal
        ↓
questionário DSS
        ↓
       T0
        ↓
preprocessing / modelo
        ↓
estimativa de risco
        ↓
acompanhamento restante da gestação
        ↓
desfecho posterior
```

- O questionário deve ser aplicado **preferencialmente o mais cedo possível** no
  acompanhamento.
- Somente informações **legitimamente disponíveis em ou antes de T0** podem
  participar do modelo preditivo principal.

---

## 5. Classificação metodológica das 48 variáveis para ML

Classificação consolidada das 48 variáveis do formulário:

| Classe | Qtde | Significado |
| ------ | ---- | ----------- |
| **ML-IN** | 34 | feature metodologicamente admissível no experimento |
| **OUT-LEAKAGE** | 5 | proximidade com acompanhamento/desfecho |
| **OUT-TEMPORAL** | 5 | mistura antecedente com acontecimento durante a gestação/acompanhamento |
| **DESCRITIVA** | 2 | caracterização, sem justificativa para feature principal |
| **SENSIBILIDADE** | 2 | fora do modelo principal; testadas em comparação (34 vs. 34+2) |

**Total: 34 + 5 + 5 + 2 + 2 = 48.**

> Estar em ML-IN **não** significa causalidade comprovada; significa apenas
> admissibilidade metodológica. Após o preprocessing, as 34 variáveis conceituais
> resultam em um número **maior** de colunas (one-hot, multi-hot e features
> derivadas).

### 5.1 ML-IN — 34 variáveis

- **Educação (5):** `estuda_atualmente`, `escolaridade`, `dificuldades_educacao`,
  `entende_orientacoes_saude`, `fez_curso_qualificacao_profissional`.
- **Trabalho e Renda (8):** `empregado`, `tipo_emprego`, `faixa_renda`,
  `trabalho_permite_pre_natal`, `ambiente_trabalho_seguro`, `tem_pausas_descanso`,
  `beneficios_trabalho`, `recebe_beneficio_social`.
- **Saneamento (5):** `fonte_agua`, `interrupcoes_agua`, `esgotamento_sanitario`,
  `frequencia_coleta_lixo`, `destino_lixo_sem_coleta`.
- **Saúde/Acesso (4):** `distancia_ubs`, `acesso_ubs`, `cadastrada_ubs`,
  `dificuldades_saude`.
- **Habitação (7):** `tipo_moradia`, `material_moradia`, `numero_pessoas`,
  `numero_comodos`, `numero_dormitorios`, `itens_residencia`,
  `seguranca_residencia`.
- **Alimentação (5):** `refeicoes_por_dia`, `deixou_de_comer_falta_dinheiro`,
  `alimentos_consumidos`, `fonte_alimentos`, `avaliacao_alimentacao`.

### 5.2 OUT-LEAKAGE — 5 variáveis

`faltou_consulta`, `servicos_pre_natal`, `exames_pre_natal_completos`,
`vacinas_em_dia`, `avaliacao_pre_natal`.

Descrevem a própria trajetória, experiência ou adesão ao pré-natal e podem
aproximar-se indevidamente do desfecho que se deseja prever. Excluídas do modelo
principal **e** do IV-DSS. **Decisão fechada** — não reabrir.

### 5.3 OUT-TEMPORAL — 5 variáveis

`situacao_estudos_gestacao`, `motivo_desemprego`, `impacto_gestacao_trabalho`,
`mudanca_alimentacao_gestacao`, `usa_suplementos`.

Misturam condição antecedente com acontecimentos/comportamentos ocorridos durante
a gestação/acompanhamento. Permanecem **coletadas**; podem ser usadas em
descrição ou análises secundárias, mas **não** no modelo preditivo principal.

### 5.4 DESCRITIVA — 2 variáveis

`cuidados_vetores`, `melhorias_desejadas`. Não entram no modelo principal.

### 5.5 SENSIBILIDADE — 2 variáveis

`problema_saude_agua`, `facil_acesso_saude`. Não entram no modelo principal.
Poderão ser comparadas em análise de sensibilidade: modelo principal (34
features) **vs.** modelo de sensibilidade (34 + 2).

### 5.6 Nomenclatura conceitual (Q_full, X_model, X_sens, Y, M_sim)

- `Q_full` = conjunto completo das **48 variáveis** observadas do questionário
  DSS.
- `X_model` = subconjunto das **34 variáveis ML-IN** usadas como entrada do
  modelo principal.
- `X_sens` = 34 ML-IN + 2 variáveis de sensibilidade (36), usado somente no
  experimento secundário 34 vs. 36.
- `Y` = target binário sintético (externo ao formulário).
- `M_sim` = metadados internos da simulação (`Z_*`, `g_*`, `eta`, `p_true`,
  condição/renda latente verdadeira etc.), nunca observados pelo modelo.

```text
Q_full (48)
   |
   |--> seleção --> X_model (34) --> ML principal
   |
   |--> seleção --> X_sens (36)  --> análise de sensibilidade
   |
   `--> cálculo independente --> IV-DSS

M_sim  --> auditoria do simulador somente
Y      --> variável-alvo
```

- As 5 OUT-LEAKAGE e as 5 OUT-TEMPORAL pertencem a `Q_full`, mas **não** a
  `X_model`.
- As 2 DESCRITIVAS pertencem a `Q_full`, mas **não** a `X_model`.
- As 2 SENSIBILIDADE pertencem a `Q_full` e somente entram em `X_sens`.
- `M_sim` **nunca** é entrada do treinamento.

---

## 6. Separação entre ML e IV-DSS

- **IV-DSS ≠ probabilidade produzida pelo modelo.**
- IV-DSS = índice **descritivo experimental** de vulnerabilidade social.
- ML = estimativa probabilística do desfecho sintético.

Regras:

- **NÃO** usar IV-DSS como target.
- **NÃO** usar IV-DSS para gerar Y.
- **NÃO** usar IV-DSS como feature principal do ML.
- O IV-DSS poderá ser analisado posteriormente em relação às previsões e ao Y,
  mas é **calculado de forma independente**.

---

## 7. Variável-alvo (externa ao formulário)

**Conceito:** descontinuidade do acompanhamento pré-natal.

Há dois planos distintos que **não** devem ser confundidos:

**A) Referência para futuro estudo com dados reais.**

- A Portaria GM/MS nº 5.350/2024 estabelece, no contexto da **Rede Alyne**,
  captação até 12 semanas e **no mínimo sete consultas** (Art. 7º, §1º, I).
- Essa referência normativa contextualiza a adequação **quantitativa** do
  acompanhamento.
- A Portaria **não** define "menos de sete consultas" como critério clínico
  universal de abandono/descontinuidade.
- A Portaria **não** fornece, nesse dispositivo, tabela de número mínimo de
  consultas ajustada pela duração gestacional.
- Em futura pesquisa com dados reais, a operacionalização **longitudinal** do
  desfecho ainda deverá ser fundamentada especificamente e considerar
  adequadamente a duração da gestação.

**B) Experimento sintético atual.**

- **Y** é uma variável binária **experimental**, externa ao formulário
  (`descontinuou_pre_natal ∈ {0,1}`).
- Y **não** é calculado a partir de consultas simuladas.
- Y **não** é produzido pela aplicação da regra de sete consultas.
- Y é gerado pelo **DGM probabilístico**: `g_* → eta → sigmoid → Bernoulli`
  (seção 18).
- O objetivo desse Y é testar **tecnicamente** o pipeline de ML em cenário
  controlado.

> **Fonte normativa (referência A):** BRASIL. Ministério da Saúde. **Portaria
> GM/MS nº 5.350, de 12 de setembro de 2024** (Art. 7º, §1º, I) — pré-natal na
> UBS com captação oportuna da gestante até 12 semanas e, no mínimo, sete
> consultas. Disponível em:
> https://bvsms.saude.gov.br/bvs/saudelegis/gm/2024/prt5350_13_09_2024.html.

**Nenhuma** pergunta do formulário fabrica o rótulo. Em futura validação com
dados reais, o critério longitudinal de desfecho deve ser definido e validado a
partir dos registros reais de acompanhamento (prontuário/SISPRENATAL).

---

## 8. IV-DSS proposto

**Nome recomendado:** *"Índice experimental de Vulnerabilidade associada aos
Determinantes Sociais da Saúde (IV-DSS proposto)"*.

**NÃO** chamar de: índice validado, instrumento clínico, escala diagnóstica ou
índice epidemiologicamente validado.

Cada dimensão produz um score entre 0 e 1 (0 = menor vulnerabilidade segundo a
operacionalização adotada; 1 = maior). Seis dimensões com **peso igual**
(`1/6 ≈ 16,67%`), agregação por **média aritmética**:

```text
IV-DSS = (D_educacao + D_trabalho_renda + D_saneamento
          + D_acesso_saude + D_habitacao + D_alimentacao) / 6
```

O IV-DSS **não** é usado como target, para gerar Y, nem como feature principal do
ML.

### 8.1 D_educacao — indicador `escolaridade`

| Código | Escore |
| ------ | ------ |
| `sem_instrucao` | 1.00 |
| `fundamental_incompleto` | 0.83 |
| `fundamental_completo` | 0.67 |
| `medio_incompleto` | 0.50 |
| `medio_completo` | 0.33 |
| `superior_incompleto` | 0.17 |
| `superior_completo` | 0.00 |

`D_educacao = score(escolaridade)`.

- A ordenação possui **fundamento ordinal**.
- Os intervalos iguais são uma **normalização operacional**; **não** implicam que
  as diferenças sociais entre níveis consecutivos sejam empiricamente iguais.
- Uma normalização alternativa deverá ser testada em análise de sensibilidade.
- **Não** converter categorias incompletas para "anos de estudo" inventados.

### 8.2 D_trabalho_renda — indicador `faixa_renda`

| Código | Escore |
| ------ | ------ |
| `ate_1_sm` | 1.00 |
| `entre_1_2_sm` | 0.67 |
| `entre_2_3_sm` | 0.33 |
| `mais_3_sm` | 0.00 |
| `nao_informar` | missing (não pontua) |

`D_trabalho_renda = score(faixa_renda)`.

- A pergunta representa **renda familiar mensal**, não renda per capita — uma
  limitação metodológica registrada.
- `nao_informar` **não** recebe 0.5.
- `empregado` e `tipo_emprego` continuam como features de ML.
- Situação ocupacional poderá ser testada futuramente no IV-DSS em análise de
  sensibilidade; **não** ordenar arbitrariamente CLT/autônomo/informal/
  desempregado; o formulário **não** permite afirmar que todo autônomo seja
  informal.

### 8.3 D_saneamento — três componentes

```text
D_saneamento = média(C_agua, C_esgotamento, C_residuos)
```

#### 8.3.1 C_agua (fonte + água encanada + interrupções)

| Subindicador | Valores |
| ------------ | ------- |
| `fonte_agua` | `rede_publica` → 0 · `poco_nascente` → 0 · `carro_pipa` → 1 · `cisterna` → missing analítico · `outra` → missing analítico |
| `itens_residencia.agua_encanada` | presente → 0 · ausente → 1 |
| `interrupcoes_agua` | `false` → 0 · `true` → 1 |

`C_agua = média dos subindicadores classificáveis`. Exigir **pelo menos 2 dos 3**
subindicadores classificáveis.

- `0` para rede/poço significa que a fonte **isolada** não foi classificada como
  precária pela operacionalização disponível; **não** significa garantia de
  potabilidade ou adequação total.
- `agua_encanada`, embora coletada na seção de habitação, é usada
  analiticamente **aqui** (componente água). **Não** pontuá-la novamente em
  Habitação.

#### 8.3.2 C_esgotamento

| Código | Escore |
| ------ | ------ |
| `rede_coletora` | 0 |
| `fossa_septica` | 0 |
| `ceu_aberto` | 1 |
| `outro` | missing analítico |

`C_esgotamento = score(esgotamento_sanitario)`. **Não** afirmar que toda fossa
séptica seja precária.

#### 8.3.3 C_residuos

- `frequencia_coleta_lixo`: `regular` → 0.0 · `irregular` → 0.5 · `nao_possui` →
  1.0.
- `destino_lixo_sem_coleta` (quando aplicável): `aguarda_proxima_coleta` → 0 ·
  `queima` → 1 · `enterra` → 1 · `terreno_baldio` → 1 · `outro` → missing
  analítico.

`C_residuos = média dos elementos classificáveis`.

> `aguarda_proxima_coleta = 0` no subindicador destino **não** significa situação
> ideal: a deficiência da frequência já foi capturada e não deve ser contada duas
> vezes.

**Validade da dimensão:** exigir **pelo menos 2/3** componentes principais
válidos.

**Não pontuar no IV-DSS principal:** `problema_saude_agua`, `cuidados_vetores`.

### 8.4 D_acesso_saude — dois componentes

```text
D_acesso_saude = (C_distancia + C_barreiras) / 2
```

#### 8.4.1 C_distancia

| Código | Escore |
| ------ | ------ |
| `muito_proxima` | 0 |
| `razoavelmente_proxima` | 0.5 |
| `distante` | 1 |

#### 8.4.2 C_barreiras (domínios de `dificuldades_saude`)

Agrupamento das respostas em três domínios:

| Domínio | Códigos |
| ------- | ------- |
| **TRANSPORTE** | `falta_transporte` |
| **ORGANIZAÇÃO** | `dificuldade_agendamento`, `demora_atendimento`, `horario_incompativel` |
| **DISPONIBILIDADE** | `falta_profissional`, `falta_exames` |

Cada domínio: ausente → 0 · presente → 1. Marcar duas ou três dificuldades dentro
do mesmo domínio mantém o domínio valendo **1** (não contar quantidade bruta de
opções).

```text
C_barreiras = (transporte + organizacao + disponibilidade) / 3
```

- `sem_dificuldades` → `C_barreiras = 0`.
- `outro` isoladamente → tratar o componente como **indeterminado** quando não
  houver barreira classificável.
- `dificuldades_saude.distancia` **não** entra novamente (já existe
  `distancia_ubs`).

**Validade:** `D_acesso_saude` exige **2/2** componentes válidos.

**Não pontuar no IV-DSS:** `acesso_ubs`, `cadastrada_ubs`, `facil_acesso_saude` e
os cinco campos de leakage. `acesso_ubs` permanece disponível ao ML como variável
nominal.

### 8.5 D_habitacao — indicador `adensamento_habitacional`

Derivar no Python (não modificar Flutter):

```text
adensamento_habitacional = numero_pessoas / numero_dormitorios
```

| Adensamento | Escore |
| ----------- | ------ |
| ≤ 2 moradores/dormitório | 0.00 |
| > 2 e ≤ 3 | 0.50 |
| > 3 | 1.00 |

`D_habitacao = score(adensamento_habitacional)`.

- A divisão usa moradores por dormitório/cômodo usado para dormir.
- A escala é uma **operacionalização experimental**; **não** representa percentual
  de inadequação habitacional.

**Não pontuar no IV-DSS principal:** `tipo_moradia`, `material_moradia`,
`numero_comodos`, `itens_residencia` (como conjunto completo),
`seguranca_residencia`, `melhorias_desejadas`, `facil_acesso_saude`.

**Exceção:** `itens_residencia.agua_encanada` é aproveitado no componente Água de
Saneamento (§8.3.1).

**Sensibilidade:** testar também o critério binário `>3 → 1; ≤3 → 0`.

### 8.6 D_alimentacao — indicador `deixou_de_comer_falta_dinheiro`

| Valor | Escore |
| ----- | ------ |
| `false` | 0 |
| `true` | 1 |
| `null` | missing |

`D_alimentacao = score(deixou_de_comer_falta_dinheiro)`.

Descrição recomendada: *"indicador de experiência autorrelatada de privação
alimentar associada à insuficiência de recursos financeiros nos três meses
anteriores."*

**Não** afirmar que essa única pergunta constitui aplicação da EBIA ou da FIES,
nem que permite classificar insegurança alimentar leve/moderada/grave.

**Fora do IV-DSS principal:** `refeicoes_por_dia`, `alimentos_consumidos`,
`fonte_alimentos`, `mudanca_alimentacao_gestacao`, `usa_suplementos`,
`avaliacao_alimentacao`. Algumas continuam no ML principal.

---

## 9. Política de missing do IV-DSS

Regras:

- `missing ≠ 0`, `missing ≠ 0.5`, `missing ≠ vulnerabilidade intermediária`.
- **Não** realizar imputação automática no IV-DSS principal.

Distinguir três situações:

1. **resposta realmente ausente;**
2. **não aplicável estrutural** (condicional do schema);
3. **categoria válida mas analiticamente indeterminada.**

Exemplo: `fonte_agua = cisterna` é resposta válida no dataset, mas produz
`score_fonte_agua = missing analítico`. **Nunca** apagar a resposta original.

**Cobertura mínima por dimensão:**

| Dimensão | Cobertura |
| -------- | --------- |
| Educação | 1/1 indicador |
| Trabalho/Renda | 1/1 indicador |
| Saneamento | ≥ 2/3 componentes principais |
| Acesso | 2/2 componentes |
| Habitação | 1/1 indicador |
| Alimentação | 1/1 indicador |

**IV-DSS principal exige 6/6 dimensões válidas.** Se uma dimensão estiver
ausente, `IV_DSS principal = não calculável` — **não** calcular silenciosamente a
média das outras cinco como se fosse o mesmo índice.

Futuramente (auxiliar/sensibilidade): `iv_dss_parcial` com
`coverage_dimensions = 5/6`, **somente** como resultado auxiliar.

> A ausência do IV-DSS **não** impede necessariamente o ML de gerar previsão. O
> tratamento de missing do ML será definido separadamente.

---

## 10. Análises de sensibilidade do IV-DSS

O índice principal usa **média aritmética**. **Não** usar média geométrica como
primeira alternativa (dimensões podem assumir 0). Planejar pelo menos:

1. normalização alternativa da `escolaridade`;
2. adensamento em 3 níveis **vs.** critério binário `>3`;
3. pequenas perturbações nos pesos das seis dimensões;
4. possível componente ocupacional alternativo;
5. agregação aritmética principal **vs.** média generalizada com `p = 2` (ou outra
   agregação menos compensatória justificável).

O objetivo é testar **robustez** — **não** escolher posteriormente a versão que
produza "melhor resultado".

---

## 11. Geração do dataset sintético — objetivo

O dataset sintético **não** tem como objetivo estimar prevalência real, descrever
a população brasileira de gestantes, reproduzir efeitos epidemiológicos
verdadeiros ou validar clinicamente o modelo.

**Objetivo:** validação técnica/experimental do pipeline.

> *"Os dados sintéticos são utilizados para avaliar o funcionamento técnico do
> pipeline de preprocessing, treinamento, comparação de modelos e inferência em
> um cenário controlado. As relações introduzidas pelo simulador não constituem
> evidência epidemiológica."*

**Planejamento principal:** `N ≈ 5.000` registros; seed fixa `42`; **proporção
sintética planejada** de Y positivo ≈ 25% (não chamar de "prevalência").

**Cenários futuros de sensibilidade (ex.):** ~15%, ~25%, ~35%.

---

## 12. Geração de Q_full (48 variáveis) — fatores latentes

As 48 variáveis **não** são sorteadas independentemente. Usam-se **cinco fatores
latentes internos ao simulador**:

| Fator | Significado experimental |
| ----- | ------------------------ |
| `Z_SES` | desvantagem socioeconômica sintética |
| `Z_LAB` | precariedade/limitações laborais sintéticas |
| `Z_TERR` | dificuldade territorial/geográfica sintética |
| `Z_INFRA` | precariedade habitacional/infraestrutura sintética |
| `Z_SERV` | dificuldades organizacionais/disponibilidade de serviços sintéticas |

Esses fatores **não** pertencem ao schema, **não** vão para o Flutter, **não** vão
para a API em produção, **não** são features do ML, **não** compõem diretamente o
IV-DSS e **não** aparecem ao usuário. Existem **exclusivamente** dentro do
simulador.

Geração: distribuição normal multivariada aproximadamente padrão com correlações
moderadas. Matriz inicial conceitual:

| | SES | LAB | TERR | INFRA | SERV |
| --- | --- | --- | --- | --- | --- |
| **SES** | 1 | .45 | .25 | .45 | .10 |
| **LAB** | .45 | 1 | .20 | .25 | .10 |
| **TERR** | .25 | .20 | 1 | .20 | .25 |
| **INFRA** | .45 | .25 | .20 | 1 | .10 |
| **SERV** | .10 | .10 | .25 | .10 | 1 |

> Esses números são **PARÂMETROS EXPERIMENTAIS**, não correlações reais
> observadas.

---

## 13. Camadas de geração de Q_full

Arquitetura do gerador:

- **CAMADA 0** — fatores latentes `Z_*`.
- **CAMADA 1** — variáveis estruturais/base.
- **CAMADA 2** — variáveis dependentes e condicionais.
- **CAMADA 3** — multiselects e variáveis descritivas.
- **CAMADA 4** — validação das invariantes do schema 1.13.
- **CAMADA 5** — derivação dos fatores internos `g_*` do DGM de Y.
- **CAMADA 6** — geração de Y.
- **CAMADA 7** — cálculo independente do IV-DSS.

Regras centrais:

- Y **nunca** gera X.
- IV-DSS **nunca** gera Y.
- `Z_*` **nunca** são fornecidos ao modelo.

---

## 14. Dependências entre as variáveis de Q_full

Não criar relações determinísticas; usar dependências probabilísticas.

**Educação:** `escolaridade` ← principalmente `Z_SES` + ruído. Demais variáveis
educacionais podem depender probabilisticamente de `escolaridade`, `Z_SES` e
contexto.

**Trabalho/Renda:** criar internamente uma condição/categoria econômica
**verdadeira sintética**; depois gerar o campo observado `faixa_renda`. Em
pequena parcela dos registros, `faixa_renda = nao_informar`. O gerador conhece a
condição econômica **antes** da ocultação; o modelo recebe somente
`nao_informar`. Isso testa informação não observada de forma controlada.

- `empregado` ← probabilisticamente de `Z_SES`, `Z_LAB` e ruído.
- Se `empregado == true` → gerar `tipo_emprego`, `trabalho_permite_pre_natal`,
  `ambiente_trabalho_seguro`, `tem_pausas_descanso`, `beneficios_trabalho`.
- Se `empregado == false` → campos não aplicáveis permanecem `null` (conforme
  schema) e gerar `motivo_desemprego`.

Distinguir `null` estrutural de missing real.

**Saneamento:** principalmente `Z_INFRA` + menor influência de `Z_TERR`.
Respeitar: `frequencia_coleta_lixo = regular` → `destino_lixo_sem_coleta = null`;
`irregular` → destino obrigatório e pode incluir `aguarda_proxima_coleta`;
`nao_possui` → destino obrigatório e `aguarda_proxima_coleta` proibido.

**Saúde/Acesso:** `distancia_ubs` ← principalmente `Z_TERR`. `acesso_ubs` ←
distância + condição socioeconômica + `Z_TERR` + ruído. Dificuldades:
`falta_transporte` ← território + distância + condição econômica;
`dificuldade_agendamento`/`demora_atendimento`/`falta_profissional`/`falta_exames`
← principalmente `Z_SERV`; `horario_incompativel` ← `Z_SERV` + situação laboral.

**Habitação:** `Z_SES` + `Z_INFRA` + ruído. Garantir `numero_pessoas ≥ 1`,
`numero_comodos ≥ 1`, `numero_dormitorios ≥ 1`,
`numero_dormitorios ≤ numero_comodos`. **Não** sortear adensamento diretamente;
derivar `numero_pessoas / numero_dormitorios`.

**Alimentação:** `deixou_de_comer_falta_dinheiro` ← principalmente `Z_SES` +
renda latente + `numero_pessoas` + ruído. **Não** tornar renda baixa
determinística de privação alimentar. Outras respostas alimentares podem ter
correlação probabilística.

---

## 15. Multiselects

Não sortear uma lista pronta arbitrariamente. Gerar as **probabilidades das
opções individualmente** e depois aplicar as regras de exclusividade. Vale para:
`dificuldades_educacao`, `beneficios_trabalho`, `cuidados_vetores`,
`servicos_pre_natal`, `dificuldades_saude`, `itens_residencia`,
`melhorias_desejadas`, `alimentos_consumidos`, `fonte_alimentos`.

Regras de exclusividade:

- `sem_dificuldades` não coexiste com dificuldades.
- `sem_beneficios` não coexiste com benefícios.
- `nenhum_dos_listados` não coexiste com itens positivos.
- `sem_melhorias` não coexiste com melhorias.

---

## 16. Campos de leakage no dataset sintético

Gerar também `faltou_consulta`, `servicos_pre_natal`,
`exames_pre_natal_completos`, `vacinas_em_dia`, `avaliacao_pre_natal` (fazem parte
do formulário).

- Y **não** pode ser usado para gerar diretamente nenhum deles.
- **Proibido:** `Y = 1 → faltou_consulta = true`.
- Eles podem depender probabilisticamente de antecedentes como `Z_TERR`,
  `Z_SERV`, barreiras de acesso, condições laborais e ruído — podendo ficar
  correlacionados com Y por **causas comuns** no simulador, mas **não** por
  construção direta a partir do target.
- Mesmo assim permanecem **excluídos** do modelo principal por decisão
  metodológica.

---

## 17. Nulls no dataset principal

O dataset sintético principal representa **questionários concluídos**. **Não**
inserir `null` aleatório em campos obrigatórios apenas para criar missing.

`null` deve surgir principalmente por:

- não aplicabilidade estrutural;
- campos realmente opcionais;
- regras condicionais do schema.

Exemplos:

- `empregado = false` → `tipo_emprego = null`, `beneficios_trabalho = null`.
- coleta `regular` → `destino_lixo_sem_coleta = null`.
- `nao_informar` em renda é **resposta válida**, não `null`.

Missing inesperado poderá ser avaliado em cenário de sensibilidade posterior.

---

## 18. DGM do target sintético

O Y sintético **não** é produzido pelo IV-DSS, **não** pela contagem artificial
de consultas e **não** pela aplicação da regra de sete consultas no cenário
principal. Usam-se **8 fatores internos** do mecanismo gerador.

### 18.1 Fatores `g_*`

- `g_escolaridade`: `superior_completo` → 0 · `superior_incompleto` → ~0.17 ·
  `medio_completo` → ~0.33 · `medio_incompleto` → 0.50 · `fundamental_completo` →
  ~0.67 · `fundamental_incompleto` → ~0.83 · `sem_instrucao` → 1.
- `g_renda`: `mais_3_sm` → 0 · `entre_2_3_sm` → ~0.33 · `entre_1_2_sm` → ~0.67 ·
  `ate_1_sm` → 1. Quando o campo observado for `nao_informar`, o simulador usa a
  categoria econômica verdadeira sintética antes da ocultação (o modelo **não**
  tem acesso).
- `g_distancia`: `muito_proxima` → 0 · `razoavelmente_proxima` → 0.5 · `distante`
  → 1.
- `g_transporte`: marcou `falta_transporte` → 1 · não marcou → 0.
- `g_organizacao`: 1 se houver ao menos uma de `dificuldade_agendamento`,
  `demora_atendimento`, `horario_incompativel`; 0 caso contrário (não somar as
  três como efeito triplo).
- `g_trabalho`: 1 quando `empregado == true` **e** `trabalho_permite_pre_natal ==
  false`; 0 caso contrário. **Não** atribuir automaticamente risco laboral a
  desempregada.
- `g_privacao_alimentar`: `deixou_de_comer_falta_dinheiro == true` → 1 · `false` →
  0. Fator experimental; **não** apresentar como efeito epidemiológico comprovado.
- `g_adensamento`: `numero_pessoas / numero_dormitorios` — `≤2` → 0 · `>2 ≤3` →
  0.5 · `>3` → 1. Fator experimental.

### 18.2 Interações

Somente duas no cenário principal:

- `I1 = g_renda * g_privacao_alimentar` — hipótese experimental de combinação
  entre desvantagem econômica e privação alimentar.
- `I2 = g_distancia * g_transporte` — hipótese experimental de combinação entre
  distância e dificuldade de transporte.

**Não** apresentar os efeitos como relações epidemiológicas quantitativamente
comprovadas.

### 18.3 Equação do DGM

```text
eta = alpha
      + 0.50 * E
      + 0.55 * R
      + 0.45 * D
      + 0.55 * T
      + 0.40 * O
      + 0.40 * W
      + 0.30 * F
      + 0.25 * H
      + 0.30 * (R*F)
      + 0.35 * (D*T)
      + U
```

onde: `E = g_escolaridade`, `R = g_renda`, `D = g_distancia`,
`T = g_transporte`, `O = g_organizacao`, `W = g_trabalho`,
`F = g_privacao_alimentar`, `H = g_adensamento`, e `U ~ Normal(0, 0.50)`.

Depois: `p = sigmoid(eta)` e `Y ~ Bernoulli(p)`.

> Os coeficientes são **PARÂMETROS DE SIMULAÇÃO**, não _odds ratios_ da
> literatura. **Não** interpretar "0.55 = 55% de aumento do risco" — incorreto.
> Poderão ser refinados durante a implementação caso produzam problema trivial ou
> excessivamente difícil, com alteração **versionada e registrada** como ajuste do
> cenário experimental.

### 18.4 Calibração do intercepto

Não escolher `alpha` manualmente por tentativa. Após gerar `Q_full`, calibrar
`alpha` numericamente de modo que a **média das probabilidades verdadeiras ≈
proporção sintética planejada** (~25% no cenário principal). Depois,
`Y_i ~ Bernoulli(p_i)`.
A proporção observada de Y pode variar ligeiramente devido ao sorteio.

---

## 19. Dados internos do simulador — separação

O modelo **não** recebe:

`Z_SES`, `Z_LAB`, `Z_TERR`, `Z_INFRA`, `Z_SERV`, condição/renda latente
verdadeira, `g_escolaridade`, `g_renda`, `g_distancia`, `g_transporte`,
`g_organizacao`, `g_trabalho`, `g_privacao_alimentar`, `g_adensamento`, `eta`,
`p_true`.

O modelo recebe **`X_model`** (as 34 features legítimas) provenientes do
questionário.

Metadados (`eta`, `p_true`, `Z_*`, `g_*`) poderão ser salvos em **arquivo
separado**, exclusivamente para auditoria da simulação. **Nunca** incluir esse
arquivo como entrada de treinamento.

---

## 20. Modelos

| Modelo | Papel |
| ------ | ----- |
| **Regressão Logística** | baseline interpretável |
| **Random Forest** | não-linear; _feature importance_ |
| **XGBoost** | candidato forte (se o ambiente permitir) |

- Rede Neural: **opcional**, com justificativa experimental posterior.
- K-means: **no máximo** análise exploratória; **não** é núcleo do pipeline
  preditivo.

---

## 21. Preprocessing (planejamento)

> **Escopo:** esta seção trata do preprocessing de **ML** (preparação de
> `X_model` para os classificadores). O **IV-DSS** é um cálculo analítico
> independente a partir de `Q_full` e **não** faz parte do
> `ColumnTransformer`/`Pipeline` do modelo principal.

- categóricas nominais → **one-hot**;
- multiselects → **multi-hot**;
- ordinais → **definir tratamento explicitamente** (não transformar nominal em
  ordinal só porque possui códigos `String`);
- booleanos → codificação apropriada **no pipeline Python** (Flutter continua
  enviando `true/false/null`; **não** converter para 0/1 no contrato Flutter);
- contagens numéricas permanecem numéricas;
- features derivadas poderão ser calculadas no Python;
- qualquer **oversampling** ocorre **somente após** a separação treino/teste e
  **exclusivamente** no conjunto de treinamento;
- priorizar inicialmente `class_weight` quando disponível.

---

## 22. Avaliação (planejamento)

Métricas: **Recall**, **Precision**, **F1-score**, **ROC-AUC**, **PR-AUC**.
Accuracy pode aparecer, mas **não** como principal critério. Recall recebe
atenção especial (identificar o maior número possível de casos positivos
experimentais), sempre analisando o trade-off com Precision.

Incluir também: matriz de confusão; comparação entre modelos; distribuição das
probabilidades; avaliação de calibração quando aplicável.

- Divisão treino/teste com **seed fixa** (estratificada).
- Validação cruzada **somente** sobre os dados de treinamento quando usada para
  ajuste/comparação.
- **Evitar** qualquer preprocessing aprendido usando o conjunto de teste; usar
  `Pipeline`/`ColumnTransformer` (ou equivalente) para prevenir leakage de
  preprocessing.

---

## 23. Arquivos previstos e reprodutibilidade

**Arquivos previstos (planejamento):**

- dataset canônico observado (`Q_full` + Y), a partir do qual `X_model` é
  selecionado para treinamento;
- arquivo **separado** de metadados internos do simulador (auditoria: `Z_*`,
  `g_*`, `eta`, `p_true`), **nunca** usado como entrada de treinamento;
- IV-DSS (calculado de forma independente, pós-geração).

**Reprodutibilidade** — registrar e versionar:

- **seed** fixa (`42`);
- **versão do gerador**;
- **versão do schema DSS** (`schema_version = 1.13`);
- **parâmetros da geração** (fatores `Z_*`, matriz, coeficientes do DGM, nível de
  ruído);
- **proporção sintética planejada** (~25%) e cenários de sensibilidade
  (~15%/~25%/~35%);
- **quantidade de registros** (`N ≈ 5.000`).

Qualquer mudança em um desses itens **invalida** a comparação direta e deve gerar
uma **nova versão** do dataset.

---

## 24. Avisos metodológicos invariáveis

> O resultado produzido pelo modelo será uma estimativa estatística de risco e
> não deverá ser tratado como diagnóstico médico ou como certeza de abandono.

> Os dados sintéticos possuem finalidade experimental e de validação técnica,
> não representando prevalências, associações clínicas ou características reais
> da população de gestantes.

> **Dado sintético não representa dados clínicos reais e não deve ser
> interpretado como evidência de prevalência ou desempenho clínico real.**
