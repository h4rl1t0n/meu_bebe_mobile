# TCC2 — PLANO DE CONTINUIDADE E APRESENTAÇÃO VISUAL

> **FASE 8A-DOC — ETAPA 2 · Alinhamento estrutural, visual e de continuidade com o TCC predecessor**
> Documento de **planejamento**. **NÃO** é a monografia. **NÃO** altera o DOCX mestre,
> **NÃO** altera código, **NÃO** reescreve capítulos, **NÃO** modifica resultados da IA e
> **NÃO** altera a arquitetura congelada na FASE 8A.
> Objetivo: **congelar** a linha de continuidade acadêmica/tecnológica em relação ao TCC
> predecessor, a estrutura narrativa dos capítulos e a estratégia de apresentação visual, para
> aplicação **progressiva** nas fases seguintes de redação.

---

## 6.1 Finalidade e escopo

**Finalidade.** Estabelecer, como referência estável e revisável, três eixos que serão aplicados
progressivamente na redação da monografia: (i) a **continuidade** entre o trabalho predecessor
(Rafael Moutinho Kanda, 2025) e o presente trabalho; (ii) a **estrutura narrativa** dos capítulos,
com a relação lógica Metodologia → Desenvolvimento → Resultados; e (iii) a **estratégia de
apresentação visual** (screenshots, diagramas, gráficos, tabelas, quadros e equações) do
aplicativo, da API e do modelo de ML, incluindo o cronograma até a entrega.

**Escopo (o que esta etapa FAZ):**
- Analisar a estrutura acadêmica e o padrão visual do TCC predecessor.
- Registrar a linha de **continuidade e evolução** (não de correção).
- Definir a estrutura narrativa recomendada e a relação lógica entre os capítulos.
- Inventariar (preliminarmente) figuras, screenshots, diagramas, gráficos, tabelas e quadros.
- Fixar regras para equações e para a linguagem científica.
- Definir a estratégia visual por componente (app / API / ML).
- Registrar o cronograma acadêmico até a entrega (05/11/2026).

**Escopo (o que esta etapa NÃO faz):**
- **NÃO** reescreve capítulos inteiros do TCC.
- **NÃO** altera código.
- **NÃO** altera o DOCX mestre.
- **NÃO** modifica resultados da IA.
- **NÃO** altera a arquitetura congelada na FASE 8A.
- **NÃO** cria figuras, screenshots, diagramas ou tabelas (apenas planeja e inventaria).
- **NÃO** promove o trabalho predecessor a fonte de fatos válidos automaticamente.

---

## 6.2 Análise estrutural do TCC predecessor

**Identificação do trabalho predecessor** (fonte: `docs/referencias/trabalhos_predecessores/TCC_Rafael_Moutinho_Kanda.pdf`, **somente leitura**):

| Campo | Valor |
|---|---|
| Autor | Rafael Moutinho Kanda |
| Título | "Uso da Inteligência Artificial para identificar o perfil de gestantes propensas a abandonar o pré-natal" |
| Instituição | IFAM — Campus Manaus Zona Leste, Bacharelado em Engenharia de Software |
| Orientador | Prof. Me. Benevaldo Pereira Gonçalves |
| Ano / aprovação | 2025 (aprovado em 08/01/2025) |
| Abordagem de ML | **Não supervisionada** (K-means, DBSCAN, GMM; com Autoencoder e SOMs como pré-processamento) |

**Estrutura de capítulos (5 capítulos):**

```
1 INTRODUÇÃO (1.1 Objetivo Geral · 1.2 Objetivos Específicos · 1.3 Justificativa)
2 REFERENCIAL TEÓRICO (Android · Flutter · Sklearn · Python · Machine Learning
   [supervisionado / não supervisionado / tipos de atributos] · IA na Saúde ·
   Gravidez e Pré-Natal · Gravidez e ML)
3 METODOLOGIA (3.1 Delimitação do Tema · 3.2 Escolha do Dataset · 3.3 Tratamento ·
   3.4 Escolha do Algoritmo · 3.5 Treinamento · 3.6 Teste · 3.7 Aperfeiçoamento ·
   3.8 Avaliação)
4 RESULTADOS (espelha a Metodologia: 4.1–4.8, com subdivisões por algoritmo)
5 CONSIDERAÇÕES FINAIS
REFERÊNCIAS
```

**Padrões estruturais observáveis:**
- **Capítulo 4 (Resultados) espelha a Metodologia seção a seção** — o relato dos resultados
  segue exatamente o ciclo de vida de ML apresentado no método (delimitação → dataset →
  tratamento → algoritmo → treinamento → teste → aperfeiçoamento → avaliação). Há forte
  rastreabilidade método↔resultado, mas pouca **Discussão** autônoma.
- **Metodologia = ciclo de vida de ML** (adaptado de Amershi et al., 2019), não uma
  metodologia científica de pesquisa (tipo de pesquisa, população, coleta, análise ética).
- **Fundamentação teórica** é prioritariamente **tecnológica** (Android, Flutter, Sklearn,
  Python) e, em segundo plano, conceitual (ML, IA na saúde, pré-natal).
- **Síntese crítica** (limitações e trabalhos futuros) concentrada no capítulo final, não diluída
  em discussão por seção.

**Padrão de apresentação visual do predecessor (quantidade observada):**

| Elemento | Quantidade | Natureza predominante |
|---|---|---|
| Figuras | 26 | 6 screenshots do app (Figuras 3–8), 2 diagramas de método (Figuras 1–2), 18 gráficos de ML (correlação, cotovelo/silhueta, AIC/BIC, dispersões PCA por algoritmo) |
| Quadros | 3 | Quadro 1 tipos de atributos; Quadro 2 trabalhos relacionados (comparativo); Quadro 3 dataset gerado |
| Tabelas | 10 | Dados contextuais (SISAB, idade), transformações (padronização, balanceamento, escalonamento), métricas (silhueta, ruídos, avaliação), agregações por cluster |
| Equações | 1 | Fórmula do número de neurônios do SOM (n = 5·√amostras) |

**Padrões normativos observáveis (a preservar como convenção, não como cópia):**
- Figuras rotuladas **"Figura N — Título"**, com **"Fonte: …"** e, quando aplicável, **"Nota: …"**.
- Tabelas rotuladas **"Tabela N — Título"** com **"Fonte: …"**; Quadros com moldura e
  **"Quadro N — Título"**.
- Screenshots compostos em **figuras multipartes** com sub-rótulos "a. …", "b. …".
- Fontes declaradas como **"Autoria Própria (ano)"** para material do próprio autor, e citação
  explícita para material de terceiros (ex.: "Fonte: Adaptado de …").

> **Restrição congelada.** O padrão acima é **referência de convenção** apenas. É **proibido**
> copiar trechos literalmente, reutilizar imagens do predecessor como autoria própria, ou
> transformar afirmações do predecessor em fatos válidos para este trabalho. A referência ao
> predecessor deve aparecer como **citação** (conforme a norma vigente), não como base factual.

---

## 6.3 Linha de continuidade e evolução (registro)

A relação com o trabalho predecessor é registrada como **continuidade e evolução**, nunca como
correção ou depreciação. A linha central é:

> O trabalho predecessor (2025) **construiu o aplicativo** de acompanhamento da gestação e
> **demonstrou a aplicabilidade** de algoritmos de aprendizado ao problema, com abordagem
> **não supervisionada** e dados **empíricos/aleatórios**; os experimentos foram conduzidos
> **separadamente** do aplicativo (coleta no app + experimentos offline), sem integração
> operacional e sem backend persistente. O presente trabalho **evolui** esse ponto de partida em
> quatro frentes: (1) questionário DSS **estruturado** (48 variáveis, 6 dimensões) substituindo a
> coleta ad hoc; (2) dataset **sintético controlado** (5000 registros, seed 42, DGM) substituindo a
> geração aleatória não controlada; (3) aprendizado **supervisionado** (LR/RF/XGBoost → RF
> selecionado) substituindo o agrupamento não supervisionado; e (4) **integração operacional**
> Flutter → FastAPI → ML, inexistente no predecessor.

**Como a continuidade será registrada no texto:**
- Na **Introdução** (contextualização/justificativa), como **evolução do estado da arte local** do
  próprio grupo de pesquisa, sem juízo de valor sobre o trabalho anterior.
- No **Capítulo 2** (trabalhos relacionados), o predecessor entra como **trabalho relacionado
  interno**, com a distinção explícita de abordagem (não supervisionado × supervisionado).
- Na **Metodologia**, quando for pertinente, apontar que a integração app↔API↔ML é o
  diferencial metodológico frente ao predecessor — **sem afirmar** que o TCC2 "resolve
  clinicamente" a limitação anterior (ver §6.14).

> **Regra de continuidade (congelada).** Toda menção ao predecessor deve (i) citá-lo
> corretamente; (ii) descrever a diferença como **evolução técnica/experimental**, não como
> correção; e (iii) **não** transferir automaticamente conclusões, imagens ou resultados do
> predecessor para este trabalho.

---

## 6.4 Quadro comparativo Rafael × TCC2 (diferenças)

| Dimensão | Rafael (2025, predecessor) | TCC2 (presente) |
|---|---|---|
| Objeto | Perfil de gestante que **abandona** o pré-natal | **Propensão/estimativa** de descontinuidade (experimental) |
| Paradigma de ML | **Não supervisionado** (K-means, DBSCAN, GMM; Autoencoder, SOMs) | **Supervisionado** (LR, RF, XGBoost → **RF selecionado**) |
| Rótulo/target | **Ausente** (dados não rotulados) | **Sintético** via DGM (g_* → η → sigmoid → Bernoulli) |
| Dados | Empíricos/aleatórios (biblioteca Random, 10.000 registros) | **Sintético controlado** (5000 registros, seed 42, ~25%) |
| Features | 7 (idade, escolaridade, renda, estado civil, gestações, partos, abortos) | **48 variáveis** em **6 dimensões DSS** (schema 1.13) |
| Aplicativo | Flutter/Android, MVVM, 7 módulos, sqflite/drift | **flutter_modular + MobX**, sqflite com SQL puro, DSS estruturado |
| Integração app↔ML | **Separada** (coleta no app + experimentos offline) | **Operacional**: Flutter → FastAPI → ML → Flutter |
| API / backend | **Inexistente** (não operacional) | **FastAPI** com endpoint real (`POST /api/v1/risk-estimate`); persistência PostgreSQL **planejada** |
| Índice DSS | Não possui | **IV-DSS** (índice descritivo experimental, calculado no pipeline Python) |
| Validação | Interna (silhueta, Dunn, Davies-Bouldin) | Hold-out + **ROC-AUC, PR-AUC, Brier**, calibração, importância por permutação, sensibilidade metodológica |
| Resultado central | Clusters dominados por **estado civil**; não resolveu o problema | Estimativa de propensão com protocolo **congelado e reprodutível** (sem pretensão clínica) |
| Status | Protótipo + experimentos exploratórios | Solução **integrada** (app + API + ML), com evolução de persistência aprovada e **não implementada** |

> Este quadro é **síntese de planejamento**. Na monografia, se usado, deverá ser **reescrito**
> (não copiado) e adaptado ao formato ABNT (Quadro), com fonte própria.

---

## 6.5 Estrutura narrativa recomendada dos capítulos

Mantém-se a estrutura **preferencial de seis capítulos** já aprovada no plano do documento
(`docs/TCC2_DOCX_PLAN.md` §5.2). **Não** se reduz para cinco capítulos apenas para imitar o
predecessor: o trabalho atual é mais amplo (metodologia científica + desenvolvimento +
resultados experimentais).

```
1 INTRODUÇÃO (Contextualização · Problema · Justificativa · Objetivos · Estrutura)
2 FUNDAMENTAÇÃO TEÓRICA (Pré-natal · DSS · Vulnerabilidade/índices · ML supervisionado · Trabalhos relacionados)
3 METODOLOGIA (Tipo de pesquisa · DSS · IV-DSS · Modelagem · População/T0/alvo · Dataset sintético ·
   Seleção de variáveis/leakage · Modelos · Treinamento/validação · Métricas · Validação da integração · Ética)
4 DESENVOLVIMENTO DA SOLUÇÃO (Arquitetura · Eixo 1 DSS · Eixo 2 acompanhamento · Armazenamento ·
   Autenticação · IV-DSS · Arquitetura futura aprovada)
5 RESULTADOS E DISCUSSÃO (Conjunto sintético · Comparação/seleção · Desempenho · Threshold ·
   Calibração · Sensibilidade · Interpretabilidade · IV-DSS · Validação de software · Discussão/limitações)
6 CONCLUSÃO (Síntese · Limitações · Trabalhos futuros)
REFERÊNCIAS
APÊNDICE A — Decisões metodológicas
APÊNDICE B — Fundamentação do título
```

**Diferenças narrativas frente ao predecessor (deliberadas):**
- O **Capítulo 3 (Metodologia)** é uma metodologia **científica** (tipo de pesquisa, população,
  coleta, ética, limitações), e **não** apenas o ciclo de vida de ML.
- O **Capítulo 4** é dedicado ao **desenvolvimento da solução** (arquitetura e eixos), separando
  "como foi construído" de "como foi avaliado" — distinção ausente no predecessor, onde o app
  era descrito dentro da metodologia.
- O **Capítulo 5** separa explicitamente **Resultados** de **Discussão** (5.10), com limitações
  identificadas — o predecessor concentrava tudo em "Considerações Finais".

---

## 6.6 Relação lógica Metodologia → Desenvolvimento → Resultados

A narrativa deve garantir **rastreabilidade** entre o que foi **planejado** (Metodologia), o que foi
**construído** (Desenvolvimento) e o que foi **medido** (Resultados), sem o espelhamento rígido
do predecessor — onde o capítulo de resultados repetia a estrutura da metodologia.

| Vínculo lógico | Direção da rastreabilidade |
|---|---|
| **3.6 Dataset sintético → 5.1 Conjunto sintético e protocolo** | O DGM descrito no método é o mesmo cujo protocolo (seed 42, 5000 registros, ~25%) é reportado em 5.1 |
| **3.4 Modelagem → 4.2/4.3 Eixos** | As 48 variáveis/6 dimensões do método materializam-se no questionário DSS do aplicativo |
| **3.3 IV-DSS → 4.6/5.8 IV-DSS** | O índice definido no método é implementado no pipeline (4.6) e reportado (5.8), **separado** da probabilidade do modelo |
| **3.8 Modelos → 5.2 Comparação e seleção** | Os três modelos (LR/RF/XGBoost) avaliados no método são os mesmos comparados em 5.2 |
| **3.9 Treinamento/validação → 5.3 Desempenho** | O protocolo de hold-out definido no método é o que gera as métricas de 5.3 |
| **3.11 Validação da integração → 5.9 Validação de software** | A integração Flutter→API→ML descrita no método é validada de ponta a ponta em 5.9 |
| **3.12 Ética/limitações → 5.10 Discussão → 6.2 Limitações** | As limitações metodológicas são retomadas na discussão e na conclusão |

> **Regra de rastreabilidade.** Cada resultado numérico do Capítulo 5 deve poder ser rastreado a
> uma subseção da Metodologia (Capítulo 3) e, quando aplicável, a um artefato técnico
> (`ia/artifacts/metrics/*.json`, `fase_*.md`). Nenhum número deve aparecer em Resultados sem
> que seu procedimento de obtenção esteja descrito no método.

---

## 6.7 Padrão de uso dos elementos visuais

Regras de **uso** (quando usar cada tipo e como rotular), aplicáveis a toda a monografia:

| Elemento | Usar quando | Rotulação / convenção |
|---|---|---|
| **Figura** | Imagem, gráfico, diagrama, fluxo, screenshot | "Figura N — Título"; "Fonte: …" abaixo; "Nota: …" se necessário |
| **Tabela** | Dados numéricos em linhas/colunas (métricas, comparações, contagens) | "Tabela N — Título" acima; "Fonte: …" abaixo; bordas horizontais (ABNT) |
| **Quadro** | Conteúdo **conceitual/comparativo** textual (tipos, decisões, trabalhos relacionados) | "Quadro N — Título"; moldura fechada; "Fonte: …" abaixo |
| **Equação** | Fórmula essencial que sustenta o método/resultado | Número sequencial à direita "(n)"; "onde:" após a equação |
| **Gráfico** | Visualização de desempenho/distribuição do ML | Submetido às mesmas regras de **Figura** |

**Distinção Tabela × Quadro (decisão):** conteúdo **numérico/tabular** → Tabela; conteúdo
**descritivo/comparativo** (texto, categorias, decisões) → Quadro. Não usar Tabela para texto e
vice-versa.

**Convenções de fonte:** material do próprio autor → "Autoria Própria (2026)"; material adaptado
de terceiro → "Adaptado de [citação]"; material de terceiro → "[citação]".

**Regras transversais:**
- Toda figura/tabela/quadro **deve** ser referenciada no texto antes de aparecer (ex.: "…conforme
  a Figura 3").
- Toda figura/tabela/quadro **deve** ter legenda completa e fonte.
- Preferir **vetorial** (SVG/PDF/EPS) para gráficos/diagramas quando apropriado; **raster** é
  aceitável para screenshots e quando necessário (sem exigir vetorização universal).
- Numeração **sequencial única** por tipo (Figura 1..n, Tabela 1..n, Quadro 1..n), independente
  do capítulo.

---

## 6.8 Inventário preliminar de figuras (quantidade)

> **Planejamento preliminar — não é compromisso rígido.** A seleção final ocorre na redação, com
> legenda e fonte ABNT. Nenhuma figura é criada nesta etapa.

**Quantidade preliminar por categoria:**

| Categoria | Quantidade | Status |
|---|---|---|
| Gráficos de ML já gerados (PNG) | **23** | gerados em `ia/artifacts/figures/` (seleção na redação) |
| Figuras conceituais/diagramas | **4** | a produzir (Dahlgren & Whitehead, arquitetura, DGM, IV-DSS) |
| Screenshots do aplicativo | **6** | a capturar do app real |
| **Total preliminar (bruto)** | **≈ 33** | sujeito a seleção/depuração |

> A quantidade **bruta** (≈ 33) **não** é meta a cumprir: espera-se **seleção** na redação,
> eliminando gráficos redundantes (ex.: múltiplas curvas de threshold que podem ser consolidadas
> em uma só figura). O número final será menor que o bruto, guiado por **valor didático**, não por
> volume. O predecessor usou 26 figuras; o presente trabalho, com mais resultados formais, tende a
> um total **comparável ou inferior**, consolidando variantes em figuras multipartes.

> **Critérios de seleção final.** A seleção será guiada por: **relevância acadêmica**,
> **não redundância**, **qualidade visual** e **capacidade de auxiliar a compreensão do leitor**.
> **Não existe meta obrigatória de quantidade de figuras.** Uma figura só deverá permanecer no
> TCC se contribuir efetivamente para a **explicação**, a **demonstração** ou a **discussão**.

---

## 6.9 Screenshots planejados

> A capturar do aplicativo em execução, na etapa de redação. **Screenshots são raster por natureza.**
> A quantidade abaixo é **planejamento conceitual**, não meta rígida.

| # | Tela | Função narrativa |
|---|---|---|
| S1 | Questionário dos DSS (formulário) | Ilustra o Eixo 1 — coleta estruturada (48 variáveis, 6 dimensões) |
| S2 | Resultado "Estimativa de acompanhamento" | Ilustra a **apresentação da estimativa experimental** (não diagnóstico) |
| S3 | Home | Ilustra a navegação geral do app |
| S4 | Gestação / acompanhamento da gestação | Ilustra o Eixo 2 — módulo de acompanhamento |
| S5 | Consultas e Exames | Ilustra o controle de consultas e exames do pré-natal |
| S6 | Vacinas e Medicamentos | Ilustra o controle de vacinas e medicamentos |
| S7 | Plano de Parto | Ilustra funcionalidade do módulo de acompanhamento |
| S8 | Perfil | Ilustra dados da gestante / cadastro |
| S9 | Autenticação / acesso | **DEPENDE DE IMPLEMENTAÇÃO** — só pode ser capturada/inserida após autenticação real implementada |

**Figuras compostas (recomendação):** S5 e S6 podem ser figuras multipartes:
- Figura X — (a) Consultas; (b) Exames.
- Figura Y — (a) Vacinas; (b) Medicamentos.

Caso a qualidade visual exija separação posteriormente, isso será decidido na redação final.

**S9 — autenticação (condicional):** só poderá ser capturada e inserida como **funcionalidade
concluída** depois que a autenticação real estiver implementada (ver arquitetura futura
aprovada, `docs/tcc2.md` §5.7). Até lá, permanece **prevista, mas não capturável** como estado atual.

**Convenções para screenshots:**
- Dispositivo/emulador e tema consistentes entre as capturas.
- **Sem dados pessoais reais** (usar dados fictícios; se necessário, mascarar campos sensíveis).
- Figuras **multipartes** ("a. …", "b. …") quando mais de uma tela ilustra o mesmo ponto.
- Fonte: "Autoria Própria (2026)".

---

## 6.10 Diagramas planejados

| # | Diagrama | Função narrativa | Formato preferido |
|---|---|---|---|
| D1 | **Arquitetura Flutter → FastAPI → ML** (fluxo de ponta a ponta) | Diferencial central do trabalho (integração operacional) | Vetorial |
| D2 | **DGM** (g_* → η → sigmoid → Bernoulli) | Explica a geração sintética (Metodologia 3.6) | Vetorial |
| D3 | **IV-DSS** (6 dimensões → níveis de agregação) | Explica o índice descritivo experimental | Vetorial |
| D4 | **Modelo dos DSS** (Dahlgren & Whitehead) | Fundamentação teórica (2.2), já citado no TCC1 | Reutilizar com fonte correta |
| D5 (opcional) | **Diagrama de domínio** da arquitetura futura (USER→GESTANTE→GESTACAO→recursos) | Ilustra 4.7 (arquitetura aprovada, **não implementada**) | Vetorial |
| D6 | **Arquitetura de persistência** do módulo de acompanhamento pré-natal (Flutter → FastAPI → camada de domínio/persistência → PostgreSQL) | Ilustra a persistência futura (arquitetura aprovada) | Vetorial |

> **Diagramas de arquitetura futura (D5 e D6).** Ambos referem-se à arquitetura **aprovada e
> ainda não implementada**. Antes da conclusão das fases técnicas correspondentes, **só** poderão
> aparecer identificados como **PLANEJADO** ou **ARQUITETURA FUTURA APROVADA**, nunca como
> resultado atual.
>
> O diagrama **D6** ("Arquitetura de persistência do módulo de acompanhamento pré-natal",
> Flutter → FastAPI → camada de domínio/persistência → PostgreSQL) está em estado **DEPENDE DE
> IMPLEMENTAÇÃO / ARQUITETURA APROVADA**. Somente depois que **PostgreSQL**, **SQLAlchemy**,
> **Alembic**, as **entidades**, os **endpoints** necessários e a **integração** correspondente
> estiverem efetivamente implementados e validados, D6 poderá ser apresentado como arquitetura
> **IMPLEMENTADA**. **Não antecipar implementação.**

---

## 6.11 Gráficos planejados (resultados ML)

Gráficos já gerados (PNG) em `ia/artifacts/figures/` — a **selecionar** na redação:

| Grupo | Gráficos candidatos | Função narrativa |
|---|---|---|
| Desempenho do modelo selecionado | ROC, Precision-Recall, matriz de confusão, calibração | Sustenta 5.3 (desempenho) e 5.5 (calibração) |
| Interpretabilidade | importância por permutação (top-15, grupos estruturais, contexto DGM, por fold) | Sustenta 5.7 |
| Threshold / trade-off | precisão-recall por limiar, F1/recall/precisão/taxa-positiva por limiar | Sustenta 5.4 (análise de threshold) |
| Calibração / estabilidade | calibração global e por fold, Brier por fold, probabilidade por fold e por classe | Sustenta 5.5 |
| Sensibilidade metodológica | métricas por conjunto de features, AUC/Brier/limiar por taxa de desfecho | Sustenta 5.6 |

**Convenções para gráficos:**
- Estilo visual **consistente** (mesma paleta, mesma fonte, mesmo tamanho de marcador) em todo
  o conjunto.
- Preferir **vetor** (regenerar como SVG/PDF/EPS) quando tecnicamente possível; PNG aceitável.
- **Consolidar** variantes redundantes em figuras multipartes (ex.: curvas de threshold por
  métrica em um só painel) para reduzir o total bruto.
- Cada gráfico **deve** vir acompanhado da métrica numérica correspondente em tabela (§6.12).

---

## 6.12 Tabelas e quadros planejados

**Tabelas (a construir — numérico/tabular):**

| # | Tabela | Função narrativa |
|---|---|---|
| T1 | Variáveis/dimensões DSS (48 variáveis, 6 dimensões) | Metodologia 3.2 (evolução da "tabela sugerida" do TCC1) |
| T2 | Comparação de modelos (ROC-AUC, PR-AUC, Brier: RF × RL × XGBoost) | Resultados 5.2 |
| T3 | Desempenho no hold-out (TN/FP/FN/TP, recall/precisão/F1, limiar) | Resultados 5.3 |
| T4 | Importância por permutação (top features) | Resultados 5.7 |
| T5 | Sensibilidade metodológica (34 × 36 features; variação de taxa de desfecho) | Resultados 5.6 |
| T6 | Cobertura do IV-DSS (4643 / 352 / 5 por nº de dimensões completas) | Resultados 5.8 |

**Quadros (a construir — conceitual/comparativo):**

| # | Quadro | Função narrativa |
|---|---|---|
| Q1 | Trabalhos relacionados (comparativo) | Fundamentação 2.5 (análogo ao Quadro 2 do predecessor, **reescrito**) |
| Q2 | Decisões metodológicas consolidadas × em aberto | Apêndice A |
| Q3 | Comparativo de evolução predecessor × TCC2 (opcional, derivado do §6.4) | Justificativa/Introdução ou Metodologia |

> Todos os valores das tabelas devem provir dos **artefatos numéricos** (`ia/artifacts/metrics/*.json`)
> e das **revisões analíticas** (`fase_*.md`); **não** inventar nem arredondar números fora dessas fontes.

---

## 6.13 Regras para equações

- **Numeração sequencial** à direita, no formato "(1)", "(2)", …, em toda a monografia.
- Após cada equação numerada, usar **"onde:"** para explicar cada símbolo.
- **Usar equação numerada apenas** quando ela **sustenta o método ou o resultado**; definições
  triviais podem ficar inline no texto.
- **Núcleo de equações previstas** (a selecionar):
  1. **DGM** — preditor linear η = Σ g_* e a transformação **η → sigmoid → Bernoulli** (sustenta
     a geração sintética, 3.6).
  2. **IV-DSS** — fórmula de agregação das 6 dimensões em níveis do índice (sustenta 3.3/5.8).
  3. **Métricas centrais** — Brier score e (opcionalmente) PR-AUC / ROC-AUC (sustentam 3.10/5.3).
- **Não** reproduzir equações de algoritmos não utilizados (ex.: número de neurônios do SOM —
  irrelevante no TCC2, que não usa SOMs). A única equação do predecessor é **exemplo de
  contexto**, não **modelo a imitar**.
- A Random Forest não possui fórmula fechada canônica; **não** forçar uma equação para o
  classificador. O foco das equações está no **DGM**, no **IV-DSS** e nas **métricas**.

> **Meta indicativa:** de 3 a 6 equações numeradas, todas essenciais; evitar equações decorativas.

---

## 6.14 Regras de linguagem e continuidade científica

**Terminologia congelada (não negociável):**
- O resultado do modelo é **"estimativa estatística experimental de probabilidade/propensão à
  descontinuidade do acompanhamento pré-natal"**. **NÃO** usar: diagnóstico, certeza, validação
  clínica, classificação de risco clínico, recomendação clínica, faixas de risco operacionais.
- O **IV-DSS** é um **índice descritivo experimental**, **separado** da probabilidade do modelo.
  **NÃO** apresentá-lo como escala diagnóstica nem fundi-lo com a estimativa do modelo.
- **NÃO** afirmar representatividade da população brasileira, **NÃO** afirmar prevalência real,
  **NÃO** fazer alegações causais, **NÃO** fazer classificação médica.

**Regras sobre o predecessor:**
- Tratar como **continuidade e evolução**, **não** como correção de trabalho ruim.
- **NÃO** copiar trechos literalmente; **NÃO** reutilizar imagens do predecessor como autoria
  própria; **NÃO** transformar afirmações do predecessor em fatos válidos para este trabalho.
- **NÃO** afirmar que o TCC2 **resolve clinicamente** a limitação do predecessor. O TCC2
  **avança técnica e experimentalmente** (dados controlados, aprendizado supervisionado,
  integração operacional), sem pretensão clínica.

**Outras regras:**
- **NÃO** reduzir a cinco capítulos apenas para imitar o predecessor.
- Distinguir rigorosamente no texto: **implementado hoje** × **planejado/aprovado** ×
  **experimental** × **não implementado** × **validação de software** (não confundir com
  validação clínica).
- Aplicar as normas ABNT/NBR vigentes citadas no plano do documento (NBR 14724:2024,
  NBR 6023:2025, NBR 10520:2023, NBR 6024:2012, NBR 6027:2012, NBR 6028:2021).

---

## 6.15 Estratégia de apresentação visual por componente

**Aplicativo (Flutter) — foco em screenshots e fluxo:**
- Screenshots reais (§6.9), com estilo consistente e sem dados pessoais.
- Diagrama **D1** (arquitetura) para situar a integração; **D5** (opcional) para a arquitetura
  futura, **claramente marcada como não implementada**.
- Priorizar **fluxos de uso** (o que a usuária vê ao responder o DSS e receber a estimativa), não
  listar telas exaustivamente.

**API (FastAPI) — foco em diagrama e contrato, não em dump de JSON:**
- Diagrama **D1** (sequência/fluxo Flutter→API→ML) é o elemento central.
- O contrato (`api/API_CONTRACT_V1.md`) é **fonte de evidência**; no texto, **não** reproduzir
  JSON bruto como figura. Descrever o endpoint e o schema em prosa ou em quadro/tabela se
  necessário.
- Representar o fluxo DSS como **stateless** (sem autenticação/persistência), fiel ao estado atual.

**ML (Random Forest / pipeline) — foco em gráficos + tabelas pareadas:**
- Gráficos selecionados (§6.11) **sempre acompanhados** da métrica numérica em tabela (§6.12).
- Diagramas **D2** (DGM) e **D3** (IV-DSS) para explicar geração sintética e índice.
- Reportar o modelo como **estimativa probabilística** (`predict_proba`), **não** como
  classificador clínico; evitar qualquer visual que sugira "risco" operacional.

---

## 6.16 Cronograma acadêmico até a entrega

> **Cronograma interno de referência.** Âncoras fixas: **feature freeze ≈ 20/10/2026**,
> **entrega 05/11/2026**, **apresentações 25, 26 e 27/11/2026**. Períodos intermediários são
> indicativos e ajustáveis, sem antecipar a redação dos capítulos.

> **Natureza gerencial (não acadêmica).** Este cronograma é **GERENCIAL/INTERNO**: serve
> para orientar a **execução**, a **redação** e a **preparação visual**. **NÃO** deve ser
> automaticamente inserido como conteúdo acadêmico da monografia; somente será incluído no
> TCC final caso exista **exigência acadêmica institucional** ou **orientação específica**.

| Período | Atividade / marco |
|---|---|
| Ago/2026 (atual) | Documentação e planejamento (FASE 7A/8A-DOC); congelamento da continuidade e da estratégia visual (este documento) |
| Ago–Set/2026 | Pesquisa bibliográfica externa (suprir lacunas do §8 do plano do documento); validação de referências |
| Set/2026 | Redação dos capítulos **1 (Introdução)** e **2 (Fundamentação Teórica)** |
| Set–Out/2026 | Redação dos capítulos **3 (Metodologia)** e **4 (Desenvolvimento)** |
| Out/2026 (até ~20/10) | Redação do capítulo **5 (Resultados e Discussão)**; **feature freeze** do código |
| Out/2026 | Preparação de figuras, screenshots, diagramas, gráficos, tabelas e quadros (seleção e legenda ABNT) |
| Out/2026 | Redação do capítulo **6 (Conclusão)**; Resumo/Abstract; lista de siglas |
| Final Out/2026 | Revisão ABNT/normas; montagem do DOCX mestre; revisão final |
| **05/11/2026** | **ENTREGA** da monografia |
| 05–24/11/2026 | Preparação da apresentação/defesa (slides a partir da estratégia visual deste plano) |
| **25–27/11/2026** | **APRESENTAÇÕES** / banca |

> **Marco de congelamento de conteúdo:** após **20/10/2026**, **não** introduzir novas
> funcionalidades, novas métricas nem alterar o contrato DSS congelado; apenas redação e
> preparação visual.

---

## 6.17 Checklist de conformidade

Marcar antes de qualquer fase de redação que consuma este plano:

- [ ] **Continuidade**: toda menção ao predecessor usa citação correta, tom de **evolução** (não correção), sem cópia literal e sem reutilização de imagens do predecessor.
- [ ] **Diferenças**: a distinção não supervisionado × supervisionado, e experimentação separada × integração operacional, está clara (Quadro do §6.4, reescrito se usado).
- [ ] **Estrutura**: seis capítulos mantidos (§6.5); **não** reduzir a cinco.
- [ ] **Rastreabilidade**: cada número do Capítulo 5 rastreável ao Capítulo 3 e a um artefato técnico.
- [ ] **Elementos visuais**: uso correto de Figura × Tabela × Quadro × Equação (§6.7), com legenda e fonte ABNT.
- [ ] **Screenshots**: sem dados pessoais; estilo consistente; fonte "Autoria Própria (2026)".
- [ ] **Diagramas**: D1/D2/D3 vetoriais; D5 (se usado) marcado como "não implementado".
- [ ] **Gráficos**: estilo consistente; pareados com tabelas; consolidação de variantes redundantes.
- [ ] **Equações**: 3–6 numeradas, essenciais, com "onde:"; sem equações decorativas.
- [ ] **Linguagem**: terminologia congelada respeitada (estimativa experimental; IV-DSS separado; sem diagnóstico/causalidade/risco clínico).
- [ ] **Cronograma**: feature freeze ≈ 20/10/2026; entrega 05/11/2026; apresentações 25–27/11/2026.
- [ ] **Integridade**: DOCX mestre inalterado; Capítulo 1, objetivos, resultados ML, contrato DSS e arquitetura FASE 8A inalterados.

---

*Fim do plano — FASE 8A-DOC · ETAPA 2.*
