# Relatório — FASE TCC-BANCA-01 (Preparação da apresentação do TCC2)

Data: 2026-09-06
Autor da apresentação: Antônio Hárliton Martins de Souza · IFAM · Engenharia de Software

---

## 1. Arquivos entregues (`docs/slides/tcc2/`)

| Arquivo | Formato | Tamanho | Conteúdo |
|---|---|---|---|
| `Apresentacao_TCC2_Antonio_Harliton.pptx` | PPTX 16:9 | 5,4 MB | Deck de 30 slides, com notas do apresentador em todos |
| `Apresentacao_TCC2_Antonio_Harliton.pdf` | PDF | 1,4 MB | Versão renderizada (30 páginas) |
| `Roteiro_Defesa_TCC2.docx` | DOCX | 41 KB | Roteiro falado slide a slide + tempos |
| `Plano_Demonstracao_App.docx` | DOCX | 37 KB | 14 passos da demo + contingência + checklist |
| `Perguntas_e_Respostas_Banca_TCC2.docx` | DOCX | 45 KB | 43 perguntas com resposta direta, aprofundamento, evidência, ressalva e frases a evitar |
| `render/slide_01..30.png` | PNG | — | Renderização de cada slide para revisão visual do autor |

**Restrições respeitadas (§14):** o documento do TCC2, o código, a API, o aplicativo, os dados, o modelo e as métricas **não** foram modificados. Nenhum modelo foi retreinado. Nenhum resultado foi inventado. Os arquivos originais do TCC1 **não** foram tocados — o deck foi construído a partir de uma **cópia** do PPTX de referência. Nenhum commit foi realizado.

---

## 2. Estrutura do deck (30 slides)

**Principal (24):** Capa · Percurso · Contexto · Problema · Justificativa · Questão/objetivo · DSS · Visão geral · Questionário · IV-DSS · Dados sintéticos · Random Forest · SOM · Fluxo experimental · Resultados RF (comparação) · Resultados RF (hold-out) · Resultados SOM · Funcionamento do app · Integração · Demonstração · Limitações/ética · Contribuições/futuros · Conclusão · Encerramento.

**Apoio (6, após o encerramento, fora do tempo principal):** A1 métricas/calibração · A2 comparação IV-DSS×RF×SOM · A3 domínio/arquitetura · A4 cobertura IV-DSS · A5 caminho de validação · A6 sequência das telas.

---

## 3. Identidade visual — fidelidade ao TCC1

O deck foi construído **reutilizando os masters/layouts/elementos editáveis do TCC1**, por clonagem XML de slides (não uma reconstrução "parecida"):

- **Capa, Percurso e Encerramento** são os slides originais do TCC1 editados (título, subtítulo, orientador, itens do percurso, nome/e-mail).
- **Slides de conteúdo, figura e figura-larga** são clones dos modelos do TCC1 (slides 3, 10 e 14), preservando barra superior `#00314B`, faixa/luz amarela `#FFC000`, logotipos IFAM, tipografia Arial 16 pt, numeração discreta e a hierarquia título→corpo→legenda→fonte.
- **Figuras e legendas** seguem o padrão "Figura N – …" com a **numeração idêntica à do TCC2** (ex.: Figura 6 – Arquitetura; Figura 18 – Comparação por PR-AUC; Figura 28 – proporção por grupo SOM).

**Correções de defeitos aplicadas ao modelo (§1):**
- Slide de encerramento: **sobreposição nome/e-mail corrigida** (nome `y=2,81" h=0,34"`; e-mail `y=3,20"`), acentuação do nome ("HÁRLITON").
- Texto reduzido a **no máximo 5 pontos curtos** por slide; títulos expressam a mensagem; sem parágrafos longos.
- Nenhuma fonte foi reduzida além de 16 pt para acomodar texto; legendas preservam o tamanho do modelo.

---

## 4. Distribuição de tempo (~23 min)

| Bloco | Tempo | Acumulado |
|---|---|---|
| Capa + percurso | 0:25 | 0:25 |
| Introdução (contexto→objetivo) | 3:05 | 3:30 |
| Fundamentação (DSS, IV-DSS) | 2:35 | 6:05 |
| Metodologia (sintéticos, RF, SOM, fluxo) | 3:30 | 9:35 |
| Resultados (RF, SOM) | 2:50 | 12:25 |
| Solução (app, integração) | 1:40 | 14:05 |
| **Demonstração ao vivo** | **5:00** | 19:05 |
| Limitações, contribuições, conclusão | 2:30 | 21:35 |
| Encerramento | 0:10 | 21:45 |

Tempos por slide, transições e marcações de início/fim da demonstração estão no **Roteiro** e nas **notas do apresentador** de cada slide (não nos slides visíveis). O Roteiro traz variantes de **compressão (20 min)** e **aprofundamento (30 min)**.

---

## 5. Fontes factuais

Todo o conteúdo factual vem do **TCC2 definitivo** (`docs/TCC2_MESTRE_Harliton_Martins.docx`) e dos **artefatos reais** do repositório (`ia/artifacts/**`, `docs/figures/**`, código da API/app):

- Métricas RF: PR-AUC médio CV — LR 0,3370 · RF **0,3508** · XGBoost 0,3346; hold-out — ROC-AUC ≈ 0,62 · PR-AUC ≈ 0,34 · Brier ≈ 0,18; **recall zero no limiar 0,5** (Tabelas 4–6, Figuras 18–19).
- SOM: grade 10×10, k=2 por Silhouette (≈0,4309); dois grupos com perfil social distinto e desfecho semelhante (Tabela 10, Figuras 22–28).
- IV-DSS: índice descritivo 0–1, média de seis dimensões com pesos iguais (Figura 3).
- Dados: 5.000 registros sintéticos, ~25% positivo, semente fixa, nenhum dado pessoal real (Figura 4).
- Testes: **605 no Flutter e 440 na API**, 0 falhas/0 pulados; análise estática sem avisos; PostgreSQL com **7 migrações** versionadas (domínio completo).

Nenhuma informação do TCC1 desatualizada foi reaproveitada (sem "rede neural como modelo principal", sem "Django", sem "resultados esperados", sem "será desenvolvido"). Varredura automática confirmou **zero resíduos** desses termos.

---

## 6. Verificações realizadas

- **Estrutural/numérica (automática):** 30 slides × 30 páginas; seções, bullets, legendas, fontes e numeração corretos; imagens dentro dos limites (margem direita ≤ 8,1", base ≤ 5,0"); sobreposição do encerramento corrigida; **nenhum texto fora dos limites da página** (checagem por coordenadas no PDF).
- **Conteúdo:** métricas conferidas contra o TCC2; legendas com numeração idêntica à monografia; notas do apresentador presentes em **todos os 30 slides**.
- **Abertura:** PPTX abre sem reparo no PowerPoint (exportação COM bem-sucedida); PDF com 30 páginas.
- **Renderização:** 30 PNGs gerados em `render/` para conferência visual do autor.

## 7. Limitações e itens que dependem de confirmação do autor

1. **Inspeção visual pixel a pixel não foi possível** (o modelo atual não lê imagens). A verificação foi **estrutural e numérica**; recomenda-se conferir visualmente os PNGs em `render/`, em especial: alinhamento das figuras, contraste das legendas e quebra de linha do título da capa.
2. **Título da capa** é longo (2 linhas); confirmar se a quebra e o tamanho ficaram adequados no slide 1.
3. **Percurso** usa a numeração automática original do TCC1 (1–10) sobre os 10 itens novos; confirmar se os marcadores laterais (barras) continuam alinhados.
4. **Slide 18 (funcionamento do app)** usa a montagem vertical `fig_acompanhamento.png` (retrato); a imagem ficou estreita e centralizada — avaliar se prefere trocar por uma composição horizontal.
5. **Email no encerramento** mantido como `2022000628@ifam.edu.br` (do TCC1); confirmar se é o correto.
6. **Demonstração**: os números/credenciais fictícias e o vídeo de backup (Plano B) precisam ser preparados pelo autor antes da banca (não fazem parte dos arquivos gerados).

---

## 8. Conclusão

Os cinco arquivos de entrega foram gerados com fidelidade visual ao TCC1, conteúdo 100% factual extraído do TCC2 e dos artefatos reais, roteiro com tempos, plano de demonstração com contingência e um banco de 43 perguntas e respostas para a banca. Nenhuma restrição da fase foi violada. Os itens da seção 7 são os únicos pontos que recomendo revisar visualmente antes da defesa.
