# Plano de Atualização do `docs/tcc2.md` — FASE 6A-DOC

> **Status:** ETAPA 1 (AUDITORIA) concluída e ETAPA 2 (EDIÇÃO) concluída.
> **`docs/tcc2.md` foi atualizado** conforme as 52 instruções da ETAPA 2.
>
> Regras desta etapa:
> - ✅ ler o `docs/tcc2.md` **inteiro** (663 linhas, ~32,6 KB);
> - ✅ auditar contra o **estado real** do projeto (código Flutter, `api/`, `ia/`
>   e os artefatos congelados em `ia/artifacts/`);
> - ✅ produzir este mapa/plano;
> - ✅ ETAPA 2 — editar `docs/tcc2.md` de forma integrada (objetivos sem
>   status/emoji; metodologia implementado vs. proposto; seção 5 expandida;
>   seções 6 e 7 preenchidas; apêndice atualizado);
> - ⛔ **NÃO** fazer commit;
> - ⛔ **NÃO** inventar referências, autores, DOIs, citações ou dados estatísticos.

---

## 1. Estrutura auditada na ETAPA 1 (histórico)

> Esta seção registra o estado encontrado na **auditoria inicial (ETAPA 1)** e
> **não** representa a versão atual do `docs/tcc2.md` após a ETAPA 2.

| Bloco | Linhas (aprox.) | Conteúdo |
|-------|-----------------|----------|
| Cabeçalho + título provisório | 1–18 | Status, disclaimer imutável, título e análise de títulos (1.5) |
| **1 Introdução** | 21–66 | 1.1 Contextualização · 1.2 Problema · 1.3 Justificativa · 1.4 Objetivos (→ seção 3) · 1.5 Título |
| **2 Referencial Teórico** | 70–104 | 2.1 Pré-natal · 2.2 DSS · 2.3 Vulnerabilidade/índices · 2.4 ML supervisionado |
| **3 Objetivos** | 108–130 | 3.1 Geral · 3.2 Específicos (tabela com status) |
| **4 Metodologia** | 134–531 | 4.1 Tipo · 4.2 DSS (6 dim/48 var) · 4.3 IV-DSS · 4.4 Modelagem · 4.5 População/T0/target · 4.6 Dataset sintético · 4.7 Seleção/leakage · 4.8 Modelos · 4.9 Treino/validação · 4.10 Métricas · 4.11 Integração · 4.12 Ética/limitações |
| **5 Desenvolvimento da aplicação** | 534–573 | 5.1 Arquitetura · 5.2 Eixo DSS · 5.3 Eixo pré-natal · 5.4 Offline · 5.5 Onde IV-DSS é calculado |
| **6 Resultados e Discussão** | 576–580 | `[AGUARDAR RESULTADOS]` |
| **7 Conclusão** | 582–585 | `[AGUARDAR RESULTADOS]` |
| **Referências** | 589–607 | 9 itens já levantados (alguns `[VALIDAR NA LITERATURA]`) |
| **Apêndice — Decisões** | 611–664 | 🔒 Congeladas (20) · ⚠️ Pendentes (5) |

---

## 2. Estado real do projeto (fonte de verdade para a auditoria)

Estes são os **fatos congelados/commitados** contra os quais o documento é
avaliado. Foram confirmados diretamente no código e nos artefatos de `ia/`.

### 2.1 Pipeline de ML (implementado — `ia/`)

- **Modelo selecionado:** `RandomForestClassifier` (`random_forest`).
- **Modelos efetivamente avaliados:** `logistic_regression`, `random_forest`,
  `xgboost` — **três**. **NÃO** há rede neural, TensorFlow/Keras/PyTorch, nem
  K-means no código (busca vazia em `ia/src/`).
- **Pipeline real:** 34 variáveis brutas (`X_model`) → preprocessing (one-hot /
  multi-hot / ordinais / booleanos / numéricos, sem imputação, sem scaling, sem
  feature selection) → **96 features transformadas** → Random Forest →
  **probability**.
- **Schema:** `1.13`; **preprocessing:** `1.0`; **protocolo:** `1.0`.
- **Dataset:** 5.000 registros sintéticos (seed fixa `42`), proporção planejada
  ~25% (real: 24,42% no total, 24,4% no teste). Divisão **4.000 treino / 1.000
  teste**, estratificada.
- **Ajuste:** o modelo congelado foi treinado **somente** nos 4.000 de treino;
  o teste **nunca** participou do fit. Seleção por **CV 5-fold** (folds
  congelados) com métrica primária **mean PR-AUC**, desempate mean Recall → mean
  F1.
- **Seleção (CV):** Random Forest `mean PR-AUC = 0,3508` > regressão logística
  `0,3370` > XGBoost `0,3346`.

### 2.2 Resultados experimentais do Random Forest (teste, avaliação única)

| Métrica | Valor |
|---------|-------|
| ROC-AUC | ≈ 0,6174 |
| PR-AUC | ≈ 0,3356 |
| Brier | ≈ 0,1787 |
| Accuracy | 0,755 |
| **Threshold 0.5 — TN / FP / FN / TP** | **755 / 1 / 244 / 0** |
| **Recall no threshold 0.5** | **0,0** |
| **Precision no threshold 0.5** | **0,0** |

> ⚠️ **Recall zero no threshold 0.5.** Este é um fato dos resultados e **não
> pode ser omitido** se a análise de threshold integrar a seção de resultados.
> Reforçar que **0.5 NÃO foi adotado operacionalmente** e que o produto **não
> usa classificação binária** — exibe apenas `probability`.

### 2.3 IV-DSS — **já implementado**

- Pacote `ia/src/meu_bebe_ml/iv_dss/` (education, work_income, saneamento,
  access, housing, food, scoring, calculator, types, sensitivity) + script
  `generate_iv_dss.py` + artefatos (`iv_dss_report_v1.json`, `iv_dss_v1.jsonl`,
  `iv_dss_audit_v1.csv`).
- Report com as 6 dimensões, `iv_dss_principal` (n válidos = 4.643),
  `iv_dss_parcial` (5/6; 352), cobertura 6/6 + 5/6 + 4/6, e sensibilidade do
  adensamento habitacional (3 níveis vs. binário).

### 2.4 Análises secundárias — **já implementadas**

- **Interpretabilidade** (`interpretability_v1.json`): permutation importance
  (TRAIN-OOF, 20 repeats, métrica PR-AUC).
- **Sensibilidade metodológica** (`methodological_sensitivity_v1.json`):
  34 vs. 36 features (`X_sens` = X_model + `facil_acesso_saude` +
  `problema_saude_agua`).
- **Calibração** (`calibration_stability_v1.json`) e **análise de threshold**
  (`threshold_analysis_v1.json`).

### 2.5 API (implementada — `api/`)

- Endpoints reais: `GET /health`, `GET /ready`, `POST /api/v1/risk-estimate`.
- **Não existe** endpoint de autenticação (`/auth`).
- A API usa o pacote `ia` (runtime de ML) sem copiar o código do modelo para o
  Flutter.

### 2.6 Flutter — gerenciamento do pré-natal (auditoria FASE 6A)

- 4 tabs: **HOME · GESTAÇÃO · PARTO · PERFIL**.
- 13 models / 13 tabelas locais (SQLite via `sqflite`, SQL bruto, `meu_bebe.db`
  v1; **sem** Drift/codegen).
- **Sem foreign keys** entre as tabelas de domínio (`PRAGMA foreign_keys = ON`,
  mas nenhuma `FOREIGN KEY`/`REFERENCES`).
- Premissa implícita atual: **1 dispositivo ≈ 1 gestante ≈ 1 gestação atual**.
- **Login decorativo:** botão "Entrar" navega sem autenticar; "Criar nova conta"
  vai para o questionário DSS (não cria conta). Código legado parcial
  (`UserRepository POST /auth`, `UserLoginService`, token em `SharedPreferences`)
  não compõe autenticação/sessão funcional.
- **DSS atual é stateless:** sem login, sem token, sem `userId`/`gestanteId`/
  `gestacaoId`.

### 2.7 Arquitetura futura (PROPOSTA — NÃO implementada)

- `USER → GESTANTE → {HISTORICO_OBSTETRICO, GESTACAO}`; `GESTACAO → {CONSULTA,
  EXAME, MEDICACAO, VACINA/checklist, PLANO_DE_PARTO, AVALIACAO_DSS}`.
- PostgreSQL, auth JWT/Argon2id, persistência DSS, etc. — tudo **planejamento**,
  a detalhar na FASE 6B. Deve ser marcado explicitamente como **PROPOSTA**.

---

## 3. Auditoria seção a seção

Legenda: ✅ correto · 🟡 desatualizado · 🔴 contraditório · ➕ incompleto/lacuna.

### 1 Introdução
| Subseção | Diagnóstico | Recomendação |
|----------|-------------|--------------|
| 1.1 Contextualização | ✅ alinhado ao foco (DSS + AM + pré-natal integrado) | manter |
| 1.2 Problema | ✅ | manter |
| 1.3 Justificativa | ✅ "armazenamento local/offline" e "integra em uma mesma solução" corretos | manter |
| 1.4 Objetivos | ✅ apenas aponta para a seção 3 | manter |
| 1.5 Título | ✅ análise honesta, sem decisão imposta | manter |

### 2 Referencial Teórico
| Subseção | Diagnóstico | Recomendação |
|----------|-------------|--------------|
| 2.1 Pré-natal | ✅ Portaria 5.350/2024 citada corretamente; ➕ referências primárias `[VALIDAR]` | consolidar referências |
| 2.2 DSS | ✅ Dahlgren & Whitehead, Fiocruz; ➕ fontes primárias pendentes | consolidar |
| 2.3 Vulnerabilidade/índices | ✅ Ayres, OECD/JRC (com ressalva correta sobre peso igual) | consolidar |
| 2.4 ML supervisionado | ✅ genérico (RF/XGBoost/redes) | manter como referencial; ver 4.8 |

### 3 Objetivos — **MAIOR FONTE DE DESATUALIZAÇÃO**
| # | Diagnóstico | Recomendação |
|---|-------------|--------------|
| 3.1 Geral | ✅ não menciona rede neural; "modelo de aprendizado de máquina" é amplo o suficiente | manter |
| 3.2 #1 (contrato DSS) | ✅ realizado | manter |
| 3.2 #2 (IV-DSS) | 🔴 diz "**aguarda implementação**", mas **já está implementado** | atualizar status → ✅ realizado |
| 3.2 #3 (app Flutter) | ✅ "parcialmente realizado" | manter (login decorativo impede "completo") |
| 3.2 #4 (target) | ✅ | manter |
| 3.2 #5 (dataset sintético) | 🔴 "**⏳ pendente**", mas **gerado** | atualizar → ✅ realizado |
| 3.2 #6 (aplicar ML) | 🔴 "**⏳ pendente**", mas **treinado/avaliado** | atualizar → ✅ realizado |
| 3.2 #7 (métricas desbalanceadas) | 🔴 "**⏳ pendente**", mas **avaliado** | atualizar → ✅ realizado |
| 3.2 #8 (integrar Flutter→API→ML) | 🔴 "**⏳ pendente**", mas **validado no emulador** | atualizar → ✅ realizado |

### 4 Metodologia
| Subseção | Diagnóstico | Recomendação |
|----------|-------------|--------------|
| 4.1 Tipo | ✅ | manter |
| 4.2 DSS (6/48) | ✅ dimensões e contagem corretas; nota de "Saúde"→"acesso" correta | manter |
| 4.3 IV-DSS | 🟡 descrito como "**proposto**" mas **implementado**; o conteúdo técnico (escores, pesos 1/6, missing) está correto | trocar "proposto" por "implementado"; preservar a separação IV-DSS ≠ P(Y) |
| 4.4 Modelagem | ✅ schema 1.13, 48 vars, sem texto livre | manter |
| 4.5 População/T0/target | ✅ guarda correta sobre Portaria 5.350 (não vira definição universal) | manter |
| 4.6 Dataset sintético | 🟡 descrito em tom de planejamento, mas **executado** | ajustar tempo verbal; registrar que foi gerado |
| 4.7 Seleção/leakage | ✅ 34/5/5/2/2 = 48 | manter |
| 4.8 Modelos ML | 🔴 menciona "rede neural opcional" e "K-means" como se fossem parte do experimento; **não foram** | restringir aos 3 modelos avaliados (LR, RF, XGBoost); mover rede neural para "planejamento inicial não executado" |
| 4.9 Treino/validação | 🟡 "`[DEPENDE DA IMPLEMENTAÇÃO]`" — já implementado | registrar CV 5-fold, split estratificado, class_weight, preprocessing aprendido só no treino |
| 4.10 Métricas | 🟡 "`[DEPENDE DA IMPLEMENTAÇÃO]`" — já calculadas | incluir valores reais (seção 6) |
| 4.11 Integração | 🟡 "`[DEPENDE DA IMPLEMENTAÇÃO]`" — já validada | atualizar |
| 4.12 Ética/limitações | ➕ falta: recall zero no 0.5; separação persistência operacional × uso científico (LGPD/consentimento) | adicionar (ver §7) |

### 5 Desenvolvimento da aplicação
| Subseção | Diagnóstico | Recomendação |
|----------|-------------|--------------|
| 5.1 Arquitetura | 🟡 "comunicação assíncrona com **futura** API" — o eixo DSS já tem API real | distinguir estado atual (DSS integrado; pré-natal local; login decorativo) × futuro |
| 5.2 Eixo DSS | ➕ fino; não descreve o fluxo real (FormularioData → repo → Dio → FastAPI → ML → bottom sheet) | expandir |
| 5.3 Eixo pré-natal | ➕ fino; não descreve as 4 tabs nem o plano de parto | expandir (sem excesso de nomes de classe) |
| 5.4 Offline | ✅ | manter |
| 5.5 Onde IV-DSS é calculado | ✅ correto e agora confirmado (pipeline Python, fora do app/API) | manter; ajustar "decisão do autor" |

### 6 Resultados e Discussão — 🔴 `[AGUARDAR RESULTADOS]`
**Desatualizado.** Há resultados concretos. Deve ser preenchido **separando**:
- **Resultados do experimento de ML** (métricas experimentais: ROC-AUC, PR-AUC,
  Brier, matriz de confusão, recall zero no 0.5, CV, interpretabilidade,
  sensibilidade, calibração, IV-DSS);
- **Validação de software** (integração Flutter ↔ FastAPI ↔ IA no emulador —
  smoke test de integração, **não** validação científica do modelo).

### 7 Conclusão — 🔴 `[AGUARDAR RESULTADOS]`
Desatualizado. Deve retomar objetivos (todos os 8 realizados), contribuições,
limitações e trabalhos futuros (incluindo arquitetura futura proposta).

### Referências — 🟡
9 itens levantados; alguns `[VALIDAR NA LITERATURA]`. Nenhum DOI/autor
fabricado. **Manter como está**; apenas consolidar e remover os marcadores à
medida que as fontes primárias forem confirmadas em `../artigos/`.

### Apêndice — Decisões
| Item | Diagnóstico | Recomendação |
|------|-------------|--------------|
| 🔒 Congeladas (20) | ✅ consistente com os artefatos | manter |
| ⚠️ "Ambiente de execução (Python/scikit-learn)" | 🔴 **resolvido** (scikit-learn 1.9.0) | mover para congelado |
| ⚠️ "Rede Neural (opcional)" | 🔴 **não executada** | registrar como "não utilizada no experimento" |
| ⚠️ "Normalização alternativa escolaridade / sensibilidade IV-DSS" | 🟡 sensibilidade **executada** (habitação binária; 34 vs 36) | atualizar |
| ⚠️ "Título final" | ✅ pendente | manter |
| ⚠️ "Operacionalização longitudinal do target" | ✅ pendente (correto) | manter |

---

## 4. Seções corretas (não mexer, ou ajuste mínimo)

- 1.1–1.5 (Introdução e análise de título).
- 2.x (Referencial — apenas consolidar referências já citadas).
- 3.1 (objetivo geral).
- 4.1, 4.2, 4.4, 4.5, 4.7.
- 4.12 (limitações — **adicionar** itens, sem remover os existentes).
- 5.4 (offline).
- Apêndice 🔒 congeladas (1–20).

---

## 5. Seções desatualizadas (resumo)

1. **3.2** — status dos objetivos 2, 5, 6, 7, 8 marcados como pendentes.
2. **4.3** — IV-DSS "proposto" → já implementado.
3. **4.6** — dataset sintético em tom de planejamento → já gerado.
4. **4.9, 4.10, 4.11** — marcados `[DEPENDE DA IMPLEMENTAÇÃO]` → implementados.
5. **5.1** — "futura API" → eixo DSS já integrado.
6. **6 e 7** — `[AGUARDAR RESULTADOS]` → há resultados.
7. **Apêndice ⚠️** — itens já resolvidos (scikit-learn; rede neural não usada;
   sensibilidade executada).

---

## 6. Contradições explícitas a corrigir

| # | Contradição | Onde |
|---|-------------|------|
| C1 | Objetivo #2 diz "aguarda implementação" do IV-DSS, mas está implementado | 3.2 × `ia/iv_dss` |
| C2 | Objetivos #5–#8 marcados "pendentes", mas ML/avaliação/integração concluídos | 3.2 × artefatos |
| C3 | 4.8 lista "rede neural" e "K-means" como modelos, mas não foram avaliados | 4.8 × `training_models` |
| C4 | 5.1 fala em "futura API", mas o DSS já tem API integrada | 5.1 × `api/` |
| C5 | Apêndice trata ambiente Python e rede neural como "pendentes", já resolvidos | Apêndice ⚠️ |

---

## 7. Lacunas (inclusive de referência)

### 7.1 Lacunas de conteúdo (adicionar)
1. **Resultados experimentais** (seção 6): métricas reais + recall zero no 0.5.
2. **Validação de software** (integração emulador) separada de validação do ML.
3. **Estado atual do pré-natal** (4 tabs; plano de parto; sem FK; 1 dispositivo
   ≈ 1 gestante; login decorativo; DSS stateless) — seção 5.
4. **Separação estado atual × arquitetura futura proposta** (regra transversal).
5. **Persistência operacional ≠ uso científico** dos dados (LGPD/consentimento/
   ética) — adicionar em 4.12 ou em ética.
6. **Distinção IV-DSS ≠ P(Y) ≠ diagnóstico** já presente; reforçar.
7. **Arquitetura futura proposta** (USER→GESTANTE→GESTACAO→…; PostgreSQL;
   auth; AVALIACAO_DSS) marcada como **PROPOSTA / não implementada**.

### 7.2 Lacunas de referência (NÃO inventar — marcar)
- 2.2 Fiocruz DSS-Brasil: **[VALIDAR NA LITERATURA]** (fonte primária em
  `../artigos/`).
- 2.3 IPEA IVS e SEADE IPVS: **[VALIDAR NA LITERATURA]**.
- 2.4 métricas de desbalanceamento: **[VALIDAR NA LITERATURA]**.
- Rede Neural como proposta inicial: se o **TCC1** (PDF) a mencionou, distinguir
  "planejamento inicial" de "modelo efetivamente selecionado", citando o TCC1
  apenas como referência histórica — **sem** inventar fonte externa.
- Qualquer afirmação nova que exija embasamento e não tenha fonte no documento:
  **marcar como lacuna de referência**, não criar citação.

---

## 8. Trechos que exigem cuidado metodológico

1. **Terminologia da saída do modelo** — usar sempre "estimativa estatística
   experimental de probabilidade/propensão à descontinuidade". **Proibir**:
   diagnóstico, diagnóstico de abandono, certeza, predição clínica validada,
   classificação clínica, alto/médio/baixo risco, ferramenta médica validada.
2. **Dados sintéticos** — manter explícito que: treino/validação técnica usam
   dados sintéticos; servem para validação experimental da metodologia; **não**
   representam prevalência real nem a população brasileira de gestantes; **não**
   validam associações clínicas; **não** tornam o modelo uma ferramenta clínica.
3. **População/target** — preservar: população = gestantes que já iniciaram o
   pré-natal; T0 = preenchimento/envio do questionário; target conceitual
   `descontinuou_pre_natal ∈ {0,1}` no estudo sintético. **Não** transformar a
   Portaria 5.350/2024 ou número mínimo de consultas em definição universal
   automática de abandono.
4. **Threshold** — reforçar que nenhuma faixa baixo/médio/alto foi adotada;
   nenhum threshold operacional definido; 0.5 não virou regra do app; a
   interface não classifica a gestante.
5. **Recall zero no 0.5** — se a análise de threshold estiver nos resultados,
   **não omitir**; apresentar como resultado experimental, não como desempenho
   clínico.
6. **IV-DSS** — descrever como índice descritivo experimental de vulnerabilidade;
   **não** é P(Y), diagnóstico, classificador, nem resultado do Random Forest.
7. **Contribuição do app** — dizer "integra em uma mesma solução", **evitar**
   "é o único aplicativo que…" sem evidência.
8. **README/FASE_*.md/código não são referência bibliográfica** — podem ser
   evidência interna de alinhamento, não literatura.

---

## 9. Alterações propostas (por capítulo)

> **Regra transversal (em todo o documento):** marcar explicitamente
> **ESTADO ATUAL IMPLEMENTADO** vs. **ARQUITETURA FUTURA / PROPOSTA**, sem
> escrever proposta no passado/presente como se já existisse.

### 9.1 Seção 3 — Objetivos
- Atualizar a coluna "Status" da tabela 3.2:
  - #2 (IV-DSS) → ✅ realizado.
  - #5 (dataset) → ✅ realizado.
  - #6 (ML) → ✅ realizado.
  - #7 (métricas) → ✅ realizado.
  - #8 (integração) → ✅ realizado.
- **NÃO** alterar o objetivo geral 3.1 (já é amplo o suficiente).

### 9.2 Seção 4 — Metodologia
- 4.3: trocar "proposto" por "implementado" (manter especificação técnica).
- 4.6: registrar execução (gerado, 5.000, seed 42).
- 4.8: restringir a "três modelos avaliados (LR, RF, XGBoost)"; registrar a
  mudança metodológica (rede neural/K-means do planejamento **não executados**)
  sem apagar a evolução.
- 4.9: preencher protocolo real (split 80/20 estratificado, CV 5-fold, seed,
  class_weight, preprocessing aprendido só no treino, TEST nunca no fit).
- 4.10: referenciar as métricas reais (detalhe na seção 6).
- 4.11: registrar integração validada.
- 4.12: adicionar (a) recall zero no threshold 0.5; (b) persistência operacional
  ≠ uso científico (LGPD/consentimento/ética).

### 9.3 Seção 5 — Desenvolvimento da aplicação
- 5.1: separar estado atual da API DSS (real) do futuro do pré-natal (proposto).
- 5.2: descrever o fluxo DSS real (Flutter → FormularioData → repository →
  cliente Dio dedicado → FastAPI → runtime ML → RF → probability → bottom sheet).
- 5.3: descrever as 4 tabs (Home: consultas/exames, vacinas, medicamentos,
  informações; Gestação; Parto/plano de parto; Perfil), sem excesso de nomes de
  classe/rota/controller.
- 5.5: manter; atualizar status (IV-DSS calculado no pipeline Python, confirmado).

### 9.4 Seção 6 — Resultados e Discussão (nova redação)
Preencher com duas frentes separadas:
- **A) Resultados do experimento de ML** — caracterização do dataset; comparação
  LR/RF/XGBoost no CV; seleção do RF (PR-AUC); avaliação no teste (ROC-AUC 0,6174;
  PR-AUC 0,3356; Brier 0,1787; matriz TN 755 / FP 1 / FN 244 / TP 0 → recall 0,0
  no 0.5); interpretabilidade; sensibilidade (34 vs 36); calibração; análise de
  threshold; IV-DSS (6 dimensões). **Tudo como resultado experimental, não
  clínico.**
- **B) Validação do software** — integração Flutter ↔ FastAPI ↔ IA validada no
  Android Emulator (smoke test de integração, não validação científica do modelo).

### 9.5 Seção 7 — Conclusão (nova redação)
Retomar os 8 objetivos (todos realizados), contribuições (DSS + pré-natal +
plano de parto + integração ML), limitações (sintético, sem validação clínica,
recall zero no 0.5, login decorativo, sem FK local, 1 dispositivo ≈ 1 gestante),
e trabalhos futuros (arquitetura futura proposta; FASE 6B).

### 9.6 Apêndice — Decisões
- Mover para "congelado": ambiente Python/scikit-learn (resolvido).
- Registrar "rede neural não utilizada no experimento" (não "opcional/pendente").
- Atualizar sensibilidade do IV-DSS (executada).

---

## 10. Referências acadêmicas que faltam (sem inventar)

- **Não há referência nova a criar.** O documento já contém a base (Portaria
  5.350/2024; WHO 2016; OECD/JRC 2008; Ayres; Fiocruz; IPEA; SEADE; Cadernos de
  Atenção Básica nº 32).
- Itens `[VALIDAR NA LITERATURA]` (Fiocruz, IPEA, SEADE, métricas ML) devem ser
  resolvidos **apenas** confirmando fontes em `../artigos/` — não fabricando.
- Se a menção a rede neural do TCC1 precisar de respaldo, citar o próprio TCC1
  como referência histórica, **não** uma fonte externa inventada.

---

## 11. Plano de edição por capítulo (histórico da ETAPA 1)

1. **Apêndice** (baixo risco; registra decisões já resolvidas).
2. **Seção 3** (atualizar status dos objetivos).
3. **Seção 4** (metodologia: implementado vs. proposto).
4. **Seção 5** (estado atual do app e separação atual × futuro).
5. **Seção 6** (resultados — a maior adição).
6. **Seção 7** (conclusão).
7. **Revisão transversal** de terminologia metodológica (regra do §8) e de
   separação atual × futuro.
8. **Referências** — consolidar apenas o que já existe; marcar lacunas.

> **Histórico da ETAPA 1:** cada passo acima era proposta, a executar somente
> após a revisão deste plano e autorização explícita. Essa autorização foi
> concedida e a edição foi **executada** na ETAPA 2.

---

## 12. Verificação da ETAPA 1 (histórico)

> Estado **na época da ETAPA 1** (antes da edição autorizada).

| Verificação | Resultado na ETAPA 1 |
|-------------|--------------------|
| Arquivo criado | `docs/TCC2_UPDATE_PLAN.md` (este) |
| `docs/tcc2.md` | **inalterado** |
| `lib/`, `api/`, `ia/`, `test/`, `README.md`, `FASE_6A_REPORT.md` | **inalterados** |
| `git status --short` | `?? docs/TCC2_UPDATE_PLAN.md` |
| `git diff --check` | limpo |
| Commit | **NÃO realizado** |

---

## 13. Verificação final da ETAPA 2

> Estado **atual**, após a edição integrada do `docs/tcc2.md` e a correção final.

| Verificação | Resultado atual |
|-------------|-----------------|
| `docs/tcc2.md` | **editado** (metodologia implementado vs. proposto; seções 6 e 7 preenchidas; apêndice atualizado; correções finais aplicadas) |
| `docs/TCC2_UPDATE_PLAN.md` | **atualizado** (blocos históricos renomeados; esta verificação final acrescentada) |
| `lib/`, `api/`, `ia/`, `test/`, `README.md`, `FASE_6A_REPORT.md` | **inalterados** |
| `git status --short` | `M docs/tcc2.md` e `?? docs/TCC2_UPDATE_PLAN.md` |
| `git diff --check` | limpo |
| Commit | **NÃO realizado** |

---

> **FASE 6A-DOC — ETAPA 2 (EDIÇÃO) CONCLUÍDA.** `docs/tcc2.md` atualizado de forma
> integrada (52 instruções + correção final). Nenhum commit realizado.
> **PARE E AGUARDE REVISÃO.**
