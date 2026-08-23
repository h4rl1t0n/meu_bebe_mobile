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

| Termo candidato   | Avaliação                                                                                                   |
| ----------------- | ----------------------------------------------------------------------------------------------------------- |
| "abandono"        | forte demais; sem definição operacional acessível/consensual; exige follow-up até o parto.                  |
| "descontinuidade" | fiel à definição operacional adotada (referência operacional preliminar de insuficiência quantitativa de consultas). |
| "propensão"       | correto: o modelo emite probabilidade, não diagnóstico.                                                     |
| "risco"           | aceitável, mas carrega conotação clínica.                                                                   |
| "DSS"             | deve aparecer (é o objeto central da coleta e do índice).                                                   |

**Recomendação:** priorizar "descontinuidade" + "DSS" + "aprendizado de
máquina"; manter "índice de vulnerabilidade" como segundo eixo do trabalho.
**[DECISÃO DO AUTOR]**.

---

## 2 Referencial Teórico

### 2.1 Pré-natal e saúde materna

Conceitos, calendário de consultas e papel do acompanhamento. Incluir a
**Rede Alyne** como referência contemporânea da atenção à saúde materna no SUS:
a Portaria GM/MS nº 5.350/2024 (Art. 7º, §1º, I) estabelece o pré-natal na UBS
com **captação oportuna da gestante até 12 semanas** e, **no mínimo, sete
consultas** intercaladas entre enfermeiros e médicos (BRASIL, 2024). Apoiar-se
no TCC1 e na literatura disponível em `../artigos/`.

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
  ponderação, agregação linear vs. geométrica, análise de sensibilidade e a
  questão da **compensabilidade**. O peso igual é uma opção possível, não uma
  regra universal determinada pelo OECD/JRC.
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

| #   | Objetivo                                                                                                                                                                          | Status                                                               |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| 1   | Modelar os DSS em um contrato de dados canônico, versionado e reproduzível.                                                                                                       | ✅ realizado                                                         |
| 2   | Construir um **Índice de Vulnerabilidade dos DSS (IV-DSS)**, baseado nas dimensões investigadas, para caracterizar o nível de vulnerabilidade social das gestantes participantes. | 🆕 metodologicamente definido (escores por dimensão); aguarda implementação |
| 3   | Desenvolver o aplicativo Flutter com o questionário DSS e o módulo de acompanhamento do pré-natal (armazenamento local/offline).                                                  | ✅ parcialmente realizado                                            |
| 4   | Definir operacionalmente a variável-alvo (descontinuidade do pré-natal).                                                                                                          | ✅ conceito do desfecho definido para o experimento sintético; operacionalização longitudinal para dados reais ainda requer fundamentação específica |
| 5   | Gerar um dataset sintético reproduzível (seed fixa), com dependências probabilísticas controladas e explicitamente definidas entre DSS e o desfecho sintético.                      | ⏳ pendente                                                          |
| 6   | Aplicar técnicas de aprendizado de máquina para estimar a propensão à descontinuidade.                                                                                            | ⏳ pendente                                                          |
| 7   | Avaliar os modelos por métricas adequadas a classes desbalanceadas.                                                                                                               | ⏳ pendente                                                          |
| 8   | Integrar aplicativo, API e modelo no fluxo Flutter → API → ML.                                                                                                                    | ⏳ pendente                                                          |

---

## 4 Metodologia

### 4.1 Tipo de pesquisa

Pesquisa aplicada, de natureza experimental/quantitativa, com dados sintéticos
(fase de validação técnica da metodologia). **[DECISÃO DO AUTOR]** — refinamento
do enquadramento no texto final.

### 4.2 Determinantes Sociais da Saúde utilizados

O instrumento coleta **seis dimensões** e **48 variáveis**:

1. **Educação**
2. **Trabalho e renda**
3. **Saneamento**
4. **Acesso aos serviços de saúde**
5. **Habitação**
6. **Alimentação**

> **Observação de nomenclatura:** o formulário possui uma dimensão denominada
> "Saúde", porém, após a exclusão das variáveis relacionadas à adesão/desfecho
> (ver 4.7), o IV-DSS e o modelo utilizam apenas os indicadores relacionados ao
> **acesso** aos serviços de saúde. Isso evita a interpretação de que o índice
> mede qualidade ou adesão ao pré-natal — ele mede **vulnerabilidade de acesso**.

### 4.3 Construção do Índice de Vulnerabilidade dos DSS (IV-DSS proposto)

O **IV-DSS proposto** é uma **medida agregada de caracterização** da
vulnerabilidade social das participantes. É um **índice experimental**: não é um
instrumento validado, nem escala diagnóstica, nem índice epidemiologicamente
validado. **Não é** variável-alvo e **não é** sinônimo de risco de
descontinuidade. A especificação técnica completa encontra-se em
`docs/planejamento_dataset_sintetico.md`.

#### 4.3.1 Definição conceitual

```text
          DSS
           │
           ├──→ IV-DSS (proposto)
           │        └── caracteriza o nível agregado de vulnerabilidade social
           │
           └──→ Modelo de ML
                    └── estima a propensão à descontinuidade do pré-natal
```

**IV-DSS ≠ probabilidade de descontinuidade.** O índice responde a _"qual o
nível de vulnerabilidade social da gestante segundo os DSS?"_; o modelo responde
a _"qual a propensão à descontinuidade do pré-natal?"_.

#### 4.3.2 Estrutura (dois níveis de agregação)

- **Nível 1 — indicador → escore:** cada indicador selecionado é transformado em
  um escore de vulnerabilidade `v_i ∈ [0,1]`, onde **0 = menor vulnerabilidade**
  e **1 = maior vulnerabilidade**, segundo a operacionalização adotada.
- **Nível 2 — dimensão:** `D_d` agrega os escores dos indicadores **válidos** da
  dimensão `d`.
- **Nível 3 — índice:** média aritmética das seis dimensões, com **pesos
  iguais**.

```text
D_d     = agregação dos v_i válidos da dimensão d

IV-DSS  = (1/6) · Σ_{d=1}^{6} D_d
```

onde:

- `v_i` = escore de vulnerabilidade do indicador `i`;
- `D_d` = escore da dimensão `d`.

**Regras de separação entre ML e IV-DSS:**

- **NÃO** usar IV-DSS como target;
- **NÃO** usar IV-DSS para gerar Y;
- **NÃO** usar IV-DSS como feature principal do ML;
- o IV-DSS poderá ser analisado em relação às previsões e ao Y, mas é calculado
  de forma **independente**.

#### 4.3.3 Indicadores e escores por dimensão

**D_educacao** — indicador `escolaridade` (normalização ordinal, intervalos
iguais operacionais):

`sem_instrucao` = 1.00 · `fundamental_incompleto` = 0.83 ·
`fundamental_completo` = 0.67 · `medio_incompleto` = 0.50 ·
`medio_completo` = 0.33 · `superior_incompleto` = 0.17 ·
`superior_completo` = 0.00.

**D_trabalho_renda** — indicador `faixa_renda` (renda **familiar**, não per
capita — limitação registrada):

`ate_1_sm` = 1.00 · `entre_1_2_sm` = 0.67 · `entre_2_3_sm` = 0.33 ·
`mais_3_sm` = 0.00 · `nao_informar` = missing (não pontua).

**D_saneamento** — média de três componentes (`C_agua`, `C_esgotamento`,
`C_residuos`), exigindo pelo menos 2/3 válidos:

- `C_agua` = média de `fonte_agua` (`rede_publica`/`poco_nascente` = 0;
  `carro_pipa` = 1; `cisterna`/`outra` = missing analítico),
  `itens_residencia.agua_encanada` (presente = 0; ausente = 1) e
  `interrupcoes_agua` (false = 0; true = 1), exigindo pelo menos 2/3 válidos.
- `C_esgotamento` = `rede_coletora`/`fossa_septica` = 0; `ceu_aberto` = 1;
  `outro` = missing analítico.
- `C_residuos` = `frequencia_coleta_lixo` (`regular` = 0; `irregular` = 0.5;
  `nao_possui` = 1) combinada com `destino_lixo_sem_coleta`
  (`aguarda_proxima_coleta` = 0; `queima`/`enterra`/`terreno_baldio` = 1).

**D_acesso_saude** — `(C_distancia + C_barreiras) / 2` (exige 2/2):

- `C_distancia` = `muito_proxima` = 0; `razoavelmente_proxima` = 0.5;
  `distante` = 1.
- `C_barreiras` = `(transporte + organizacao + disponibilidade) / 3`, onde os
  domínios de `dificuldades_saude` são: **transporte** (`falta_transporte`),
  **organização** (`dificuldade_agendamento`, `demora_atendimento`,
  `horario_incompativel`), **disponibilidade** (`falta_profissional`,
  `falta_exames`); cada domínio presente = 1, ausente = 0;
  `sem_dificuldades` = 0.

**D_habitacao** — indicador `adensamento_habitacional` (derivado no pipeline
Python, sem alterar o Flutter):

`adensamento = numero_pessoas / numero_dormitorios` — `≤ 2` = 0.00 ·
`> 2 e ≤ 3` = 0.50 · `> 3` = 1.00. Testar em sensibilidade o critério binário
`> 3` = 1; `≤ 3` = 0.

**D_alimentacao** — indicador `deixou_de_comer_falta_dinheiro` (`false` = 0;
`true` = 1; `null` = missing). Descrição recomendada: *"indicador de experiência
autorrelatada de privação alimentar associada à insuficiência de recursos
financeiros nos três meses anteriores."* **Não** afirmar que constitui aplicação
da EBIA ou da FIES.

**Fora do IV-DSS (e por quê):** as 5 variáveis de leakage (4.7), as 5 temporais
(4.7), as 2 descritivas (`cuidados_vetores`, `melhorias_desejadas`) e as 2 de
sensibilidade (`problema_saude_agua`, `facil_acesso_saude`). `acesso_ubs` e
`cadastrada_ubs` permanecem disponíveis ao ML como variáveis nominais, mas **não**
pontuam no IV-DSS.

#### 4.3.4 Pesos

Na ausência de evidência empírica que sustente pesos diferenciados entre as
dimensões, este estudo adota **pesos iguais (1/6)** como opção metodológica
transparente e parcimoniosa. Essa escolha é **explícita** e será submetida à
análise de sensibilidade. O OECD/JRC é citado como referência geral para
construção de indicadores compostos (normalização, ponderação, agregação e
análise de sensibilidade), sem que o peso igual seja tratado como regra
universal por ele determinada.

#### 4.3.5 Escala e interpretação

- **Saída principal:** IV-DSS contínuo no intervalo `[0,1]`.
- **Não** criar pontos de corte absolutos de baixa/média/alta vulnerabilidade.
- Caso seja necessária categorização apenas para **visualização/descrição**,
  utilizar **quantis relativos à amostra**.
- Essas categorias por quantis são **amostrais** e **não** representam pontos de
  corte clínicos, epidemiológicos ou validados.

#### 4.3.6 Política de missing e validade

`missing ≠ 0`, `missing ≠ 0.5`, `missing ≠ vulnerabilidade intermediária`.
Distinguir resposta ausente, não aplicável estrutural (condicional do schema) e
categoria válida porém analiticamente indeterminada. **Não** imputar
automaticamente. O **IV-DSS principal exige 6/6 dimensões válidas**; caso
contrário, `IV-DSS = não calculável` (não calcular silenciosamente a média das
dimensões restantes). Um `iv_dss_parcial` com cobertura 5/6 poderá existir
apenas como resultado auxiliar futuro.

#### 4.3.7 Análises de sensibilidade

A agregação principal é **aritmética** (não usar geométrica como primeira
alternativa, pois dimensões podem assumir 0). Planejar: normalização alternativa
da `escolaridade`; adensamento em 3 níveis vs. binário; perturbações nos pesos;
possível componente ocupacional; agregação menos compensatória justificável. O
objetivo é testar **robustez** — não escolher a posteriori a versão com "melhor
resultado".

### 4.4 Modelagem dos dados

Contrato de dados canônico e versionado (`schema_version = '1.13'`), com códigos
canônicos (`snake_case`) separados dos rótulos de UI. `FormularioData.toMap()`
(aninhado, versionado) e `toFlatMap()` (`dimensao.campo`). O schema possui seis
dimensões e 48 variáveis, todas estruturadas (booleanas, categóricas por código,
múltipla escolha por código ou numéricas) — **sem campos de texto livre**.

### 4.5 População, T0 e variável-alvo

**População-alvo do modelo:** gestantes que **já iniciaram** o acompanhamento
pré-natal. O critério de inclusão "iniciou o pré-natal" é **parte da população**,
não uma variável coletada pelo formulário.

**T0** = instante em que a gestante conclui o questionário DSS e os dados são
enviados à API para inferência. Somente informações **legitimamente disponíveis
em ou antes de T0** participam do modelo preditivo principal.

**Variável-alvo (externa ao formulário):**

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
  (ver 4.6).
- O objetivo desse Y é testar **tecnicamente** o pipeline de ML em cenário
  controlado.

**Nenhuma** pergunta do formulário fabrica o rótulo. Em futura validação com
dados reais, o critério longitudinal de desfecho deve ser definido e validado a
partir dos registros reais de acompanhamento (prontuário/SISPRENATAL).

### 4.6 Geração do dataset sintético

**Nomenclatura conceitual (usada em todo o documento):**

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

Fluxo (seed fixa, gerador versionado):

```text
Geração de Q_full (48)
      |
      |--> cálculo independente do IV-DSS   (função de Q_full)
      |
      `--> fatores g_* → escore latente → probabilidade → Y
```

- **Q_full** = variáveis dos DSS observadas (48, tabulares);
- **IV-DSS** = variável **derivada** de `Q_full` (função determinística,
  independente);
- **Y** = descontinuidade do pré-natal (target sintético).

**O IV-DSS não participa da geração de Y.** O Y é gerado por um **mecanismo
probabilístico experimental (DGM)**, descrito a seguir, cujos coeficientes são
**parâmetros de simulação** — não _odds ratios_ da literatura.

- **Fatores latentes Z:** cinco fatores internos do simulador (`Z_SES`,
  `Z_LAB`, `Z_TERR`, `Z_INFRA`, `Z_SERV`) gerados por distribuição normal
  multivariada com correlações moderadas (matriz especificada no documento
  técnico). Esses fatores **não** vão ao Flutter, à API, ao ML nem ao IV-DSS.
- **Camadas de geração:** fatores latentes → variáveis base → variáveis
  dependentes/condicionais → multiselects/descritivas → validação das invariantes
  do schema → fatores `g_*` → Y → IV-DSS.
- **Fatores g:** oito fatores internos derivados de `Q_full`
  (`g_escolaridade`, `g_renda`, `g_distancia`, `g_transporte`, `g_organizacao`,
  `g_trabalho`, `g_privacao_alimentar`, `g_adensamento`) alimentam o escore
  latente de Y, com duas interações experimentais
  (`g_renda × g_privacao_alimentar`, `g_distancia × g_transporte`).
- **Equação:** `eta = alpha + 0.50·E + 0.55·R + 0.45·D + 0.55·T + 0.40·O +
  0.40·W + 0.30·F + 0.25·H + 0.30·(R·F) + 0.35·(D·T) + U`, com
  `U ~ Normal(0, 0.50)`; depois `p = sigmoid(eta)` e `Y ~ Bernoulli(p)`.
- **Calibração do intercepto:** `alpha` é calibrado numericamente para que a
  média das probabilidades verdadeiras ≈ proporção sintética planejada (~25%),
  não escolhido por tentativa manual.
- **Não-determinismo controlado:** `faixa_renda = nao_informar` em pequena
  parcela dos registros — o simulador conhece a condição econômica verdadeira
  antes da ocultação; o modelo recebe apenas `nao_informar`.

Configurações mantidas: **~5.000 registros**, **proporção sintética planejada
~25%** de Y=1 (não chamar de "prevalência"), seed fixa `42`. Cenários de
sensibilidade futuros: ~15%, ~25%, ~35%.

### 4.7 Seleção de variáveis e controle de leakage

Classificação consolidada das 48 variáveis:

| Classe | Qtde | Significado |
| ------ | ---- | ----------- |
| **ML-IN** | 34 | feature metodologicamente admissível |
| **OUT-LEAKAGE** | 5 | proximidade com acompanhamento/desfecho |
| **OUT-TEMPORAL** | 5 | mistura antecedente com acontecimento durante a gestação/acompanhamento |
| **DESCRITIVA** | 2 | caracterização; sem justificativa para feature principal |
| **SENSIBILIDADE** | 2 | fora do modelo principal; comparadas em sensibilidade (34 vs. 34+2) |

**Total: 34 + 5 + 5 + 2 + 2 = 48.**

**Leakage (excluídas do ML e do IV-DSS):** `faltou_consulta`,
`servicos_pre_natal`, `exames_pre_natal_completos`, `vacinas_em_dia`,
`avaliacao_pre_natal`. Descrevem a própria trajetória, experiência ou adesão ao
pré-natal e podem aproximar-se indevidamente do desfecho. **Decisão fechada.**

**Temporais (coletadas, fora do modelo principal):** `situacao_estudos_gestacao`,
`motivo_desemprego`, `impacto_gestacao_trabalho`, `mudanca_alimentacao_gestacao`,
`usa_suplementos`. Misturam condição antecedente com acontecimentos/comportamentos
durante a gestação/acompanhamento.

**Descritivas (fora do modelo principal):** `cuidados_vetores`,
`melhorias_desejadas`.

**Sensibilidade (fora do modelo principal):** `problema_saude_agua`,
`facil_acesso_saude`.

O IV-DSS é construído **exclusivamente** a partir de determinantes sociais e
condições de vulnerabilidade, nunca de informações do próprio acompanhamento.

### 4.8 Modelos de aprendizado de máquina

Regressão logística (baseline interpretável), Random Forest, XGBoost; rede neural
opcional (com justificativa experimental); K-means como análise exploratória
(apêndice). **[DECISÃO DO AUTOR]** sobre o ambiente de execução
(Python/scikit-learn).

### 4.9 Treinamento e validação

Divisão estratificada treino/teste; validação cruzada estratificada; seed fixa;
`class_weight` quando disponível. Preprocessing aprendido **somente** no
treinamento (via `Pipeline`/`ColumnTransformer`) para evitar leakage. Qualquer
oversampling ocorre **somente** após a separação e **exclusivamente** no
treinamento. **[DEPENDE DA IMPLEMENTAÇÃO]**.

### 4.10 Métricas

Precision, **Recall (atenção especial)**, F1, ROC-AUC, PR-AUC; Accuracy pode
aparecer mas **não** como critério principal. O Recall recebe atenção especial em
razão do objetivo experimental de avaliar a capacidade dos modelos de identificar
a maior proporção possível dos casos positivos sintéticos, sendo interpretado
conjuntamente com Precision, F1-score, PR-AUC, ROC-AUC e demais métricas — **não**
como critério único de escolha do modelo. Incluir matriz de confusão, comparação
entre modelos, distribuição das probabilidades e calibração quando aplicável.
**[DEPENDE DA IMPLEMENTAÇÃO]**.

### 4.11 Integração Flutter → API → ML

Contrato de entrada (`X_model`) e saída (probabilidade de descontinuidade), com a
resposta **não** apresentada como diagnóstico. **[DEPENDE DA IMPLEMENTAÇÃO]**.

### 4.12 Aspectos éticos e limitações

1. Dados sintéticos **≠** dados reais (sem validade externa clínica).
2. Estimativa **≠** diagnóstico médico.
3. Associação estatística **≠** causalidade.
4. O IV-DSS é um **índice experimental**, não validado; não é escala
   diagnóstica.
5. `faixa_renda` representa **renda familiar**, não renda per capita.
6. A normalização ordinal com **intervalos iguais** é operacional; não implica
   que as diferenças sociais entre níveis consecutivos sejam empiricamente
   iguais.
7. Neste trabalho, o limiar de menos de sete consultas é considerado uma
   **referência operacional preliminar**, fundamentada no mínimo assistencial
   estabelecido pela Portaria GM/MS nº 5.350/2024. A Portaria **não** define esse
   limiar como critério de abandono/descontinuidade, nem estabelece, nesse
   dispositivo, ajuste pela duração gestacional.
8. A `fonte_agua` isolada **não** avalia potabilidade nem adequação total.
9. `fossa_septica` é tratada como equivalente a `rede_coletora` sem distinguir
   qualidade/conservação.
10. O indicador alimentar (`deixou_de_comer_falta_dinheiro`) é **único** e **não**
    constitui EBIA/FIES nem classifica insegurança alimentar leve/moderada/grave.
11. O `adensamento_habitacional` usa moradores/dormitório sem considerar outros
    fatores de inadequação habitacional.
12. Os coeficientes do DGM são **parâmetros de simulação**, não efeitos
    epidemiológicos quantitativamente comprovados.
13. A proporção sintética planejada (~25%) **não** representa prevalência real.

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

Nesta versão, o IV-DSS é calculado em **módulo/etapa analítica independente** no
pipeline Python, não no aplicativo nem na API. **[DECISÃO DO AUTOR]** para
exibição futura no app.

Distinção explícita:

- **IV-DSS** = cálculo analítico independente a partir de `Q_full`; **não** entra
  no `ColumnTransformer`/`Pipeline` como feature do modelo principal.
- **Preprocessing de ML** = preparação de `X_model` para os classificadores
  (one-hot, multi-hot, tratamento de ordinais, booleanos, missing etc.).

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
3. BRASIL. Ministério da Saúde. **Portaria GM/MS nº 5.350, de 12 de setembro de
   2024.** Altera a Portaria de Consolidação GM/MS nº 3, de 28 de setembro de
   2017, para dispor sobre a Rede Alyne. Disponível em:
   https://bvsms.saude.gov.br/bvs/saudelegis/gm/2024/prt5350_13_09_2024.html.
4. World Health Organization. _WHO recommendations on antenatal care for a
   positive pregnancy experience_. 2016.
5. OECD/JRC. _Handbook on Constructing Composite Indicators: Methodology and
   User Guide_. 2008.
6. Ayres, J. R. C. M. et al. _O conceito de vulnerabilidade e as práticas de
   saúde: novas perspectivas e desafios_.
7. Fiocruz. _Determinantes Sociais da Saúde_ (portal DSS-Brasil).
8. IPEA. _Atlas da Vulnerabilidade Social (IVS)_. **[VALIDAR NA LITERATURA]**.
9. SEADE. _Índice Paulista de Vulnerabilidade Social (IPVS)_.
   **[VALIDAR NA LITERATURA]**.

---

## Apêndice — Decisões congeladas e pendentes

### 🔒 Decisões congeladas

1. Variável-alvo conceitual `descontinuou_pre_natal ∈ {0,1}`: referência
   normativa preliminar de **≥ 7 consultas** (Portaria GM/MS nº 5.350/2024,
   contexto **Rede Alyne**) para o desfecho real futuro — **não** a fórmula de
   geração do Y sintético.
2. Target = **referência operacional preliminar** de insuficiência/
   descontinuidade quantitativa de consultas — não definição clínica universal
   de "abandono".
3. Rótulo externo ao formulário (processo probabilístico / DGM).
4. População-alvo = gestantes que **já iniciaram** o pré-natal; **T0** = envio
   do questionário.
5. Leakage: 5 variáveis excluídas de features e do índice (decisão fechada).
6. Classificação 34 ML-IN / 5 OUT-LEAKAGE / 5 OUT-TEMPORAL / 2 DESCRITIVA /
   2 SENSIBILIDADE (total 48).
7. IV-DSS: pesos iguais (1/6), escala [0,1], média aritmética; escores por
   dimensão definidos.
8. IV-DSS descritivo (não é target, não gera Y, não é feature principal do ML).
9. Ordem de geração: `DSS → (IV-DSS) ∥ (fatores g_* → escore latente → Y)`.
10. Y sintético gerado **exclusivamente** por DGM probabilístico
    (`g_* → eta → sigmoid → Bernoulli`); **não** por contagem de consultas e
    **não** pela regra de sete consultas; IV-DSS **não** participa da geração.
11. ~5.000 registros, proporção sintética planejada ~25% (não "prevalência"),
    seed fixa `42`.
12. `recebe_beneficio_social`: ML-IN; **não** pontua no IV-DSS.
13. `acesso_ubs` e `cadastrada_ubs`: disponíveis ao ML; **não** pontuam no
    IV-DSS.
14. `usa_suplementos` e `mudanca_alimentacao_gestacao`: OUT-TEMPORAL.
15. `situacao_estudos_gestacao` e `impacto_gestacao_trabalho`: OUT-TEMPORAL.
16. `faixa_renda = nao_informar`: missing no IV-DSS (não imputar 0.5).
17. Limiar do adensamento habitacional: 3 níveis (≤2 / >2≤3 / >3).
18. IV-DSS calculado em módulo/etapa analítica independente no pipeline Python
    (não no preprocessing do ML).
19. Política de missing do IV-DSS: 6/6 dimensões válidas no índice principal;
    `iv_dss_parcial` (5/6) apenas auxiliar futuro.
20. Interpretação do IV-DSS: saída contínua [0,1]; sem pontos de corte
    absolutos; categorização, quando necessária, por **quantis amostrais** (não
    clínicos/epidemiológicos/validados).

### ⚠️ Decisões pendentes

- Ambiente de execução do pipeline (Python/scikit-learn) —
  **[DECISÃO DO AUTOR]**.
- Rede Neural como modelo (opcional, com justificativa experimental) —
  **[DECISÃO DO AUTOR]**.
- Normalização alternativa da `escolaridade` e demais análises de sensibilidade
  do IV-DSS — a definir na implementação.
- Título final do trabalho — **[DECISÃO DO AUTOR]**.
- Operacionalização longitudinal da variável-alvo ajustada pela duração
  gestacional (para uso futuro com dados reais) — **ainda exigirá fundamentação
  específica**; não adotada no experimento sintético.
