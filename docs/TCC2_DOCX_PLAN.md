# TCC2 — PLANO DO DOCUMENTO DEFINITIVO (MONOGRAFIA)

> **FASE 7A — ETAPA 1 · Inventário acadêmico e plano do TCC2 definitivo**
> Documento de planejamento. **NÃO** é a monografia. **NÃO** gera DOCX nesta etapa.
> Fonte técnica consolidada de referência: `docs/tcc2.md` (inalterada nesta etapa).

---

## 1. Inventário do TCC1

**Arquivo localizado:** `docs/TCC - Hárliton Martins.pdf` (≈ 4,1 MB) — texto extraído via `pdftotext` (394 linhas, UTF-8).

| Campo | Valor |
|---|---|
| **Título** | "Identificação do perfil de gestantes que **abandonam** o acompanhamento do pré-natal associado aos Determinantes Sociais da Saúde: uma abordagem utilizando Inteligência Artificial" |
| **Autor** | Antônio Hárliton Martins de Souza |
| **Orientador** | Prof. Mestre Benevaldo Pereira Gonçalves |
| **Instituição** | IFAM — Campus Manaus Zona Leste, Bacharelado em Engenharia de Software |
| **Ano** | 2025 |
| **Natureza** | **Projeto de TCC** (não é a monografia final) |

> **Denominação institucional:** no trabalho atual, usar a denominação oficial **Instituto Federal do Amazonas — Campus Manaus Zona Leste**. A sigla "IFAM CZL" **não foi identificada** no material local e **não deve** ser propagada no texto do TCC2 sem confirmação oficial. O conteúdo histórico do TCC1 permanece inalterado (inclusive qualquer grafia nele presente).

**Estrutura do TCC1** (sumário): 1 Introdução · 2 Problematização · 3 Justificativa · 4 Hipótese e Pergunta Norteadora (4.1/4.2) · 5 Objetivos (5.1/5.2) · 6 Referencial Teórico (6.1 DSS, 6.2 Saúde Materna e Pré-natal, 6.3 IA na Saúde) · 7 Metodologia (7.1–7.7) · 8 Cronograma · 9 Resultados Esperados · 10 Conclusão · Referências.

**Figuras/tabelas do TCC1:**
- Figura 1 — Modelo dos DSS proposto por Dahlgren e Whitehead (Fonte: CNDSS, 2008).
- Figura 2 — "Modelo de Rede Neural integrada ao aplicativo de coleta" (Fonte: Autoria Própria, 2025). **⚠ Não reutilizável** — a arquitetura de RNA foi abandonada no TCC2.
- Não há tabela formal no corpo (há apenas uma **sugestão** de tabela de variáveis ao final do PDF, com a anotação "Opção 1: dentro da seção 7.2 — ideal para TCC 1").

**Decisões do TCC1 que MUDARAM no TCC2** (essenciais para o capítulo de metodologia e para evitar contradição):

| # | No TCC1 | No TCC2 |
|---|---|---|
| 1 | "**abandonam**" (abandono) | "**descontinuidade**" do pré-natal |
| 2 | Rede Neural Artificial (Keras/TensorFlow) como classificador | **RandomForestClassifier** (scikit-learn) — modelo selecionado; também avaliados regressão logística e XGBoost |
| 3 | **K-means** como etapa de agrupamento | **não executado**; substituído pelo **IV-DSS** (índice descritivo experimental, calculado no pipeline Python, fora do app) |
| 4 | "Validar com conjunto de **dados reais**" | validação em **dataset sintético** (5000 registros, seed 42, ~25% positivos) |
| 5 | Coleta de dados reais via app em UBS | dados sintéticos via **DGM** (Data Generation Model) |
| 6 | Arquitetura **MVVM** + pacotes `drift`/`drift_sqflite` | **flutter_modular + MobX**; **sqflite** com SQL puro (sem Drift/codegen) |
| 7 | ~13 variáveis (tabela sugerida) | **48 variáveis** em **6 dimensões DSS** (schema 1.13) |
| 8 | Métricas: acurácia, sensibilidade, especificidade, AUC-ROC | ROC-AUC, **PR-AUC**, **Brier**, calibração, sensibilidade metodológica, importância por permutação |
| 9 | Base de dados "robusta e atualizada" | base **sintética e congelada** (não há coleta real) |

> **Implicação:** a monografia definitiva deve reescrever introdução/objetivos/hipótese a partir do escopo **experimental/sintético** já consolidado em `docs/tcc2.md`, e não herdar a narrativa "rede neural + dados reais" do TCC1.

---

## 2. Inventário bibliográfico local

**Localização:** `C:\Users\Harliton\Desktop\TCC\artigos\` (fora do repositório) — 13 PDFs, mais 1 documento institucional na raiz do TCC (`9789240107588-eng.pdf`).

> **⚠ PONTO DE PARTIDA — corpus NÃO suficiente.** O material local é um **ponto de partida** para o mapeamento inicial; **não** é considerado suficiente para a monografia definitiva. A pesquisa bibliográfica externa e a ampliação do corpus ocorrerão em etapa posterior (FASE 7A — ETAPA 2).

> **Três conjuntos relacionados, mas não idênticos.** (a) referências **citadas pelo TCC1**; (b) **PDFs disponíveis localmente**; (c) referências **efetivamente utilizáveis no TCC2**. Uma mesma fonte pode pertencer a mais de um conjunto; a consolidação final deve **evitar dupla contagem**.

Legenda: ✅ = metadata confirmada (extraída do PDF ou da lista de referências do TCC1); ⚠ = parcial; ❌ = NÃO CONFIRMADA (PDF sem texto extraível).

### 2.1 Artigos com metadata confirmada

| # | Referência (autores, ano, título, veículo) | DOI | Tema → capítulo |
|---|---|---|---|
| 1 | BUSS, P. M.; PELLEGRINI FILHO, A. **A saúde e seus determinantes sociais**. *Physis: Rev. Saúde Coletiva*, 17(1):77-93, 2007. ✅ | — | DSS → Fund. Teórica 2.2 |
| 2 | GARBOIS, J. A.; SODRÉ, F.; DALBELLO-ARAUJO, M. **Da noção de determinação social à de determinantes sociais da saúde**. *Saúde em Debate*, 41(112):63-76, 2017. ✅ | 10.1590/0103-1104201711206 | DSS (crítica conceitual) → Fund. Teórica 2.2 |
| 3 | **Fatores associados à não realização de pré-natal em município de grande porte**. *Rev. Saúde Pública*, 48(6), Dez 2014. ✅ (autor não legível na 1ª pág. — ⚠) | 10.1590/S0034-8910.2014048005283 | Pré-natal/abandono → Fund. Teórica 2.1 |
| 4 | SILVA, D. C. S. et al. **Fatores determinantes na realização do pré-natal no Brasil: uma investigação com dados da PNS**. 2023. ✅ (via refs. TCC1) | 10.34119/bjhrv7n10-033 | Pré-natal/DSS → Fund. Teórica 2.1/2.2 |
| 5 | LOPES, J. F. C. V. et al. **Impacto dos Determinantes Sociais no Estado Nutricional e na Assistência Pré-Natal de Gestantes no SUS**. *BJIHS*, 6(9):547-563, 2024. ✅ (via refs. TCC1) | 10.36557/2674-8169.2024v6n9p547-563 | DSS + pré-natal → Fund. Teórica 2.1/2.2 |
| 6 | ALVES, G. G.; TERAZIMA, S. S.; LIMA, J. F. P. K. **Inteligência artificial na saúde pública: potenciais e desafios no SUS**. *Asclepius Int. J. Sci. Health Sci.*, 4(3):262-267, 2025. ✅ (via refs. TCC1) | 10.70779/aijshs.v4i3.67 | IA na saúde → Fund. Teórica 2.4 |

### 2.2 Documentos institucionais / páginas web (metadata básica)

| # | Referência | Observação |
|---|---|---|
| 7 | IBES. **O que são os Determinantes Sociais da Saúde?** 31 mar. 2023. ✅ | Página institucional (divulgação) |
| 8 | BRASIL / FIOCRUZ. **O que é DSS — Determinantes Sociais da Saúde**. [portal]. ✅ | Página institucional; sem data precisa |
| 9 | BRASIL / FIOCRUZ. **OS DSS na OMS**. [portal]. ✅ | Página institucional; sem data precisa |
| 10 | BVS / MS. **OMS publica novo "Relatório Mundial sobre Determinantes Sociais da Equidade em Saúde"**. 2025. ✅ | Notícia institucional |

### 2.3 Documento institucional na raiz do TCC

| # | Referência | Observação |
|---|---|---|
| 11 | WHO. **World report on social determinants of health equity**. 2025. ISBN 9789240107588. ⚠ | Título confirmado via `pdftotext`; demais metadados (nº exato, licença) a confirmar |

### 2.4 Artigos NÃO CONFIRMADOS (PDF somente-imagem, sem texto extraível)

| # | Título (do nome do arquivo) | Status |
|---|---|---|
| 12 | Social Determinants of Health in prenatal care: a multidisciplinary view in Primary Health Care | ❌ NÃO CONFIRMADA |
| 13 | Social determinants of health of high-risk pregnant women during prenatal follow-up | ❌ NÃO CONFIRMADA |
| 14 | Determinantes sociais da saúde na consulta de enfermagem do pré-natal | ❌ NÃO CONFIRMADA |

> **Regra:** preservar estes 3 documentos com metadata **NÃO CONFIRMADA**. **Não inferir** autor, ano, DOI ou periódico a partir do nome do arquivo ou do título. A identificação (autores, ano, DOI, veículo) é **tarefa da próxima etapa bibliográfica** (FASE 7A — ETAPA 2), não uma decisão humana a ser tomada agora.

### 2.5 Referências citadas no TCC1 ainda sem PDF local (a recuperar/validar)

O TCC1 cita, mas **não há PDF correspondente no inventário local**:
- SOLAR, O.; IRWIN, A. *A conceptual framework for action on the social determinants of health*. WHO, 2010.
- CNDSS / BRASIL. *As causas sociais das iniquidades em saúde no Brasil*. Fiocruz, 2008.
- BRASIL. MS. *Estratégia de Saúde Digital para o Brasil 2020–2028*. 2020.
- BRASIL. MS. *Importância do Pré-Natal* (2016); *Pré-Natal* (2024b); *SISAB* (2024c).
- KAUFMAN, D. *Desmistificando a inteligência artificial*. 2022 (e-book).
- NASCIMENTO NETO, C. et al. *IA e novas tecnologias em saúde*. *BJD*, 6(2):9431–9445, 2020.
- NOGUEIRA, A. et al. *O uso da IA como ferramenta de apoio à gestão... Goiás*. *Rev. Cient. ESAP-GO*, 8:1-5, 2022.
- OMS. *Diminuindo diferenças* (2011); *Global strategy on digital health 2020–2025* (2020); *Maternal mortality* (2024); *Trends in maternal mortality 2000–2017* (2019).
- FIOCRUZ. *DSS – Determinantes Sociais da Saúde* (glossário). 2021.

> Essas referências são **legítimas** (foram usadas no TCC1 e constam em `docs/tcc2.md`), mas não possuem arquivo local. Devem ser **validadas** (URL/DOI/ano) antes da consolidação final das Referências.

---

## 3. Documentos técnicos disponíveis (evidência, não referência)

**Relatórios de fase (nível de projeto):**
- `FASE_5A_REPORT.md`, `FASE_5B_REPORT.md`, `FASE_5C_REPORT.md`, `FASE_5D_REPORT.md` (Flutter/DSS)
- `FASE_6A_REPORT.md` (67,7 KB — auditoria profunda / consolidação)
- `FLUTTER_API_INTEGRATION.md` (17,5 KB — integração Flutter ↔ API)
- `README.md` (raiz, 5,8 KB)

**API (FastAPI):**
- `api/FASE_4A_REPORT.md`, `api/FASE_4B_REPORT.md`, `api/FASE_4C_REPORT.md`, `api/FASE_4D_REPORT.md`
- `api/API_CONTRACT_V1.md` (contrato de integração)
- `api/README.md`

**IA / ML:**
- `ia/README.md`
- `ia/configs/*.yaml` (9 arquivos: schema 1.13, generator, preprocessing, training protocol, threshold, calibration, methodological sensitivity, interpretability, simulation)
- `ia/artifacts/metrics/*.json` (12 artefatos numéricos)
- `ia/artifacts/metrics/fase_*.md` (5 revisões analíticas: final, threshold, calibration/stability, methodological sensitivity, interpretability)
- `ia/artifacts/models/selected_model_v1_manifest.json` (manifesto do modelo selecionado)

**Documentação de planejamento:**
- `docs/planejamento_dataset_sintetico.md` (40,8 KB — projeto do DGM)
- `docs/tcc2.md` (51,0 KB — fonte técnica consolidada, INALTERADA)
- `docs/TCC2_UPDATE_PLAN.md` (23,4 KB — histórico de etapas)

> **Uso:** esses documentos são **fonte de evidência** para os capítulos 3–5 (metodologia, desenvolvimento, resultados). **Não** entram na lista de Referências como citações acadêmicas; podem ser citados como apêndice/memorial técnico se o orientador autorizar.

---

## 4. Figuras / tabelas potenciais

> **Não criar nesta etapa.** Lista de candidatos para a monografia (a selecionar/regenerar na ETAPA 2, com legenda e fonte ABNT).

> **Formatos de figura:** preferir **vetorial** (SVG/PDF/EPS) para gráficos e diagramas, **quando tecnicamente apropriado**; PNG/raster em **resolução adequada** é aceitável quando necessário; **screenshots** do aplicativo serão naturalmente raster. Não há exigência de que toda figura seja vetorial.

### 4.1 Figuras já geradas (PNG, em `ia/artifacts/figures/`)

**Modelo selecionado (essenciais):**
- `selected_model_roc_v1.png` — curva ROC
- `selected_model_pr_v1.png` — curva Precision-Recall
- `selected_model_confusion_matrix_v1.png` — matriz de confusão
- `selected_model_calibration_v1.png` — curva de calibração

**Interpretabilidade (importância por permutação):**
- `permutation_importance_pr_auc_top15_v1.png`
- `permutation_importance_structural_groups_v1.png`
- `permutation_importance_dgm_context_v1.png`
- `permutation_importance_by_fold_v1.png`

**Threshold / trade-off:**
- `oof_precision_recall_threshold_tradeoff_v1.png`
- `oof_f1_by_threshold_v1.png`, `oof_recall_by_threshold_v1.png`, `oof_precision_by_threshold_v1.png`, `oof_predicted_positive_rate_by_threshold_v1.png`

**Calibração / estabilidade:**
- `oof_calibration_global_v1.png`, `oof_calibration_by_fold_v1.png`, `oof_brier_by_fold_v1.png`, `oof_probability_by_fold_v1.png`, `oof_probability_distribution_by_class_v1.png`

**Sensibilidade metodológica:**
- `feature_set_sensitivity_metrics_v1.png`, `feature_set_sensitivity_threshold_metrics_v1.png`
- `outcome_rate_sensitivity_auc_v1.png`, `outcome_rate_sensitivity_brier_v1.png`, `outcome_rate_sensitivity_threshold_v1.png`

### 4.2 Figuras conceituais (a produzir ou adaptar)

- Modelo dos DSS de **Dahlgren & Whitehead** (já citado no TCC1, Figura 1; pode ser reutilizado com fonte correta).
- **Diagrama da arquitetura** Flutter → API → pipeline ML (material novo; alto valor didático).
- **Diagrama do DGM** (g_* → eta → sigmoid → Bernoulli) — descrever graficamente a geração sintética.
- **Estrutura do IV-DSS** (6 dimensões → 3 níveis de agregação).

### 4.3 Tabelas potenciais (a construir na ETAPA 2)

- T1 — Variáveis/dimensões DSS (48 variáveis, 6 dimensões) — evolução da "tabela sugerida" do TCC1.
- T2 — Comparação de modelos (ROC-AUC, PR-AUC, Brier por modelo: RF vs. RL vs. XGBoost).
- T3 — Desempenho do modelo selecionado no hold-out (TN/FP/FN/TP, recall/precisão/F1, limiar).
- T4 — Importância por permutação (top features).
- T5 — Sensibilidade metodológica (34 vs. 36 features; variação de taxa de desfecho).
- T6 — Cobertura do IV-DSS (4643 / 352 / 5 por nº de dimensões completas).

### 4.4 Screenshots do aplicativo (a capturar posteriormente do app real)

> **Não gerar agora.** Figuras a capturar do aplicativo em execução, na etapa de redação.

- Tela / questionário dos **DSS**
- Resultado **"Estimativa de acompanhamento"** (apresentação da estimativa experimental de propensão)
- **Home**
- **Gestação** (acompanhamento do pré-natal)
- **Plano de Parto**
- **Perfil**

> Screenshots são raster por natureza; não há exigência de vetorização.

---

## 5. Estrutura proposta da monografia

> Base: estrutura de `docs/tcc2.md`, avaliada quanto a **fusões / divisões / ordem / redundâncias / omissões**.

### 5.1 Elementos pré-textuais
Capa · Folha de rosto · Folha de aprovação · Dedicatória (opcional) · Agradecimentos (opcional) · Epígrafe (opcional) · **Resumo** · **Abstract** · Lista de figuras · Lista de tabelas · Lista de abreviaturas e siglas · Sumário.

### 5.2 Elementos textuais (proposta — com fusão e renumeração)

```
1  INTRODUÇÃO
   1.1 Contextualização
   1.2 Problema de pesquisa
   1.3 Justificativa
   1.4 Objetivos
       1.4.1 Objetivo geral
       1.4.2 Objetivos específicos
   1.5 Estrutura do trabalho (breve)
2  FUNDAMENTAÇÃO TEÓRICA
   2.1 Pré-natal e saúde materna
   2.2 Determinantes Sociais da Saúde
   2.3 Vulnerabilidade e índices compostos
   2.4 Aprendizado de máquina supervisionado
   2.5 Trabalhos relacionados
3  METODOLOGIA
   3.1 Tipo de pesquisa
   3.2 Determinantes Sociais da Saúde utilizados
   3.3 Construção do Índice de Vulnerabilidade dos DSS (IV-DSS)
   3.4 Modelagem dos dados
   3.5 População, T0 e variável-alvo
   3.6 Geração do dataset sintético
   3.7 Seleção de variáveis e controle de leakage
   3.8 Modelos de aprendizado de máquina
   3.9 Treinamento e validação
   3.10 Métricas
   3.11 Procedimento de validação da integração Flutter → API → ML
   3.12 Aspectos éticos e limitações
4  DESENVOLVIMENTO DA SOLUÇÃO
   4.1 Arquitetura
   4.2 Eixo 1 — Questionário dos DSS
   4.3 Eixo 2 — Módulo de acompanhamento do pré-natal
   4.4 Armazenamento local / offline
   4.5 Autenticação e estado atual do DSS
   4.6 Onde o IV-DSS é calculado
   4.7 Arquitetura futura proposta (evolução)
5  RESULTADOS E DISCUSSÃO
   5.1 Conjunto sintético e protocolo
   5.2 Comparação e seleção de modelos
   5.3 Desempenho do modelo selecionado (hold-out)
   5.4 Análise de threshold
   5.5 Calibração e estabilidade
   5.6 Sensibilidade metodológica
   5.7 Interpretabilidade
   5.8 IV-DSS
   5.9 Validação da implementação de software
   5.10 Discussão (inclui limitações do estudo)
6  CONCLUSÃO
   6.1 Síntese dos resultados
   6.2 Limitações do estudo
   6.3 Trabalhos futuros
REFERÊNCIAS
APÊNDICE A — Decisões metodológicas consolidadas e em aberto
APÊNDICE B — Fundamentação da escolha do título (se mantido)
```

> **Estrutura preferencial:** manter os **seis capítulos** acima (1 Introdução · 2 Fundamentação Teórica · 3 Metodologia · 4 Desenvolvimento da Solução · 5 Resultados e Discussão · 6 Conclusão), sem criar capítulos independentes desnecessários. As exigências estão atendidas explicitamente: **Trabalhos Relacionados** dentro do cap. 2 (2.5); **Discussão** claramente identificada no cap. 5 (5.10); **Limitações** claramente identificadas (3.12 e 5.10, retomadas em 6.2); **Trabalhos Futuros** na Conclusão (6.3).

### 5.3 Avaliação estrutural (fusões / divisões / ordem / redundâncias / omissões)

| Ponto | Diagnóstico | Recomendação |
|---|---|---|
| **Fusão** — `3 Objetivos` (tcc2.md) duplica `1.4 Objetivos` | Redundância: objetivos aparecem duas vezes | **Fundir** em `1.4 Objetivos`; eliminar capítulo 3 autônomo |
| **Relocação** — `1.5 Título — análise` | Conteúdo interno de fundamentação, não é capítulo de monografia | Mover para **Apêndice B** ou remover |
| **Renumeração** | Com a fusão do cap. 3, todos os capítulos posteriores deslocam −1 | Aplicar renumeração global (já refletida na proposta §5.2) |
| **Ordem** | Ordem lógica mantida (teoria → método → implementação → resultados) | Manter; não alterar |
| **Divisão** — Metodologia (12 subseções) | Capítulo denso, porém coeso | Manter íntegro; divisão em "Materiais" não agrega valor |
| **Omissão** — Hipótese | TCC1 tinha "Hipótese e Pergunta Norteadora"; tcc2.md reformula como problema experimental | Garantir que a pergunta de pesquisa esteja explícita em `1.2`; não reintroduzir "hipótese" formal se o desenho é descritivo/preditivo |
| **Omissão** — Cronograma | TCC1 tinha capítulo 8 (Cronograma) | Não aplicável à monografia (é elemento de projeto); omitir |

---

## 6. Distribuição aproximada de páginas (faixa-alvo ≈ 85–95 páginas)

> ABNT (fonte 12, espaçamento 1,5, margens 3/2 cm). **Estimativa, não obrigação rígida.** Crescimento decorre de conteúdo acadêmico real (figuras, tabelas, metodologia, resultados, discussão) — **sem preenchimento artificial**.

**Sobre a Introdução (distinção explícita):**
- O **texto principal de contextualização/introdução** corresponde a **≈ 1,5 página**.
- O **Capítulo 1 completo** pode chegar a **≈ 3–4 páginas**, considerando: contextualização, justificativa, problema, objetivos e organização do trabalho.

| Seção | Páginas | Observação |
|---|---|---|
| Elementos pré-textuais (capa → sumário) | ~6 | Resumo/Abstract ~1 p. cada |
| 1 Introdução (capítulo completo) | ~4 | texto principal ≈ 1,5 p. + justificativa/problema/objetivos/organização |
| 2 Fundamentação Teórica | ~18 | 5 subseções (inclui trabalhos relacionados) |
| 3 Metodologia | ~20 | 12 subseções, inclui IV-DSS e DGM |
| 4 Desenvolvimento da Solução | ~12 | arquitetura + 2 eixos + integração |
| 5 Resultados e Discussão | ~20 | 10 subseções, com figuras/tabelas |
| 6 Conclusão | ~3 | síntese + limitações + trabalhos futuros |
| Referências | ~5 | ABNT |
| Apêndices | ~3 | decisões + título |
| **Total indicativo** | **≈ 91** | dentro da faixa-alvo 85–95 |

> O volume concentra-se em Fundamentação Teórica (~18), Metodologia (~20) e Resultados/Discussão (~20), onde há evidência técnica real a reportar; Introdução permanece enxuta (texto principal ≈ 1,5 p.). O total indicativo de ≈ 91 páginas é **planejamento aproximado**, ajustável conforme o conteúdo efetivamente redigido — **sem preenchimento artificial**.

---

## 7. Matriz capítulo × fontes disponíveis

| Capítulo | Fonte técnica (evidência) | Fonte bibliográfica |
|---|---|---|
| 1 Introdução | `docs/tcc2.md` §1; TCC1 §1–3 | Buss & Pellegrini Filho (2007); OMS/CNDSS; [VALIDAR NA LITERATURA] |
| 2.1 Pré-natal | `docs/tcc2.md` §2.1 | Rev. Saúde Pública (2014); Silva et al. (2023); WHO maternal mortality |
| 2.2 DSS | `docs/tcc2.md` §2.2 | Buss & Pellegrini Filho (2007); Garbois et al. (2017); Solar & Irwin (2010); WHO 2025 (ISBN 9789240107588) |
| 2.3 Vulnerabilidade / índices | `docs/tcc2.md` §2.3 | **LACUNA** (ver §8) |
| 2.4 ML supervisionado | `docs/tcc2.md` §2.4 | Alves et al. (2025); Kaufman (2022); Nascimento Neto et al. (2020) |
| 2.5 Trabalhos relacionados | — | **LACUNA** (ver §8) — pesquisa a realizar na ETAPA 2 |
| 3 Metodologia | `docs/tcc2.md` §4; `docs/planejamento_dataset_sintetico.md`; `ia/configs/*.yaml` | **LACUNA** (DGM / dados sintéticos / índices compostos — ver §8) |
| 4 Desenvolvimento da Solução | `docs/tcc2.md` §5; `FLUTTER_API_INTEGRATION.md`; `api/API_CONTRACT_V1.md`; código `lib/` | Flutter/Modular/MobX (docs oficiais, se citadas) |
| 5 Resultados | `docs/tcc2.md` §6; `ia/artifacts/metrics/*.json`; `fase_*.md`; `figures/*.png` | — (evidência primária) |
| 6 Conclusão | `docs/tcc2.md` §7 | — |
| Referências | — | §2 desta planilha + validação de URLs/DOIs |

---

## 8. Lacunas bibliográficas

**Classificação A/B/C/D da bibliografia disponível:**
- **A — DSS / fundamento teórico:** Buss & Pellegrini Filho (2007); Garbois et al. (2017); Solar & Irwin (2010); CNDSS (2008); WHO 2025. **Cobertura OK.**
- **B — Pré-natal / saúde materna / descontinuidade:** Rev. Saúde Pública (2014); Silva et al. (2023); Lopes et al. (2024); WHO maternal mortality. **Cobertura OK**, mas com pouca literatura específica de 2024–2025 sobre **descontinuidade** (não apenas "não realização").
- **C — IA na saúde:** Alves et al. (2025); Kaufman (2022); Nascimento Neto et al. (2020); Nogueira (2022). **Cobertura suficiente**, porém genérica (IA em saúde, não ML preditivo para pré-natal).
- **D — Institucional/normativo:** Brasil MS; IBES; Fiocruz; OMS/WHO. **Cobertura OK.**

**Lacunas temáticas a suprir pela pesquisa bibliográfica externa (ETAPA 2):** o corpus local é apenas **ponto de partida**; as seguintes frentes precisam ser cobertas por busca externa em etapa posterior:
- **Continuidade / descontinuidade / adesão ao pré-natal**;
- **DSS aplicados à saúde materna**;
- **ML em saúde materna / pré-natal** (preditivo);
- **mHealth e aplicativos para gestantes**;
- **IA responsável / ética em aplicações de saúde**.

**Lacunas identificadas (ordenadas por criticidade):**

1. **Dados sintéticos / DGM** — não há referência que fundamente a metodologia de geração sintética. Recomenda-se citar literatura de *synthetic data generation* (ex.: CTGAN — Xu et al.; *Bayesian networks*; ou revisões de dados sintéticos em saúde). **Crítica** — sustenta o §3.6.
2. **Índices compostos** — o IV-DSS precisa de base metodológica (ex.: *OECD Handbook on Constructing Composite Indicators*, 2008). **Crítica** — sustenta o §3.3 / §2.3.
3. **Interpretabilidade / importância por permutação** — referência para permutation importance (Breiman, 2001 — *Random Forests*; Fisher, Rudin & Dominici, 2019). **Alta** — sustenta §5.7.
4. **Calibração probabilística** — referência para Brier score e *calibration-in-the-large* (ex.: Steyerberg, *Clinical Prediction Models*). **Alta** — sustenta §5.5.
5. **ML preditivo aplicado a pré-natal/abandono** — não há artigo específico de aprendizado de máquina preditivo para descontinuidade do pré-natal. **Média** — reforça originalidade, mas precisa de ancoragem.
6. **Metadata dos 3 PDFs somente-imagem** (itens 12–14 do §2.4) — autores/ano/DOI **NÃO CONFIRMADOS**. **Alta** — necessária para citação correta.
7. **Referências do TCC1 sem PDF local** (§2.5) — validar URL/DOI/ano antes da consolidação.

---

## 9. Lacunas de conteúdo (não-bibliográficas)

1. **Preparação de figuras (gráficos/diagramas)** — preferir **vetorial** (SVG/PDF/EPS) quando tecnicamente apropriado; **PNG/raster em resolução adequada** é aceitável quando necessário (não exigir vetorização universal). Avaliar regeneração na ETAPA 2.
2. **Tabelas formais** — nenhuma tabela ABNT existe ainda; todas as 6 tabelas do §4.3 precisam ser construídas com legenda/fonte.
3. **Diagrama de arquitetura e do DGM** — não existem; precisam ser desenhados.
4. **Resumo e Abstract** — não redigidos (dependem do texto final).
5. **Lista de abreviaturas** — consolidar (DSS, IV-DSS, ML, DGM, ROC-AUC, PR-AUC, T0, SUS, UBS, OMS/WHO, API, SQL, CV, RF, RL, XGBoost).
6. **Marcadores `[VALIDAR NA LITERATURA]`** — `docs/tcc2.md` §1.1 e §1.2 possuem marcações pendentes de validação bibliográfica.

---

## 10. Decisões do autor/orientador × pendências executáveis

### A) DECISÕES DO AUTOR / ORIENTADOR

| # | Decisão | Recomendação padrão |
|---|---|---|
| A1 | **Título final** da monografia | Definir com o orientador |
| A2 | **Estrutura final** (confirmar os seis capítulos da §5.2) | Manter proposta preferencial |
| A3 | **Fundir** "Objetivos" na Introdução (eliminar cap. 3 autônomo)? | Sim — seguir §5.2 |
| A4 | **Destino** da antiga seção "1.5 Título — análise" | Apêndice B (ou remover) |
| A5 | **Escopo do DOCX**: só elementos textuais ou incluir pré-textuais completos? | Sugestão: gerar tudo (pré + textual + pós) |
| A6 | **Tratamento** dos relatórios de fase (`FASE_*`) — apêndice/memorial técnico ou não citar? | Decidir com orientador |
| A7 | **Suprimir** menção residual a "Rede Neural" em qualquer trecho herdado do TCC1 | Sim — já consolidado em `tcc2.md` |

### B) PENDÊNCIAS EXECUTÁVEIS (tarefas — não são decisões humanas)

| # | Tarefa | Quando |
|---|---|---|
| B1 | **Recuperar metadata** (autores, ano, DOI, veículo) dos 3 PDFs somente-imagem (§2.4, itens 12–14) | ETAPA 2 (bibliográfica) |
| B2 | **Validar referências** (URL/DOI/ano) do TCC1 sem PDF local (§2.5) | ETAPA 2 |
| B3 | **Verificar normas IFAM/ABNT** (margens, fonte, espaçamento, modelo de capa) | antes do DOCX |
| B4 | **Preparar figuras** (gráficos/diagramas — vetorial quando apropriado) | ETAPA 2 |
| B5 | **Gerar screenshots** do aplicativo real (§4.4) | ETAPA 2 |
| B6 | **Pesquisar literatura adicional** (lacunas temáticas do §8) | ETAPA 2 |

> Regra de classificação: tarefas de **pesquisa/verificação** (recuperar metadata, validar referências, verificar normas, preparar figuras, gerar screenshots, pesquisar literatura) são **pendências executáveis** (B), não decisões do autor/orientador (A).

---

## 11. Próxima etapa recomendada

**FASE 7A — ETAPA 2 · Pesquisa, validação e matriz bibliográfica.**

Objetivo da etapa seguinte: suprir as lacunas bibliográficas do §8, validar referências e produzir a **matriz bibliográfica consolidada** que sustentará a redação.

1. **Pesquisa bibliográfica externa** — cobrir as lacunas temáticas (§8): continuidade/descontinuidade/adesão ao pré-natal; DSS aplicados à saúde materna; ML em saúde materna/pré-natal; mHealth/aplicativos para gestantes; IA responsável/ética em saúde.
2. **Identificar metadata** dos 3 PDFs somente-imagem (§2.4) — autores, ano, DOI, veículo.
3. **Validar referências** do TCC1 sem PDF local (§2.5) — URL/DOI/ano.
4. **Classificar e consolidar** o corpus em matriz capítulo × fonte (§7), evitando dupla contagem.
5. **Verificar normas IFAM/ABNT** (margens, fonte, espaçamento, modelo de capa) para o DOCX futuro.

> **Não iniciar a ETAPA 2 agora.** Aguardar aprovação explícita deste plano (ETAPA 1) e das decisões do §10.

---

*Fim do inventário e plano — FASE 7A · ETAPA 1.*
