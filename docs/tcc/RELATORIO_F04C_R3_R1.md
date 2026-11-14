# Relatório — FASE TCC-FINAL-04C-R3-R1 (Reabertura e Correções Residuais Obrigatórias)

**Data:** 2026-09-05
**Veredicto de entrada:** auditoria visual independente do TCC (96 páginas na versão R3) apontou problemas objetivos em 12 frentes; reabertura R3-R1 para correção.
**Instrução mantida:** NÃO COMMITAR (nenhum commit realizado; último commit permanece `1e60058`).

---

## Restrições obrigatórias (§11) — cumprimento

| Restrição | Estado |
|-----------|--------|
| Criar backup antes de qualquer alteração | ✅ `_backup_pre_04c_r3_r1.docx` (pré-R3-R1) |
| Alterar somente arquivos da documentação e, quando necessário, as imagens compiladas do TCC | ✅ Só o DOCX e o PDF foram alterados |
| Não alterar lib/, test/, api/, ia/, dataset/, código-fonte, modelo, treinamento, resultados ou métricas | ✅ Nenhum arquivo fora de `docs/` foi tocado |
| Não modificar as capturas de tela originais | ✅ Nenhuma imagem foi alterada |
| Não excluir Dedicatória e Agradecimentos | ✅ Preservadas |
| Preservar os placeholders dessas duas páginas (textos fornecidos posteriormente pelo autor) | ✅ Placeholders mantidos |
| Não realizar commit | ✅ Nenhum commit realizado |
| Não mudar resultados experimentais para facilitar a redação | ✅ Apenas texto editorial/terminologia/leiaute |
| Não declarar a fase totalmente concluída enquanto os dois textos pessoais permanecerem pendentes | ✅ **A fase permanece NÃO CONCLUÍDA** (Dedicatória/Agradecimentos pendentes) |

---

## Status por requisito (12 seções)

| # | Requisito | Estado | Observação |
|---|-----------|--------|------------|
| §1 | Formatação de parágrafos narrativos | ✅ Concluído | Resumo/Abstract/introdução/capítulos/conclusão/textos de apêndice → `CorpoTexto` (TNR 12, justificado, 1,5, recuo 1,25 cm, 0 pt antes/depois); linha esticada da p.36 corrigida com espaços não separáveis |
| §2 | Espaçamento de títulos | ✅ Concluído | `page_break_before` em capítulos/apêndices; linhas em branco manuais removidas após títulos |
| §3 | Sumário/listas | ✅ Concluído | Sumário principal (TOC) ausente foi reconstruído; 69 entradas niveladas 1–3 |
| §4 | Continuações de tabelas | ✅ Concluído | 4 tabelas com "Continuação" divididas em 8 tabelas independentes |
| §5 | Figuras (termos técnicos em imagens) | ⛔ Bloqueado | Ver "Bloqueios" — termos estão somente dentro de PNGs raster sem fonte |
| §6 | Nota de dados fictícios | ✅ Concluído | Declaração inserida antes da primeira captura de tela (Figura 7, §4.1.2) |
| §7 | Nomes de variáveis | ✅ Concluído | `tipo_emprego`, `trabalho_permite_pre_natal` etc. (p.91) e `X_model` (p.67) reescritos em linguagem natural |
| §8 | Linguagem técnica | ✅ Concluído | `notice`→aviso metodológico, `onboarding`→configuração inicial, `login/logout`, `rotas`, `backend`→servidor da aplicação; nomes de ORM/migração/token reduzidos |
| §9 | Correções de texto | ✅ Concluído | 5 ocorrências ("partes congelados", "cinco partes estratificado", "entre os partes", "por validação cruzada", "reversão da transação") |
| §10 | Páginas com pouco conteúdo | ⚪ Sem ação | Não compactar; p.36 permanece curta |
| §11 | Restrições obrigatórias | ✅ Cumprido | Ver tabela acima |
| §12 | Verificação final | ✅ Concluído | 2 passadas de campos + listas + Sumário + PDF/A-3a + verificação estrutural; inspeção visual 100% **bloqueada** (ver abaixo) |

---

## Detalhamento das correções

### §1 — Formatação de parágrafos narrativos
- 26 parágrafos narrativos (Resumo, Abstract, introdução, capítulos, conclusão, textos explicativos dos apêndices) convertidos para o estilo `CorpoTexto`: Times New Roman 12 pt, justificado, espaçamento 1,5, recuo de primeira linha 1,25 cm, 0 pt antes/depois.
- 2 linhas de palavras-chave convertidas ao mesmo padrão **sem** recuo de primeira linha.
- Linha esticada da p.36: `(índices 0 a 4)` e `(índices 4.995 a 4.999)` receberam espaços não separáveis (`0 a 4`, `4.995 a 4.999`) para impedir a quebra de linha no meio do intervalo.
- Títulos, legendas, fontes, referências, citações longas, listas e tabelas **não** foram tocados (fora do escopo da regra).

### §2 — Espaçamento de títulos
- `page_break_before = True` aplicado a: `1 INTRODUÇÃO`, `REFERÊNCIAS`, `APÊNDICE A`, `APÊNDICE B`, `APÊNDICE C` (e capítulos que precisavam).
- Removidas linhas em branco manuais imediatamente após títulos (evita espaçamento duplicado mantido apenas por `keepWithNext`/`space_after`).

### §3 — Sumário e listas
- O **Sumário principal (campo TOC) estava ausente** — existiam apenas os 3 campos das listas de Figuras/Tabelas/Quadros. Foi reconstruído um campo `TOC \o "1-3" \h \z \u` logo após o rótulo "SUMÁRIO".
- Após as 2 passadas de atualização de campos (Word COM), o Sumário foi populado com **69 entradas** (níveis 1–3), com números de página à direita, líder de pontos uniforme e recuos consistentes.
- Itálico preservado apenas nos termos estrangeiros; cada lista (Figuras/Tabelas/Quadros) em página própria.

### §4 — Continuações de tabelas
Divisão em tabelas independentes, por página:

| Tabela original | Local | Resultado |
|-----------------|-------|-----------|
| Quadro 1 | p.27 | 2 tabelas independentes + parágrafo "Continuação" |
| Tabela 7 | p.70–71 | idem |
| Apêndice A | p.89–90 | idem |
| Apêndice C | p.93–94 | idem |

Regras aplicadas em cada uma: cabeçalho único (negrito, sem sombreamento), "Continuação" como parágrafo acima da segunda tabela com `pageBreakBefore`, fonte TNR 10 pt forçada em todos os runs, remoção de `lastRenderedPageBreak` obsoletos, sem divisão de linha dentro da tabela, sem legenda/cabeçalho órfãos.

**Observação (fora de escopo):** a `Tabela 2` (Amostra do conjunto de dados sintético) permanece em 9 pt — não faz parte das 4 tabelas-alvo do §4.

### §5 — Figuras (termos técnicos em imagens)
**BLOQUEADO.** Os termos técnicos a substituir (endpoints, `USER`, `AUTH_REFRESH_SESSION`, `HTTP`, `JSON`, `TEST`, `threshold`, `Permutation importance`, `holdout`, `target`, `mean delta PR-AUC`, nomes de variáveis) estão **somente dentro das imagens PNG raster** (capturas de tela e diagramas), sem arquivos-fonte editáveis no repositório. Além disso, o modelo atual não consegue visualizar imagens. Nenhuma figura foi alterada — ver "Bloqueios".

### §6 — Nota de dados fictícios
Declaração inserida **antes da primeira captura de tela** (legenda `Figura 7 — Questionário dos DSS`, §4.1.2), formatada como corpo narrativo:
> "Todos os nomes, documentos, contatos, datas e demais informações pessoais exibidos nas telas são fictícios e foram utilizados exclusivamente para fins demonstrativos."

### §7 — Nomes de variáveis
- p.91: `tipo_emprego`, `trabalho_permite_pre_natal` e demais identificadores técnicos reescritos em descrição natural.
- p.67: `Variáveis de entrada (X_model)` → **"Variáveis utilizadas pelo modelo"**.
- p.94: `C_agua`, `C_esgotamento` etc. mantidos apenas quando indispensáveis à rastreabilidade metodológica.

### §8 — Linguagem técnica
- `notice` → **aviso metodológico** · `onboarding` → **configuração inicial** · `login` → **entrada na conta** · `logout` → **saída da conta** · `rotas` → **funcionalidades** · `backend` → **servidor da aplicação**.
- Nomes de `SQLAlchemy`, `Alembic`, `Argon2id`, `JWT` e termos de migração **reduzidos** no corpo (mantidos apenas onde imprescindíveis à rastreabilidade, e sempre que possível substituídos por descrição natural).

### §9 — Correções de texto (verbatim)
1. p.40/67: "partes congelados" → **"partições estratificadas e predefinidas"**
2. p.40: "cinco partes estratificado" → **"cinco partições estratificadas"**
3. p.70: "entre os partes" → **"entre as partições"**
4. p.71: "validação cruzada, por validação cruzada" → **"Os resultados obtidos por validação cruzada indicaram…"**
5. p.73: "o respectivo reversão da transação" → **"a execução e a respectiva reversão da transação"**

### §10 — Páginas com pouco conteúdo
Sem ação, conforme instrução ("Desconsidere" / não compactar). A p.36 permanece curta por decisão do auditor.

### §12 — Verificação final
- **Campos:** 2 passadas de atualização (`Fields.Update()` + `TablesOfContents.Update()` + `Repaginate()`) via Word COM.
- **Sumário:** 69 entradas (1 INTRODUÇÃO=18, 2 FUNDAMENTAÇÃO=23, 3 METODOLOGIA=31, 4 RESULTADOS=50, 5 CONCLUSÃO=86, REFERÊNCIAS=88, APÊNDICE A=93, APÊNDICE B=97, APÊNDICE C=99, APÊNDICE D=103).
- **PDF/A:** reexportado como **PDF/A-3a** (`pdfaid:part=3`, `conformance=A`, OutputIntent `GTS_PDFA1`).
- **Fontes:** 9 fontes incorporadas como subconjunto (`FontFile2`, prefixo de subset presente).
- **Estrutura final:** 104 páginas, 757 parágrafos, 21 tabelas, 41 legendas.
- **Erros:** 0 ocorrências de "Fonte de referência não encontrada" (após 2 passadas).

---

## Verificações técnicas (evidências pós-round-trip Word)

Após a reabertura no Word COM (round-trip de campos), a verificação estrutural confirmou que **todas as edições R3-R1 sobreviveram**:

| Checagem | Resultado |
|----------|-----------|
| `tables = 21` | ✅ |
| Linhas "Continuação" dentro de tabelas | ✅ 0 (divididas) |
| Espaço não separável "4.995 a 4.999" | ✅ presente |
| Parágrafos da declaração (§6) | ✅ 1 |
| Texto de abertura do apêndice como `CorpoTexto` | ✅ presente |
| Parágrafos "Continuação" independentes | ✅ 4 |
| `page_break_before` em "1 INTRODUÇÃO" | ✅ presente |
| `page_break_before` em "APÊNDICE A…" | ✅ presente |

---

## Bloqueios remanescentes (a fase permanece NÃO CONCLUÍDA)

1. **§5 — Figuras com termos técnicos (BLOQUEADO).** Os termos a substituir estão exclusivamente dentro de imagens PNG raster sem arquivos-fonte no repositório, e o modelo atual não visualiza imagens. Nenhuma figura foi alterada. Para concluir esta frente é necessário que o autor forneça as fontes editáveis (arquivos originais dos diagramas/screenshots) ou aceite a regeneração das imagens por um fluxo que leia a imagem.

2. **§12 — Inspeção visual de 100% das páginas (BLOQUEADO).** O modelo atual não lê imagens/PDFs, impossibilitando a inspeção visual das páginas críticas (27, 36, 49, 67, 70–71, 89–91, 93–94). Substituída por verificação textual/estrutural completa (extração por página, contagem de legendas/tabelas, checagem de fontes, renderização sem erro, PDF/A-3a) — mas a confirmação visual final fica a cargo do autor.

3. **Dedicatória e Agradecimentos (R2-2) — aguardando textos do autor.** Os placeholders foram preservados conforme §11. Sem os textos pessoais, o critério de conclusão final não é atingível e a fase **não pode ser declarada totalmente concluída**.

---

## Arquivos

- `docs/TCC2_MESTRE_Harliton_Martins.docx` — modificado (104 páginas).
- `docs/TCC2_MESTRE_Harliton_Martins.pdf` — reexportado como PDF/A-3a (104 páginas).
- Backup: `docs/_backup_pre_04c_r3_r1.docx` (pré-R3-R1).

**Nenhum código, dataset, modelo, resultado ou métrica foi alterado. Nenhuma captura de tela original foi modificada. Nenhum commit foi realizado.**
