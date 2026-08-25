# TCC2 — Matriz Bibliográfica Consolidada (FASE 7A — ETAPA 2)

> **Documento gerado:** FASE 7A — ETAPA 2 "Pesquisa, validação e matriz bibliográfica" — **correção final**.
> **Escopo:** consolidar, validar e classificar a base bibliográfica que sustentará a monografia (~85–95 páginas) do TCC2 "Meu Bebê".
> **Regra de ouro:** nenhum autor, ano, DOI, periódico, página ou URL foi **inferido**; toda metadata foi confirmada em fonte primária (Crossref/DataCite/Europe PMC/DOAJ/SciELO/BVS/PubMed/Repositório USP/página oficial do veículo ou instituição) **ou** está explicitamente marcada como não confirmada.
> **Relaciona-se com:** `TCC2_DOCX_PLAN.md` (inventário e plano, **inalterado nesta etapa**) e `docs/tcc2.md` (fonte técnica consolidada, **inalterada**).

---

## Resumo executivo e contagem consolidada

| Métrica | Valor |
|---|---|
| Referências **distintas** no corpus validado | **85** |
| Herdadas do corpus TCC1 (artigos + institucionais + 3 PDFs) | 25 |
| Externas novas (frentes A–M + trabalhos relacionados + Ayres) | 60 |
| Utilidade **A** (essencial) | 36 |
| Utilidade **B** (muito útil) | 41 |
| Utilidade **C** (complementar) | 2 |
| Utilidade **D** (contextual) | 6 |
| **Status** VALIDADA | 84 |
| **Status** CONFLITO DE METADATA (corrigida) | 1 (SANTORIO et al., 2024) |
| Referências **excluídas** (status EXCLUÍDA — fora do corpus) | 8 |
| Correções de metadata/remap (§7) | 6 (1 conflito + 5 correções) |
| Citações "órfãs" do TCC1 (§4.3) | 6 (1 já resolvida; 5 históricas, a sanar só se citadas) |
| Subseções da monografia **verde** / **amarela** / **vermelha** (§13.2) | 20 / 5 / 0 |

> **Leitura do tamanho do corpus:** a matriz é um **corpus validado/candidato**, não a lista final de REFERÊNCIAS. O total (85) excede o teto de 70 porque a pesquisa externa foi abrangente por orientação da própria etapa. **A lista final de REFERÊNCIAS conterá SOMENTE as obras efetivamente citadas no texto** — não há obrigação de citar as 85. A classificação **A/B** indica **prioridade de uso na redação**; **C/D** são opcionais/contextuais e podem ser descartadas sem prejuízo. Não há "padding": todo excedente corresponde a fonte acadêmica validada.

---

## 1. Metodologia de validação

1. **Extração do corpus local** — `docs/TCC - Hárliton Martins.pdf` foi extraído via `pdftotext` (394 linhas, UTF-8), permitindo reconstruir a lista exata de referências do TCC1 e o mapeamento de citações no texto.
2. **Identificação dos 3 PDFs somente-imagem** — os títulos (com prefixo "View of"/"Vista do", característico de exportação OJS) foram submetidos a busca por título na API Crossref (`query.title`), retornando DOI/autores/ano/veículo.
3. **Validação por DOI** — cada DOI foi resolvido em `https://api.crossref.org/works/<DOI>` (via `urllib` do stdlib; `requests` não instalado), confirmando título, autores, veículo, ano, volume, fascículo e páginas.
4. **Busca por título** — para referências sem DOI registrado no TCC1 (ex.: Nascimento Neto 2020, Nogueira 2022), usou-se `query.title` com variantes PT/EN.
5. **Documentos institucionais / cinzentos** — validação por página oficial (WHO, Planalto/Presidência, OECD, IFAM) via WebSearch/WebFetch, com ISBN quando disponível. **Ayres et al. (2003)** validado via **Repositório USP** (`repositorio.usp.br/item/001528349`), que confirma autores, título do capítulo, livro, editora (Fiocruz), ano e ISBN.
6. **Ferramentas auxiliares** — scripts temporários `cr.py`, `cr2.py` e `validate_batch.py` (com `sys.stdout.reconfigure(encoding='utf-8')` para evitar `UnicodeEncodeError` em cp1252).
7. **Dois eixos independentes** — (a) **UTILIDADE** (A=essencial, B=muito útil, C=complementar, D=contextual): grau de centralidade para a redação; (b) **STATUS** (VALIDADA / CONFLITO DE METADATA / NÃO CONFIRMADA / EXCLUÍDA): grau de confiabilidade da metadata. **Utilidade ≠ status**: uma referência "D" (contextual) pode estar plenamente VALIDADA, e uma referência "EXCLUÍDA" não é classe de utilidade — está fora do corpus.
8. **Peer-review** — campo independente de UTILIDADE e STATUS. **Crossref confirma metadata/DOI, não certifica peer-review**; tampouco o formato de exportação OJS. **SIM** = somente quando confirmado por **política editorial / DOAJ / fonte adequada**; **N/A-inst** = institucional/normativa; **N/A-liv** = livro/capítulo; **NÃO CONFIRMADO** = ausência de confirmação adequada.

---

## 2. Bases de dados e fontes consultadas

| Fonte | Tipo | Uso |
|---|---|---|
| Crossref (`api.crossref.org`) | Registro DOI | Validação primária de DOI (autor, título, veículo, ano, vol., fasc., pág.) |
| DataCite (`api.datacite.org`) | Registro DOI | DOI de preprints/software (ex.: arXiv de Fisher et al. 2019) |
| Europe PMC | Resumos/metadata | Confirmação de resumo de artigos biomédicos |
| DOAJ | Diretório | Confirmação de indexação/peer-review |
| SciELO / BVS | Portais BR | Artigos nacionais (Physis, Saúde em Debate, Rev. Saúde Pública, Cad. Saúde Pública) |
| PubMed | Índice biomédico | Referência cruzada de artigos de saúde |
| Repositório USP (`repositorio.usp.br`) | Repositório institucional | Validação de capítulo de livro (Ayres et al., 2003) |
| Páginas oficiais | Institucional | WHO, Planalto (LGPD), OECD, IFAM, Ministério da Saúde, JMLR |
| WebSearch / WebFetch | Busca dirigida | Normas ABNT/IFAM e documentos cinzentos |

---

## 3. Critérios de inclusão e exclusão

**Inclusão:**
- Artigo revisado por pares (peer-review) **ou** documento institucional canônico (WHO/MS/OECD/legislação) com metadata confirmável.
- Aderência temática às 13 frentes (A pré-natal; B DSS; C vulnerabilidade/índices; D mHealth; E ML saúde materna; F/G/H trabalhos relacionados; I dados sintéticos; J classificação/métricas; K calibração; L IA responsável; M interpretabilidade).
- Português ou inglês.
- Metadata (autor, ano, veículo) confirmada em fonte primária.

**Exclusão:**
- **Preprints** não revisados por pares (medRxiv, Research Square, JMIR Preprints) — regra de rigor adotada.
- **Metadata não confirmável** (resumo ausente no Crossref/Semantic Scholar; texto atrás de paywall sem resumo público).
- **Revisões de literatura** quando o objetivo era um estudo preditivo primário comparável (caso a caso).
- Referências com **URL quebrada** no TCC1 sem DOI alternativo localizável.

---

## 4. Corpus local validado (herdado do TCC1)

### 4.1 Artigos acadêmicos com metadata confirmada (6)

| # | Referência | DOI | Frente | Util. | Capítulo(s) destino |
|---|---|---|---|---|---|
| 1 | BUSS, P. M.; PELLEGRINI FILHO, A. A saúde e seus determinantes sociais. *Physis*, 17(1):77–93, 2007. | 10.1590/S0103-73312007000100006 | B | A | 2.2 |
| 2 | GARBOIS, J. A.; SODRÉ, F.; DALBELLO-ARAUJO, M. Da noção de determinação social à de determinantes sociais da saúde. *Saúde em Debate*, 41(112):63–76, 2017. | 10.1590/0103-1104201711206 | B | A | 2.2 |
| 3 | ROSA, C. Q.; SILVEIRA, D. S.; COSTA, J. S. D. Fatores associados à não realização de pré-natal em município de grande porte. *Rev. Saúde Pública*, 48(6):977–984, 2014. | 10.1590/S0034-8910.2014048005283 | A | A | 2.1 |
| 4 | SANTORIO, K. T.; SANTORIO, K. T.; BARBOSA, C. N. B. Fatores determinantes na realização do pré-natal no Brasil: uma investigação com dados da PNS. *BJHRev*, 7(10):e74857, 2024. | 10.34119/bjhrv7n10-033 | A | A | 2.1 / 2.2 |
| 5 | LOPES, J. F. C. V. et al. Impacto dos Determinantes Sociais no Estado Nutricional e na Assistência Pré-Natal de Gestantes no SUS. *BJIHS*, 6(9):547–563, 2024. | 10.36557/2674-8169.2024v6n9p547-563 | B | B | 2.1 / 2.2 |
| 6 | ALVES, G. G.; TERAZIMA, S. S.; LIMA, J. F. P. K. Inteligência artificial na saúde pública: potenciais e desafios no SUS. *Asclepius*, 4(3):262–267, 2025. | 10.70779/aijshs.v4i3.67 | L | B | 2.4 |

> **Nota (item 4):** a referência "SILVA, D. C. S. et al., 2023" do TCC1 foi **corrigida** para SANTORIO et al., 2024 (ver §7). Status: **CONFLITO DE METADATA** (única do corpus).

### 4.2 Documentos institucionais / literatura cinzenta (herdados do TCC1)

| # | Referência | Util. | Capítulo(s) |
|---|---|---|---|
| 7 | CNDSS / BRASIL. As causas sociais das iniquidades em saúde no Brasil. Rio de Janeiro: Fiocruz, 2008. | A | 2.2 (fonte da Figura 1) |
| 8 | SOLAR, O.; IRWIN, A. A conceptual framework for action on the social determinants of health. Geneva: WHO, 2010. | A | 2.2 |
| 9 | BRASIL. MS. Estratégia de Saúde Digital para o Brasil 2020–2028. 2020. | B | 2.4 / 4 |
| 10 | BRASIL. MS. Importância do Pré-Natal. 2016. | D | 2.1 |
| 11 | BRASIL. MS. Pré-Natal. 2024. | D | 2.1 |
| 12 | BRASIL. MS. SISAB — Indicador Pré-natal. 2024. | C | 2.1 / 5 |
| 13 | KAUFMAN, D. Desmistificando a inteligência artificial. São Paulo: Autêntica, 2022. | B | 2.4 |
| 14 | NASCIMENTO NETO, C. et al. IA e novas tecnologias em saúde. *BJD*, 6(2):9431–9445, 2020. (DOI 10.34117/bjdv6n2-306) | B | 2.4 |
| 15 | NOGUEIRA, A. et al. O uso da IA como ferramenta de apoio à gestão das ações em saúde de Goiás. *Rev. Cient. ESAP-GO*, 8:1–5, 2022. (DOI 10.22491/2447-3405.2022.v8.80004) | D | 2.4 |
| 16 | OMS. Diminuindo diferenças: a prática das políticas sobre DSS. 2011. | B | 2.2 |
| 17 | OMS. Global strategy on digital health 2020–2025. 2020. | B | 2.4 |
| 18 | OMS. Maternal mortality (fact sheet). 2024. | B | 2.1 |
| 19 | OMS. Trends in maternal mortality 2000 to 2017. 2019. | B | 2.1 |
| 20 | FIOCRUZ. DSS — Determinantes Sociais da Saúde (glossário). 2021. | D | 2.2 |
| 21 | IBES. O que são os Determinantes Sociais da Saúde? 2023. | D | 2.2 |
| 22 | WHO. World report on social determinants of health equity. 2025. ISBN 9789240107588. | A | 1 / 2.2 |

### 4.3 Citações "órfãs" do TCC1 (no texto, sem entrada na lista de Referências)

Estas citações aparecem no corpo do TCC1 **mas não possuem entrada** na seção REFERÊNCIAS. O TCC1 é um **documento histórico** (projeto de TCC, já depositado); **não há obrigação de recuperar todas**. Só serão formalizadas as que forem **efetivamente necessárias** à nova monografia:

| Citação (texto TCC1) | Status | Ação |
|---|---|---|
| Dahlgren & Whitehead (1991) | ✅ Resolvida (adicionada via frente B) | Já incluída (ID 32) |
| Diderichsen & Hallqvist (1998) | ⚠ Não validada | Formalizar **apenas se** citada na nova redação |
| Costa et al. (2021) — PNS | ⚠ Não validada | Formalizar **apenas se** citada na nova redação |
| Petrovskiy (2003) | ⚠ Não validada | Citação incomum; descartar se não citada |
| Shortliffe & Cimino (2006) | ⚠ Não validada | Livro canônico (*Biomedical Informatics*); formalizar se citado |
| OMS (2023) — intro | ⚠ Não validada | Remapear para fonte OMS correta (2023/2024) se citada |

---

## 5. Referências externas validadas (por frente temática)

> Convenção de utilidade: **A** essencial · **B** muito útil · **C** complementar · **D** contextual.

### Frente A — Pré-natal e saúde materna
| Ref | Util. |
|---|---|
| VIELLAS, E. F. et al. Assistência pré-natal no Brasil. *Cad. Saúde Pública*, 30(Suppl 1):S85–S100, 2014. DOI 10.1590/0102-311X00126013 | A |
| LEAL, M. C. et al. Saúde reprodutiva, materna, neonatal e infantil nos 30 anos do SUS. *Ciênc. Saúde Coletiva*, 23(6):1915–1928, 2018. DOI 10.1590/1413-81232018236.03942018 | B |
| DEGLI ESPOSTI, C. D. et al. Desigualdades sociais e geográficas no desempenho da assistência pré-natal. *Ciênc. Saúde Coletiva*, 25(5):1735–1750, 2020. DOI 10.1590/1413-81232020255.32852019 | A |
| WHO. WHO recommendations on antenatal care for a positive pregnancy experience. 2016. | A |
| WHO; UNICEF; UNFPA; World Bank; UNDESA. Trends in maternal mortality 2000 to 2020. 2023. | B |
| BRASIL. MS. Portaria GM/MS nº 5.350/2024 — Rede Alyne. 2024. | A |

### Frente B — DSS e saúde materna
| Ref | Util. |
|---|---|
| DAHLGREN, G.; WHITEHEAD, M. Policies and strategies to promote social equity in health. Stockholm: IFS, 1991. | A |
| DAHLGREN, G.; WHITEHEAD, M. The Dahlgren-Whitehead model of health determinants: 30 years on. *Public Health*, 199:20–24, 2021. DOI 10.1016/j.puhe.2021.08.009 | B |
| SOLAR, O.; IRWIN, A. (2010) — *dup* com §4.2 item 8. | A |
| CSDH/WHO. Closing the gap in a generation. 2008. (WHO/IER/CSDH/08.1) | B |
| BUSS & PELLEGRINI FILHO (2007) — *dup* com §4.1 item 1. | A |
| MARMOT, M. Social determinants of health inequalities. *The Lancet*, 365(9464):1099–1104, 2005. DOI 10.1016/S0140-6736(05)71146-6 | B |

### Frente C — Vulnerabilidade e índices compostos
| Ref | Util. |
|---|---|
| AYRES, J. R. C. M.; FRANÇA JÚNIOR, I.; CALAZANS, G. J.; SALETTI FILHO, H. C. O conceito de vulnerabilidade e as práticas de saúde: novas perspectivas e desafios. In: CZERESNIA, D.; FREITAS, C. M. (org.). *Promoção da saúde: conceitos, reflexões, tendências*. Rio de Janeiro: Fiocruz, 2003. ISBN 85-7541-024-5. | A |
| OECD; EC; JRC. Handbook on Constructing Composite Indicators. Paris: OECD, 2008. DOI 10.1787/9789264043466-en | A |
| CUTTER, S. L.; BORUFF, B. J.; SHIRLEY, W. L. Social Vulnerability to Environmental Hazards. *Soc. Sci. Q.*, 84(2):242–261, 2003. DOI 10.1111/1540-6237.8402002 | B |
| ADGER, W. N. Vulnerability. *Global Environ. Change*, 16(3):268–281, 2006. DOI 10.1016/j.gloenvcha.2006.02.006 | B |
| WISNER, B. et al. At Risk: Natural Hazards, People's Vulnerability and Disasters. 2. ed. Routledge, 2004. DOI 10.4324/9780203714775 | B |
| GRECO, S. et al. On the Methodological Framework of Composite Indices. *Soc. Indic. Res.*, 141(1):61–94, 2019. DOI 10.1007/s11205-017-1832-9 | B |
| SALTELLI, A. Composite Indicators between Analysis and Advocacy. *Soc. Indic. Res.*, 81(1):65–77, 2007. DOI 10.1007/s11205-006-0024-9 | B |
| MAZZIOTTA, M.; PARETO, A. Methods for Constructing Non-Compensatory Composite Indices. *Forum Soc. Econ.*, 45(2–3):213–229, 2016. DOI 10.1080/07360932.2014.996912 | C |

> **Nota (Ayres):** Ayres et al. (2003) é a **referência conceitual central** de "vulnerabilidade em saúde ≠ risco". Cutter/Adger/Wisner (vulnerabilidade ambiental/desastres) permanecem **apenas como complementares**.

### Frente D — mHealth
| Ref | Util. |
|---|---|
| FREE, C. et al. The effectiveness of mobile-health technology-based interventions. *PLoS Med.*, 10(1):e1001362, 2013. DOI 10.1371/journal.pmed.1001362 | B |
| LEE, S. H. et al. Effectiveness of mHealth interventions for maternal, newborn and child health in LMICs. *J. Glob. Health*, 6(1):010401, 2016. DOI 10.7189/jogh.06.010401 | B |
| FEROZ, A.; PERVEEN, S.; AFTAB, W. Role of mHealth applications for improving antenatal and postnatal care in LMICs. *BMC Health Serv. Res.*, 17(1):704, 2017. DOI 10.1186/s12913-017-2664-7 | B |
| PALMER, M. J. et al. Targeted client communication via mobile devices. *Cochrane DB Syst. Rev.*, 2020(8):CD013679. DOI 10.1002/14651858.CD013679 | B |
| WATTERSON, J. L.; CASTANEDA, D.; CATALANI, C. Promoting antenatal care attendance through a text messaging intervention in Samoa. *JMIR mHealth uHealth*, 8(6):e15890, 2020. DOI 10.2196/15890 | B |
| IYAWA, G. E.; DANSHARIF, A. R.; KHAN, A. Mobile apps for self-management in pregnancy. *Health Technol.*, 11(2):283–294, 2021. DOI 10.1007/s12553-021-00523-z | B |

### Frente E — ML em saúde materna
| Ref | Util. |
|---|---|
| WILDER, B. et al. Development of Prediction Models for Antenatal Care Attendance. *JAMA Netw. Open*, 6(5):e2315985, 2023. DOI 10.1001/jamanetworkopen.2023.15985 | A |
| YOSEPH, A.; MUSSIE, L.; BELAYNEH, M. Predicting antenatal care dropout using machine learning. *BMJ Open*, 16(7):e111423, 2026. DOI 10.1136/bmjopen-2025-111423 | A |
| SANI, J.; OLUWAGBEMIGA, A.; AHMED, M. M. ML-based prediction of optimal antenatal care utilization. *ML with Applications*, 21:100698, 2025. DOI 10.1016/j.mlwa.2025.100698 | A |

### Frente I — Dados sintéticos e simulação
| Ref | Util. |
|---|---|
| BURTON, A.; ALTMAN, D. G.; ROYSTON, P.; HOLDER, R. L. The design of simulation studies in medical statistics. *Stat. Med.*, 25(24):4279–4292, 2006. DOI 10.1002/sim.2673 | A |
| MORRIS, T. P.; WHITE, I. R.; CROWTHER, M. J. Using simulation studies to evaluate statistical methods. *Stat. Med.*, 38(11):2074–2102, 2019. DOI 10.1002/sim.8086 | A |

> **Nota (Frente I):** Burton (2006) + Morris (2019) são as **referências metodológicas centrais** que sustentam o desenho do DGM e do estudo de simulação. O **seed 42** é decisão técnica/reprodutível do projeto (artefatos internos), **não** da bibliografia. Não se exige saturação adicional e **não** se adiciona CTGAN/GAN como se fosse o método deste projeto (o DGM é um gerador próprio `g_* → eta → sigmoid → Bernoulli`).

### Frente J — Classificação e métricas
| Ref | Util. |
|---|---|
| COURONNÉ, R.; PROBST, P.; BOULESTEIX, A.-L. Random forest versus logistic regression. *BMC Bioinformatics*, 19(1):270, 2018. DOI 10.1186/s12859-018-2264-5 | A |
| BREIMAN, L. Random Forests. *Machine Learning*, 45(1):5–32, 2001. DOI 10.1023/A:1010933404324 | A |
| CHEN, T.; GUESTRIN, C. XGBoost: A Scalable Tree Boosting System. *KDD*, pp. 785–794, 2016. DOI 10.1145/2939672.2939785 | A |
| HOSMER, D. W.; LEMESHOW, S.; STURDIVANT, R. X. Applied Logistic Regression. 3. ed. Wiley, 2013. DOI 10.1002/9781118548387 | A |
| HE, H.; GARCIA, E. A. Learning from Imbalanced Data. *IEEE TKDE*, 21(9):1263–1284, 2009. DOI 10.1109/TKDE.2008.239 | A |
| SAITO, T.; REHMSMEIER, M. The Precision-Recall Plot Is More Informative than the ROC Plot. *PLoS ONE*, 10(3):e0118432, 2015. DOI 10.1371/journal.pone.0118432 | A |
| DAVIS, J.; GOADRICH, M. The relationship between Precision-Recall and ROC curves. *ICML '06*, pp. 233–240, 2006. DOI 10.1145/1143844.1143874 | B |

### Frente K — Calibração
| Ref | Util. |
|---|---|
| BRIER, G. W. Verification of Forecasts Expressed in Terms of Probability. *Mon. Weather Rev.*, 78(1):1–3, 1950. DOI 10.1175/1520-0493(1950)078<0001:VOFEIT>2.0.CO;2 | A |
| GNEITING, T.; RAFTERY, A. E. Strictly Proper Scoring Rules. *JASA*, 102(477):359–378, 2007. DOI 10.1198/016214506000001437 | B |
| STEYERBERG, E. W. Clinical Prediction Models. 2. ed. Springer, 2019. DOI 10.1007/978-3-030-16399-0 | A |
| VAN CALSTER, B. et al. Calibration: the Achilles heel of predictive analytics. *BMC Medicine*, 17(1):230, 2019. DOI 10.1186/s12916-019-1466-7 | A |
| VAN CALSTER, B. et al. A calibration hierarchy for risk models. *J. Clin. Epidemiol.*, 74:167–176, 2016. DOI 10.1016/j.jclinepi.2015.12.005 | B |

### Frente L — IA responsável / ética / relato
| Ref | Util. |
|---|---|
| WHO. Ethics and Governance of Artificial Intelligence for Health. 2021. ISBN 978-92-4-002920-0 | A |
| WHO. Regulatory Considerations on Artificial Intelligence for Health. 2023. ISBN 978-92-4-007887-1 | B |
| WHO. Ethics and Governance of AI for Health: Guidance on Large Multi-modal Models. 2025. ISBN 978-92-4-008475-9 | D |
| BRASIL. Lei nº 13.709/2018 (LGPD). 2018. | B |
| OBERMEYER, Z. et al. Dissecting Racial Bias in an Algorithm. *Science*, 366(6464):447–453, 2019. DOI 10.1126/science.aax2342 | A |
| COLLINS, G. S. et al. TRIPOD Statement. *Ann. Intern. Med.*, 162(1):55–63, 2015. DOI 10.7326/M14-0697 | A |
| WOLFF, R. F. et al. PROBAST. *Ann. Intern. Med.*, 170(1):51–58, 2019. DOI 10.7326/M18-1376 | A |

### Frente M — Interpretabilidade
| Ref | Util. |
|---|---|
| FISHER, A.; RUDIN, C.; DOMINICI, F. All Models are Wrong, but Many are Useful. *JMLR*, 20(177):1–81, 2019. (sem DOI; URL oficial https://jmlr.org/papers/v20/18-760.html) | A |
| STROBL, C. et al. Bias in random forest variable importance measures. *BMC Bioinformatics*, 8(1):25, 2007. DOI 10.1186/1471-2105-8-25 | B |
| ALTMANN, A. et al. Permutation importance: a corrected feature importance measure. *Bioinformatics*, 26(10):1340–1347, 2010. DOI 10.1093/bioinformatics/btq134 | B |
| HOOKER, G.; MENTCH, L.; ZHOU, S. Unrestricted permutation forces extrapolation. *Stat. Comput.*, 31(6):82, 2021. DOI 10.1007/s11222-021-10057-z | A |

---

## 6. Identificação dos 3 PDFs somente-imagem (itens 12–14 do plano)

Metadata recuperada via Crossref (título → DOI). Estes PDFs **só continham imagem**, sem texto extraível; a identificação é resultado desta etapa.

| # | Título (arquivo) | Referência identificada | DOI | Util. |
|---|---|---|---|---|
| P1 | Social Determinants of Health in prenatal care: a multidisciplinary view in Primary Health Care | ROCHA, C. G. G.; HEIDEMANN, I. T. S. B.; SOUZA, J. B.; DURAND, M. K.; MACIEL, K. S.; SIMAS, L. T. L. Determinantes Sociais da Saúde no pré-natal: um olhar multiprofissional na Atenção Primária. *Research, Society and Development*, 10(3):e50510313434, 2021. | 10.33448/rsd-v10i3.13434 | B |
| P2 | Social determinants of health of high-risk pregnant women during prenatal follow-up | GADELHA, I. P.; DINIZ, F. F.; AQUINO, P. S.; SILVA, D. M.; BALSELLS, M. M. D.; PINHEIRO, A. K. B. Determinantes sociais da saúde de gestantes acompanhadas no pré-natal de alto risco. *Rev Rene*, 21:e42198, 2020. | 10.15253/2175-6783.20202142198 | B |
| P3 | Determinantes sociais da saúde na consulta de enfermagem do pré-natal | ROCHA, C. G. G.; HEIDEMANN, I. T. S. B.; RUMOR, P. C. F.; ANTONINI, F. O.; DURAND, M. K.; MAGAGNIN, A. B. Determinantes sociais da saúde na consulta de enfermagem do pré-natal. *Revista de Enfermagem UFPE on line*, 13, 2019. | 10.5205/1981-8963.2019.241571 | B |

> **Nota (peer-review):** Crossref confirma **metadata/DOI**, **não** certifica peer-review; tampouco o formato de exportação OJS é evidência de revisão por pares. Os três PDFs permanecem **no corpus** com metadata VALIDADA (autores/título/veículo/DOI via Crossref), mas seu status de peer-review fica **NÃO CONFIRMADO** até haver confirmação por política editorial/DOAJ/fonte adequada — o campo "Peer" da matriz (§10) registra isso por referência.

---

## 7. Conflitos e correções de metadata

| # | Problema detectado | Correção aplicada | Status |
|---|---|---|---|
| 1 | TCC1 cita "SILVA, D. C. S. et al. Fatores determinantes… 2023" (DOI 10.34119/bjhrv7n10-033) — autores e ano **incorretos**. Crossref mostra SANTORIO, K. T.; SANTORIO, K. T.; BARBOSA, C. N. B., *BJHRev* 7(10):e74857, **2024**. | Renomear para **SANTORIO et al., 2024** | CONFLITO DE METADATA |
| 2 | TCC1 lista o mesmo artigo acima também sob "REVISTA BRASILEIRA DE SAÚDE MATERNO INFANTIL" (veículo errado) — **duplicata**. | Fundir em uma única entrada (SANTORIO et al., 2024); descartar a entrada de veículo errado | correção |
| 3 | URL do artigo de GARBOIS et al. (2017) no TCC1 está **corrompida** (contém "PWHITEHEAD" embutido). | Usar DOI 10.1590/0103-1104201711206 (SciELO) | correção |
| 4 | Item 3 do corpus ("Fatores associados à não realização de pré-natal", Rev. Saúde Pública 2014) tinha autor "não legível". | Autores confirmados: ROSA, C. Q.; SILVEIRA, D. S.; COSTA, J. S. D. | correção |
| 5 | Dahlgren & Whitehead (1991) citado no texto do TCC1 **sem entrada** na lista de referências. | Incluir entrada canônica (IFS, Stockholm, 1991) | correção |
| 6 | "OMS (2023)" citado na introdução do TCC1 sem entrada correspondente. | Remapear para a fonte OMS correta (2023/2024) **se** citada na nova redação | correção |

---

## 8. Referências excluídas (com justificativa — status EXCLUÍDA, fora do corpus)

| # | Referência | Motivo da exclusão |
|---|---|---|
| 1 | Rahman, M. O. et al. Effects of mHealth interventions on improving antenatal care visits… (DOI 10.2196/preprints.34061) | Preprint JMIR, não revisado por pares |
| 2 | Kant, R. et al. Impact of mHealth interventions on antenatal and postnatal care utilization… (DOI 10.1101/2020.12.22.20248713) | Preprint medRxiv |
| 3 | Nationwide Prediction of Missed and Cancelled Appointments… (DOI 10.64898/2026.04.08.26349942) | Preprint medRxiv |
| 4 | Predicting Adequate ANC Utilization… Kenya… (DOI 10.21203/rs.3.rs-9093496/v1) | Preprint Research Square |
| 5 | Exploring ML Algorithms for Predicting Early ANC Initiation… Nigeria (DOI 10.21203/rs.3.rs-5321613/v1) | Preprint Research Square |
| 6 | Enhancing Maternal Health Risk Prediction Using ML-Based Data Augmentation (IEEE IWCMC) | Resumo não confirmável (ausente no Crossref/Semantic Scholar; paywall) |
| 7 | Machine Learning Methods for Pregnancy and Childbirth Risk Management (PMC10303537) | Revisão de literatura, não estudo preditivo primário comparável |
| 8 | Mazziotta & Pareto (2013) "Methods for constructing composite indices: One for all or all for one?" | Sem registro/DOI localizável; substituída pela edição de 2016 (Frente C) |

> **STATUS EXCLUÍDA ≠ classe D.** As 8 referências acima estão **fora do corpus**; "D" (§10) é a classe de utilidade *contextual*, aplicada a referências **validadas** de baixa centralidade.

---

## 9. Deduplicação e classificação (UTILIDADE × STATUS)

**Deduplicações aplicadas (evita contagem dupla):**
- SOLAR & IRWIN (2010): aparece no corpus TCC1 (§4.2) **e** na Frente B → contada **1×**.
- BUSS & PELLEGRINI FILHO (2007): corpus TCC1 (§4.1) **e** Frente B → **1×**.
- SANI et al. (2025): Frente E **e** Trabalhos Relacionados → **1×**.
- DAHLGREN & WHITEHEAD (1991): só em texto no TCC1 + Frente B → **1×**.

**Distribuição de UTILIDADE (85 referências distintas):**

| Classe | Critério | Qtd. |
|---|---|---|
| **A** | Essencial — sem ela uma afirmação central ou método desmorona (fonte metodológica/conceitual nuclear ou diretriz canônica) | 36 |
| **B** | Muito útil — fortalece, mas não é a única fonte possível | 41 |
| **C** | Complementar — nuance técnica específica, substituível | 2 |
| **D** | Contextual — página institucional/notícia/glossário; não sustenta afirmação central | 6 |

**Distribuição de STATUS (85 referências distintas):**

| Status | Critério | Qtd. |
|---|---|---|
| **VALIDADA** | metadata confirmada em fonte primária | 84 |
| **CONFLITO DE METADATA** | metadata corrigida (SANTORIO et al., 2024) | 1 |
| **NÃO CONFIRMADA** | metadata não confirmável | 0 (no corpus; as órfãs ficam no §4.3) |
| **EXCLUÍDA** | fora do corpus (§8) | 8 |

> **Recalibração A/B/C/D (vs. versão anterior):** 9 referências desceram de A → B (LEAL 2018; LEE 2016; FEROZ 2017; PALMER 2020; GRECO 2019; DAVIS & GOADRICH 2006; VAN CALSTER 2016; STROBL 2007; PATEL 2026) por serem "muito úteis" e não "essenciais"; 6 referências de literatura cinzenta desceram de C → D (BRASIL MS *Importância* 2016; *Pré-Natal* 2024; NOGUEIRA 2022; FIOCRUZ glossário 2021; IBES 2023; WHO LMM 2025); AYRES et al. (2003) entrou como A. Resultado: **A=36, B=41, C=2, D=6**.

---

## 10. Matriz bibliográfica detalhada — registro consolidado do corpus

> **Colunas:** ID · Referência (ABNT abreviada) · Ano · **Tipo** (ART artigo / CONF conferência / LIV livro·capítulo / INST institucional·normativa / REL relatório) · **Status** (VAL validada / CONF-META conflito) · **Peer-review** (SIM · confirmado por política editorial/DOAJ/fonte adequada / NÃO / NÃO CONFIRMADO / N/A-inst · institucional-normativa / N/A-liv · livro-capítulo) · **Fonte** (1ª primária / 2ª secundária) · **DOI ou URL oficial** · **Local?** (PDF no inventário) · **Frente** · **Cap./Subseção** · **Afirmação que sustenta** · **O que NÃO sustenta / limitações de uso** · **Util.** · **Observações**.

| ID | Referência (ABNT) | Ano | Tipo | Status | Peer | Fonte | DOI / URL oficial | Local | Frente | Cap./Sub | Afirmação que sustenta | Não sustenta / limitações | Util. | Obs. |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 01 | BUSS, P. M.; PELLEGRINI FILHO, A. A saúde e seus determinantes sociais | 2007 | ART | VAL | SIM | 2ª | 10.1590/S0103-73312007000100006 | sim | B | 2.2 | DSS como conceito e agenda | Não cobre DSS em saúde materna nem ML | A | Ensaio fundador (Physis) |
| 02 | GARBOIS, J. A.; SODRÉ, F.; DALBELLO-ARAUJO, M. Da noção de determinação social à de determinantes sociais da saúde | 2017 | ART | VAL | SIM | 2ª | 10.1590/0103-1104201711206 | sim | B | 2.2 | Distinção determinação social × determinantes sociais | Crítica conceitual; sem método de mensuração | A | URL TCC1 corrompida → DOI |
| 03 | ROSA, C. Q.; SILVEIRA, D. S.; COSTA, J. S. D. Fatores associados à não realização de pré-natal | 2014 | ART | VAL | SIM | 1ª | 10.1590/S0034-8910.2014048005283 | sim | A | 2.1 | Fatores associados à não realização do pré-natal | "Não realização" ≠ "descontinuidade" (desfecho distinto) | A | Autor recuperado (§7.4) |
| 04 | SANTORIO, K. T.; SANTORIO, K. T.; BARBOSA, C. N. B. Fatores determinantes na realização do pré-natal (PNS) | 2024 | ART | CONF-META | SIM | 1ª | 10.34119/bjhrv7n10-033 | não | A | 2.1/2.2 | Determinantes do pré-natal com dados da PNS | Não trata de ML preditivo | A | TCC1 citava "SILVA et al. 2023" |
| 05 | LOPES, J. F. C. V. et al. Impacto dos DSS no estado nutricional e na assistência pré-natal | 2024 | ART | VAL | SIM | 1ª | 10.36557/2674-8169.2024v6n9p547-563 | não | B | 2.1/2.2 | DSS e estado nutricional na assistência pré-natal | Escopo nutricional; sem ML | B | |
| 06 | ALVES, G. G.; TERAZIMA, S. S.; LIMA, J. F. P. K. IA na saúde pública: potenciais e desafios no SUS | 2025 | ART | VAL | SIM | 2ª | 10.70779/aijshs.v4i3.67 | não | L | 2.4 | IA na saúde pública/SUS | Perspectiva geral; não é ML preditivo | B | |
| 07 | CNDSS/BRASIL. As causas sociais das iniquidades em saúde no Brasil | 2008 | REL | VAL | N/A-inst | 2ª | — (sem DOI) | não | B | 2.2 | Fonte da Figura 1 (Dahlgren & Whitehead); iniquidades | Relatório; sem DOI | A | |
| 08 | SOLAR, O.; IRWIN, A. A conceptual framework for action on the SDH | 2010 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | B | 2.2 | Framework CSDH; camadas dos DSS | Discussion paper; sem DOI | A | |
| 09 | BRASIL. MS. Estratégia de Saúde Digital 2020–2028 | 2020 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | L | 2.4/4 | Contexto de saúde digital no Brasil | Não trata de ML preditivo | B | |
| 10 | BRASIL. MS. Importância do Pré-Natal | 2016 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | A | 2.1 | Contexto da importância do pré-natal | Página informativa; substituível | D | |
| 11 | BRASIL. MS. Pré-Natal | 2024 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | A | 2.1 | Contexto do pré-natal no SUS | Página informativa | D | |
| 12 | BRASIL. MS. SISAB — Indicador Pré-natal | 2024 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | A | 2.1/5 | Indicador de cobertura pré-natal (SISAB) | Indicador administrativo | C | Ancora contexto de dados |
| 13 | KAUFMAN, D. Desmistificando a inteligência artificial | 2022 | LIV | VAL | N/A-liv | 2ª | — (e-book) | não | L | 2.4 | Divulgação de IA | Não é fonte técnica primária | B | |
| 14 | NASCIMENTO NETO, C. et al. IA e novas tecnologias em saúde | 2020 | ART | VAL | SIM | 2ª | 10.34117/bjdv6n2-306 | não | L | 2.4 | IA e novas tecnologias em saúde | Genérico; não é ML preditivo | B | |
| 15 | NOGUEIRA, A. et al. IA como ferramenta de apoio à gestão… Goiás | 2022 | ART | VAL | SIM | 2ª | 10.22491/2447-3405.2022.v8.80004 | não | L | 2.4 | IA na gestão em saúde | Regional/gestão; uso seletivo | D | |
| 16 | OMS. Diminuindo diferenças: a prática das políticas sobre DSS | 2011 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | B | 2.2 | Políticas sobre DSS | Sem DOI | B | |
| 17 | OMS. Global strategy on digital health 2020–2025 | 2020 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | L | 2.4 | Estratégia global de saúde digital | Sem DOI | B | |
| 18 | OMS. Maternal mortality (fact sheet) | 2024 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | A | 2.1 | Mortalidade materna global | Fact sheet | B | |
| 19 | OMS. Trends in maternal mortality 2000 to 2017 | 2019 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | A | 2.1 | Tendência de mortalidade materna | Estatística agregada | B | |
| 20 | FIOCRUZ. DSS — Determinantes Sociais da Saúde (glossário) | 2021 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | B | 2.2 | Definição de DSS | Glossário | D | |
| 21 | IBES. O que são os Determinantes Sociais da Saúde? | 2023 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | B | 2.2 | Divulgação de DSS | Página institucional | D | |
| 22 | WHO. World report on social determinants of health equity | 2025 | INST | VAL | N/A-inst | 2ª | ISBN 9789240107588 | sim | B | 1/2.2 | Equidade em saúde; DSS | Sem DOI | A | PDF na raiz do repo |
| 23 | ROCHA, C. G. G. et al. DSS no pré-natal: um olhar multiprofissional na APS | 2021 | ART | VAL | NÃO CONFIRMADO | 1ª | 10.33448/rsd-v10i3.13434 | sim | B | 2.1/2.2 | DSS no pré-natal (APS) | PDF somente-imagem | B | |
| 24 | GADELHA, I. P. et al. DSS de gestantes no pré-natal de alto risco | 2020 | ART | VAL | NÃO CONFIRMADO | 1ª | 10.15253/2175-6783.20202142198 | sim | B | 2.1/2.2 | DSS no pré-natal de alto risco | PDF somente-imagem | B | |
| 25 | ROCHA, C. G. G. et al. DSS na consulta de enfermagem do pré-natal | 2019 | ART | VAL | NÃO CONFIRMADO | 1ª | 10.5205/1981-8963.2019.241571 | sim | B | 2.1/2.2 | DSS na consulta de enfermagem pré-natal | PDF somente-imagem | B | |
| 26 | VIELLAS, E. F. et al. Assistência pré-natal no Brasil | 2014 | ART | VAL | SIM | 1ª | 10.1590/0102-311X00126013 | não | A | 2.1 | Assistência pré-natal no Brasil (Nascer no Brasil) | Análise de adequação; sem ML | A | |
| 27 | LEAL, M. C. et al. Saúde reprodutiva, materna, neonatal e infantil nos 30 anos do SUS | 2018 | ART | VAL | SIM | 2ª | 10.1590/1413-81232018236.03942018 | não | A | 2.1 | Panorama 30 anos SUS (saúde materna) | Panorâmico | B | rebaixada A→B |
| 28 | DEGLI ESPOSTI, C. D. et al. Desigualdades sociais e geográficas no desempenho do pré-natal | 2020 | ART | VAL | SIM | 1ª | 10.1590/1413-81232020255.32852019 | não | A | 2.1 | Desigualdades no desempenho do pré-natal | Sem ML | A | |
| 29 | WHO. WHO recommendations on antenatal care for a positive pregnancy experience | 2016 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | A | 2.1 | Diretriz canônica de pré-natal | Sem DOI | A | |
| 30 | WHO; UNICEF; UNFPA; World Bank; UNDESA. Trends in maternal mortality 2000–2020 | 2023 | INST | VAL | N/A-inst | 2ª | ISBN 9789240068759 | não | A | 2.1 | Tendência de mortalidade materna | Estatística agregada | B | |
| 31 | BRASIL. MS. Portaria GM/MS nº 5.350/2024 — Rede Alyne | 2024 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | A | 1/2.1 | Política nacional de atenção materno-infantil | Norma; sem DOI | A | |
| 32 | DAHLGREN, G.; WHITEHEAD, M. Policies and strategies to promote social equity in health | 1991 | INST | VAL | N/A-inst | 2ª | — (sem URL estável) | não | B | 2.2 | Modelo em camadas dos DSS | Sem URL estável (pré-digital) | A | Apoiada por 33 |
| 33 | DAHLGREN, G.; WHITEHEAD, M. The Dahlgren-Whitehead model: 30 years on | 2021 | ART | VAL | SIM | 2ª | 10.1016/j.puhe.2021.08.009 | não | B | 2.2 | Atualização do modelo D-W | Sem dados BR | B | |
| 34 | CSDH/WHO. Closing the gap in a generation | 2008 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | B | 2.2 | Ação sobre DSS (CSDH) | Sem DOI | B | |
| 35 | MARMOT, M. Social determinants of health inequalities | 2005 | ART | VAL | SIM | 2ª | 10.1016/S0140-6736(05)71146-6 | não | B | 2.2 | Desigualdades em saúde | Ensaio; sem ML | B | |
| 36 | FREE, C. et al. The effectiveness of mHealth technology-based interventions | 2013 | ART | VAL | SIM | 2ª | 10.1371/journal.pmed.1001362 | não | D | 2.4 | Efetividade de mHealth | Revisão; não específica de pré-natal | B | |
| 37 | LEE, S. H. et al. Effectiveness of mHealth interventions for MNCH in LMICs | 2016 | ART | VAL | SIM | 2ª | 10.7189/jogh.06.010401 | não | D | 2.4 | mHealth MNCH em LMICs | Revisão; não é estudo preditivo | B | rebaixada A→B |
| 38 | FEROZ, A.; PERVEEN, S.; AFTAB, W. Role of mHealth applications for antenatal/postnatal care | 2017 | ART | VAL | SIM | 2ª | 10.1186/s12913-017-2664-7 | não | D | 2.4 | mHealth no pré-natal | Revisão; não preditivo | B | rebaixada A→B |
| 39 | PALMER, M. J. et al. Targeted client communication via mobile devices | 2020 | ART | VAL | SIM | 2ª | 10.1002/14651858.CD013679 | não | D | 2.4 | Comunicação dirigida (Cochrane) | Revisão Cochrane; não preditivo | B | rebaixada A→B |
| 40 | WATTERSON, J. L.; CASTANEDA, D.; CATALANI, C. Promoting antenatal care via text messaging (Samoa) | 2020 | ART | VAL | SIM | 1ª | 10.2196/15890 | não | D | 2.4 | SMS e comparecimento pré-natal | Caso único (Samoa) | B | |
| 41 | IYAWA, G. E.; DANSHARIF, A. R.; KHAN, A. Mobile apps for self-management in pregnancy | 2021 | ART | VAL | SIM | 2ª | 10.1007/s12553-021-00523-z | não | D | 2.4 | Apps para gestantes | Revisão; não preditivo | B | |
| 42 | OECD; EC; JRC. Handbook on Constructing Composite Indicators | 2008 | INST | VAL | N/A-inst | 2ª | 10.1787/9789264043466-en | não | C | 3.3 | Metodologia de índices compostos | Não específico de saúde | A | Base do IV-DSS |
| 43 | CUTTER, S. L.; BORUFF, B. J.; SHIRLEY, W. L. Social Vulnerability to Environmental Hazards (SoVI) | 2003 | ART | VAL | SIM | 1ª | 10.1111/1540-6237.8402002 | não | C | 2.3 | Índice de vulnerabilidade social | Foco ambiental/desastres | B | Complementar |
| 44 | ADGER, W. N. Vulnerability | 2006 | ART | VAL | SIM | 2ª | 10.1016/j.gloenvcha.2006.02.006 | não | C | 2.3 | Conceito de vulnerabilidade | Foco ambiental | B | Complementar |
| 45 | WISNER, B. et al. At Risk (2. ed.) | 2004 | LIV | VAL | N/A-liv | 2ª | 10.4324/9780203714775 | não | C | 2.3 | Vulnerabilidade a desastres | Foco ambiental | B | Complementar |
| 46 | GRECO, S. et al. On the Methodological Framework of Composite Indices | 2019 | ART | VAL | SIM | 2ª | 10.1007/s11205-017-1832-9 | não | C | 3.3 | Framework metodológico de índices | Não específico de saúde | B | rebaixada A→B |
| 47 | SALTELLI, A. Composite Indicators between Analysis and Advocacy | 2007 | ART | VAL | SIM | 2ª | 10.1007/s11205-006-0024-9 | não | C | 3.3 | Robustez/advocacia de índices | Não específico | B | |
| 48 | MAZZIOTTA, M.; PARETO, A. Methods for Constructing Non-Compensatory Composite Indices | 2016 | ART | VAL | SIM | 2ª | 10.1080/07360932.2014.996912 | não | C | 3.3 | Índices não compensatórios | Não específico de saúde | C | |
| 49 | WILDER, B. et al. Development of Prediction Models for ANC Attendance | 2023 | ART | VAL | SIM | 1ª | 10.1001/jamanetworkopen.2023.15985 | não | E | 2.5/5.2 | ML preditivo para comparecimento ANC | Desfecho comparecimento ≠ descontinuidade | A | Trabalho relacionado chave |
| 50 | YOSEPH, A.; MUSSIE, L.; BELAYNEH, M. Predicting antenatal care dropout using ML | 2026 | ART | VAL | SIM | 1ª | 10.1136/bmjopen-2025-111423 | não | E | 2.5/5.2 | ML para descontinuidade/abandono do pré-natal | Definição operacional própria de "dropout" | A | Mais próximo do desfecho do TCC |
| 51 | SANI, J.; OLUWAGBEMIGA, A.; AHMED, M. M. ML-based prediction of optimal ANC utilization | 2025 | ART | VAL | SIM | 1ª | 10.1016/j.mlwa.2025.100698 | não | E | 2.5/5.2 | ML para utilização ótima de ANC | "Ótimo" ≠ "descontinuidade" | A | |
| 52 | BURTON, A. et al. The design of simulation studies in medical statistics | 2006 | ART | VAL | SIM | 2ª | 10.1002/sim.2673 | não | I | 3.6 | Desenho de estudos de simulação | Estatística médica geral | A | Central p/ DGM |
| 53 | MORRIS, T. P.; WHITE, I. R.; CROWTHER, M. J. Using simulation studies to evaluate statistical methods | 2019 | ART | VAL | SIM | 2ª | 10.1002/sim.8086 | não | I | 3.6 | Método de estudos de simulação | Tutorial; não é dado sintético de saúde | A | Central p/ DGM |
| 54 | COURONNÉ, R.; PROBST, P.; BOULESTEIX, A.-L. Random forest versus logistic regression | 2018 | ART | VAL | SIM | 1ª | 10.1186/s12859-018-2264-5 | não | J | 3.8/5.2 | Comparação RF × RL | Não cobre XGBoost | A | |
| 55 | BREIMAN, L. Random Forests | 2001 | ART | VAL | SIM | 1ª | 10.1023/A:1010933404324 | não | J | 3.8 | Algoritmo RF | Fonte original | A | |
| 56 | CHEN, T.; GUESTRIN, C. XGBoost | 2016 | CONF | VAL | SIM | 1ª | 10.1145/2939672.2939785 | não | J | 3.8 | Algoritmo XGBoost | Conferência | A | |
| 57 | HOSMER, D. W.; LEMESHOW, S.; STURDIVANT, R. X. Applied Logistic Regression (3. ed.) | 2013 | LIV | VAL | N/A-liv | 2ª | 10.1002/9781118548387 | não | J | 3.8 | Regressão logística | Livro-texto | A | |
| 58 | HE, H.; GARCIA, E. A. Learning from Imbalanced Data | 2009 | ART | VAL | SIM | 2ª | 10.1109/TKDE.2008.239 | não | J | 3.10/5.3 | Desbalanceamento de classes | Survey | A | |
| 59 | SAITO, T.; REHMSMEIER, M. The Precision-Recall Plot Is More Informative than the ROC Plot | 2015 | ART | VAL | SIM | 1ª | 10.1371/journal.pone.0118432 | não | J | 3.10/5.3 | PR-AUC vs ROC sob desbalanceamento | Não trata de calibração | A | |
| 60 | DAVIS, J.; GOADRICH, M. The relationship between PR and ROC curves | 2006 | CONF | VAL | SIM | 1ª | 10.1145/1143844.1143874 | não | J | 3.10 | Relação PR–ROC | Conferência | B | rebaixada A→B |
| 61 | BRIER, G. W. Verification of Forecasts Expressed in Terms of Probability | 1950 | ART | VAL | SIM | 1ª | 10.1175/1520-0493(1950)078<0001:VOFEIT>2.0.CO;2 | não | K | 3.10/5.5 | Brier score | Fonte original | A | |
| 62 | GNEITING, T.; RAFTERY, A. E. Strictly Proper Scoring Rules | 2007 | ART | VAL | SIM | 2ª | 10.1198/016214506000001437 | não | K | 3.10/5.5 | Regras de pontuação próprias | Não específico de saúde | B | |
| 63 | STEYERBERG, E. W. Clinical Prediction Models (2. ed.) | 2019 | LIV | VAL | N/A-liv | 2ª | 10.1007/978-3-030-16399-0 | não | K | 3.9/5.5 | Modelos preditivos clínicos | Livro-texto | A | |
| 64 | VAN CALSTER, B. et al. Calibration: the Achilles heel of predictive analytics | 2019 | ART | VAL | SIM | 2ª | 10.1186/s12916-019-1466-7 | não | K | 3.10/5.5 | Importância da calibração | Não específico de pré-natal | A | |
| 65 | VAN CALSTER, B. et al. A calibration hierarchy for risk models | 2016 | ART | VAL | SIM | 2ª | 10.1016/j.jclinepi.2015.12.005 | não | K | 5.5 | Hierarquia de calibração | Complementar ao 64 | B | rebaixada A→B |
| 66 | WHO. Ethics and Governance of AI for Health | 2021 | INST | VAL | N/A-inst | 2ª | ISBN 978-92-4-002920-0 | não | L | 3.12 | Ética/governança de IA em saúde | Sem DOI | A | |
| 67 | WHO. Regulatory Considerations on AI for Health | 2023 | INST | VAL | N/A-inst | 2ª | ISBN 978-92-4-007887-1 | não | L | 3.12 | Regulação de IA em saúde | Sem DOI | B | |
| 68 | WHO. Ethics and Governance of AI: Guidance on LMM | 2025 | INST | VAL | N/A-inst | 2ª | ISBN 978-92-4-008475-9 | não | L | 3.12 | IA multimodal (LLM) | Tangencial (projeto usa RF/RL/XGBoost) | D | |
| 69 | BRASIL. Lei nº 13.709/2018 (LGPD) | 2018 | INST | VAL | N/A-inst | 2ª | — (sem DOI) | não | L | 3.12 | Privacidade de dados | Norma; sem DOI | B | |
| 70 | OBERMEYER, Z. et al. Dissecting Racial Bias in an Algorithm | 2019 | ART | VAL | SIM | 1ª | 10.1126/science.aax2342 | não | L | 3.12/5.10 | Viés algorítmico | Exemplo EUA, não pré-natal | A | |
| 71 | COLLINS, G. S. et al. TRIPOD Statement | 2015 | ART | VAL | SIM | 2ª | 10.7326/M14-0697 | não | L | 3.9/5.10 | Relato transparente de modelos | Guideline de relato | A | |
| 72 | WOLFF, R. F. et al. PROBAST | 2019 | ART | VAL | SIM | 2ª | 10.7326/M18-1376 | não | L | 5.10 | Risco de viés em modelos | Guideline de avaliação | A | |
| 73 | FISHER, A.; RUDIN, C.; DOMINICI, F. All Models are Wrong, but Many are Useful | 2019 | ART | VAL | SIM | 1ª | URL jmlr.org/papers/v20/18-760.html (sem DOI) | não | M | 5.7 | Importância de variáveis (model class reliance) | JMLR **sem DOI** | A | DOI 10.48550/arXiv.1801.01489 é só o preprint |
| 74 | STROBL, C. et al. Bias in random forest variable importance measures | 2007 | ART | VAL | SIM | 1ª | 10.1186/1471-2105-8-25 | não | M | 5.7 | Viés de importância (Gini) | Complementar | B | rebaixada A→B |
| 75 | ALTMANN, A. et al. Permutation importance: a corrected feature importance measure | 2010 | ART | VAL | SIM | 1ª | 10.1093/bioinformatics/btq134 | não | M | 5.7 | Importância por permutação | Complementar | B | |
| 76 | HOOKER, G.; MENTCH, L.; ZHOU, S. Unrestricted permutation forces extrapolation | 2021 | ART | VAL | SIM | 1ª | 10.1007/s11222-021-10057-z | não | M | 5.7 | Limites da importância por permutação | Não específico de saúde | A | |
| 77 | ADEM, J. B. et al. Modeling predictors of incomplete ANC utilization (Ethiopia) | 2026 | ART | VAL | SIM | 1ª | 10.1371/journal.pdig.0001489 | não | F | 2.5 | ML p/ ANC incompleta (Etiópia) | "Incompleto" ≠ "descontinuidade" | A | |
| 78 | KHADIDOS, A. O. et al. Ensemble ML for maternal health risk | 2024 | ART | VAL | SIM | 1ª | 10.1038/s41598-024-71934-x | não | F | 2.5 | Ensemble p/ risco materno | Multiclasse; sem DSS | B | |
| 79 | OSBORNE, A. et al. Hierarchical ML for ANC utilisation (Nigeria) | 2026 | ART | VAL | SIM | 1ª | 10.1186/s13040-026-00538-0 | não | F | 2.5 | ML hierárquico p/ ANC | Multiclasse | A | |
| 80 | BAYKEMAGN, N. D. et al. Predicting delayed ANC initiation (East Africa) | 2025 | ART | VAL | SIM | 1ª | 10.3389/fgwh.2025.1488391 | não | F | 2.5 | ML p/ início tardio ANC | "Início tardio" ≠ "descontinuidade" | B | |
| 81 | PATEL, S. Y.; AKILESWARAN, C.; BASU, S. Early detection of high risk pregnancies (clinical+social) | 2026 | ART | VAL | SIM | 1ª | 10.1038/s44482-025-00003-5 | não | F | 2.5 | Risco de gravidez + SDoH | Desfecho clínico; EUA | B | rebaixada A→B |
| 82 | YANG, Y.; MADANIAN, S.; PARRY, D. Predicting missed appointments in health care | 2024 | ART | VAL | SIM | 1ª | 10.2196/48273 | não | F | 2.5 | No-show em consultas | Consultas gerais; não pré-natal | B | |
| 83 | PRABA, G. C.; VANI, V.; SUGANYA, G. Synthetic dataset based maternal health risk prediction | 2026 | ART | VAL | SIM | 1ª | 10.1007/s42979-026-04939-0 | não | I | 2.5 | Dados sintéticos p/ risco materno | Multiclasse; sem DSS/app | B | |
| 84 | ADEOLA, L.; IWENDI, C.; AKEREN, K. ML to predict and monitor maternal health risk (Materna) | 2025 | CONF | VAL | SIM | 1ª | 10.1109/ieeeconf64992.2025.10963030 | não | D | 2.5 | App/questionário p/ risco materno | Web (não Flutter); sem DSS | B | |
| 85 | AYRES, J. R. C. M.; FRANÇA JÚNIOR, I.; CALAZANS, G. J.; SALETTI FILHO, H. C. O conceito de vulnerabilidade e as práticas de saúde | 2003 | LIV | VAL | N/A-liv | 1ª | ISBN 85-7541-024-5 · repositorio.usp.br/item/001528349 | não | C | 2.3 | Vulnerabilidade em saúde ≠ risco; práticas de saúde | Não fornece índice/métrica | A | Referência conceitual central (nova) |

---

## 11. Tabela comparativa de trabalhos relacionados (9 estudos)

> Colunas: **Dados** (Reais/Sintéticos) · **DSS?** · **App/mHealth?** · **Desfecho** · **Modelo** · **Métrica** · **Diferença vs. TCC**.

| Ref | Ano | País | N | Dados | DSS? | App? | Desfecho | Modelo | Métrica | Diferença vs. TCC |
|---|---|---|---|---|---|---|---|---|---|---|
| ADEM et al. | 2026 | Etiópia | 3.979 | Reais (DHS) | Sim | Não | ANC incompleta | RF (melhor) + SHAP | Acc 73%, AUC 79% | Dados reais; desfecho "incompleto" ≠ "descontinuidade"; sem app |
| KHADIDOS et al. | 2024 | n/d | n/d | Reais | Não | Não | Risco (multiclasse) | Ensemble GBT+stacking | 0,86 | Clínico; sem DSS; multiclasse; ensemble |
| OSBORNE et al. | 2026 | Nigéria | 13.955 | Reais (DHS) | Sim | Não | ANC (3 classes) | LightGBM+XGBoost hierárquico | Acc 0,77–0,81 | Multiclasse; sem app; XGBoost/LightGBM |
| BAYKEMAGN et al. | 2025 | África Oriental | n/d | Reais (DHS) | Sim | Não | Início tardio ANC | LGBM (melhor) + SMOTE | AUC 81% | Desfecho "início tardio"; LGBM; sem app |
| PATEL et al. | 2026 | EUA | 190.698 | Reais (Medicaid) | Sim (SDoH) | Não | Risco gravidez | ML + simulação SDoH | AUC 93% | Larga escala; EUA; desfecho clínico |
| YANG et al. | 2024 | NZ | 1.080.566 | Reais | Parcial | Não | No-show consultas | XGBoost (melhor) | AUC 0,92 | Consultas gerais (não pré-natal); DSS limitado |
| SANI et al. | 2025 | Nigéria | n/d | Reais (DHS) | Sim | Não | ANC ótima | RF (melhor), XGBoost | AUC 0,90 | Desfecho "ótimo" ≠ "descontinuidade" |
| PRABA et al. | 2026 | n/d | n/d | **Sintéticos** | Não | Não | Risco (multiclasse) | Stacking XGBoost+CatBoost | Acc 97% | Sintético (mais próximo), mas sem DSS/app/RF |
| ADEOLA et al. | 2025 | Global South | n/d | Reais | Não | **Sim (web)** | Risco materno | Classificador web | Acc 84% | Único com app/questionário; web (não Flutter); sem DSS |

**Observação de rigor (para a monografia):** nenhum dos 9 declarou validação clínica prospectiva; a maioria usa dados transversais secundários (DHS). **Entre os 9 trabalhos selecionados neste corpus**, nenhum combina **Flutter + API + dados sintéticos + DSS + PR-AUC/Brier/calibração** — esse é o diferencial a enfatizar na seção 2.5, **sem reivindicar ineditismo universal** (a comparação vale apenas para o conjunto aqui selecionado).

---

## 12. Matriz capítulo × afirmação × fonte

> Mapeamento das **afirmações centrais** que a monografia sustentará e as fontes que as ancoram.

| Cap. | Afirmação / conteúdo | Fonte(s) (nº da matriz) |
|---|---|---|
| 1.1–1.2 | Desigualdades socioeconômicas e barreiras de acesso estão associadas à menor adequação, à não realização, ao início tardio ou à descontinuidade do acompanhamento pré-natal, conforme a definição operacional adotada em cada estudo | 03, 04, 18, 19, 26, 28, 29, 30, 31 |
| 1.1–1.2 | DSS moldam oportunidades de saúde e geram iniquidades evitáveis | 07, 08, 22, 34, 35 |
| 2.1 | Adequação/continuidade do pré-natal e desigualdades de acesso no Brasil | 03, 04, 26, 27, 28, 29 |
| 2.2 | Modelo em camadas dos DSS (Dahlgren & Whitehead) e distinção determinação×determinantes | 02, 07, 08, 32, 33, 35 |
| 2.3 | Vulnerabilidade em saúde **≠** risco (Ayres); complementarmente, vulnerabilidade ambiental/índices | **85** (central); 43, 44, 45 (complementar); 42, 46, 47, 48 (índices) |
| 2.4 | ML supervisionado (RF/RL/XGBoost), mHealth e IA responsável na saúde | 06, 13, 14, 36–41, 55, 56, 57, 66 |
| 2.5 | Trabalhos relacionados: estado comparativo de ML + pré-natal | 49, 50, 51, 77–84 |
| 3.3 | Construção de índice composto (normalização, agregação, ponderação, pesos iguais) | 42, 46, 47, 48 |
| 3.6 | Geração de dados sintéticos (DGM) e desenho de estudos de simulação — fundamentação metodológica (Burton/Morris) e exemplo aplicado (Praba); **seed 42** = decisão técnica do projeto (artefatos internos) | 52, 53 (metodologia); 83 (exemplo aplicado) |
| 3.8 | Modelos comparados (RF, RL, XGBoost) | 54, 55, 56, 57 |
| 3.9 | Treinamento/validação e relato transparente (TRIPOD) | 63, 71 |
| 3.10 | Métricas: desbalanceamento de classes; ROC-AUC; PR-AUC e sua relevância em cenários desbalanceados; Brier Score | 58, 59, 60, 61, 62, 64 |
| 3.12 | Ética, privacidade (LGPD), governança e viés | 66, 67, 68, 69, 70 |
| 4.1–4.7 | Arquitetura Flutter → API → ML; eixos do app; onde o IV-DSS é calculado | 09, 17 (contexto saúde digital); evidência primária do código |
| 5.2–5.3 | Comparação e seleção de modelos; desempenho hold-out | 54, 58, 59 |
| 5.5 | Calibração (Brier, calibration-in-the-large) e estabilidade | 61, 62, 63, 64, 65 |
| 5.7 | Interpretabilidade (permutation importance e seus vieses) | 73, 74, 75, 76 |
| 5.8 | IV-DSS e cobertura por dimensões | 42, 46 (metodologia de índice) |
| 5.10 | Discussão: limitações, viés, aplicabilidade | 64, 70, 71, 72 |
| 6.2–6.3 | Limitações e trabalhos futuros | 70, 72 |

> **Nota (terminologia):** a monografia **não** deve afirmar genericamente "o abandono persiste entre os vulneráveis". Formulação segura: *"Desigualdades socioeconômicas e barreiras de acesso estão associadas à menor adequação, à não realização, ao início tardio ou à descontinuidade do acompanhamento pré-natal, conforme a definição operacional adotada em cada estudo."* Para estudos que medem "abandono"/"dropout", registrar a **definição operacional específica** de cada um e **não transportá-la** para o alvo do TCC2 (que adota "descontinuidade" simulada).

---

## 13. Cobertura temática (verde / amarelo / vermelho)

### 13.1 Cobertura por frente A–M

| Frente | Status | Justificativa |
|---|---|---|
| A — Pré-natal/saúde materna | 🟢 Verde | Fontes canônicas A/B, incl. WHO 2016 e Rede Alyne 2024 |
| B — DSS e saúde materna | 🟢 Verde | Fontes canônicas (Dahlgren & Whitehead, Solar & Irwin, CNDSS, Marmot, WHO 2025) |
| C — Vulnerabilidade/índices compostos | 🟢 Verde | **Ayres (2003)** como referência conceitual central + OECD handbook + literatura de índices/robustez |
| D — mHealth | 🟢 Verde | Revisões sistemáticas Cochrane/PLoS/BMC |
| E — ML em saúde materna | 🟢 Verde | 3 estudos preditivos comparáveis (JAMA, BMJ Open, MLWA) |
| F/G/H — Trabalhos relacionados | 🟢 Verde | 9 estudos comparáveis em tabela |
| I — Dados sintéticos/simulação | 🟢 Verde | **Burton (2006) + Morris (2019)** são referências metodológicas centrais que sustentam DGM/simulação; não se exige saturação; CTGAN/GAN não é o método do projeto |
| J — Classificação/métricas | 🟢 Verde | Cobertura completa (RF/RL/XGB, desbalanceamento, PR-AUC) |
| K — Calibração | 🟢 Verde | Brier + scoring rules + Steyerberg + Van Calster |
| L — IA responsável/ética | 🟢 Verde | WHO ×3 + LGPD + Obermeyer + TRIPOD/PROBAST |
| M — Interpretabilidade | 🟢 Verde | 4 fontes (Fisher, Strobl, Altmann, Hooker) |

### 13.2 Cobertura por subseção da monografia (estrutura real — §5.2 do plano)

| Subseção | Status | Fonte(s) principais | Lacuna / observação |
|---|---|---|---|
| 1.1 Contextualização | 🟢 Verde | 22, 07, 08, 03, 04 | — |
| 1.2 Problema de pesquisa | 🟢 Verde | 03, 04, 26, 28, 31 | — |
| 1.3 Justificativa | 🟢 Verde | 03, 04, 18, 19, 26, 29, 31 | — |
| 1.4 Objetivos | 🟢 Verde | deriva de 1.1–1.3 | Não exige fonte externa |
| 1.5 Estrutura do trabalho | 🟢 Verde | — | Não exige fonte externa |
| 2.1 Pré-natal e saúde materna | 🟢 Verde | 03, 04, 26, 27, 28, 29, 31, 18, 19, 30, 23, 24, 25 | — |
| 2.2 Determinantes Sociais da Saúde | 🟢 Verde | 01, 02, 07, 08, 22, 32, 33, 34, 35 | — |
| 2.3 Vulnerabilidade e índices compostos | 🟢 Verde | 85, 42, 46, 47, 48, 43, 44, 45 | Resolvida com Ayres (2003) |
| 2.4 Aprendizado de máquina supervisionado | 🟢 Verde | 06, 13, 14, 55, 56, 57, 66, 36–41, 09, 17 | — |
| 2.5 Trabalhos relacionados | 🟢 Verde | 49, 50, 51, 77–84 | — |
| 3.1 Tipo de pesquisa | 🟡 Amarelo | 63, 71 (enquadram desenho preditivo) | Sem fonte dedicada a "pesquisa experimental preditiva aplicada" |
| 3.2 DSS utilizados | 🟢 Verde | 01, 02, 07, 08, 22, 32, 33 | Evidência: schema 1.13 |
| 3.3 Construção do IV-DSS | 🟢 Verde | 42, 46, 47, 48 | — |
| 3.4 Modelagem dos dados | 🟢 Verde | 42, 46 | Evidência: planejamento_dataset_sintetico.md |
| 3.5 População, T0 e variável-alvo | 🟡 Amarelo | 03, 04, 26, 28 (base conceitual) | "T0/descontinuidade" é definição operacional própria; sem padronização na literatura |
| 3.6 Geração do dataset sintético | 🟢 Verde | 52, 53, 83 | — |
| 3.7 Seleção de variáveis e controle de leakage | 🟡 Amarelo | 54, 63 | Sem fonte dedicada a leakage em seleção de variáveis |
| 3.8 Modelos de aprendizado de máquina | 🟢 Verde | 54, 55, 56, 57 | — |
| 3.9 Treinamento e validação | 🟢 Verde | 63, 71, 64 | — |
| 3.10 Métricas | 🟢 Verde | 58, 59, 60, 61, 62, 64 | — |
| 3.11 Validação da integração Flutter → API → ML | 🟡 Amarelo | 09, 17 (contexto) | Evidência primária do projeto; literatura só contextual |
| 3.12 Aspectos éticos e limitações | 🟢 Verde | 66, 67, 68, 69, 70, 71, 72 | — |
| 4 Desenvolvimento da Solução | 🟡 Amarelo | 09, 17 (contexto); docs oficiais Flutter/Modular se citadas | Evidência primária do código; ancoragem bibliográfica fraca |
| 5 Resultados e Discussão | 🟢 Verde | 54, 58, 59, 61–65, 73–76, 70, 71, 72 | Evidência primária |
| 6 Conclusão | 🟢 Verde | 70, 72 (limitações/futuros) | — |

**Resumo:** **20 subseções verdes, 5 amarelas (3.1, 3.5, 3.7, 3.11, 4), 0 vermelhas.** As amarelas não são lacunas de literatura crítica, mas subseções cuja ancoragem é predominantemente **evidência primária do próprio projeto** (código, schema, métricas) ou definição operacional própria.

---

## 14. Lacunas remanescentes

1. **5 citações "órfãs" do TCC1** (§4.3): Diderichsen & Hallqvist (1998); Costa et al. (2021); Petrovskiy (2003); Shortliffe & Cimino (2006); OMS (2023). **Não há obrigação de recuperá-las** — o TCC1 é histórico. Formalizar **somente** as que forem efetivamente citadas na nova monografia; as demais são simplesmente **não reaproveitadas**.
2. **DAHLGREN & WHITEHEAD (1991)** sem URL oficial estável (documento clássico pré-digital) — citar pela entrada canônica (IFS, Stockholm), apoiada por Dahlgren & Whitehead (2021, DOI 10.1016/j.puhe.2021.08.009).
3. **Definição operacional de "descontinuidade" (T0)** — a literatura de pré-natal fornece base conceitual (não realização/início tardio/inadequação), mas não uma definição padronizada de "descontinuidade"; a do TCC2 é **operacionalização própria** a explicitar em 3.5.
4. **Validação clínica prospectiva** — nenhum trabalho relacionado a declara; reforçar como limitação e trabalho futuro (já ancorado em 70/72).

---

## 15. Normas IFAM/ABNT (verificação documental)

| Norma | Descrição | Status |
|---|---|---|
| ABNT NBR 14724:2024 | Trabalhos acadêmicos — Apresentação | ✅ versão vigente confirmada |
| ABNT NBR 6023:2025 | Referências — Elaboração | ✅ **edição vigente** (a 6023:2018 é a **anterior**) |
| ABNT NBR 6023:2018 | Referências — Elaboração (edição anterior) | ⚠ citada pelo Manual do TCC do IFAM (2019), **já substituída** |
| ABNT NBR 10520:2023 | Citações em documentos | ✅ |
| ABNT NBR 6024:2012 | Numeração progressiva das seções | ✅ |
| ABNT NBR 6027:2012 | Sumário — Apresentação | ✅ |
| ABNT NBR 6028:2021 | Resumo, resenha e recensão | ✅ |
| IFAM Resolução nº 43-CONSUP/IFAM, 22/08/2017 | Regulamento do TCC do IFAM | ✅ |
| IFAM — Manual do Trabalho de Conclusão de Curso (2019) | Formatação e estrutura | ✅ (cita a NBR 6023:2018) |

> **Nota (conflito NBR 6023):** a NBR 6023 foi atualizada de **2018 → 2025**. O Manual do TCC do IFAM (2019) ainda referencia a **2018**. **Não se apaga o conflito histórico.** Na formatação definitiva, devem ser observadas **prioritariamente as regras formais específicas aplicáveis do curso/campus e do IFAM**; nos aspectos omissos ou desatualizados, deverá ser considerada a **ABNT vigente (2025)**, com eventuais divergências submetidas ao **orientador e à biblioteca**. A conferência do texto integral de cada NBR e o cotejo com o modelo de capa/folha de rosto do campus **Manaus Zona Leste** devem ser feitos na fase de formatação final.

---

## 16. Recomendações

1. **Tratar a matriz como corpus validado/candidato, não como lista final.** A lista de REFERÊNCIAS conterá **somente as obras efetivamente citadas**; **A/B** indicam prioridade de uso na redação, **C/D** são opcionais. Não há obrigação de citar as 85.
2. **Corrigir a referência SILVA 2023 → SANTORIO et al. 2024** em toda menção herdada do TCC1.
3. **Resolver apenas as citações "órfãs" que forem reutilizadas** (§14) — remover ou formalizar caso a caso; não há obrigação de recuperar todas.
4. **Citar Dahlgren & Whitehead (1991)** pela entrada canônica, com apoio do artigo de 2021.
5. **Reusar a Figura 1 (Dahlgren & Whitehead)** do TCC1 com fonte correta (CNDSS, 2008), conforme `TCC2_DOCX_PLAN.md`.
6. **Preservar o caráter experimental/sintético** do estudo (não herdar a narrativa "rede neural + dados reais" do TCC1) — ancorado em 52/53/83 e no diferencial enfatizado em §11.
7. **Usar Ayres et al. (2003) como referência conceitual central de vulnerabilidade em saúde** (§2.3), mantendo Cutter/Adger/Wisner como complementares.
8. **Registrar Fisher et al. (2019) sem DOI** (JMLR não atribui DOI; usar URL oficial e citar o arXiv apenas como versão alternativa).

---

## 17. Próximo passo

1. Submeter esta matriz à revisão do orientador (decisões humanas pendentes: quais referências C/D manter; quais citações "órfãs" reaproveitar; resolução do conflito NBR 6023 junto à biblioteca).
2. Após aprovação, **iniciar a redação** dos capítulos usando `TCC2_DOCX_PLAN.md` (estrutura) + esta matriz (fontes) + `docs/tcc2.md` (conteúdo técnico).
3. A formatação ABNT/IFAM integral (§15) será aplicada na fase de montagem do DOCX.

---

*Fim do documento — FASE 7A ETAPA 2 (correção final). Nenhuma referência foi inventada; metadata conflitante foi explicitamente corrigida (§7); NBR 6023 registrada em suas duas edições (§15).*
