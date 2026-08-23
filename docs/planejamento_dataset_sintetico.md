# Planejamento do Dataset Sintético — DSS Pré-natal

> **Documento de planejamento metodológico (Solicitação 03).**
> Este documento **não** gera, treina nem implementa nada: é a especificação que
> antecede a etapa de geração do dataset sintético e do modelo de ML.

> ⚠️ **Dado sintético não representa dados clínicos reais e não deve ser
> interpretado como evidência de prevalência ou desempenho clínico real.**

---

## 1. Campos de texto livre (Parte 1)

Os **5 campos qualitativos** do formulário permanecem `String?`, são coletados e
preservados no JSON canônico **sem** conversão automática em categoria, **sem**
NLP e **sem** alteração da pergunta na UI. Nenhum deles entra no modelo tabular
inicial.

| Campo                       | Key no JSON                          | Tipo      | Tratamento                                                                               |
| --------------------------- | ------------------------------------ | --------- | ---------------------------------------------------------------------------------------- |
| `motivo_desemprego`         | `trabalho.motivo_desemprego`         | `String?` | Qualitativo. **Pode futuramente ser categorizado.** Não entra no modelo tabular inicial. |
| `impacto_gestacao_trabalho` | `trabalho.impacto_gestacao_trabalho` | `String?` | Relato qualitativo. Não entra no modelo tabular inicial.                                 |
| `cuidados_vetores`          | `saneamento.cuidados_vetores`        | `String?` | Relato qualitativo. Não entra no modelo tabular inicial.                                 |
| `dificuldades_saude`        | `saude.dificuldades_saude`           | `String?` | Relato qualitativo. Não entra no modelo tabular inicial.                                 |
| `melhorias_desejadas`       | `habitacao.melhorias_desejadas`      | `String?` | Relato qualitativo. Não entra no modelo tabular inicial.                                 |

Simetria garantida por toda a cadeia (verificada nesta etapa):

```
UI (TextFormField)
 → Controller (String?, trim + null em vazio)
 → Model (String?)
 → FormularioData.toMap()   (String? → chave canônica)
 → FormularioData.fromMap() (String? ← chave canônica)
```

Cobertura de teste: `test/formulario/models/texto_livre_test.dart`.

---

## 2. Separação entre dados coletados, features e dados qualitativos (Parte 2)

Três conceitos distintos, para que o contrato DSS v1.0 não precise ser quebrado
quando o modelo evoluir:

- **A) Dados coletados** — tudo o que o `FormularioData` serializa: as 6
  dimensões, incluindo os 5 campos de texto livre. É o "fato" registrado.

- **B) Features do modelo** — o subconjunto **tabular** dos dados coletados que
  entra no modelo inicial (bool/int/categorias/multi). Definido na seção 7.

- **C) Dados qualitativos** — os 5 campos de texto livre, preservados para
  análise futura, documentação ou possível NLP. **Não são descartados**; apenas
  ficam fora do primeiro pipeline tabular.

A arquitetura já suporta essa evolução: o `toMap()` mantém **todos** os campos
(nada é removido), e o `toFlatMap()` expõe uma visão plana — cabe ao pipeline de
feature engineering (futuro) **selecionar** quais chaves entram no modelo, sem
tocar no contrato.

---

## 3. Variável-alvo (Parte 3)

**Definição (fechada na Solicitação 06):** variável supervisionada **binária**
`descontinuou_pre_natal`, mantida **fora** do formulário e **fora** do
`FormularioData` (é `y`, nunca feature `x`).

| Valor | Significado operacional                                           |
| ----- | ----------------------------------------------------------------- |
| `0`   | realizou **6 ou mais consultas** de pré-natal                     |
| `1`   | realizou **menos de 6 consultas** (descontinuidade/insuficiência) |

Fonte do limiar "6 consultas": Ministério da Saúde, Caderno de Atenção Básica
nº 32, 2013. O rótulo é **externo** ao formulário — em estudo real viria de
acompanhamento longitudinal/prontuário/SISPRENATAL; no estudo sintético é
gerado por processo probabilístico (seção 4). Nenhuma pergunta do formulário
fabrica o rótulo. **[VALIDAR NA LITERATURA]** — "6 consultas" vs. Kotelchuck
(ajuste por idade gestacional).

**Justificativa da escolha (entre as opções avaliadas):** a definição por
"número mínimo de consultas" foi escolhida por ser a mais **objetiva e
reprodutível** para um estudo sintético — as alternativas de "interrupção
definitiva" (follow-up até o parto), "ausência no 3º trimestre" ou critério
combinado exigem dados longitudinais que o formulário transversal não captura.
A definição **não** deriva de nenhuma pergunta que também seja usada como
feature (ver seção 8).

**Por que binária:** o objetivo é uma primeira estimativa supervisionada de
propensão; uma versão multiclasse (grau de risco) é evolução futura.

---

## 4. Estratégia de geração do dataset sintético (Parte 4)

O dataset será **probabilístico controlado**, **não** determinístico:

- **Seed fixa** (ex.: `seed = 42`), gerador versionado e parâmetros documentados
  (seção 10) → reproduzível.
- A variável-alvo é gerada **condicionalmente** a um _score de risco latente_
  derivado de uma combinação ponderada das features (regressão logística
  sintética + ruído), **não** por regra "se X então y=1".
- Correlações entre features e alvo são **suaves e ruidosas**, evitando
  separação perfeita (accuracy ~100%) e vazamento.
- Nenhuma feature é derivada **diretamente** do alvo; nenhuma pergunta que
  _é_ o desfecho (descontinuidade) é usada para prever o desfecho.

### 4.1 Ordem de geração com o IV-DSS

```
Geração dos DSS (X)
      │
      ├──→ cálculo do IV-DSS        (variável derivada de X — seção 12)
      │
      └──→ escore latente de risco → probabilidade → Y = descontinuou_pre_natal
```

- **X** = variáveis dos DSS (tabulares, sem texto livre e sem leakage).
- **IV-DSS** = variável **derivada** de X (função determinística de X).
- **Y** = descontinuidade do pré-natal.

**O IV-DSS não participa da geração de Y.** O escore latente de Y usa um
subconjunto **cru** de X, nunca o índice. Isso evita tornar o índice a "causa"
artificial do rótulo e preserva a associação IV-DSS↔Y como **resultado
empírico**, não como premissa. (Como ambos derivam de X, haverá associação
IV-DSS↔Y por construção — esperado e válido; declarar como limitação.)

**Classificação dos fatores sugeridos** (não assumir que são todos preditores):

| #   | Fator                                     | Classificação                                                                                                                  |
| --- | ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| 1   | Acesso à UBS                              | **Candidato a feature** (`acesso_ubs`, `cadastrada_ubs`)                                                                       |
| 2   | Distância da UBS                          | **Candidato a feature** (`distancia_ubs`)                                                                                      |
| 3   | Dificuldade de transporte                 | **Candidato a feature** (`acesso_ubs`, correlata a `faltou_consulta`)                                                          |
| 4   | Faltas às consultas                       | **Precisa de avaliação estatística** (próxima do alvo — risco de leakage, seção 8)                                             |
| 5   | Compatibilidade do trabalho com pré-natal | **Candidato a feature** (`trabalho_permite_pre_natal`, `tem_pausas_descanso`)                                                  |
| 6   | Renda                                     | **Candidato a feature** (`faixa_renda`)                                                                                        |
| 7   | Insegurança alimentar                     | **Candidato a feature** (`inseguranca_alimentar`, `refeicoes_por_dia`, `alimentos_consumidos`)                                 |
| 8   | Condições habitacionais                   | **Candidato a feature** (`tipo_moradia`, `numero_pessoas`, `numero_comodos`, `itens_residencia`, `seguranca_residencia`)       |
| 9   | Saneamento                                | **Candidato a feature** (`fonte_agua`, `esgotamento_sanitario`, `coleta_lixo`, `interrupcoes_agua`)                            |
| 10  | Escolaridade                              | **Candidato a feature** (`escolaridade`, `estuda_atualmente`)                                                                  |
| 11  | Acesso aos serviços de pré-natal          | **Candidato a feature, parcialmente leakage-adjacente** (`servicos_pre_natal`, `exames_pre_natal_completos`, `vacinas_em_dia`) |
| 12  | Dificuldades de acesso à saúde            | **Qualitativo** (`dificuldades_saude` — texto livre)                                                                           |

---

## 5. Tamanho do dataset (Parte 5)

Três patamares (para prevalência de referência ~25%, ver seção 6):

| Tamanho                           | Registros | Positivos (`1`) | Negativos (`0`) | Vantagens                                                           | Limitações                                                        |
| --------------------------------- | --------- | --------------- | --------------- | ------------------------------------------------------------------- | ----------------------------------------------------------------- |
| **Pequeno**                       | ~1.000    | ~250            | ~750            | rápido de gerar/iterar; suficiente para um _smoke test_ de pipeline | CV instável; intervalos de confiança largos; risco de overfitting |
| **Intermediário** _(recomendado)_ | ~5.000    | ~1.250          | ~3.750          | bom equilíbrio custo/estabilidade; Recall avaliável com robustez    | ainda modesto para modelos mais expressivos                       |
| **Maior**                         | ~20.000   | ~5.000          | ~15.000         | CV estável; permite comparar modelos com confiança                  | mais lento; ganho marginal para o porte do TCC                    |

> **DECISÃO NECESSÁRIA DO AUTOR — tamanho definitivo.**
> **Recomendação para o TCC:** **intermediário (~5.000)**, com a mesma _seed_,
> para balancear estabilidade estatística e esforço computacional. O valor final
> é do autor.

---

## 6. Balanceamento da classe (Parte 6)

- **Não** usar 50/50 "por conveniência".
- **Não** usar uma classe positiva tão rara que impossibilite avaliar Recall.

**Proposta:** ~**25%** positivos (faixa experimental **20–30%**), o que mantém a
classe positiva numericamente adequada (~1.250 em 5.000) sem inflar
artificialmente a separação.

> ⚠️ **Esta distribuição é uma decisão experimental do estudo sintético**, não
> uma estimativa de prevalência clínica real. O valor exato é
> **DECISÃO NECESSÁRIA DO AUTOR**.

Mitigações previstas para desbalanceamento residual (documentadas, a aplicar
apenas se necessário): `class_weight`, oversampling (ex.: SMOTE) **somente no
treino**, ou uso de `PR-AUC`/`F1` em vez de `Accuracy` como métrica principal.

---

## 7. Feature engineering (Parte 7) — documentação apenas

Mapeamento dos grupos do contrato DSS v1.0 para o futuro dataset tabular
(nenhum pipeline de encoding é implementado nesta etapa):

| Grupo                      | Campos                                                                                                                                                                                                                                                                                                                                      | Transformação futura                                                                                           |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Booleanas**              | `estuda_atualmente`, `interrompeu_estudos_gestacao`, `entende_orientacoes_saude`, `fez_curso_extracurricular`, `empregado`, `interrupcoes_agua`, `problema_saude_agua`, `faltou_consulta`, `exames_pre_natal_completos`, `vacinas_em_dia`, `inseguranca_alimentar`, `mudanca_alimentacao_gestacao`, `usa_suplementos`, `facil_acesso_saude` | `0/1` (bool → int)                                                                                             |
| **Categóricas (nominais)** | `tipo_emprego`, `fonte_agua`, `esgotamento_sanitario`, `coleta_lixo`, `acesso_ubs`, `tipo_moradia`, `fonte_alimentos`                                                                                                                                                                                                                       | one-hot encoding                                                                                               |
| **Ordinais**               | `escolaridade`, `faixa_renda`, `distancia_ubs`, `avaliacao_pre_natal`, `seguranca_residencia`, `refeicoes_por_dia`, `avaliacao_alimentacao`                                                                                                                                                                                                 | **avaliar** label/ordinal encoding — só se a ordem for metodologicamente justificável; caso contrário, one-hot |
| **Numéricas**              | `numero_pessoas`, `numero_comodos`                                                                                                                                                                                                                                                                                                          | valor numérico (normalizar/escalar no pré-processamento)                                                       |
| **Múltipla escolha**       | `dificuldades_educacao`, `beneficios_trabalho`, `servicos_pre_natal`, `itens_residencia`, `alimentos_consumidos`                                                                                                                                                                                                                            | multi-hot (uma coluna binária por código canônico)                                                             |
| **Qualitativas (texto)**   | os 5 campos da seção 1                                                                                                                                                                                                                                                                                                                      | **excluídos** do modelo tabular inicial                                                                        |

**Condicionais** (`trabalho_*`, `cadastrada_ubs`, `recebe_beneficio_social`)
são `bool?` com `null` = "não se aplica"; no pipeline, decidir entre
_missing indicator_ ou imputação — a ser definido no pré-processamento.

---

## 8. Data leakage — variáveis potencialmente problemáticas (Parte 8)

### Preocupação temporal (prever descontinuidade futura exige variáveis conhecidas _antes_)

O formulário é **transversal**; o rótulo `descontinuou_pre_natal` deve ser
coletado/definido **independentemente** e em momento posterior às features. Se
uma feature for capturada _depois_ do desfecho, ela não é um preditor válido.

### Variáveis EXCLUÍDAS do modelo e do IV-DSS (decisão fechada na Solicitação 06)

| Campo                        | Motivo da exclusão                                                                                                      |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `faltou_consulta`            | Semântica muito próxima do alvo; pode ser **praticamente sinônimo** de descontinuidade → risco de vazamento/tautologia. |
| `exames_pre_natal_completos` | Se o desfecho é definido por consultas/exames não realizados, esta variável _é_ parte do alvo.                          |
| `vacinas_em_dia`             | Desfecho de adesão, pode ser pós-descontinuidade.                                                                       |
| `servicos_pre_natal`         | Proxy de participação/engajamento; correlato ao alvo.                                                                   |
| `avaliacao_pre_natal`        | Reflete experiência **após** engajamento; temporalmente posterior.                                                      |

Essas variáveis representam informação posterior ou diretamente relacionada à
adesão/desfecho e **não entram nem no ML nem no IV-DSS** (ver seção 12). São
mantidas apenas como _variáveis de adesão_ para análise descritiva.

### Variável de acesso que PERMANECE

| Campo            | Motivo                                                                                                                                                                |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cadastrada_ubs` | **Não é leakage**: o cadastro na UBS **precede** as consultas (pré-condição de acesso). Permanece como feature e no IV-DSS (dimensão "acesso aos serviços de saúde"). |

**Regra de ouro:** nenhuma feature pode **ser** a variável-alvo nem ser
derivada dela. O IV-DSS é construído **exclusivamente** a partir de
determinantes sociais e condições de vulnerabilidade, nunca de informações do
próprio acompanhamento/adesão.

---

## 9. Plano experimental (Parte 9)

Pipeline futuro (não implementado aqui):

```
Dataset (CSV/Parquet)
 → divisão treino/teste (estratificada por y)
 → pré-processamento (encoding seção 7 + normalização)
 → validação cruzada estratificada (ex.: 5-fold)
 → treinamento (na dobra de treino)
 → avaliação (na dobra de validação e no holdout de teste)
```

**Candidatos a modelo (comparação justificada):**

| Modelo                  | Papel                  | Justificativa                                                          |
| ----------------------- | ---------------------- | ---------------------------------------------------------------------- |
| **Regressão Logística** | baseline interpretável | calibração e coeficientes legíveis (importante para DSS)               |
| **Random Forest**       | não-linear, robusta    | lida com interações; fornece _feature importance_                      |
| **XGBoost**             | forte candidato        | se o ambiente permitir a dependência; SOTA tabular                     |
| **Rede Neural**         | opcional               | só se fizer sentido metodológico (dados suficientes); senão é overkill |

> **DECISÃO NECESSÁRIA DO AUTOR** — o ambiente de execução do ML (Dart vs.
> sidecar Python, ex.: scikit-learn) define a viabilidade do XGBoost e da rede.

**Métricas planejadas:** Accuracy, Precision, Recall, F1-score, ROC-AUC —
com **ênfase em Recall**, pois o objetivo é **identificar gestantes em risco** e
um falso-negativo (risco não detectado) custa mais que um falso-positivo.

---

## 10. Reproducibilidade (Parte 10)

O gerador futuro deve registrar, e o dataset deve permitir "rodar de novo com os
mesmos parâmetros e obter o mesmo resultado":

- **seed** (fixa, ex.: `42`);
- **versão do gerador** (ex.: `generator 1.0.0`);
- **versão do schema DSS** (`schema_version = 1.0`);
- **parâmetros da geração** (pesos do score latente, nível de ruído);
- **distribuição das classes** (ex.: ~25% positivos);
- **quantidade de registros** (ex.: 5.000).

Qualquer mudança em qualquer um desses itens **invalida** a comparação direta e
deve gerar uma **nova versão** do dataset.

---

## 11. Documentação e disclaimers (Parte 11)

O dataset sintético deve ser acompanhado de uma ficha (`DATASET.md`) contendo:

1. o que é (dados sintéticos, não reais);
2. por que é usado (estudo metodológico do TCC, antes de dados reais);
3. como os registros são gerados (probabilístico + seed + score latente);
4. qual a variável-alvo (`descontinuou_pre_natal`);
5. quais são as features candidatas (seção 7);
6. quais campos são qualitativos (seção 1);
7. como o data leakage é evitado (seção 8);
8. como o IV-DSS é calculado (seção 12) e por que não é feature;
9. como será feita a avaliação (seção 9).

> ⚠️ **Dado sintético não representa dados clínicos reais e não deve ser
> interpretado como evidência de prevalência ou desempenho clínico real.**

---

## 12. Índice de Vulnerabilidade dos DSS — IV-DSS (Parte 12)

> Definição acadêmica e integração com o TCC: ver `docs/tcc2.md` (seções 2.3 e
> 4.3). Esta seção documenta os detalhes técnicos de planejamento.

### 12.1 Papel no experimento

O IV-DSS é uma **medida agregada de caracterização** da vulnerabilidade social,
**derivada** das variáveis DSS. Ele **não é** a variável-alvo e **não é** uma
feature do modelo de ML:

```
          DSS
           │
           ├──→ IV-DSS        → análise descritiva / caracterização
           │
           └──→ Features individuais → ML → P(descontinuidade)
```

**IV-DSS ≠ probabilidade de descontinuidade.** Incluí-lo como feature
simultaneamente às variáveis que o compõem introduziria **redundância** (é uma
função determinística delas).

### 12.2 Dimensões e transformação

Seis dimensões; cada variável é mapeada para um escore de vulnerabilidade
`v_i ∈ [0,1]` (**0 = menor vulnerabilidade; 1 = maior vulnerabilidade**):

1. **Educação**
2. **Trabalho e renda**
3. **Saneamento**
4. **Acesso aos serviços de saúde** (a dimensão "Saúde" do formulário, após
   exclusão das variáveis de adesão — ver seção 8)
5. **Habitação**
6. **Alimentação**

Os cinco campos de texto livre e as cinco variáveis de leakage (seção 8) **não
entram** no índice. As direções dos escores (maior/menor vulnerabilidade por
variável) estão mapeadas na Solicitação 07; os valores nominais finais seguem
**pendentes** (§12.6).

### 12.3 Fórmula

```
D_d     = (1 / |I_d|) · Σ_{i ∈ I_d} v_i

IV-DSS  = (1/6) · Σ_{d=1}^{6} D_d
```

onde `v_i` = escore do indicador; `D_d` = escore da dimensão; `I_d` = conjunto
de indicadores **válidos** da dimensão (não ausentes / condicionais
inaplicáveis).

### 12.4 Pesos

**Pesos iguais (1/6)** entre as seis dimensões (OECD/JRC: padrão na ausência de
base causal/empírica). Agregação principal por **média aritmética**.

### 12.5 Escala e interpretação

Escala contínua `[0,1]`. Sem faixas absolutas fundamentadas na literatura; para
apresentação, usar **quantis** (relativos à amostra). A **agregação geométrica**
`IV-DSS_geo = (Π D_d)^{1/6}` é **análise de sensibilidade**, não o índice
principal.

### 12.6 Decisões pendentes (não bloqueiam a geração, mas precisam de fechamento)

- `recebe_beneficio_social` (direção do escore).
- `acesso_ubs` (incluir ou excluir).
- `usa_suplementos` e `mudanca_alimentacao_gestacao` (possível consequência da
  adesão).
- `faixa_renda = nao_informar` (imputar 0.5 vs. omitir).
- Limiar do adensamento habitacional.
- Valores finais de escores nominais.
- Taxa de missing planejada.
- Faixas de interpretação.
