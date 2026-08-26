# TCC2 — Estrutura e Metodologia (documento principal)

> **Status:** documento acadêmico principal do TCC2 (em construção).
> Não reproduz decisões do TCC1; o TCC1 (`docs/TCC - Hárliton Martins.pdf`) é
> usado apenas como referência estrutural e histórica.

> ⚠️ **Disclaimer (terminologia congelada):** o resultado produzido pelo modelo
> será uma estimativa estatística **experimental de probabilidade/propensão à
> descontinuidade do acompanhamento pré-natal** e **NÃO** deverá ser tratado
> como diagnóstico médico ou como certeza de abandono. Os dados sintéticos
> possuem finalidade experimental e de validação técnica, não representando
> prevalências, associações clínicas ou características reais da população de
> gestantes. Nenhuma associação estatística será apresentada como relação
> causal.

**Título provisório** — _"Estimativa da propensão à descontinuidade do
acompanhamento pré-natal a partir dos Determinantes Sociais da Saúde: uma
abordagem com aprendizado de máquina e um índice de vulnerabilidade"_.
**[DECISÃO DO AUTOR]** — ver análise de títulos na seção 1.5.

---

## 1 Introdução

### 1.1 Contextualização

O pré-natal é a principal estratégia de cuidado da gestação e de prevenção de
desfechos materno-infantis adversos **[VALIDAR NA LITERATURA]**. As
**Condições/Determinantes Sociais da Saúde (DSS)** — educação, trabalho e renda,
habitação, saneamento, acesso a serviços e alimentação — condicionam, de forma
documentada na literatura, o acesso e a continuidade desse acompanhamento
**[VALIDAR NA LITERATURA]**. Este trabalho desenvolve uma solução que **integra,
em uma mesma aplicação**, (i) a coleta estruturada dos DSS e (ii) um módulo de
acompanhamento do pré-natal, e aplica **aprendizado de máquina** sobre os DSS
para estimar a propensão à descontinuidade do pré-natal.

### 1.2 Problema de pesquisa

A descontinuidade do acompanhamento pré-natal está associada a piores desfechos
maternos e neonatais **[VALIDAR NA LITERATURA]**. O problema investigado é: _em
que medida uma abordagem experimental de aprendizado de máquina baseada nos DSS,
inicialmente avaliada com dados sintéticos, é capaz de produzir estimativas de
propensão à descontinuidade do acompanhamento pré-natal?_

### 1.3 Justificativa

O diferencial/proposta do sistema é **integrar, em uma mesma solução**, a coleta
de informações relacionadas aos Determinantes Sociais da Saúde e um módulo de
acompanhamento do pré-natal. **No estado atual do protótipo**, os dados desse
módulo permanecem em **persistência local**; como **evolução definida para o
trabalho**, prevê-se sua integração a uma **API** para persistência e
gerenciamento dos dados. O eixo DSS já consome via API a **estimativa
experimental por aprendizado de máquina**, enquanto o **IV-DSS** é calculado no
pipeline analítico Python, fora da interface e da API operacional. Assim, o
sistema e o pipeline analítico associado permitem tanto **caracterizar** a
vulnerabilidade social (via índice) quanto **estimar** a propensão à
descontinuidade (via modelo).

### 1.4 Objetivos

Ver seção 3.

### 1.5 Título — análise (fundamentação metodológica)

| Termo candidato   | Avaliação                                                                                                   |
| ----------------- | ----------------------------------------------------------------------------------------------------------- |
| "abandono"        | forte demais; sem definição operacional acessível/consensual; exige follow-up até o parto.                  |
| "descontinuidade" | fiel ao conceito investigado; no experimento atual o desfecho é sintético (gerado por mecanismo probabilístico), e a operacionalização longitudinal com dados reais ainda está em aberto (ver 4.5). |
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
Vulnerabilidade dos DSS (IV-DSS)** para caracterização dos perfis representados
no dataset sintético, e desenvolver um **modelo de aprendizado de máquina** —
treinado e avaliado sobre um **dataset sintético** — capaz de **estimar a
propensão** à **descontinuidade do acompanhamento pré-natal**.

### 3.2 Objetivos específicos

1. Modelar os DSS em um contrato de dados canônico, versionado e reproduzível.
2. Construir um **Índice de Vulnerabilidade dos DSS (IV-DSS)**, baseado nas
   dimensões investigadas, para caracterizar o nível de vulnerabilidade social
   dos perfis representados no dataset sintético.
3. Desenvolver o aplicativo Flutter com o questionário dos Determinantes Sociais
   da Saúde e o módulo de acompanhamento do pré-natal, integrando este último a
   uma API para persistência e gerenciamento dos dados.
4. Definir a variável-alvo experimental utilizada no estudo sintético,
   distinguindo-a da futura operacionalização longitudinal com dados reais.
5. Gerar um dataset sintético reproduzível (seed fixa), com dependências
   probabilísticas controladas e explicitamente definidas entre os DSS e o
   desfecho sintético.
6. Aplicar e avaliar técnicas de aprendizado de máquina para estimar a propensão
   à descontinuidade do acompanhamento pré-natal.
7. Avaliar os modelos por métricas adequadas a classes desbalanceadas.
8. Integrar o questionário dos Determinantes Sociais da Saúde ao serviço de API
   e ao modelo de aprendizado de máquina, estabelecendo o fluxo Flutter → API →
   ML para obtenção da estimativa experimental de propensão à descontinuidade do
   acompanhamento pré-natal.

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

### 4.3 Construção do Índice de Vulnerabilidade dos DSS (IV-DSS)

O **IV-DSS** é uma **medida agregada de caracterização** da vulnerabilidade
social dos perfis representados no dataset sintético. É um **índice descritivo
experimental**: não é um instrumento validado, nem escala diagnóstica, nem
índice epidemiologicamente validado. **Não é** variável-alvo e **não é** sinônimo
de risco de descontinuidade. A especificação técnica completa encontra-se em
`docs/planejamento_dataset_sintetico.md`.

#### 4.3.1 Definição conceitual

```text
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

#### 4.3.2 Estrutura (três níveis de agregação)

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
`> 2 e ≤ 3` = 0.50 · `> 3` = 1.00. Em análise de sensibilidade já executada,
comparou-se o critério binário `> 3` = 1; `≤ 3` = 0.

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
dimensões restantes). O `iv_dss_parcial` com cobertura 5/6 é calculado como
resultado auxiliar.

#### 4.3.7 Análises de sensibilidade

A agregação principal é **aritmética** (não usar geométrica como primeira
alternativa, pois dimensões podem assumir 0).

**Já executado:** a análise de sensibilidade do **adensamento habitacional**
comparou o critério em três níveis (`≤ 2` / `> 2 e ≤ 3` / `> 3`), usado no
índice principal, com o critério **binário** (`> 3`), como variante alternativa;
ambas as versões foram calculadas sobre os registros sintéticos.

**Ainda planejado (não executado):** normalização alternativa da `escolaridade`;
perturbações nos pesos; possível componente ocupacional; e agregação menos
compensatória justificável. O objetivo de toda análise de sensibilidade é testar
**robustez** — não escolher a posteriori a versão com "melhor resultado".

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

**Horizonte:** de T0 até o término da gestação.

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

Fluxo de geração (seed fixa, gerador versionado):

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
probabilístico experimental (DGM)**, cujos coeficientes são **parâmetros de
simulação** — não _odds ratios_ da literatura.

- **Fatores latentes Z:** cinco fatores internos do simulador (`Z_SES`,
  `Z_LAB`, `Z_TERR`, `Z_INFRA`, `Z_SERV`) gerados por distribuição normal
  multivariada com correlações moderadas. Esses fatores **não** vão ao Flutter,
  à API, ao ML nem ao IV-DSS.
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
  média das probabilidades verdadeiras ≈ proporção sintética planejada (~25%).
- **Não-determinismo controlado:** `faixa_renda = nao_informar` em pequena
  parcela dos registros — o simulador conhece a condição econômica verdadeira
  antes da ocultação; o modelo recebe apenas `nao_informar`.

O dataset foi **gerado** com as seguintes configurações: **5.000 registros**,
**proporção sintética planejada ~25%** de Y=1 (não chamar de "prevalência"),
seed fixa `42`. Cenários de sensibilidade futuros: ~15%, ~25%, ~35%.

### 4.7 Seleção de variáveis e controle de leakage

Nem todas as 48 respostas do questionário são utilizadas no modelo principal. A
classificação consolidada das 48 variáveis é:

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

O protocolo experimental avaliou **três** algoritmos de classificação
supervisionada:

1. **Regressão logística** — baseline interpretável, com regularização L2;
2. **Random Forest** — ensemble de árvores;
3. **XGBoost** — gradient boosting.

A proposta inicial do trabalho considerou, adicionalmente, técnicas como **redes
neurais** e análise de agrupamento exploratória (**K-means**). Essas abordagens,
entretanto, **não foram executadas** no experimento: o protocolo adotado
restringiu-se aos três modelos efetivamente implementados e comparados, levando
à seleção do **Random Forest** (seção 6.2). Essa evolução metodológica — de uma
proposta ampla para um protocolo fechado com três classificadores — é registrada
aqui de forma explícita, sem que as técnicas não executadas sejam descritas como
realizadas.

### 4.9 Treinamento e validação

O protocolo de treinamento e validação seguiu os seguintes procedimentos:

- **Divisão treino/teste:** o dataset sintético (5.000 registros) foi dividido
  em **80% treino (4.000)** e **20% teste (1.000)**, de forma **estratificada**
  em relação ao desfecho.
- **Validação cruzada:** 5-fold estratificado, com **folds congelados** e seed
  fixa.
- **Controle de desbalanceamento:** `class_weight` quando disponível (balanced
  na regressão logística; `balanced_subsample` no Random Forest; `scale_pos_weight`
  calculado exclusivamente a partir do y de cada fold no XGBoost).
- **Controle de leakage de preprocessing:** o pré-processamento foi aprendido
  **somente** sobre o treinamento (encodings one-hot/multi-hot, ordinais e
  booleanos, sem imputação, sem scaling e sem feature selection), e aplicado
  aos folds de validação e ao teste sem reutilizar estatísticas do teste.
- **Conjunto de teste:** o teste (1.000 registros) **não participou** de nenhuma
  decisão — nem do ajuste, nem da seleção de modelo.

O pré-processamento transformou as **34 variáveis brutas** de `X_model` em
**96 features** numéricas (`float64`), por codificação one-hot/multi-hot de
categorias nominais e multiselect, mapeamento de ordinais e normalização de
booleanos — sem imputação e sem escalonamento.

### 4.10 Métricas

A avaliação adotou métricas **independentes de threshold** e **dependentes de
threshold**:

- **Independentes de threshold:** ROC-AUC e PR-AUC (métricas primárias para
  seleção e comparação), além do Brier score e da curva de calibração.
- **Dependentes de threshold (referência 0.5):** accuracy, precision, recall,
  F1 e matriz de confusão.
- O **Recall** recebe atenção especial em razão do objetivo experimental de
  avaliar a capacidade dos modelos de identificar a maior proporção possível dos
  casos positivos sintéticos, sendo interpretado conjuntamente com as demais
  métricas — **não** como critério único de escolha do modelo.

A seleção do modelo foi orientada pela **PR-AUC média** na validação cruzada
(desempate por recall e F1), por ser mais adequada a cenários desbalanceados do
que a accuracy. Os resultados são apresentados na seção 6.

### 4.11 Integração Flutter → API → ML

O aplicativo integra o formulário DSS à API e ao modelo de ML: a resposta do
modelo é uma **probabilidade de descontinuidade**, apresentada **não** como
diagnóstico. A integração foi **implementada e validada** (seções 5.1 e 6.9).
Adicionalmente, a **infraestrutura de persistência** do backend foi submetida a
um procedimento de validação técnica próprio, contra **PostgreSQL real**, cobrindo
conexão, sessão, transação, rollback e encerramento de recursos (detalhado em
6.9).

> **Nota (continuidade com o trabalho predecessor).** O TCC predecessor (Rafael
> Moutinho Kanda, 2025) desenvolveu o aplicativo e os experimentos de aprendizado **não
> supervisionado** de forma **separada** (app de coleta + experimentos offline), sem
> integração operacional app ↔ API ↔ ML e sem backend persistente. O presente trabalho
> **integra** esses três elementos em um único fluxo operacional (Flutter → FastAPI →
> modelo serializado → resposta). Trata-se de uma diferença de **integração operacional**,
> não de correção do trabalho anterior. A estratégia de documentação visual (screenshots,
> diagramas, gráficos, tabelas e quadros) que sustenta essa continuidade está definida em
> `docs/TCC2_VISUAL_CONTINUITY_PLAN.md`.

### 4.12 Aspectos éticos e limitações

1. Dados sintéticos **≠** dados reais (sem validade externa clínica).
2. Estimativa **≠** diagnóstico médico.
3. Associação estatística **≠** causalidade.
4. O IV-DSS é um **índice descritivo experimental**, não validado; não é escala
   diagnóstica.
5. `faixa_renda` representa **renda familiar**, não renda per capita.
6. A normalização ordinal com **intervalos iguais** é operacional; não implica
   que as diferenças sociais entre níveis consecutivos sejam empiricamente
   iguais.
7. O mínimo de **≥ 7 consultas** (Portaria GM/MS nº 5.350/2024, contexto **Rede
   Alyne**) é uma **referência normativa contextual/preliminar** para a futura
   operacionalização longitudinal com dados reais. **Não** gera o Y sintético do
   experimento atual (que provém do DGM) e **não** é definição universal de
   abandono/descontinuidade; a Portaria também não estabelece, nesse dispositivo,
   ajuste pela duração gestacional.
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
14. O modelo selecionado apresentou **recall zero no limiar 0,5** (seção 6.3);
    isso é um resultado experimental e **não** sustenta interpretação de
    desempenho clínico.
15. **Persistência operacional ≠ uso científico.** Armazenar futuramente as
    respostas DSS em servidor para o funcionamento do aplicativo é uma finalidade
    **operacional**, que **não** autoriza automaticamente o uso desses dados como
    dataset de treinamento, validação científica ou publicação. Qualquer uso
    científico com dados reais deverá observar consentimento, privacidade/LGPD,
    metodologia e os requisitos éticos aplicáveis.

---

## 5 Desenvolvimento da aplicação

### 5.1 Arquitetura

A solução é composta por um **aplicativo móvel** (Flutter), um **backend**
(FastAPI) e um **pacote de aprendizado de máquina** (`meu_bebe_ml`, Python). O
aplicativo reúne dois eixos funcionais: (i) o **questionário DSS** com a
estimativa experimental; e (ii) o **acompanhamento do pré-natal**, com
armazenamento local.

O eixo DSS é **integrado de ponta a ponta** e segue o fluxo:

```text
Flutter
→ formulário DSS
→ FormularioData (contrato versionado)
→ RiskEstimateRepository
→ cliente HTTP dedicado
→ FastAPI (POST /api/v1/risk-estimate)
→ meu_bebe_ml (pipeline congelado)
→ RandomForestClassifier → predict_proba
→ probability (classe positiva)
→ resposta HTTP
→ Flutter (bottom sheet de resultado)
```

A API expõe os seguintes endpoints: `GET /health` (status do serviço),
`GET /ready` (disponibilidade do modelo) e `POST /api/v1/risk-estimate`
(estimativa). A API utiliza o pacote de ML como dependência, sem duplicar o
código do modelo no aplicativo.

A camada de apresentação é construída com **flutter_modular + MobX**, com
contratos de dados canônicos versionados.

O backend conta, adicionalmente, com uma **infraestrutura de persistência** já
**implementada e validada**, ainda que **não utilizada** pelo módulo de
acompanhamento — que permanece em **SQLite local** (seção 5.4). Essa
infraestrutura organiza o acesso ao banco de dados relacional em uma camada
própria da API, com ciclo de vida centralizado:

```text
                 ┌──────────────────────┐
                 │       Flutter        │
                 └──────────┬───────────┘
                            │
                         FastAPI
                            │
             ┌──────────────┴──────────────┐
             │                             │
             ▼                             ▼
     Fluxo DSS atual              Infraestrutura persistente
             │                             │
             ▼                             ▼
       meu_bebe_ml                   SQLAlchemy 2.x
             │                             │
             ▼                             ▼
      Random Forest                    psycopg 3
             │                             │
             ▼                             ▼
       probability                   PostgreSQL 16
```

O ramo da esquerda representa o **fluxo DSS atual** (já operacional). O ramo da
direita representa a **infraestrutura de persistência** disponível — e, nesta
etapa, **ainda não conectada** a entidades de acompanhamento: não há tabelas de
domínio nem persistência de consultas, exames, vacinas, medicamentos, gestações
ou planos de parto. Essa infraestrutura emprega os seguintes componentes:

| Componente | Tecnologia     | Função                                      |
| ---------- | -------------- | ------------------------------------------- |
| API        | FastAPI        | comunicação HTTP                            |
| ORM        | SQLAlchemy 2.x | acesso estruturado (síncrono) aos dados     |
| Driver     | psycopg 3      | comunicação com o PostgreSQL                |
| Banco      | PostgreSQL 16  | persistência central futura                 |
| Migrações  | Alembic        | controle da evolução do esquema             |

A arquitetura aqui descrita corresponde ao **estado implementado** — incluindo a
**infraestrutura de persistência** do backend, pronta para receber as entidades de
domínio em fases posteriores. Distingue-se, portanto, a **API DSS atual** (que
recebe a estimativa experimental, stateless) da futura **API CRUD do
acompanhamento pré-natal** — cuja infraestrutura de persistência **já existe**,
mas cujas entidades, autenticação e operações CRUD permanecem **ainda não
implementadas** (seção 5.7).

### 5.2 Eixo 1 — Questionário dos DSS

Formulário estruturado das seis dimensões; coleta informações usadas na
caracterização (IV-DSS) e na estimativa experimental do modelo. O resultado
apresentado no aplicativo é denominado **"Estimativa de acompanhamento"**,
contendo **probabilidade percentual**, **texto explicativo** e um **notice
metodológico** que esclarece o caráter experimental, a base em dados sintéticos
e a ausência de diagnóstico ou certeza. **Não** há tela de "risco" nem
classificação de risco.

### 5.3 Eixo 2 — Módulo de acompanhamento do pré-natal

O aplicativo integra, em uma mesma solução, o gerenciamento do acompanhamento
pré-natal, organizado em **quatro abas principais**: **Home**, **Gestação**,
**Parto** e **Perfil**.

- **Home** — reúne **Consultas e exames** (cadastro, listagem e exclusão
  local), **Minhas vacinas** (catálogo pré-cadastrado com controle de
  realização), **Meus medicamentos** (cadastro, listagem e exclusão local) e
  **Informações básicas** (conteúdo educativo estático, sem persistência).
- **Gestação** — agrega identificação da gestante, **idade gestacional (IG)**,
  **data provável do parto (DPP)**, local do pré-natal, profissional, consultas,
  exames e histórico obstétrico. IG e DPP são **calculadas em tempo de
  execução** a partir dos dados da gestação (data da última menstruação), e
  **não** são persistidas como valores independentes.
- **Parto** — representa um **plano de parto**, com seções de identificação,
  histórico, gestação atual, expectativas, parto, alívio da dor, nascimento,
  observações e resumo.
- **Perfil** — reúne **Meus Dados**, **Notificações**, **Configurações**,
  **Sobre o app** e **Sair**.

Conceitualmente, no plano de parto, **identificação**, **histórico** e
**gestação atual** são **dados de contexto** reutilizados de outras entidades; as
**preferências específicas do plano** são: **expectativas**, **momento do parto**,
**alívio da dor**, **nascimento** e **observações**. Essas informações representam
**preferências e expectativas**, e **não** o registro do desfecho real do parto.

### 5.4 Armazenamento local / offline

O módulo de acompanhamento **não depende de API** para armazenar essas
informações; funciona offline. Esta é uma característica arquitetural e
funcional — **não** um preditor do modelo.

> O módulo de acompanhamento é **funcionalidade da aplicação** e **não** faz
> parte diretamente do modelo de predição.

A persistência local é realizada com **SQLite** por meio do pacote **sqflite**,
com **SQL bruto** (sem Drift/codegen). O banco `meu_bebe.db` (versão 1) contém
**13 models** e **13 tabelas** locais.

> **Limitação relacional da implementação atual:** as tabelas locais **não**
> possuem relacionamentos formais (foreign keys) entre os registros de domínio.
> Embora a configuração do banco ative `PRAGMA foreign_keys`, nenhuma restrição
> de `FOREIGN KEY`/`REFERENCES` foi declarada. A implementação local assume
> implicitamente **uma única gestante/gestação por instalação/dispositivo**. Essa
> é uma **limitação da implementação atual**, e **não** uma decisão desejada para
> a arquitetura futura (seção 5.7).

A estratégia de evolução **aprovada** para a persistência do acompanhamento prevê
que a **API/backend** passe a ser a **fonte de verdade**, substituindo
progressivamente a dependência do SQLite local. A transição será **feature por
feature**: cada recurso migra da implementação local para uma implementação REST,
validada de ponta a ponta, e só então a API passa a ser a fonte de verdade
daquela feature. **Não** haverá, nesta etapa, migração automática dos registros
SQLite existentes, nem offline-first, sincronização ou cache distribuído
(seção 5.7).

> **Infraestrutura já implementada.** Embora o módulo de acompanhamento ainda
> utilize **SQLite local**, a **infraestrutura de persistência do backend** —
> PostgreSQL 16, SQLAlchemy 2.x (síncrono) e Alembic — **já foi implementada e
> validada** (seções 5.1 e 6.9). A troca do SQLite por essa infraestrutura
> permanece **planejada para etapas posteriores**, feature por feature, por meio
> da API. O SQLite continua sendo o **estado atual** da persistência no
> aplicativo.

### 5.5 Autenticação e estado atual do DSS

O aplicativo possui uma **tela visual de login**; entretanto, **não existe um
fluxo funcional completo de autenticação e sessão**. O botão "Entrar" atualmente
navega sem autenticar de fato; o botão "Criar nova conta" direciona ao
questionário DSS e **não** cria conta. Existe código parcial/legado de
autenticação (repositório de usuário, serviço de login e armazenamento de token),
mas ele **não** compõe um sistema real completo de autenticação/sessão.

O fluxo DSS atual é **stateless** do ponto de vista da API: **não** exige login,
**não** envia token e **não** possui identificador de usuária/gestante/gestação;
a API **não** persiste a avaliação.

> O item "Sair" da aba Perfil atualmente corresponde a navegação para a tela de
> login, e **não** a um logout autenticado real. Da mesma forma, **Notificações**
> e parte das **Configurações** ainda não representam subsistemas persistentes
> completos.

A arquitetura futura aprovada prevê **autenticação real** — cadastro, login,
sessão, token de acesso e token de renovação, com hash de senha moderno — e a
relação `USER ↔ GESTANTE`, com **autorização por ownership**. Distinguem-se
**autenticação** (quem é a usuária) de **autorização** (quais registros ela pode
acessar); o CPF, quando utilizado, pertence ao perfil da gestante e **não** é
chave primária nem login automático. Tudo isso permanece **planejado**, e **não**
implementado (seção 5.7).

### 5.6 Onde o IV-DSS é calculado

O IV-DSS é calculado em **etapa analítica independente** no pipeline Python
(`meu_bebe_ml`), e **não** no aplicativo nem na API — nesta versão. Distinção
explícita:

- **IV-DSS** = cálculo analítico independente a partir de `Q_full`; **não** entra
  no pré-processamento do modelo principal como feature.
- **Pré-processamento de ML** = preparação de `X_model` para os classificadores
  (one-hot, multi-hot, ordinais, booleanos).

### 5.7 Arquitetura futura aprovada (evolução planejada)

A arquitetura descrita até aqui corresponde ao **estado atual implementado** — o
módulo de acompanhamento do pré-natal persiste localmente em SQLite, e o fluxo
DSS utiliza a API apenas para a estimativa experimental, de forma **stateless**. A
seguir apresenta-se a **arquitetura futura aprovada**, **planejada mas ainda não
implementada**, que estabelece a direção de evolução da persistência e da
identidade do acompanhamento pré-natal.

Conceitualmente, o domínio evoluirá para as seguintes entidades e relacionamentos:

```text
USER 1 ─ 1 GESTANTE
GESTANTE 1 ─ N GESTACAO
GESTANTE 1 ─ 1 HISTORICO_OBSTETRICO
GESTACAO 1 ─ N CONSULTA
GESTACAO 1 ─ N EXAME
GESTACAO 1 ─ N MEDICACAO
GESTACAO 1 ─ N VACINA
GESTACAO 1 ─ 0..1 PLANO_DE_PARTO
GESTACAO 1 ─ N AVALIACAO_DSS
```

Nessa arquitetura, `USER` representa a **identidade/autenticação** e `GESTANTE` o
**perfil pessoal** (nome, nome social, data de nascimento, CPF — se utilizado — e
Cartão Nacional de Saúde). O **histórico obstétrico** atual (números agregados de
gravidezes, partos e abortos) **pertence à `GESTANTE`** e **não** representa uma
gestação anterior individual, sendo modelado como `HISTORICO_OBSTETRICO`. Cada
`GESTACAO` possui identidade própria, e as entidades do pré-natal (consultas,
exames, medicamentos, vacinas, plano de parto e avaliação DSS) ficam associadas à
gestação.

A persistência futura aprovada prevê **PostgreSQL** como banco, **SQLAlchemy 2.x**
como camada ORM e **Alembic** para migrações versionadas, com **integridade
referencial formal** (chaves estrangeiras), **timestamps** e identificadores
**UUID v4** para as novas entidades persistentes. **A infraestrutura de
persistência correspondente já foi implementada e validada** — PostgreSQL 16,
SQLAlchemy 2.x em modo **síncrono** e Alembic configurado (seções 5.1 e 6.9);
permanecem **futuras** a criação das **entidades de domínio**, as **migrations**
de domínio, a **autenticação** e o **CRUD** do acompanhamento. A adoção do modo
**síncrono** decorreu da adequação às características desta solução — endpoints
síncronos, ausência de demanda concreta por I/O concorrente intenso, menor
complexidade de implementação e maior simplicidade em transações, testes e
manutenção — sem que isso constitua juízo de que a abordagem assíncrona seja
inferior em geral. O **CPF**, quando utilizado, pertence ao perfil da gestante e
**não** é chave primária nem credencial de login automática.

A API/backend passará a ser a **fonte de verdade** do acompanhamento pré-natal,
com **autenticação** (cadastro, login e sessão) e **autorização por ownership**,
aplicada pelo caminho `USER → GESTANTE → GESTACAO → recurso`, para impedir o
acesso a registros de outra usuária. Distinguem-se, assim, **autenticação**
("quem é a usuária") de **autorização** ("quais registros ela pode acessar");
trata-se de **controle de propriedade/autorização**, e **não** de "multi-tenancy".

A transição do SQLite para a API será **incremental, feature por feature**: cada
recurso migra da implementação local para a implementação REST, validado de ponta
a ponta, e só então a API passa a ser a fonte de verdade daquela feature. **Não**
haverá, nesta etapa, migração automática dos registros SQLite existentes, nem
offline-first, sincronização ou cache distribuído; essas capacidades poderão ser
avaliadas apenas posteriormente.

> **Não implementado ainda.** Esta subseção registra uma arquitetura **aprovada e
> planejada**, e **não** deve ser lida como descrição do estado atual nem como
> resultado de implementação. O fluxo DSS (`POST /api/v1/risk-estimate`) permanece
> inalterado: stateless, sem autenticação e sem persistência operacional.

---

## 6 Resultados e Discussão

Os resultados são organizados em duas frentes distintas: (i) os **resultados do
experimento de aprendizado de máquina**; e (ii) a **validação da implementação de
software**.

### 6.1 Conjunto sintético e protocolo

O experimento utilizou um dataset sintético de **5.000 registros** (seed fixa
`42`), com proporção sintética planejada de ~25% de casos positivos. A divisão
estratificada resultou em **4.000 registros de treino** e **1.000 de teste**, com
razão de positivos preservada (~24,4%). O pré-processamento transformou as
**34 variáveis brutas** de `X_model` em **96 features** numéricas.

### 6.2 Comparação e seleção de modelos

Três modelos foram comparados por validação cruzada 5-fold (folds congelados,
somente sobre o treino), tendo como métrica primária a **PR-AUC média**:

| Modelo | PR-AUC média (CV) | ROC-AUC média (CV) |
| ------ | ----------------- | ------------------ |
| Regressão logística | 0,3370 | 0,6087 |
| **Random Forest** | **0,3508** | 0,6098 |
| XGBoost | 0,3346 | 0,6054 |

O **Random Forest** foi selecionado por apresentar a maior PR-AUC média, sem
empate numérico no critério de desempate (recall → F1). Esse é o **modelo
selecionado para o experimento técnico** realizado sobre dados sintéticos — não
um modelo validado clinicamente, nem superior para a população real, nem uma
ferramenta diagnóstica.

### 6.3 Desempenho do modelo selecionado (hold-out)

O modelo selecionado foi avaliado **uma única vez** no conjunto de teste
(1.000 registros), após a seleção. Resultados históricos:

| Métrica | Valor |
| ------- | ----- |
| ROC-AUC | ≈ 0,6174 |
| PR-AUC | ≈ 0,3356 |
| Brier Score | ≈ 0,1787 |

No limiar de decisão 0,5, a matriz de confusão foi:

| | Predito negativo | Predito positivo |
| --- | ---: | ---: |
| **Real negativo** | 755 (TN) | 1 (FP) |
| **Real positivo** | 244 (FN) | 0 (TP) |

Ou seja, **no threshold 0,5 houve recall zero para a classe positiva**: nenhum
dos 244 casos positivos do teste foi classificado como positivo. Esse resultado é
apresentado de forma explícita e **não** deve ser interpretado como desempenho
clínico. A AUC modesta, o recall zero no limiar 0,5 e a natureza sintética dos
dados impedem qualquer leitura de "bom desempenho" ou "capacidade preditiva
validada".

> **O threshold 0,5 não foi adotado operacionalmente.** O aplicativo **não**
> retorna classe, faixa de risco ou previsão de abandono; retorna somente a
> **probabilidade**.

### 6.4 Análise de threshold

Foi realizada uma análise exploratória de sensibilidade a diferentes limiares de
decisão (grade de 0,05 a 0,5), sobre as probabilidades out-of-fold do treino. As
probabilidades preditas concentraram-se em uma faixa restrita (aproximadamente
0,05 a 0,54, média ≈ 0,25), consistente com a baixa separação entre classes já
evidenciada pelas AUCs. **Nenhum threshold foi adotado operacionalmente**; a
análise serve apenas para caracterizar o comportamento do modelo.

### 6.5 Calibração e estabilidade

A calibração do modelo foi avaliada por três indicadores complementares, todos
sobre as previsões out-of-fold do treino: (i) o **Brier score**; (ii) a
**calibração em escala ampla** (calibration-in-the-large), comparando a
probabilidade média predita com a taxa observada de positivos; e (iii) a **curva
de calibração** (em bins), comparando probabilidade média predita com a fração
observada de positivos em cada bin.

- O **Brier score** médio foi ≈ 0,1789, ligeiramente inferior ao baseline
  (≈ 0,1846), uma melhora relativa de ≈ 3,1%. O Brier combina discriminação e
  calibração e, isoladamente, **não** é uma medida exclusiva de calibração.
- A **calibração em escala ampla** apresentou diferença pequena (≈ 0,0018) entre
  a probabilidade média predita (≈ 0,246) e a taxa observada (≈ 0,244),
  indicando boa calibração global.
- A **curva de calibração** apresentou desvios médios por bin da ordem de 0,015,
  com maiores desvios nos bins extremos (probabilidades muito baixas e muito
  altas).

A **estabilidade entre folds** foi avaliada pela dispersão das métricas: o desvio
padrão do Brier entre folds foi ≈ 0,0017, o da ROC-AUC ≈ 0,017 e o da PR-AUC
≈ 0,025 — uma variação moderada, sem indício de instabilidade grave entre os
folds.

### 6.6 Sensibilidade metodológica

A análise de sensibilidade comparou o modelo principal (`X_model`, 34 variáveis)
com uma variante estendida (`X_sens`, 36 variáveis), que acrescenta duas
variáveis de sensibilidade (`problema_saude_agua`, `facil_acesso_saude`). Essas
duas variáveis **não** fazem parte do modelo principal congelado; foram usadas
apenas para avaliar a estabilidade dos resultados à inclusão de informação
adicional.

Os resultados (validação cruzada, out-of-fold) indicaram que a inclusão das duas
variáveis **não alterou materialmente o desempenho** do modelo: a diferença média
de PR-AUC foi de ≈ −0,004 e a de ROC-AUC de ≈ −0,003, com variação de Brier
praticamente nula (≈ +0,0004). Trata-se de uma **conclusão estritamente
experimental**: os resultados do modelo principal mostram-se estáveis à adição
dessas duas variáveis, e este exercício **não** constitui validação clínica.

### 6.7 Interpretabilidade

A interpretabilidade foi avaliada por **importância por permutação** (out-of-fold,
múltiplas repetições, métrica PR-AUC). As variáveis com maior impacto na
permutação incluíram, em ordem aproximada, `dificuldades_saude`, `faixa_renda`,
`deixou_de_comer_falta_dinheiro`, `escolaridade`, `distancia_ubs` e `acesso_ubs`.

> A importância de variável **no modelo sintético** é uma propriedade do modelo
> treinado, e **não** deve ser lida como associação causal nem como determinante
> clinicamente comprovado de descontinuidade.

### 6.8 IV-DSS

O IV-DSS foi **implementado e calculado** sobre os 5.000 registros sintéticos,
com as seis dimensões (educação; trabalho e renda; saneamento; acesso aos
serviços de saúde; habitação; alimentação). O índice principal (cobertura 6/6)
foi calculável para **4.643 registros**; o índice parcial (cobertura 5/6), para
**352 registros**; e **5 registros** apresentaram cobertura inferior (4/6),
permanecendo não calculáveis. O IV-DSS é um **índice descritivo experimental de
vulnerabilidade social**, e permanece conceitualmente separado da probabilidade
do modelo: **IV-DSS ≠ P(Y) ≠ probability do Random Forest ≠ diagnóstico ≠
classificador**.

### 6.9 Validação da implementação de software

A integração **Flutter → FastAPI → IA → Flutter** foi validada de ponta a ponta
em **Android Emulator**. Trata-se de uma **validação de integração de software**
(smoke test), e **não** de validação clínica, validação externa do modelo ou
evidência científica sobre a população real.

Além disso, a **infraestrutura de persistência** do backend foi validada contra
**PostgreSQL real** (bancos locais `meu_bebe` e `meu_bebe_test`). Foram
verificados: a abertura de conexão; o teste de conectividade (`SELECT 1`); a
criação e o encerramento de sessões do SQLAlchemy; a execução de transação e o
respectivo **rollback**; o acesso do **Alembic** ao banco (com **zero revisions**
de domínio); a ausência de **tabelas residuais**; e o descarte explícito do
**engine** no encerramento da aplicação. A suíte de testes da API encerrou com
**202 testes aprovados** e **nenhum pulado**. Reitera-se que esses testes validam
a **infraestrutura de software**, e **não** a validade clínica do modelo de ML.

### 6.10 Discussão

Os resultados devem ser interpretados com cautela. A capacidade discriminativa
do modelo é **limitada** (ROC-AUC ≈ 0,62; PR-AUC ≈ 0,34), e o **recall zero no
threshold 0,5** evidencia que o modelo, sob um limiar de decisão convencional, não
consegue identificar os casos positivos sintéticos. Não há threshold operacional
adotado, e o produto apresenta apenas a probabilidade, evitando classificação
individual.

Esse **desempenho limitado é um resultado observado no experimento sintético**
e, por si só, descreve o comportamento do modelo sobre esses dados. Já a
**natureza sintética** dos dados e a **ausência de validação externa** implicam,
de forma distinta, que tais resultados **não representam desempenho clínico nem
generalizam para a população real** — não são a causa das métricas observadas. O
valor do trabalho, nesta etapa, está **menos** no desempenho preditivo e **mais**
na consolidação de um pipeline experimental reproduzível (contrato de dados,
geração controlada, protocolo de treinamento/validação, métricas de
desbalanceamento, calibração, sensibilidade, interpretabilidade e integração de
software) que poderá ser reutilizado em etapas futuras com dados reais.

A integração tecnológica — questionário DSS, modelo de ML e módulo de
acompanhamento pré-natal em uma única aplicação — constitui um resultado de
engenharia válido **independentemente** da validade clínica do modelo.

---

## 7 Conclusão

Este trabalho propôs estimar, a partir dos Determinantes Sociais da Saúde
coletados de forma estruturada, a propensão de gestantes à descontinuidade do
acompanhamento pré-natal, por meio de aprendizado de máquina, integrando a essa
função um módulo de acompanhamento do pré-natal.

Foram desenvolvidos: um contrato de dados canônico e versionado (schema 1.13, 6
dimensões, 48 variáveis); um **índice descritivo experimental de vulnerabilidade
(IV-DSS)**; um **dataset sintético reproduzível** (5.000 registros); um protocolo
de treinamento/validação com controle de leakage; a comparação de três modelos e
a seleção do **Random Forest**; análises de calibração, sensibilidade e
interpretabilidade; e a **integração de software** Flutter ↔ FastAPI ↔ IA,
validada de ponta a ponta.

O modelo selecionado apresentou desempenho discriminativo **limitado** e **recall
zero no limiar 0,5**, reforçando que os resultados são **experimentais** e não
constituem validação clínica. O aplicativo, por sua vez, entrega um diferencial
funcional ao integrar, em uma mesma solução, o questionário DSS, a estimativa
experimental e o acompanhamento do pré-natal (incluindo plano de parto), com
armazenamento local/offline.

Entre as limitações, destacam-se: uso de dados sintéticos (sem validade externa),
ausência de validação clínica, recall zero no limiar 0,5, autenticação ainda não
funcional, e a ausência de relacionamentos formais na persistência local (modelo
implicitamente monousuário).

O problema da descontinuidade do pré-natal **não** foi resolvido; este trabalho
estabeleceu, antes, uma base metodológica e tecnológica experimental que poderá
ser estendida a dados reais. Como trabalhos futuros, indicam-se: a
operacionalização longitudinal do desfecho com dados reais (fundamentada e
ajustada pela duração gestacional), a implementação das **entidades de domínio**,
da **autenticação** e do **CRUD** do acompanhamento pré-natal (seção 5.7) — cuja
infraestrutura de persistência **já foi implementada e validada** —, e a condução
de estudos com dados reais sob os devidos requisitos éticos e de consentimento.

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

## Apêndice — Decisões metodológicas consolidadas e em aberto

### Decisões consolidadas

1. **Experimento sintético (atual):** a variável-alvo `Y = descontinuou_pre_natal
   ∈ {0,1}` é gerada **exclusivamente** pelo DGM probabilístico
   (`g_* → eta → sigmoid → Bernoulli`); **não** é calculada por contagem de
   consultas nem pela regra de sete consultas.
2. **Estudo real futuro:** a operacionalização longitudinal do desfecho ainda
   deverá ser fundamentada especificamente; a Portaria GM/MS nº 5.350/2024 e o
   mínimo de **≥ 7 consultas** (contexto **Rede Alyne**) são apenas **referência
   normativa contextual/preliminar**, **não** uma definição universal automática
   de descontinuidade/abandono.
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
11. 5.000 registros, proporção sintética planejada ~25% (não "prevalência"),
    seed fixa `42`.
12. `recebe_beneficio_social`: ML-IN; **não** pontua no IV-DSS.
13. `acesso_ubs` e `cadastrada_ubs`: disponíveis ao ML; **não** pontuam no
    IV-DSS.
14. `usa_suplementos` e `mudanca_alimentacao_gestacao`: OUT-TEMPORAL.
15. `situacao_estudos_gestacao` e `impacto_gestacao_trabalho`: OUT-TEMPORAL.
16. `faixa_renda = nao_informar`: missing no IV-DSS (não imputar 0.5).
17. Limiar do adensamento habitacional: 3 níveis (≤2 / >2≤3 / >3).
18. IV-DSS calculado em etapa analítica independente no pipeline Python
    (não no pré-processamento do ML).
19. Política de missing do IV-DSS: 6/6 dimensões válidas no índice principal;
    `iv_dss_parcial` (5/6) apenas auxiliar.
20. Interpretação do IV-DSS: saída contínua [0,1]; sem pontos de corte
    absolutos; categorização, quando necessária, por **quantis amostrais** (não
    clínicos/epidemiológicos/validados).
21. Modelos avaliados no experimento: **regressão logística, Random Forest e
    XGBoost**; modelo selecionado: **Random Forest** (por PR-AUC média na CV,
    desempate recall → F1).
22. Pré-processamento: 34 variáveis brutas → 96 features, aprendido somente no
    treino (sem imputação, sem scaling, sem feature selection).
23. O conjunto de teste (1.000) não participou de nenhuma decisão.
24. Nenhum threshold operacional adotado; o aplicativo retorna somente
    probability.

### Decisões em aberto

- Título final do trabalho — **[DECISÃO DO AUTOR]**.
- Operacionalização longitudinal da variável-alvo ajustada pela duração
  gestacional (para uso futuro com dados reais) — **ainda exigirá fundamentação
  específica**; não adotada no experimento sintético.
- Normalização alternativa da `escolaridade` e demais análises de sensibilidade
  do IV-DSS — refinamentos adicionais a definir em etapas futuras.
- Implementação da arquitetura de persistência e autenticação **aprovada**
  (seção 5.7) — a ser executada em etapas posteriores; o modo de acesso do ORM
  (síncrono/assíncrono) e a forma física do plano de parto permanecem a definir.
