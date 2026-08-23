# TCC2 — Estrutura e Metodologia (documento principal)

> **Status:** documento acadêmico principal do TCC2 (em construção).
> Não reproduz decisões do TCC1; o TCC1 (`docs/TCC - Hárliton Martins.pdf`) é
> usado apenas como referência estrutural e histórica.

> ⚠️ **Disclaimer (imutável):** o resultado produzido pelo modelo será uma
> estimativa estatística de risco e **NÃO** deverá ser tratado como diagnóstico
> médico ou como certeza de abandono. Os dados sintéticos possuem finalidade
> experimental e de validação técnica, não representando prevalências,
> associações clínicas ou características reais da população de gestantes.
> Nenhuma associação estatística será apresentada como relação causal.

**Título provisório** — _"Estimativa da propensão à descontinuidade do
acompanhamento pré-natal a partir dos Determinantes Sociais da Saúde: uma
abordagem com aprendizado de máquina e um índice de vulnerabilidade"_.
**[DECISÃO DO AUTOR]** — ver análise de títulos na seção 1.5.

---

## 1 Introdução

### 1.1 Contextualização

O pré-natal é a principal estratégia de cuidado da gestação e de prevenção de
desfechos materno-infantis adversos. As **Condições/Determinantes Sociais da
Saúde (DSS)** — educação, trabalho e renda, habitação, saneamento, acesso a
serviços e alimentação — condicionam, de forma documentada na literatura, o
acesso e a continuidade desse acompanhamento. Este trabalho desenvolve uma
solução que **integra, em uma mesma aplicação**, (i) a coleta estruturada dos
DSS e (ii) um módulo de acompanhamento do pré-natal, e aplica **aprendizado de
máquina** sobre os DSS para estimar a propensão à descontinuidade do pré-natal.

### 1.2 Problema de pesquisa

A descontinuidade do acompanhamento pré-natal está associada a piores desfechos
maternos e neonatais. O problema investigado é: _é possível estimar, a partir
dos DSS coletados de forma estruturada, a propensão de uma gestante à
descontinuidade do acompanhamento pré-natal?_

### 1.3 Justificativa

O diferencial/proposta do sistema é **integrar, em uma mesma solução**, a coleta
de informações relacionadas aos Determinantes Sociais da Saúde e um módulo de
acompanhamento do pré-natal, com **armazenamento local** das informações de
acompanhamento (funcionamento offline). Essa integração permite tanto
**caracterizar** a vulnerabilidade social da gestante (via índice) quanto
**estimar** a propensão à descontinuidade (via modelo), em uma única ferramenta.

### 1.4 Objetivos

Ver seção 3.

### 1.5 Título — análise (fundamentação metodológica)

| Termo candidato   | Avaliação                                                                                  |
| ----------------- | ------------------------------------------------------------------------------------------ |
| "abandono"        | forte demais; sem definição operacional acessível/consensual; exige follow-up até o parto. |
| "descontinuidade" | fiel à definição operacional adotada (menos de 6 consultas).                               |
| "propensão"       | correto: o modelo emite probabilidade, não diagnóstico.                                    |
| "risco"           | aceitável, mas carrega conotação clínica.                                                  |
| "DSS"             | deve aparecer (é o objeto central da coleta e do índice).                                  |

**Recomendação:** priorizar "descontinuidade" + "DSS" + "aprendizado de
máquina"; manter "índice de vulnerabilidade" como segundo eixo do trabalho.
**[DECISÃO DO AUTOR]**.

---

## 2 Referencial Teórico

### 2.1 Pré-natal e saúde materna

Conceitos, calendário de consultas e papel do acompanhamento. **[VALIDAR NA
LITERATURA]** — apoiar-se no TCC1 e na literatura disponível em `../artigos/`.

### 2.2 Determinantes Sociais da Saúde

- Modelo de **Dahlgren & Whitehead** (camadas de determinação).
- Fiocruz — Determinantes Sociais da Saúde (portal DSS-Brasil).
- Distinção entre determinante social e **iniquidade** em saúde.
  **[VALIDAR NA LITERATURA]** — fontes primárias em `../artigos/`.

### 2.3 Vulnerabilidade e índices compostos

- Conceito de **vulnerabilidade** (Ayres et al.): vulnerabilidade **≠** risco;
  construção social multideterminada (dimensões individual, social e
  programática).
- Construção de **índices compostos** (OECD/JRC Handbook, 2008): normalização,
  ponderação (pesos iguais como padrão na ausência de base causal), agregação
  linear vs. geométrica, e a questão da **compensabilidade**.
- Referências brasileiras de índices compostos: IPEA — Atlas da Vulnerabilidade
  Social (IVS) e IPVS/SEADE. **[VALIDAR NA LITERATURA]**.

### 2.4 Aprendizado de máquina supervisionado

Classificação binária; regressão logística, modelos de árvore (Random Forest,
XGBoost) e redes neurais; métricas para classes desbalanceadas (Recall,
Precision, F1, ROC-AUC, PR-AUC). **[VALIDAR NA LITERATURA]**.

---

## 3 Objetivos

### 3.1 Objetivo geral

Desenvolver um aplicativo móvel para coleta estruturada dos **Determinantes
Sociais da Saúde** e **acompanhamento do pré-natal**, construir um **Índice de
Vulnerabilidade dos DSS (IV-DSS)** para caracterização das participantes, e
desenvolver um **modelo de aprendizado de máquina** — treinado e avaliado sobre
um **dataset sintético** — capaz de **estimar a propensão** à **descontinuidade
do acompanhamento pré-natal**.

### 3.2 Objetivos específicos

| #   | Objetivo                                                                                                                                                                          | Status                                               |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| 1   | Modelar os DSS em um contrato de dados canônico, versionado e reproduzível.                                                                                                       | ✅ realizado                                         |
| 2   | Construir um **Índice de Vulnerabilidade dos DSS (IV-DSS)**, baseado nas dimensões investigadas, para caracterizar o nível de vulnerabilidade social das gestantes participantes. | 🆕 metodologicamente definido; aguarda implementação |
| 3   | Desenvolver o aplicativo Flutter com o questionário DSS e o módulo de acompanhamento do pré-natal (armazenamento local/offline).                                                  | ✅ parcialmente realizado                            |
| 4   | Definir operacionalmente a variável-alvo (descontinuidade do pré-natal).                                                                                                          | ⏳ [VALIDAR NA LITERATURA]                           |
| 5   | Gerar um dataset sintético reproduzível (seed fixa), com relações estatísticas plausíveis entre DSS e alvo.                                                                       | ⏳ pendente                                          |
| 6   | Aplicar técnicas de aprendizado de máquina para estimar a propensão à descontinuidade.                                                                                            | ⏳ pendente                                          |
| 7   | Avaliar os modelos por métricas adequadas a classes desbalanceadas.                                                                                                               | ⏳ pendente                                          |
| 8   | Integrar aplicativo, API e modelo no fluxo Flutter → API → ML.                                                                                                                    | ⏳ pendente                                          |

---

## 4 Metodologia

### 4.1 Tipo de pesquisa

Pesquisa aplicada, de natureza experimental/quantitativa, com dados sintéticos
(fase de validação técnica da metodologia). **[DECISÃO DO AUTOR]** — refinamento
do enquadramento no texto final.

### 4.2 Determinantes Sociais da Saúde utilizados

O instrumento coleta **seis dimensões**:

1. **Educação**
2. **Trabalho e renda**
3. **Saneamento**
4. **Acesso aos serviços de saúde**
5. **Habitação**
6. **Alimentação**

> **Observação de nomenclatura:** o formulário possui uma dimensão denominada
> "Saúde", porém, após a exclusão das variáveis relacionadas à adesão/desfecho
> (ver 4.5 e 4.7), o IV-DSS e o modelo utilizam apenas os indicadores
> relacionados ao **acesso** aos serviços de saúde. Isso evita a interpretação
> de que o índice mede qualidade ou adesão ao pré-natal — ele mede
> **vulnerabilidade de acesso**.

### 4.3 Construção do Índice de Vulnerabilidade dos DSS (IV-DSS)

O IV-DSS é uma **medida agregada de caracterização** da vulnerabilidade social
das participantes. **Não é** variável-alvo e **não é** sinônimo de risco de
descontinuidade.

#### 4.3.1 Definição conceitual

```
          DSS
           │
           ├──→ IV-DSS
           │        └── caracteriza o nível agregado de vulnerabilidade social
           │
           └──→ Modelo de ML
                    └── estima a propensão à descontinuidade do pré-natal
```

**IV-DSS ≠ probabilidade de descontinuidade.** O índice responde a _"qual o
nível de vulnerabilidade social da gestante segundo os DSS?"_; o modelo responde
a _"qual a propensão à descontinuidade do pré-natal?"_.

#### 4.3.2 Estrutura (dois níveis)

- **Nível 1 — indicador → escore:** cada variável DSS é transformada em um
  escore de vulnerabilidade `v_i ∈ [0,1]`, onde **0 = menor vulnerabilidade** e
  **1 = maior vulnerabilidade**.
- **Nível 2 — dimensão:** `D_d` é a média aritmética dos `v_i` **válidos** da
  dimensão `d`.
- **Nível 3 — índice:** média aritmética das seis dimensões, com **pesos
  iguais**.

#### 4.3.3 Fórmula

```
D_d     = (1 / |I_d|) · Σ_{i ∈ I_d} v_i

IV-DSS  = (1/6) · Σ_{d=1}^{6} D_d
```

onde:

- `v_i` = escore de vulnerabilidade do indicador `i`;
- `D_d` = escore da dimensão `d`;
- `I_d` = conjunto de indicadores **válidos** da dimensão `d` (não ausentes /
  não condicionais-inaplicáveis).

#### 4.3.4 Pesos

**Pesos iguais (1/6)** entre as seis dimensões. Fundamentação (OECD/JRC): pesos
iguais são a escolha defensável por padrão quando **não há base causal ou
empírica** para pesos diferentes; com dados sintéticos, pesos estatísticos
seriam artificiais. Os pesos são uma **decisão explícita**, não uma "ausência de
peso".

#### 4.3.5 Escala e interpretação

- Escala **contínua** `IV-DSS ∈ [0,1]`.
- **Sem faixas absolutas fundamentadas na literatura.** A saída primária é o
  valor contínuo; para apresentação, usar **estratificação por quantis**
  (relativa à amostra), não faixas fixas de risco. **[DECISÃO DO AUTOR]**.

#### 4.3.6 Agregação de sensibilidade

A **agregação geométrica** `IV-DSS_geo = (Π D_d)^{1/6}` poderá ser usada como
**análise de sensibilidade** (reduz a compensabilidade entre dimensões), mas
**não** é o índice principal.

### 4.4 Modelagem dos dados

Contrato de dados canônico e versionado (`schema_version = '1.0'`), com códigos
canônicos (`snake_case`) separados dos rótulos de UI. `FormularioData.toMap()`
(aninhado, versionado) e `toFlatMap()` (`dimensao.campo`). Os cinco campos de
texto livre são preservados como qualitativos e **não entram** no modelo tabular
nem no índice.

### 4.5 Definição operacional da variável-alvo

- **Conceito:** descontinuidade do acompanhamento pré-natal.
- **Definição operacional:** realizou **menos de 6 consultas** (referência:
  Ministério da Saúde, Caderno de Atenção Básica nº 32, 2013).
- **Variável:** `descontinuou_pre_natal ∈ {0,1}` — `0` = ≥6 consultas;
  `1` = <6 consultas.
- O rótulo é **externo ao formulário**: em estudo real viria de acompanhamento
  longitudinal/prontuário/SISPRENATAL; no estudo sintético é gerado por processo
  probabilístico (ver 4.6). **Nenhuma** pergunta do formulário fabrica o rótulo.
- **[VALIDAR NA LITERATURA]** — limiar "6 consultas" vs. Kotelchuck (ajuste por
  idade gestacional).

### 4.6 Geração do dataset sintético

Fluxo (seed fixa, gerador versionado):

```
Geração dos DSS (X)
      │
      ├──→ cálculo do IV-DSS        (variável derivada de X)
      │
      └──→ escore latente de risco → probabilidade → Y = descontinuou_pre_natal
```

- **X** = variáveis dos DSS (tabulares, sem texto livre e sem leakage);
- **IV-DSS** = variável **derivada** de X (função determinística);
- **Y** = descontinuidade do pré-natal.

**O IV-DSS não participa da geração de Y.** O escore latente de Y usa um
subconjunto **cru** de X, nunca o índice — isso evita tornar o índice a "causa"
artificial do rótulo e preserva a associação IV-DSS↔Y como resultado empírico,
não como premissa. Configurações mantidas: **~5.000 registros**, **prevalência
~25%** de Y=1.

### 4.7 Pré-processamento e controle de leakage

As variáveis a seguir **não entram no ML nem no IV-DSS**, pois representam
informação posterior ou diretamente relacionada à adesão/desfecho (risco de
leakage):

- `faltou_consulta`
- `exames_pre_natal_completos`
- `vacinas_em_dia`
- `servicos_pre_natal`
- `avaliacao_pre_natal`

O IV-DSS é construído **exclusivamente** a partir de determinantes sociais e
condições de vulnerabilidade, nunca de informações do próprio acompanhamento.
Os cinco campos de texto livre também ficam de fora do índice e do modelo.

### 4.8 Modelos de aprendizado de máquina

Regressão logística (baseline), Random Forest, XGBoost; rede neural opcional;
K-means como análise exploratória (apêndice). **[DECISÃO DO AUTOR]** sobre o
ambiente de execução (Python/scikit-learn).

### 4.9 Treinamento e validação

Divisão estratificada treino/teste; validação cruzada estratificada; seed fixa;
`class_weight` se necessário. **[DEPENDE DA IMPLEMENTAÇÃO]**.

### 4.10 Métricas

Accuracy, Precision, **Recall (prioridade)**, F1, ROC-AUC, PR-AUC. Justificativa:
falso-negativo (propensão não detectada) custa mais que falso-positivo.
**[DEPENDE DA IMPLEMENTAÇÃO]**.

### 4.11 Integração Flutter → API → ML

Contrato de entrada (X) e saída (probabilidade de descontinuidade), com a
resposta **não** apresentada como diagnóstico. **[DEPENDE DA IMPLEMENTAÇÃO]**.

### 4.12 Aspectos éticos e limitações

- Dados sintéticos ≠ dados reais (sem validade externa clínica).
- Estimativa ≠ diagnóstico médico.
- Associação estatística ≠ causalidade.
- O IV-DSS caracteriza vulnerabilidade; **não** é julgamento individual nem
  preditor isolado de desfecho.

---

## 5 Desenvolvimento da aplicação

### 5.1 Arquitetura

Flutter com **flutter_modular + MobX** (não "MVVM" — corrigir em relação ao
TCC1), contratos canônicos versionados, persistência local e comunicação
assíncrona com futura API.

### 5.2 Eixo 1 — Questionário dos DSS

Formulário estruturado das seis dimensões; coleta informações usadas na
caracterização (IV-DSS) e, posteriormente, no modelo analítico.

### 5.3 Eixo 2 — Módulo de acompanhamento do pré-natal

Permite à gestante registrar/acompanhar informações do próprio pré-natal
(consultas e dados), com **armazenamento local no dispositivo**.

### 5.4 Armazenamento local / offline

O módulo de acompanhamento **não depende de API** para armazenar essas
informações; funciona offline. Esta é uma característica arquitetural e
funcional — **não** um preditor do modelo.

> O módulo de acompanhamento é **funcionalidade da aplicação** e **não** faz
> parte diretamente do modelo de predição.

### 5.5 Onde o IV-DSS é calculado

Nesta versão, o IV-DSS é calculado **no pipeline analítico** (pré-processamento),
não no aplicativo nem na API. **[DECISÃO DO AUTOR]** para exibição futura no app.

---

## 6 Resultados e Discussão

**[AGUARDAR RESULTADOS]** — caracterização do dataset, desempenho dos modelos,
comparação entre modelos, análise de importância de features, associação
IV-DSS↔Y, limitações.

## 7 Conclusão

**[AGUARDAR RESULTADOS]** — retomada dos objetivos, contribuições, limitações,
trabalhos futuros.

---

## Referências (já levantadas; a consolidar)

1. Ministério da Saúde. _Atenção ao pré-natal de baixo risco_. Cadernos de
   Atenção Básica nº 32, 2013.
2. Ministério da Saúde. _Pré-natal_. gov.br.
3. World Health Organization. _WHO recommendations on antenatal care for a
   positive pregnancy experience_. 2016.
4. OECD/JRC. _Handbook on Constructing Composite Indicators: Methodology and
   User Guide_. 2008.
5. Ayres, J. R. C. M. et al. _O conceito de vulnerabilidade e as práticas de
   saúde: novas perspectivas e desafios_.
6. Fiocruz. _Determinantes Sociais da Saúde_ (portal DSS-Brasil).
7. IPEA. _Atlas da Vulnerabilidade Social (IVS)_. **[VALIDAR NA LITERATURA]**.
8. SEADE. _Índice Paulista de Vulnerabilidade Social (IPVS)_.
   **[VALIDAR NA LITERATURA]**.

---

## Apêndice — Decisões congeladas e pendentes

### 🔒 Decisões congeladas

1. Variável-alvo `descontinuou_pre_natal ∈ {0,1}` (0 = ≥6 consultas; 1 = <6).
2. Rótulo externo ao formulário (processo probabilístico).
3. Leakage: 5 variáveis excluídas de features e do índice.
4. 5 campos de texto livre excluídos do índice e do modelo tabular.
5. IV-DSS: pesos iguais (1/6), escala [0,1], média aritmética.
6. IV-DSS descritivo (não é feature do ML).
7. Ordem de geração: `DSS → (IV-DSS) ∥ (escore latente → Y)`.
8. Agregação geométrica = análise de sensibilidade.
9. ~5.000 registros, ~25% de prevalência.
10. IV-DSS calculado no pipeline analítico.

### ⚠️ Decisões pendentes

adas; a consolidar)

1. Ministério da Saúde. _Atenção ao pré-natal de baixo risco_. Cadernos de
   Atenção Básica nº 32, 2013.
2. Ministério da Saúde. _Pré-natal_. gov.br.
3. World Health Organization. _WHO recommendations on antenatal care for a
   positive pregnancy experience_. 2016.
4. OECD/JRC. _Handbook on Constructing Composite Indicators: Methodology and
   User Guide_. 2008.
5. Ayres, J. R. C. M. et al. _O conceito de vulnerabilidade e as práticas de
   saúde: novas perspectivas e desafios_.
6. Fiocruz. _Determinantes Sociais da Saúde_ (portal DSS-Brasil).
7. IPEA. _Atlas da Vulnerabilidade Social (IVS)_. **[VALIDAR NA LITERATURA]**.
8. SEADE. _Índice Paulista de Vulnerabilidade Social (IPVS)_ NA LITERATURA]**.
8. SEADE. _Índice Paulista de Vulnerabilidade Social (IPVS)_.
   **[VALIDAR NA LITERATURA]**.

---

## Apêndice — Decisões congeladas e pendentes

### 🔒 Decisões congeladas

1. Variável-alvo `descontinuou_pre_natal ∈ {0,1}` (0 = ≥6 consultas; 1 = <6).
2. Rótulo externo ao formulário (processo probabilístico).
3. Leakage: 5 variáveis excluídas de features e do índice.
4. 5 campos de texto livre excluídos do índice e do modelo tabular.
5. IV-DSS: pesos iguais (1/6), escala [0,1], média aritmética.
6. IV-DSS descritivo (não é feature do ML).
7. Ordem de geração: `DSS → (IV-DSS) ∥ (escore latente → Y)`.
8. Agregação geométrica = análise de sensibilidade.
9. ~5.000 registros, ~25% de prevalência.
10. IV-DSS calculado no pipeline analítico.

### ⚠️ Decisões pendentes

- `recebe_beneficio_social` (direção do escore).
- `acesso_ubs` (incluir ou excluir do índice).
- `usa_suplementos` e `mudanca_alimentacao_gestacao` (possível consequência da
  adesão).
- `faixa_renda = nao_informar` (imputar 0.5 vs. omitir).
- Limiar do adensamento habitacional.
- Valores finais de alguns escores nominais.
- Taxa de missing planejada.
- Critério definitivo de descontinuidade (6 consultas vs. Kotelchuck).
- Faixas de interpretação do IV-DSS.
- Título final do trabalho.
