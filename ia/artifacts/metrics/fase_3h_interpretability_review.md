# FASE 3H — Relatório Final de Revisão

**Interpretabilidade pós-hoc do Random Forest por permutation importance OOF**
(análise **secundária, descritiva e NÃO causal**), respondendo: *"quais variáveis
brutas de `X_model` apresentam maior **importância preditiva** para o Random
Forest, medida pela **perda de desempenho** após permutação nas porções de
validação out-of-fold?"*.

- Data (UTC): 2026-08-23
- Configuração: `interpretability_v1.yaml` (v1.0)
- Modelo analisado: `random_forest` (selecionado na FASE 3F-B, **congelado**)
- Conjunto: `X_model` (34 variáveis brutas → 96 features); `X_sens` permanece secundário
- Fonte: exclusivamente OOF do TREINAMENTO (4000 registros, 5 folds congelados)
- Nenhum commit foi realizado. Aguardando revisão.

---

## 1. Escopo e caráter da análise

Esta é uma análise **pós-hoc, secundária e descritiva**, que caracteriza a
**dependência do desempenho do modelo** em relação a cada variável bruta de
`X_model`, em um **cenário sintético experimental**. A métrica primária de
importância é a **PR-AUC** (definição congelada `auc(recall, precision)`), e as
métricas secundárias são **ROC-AUC** e **Brier**.

A permutação ocorre **ANTES do preprocessing**, sobre as **variáveis brutas**
(ex.: `faixa_renda` é permutada como uma única variável; `dificuldades_saude` é
permutada como a lista bruta inteira; `beneficios_trabalho` como lista inteira).
Nunca se calcula importância dummy por dummy (por categoria codificada).

Esta análise **não**:
- usa o TEST (nem `test_predictions_selected_v1.csv`, nem `final_test_results_v1.json`);
- seleciona modelo, feature ou threshold;
- recalibra (sem Platt, isotonic ou `CalibratedClassifierCV`);
- faz tuning;
- usa `feature_importances_` (impurity/Gini) do Random Forest;
- calcula SHAP / PDP / ICE;
- avalia Logistic Regression ou XGBoost;
- calcula p-valor / teste de hipótese / intervalo de confiança;
- cria API nem altera o Flutter.

O experimento principal das Fases 3F-A / 3F-B / 3G-A / 3G-B1 / 3G-B2 permanece
**congelado e inalterado**.

---

## 2. Pré-condições

| # | Item | Status |
|---|------|--------|
| 1 | Artefatos congelados (`data/`, `artifacts/`, configs de fases anteriores) inalterados no working tree? | ✅ SIM |
| 2 | Suíte de testes `pytest` — 406 esperados anteriormente, sem falhas? | ✅ SIM (438 passed após esta fase) |
| 3 | Hashes congelados conferem (dataset `36a0e342…`, split `55eeaf0f…`, folds `7b3cf1ff…`, OOF `1c08fa73…`, modelo `17db2db0…`)? | ✅ SIM |
| 4 | `selected_model == random_forest`? | ✅ SIM |
| 5 | RF congelado (n_estimators=500, gini, max_depth=None, min_samples_split=2, min_samples_leaf=1, max_features=sqrt, class_weight=balanced_subsample, random_state=42, n_jobs=-1)? | ✅ SIM |
| 6 | Config v1.0 com `test_usage.allowed=false`, `model_selection.enabled=false`, `feature_selection.enabled=false`, `recalibration.enabled=false`, `n_repeats=20`, `seed=314159`, primária `pr_auc`, secundárias `[roc_auc, brier]`? | ✅ SIM |

> **Nota sobre o working tree.** A implementação da FASE 3H foi iniciada a
> partir de working tree limpo. Durante a implementação surgiram naturalmente
> arquivos novos da própria fase. A integridade dos artefatos congelados foi
> verificada por hashes byte-a-byte (itens 1 e 3 desta tabela) e re-verificada
> ao final da execução (guarda `input_hashes_unchanged`).

---

## 3. Conformidade com a regra de ouro (anti-leakage / anti-TEST)

| # | Item | Status |
|---|------|--------|
| 7 | Usado exclusivamente o TREINAMENTO congelado (4000 registros, Y0=3023, Y1=977)? | ✅ SIM |
| 8 | Os 1000 registros do TEST **não** foram abertos / carregados? | ✅ SIM |
| 9 | `test_predictions_selected_v1.csv` **não** foi carregado? | ✅ SIM |
| 10 | `final_test_results_v1.json` **não** foi usado para cálculos? | ✅ SIM |
| 11 | Nenhum row_index analisado fora do TRAIN congelado (`assert_no_test_rows`)? | ✅ SIM |
| 12 | Nenhuma seleção de modelo/feature/threshold, tuning ou recalibração? | ✅ SIM |
| 13 | Permutação sobre variáveis brutas, antes do preprocessing (multiselect como lista inteira)? | ✅ SIM |
| 14 | `feature_importances_` (impurity/Gini) **não** usado; SHAP **não** usado? | ✅ SIM |
| 15 | Fit do RF restrito aos `train_rows` de cada fold congelado (reprodução do OOF, nunca do TEST)? | ✅ SIM |

---

## 4. Reprodução exata do OOF (baseline)

Para cada fold congelado, o pipeline `X_model` + Random Forest congelado foi
re-fitado **uma única vez** sobre `train_rows` e usado para prever `val_rows`,
reproduzindo as probabilidades OOF congeladas. A classe positiva é obtida via
`classes_` (nunca hardcoded `[:, 1]`).

| # | Item | Valor |
|---|------|-------|
| 16 | `max |prob reconstruída − OOF congelada|` | **0.000e+00** (tolerância 1e-12) ✅ |
| 17 | mean-fold PR-AUC (média dos 5 folds) | **0.350786** ← métrica canônica da seleção |
| 18 | pooled OOF PR-AUC (4000 concatenados) | 0.344891 |
| 19 | mean-fold ROC-AUC | **0.609831** |
| 20 | pooled OOF ROC-AUC | 0.609684 |
| 21 | OOF Brier | 0.178872 |

| fold | n | PR-AUC | ROC-AUC | Brier |
|------|---|--------|---------|-------|
| 0 | 800 | 0.390024 | 0.627311 | 0.176545 |
| 1 | 800 | 0.327662 | 0.606633 | 0.179470 |
| 2 | 800 | 0.340740 | 0.585145 | 0.180348 |
| 3 | 800 | 0.361498 | 0.624109 | 0.177769 |
| 4 | 800 | 0.334005 | 0.605956 | 0.180230 |

A reprodução é **exata** (diferença máxima 0.0), coerente com a regra "PARE se
> 1e-12". Os baselines coincidem com os valores históricos das Fases 3F-B/3G-B1.

---

## 5. Ranking de importância preditiva (mean delta PR-AUC)

Convenção de sinal: **delta = baseline − permutado** para PR-AUC/ROC-AUC e
**delta = permutado − baseline** para Brier. **Positivo = deterioração** após
permutar. Valores negativos são permitidos (não truncados) e indicam flutuação
amostral. Agregação: 20 repeats dentro do fold → média; 5 fold means → média e
desvio (ddof=1) entre folds. Rank por `mean_delta_pr_auc` descendente, desempate
por `mean_delta_roc_auc` (depois ordem congelada). `*` = variável diretamente
utilizada no DGM sintético.

| rank | variável | mean delta PR-AUC | std entre folds | DGM |
|------|----------|-------------------|-----------------|-----|
| 1 | dificuldades_saude | **+0.040525** | 0.020435 | * |
| 2 | faixa_renda | **+0.025198** | 0.009799 | * |
| 3 | deixou_de_comer_falta_dinheiro | **+0.020443** | 0.010481 | * |
| 4 | escolaridade | **+0.010649** | 0.008445 | * |
| 5 | distancia_ubs | **+0.007810** | 0.010156 | * |
| 6 | acesso_ubs | +0.007672 | 0.003042 | |
| 7 | avaliacao_alimentacao | +0.005372 | 0.004240 | |
| 8 | seguranca_residencia | +0.005315 | 0.001749 | |
| 9 | alimentos_consumidos | +0.003593 | 0.007168 | |
| 10 | numero_comodos | +0.003457 | 0.004833 | |
| 11 | tipo_emprego | +0.003156 | 0.005249 | |
| 12 | fonte_agua | +0.001928 | 0.003486 | |
| 13 | tipo_moradia | +0.001812 | 0.005668 | |
| 14 | fez_curso_qualificacao_profissional | +0.001723 | 0.004399 | |
| 15 | recebe_beneficio_social | +0.001715 | 0.001179 | |
| 16 | entende_orientacoes_saude | +0.001569 | 0.002985 | |
| 17 | refeicoes_por_dia | +0.001516 | 0.001825 | |
| 18 | dificuldades_educacao | +0.001300 | 0.005314 | |
| 19 | trabalho_permite_pre_natal | +0.001161 | 0.003373 | * |
| 20 | numero_dormitorios | +0.000685 | 0.001994 | * |
| 21 | material_moradia | +0.000469 | 0.004941 | |
| 22 | frequencia_coleta_lixo | +0.000388 | 0.002973 | |
| 23 | esgotamento_sanitario | +0.000009 | 0.007597 | |
| 24 | numero_pessoas | −0.000201 | 0.001690 | * |
| 25 | itens_residencia | −0.000288 | 0.002532 | |
| 26 | estuda_atualmente | −0.000491 | 0.001573 | |
| 27 | tem_pausas_descanso | −0.000530 | 0.002300 | |
| 28 | empregado | −0.000949 | 0.001666 | * |
| 29 | fonte_alimentos | −0.001179 | 0.004225 | |
| 30 | interrupcoes_agua | −0.001228 | 0.001257 | |
| 31 | cadastrada_ubs | −0.001606 | 0.001758 | |
| 32 | beneficios_trabalho | −0.001717 | 0.004345 | |
| 33 | destino_lixo_sem_coleta | −0.002218 | 0.003516 | |
| 34 | ambiente_trabalho_seguro | −0.003185 | 0.002012 | |

**Leitura.** As variáveis com maior **importância preditiva** (maior **perda de
desempenho** após permutação) são `dificuldades_saude`, `faixa_renda`,
`deixou_de_comer_falta_dinheiro`, `escolaridade` e `distancia_ubs`. Várias
variáveis do meio/fim da tabela têm deltas próximos de zero ou negativos, o que,
neste **cenário sintético experimental**, indica pouca **dependência do
desempenho do modelo** em relação a elas (com flutuação amostral). Os valores
negativos **não foram truncados** e não recebem interpretação de "piora por
permutação" — são apenas **diferenças observadas** de ranking descritivo.

---

## 6. Contexto dos inputs diretos do DGM (diagnóstico descritivo)

O DGM sintético usa **9 variáveis** diretamente (validado contra a implementação
congelada; PARE em caso de divergência — não ocorreu): `escolaridade`,
`faixa_renda`, `distancia_ubs`, `dificuldades_saude`, `empregado`,
`trabalho_permite_pre_natal`, `deixou_de_comer_falta_dinheiro`, `numero_pessoas`,
`numero_dormitorios`.

| # | Item | Valor |
|---|------|-------|
| 22 | Inputs diretos do DGM validados | 9 (matching) ✅ |
| 23 | Overlap com o top-5 do ranking | **5 / 5** |
| 24 | Overlap com o top-10 do ranking | **5 / 10** |
| 25 | Posição de cada input direto no ranking | dificuldades_saude=1, faixa_renda=2, deixou_de_comer_falta_dinheiro=3, escolaridade=4, distancia_ubs=5, trabalho_permite_pre_natal=19, numero_dormitorios=20, numero_pessoas=24, empregado=28 |

**Leitura.** As cinco variáveis com maior **importância preditiva** são, todas,
**variáveis diretamente utilizadas no DGM sintético**. Isso é coerente com o
desenho do cenário (o DGM é a fonte da sinalização), mas **NÃO** confere caráter
causal: o DGM sintético é uma ferramenta de geração de dados, não uma "verdade"
clínica. `empregado` e `numero_pessoas`, apesar de serem inputs diretos, ocupam
posições baixas no ranking — o que é esperado quando outra variável correlacionada
(ex.: `faixa_renda`, `tipo_emprego`) já carrega informação redundante. `faixa_renda`
é derivada de renda latente com possível mascaramento, conforme documentado no
DGM; isso limita a leitura de sua importância.

---

## 7. Grupos estruturais (grouped permutation importance)

A permutação conjunta preserva as combinações internas de cada grupo (a mesma
permutação é aplicada a todas as colunas do grupo). NÃO há soma das importâncias
marginais: cada grupo é medido independentemente.

| grupo | membros | mean delta PR-AUC | std entre folds |
|-------|---------|-------------------|-----------------|
| WORK_STRUCTURAL | empregado, tipo_emprego, trabalho_permite_pre_natal, ambiente_trabalho_seguro, tem_pausas_descanso, beneficios_trabalho | **+0.012207** | 0.009723 |
| HOUSING_COUNTS | numero_pessoas, numero_comodos, numero_dormitorios | **+0.004513** | 0.008684 |
| WASTE_STRUCTURAL | frequencia_coleta_lixo, destino_lixo_sem_coleta | **+0.000717** | 0.004048 |

**Leitura.** O grupo `WORK_STRUCTURAL` apresenta a maior **dependência do
desempenho do modelo** entre os três grupos estruturais, seguido por
`HOUSING_COUNTS` e `WASTE_STRUCTURAL`. Trata-se de um **ranking descritivo** entre
grupos; os desvios entre folds são comparáveis ou maiores que as próprias médias,
o que reforça o caráter exploratório (sem teste de hipótese).

---

## 8. Limitações metodológicas

| # | Limitação |
|---|-----------|
| 26 | **Permutação marginal.** Quebra a associação entre a variável permutada e as demais, podendo gerar combinações pouco frequentes ou estruturalmente implausíveis (ex.: `empregado` × `tipo_emprego`). |
| 27 | **Preditores correlacionados.** Permutation importance pode subestimar ou distribuir importância entre preditores correlacionados/redundantes; uma variável não usada no DGM pode apresentar importância positiva por carregar informação correlacionada. |
| 28 | **Sem direção de efeito.** Permutation importance não informa direção de efeito, magnitude causal nem proteção/risco de categorias. |
| 29 | **Não causal.** É uma análise de **dependência do desempenho do modelo**, não de causalidade. |
| 30 | **Cenário sintético.** Sem interpretação epidemiológica/clínica; os resultados valem para o **cenário sintético experimental** deste projeto. |
| 31 | **`faixa_renda` derivada de renda latente.** Com possível mascaramento, conforme o DGM congelado. |
| 32 | **Sem p-valor.** Nenhum teste de hipótese, bootstrap ou intervalo de confiança foi aplicado. |

---

## 9. Testes e artefatos

| # | Item | Status |
|---|------|--------|
| 33 | 32 novos testes (`tests/test_interpretability.py`) — config (rejeita test/selection/recalibration habilitados), permutação de variáveis brutas e de grupos (preserva demais colunas, integridade de listas/null), determinismo SeedSequence, convenção de sinal dos deltas (negativos permitidos), agregação (mean repeats → fold; mean/std/min/max dos fold means), ranking com desempate, guarda anti-TEST, validação dos inputs diretos do DGM, não-referência a TEST/impurity/SHAP, consistência com artefatos | ✅ 32 passed |
| 34 | Suíte completa `pytest` | ✅ **438 passed** (406 anteriores + 32 novos) |
| 35 | Inspeção (`inspect_interpretability.py`) | ✅ todos os invariantes OK |
| 36 | Script principal (`run_interpretability_analysis.py`) executado sem falhas | ✅ SIM (477.2s) |
| 37 | 4 figuras geradas | ✅ SIM |
| 38 | CSVs gerados (repeats 3400, features 34, groups 18) | ✅ SIM |
| 39 | JSON gerado (`interpretability_v1.json`) | ✅ SIM |

### 9.1 Artefatos produzidos nesta fase

| Artefato | Caminho | Nota |
|----------|---------|------|
| Config | `configs/interpretability_v1.yaml` | v1.0; todas as flags proibidas = false |
| Módulo | `src/meu_bebe_ml/evaluation/interpretability.py` | funções puras (permutação, métricas, agregação, ranking, DGM, guarda anti-TEST) |
| Script principal | `scripts/run_interpretability_analysis.py` | valida congelados, fit por fold, permutações, agrega, grava CSV/JSON/4 figuras |
| Script de inspeção | `scripts/inspect_interpretability.py` | somente leitura |
| CSV repeats | `artifacts/metrics/permutation_importance_repeats_v1.csv` | 3400 linhas (34 × 5 × 20), 13 colunas |
| CSV features | `artifacts/metrics/permutation_importance_features_v1.csv` | 34 linhas, 14 colunas |
| CSV groups | `artifacts/metrics/permutation_importance_groups_v1.csv` | 18 linhas (3 × (5 folds + aggregate)), 6 colunas |
| JSON | `artifacts/metrics/interpretability_v1.json` | metadata/baseline_reproduction/feature_importance/structural_group_sensitivity/dgm_context/limitations/guards |
| Figuras (4) | `artifacts/figures/permutation_importance_*_v1.png` | top-15 PR-AUC, por fold, contexto DGM, grupos estruturais |

---

## 10. Confirmações explícitas

- ✅ **O TEST não foi usado.** `test_used = false`; `test_predictions_selected_v1.csv`
  e `final_test_results_v1.json` não foram abertos para cálculos.
- ✅ **Nenhuma seleção foi realizada.** `feature_selection_performed = false`;
  nenhum threshold, modelo ou feature foi selecionado; o threshold primário
  permanece 0.50.
- ✅ **Nenhuma recalibração nem tuning.** `recalibration_performed = false`,
  `tuning_performed = false`.
- ✅ **O modelo selecionado permanece inalterado.** `primary_model_modified = false`;
  `selected_model_v1.joblib` com hash `17db2db0…48ce883b`, idêntico ao manifest.
- ✅ **`feature_importances_` (impurity/Gini) NÃO foi usado** (`impurity_importance_used = false`).
- ✅ **SHAP NÃO foi usado** (`shap_used = false`); também não há PDP/ICE.
- ✅ **Nenhuma variável foi adicionada/removida.** A análise usa exatamente as 34
  variáveis de `X_model`; `X_sens` permanece secundária e não foi avaliada aqui.
- ✅ **Os inputs diretos do DGM foram validados** (9 variáveis, matching), sem
  correção silenciosa.
- ✅ **Reprodução OOF exata** (max diff 0.0, tolerância 1e-12).
- ✅ **Hashes dos artefatos congelados inalterados antes/depois** — guarda
  `input_hashes_unchanged` com todos `true`.
- ✅ **Nenhum M_sim / renda latente / p_true foi usado nesta análise**; apenas as
  variáveis brutas observadas de `X_model` e as probs OOF congeladas.
- ✅ **Linguagem adotada:** "importância preditiva", "permutation importance",
  "dependência do desempenho do modelo", "cenário sintético experimental",
  "variável diretamente utilizada no DGM sintético", "diferença observada",
  "ranking descritivo". NUNCA "fator causal", "causa de abandono", "efeito
  clínico", "risco real" nem "modelo explicável clinicamente".
- ✅ **Os resultados das Fases 3F-A / 3F-B / 3G-A / 3G-B1 / 3G-B2 permanecem
  congelados e inalterados.** Esta é uma análise secundária e não os substitui.
- ✅ **Nenhum teste de hipótese nem p-valor foi aplicado.**
- ✅ **Nenhuma API foi criada; o Flutter não foi alterado.**
- ✅ **Nenhum commit foi realizado.**
- ⏸️ **Parado e aguardando revisão.**
