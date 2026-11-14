# Relatório — FASE TCC-FINAL-04C-R2

**Data:** 2026-09-04
**Veredicto de entrada:** F04C-R1 AINDA NÃO CONCLUÍDA → correções R2 aplicadas.
**Instrução mantida:** NÃO COMMITAR (nenhum commit realizado; último commit `1e60058`).

---

## Status por requisito

| # | Requisito | Estado | Observação |
|---|-----------|--------|------------|
| R2-1 | PDF/A com fontes incorporadas | ✅ Concluído | PDF/A-3a; 10 fontes incorporadas, 0 não-incorporadas (todas as variantes TNR) |
| R2-2 | Dedicatória/Agradecimentos sem placeholder | ⛔ Bloqueado | Mantido como bloqueio (decisão do autor); aguardando textos |
| R2-3 | Padronizar 17 tabelas (TNR 10pt) | ✅ Concluído | 10pt; 9pt nas largas (Tabela 2, Apêndices A/C); margens uniformes |
| R2-4 | Tabelas divididas (cabeçalho + Continuação) | ✅ Concluído* | cabeçalho repetido (tblHeader) + "Continuação" no topo da continuação |
| R2-5 | Uniformizar listas (remover negrito) | ✅ Concluído | Negrito removido na fonte (legendas); TOF uniforme e permanente |
| R2-6 | Completar estrangeirismos (itálico) | ✅ Concluído | Termos técnicos em itálico; comandos/marcas preservados |
| R2-7 | Refluir páginas 47/67/85/101/103 | ✅ Concluído | Sem vazios grandes; 103→96 páginas (efeito das correções ABNT) |
| R2-8 | Remover sombreamento F2F2F2 | ✅ Concluído | 0 sombreamentos restantes |
| R2-9 | Listas com marcadores sem herdar 10pt | ✅ Concluído | space_after=0 nos estilos de lista |
| R2-10 | Campos 2 passadas + listas + inspeção | ⚠️ Parcial | Campos/listas/Sumário regenerados e PDF exportado; inspeção visual não possível (limitação do modelo) |

\* R2-4: o rótulo **"Continua..."** no rodapé da página de quebra **não foi inserido** porque as 4 páginas de quebra estão completas (0–6pt de espaço útil abaixo da última linha, margem inferior ABNT de 2cm). Inseri-lo exigiria refluir/encolher dados — fora do escopo ("não alterar dados/resultados"). O cabeçalho repetido + "Continuação" no topo atende ao núcleo do requisito.

---

## Verificações técnicas (evidências)

- **Fontes incorporadas (PDF/A):** 10 fontes, todas com `ext=embedded` (0 `n/a`). Variantes TNR: `TimesNewRomanPSMT`, `PS-BoldMT`, `PS-ItalicMT`, `PS-BoldItalicMT`. Também `CambriaMath`, `SymbolMT`, `ArialMT`.
- **Conformidade PDF/A:** XMP `pdfaid:part=3`, `pdfaid:conformance=A` → **PDF/A-3a** (Word 2024, `UseISO19005_1=True`).
- **Renderização:** 96/96 páginas renderizadas sem erro (proxy via PyMuPDF; Poppler/Ghostscript não instalados nesta máquina).
- **Contagens:** 28 Figuras, 10 Tabelas, 3 Quadros; 17 tabelas no DOCX; 96 páginas.
- **Itálicos (spot-check):** `Brier` 18/0, `clusters` 1/0, `stateless` 1/0, `datasets` 23/0 (itálico/não-itálico).
- **Sombreamento:** 0 ocorrências de `F2F2F2`.
- **Negrito TOF:** entradas Tabelas 1–10 e Quadros 1–3 todas sem negrito (títulos "LISTA DE…" mantidos em negrito, como seções).

---

## Bloqueios remanescentes (a fase permanece "não concluída")

1. **Dedicatória/Agradecimentos** — elementos opcionais sem texto do autor; mantidos como bloqueio (não deletados, sem placeholder).
2. **Inspeção visual de 100% das páginas** — impossível: o modelo atual (DeepSeek) não lê imagens/documentos. A inspeção foi substituída por verificação textual/estrutural completa (extração de texto por página, contagem de legendas/tabelas, checagem de fontes e renderização sem erro).

---

## Arquivos

- `docs/TCC2_MESTRE_Harliton_Martins.docx` — modificado (96 páginas).
- `docs/TCC2_MESTRE_Harliton_Martins.pdf` — reexportado como PDF/A-3a (96 páginas).
- Backups: `docs/_backup_pre_04c_r2.docx` (pré-R2), `docs/_backup_pre_04c_r2_fields.docx` (pré-atualização de campos).

**Nenhum código, dataset, modelo ou resultado científico foi alterado. Nenhum commit foi realizado.**
