# Relatório — FASE TCC-FINAL-04C-R3

**Data:** 2026-09-04
**Veredicto de entrada:** F04C-R2 não concluída (Dedicatória/Agradecimentos pendentes) → correções residuais R3 aplicadas.
**Instrução mantida:** NÃO COMMITAR (nenhum commit realizado; último commit `1e60058`).

---

## Restrições obrigatórias — cumprimento

| Restrição | Estado |
|-----------|--------|
| Trabalhar somente no DOCX, PDF e diagramas acadêmicos | ✅ Cumprido — só `TCC2_MESTRE_Harliton_Martins.docx` e o PDF foram alterados |
| Não alterar código-fonte, banco, dataset, modelo, métricas, resultados, testes | ✅ Cumprido — nenhum arquivo fora de `docs/` foi tocado |
| Não retreinar o modelo | ✅ Cumprido |
| Não modificar capturas originais do aplicativo | ✅ Cumprido |
| Não alterar valores metodológicos/resultados | ✅ Cumprido — apenas texto editorial e terminologia |
| Não realizar commit | ✅ Cumprido |
| Backup do DOCX antes das alterações | ✅ `_backup_pre_04c_r3.docx` (pré-R3) e `_backup_stage2_text.docx` (pré-atualização de campos) |
| Manter placeholders de DEDICATÓRIA/AGRADECIMENTOS | ✅ Cumprido (bloqueio mantido, ver abaixo) |

---

## Status por requisito (18 seções)

| # | Requisito | Estado | Observação |
|---|-----------|--------|------------|
| §3 | Alinhamento do Sumário (TOC) | ✅ Concluído | Tabs de líder direita corrigidos para 9071 twips (níveis 1–3) |
| §4 | Reduzir títulos + padronizar listas | ✅ Concluído | 26 de 41 legendas encurtadas; Listas de Figuras/Tabelas/Quadros regeneradas e uniformes |
| §5 | Corrigir Tabela 4 + continuações | ✅ Concluído | Tabela 4 unida (sem quebra); 4 tabelas com "Continuação" + cabeçalho repetido |
| §6 | Páginas com pouco conteúdo | ⚪ Sem ação | "Desconsidere" — não compactar (refluxo preservado) |
| §7 | Revisão de linguagem técnica | ✅ Concluído | rollback, engine, upgrade/downgrade, builds, debug, release, data leakage, 5-fold/folds, schema, stateless traduzidos |
| §8 | Remover caminhos de endpoint | ✅ Concluído | Corpo (3 parágrafos) e Apêndice D reescritos sem paths literais |
| §9 | Nomes de entidades (USER/GESTANTE/…) | ✅ Concluído | P445/P446/P448/P522 reescritos em linguagem natural |
| §10 | Contextualizar números | ✅ Avaliado | Números já contextualizados (605 testes, 48 variáveis, n=1.000, 87 atributos); sem números órfãos |
| §11 | Lista de siglas | ✅ Avaliado | Lista com 24 entradas; SOM/BMU/PCA definidos na 1ª ocorrência |
| §12 | Estrangeirismos | ✅ Concluído | dataset→conjunto de dados, backend→servidor, pipeline→fluxo, endpoint→rota, token→credencial, baseline→referência, clusters→agrupamentos, ensemble→conjunto, etc. |
| §13 | Nota de dados fictícios | ✅ Avaliado | Dados explicitamente "fictícios" (DGM, §3.6) e "sintéticos" (85×) em todo o texto |
| §14 | Sombreamento E7E6E6 + padronizar tabelas | ✅ Concluído | 0 sombreamentos; tabelas em TNR 10pt |
| §15 | Preservar lista | ⚪ Sem ação | Nada a alterar |
| §16 | Pós-correção (campos 2 passadas, PDF/A, verificação) | ✅ Concluído | 2 passadas de campos + listas + Sumário + PDF/A-3a + verificação estrutural |
| §17 | Relatório final R3 | ✅ Este arquivo | — |
| §18 | Critérios de conclusão | ⚠️ Bloqueado | Ver "Bloqueios" abaixo |

---

## Detalhamento das correções de linguagem (§7–§12)

### §7 — Termos técnicos (corpo, exceto referências e ABSTRACT em inglês)
- `stateless (sem estado)` → **sem estado**
- `rollback` → **reversão da transação** · `engine` → já "conexão" (P521)
- `upgrade` → **migração para a versão superior** · `downgrade` → **retorno à versão anterior**
- `builds` → **compilações** · `debug` → **depuração** · `release` → **distribuição**
- `flutter analyze` → **análise estática do Flutter** · `issues` → **avisos**
- `data leakage` → **vazamento de informação** · `5-fold` → **dividida em cinco partes** · `folds` → **partes**
- `schema` → **esquema de dados** · `smoke test` → **teste de fumaça**

### §12 — Estrangeirismos
- `dataset (sintético)` → **conjunto de dados (sintético)** · `backend` → **servidor**
- `pipeline` → **fluxo** · `endpoint(s)` → **rota(s)** · `token(s)` → **credencial(is)**
- `baseline` → **referência** · `clusters` → **agrupamentos** · `ensemble` → **conjunto**
- `out-of-fold (OOF)` → **por validação cruzada** · `snapshot` → **instantâneo** · `seed` → **semente**
- `target(s)` → **variável-alvo** · `bins` → **faixas** · `hold-out` → **conjunto de teste separado**
- `accuracy/precision/recall` → **acurácia/precisão/revocação** · `score(s)` → **escore(s)**
- `gradient boosting` → **impulsionamento por gradiente** · `oversampling` → **sobreamostragem**
- `Best Matching Unit` → **unidade de melhor correspondência** · `U-Matrix` → **matriz unificada de distâncias**

**Mantidos (nomes próprios/acrônimos):** Flutter, FastAPI, PostgreSQL, SQLAlchemy, Alembic, Argon2id, JWT, HS256, XGBoost, SMOTE (se presente), SOM, IV-DSS, DSS, PR-AUC, ROC-AUC, BMU, PCA, HTTP, REST, CRUD, ORM. `login`/`logout` mantidos por serem termos consagrados no português técnico brasileiro.

**Consistência de itálico:** removido o itálico indevido dos termos traduzidos; mantido o itálico apenas nos nomes de métodos que permanecem estrangeiros (Random Forest, Self-Organizing Map, Brier). `Silhouette` e `K-means` permanecem sem itálico (decisão já tomada em R2-6).

### §8 — Endpoints (paths removidos, linguagem natural)
Reescritos: P371 (fluxo DSS), P372 (3 rotas), P432 (rota de estimativa), P449 (avaliação DSS) e o **Apêndice D** inteiro (P673–P685). Nenhum path literal (`GET /health`, `POST /api/v1/risk-estimate`, `/gestacoes/{id}` etc.) permanece no corpo.

### §9 — Entidades
`USER`→**usuário**, `GESTANTE`→**perfil de gestante**, `GESTAÇÃO/GESTACAO`→**gestação**, `HISTÓRICO OBSTÉTRICO`→**histórico obstétrico**, `AUTH_REFRESH_SESSION`→removido (descrito como "sessões de renovação"). Identificadores técnicos no Apêndice A (`ML-IN`, `OUT-LEAKAGE`, `OUT-TEMPORAL`, `DESCRITIVA`, `SENSIBILIDADE`) foram **preservados** por serem necessários à rastreabilidade metodológica.

---

## Verificações técnicas (evidências)

- **PDF/A:** `pdfaid:part=3`, `pdfaid:conformance=A` → **PDF/A-3a**.
- **Fontes:** todas subset-incorporadas (prefixo `BCD…+` em `TimesNewRomanPSMT`, `PS-BoldMT`, `PS-ItalicMT`, `PS-BoldItalicMT`, `CambriaMath`, `SymbolMT`, `ArialMT`).
- **Páginas:** 96 (estável entre R2 e R3).
- **Estrutura:** 686 parágrafos, 17 tabelas, 41 legendas (28 Figuras + 10 Tabelas + 3 Quadros).
- **Listas de Figuras/Tabelas/Quadros:** 41 entradas regeneradas com títulos encurtados e alinhamento correto.
- **Varredura de estrangeirismos/caminhos/concordância no corpo:** 0 ocorrências restantes (referências em inglês e ABSTRACT preservados corretamente).
- **Sombreamento F2F2F2/E7E6E6:** 0 ocorrências.

---

## Bloqueios remanescentes (a fase permanece "não concluída")

1. **Dedicatória/Agradecimentos (R2-2)** — mantidos como bloqueio por decisão do autor; placeholders preservados; aguardando textos. Sem isso, o critério de conclusão final (§18) não é atingível.
2. **Inspeção visual de 100% das páginas** — impossível para o modelo atual (não lê imagens). Substituída por verificação textual/estrutural completa (extração por página, contagem de legendas/tabelas, checagem de fontes, renderização sem erro, PDF/A).

---

## Arquivos

- `docs/TCC2_MESTRE_Harliton_Martins.docx` — modificado (96 páginas).
- `docs/TCC2_MESTRE_Harliton_Martins.pdf` — reexportado como PDF/A-3a (96 páginas).
- Backups: `docs/_backup_pre_04c_r3.docx` (pré-R3), `docs/_backup_stage2_text.docx` (pré-atualização de campos).

**Nenhum código, dataset, modelo ou resultado científico foi alterado. Nenhum commit foi realizado.**
