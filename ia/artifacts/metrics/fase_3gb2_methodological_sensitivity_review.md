# FASE 3G-B2 — Relatório Final de Revisão

**Análise de sensibilidade metodológica** (análise **secundária**), com duas
trilhas independentes, que **não substituem** o experimento principal das Fases
3F-A / 3F-B / 3G-A / 3G-B1 (que permanece congelado):

- **3G-B2A — sensibilidade ao conjunto de variáveis.** Compara o baseline
  `X_model` (34 variáveis, 96 features) com o conjunto de variáveis de
  sensibilidade `X_sens` (36 = `X_model` + `problema_saude_agua` +
  `facil_acesso_saude`, 98 features), usando o Random Forest congelado, sobre o
  OOF do TREINAMENTO (4000 registros) e os 5 folds congelados.

- **3G-B2B — sensibilidade à taxa média de probabilidade simulada.** Gera
  cenários sintéticos experimentais com taxa média de probabilidade alvo de
  15 % / 25 % / 35 % (**NÃO são prevalências reais**), alterando **apenas** o
  intercepto `alpha`. Realização secundária com números aleatórios comuns (CRN).

- Data (UTC): 2026-08-23
- Configuração: `methodological_sensitivity_v1.yaml` (v1.0)
- Modelo analisado: `random_forest` (selecionado na FASE 3F-B, **congelado**)
- Fonte: OOF do TREINAMENTO (4000 registros)
- Nenhum commit foi realizado. Aguardando revisão.

---

## 1. Escopo e caráter da análise

Esta é uma análise **secundária, descritiva e sem inferência estatística**. Ela
caracteriza a **diferença observada** entre o conjunto de variáveis de
sensibilidade e o baseline, e como os indicadores variam quando a **taxa média
de probabilidade simulada** é deslocada. Não há teste de hipótese nem p-valor em
nenhuma das duas trilhas.

Esta análise **não** seleciona modelo nem threshold, **não** recalibra (sem
Platt, isotonic ou `CalibratedClassifierCV`), **não** abre o TEST e **não**
modifica o modelo selecionado.

---

## 2. Pré-condições

| # | Item | Status |
|---|------|--------|
| 1 | Artefatos congelados (`data/`, `artifacts/`, configs de fases anteriores) inalterados no working tree? | ✅ SIM |
| 2 | Suíte de testes `pytest` — 382 esperados anteriormente, sem falhas? | ✅ SIM (406 passed após esta fase) |
| 3 | Hashes congelados conferem (dataset `36a0e342…`, dgm_audit `9185751f…`, split `55eeaf0f…`, folds `7b3cf1ff…`, OOF `1c08fa73…`, modelo `17db2db0…`)? | ✅ SIM |
| 4 | `selected_model == random_forest`? | ✅ SIM |
| 5 | RF congelado (n_estimators=500, gini, max_depth=None, min_samples_split=2, min_samples_leaf=1, max_features=sqrt, class_weight=balanced_subsample, random_state=42, n_jobs=-1)? | ✅ SIM |
| 6 | Config v1.0 com `selection.enabled=false`, `test_usage.allowed=false`, `recalibration.enabled=false`, targets `[0.15, 0.25, 0.35]`? | ✅ SIM |

> **Nota sobre o working tree.** A implementação da FASE 3G-B2 foi iniciada a
> partir de working tree limpo (`git status --short` vazio no momento anterior à
> implementação). Durante a implementação surgiram naturalmente arquivos novos da
> própria fase. A integridade dos artefatos congelados também foi verificada por
> hashes byte-a-byte (itens 1 e 3 desta tabela).

---

## 3. Conformidade com a regra de ouro (anti-leakage)

| # | Item | Status |
|---|------|--------|
| 7 | Usado exclusivamente o TREINAMENTO congelado (4000 registros)? | ✅ SIM |
| 8 | Os 1000 registros do TEST foram **não** abertos / **não** carregados? | ✅ SIM |
| 9 | Baseline `X_model` **não** retreinado — lido apenas de `cv_oof_predictions_v1.csv`? | ✅ SIM |
| 10 | Nenhuma seleção de modelo nem de threshold nesta fase? | ✅ SIM |
| 11 | Nenhuma recalibração (Platt / isotonic / `CalibratedClassifierCV`)? | ✅ SIM |
| 12 | CSV de desfechos sintéticos sem `U_sens` / `V_sens` / `p_true` (M_sim, leakage)? | ✅ SIM |
| 13 | Avaliação apenas com as probs OOF congeladas do Random Forest? | ✅ SIM |

---

## 4. Trilha B2A — sensibilidade ao conjunto de variáveis (X_model × X_sens)

`X_sens` acrescenta exatamente `problema_saude_agua` e `facil_acesso_saude`
(ambas `bool`, requeridas) ao baseline `X_model`, sem alterar nenhuma variável
existente (`X_model ⊂ X_sens`, verificado). O preprocessor de sensibilidade
expande 36 variáveis para 98 features (o baseline produz 96).

### 4.1 Métricas por fold — baseline `X_model` (OOF congelado)

| fold | ROC-AUC | PR-AUC | Brier | accuracy | balanced_accuracy | TN/FP/FN/TP @0.50 |
|------|---------|--------|-------|----------|-------------------|-------------------|
| 0 | 0.627311 | 0.390024 | 0.176545 | 0.7575 | 0.502564 | 605/0/194/1 |
| 1 | 0.606633 | 0.327662 | 0.179470 | 0.7550 | 0.499174 | 604/1/195/0 |
| 2 | 0.585145 | 0.340740 | 0.180348 | 0.75625 | 0.500000 | 605/0/195/0 |
| 3 | 0.624109 | 0.361498 | 0.177769 | 0.7575 | 0.505102 | 604/0/194/2 |
| 4 | 0.605956 | 0.334005 | 0.180230 | 0.7550 | 0.501723 | 603/1/195/1 |

### 4.2 Métricas por fold — sensibilidade `X_sens`

| fold | ROC-AUC | PR-AUC | Brier | accuracy | balanced_accuracy | TN/FP/FN/TP @0.50 |
|------|---------|--------|-------|----------|-------------------|-------------------|
| 0 | 0.614033 | 0.369405 | 0.177855 | 0.75625 | 0.500000 | 605/0/195/0 |
| 1 | 0.605853 | 0.325774 | 0.179586 | 0.75375 | 0.498347 | 603/2/195/0 |
| 2 | 0.586120 | 0.324930 | 0.180856 | 0.75625 | 0.500000 | 605/0/195/0 |
| 3 | 0.625224 | 0.373564 | 0.177332 | 0.7550 | 0.500000 | 604/0/196/0 |
| 4 | 0.602936 | 0.340854 | 0.180541 | 0.75625 | 0.502551 | 604/0/195/1 |

### 4.3 Diferença observada (X_sens − X_model) por métrica

| # | métrica | mean | std | min | max |
|---|---------|------|-----|-----|-----|
| 14 | roc_auc | −0.002998 | 0.005985 | −0.013278 | +0.001115 |
| 15 | pr_auc | −0.003881 | 0.014106 | −0.020620 | +0.012065 |
| 16 | brier | +0.000361 | 0.000637 | −0.000437 | +0.001310 |
| 17 | accuracy | −0.000750 | 0.001425 | −0.002500 | +0.001250 |
| 18 | precision @0.50 | −0.300000 | 0.670820 | −1.000000 | +0.500000 |
| 19 | recall @0.50 | −0.003066 | 0.004566 | −0.010204 | 0.000000 |
| 20 | specificity @0.50 | +0.000001 | 0.001170 | −0.001653 | +0.001656 |
| 21 | f1 @0.50 | −0.006071 | 0.009055 | −0.020202 | +0.000051 |
| 22 | balanced_accuracy | −0.001533 | 0.002357 | −0.005102 | +0.000828 |
| 23 | tn @0.50 | 0.0000 | 0.7071 | −1.0 | +1.0 |
| 24 | fp @0.50 | 0.0000 | 0.7071 | −1.0 | +1.0 |
| 25 | fn @0.50 | +0.6000 | 0.8944 | 0.0 | +2.0 |
| 26 | tp @0.50 | −0.6000 | 0.8944 | −2.0 | 0.0 |

**Leitura.** A **diferença observada** nas métricas contínuas teve médias
próximas de zero: delta ROC-AUC média −0.002998 (std 0.005985), delta PR-AUC
média −0.003881 (std 0.014106), delta Brier média +0.000361 (std 0.000637),
delta accuracy média −0.000750 (std 0.001425) e delta balanced_accuracy média
−0.001533 (std 0.002357). As métricas discretas @0.50 (precision, recall, F1 e
as contagens da matriz de confusão) apresentaram **diferença observada** com
amplitude maior (delta precision de −1.0 a +0.5; delta TP de −2 a 0): como as
probabilidades do Random Forest raramente ultrapassam 0.50, há pouquíssimos
positivos previstos por fold (TP de 0 a 2), de modo que uma mudança de uma única
classificação altera precision/F1 de forma descontínua (ex.: precision do fold 0
vai de 1.0 para 0.0, delta −1.0). Descrito como **diferença observada**, sem
interpretação de direção de efeito. Nenhum teste de hipótese foi aplicado.

---

## 5. Trilha B2B — sensibilidade à taxa média de probabilidade simulada

Realização secundária com **números aleatórios comuns** (CRN): o mesmo
`U_sens ~ Normal(0, 0.50)` (seed `noise_seed=4241`) e o mesmo
`V_sens ~ Uniform(0, 1)` (seed `outcome_seed=4242`) são reutilizados nos três
cenários, garantindo comparabilidade pareada. Apenas o intercepto `alpha` muda;
os efeitos congelados do DGM (`linear_component`), as transformações, as
interações, a forma logística e o desvio do ruído permanecem congelados.

| # | Item | Valor |
|---|------|-------|
| 27 | `noise_seed` / `outcome_seed` / `noise_sd` | 4241 / 4242 / 0.50 |
| 28 | `linear_component` (M_sim, congelado) | lido de `dgm_audit_v1.csv` (4000 TRAIN) |
| 29 | Monotonicidade `alpha_15 < alpha_25 < alpha_35` | ✅ True |
| 30 | Monotonicidade `p_15 <= p_25 <= p_35` (elemento a elemento) | ✅ True |
| 31 | Monotonicidade `Y_15 <= Y_25 <= Y_35` (elemento a elemento) | ✅ True |

### 5.1 Calibração do intercepto por cenário

| # | cenário | taxa média alvo | alpha | taxa média alcançada (mean p) | prevalência realizada na simulação |
|---|---------|-----------------|-------|-------------------------------|-------------------------------------|
| 32 | sensitivity_y_15 | 0.15 | −3.152795 | 0.1500000000 | 0.1450 |
| 33 | sensitivity_y_25 | 0.25 | −2.448528 | 0.2500000000 | 0.2412 |
| 34 | sensitivity_y_35 | 0.35 | −1.907312 | 0.3500000000 | 0.3410 |

- A **taxa média de probabilidade simulada** alcançada coincide com o alvo em
  todos os cenários (tolerância < 1e-10).
- A **prevalência realizada na simulação** (fração de `Y=1`) é reportada em
  separado e difere levemente da taxa média alvo (0.1450, 0.2412, 0.3410), como
  esperado para uma realização Bernoulli.
- `sensitivity_y_25` é o **controle de sensibilidade**, distinto do
  `primary_y_25` do experimento principal (que permanece congelado).

### 5.2 Métricas pooled OOF por cenário (probs OOF do RF congelado)

| # | métrica | y_15 | y_25 | y_35 |
|---|---------|------|------|------|
| 35 | prevalência realizada | 0.1450 | 0.2412 | 0.3410 |
| 36 | ROC-AUC (pooled OOF) | 0.6370 | 0.6390 | 0.6277 |
| 37 | PR-AUC (pooled OOF) | 0.2202 | 0.3461 | 0.4572 |
| 38 | Brier do modelo | 0.1308 | 0.1756 | 0.2245 |
| 39 | Brier baseline (prevalência constante) | 0.1240 | 0.1830 | 0.2247 |
| 40 | PR-AUC − prevalência | +0.0752 | +0.1048 | +0.1162 |
| 41 | PR-AUC / prevalência | 1.5187 | 1.4345 | 1.3408 |
| 42 | melhoria relativa do Brier | −0.0554 | +0.0407 | +0.0009 |

**Leitura.** Conforme a **taxa média de probabilidade simulada** aumenta
(0.15 → 0.25 → 0.35), a **PR-AUC pooled** passa de 0.2202 para 0.3461 e 0.4572
(acompanhando a elevação da própria prevalência), enquanto a **ROC-AUC pooled**
variou aproximadamente de 0.6277 a 0.6390 entre os cenários. O descritor
`PR-AUC − prevalência` passa de +0.0752 para +0.1048 e +0.1162, e o
`PR-AUC / prevalência` passa de 1.5187 para 1.4345 e 1.3408 — uma redução
observada do descritor relativo à taxa-base. O Brier do modelo passa de 0.1308
para 0.1756 e 0.2245; a **melhoria relativa do Brier** sobre o baseline é
−0.0554 no cenário 15 %, +0.0407 no cenário 25 % e +0.0009 no cenário 35 %.

### 5.3 Métricas por fold (exemplos de ROC-AUC / PR-AUC / Brier)

| cenário | fold | prevalência | ROC-AUC | PR-AUC | Brier |
|---------|------|-------------|---------|--------|-------|
| y_15 | 0 | 0.1388 | 0.6082 | 0.1844 | 0.1300 |
| y_15 | 1 | 0.1275 | 0.6626 | 0.2456 | 0.1202 |
| y_25 | 0 | 0.2338 | 0.6152 | 0.2916 | 0.1752 |
| y_25 | 3 | 0.2637 | 0.6679 | 0.4164 | 0.1831 |
| y_35 | 0 | 0.3275 | 0.6092 | 0.4130 | 0.2203 |
| y_35 | 1 | 0.3187 | 0.6699 | 0.4891 | 0.2087 |

| # | Item | Status |
|---|------|--------|
| 43 | 5 folds por cenário, métricas completas @0.50 + descritores relativos gravados? | ✅ SIM |

---

## 6. Testes e artefatos

| # | Item | Status |
|---|------|--------|
| 44 | 24 novos testes (`tests/test_methodological_sensitivity.py`) — config (selection/test/recalibration false, targets congelados), métricas por fold, delta descritivo, CRN determinístico, monotonicidade alpha/p/Y, DataFrame anti-leakage, descritores relativos, guarda anti-TEST, consistência com artefatos | ✅ 24 passed |
| 45 | Suíte completa `pytest` | ✅ **406 passed** (382 anteriores + 24 novos) |
| 46 | Inspeção (`inspect_methodological_sensitivity.py`) | ✅ todos os invariantes OK |
| 47 | Script principal (`run_methodological_sensitivity.py`) executado sem falhas | ✅ SIM |
| 48 | 5 figuras geradas (`feature_set_sensitivity_metrics_v1.png`, `feature_set_sensitivity_threshold_metrics_v1.png`, `outcome_rate_sensitivity_auc_v1.png`, `outcome_rate_sensitivity_brier_v1.png`, `outcome_rate_sensitivity_threshold_v1.png`) | ✅ SIM |
| 49 | CSV/JSON gerados (`cv_oof_predictions_x_sens_v1.csv`, `sensitivity_outcomes_v1.csv`, `feature_set_sensitivity_v1.csv`, `outcome_rate_sensitivity_v1.csv`, `methodological_sensitivity_v1.json`) | ✅ SIM |
| 50 | Nenhum commit realizado | ✅ SIM |

---

## 7. Confirmações explícitas

- ✅ **Nenhuma recalibração foi realizada.** `recalibration_performed = false`.
- ✅ **O TEST não foi usado.** `test_used = false`, `test_rows = 0`;
  `test_predictions_selected_v1.csv` e `final_test_results_v1.json` não foram
  abertos.
- ✅ **Nenhuma seleção de modelo nem de threshold ocorreu.**
  `selection_performed = false`; threshold de referência permanece 0.50.
- ✅ **O modelo selecionado permanece inalterado.** `model_modified = false`;
  `selected_model_v1.joblib` com hash `17db2db0…48ce883b`, idêntico ao manifest.
- ✅ **Nenhum retreino ou modificação do modelo principal
  `selected_model_v1.joblib` foi realizado.** A FASE 3G-B2 realizou fits
  secundários exclusivamente dentro dos folds de treinamento para as análises de
  sensibilidade (`X_sens` na trilha B2A; cenários 15/25/35 na trilha B2B), sem
  alterar o artefato principal (`model_modified = false`). O baseline `X_model`
  não foi retreinado — apenas as probs OOF congeladas de
  `cv_oof_predictions_v1.csv` foram lidas.
- ✅ **Nenhum M_sim vazou para o CSV de desfechos.** `sensitivity_outcomes_v1.csv`
  contém apenas `row_index, fold, y_sens_15, y_sens_25, y_sens_35`
  (`noise_or_latent_leaked_in_outcomes_csv = false`).
- ✅ **Monotonicidade verificada.** `alpha_15 < alpha_25 < alpha_35`;
  `p_15 <= p_25 <= p_35`; `Y_15 <= Y_25 <= Y_35` (elemento a elemento, mesmo
  `V_sens`).
- ✅ **Linguagem adotada:** "análise de sensibilidade metodológica", "cenário
  sintético experimental", "conjunto de variáveis de sensibilidade", "taxa média
  de probabilidade simulada", "prevalência realizada na simulação", "diferença
  observada". NUNCA "prevalência real", "efeito clínico" nem "melhor modelo".
- ✅ **Os resultados das Fases 3F-A / 3F-B / 3G-A / 3G-B1 permanecem congelados
  e inalterados.** Esta é uma análise secundária e não os substitui.
- ✅ **Nenhum teste de hipótese nem p-valor foi aplicado** em nenhuma das duas
  trilhas.
- ✅ **Nenhum commit foi realizado.**
- ⏸️ **Parado e aguardando revisão.**
