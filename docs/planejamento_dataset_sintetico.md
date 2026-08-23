# Planejamento do Dataset Sintético — DSS Pré-natal

> **Documento de planejamento metodológico.**
> Este documento **não** gera, treina nem implementa nada: é a especificação que
> antecede a etapa de geração do dataset sintético e do modelo de ML.
>
> ⚠️ **Dado sintético não representa dados clínicos reais e não deve ser
> interpretado como evidência de prevalência ou desempenho clínico real.**
>
> **Fonte de verdade do contrato de dados:** o código Flutter
> (`lib/app/modules/formulario/`). O schema DSS foi versionado durante a
> estabilização do instrumento; **`schema_version = 1.13`** é o contrato
> consolidado utilizado nas próximas etapas (dataset sintético, pré-processamento
> e modelo).

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

### 2.1 Educação (6)

| Chave JSON                         | Tipo | Categorias (códigos)                                                                                          | Nullable / condicional | Observação |
| ---------------------------------- | ---- | ------------------------------------------------------------------------------------------------------------- | ---------------------- | ---------- |
| `estuda_atualmente`                | B    | —                                                                                                             | obrigatório            | —          |
| `escolaridade`                     | C    | `sem_instrucao`, `fundamental_incompleto`, `fundamental_completo`, `medio_incompleto`, `medio_completo`, `superior_incompleto`, `superior_completo` | obrigatório            | ordinal     |
| `situacao_estudos_gestacao`        | C    | `nao_estudava`, `nao_interrompeu`, `interrompeu`                                                              | obrigatório            | pendente (§7) |
| `dificuldades_educacao`            | L    | `falta_dinheiro`, `distancia`, `falta_transporte`, `falta_vagas`, `gravidez`, `trabalho`, `cuidado_filhos`, `sem_dificuldades`, `outro` | obrigatório (não vazia); `sem_dificuldades` exclusivo | — |
| `entende_orientacoes_saude`        | B    | —                                                                                                             | obrigatório            | —          |
| `fez_curso_qualificacao_profissional` | B | —                                                                                                             | obrigatório            | —          |

### 2.2 Trabalho e Renda (10)

| Chave JSON                    | Tipo | Categorias (códigos)                                                                              | Nullable / condicional | Observação |
| ----------------------------- | ---- | ------------------------------------------------------------------------------------------------- | ---------------------- | ---------- |
| `empregado`                   | B    | —                                                                                                 | obrigatório            | controla os blocos de emprego/desemprego (§3) |
| `tipo_emprego`                | C    | `clt`, `autonomo`, `informal`                                                                     | condicional (`empregado == true`) | — |
| `faixa_renda`                 | C    | `ate_1_sm`, `entre_1_2_sm`, `entre_2_3_sm`, `mais_3_sm`, `nao_informar`                          | obrigatório; independente de `empregado` | renda familiar mensal |
| `trabalho_permite_pre_natal`  | B    | —                                                                                                 | condicional (`empregado == true`) | — |
| `ambiente_trabalho_seguro`    | B    | —                                                                                                 | condicional (`empregado == true`) | — |
| `tem_pausas_descanso`         | B    | —                                                                                                 | condicional (`empregado == true`) | — |
| `beneficios_trabalho`         | L    | `auxilio_maternidade`, `vale_transporte`, `vale_alimentacao`, `sem_beneficios`                    | condicional: obrigatório não vazio se `empregado == true`; `null` se `empregado == false`/não respondido; `sem_beneficios` exclusivo | `List<String>?` |
| `motivo_desemprego`           | C    | `dificuldade_encontrar_vaga`, `problemas_saude`, `cuidado_casa_filhos`, `gestacao`, `opcao_propria`, `outro` | condicional (`empregado == false`) | — |
| `recebe_beneficio_social`     | B    | —                                                                                                 | independente de `empregado` | — |
| `impacto_gestacao_trabalho`   | C    | `nao_afetou`, `reduziu_jornada`, `afastamento_temporario`, `demitida`, `pediu_demissao`, `outro`  | independente de `empregado` | pendente (§7) |

### 2.3 Saneamento (7)

| Chave JSON                 | Tipo | Categorias (códigos)                                                                                           | Nullable / condicional | Observação |
| -------------------------- | ---- | -------------------------------------------------------------------------------------------------------------- | ---------------------- | ---------- |
| `fonte_agua`               | C    | `rede_publica`, `poco_nascente`, `cisterna`, `carro_pipa`, `outra`                                             | obrigatório            | — |
| `interrupcoes_agua`        | B    | —                                                                                                              | obrigatório            | — |
| `esgotamento_sanitario`    | C    | `rede_coletora`, `ceu_aberto`, `fossa_septica`, `outro`                                                        | obrigatório            | — |
| `frequencia_coleta_lixo`   | C    | `regular`, `irregular`, `nao_possui`                                                                           | obrigatório            | controla `destino_lixo_sem_coleta` (§3) |
| `destino_lixo_sem_coleta`  | C    | `aguarda_proxima_coleta`, `queima`, `enterra`, `terreno_baldio`, `outro`                                       | condicional: `null` se `regular`; obrigatório se `irregular`/`nao_possui` | — |
| `problema_saude_agua`      | B    | —                                                                                                              | obrigatório            | — |
| `cuidados_vetores`         | L    | `elimina_agua_parada`, `mantem_reservatorios_tampados`, `usa_repelente`, `usa_mosquiteiro_telas`, `mantem_ambiente_limpo`, `usa_inseticida`, `sem_cuidados`, `outro` | obrigatório (não vazia); `sem_cuidados` exclusivo | — |

### 2.4 Saúde (9)

| Chave JSON                   | Tipo | Categorias (códigos)                                                                                     | Nullable / condicional | Observação |
| ---------------------------- | ---- | -------------------------------------------------------------------------------------------------------- | ---------------------- | ---------- |
| `distancia_ubs`              | C    | `muito_proxima`, `razoavelmente_proxima`, `distante`                                                     | obrigatório            | ordinal     |
| `faltou_consulta`            | B    | —                                                                                                        | descritivo (`null` permitido) | **leakage** (§6) |
| `acesso_ubs`                 | C    | `a_pe`, `transporte_publico`, `carro_moto`, `outro`                                                      | obrigatório            | — |
| `cadastrada_ubs`             | B    | —                                                                                                        | descritivo (`null` permitido) | independente de `acesso_ubs` |
| `servicos_pre_natal`         | L    | `consulta_medica`, `consulta_enfermagem`, `grupo_gestantes`, `nenhum_dos_listados`                       | obrigatório (não vazia); `nenhum_dos_listados` exclusivo | **leakage** (§6) |
| `exames_pre_natal_completos` | B    | —                                                                                                        | descritivo (`null` permitido) | **leakage** (§6) |
| `vacinas_em_dia`             | B    | —                                                                                                        | descritivo (`null` permitido) | **leakage** (§6) |
| `avaliacao_pre_natal`        | C    | `excelente`, `bom`, `regular`, `ruim`, `pessimo`                                                         | obrigatório            | **leakage** (§6) |
| `dificuldades_saude`         | L    | `dificuldade_agendamento`, `demora_atendimento`, `distancia`, `falta_transporte`, `horario_incompativel`, `falta_profissional`, `falta_exames`, `sem_dificuldades`, `outro` | obrigatório (não vazia); `sem_dificuldades` exclusivo | — |

### 2.5 Habitação (9)

| Chave JSON              | Tipo | Categorias (códigos)                                                                                                   | Nullable / condicional | Observação |
| ----------------------- | ---- | ---------------------------------------------------------------------------------------------------------------------- | ---------------------- | ---------- |
| `tipo_moradia`          | C    | `casa`, `apartamento`, `comodo_unico`, `outro`                                                                         | obrigatório            | — |
| `material_moradia`      | C    | `alvenaria`, `madeira`, `mista`, `outro`                                                                               | obrigatório            | — |
| `numero_pessoas`        | N    | —                                                                                                                      | obrigatório (`> 0`)    | futuro indicador de adensamento |
| `numero_comodos`        | N    | —                                                                                                                      | obrigatório (`> 0`)    | — |
| `numero_dormitorios`    | N    | —                                                                                                                      | obrigatório (`> 0`, `≤ numero_comodos`) | futuro indicador de adensamento |
| `itens_residencia`      | L    | `agua_encanada`, `banheiro_interno`, `cozinha_separada`, `nenhum_dos_listados`                                         | obrigatório (não vazia); `nenhum_dos_listados` exclusivo | — |
| `seguranca_residencia`  | C    | `muito_segura`, `segura`, `regular`, `insegura`, `muito_insegura`                                                      | obrigatório            | percepção subjetiva; ordinal |
| `melhorias_desejadas`   | L    | `ampliacao_espaco`, `reforma_estrutura`, `melhorar_banheiro`, `melhorar_ventilacao`, `melhorar_instalacao_eletrica`, `melhorar_abastecimento_agua`, `melhorar_seguranca`, `sem_melhorias`, `outro` | obrigatório (não vazia); `sem_melhorias` exclusivo | — |
| `facil_acesso_saude`    | B    | —                                                                                                                      | obrigatório            | — |

### 2.6 Alimentação (7)

| Chave JSON                          | Tipo | Categorias (códigos)                                                                 | Nullable / condicional | Observação |
| ----------------------------------- | ---- | ------------------------------------------------------------------------------------ | ---------------------- | ---------- |
| `refeicoes_por_dia`                 | C    | `uma_duas`, `tres`, `quatro_mais`                                                    | obrigatório            | ordinal |
| `deixou_de_comer_falta_dinheiro`    | B    | —                                                                                    | obrigatório            | privação alimentar por motivo financeiro (§5.1) |
| `alimentos_consumidos`              | L    | `frutas_verduras`, `carnes`, `leite_derivados`, `feijao_leguminosas`, `nenhum_dos_listados` | obrigatório (não vazia); `nenhum_dos_listados` exclusivo | — |
| `fonte_alimentos`                   | L    | `supermercado_feira`, `horta_propria`, `doacoes`, `cesta_basica`, `outro`            | obrigatório (não vazia) | — |
| `mudanca_alimentacao_gestacao`      | B    | —                                                                                    | obrigatório            | pendente (§7) |
| `usa_suplementos`                   | B    | —                                                                                    | obrigatório            | pendente (§7) |
| `avaliacao_alimentacao`             | C    | `muito_boa`, `boa`, `regular`, `ruim`                                                | obrigatório            | ordinal |

---

## 3. Condicionalidades

### 3.1 `empregado` (Trabalho e Renda)

- `empregado = null` → ainda não respondeu; nenhum bloco (emprego/desemprego) é
  exibido e os campos condicionais não são aplicáveis.
- `empregado = true` → campos relacionados à situação de emprego
  (`tipo_emprego`, `trabalho_permite_pre_natal`, `ambiente_trabalho_seguro`,
  `tem_pausas_descanso`, `beneficios_trabalho`).
- `empregado = false` → `motivo_desemprego`.

`faixa_renda`, `recebe_beneficio_social` e `impacto_gestacao_trabalho` são
**independentes** da condição `empregado`.

- `beneficios_trabalho`:
  - aplicável quando `empregado == true` (obrigatório e não vazio);
  - `sem_beneficios` é resposta explícita válida (exclusiva);
  - `null` quando `empregado == false` ou não respondido.

### 3.2 `frequencia_coleta_lixo` (Saneamento)

- `regular` → `destino_lixo_sem_coleta` **não aplicável** (`null`).
- `irregular` ou `nao_possui` → `destino_lixo_sem_coleta` **aplicável**
  (obrigatório).
- `aguarda_proxima_coleta` só é oferecida quando existe serviço de coleta
  (mesmo que irregular); para `nao_possui`, essa opção é removida.

> **Não** inventar condicionais além das documentadas acima.

---

## 4. Variável-alvo (externa ao formulário)

**Definição:** variável supervisionada **binária** `descontinuou_pre_natal`,
mantida **fora** do formulário e **fora** do `FormularioData` (é `y`, nunca
feature `x`).

| Valor | Significado operacional                                           |
| ----- | ----------------------------------------------------------------- |
| `0`   | realizou **6 ou mais consultas** de pré-natal                     |
| `1`   | realizou **menos de 6 consultas** (descontinuidade/insuficiência) |

Fonte do limiar "6 consultas": Ministério da Saúde, Caderno de Atenção Básica
nº 32, 2013.

> ⚠️ **A regra do "número mínimo de consultas" é uma PROXY operacional** para
> insuficiência/descontinuidade do acompanhamento, **não** uma definição clínica
> universal de "abandono". O questionário **sozinho não observa** o desfecho
> real; em estudo real o rótulo viria de acompanhamento
> longitudinal/prontuário/SISPRENATAL. **[VALIDAR NA LITERATURA]** — "6 consultas"
> vs. Kotelchuck (ajuste por idade gestacional).

---

## 5. Alimentação — esclarecimentos

### 5.1 `deixou_de_comer_falta_dinheiro` (bool?)

Semântica: "Nos últimos 3 meses, deixou de comer por falta de dinheiro?".

Trata-se de uma **manifestação específica de privação alimentar por motivo
financeiro**. **Não** deve ser apresentado como aplicação validada da EBIA nem
como medida completa de insegurança alimentar. Não existe a variável
`inseguranca_alimentar` no schema 1.13.

### 5.2 Demais campos

- `fonte_alimentos`: `List<String>` (códigos), obrigatória.
- `alimentos_consumidos`: `List<String>`, obrigatória, com `nenhum_dos_listados`.
- `mudanca_alimentacao_gestacao`: `bool?`.
- `usa_suplementos`: `bool?`.
- `avaliacao_alimentacao`: códigos `muito_boa`, `boa`, `regular`, `ruim`.

---

## 6. Data leakage — variáveis excluídas do modelo principal e do IV-DSS

Os cinco campos a seguir representam informação posterior ou diretamente
relacionada à adesão/desfecho (risco de leakage/proximidade com a trajetória de
acompanhamento pré-natal). Eles **continuam no questionário/JSON** para fins
descritivos ou de acompanhamento, mas **não** devem ser usados como features
preditoras principais:

| Campo                        | Motivo da exclusão                                                                                                      |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `faltou_consulta`            | Semântica muito próxima do alvo; pode ser **praticamente sinônimo** de descontinuidade → risco de vazamento/tautologia. |
| `exames_pre_natal_completos` | Se o desfecho é definido por consultas/exames não realizados, esta variável _é_ parte do alvo.                          |
| `vacinas_em_dia`             | Desfecho de adesão, pode ser pós-descontinuidade.                                                                       |
| `servicos_pre_natal`         | Proxy de participação/engajamento; correlato ao alvo.                                                                   |
| `avaliacao_pre_natal`        | Reflete experiência **após** engajamento; temporalmente posterior.                                                      |

Esses campos **não são removidos estruturalmente** da documentação do
formulário: são mantidos como _variáveis de adesão_ para análise descritiva.

**Regra de ouro:** nenhuma feature pode **ser** a variável-alvo nem ser derivada
dela. O IV-DSS é construído **exclusivamente** a partir de determinantes sociais
e condições de vulnerabilidade, nunca de informações do próprio
acompanhamento/adesão.

---

## 7. Variáveis temporais — decisões metodológicas pendentes

Registradas como pendentes, **sem** classificação definitiva de feature ou
exclusão nesta etapa (aguardam a etapa metodológica/literatura posterior):

- `usa_suplementos`
- `mudanca_alimentacao_gestacao`
- `situacao_estudos_gestacao`
- `impacto_gestacao_trabalho`

---

## 8. Índice de Vulnerabilidade dos DSS — IV-DSS

> Definição acadêmica e integração com o TCC: ver `docs/tcc2.md` (seções 2.3 e
> 4.3). Esta seção documenta os detalhes técnicos de planejamento.

### 8.1 Papel no experimento

O IV-DSS é uma **medida agregada de caracterização** da vulnerabilidade social,
**derivada** das variáveis DSS. Ele **não é** a variável-alvo e **não é** uma
feature do modelo de ML:

```text
          DSS
           │
           ├──→ IV-DSS        → análise descritiva / caracterização
           │
           └──→ Features individuais → ML → P(descontinuidade)
```

**IV-DSS ≠ probabilidade prevista pelo modelo.** O IV-DSS é um índice descritivo
de vulnerabilidade social; o modelo de ML estima `P(descontinuidade do
acompanhamento pré-natal | características)`. O IV-DSS **não** é usado
automaticamente como feature principal do modelo (seria redundante, pois é uma
função determinística das variáveis que o compõem).

### 8.2 Estrutura (proposta metodológica, sujeita à definição final)

- **Nível 1 — indicador → escore:** cada variável DSS é mapeada para um escore de
  vulnerabilidade `v_i ∈ [0,1]` (**0 = menor vulnerabilidade; 1 = maior**).
- **Nível 2 — dimensão:** `D_d` = média aritmética dos `v_i` **válidos** da
  dimensão `d`.
- **Nível 3 — índice:** média aritmética das seis dimensões, com **pesos iguais**
  (estrutura conceitual de seis dimensões com pesos iguais **apenas como
  proposta**, ainda sujeita à definição final dos indicadores).

```text
D_d     = (1 / |I_d|) · Σ_{i ∈ I_d} v_i

IV-DSS  = (1/6) · Σ_{d=1}^{6} D_d
```

Escala contínua `[0,1]`; sem faixas absolutas fundamentadas na literatura; para
apresentação, usar **quantis** (relativos à amostra). A **agregação geométrica**
`IV-DSS_geo = (Π D_d)^{1/6}` é **análise de sensibilidade**, não o índice
principal.

### 8.3 Decisões pendentes (não resolvidas nesta etapa)

- `recebe_beneficio_social`: direção do escore.
- `acesso_ubs`: inclusão ou não no índice.
- `faixa_renda = nao_informar`: imputar 0.5 vs. omitir.
- Redundâncias / distância / transporte.
- Água duplicada entre dimensões.
- `facil_acesso_saude`.
- Limiar de adensamento habitacional.
- `problema_saude_agua` e `cuidados_vetores`: **não** tratar automaticamente
  como indicadores estruturais do IV-DSS (decisão da etapa metodológica).
- Demais pesos/scores individuais (valores nominais finais).

---

## 9. Geração do dataset sintético

O dataset tem finalidade **experimental**, **técnica** e de **validação do
pipeline**. Ele **não** representa prevalências reais, associações clínicas
reais, características reais da população de gestantes, nem validação clínica do
modelo.

O dataset será **probabilístico controlado** (não determinístico):

- **~5.000 registros**, **seed fixa/reprodutível** (ex.: `seed = 42`), gerador
  versionado e parâmetros documentados.
- **Target externo ao questionário**: a variável-alvo é gerada
  **condicionalmente** a um _score de risco latente_ derivado de uma combinação
  ponderada das features (regressão logística sintética + ruído), **não** por
  regra "se X então y=1".
- **Separação entre geração de X e cálculo posterior do IV-DSS**: o IV-DSS é
  derivado de X **depois**, e **não** participa da geração de Y.

```text
Geração dos DSS (X)
      │
      ├──→ cálculo do IV-DSS        (variável derivada de X — seção 8)
      │
      └──→ escore latente de risco → probabilidade → Y = descontinuou_pre_natal
```

- **X** = variáveis dos DSS (tabulares, sem leakage);
- **IV-DSS** = variável **derivada** de X (função determinística);
- **Y** = descontinuidade do pré-natal (target externo).

**O IV-DSS não participa da geração de Y.** O escore latente de Y usa um
subconjunto **cru** de X, nunca o índice — isso evita tornar o índice a "causa"
artificial do rótulo e preserva a associação IV-DSS↔Y como resultado empírico,
não como premissa.

Configurações mantidas como planejamento: **~5.000 registros**, **prevalência
~25%** de Y=1 (faixa experimental 20–30%). **Não** gerar os dados nesta etapa.

---

## 10. Pré-processamento futuro (feature engineering)

Mapeamento do schema 1.13 para o futuro dataset tabular (nenhum pipeline de
encoding é implementado nesta etapa). **Não há campos de texto livre** no schema
1.13 — todos os campos são booleanos, categóricos (códigos), múltipla escolha
(códigos) ou numéricos.

| Grupo                      | Campos (chaves atuais)                                                                                                                                                                                                                                                                                    | Transformação futura                                                                                           |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Booleanas**              | `estuda_atualmente`, `entende_orientacoes_saude`, `fez_curso_qualificacao_profissional`, `empregado`, `trabalho_permite_pre_natal`, `ambiente_trabalho_seguro`, `tem_pausas_descanso`, `recebe_beneficio_social`, `interrupcoes_agua`, `problema_saude_agua`, `cadastrada_ubs`, `facil_acesso_saude`, `deixou_de_comer_falta_dinheiro`, `mudanca_alimentacao_gestacao`, `usa_suplementos` | `0/1` (bool → int) no Python; `null` tratado no pré-processamento (missing indicator / imputação) |
| **Categóricas (nominais)** | `tipo_emprego`, `motivo_desemprego`, `impacto_gestacao_trabalho`, `fonte_agua`, `esgotamento_sanitario`, `frequencia_coleta_lixo`, `destino_lixo_sem_coleta`, `acesso_ubs`, `tipo_moradia`, `material_moradia`                                                                                            | one-hot encoding                                                                                               |
| **Ordinais**               | `escolaridade`, `faixa_renda`, `situacao_estudos_gestacao`, `distancia_ubs`, `seguranca_residencia`, `refeicoes_por_dia`, `avaliacao_alimentacao` (e `avaliacao_pre_natal`, leakage)                                                                                                                     | **avaliar** label/ordinal encoding — só se a ordem for metodologicamente justificável; caso contrário, one-hot |
| **Numéricas**              | `numero_pessoas`, `numero_comodos`, `numero_dormitorios`                                                                                                                                                                                                                                                  | valor numérico (normalizar/escalar no pré-processamento)                                                       |
| **Múltipla escolha**       | `dificuldades_educacao`, `beneficios_trabalho`, `cuidados_vetores`, `servicos_pre_natal`, `dificuldades_saude`, `itens_residencia`, `melhorias_desejadas`, `alimentos_consumidos`, `fonte_alimentos`                                                                                                      | multi-hot (uma coluna binária por código canônico)                                                             |

> Nota metodológica: `numero_pessoas` + `numero_dormitorios` poderão originar,
> no Python, um indicador de **adensamento habitacional**. **Não** definir ainda
> limiar arbitrário.

---

## 11. Modelos (planejamento)

Candidatos a modelo (comparação justificada; **não executar nenhum nesta etapa**):

| Modelo                  | Papel                  | Justificativa                                                          |
| ----------------------- | ---------------------- | ---------------------------------------------------------------------- |
| **Regressão Logística** | baseline interpretável | calibração e coeficientes legíveis (importante para DSS)               |
| **Random Forest**       | não-linear, robusta    | lida com interações; fornece _feature importance_                      |
| **XGBoost**             | forte candidato        | se o ambiente permitir a dependência; SOTA tabular                     |
| **Rede Neural**         | opcional               | apenas com justificativa experimental (dados suficientes)              |

**K-means** fica **no máximo exploratório**, não é componente obrigatório do
pipeline preditivo.

---

## 12. Métricas (planejamento)

Planejadas: **Recall**, **Precision**, **F1-score**, **ROC-AUC**, **PR-AUC**.

**Accuracy** pode ser relatada, mas **não** deve ser a única métrica. Destaca-se
o **Recall** pela importância de reduzir falsos negativos (gestante em risco não
detectada) no contexto experimental. **Não** inventar valores de desempenho.

---

## 13. Arquitetura futura (planejada, ainda não implementada)

```text
Flutter → API FastAPI → preprocessing → modelo treinado → probabilidade → resposta da API → Flutter
```

A API e o pipeline Python serão **projetos/componentes separados** do aplicativo
Flutter. A resposta futura da API deve possuir, no mínimo, conceitos equivalentes
a:

- `schema_version`
- `model_version`
- `probability`

> A API **ainda não existe**; este é o planejamento.

---

## 14. Reproducibilidade

O gerador futuro deve registrar, e o dataset deve permitir "rodar de novo com os
mesmos parâmetros e obter o mesmo resultado":

- **seed** (fixa, ex.: `42`);
- **versão do gerador**;
- **versão do schema DSS** (`schema_version = 1.13`);
- **parâmetros da geração** (pesos do score latente, nível de ruído);
- **distribuição das classes** (ex.: ~25% positivos);
- **quantidade de registros** (ex.: 5.000).

Qualquer mudança em qualquer um desses itens **invalida** a comparação direta e
deve gerar uma **nova versão** do dataset.

---

## 15. Avisos metodológicos invariáveis

> O resultado produzido pelo modelo será uma estimativa estatística de risco e
> não deverá ser tratado como diagnóstico médico ou como certeza de abandono.

> Os dados sintéticos possuem finalidade experimental e de validação técnica,
> não representando prevalências, associações clínicas ou características reais
> da população de gestantes.

> **Dado sintético não representa dados clínicos reais e não deve ser
> interpretado como evidência de prevalência ou desempenho clínico real.**
