# 1 INTRODUÇÃO

## 1.1 Contextualização

O acompanhamento pré-natal constitui um componente central da atenção à gestação
e da promoção da saúde materno-infantil, sendo objeto de diretrizes
internacionais que recomendam uma atenção organizada, periódica e centrada na
gestante (OMS, 2016). No Brasil, essa atenção integra a política de saúde
materno-infantil do Sistema Único de Saúde (SUS) e foi reafirmada, em sua
configuração mais recente, pela Rede Alyne, instituída pela Portaria GM/MS
nº 5.350, de 2024, que prevê a captação oportuna da gestante e a realização de
um conjunto mínimo de consultas intercaladas entre diferentes profissionais
(Brasil, 2024). A mortalidade materna permanece, todavia, um problema relevante
em escala global (OMS, 2019, 2024), o que reforça a importância de estratégias
que favoreçam a continuidade do acompanhamento.

Apesar da expansão da cobertura, a adequação e a continuidade do pré-natal
permanecem desiguais no Brasil. Desigualdades socioeconômicas e barreiras de
acesso estão associadas à menor adequação, à não realização, ao início tardio ou
à descontinuidade do acompanhamento pré-natal, conforme a definição operacional
adotada em cada estudo (Rosa; Silveira; Costa, 2014; Viellas et al., 2014;
Degli Esposti et al., 2020; Santorio et al., 2024). Estudos conduzidos em
diferentes contextos brasileiros evidenciam a associação entre condições sociais
e a não realização do pré-natal (Rosa; Silveira; Costa, 2014), bem como o papel
de determinantes sociais na realização do acompanhamento, em análises de base
populacional (Santorio et al., 2024). As desigualdades observadas assumem,
ademais, recortes sociais e geográficos, refletindo-se no desempenho da
assistência (Degli Esposti et al., 2020).

Os Determinantes Sociais da Saúde (DSS) constituem o conjunto de condições
sociais, econômicas e ambientais em que as pessoas nascem, vivem e trabalham e
que moldam as oportunidades de saúde, gerando iniquidades evitáveis quando
distribuídos de forma desigual (Buss; Pellegrini Filho, 2007; CNDSS, 2008;
Solar; Irwin, 2010; OMS, 2025). No escopo deste trabalho, esses determinantes
são operacionalizados em seis dimensões — educação, trabalho e renda,
saneamento, acesso aos serviços de saúde, habitação e alimentação — que orientam
a coleta estruturada de informações e a caracterização de perfis de
vulnerabilidade social.

Em paralelo, o avanço das tecnologias digitais em saúde tem ampliado as
possibilidades de coleta, registro e acompanhamento dessas informações.
Iniciativas de saúde móvel (mHealth) têm sido investigadas como apoio ao
pré-natal e ao pós-parto (Feroz; Perveen; Aftab, 2017), e aplicativos voltados à
gestação vêm sendo estudados como recurso de apoio ao autocuidado e à gestão da
gravidez (Iyawa; Dansharif; Khan, 2021). No contexto brasileiro, a Estratégia de
Saúde Digital para o Brasil 2020–2028 estabelece diretrizes para o uso de
tecnologias digitais no sistema de saúde (Brasil, 2020). É nessa confluência
entre os DSS, a saúde digital e o aprendizado de máquina que se insere a
proposta deste trabalho.

O emprego de inteligência artificial na saúde pública tem sido objeto de
crescente discussão (Alves; Terazima; Lima, 2025). Nesse contexto, este trabalho
investiga experimentalmente o emprego de aprendizado de máquina supervisionado
sobre variáveis estruturadas dos DSS para estimar a propensão à descontinuidade
do acompanhamento pré-natal, materializando-se no aplicativo "Meu Bebê", que
integra, em uma mesma aplicação, a coleta estruturada dos DSS e um módulo de
acompanhamento do pré-natal.

O estudo é conduzido sobre um dataset sintético, com finalidade de avaliação
técnica e controlada da metodologia: os dados não representam prevalências reais
e os resultados não autorizam inferência clínica ou populacional sobre gestantes
reais. A estimativa produzida não constitui diagnóstico, classificação clínica
ou certeza de descontinuidade, e nenhuma associação estatística é apresentada
como relação causal. De modo complementar e separado do aplicativo, o estudo
calcula, em seu componente analítico, o Índice de Vulnerabilidade dos
Determinantes Sociais da Saúde (IV-DSS), de caráter descritivo e experimental,
destinado a caracterizar a vulnerabilidade social dos perfis representados no
dataset sintético — distinto da probabilidade estimada pelo modelo.

## 1.2 Problema de pesquisa

Apesar da existência de diretrizes nacionais e da expansão do acesso, persistem
desigualdades na adequação e na continuidade do acompanhamento pré-natal,
associadas a condições sociais e a barreiras de acesso (Rosa; Silveira; Costa,
2014; Viellas et al., 2014; Degli Esposti et al., 2020; Santorio et al., 2024).
A disponibilidade de informações estruturadas sobre os DSS abre espaço para
investigar se técnicas de aprendizado de máquina podem, a partir dessas
variáveis, produzir estimativas experimentais de propensão à descontinuidade.

É necessário, contudo, distinguir o fenômeno real — a descontinuidade do
acompanhamento pré-natal, cuja operacionalização longitudinal com dados reais
ainda exige fundamentação específica — da variável-alvo experimental adotada
neste estudo, definida sobre dados sintéticos. O problema investigado, portanto,
pode ser enunciado nos seguintes termos: **em que medida uma abordagem
experimental de aprendizado de máquina baseada nos DSS, inicialmente avaliada com
dados sintéticos, é capaz de produzir estimativas de propensão à descontinuidade
do acompanhamento pré-natal?**

Não se pretende, com este trabalho, estabelecer causalidade nem produzir
diagnóstico ou classificação clínica. Trata-se de avaliar, de forma controlada e
reproduzível, a viabilidade técnica de um pipeline computacional que relacione os
DSS a um desfecho experimental.

## 1.3 Justificativa

A relevância social deste trabalho reside na centralidade do pré-natal para a
saúde materna e na persistência de desigualdades de acesso e de continuidade,
documentadas para o contexto brasileiro (Rosa; Silveira; Costa, 2014; Viellas et
al., 2014; Degli Esposti et al., 2020). A mortalidade materna permanece um
problema relevante em escala global (OMS, 2019, 2024), e o acompanhamento
pré-natal adequado figura entre as estratégias de prevenção recomendadas (OMS,
2016). Compreender como condições relacionadas aos DSS se associam às
desigualdades observadas na adequação e na continuidade desse acompanhamento
pode subsidiar o planejamento da atenção, ainda que este trabalho não se proponha
a intervir diretamente sobre esse fenômeno nem a estabelecer relações de
causalidade.

Do ponto de vista científico e tecnológico, justifica-se investigar se uma
abordagem de aprendizado de máquina, aplicada a dados estruturados dos DSS, é
capaz de produzir estimativas de propensão passíveis de avaliação segundo o
protocolo experimental adotado. A opção por um dataset sintético permite a
avaliação controlada e reproduzível do pipeline, ao mesmo tempo em que afasta
qualquer leitura de validade clínica ou de representatividade populacional: os
dados não representam prevalências reais nem autorizam inferência sobre
gestantes reais.

A solução tecnológica proposta reúne, no aplicativo, a coleta estruturada dos
DSS, o módulo de acompanhamento do pré-natal e o consumo da estimativa
experimental produzida pelo pipeline de aprendizado de máquina. Paralelamente,
no componente analítico do estudo, é calculado o Índice de Vulnerabilidade dos
Determinantes Sociais da Saúde (IV-DSS), de caráter descritivo e experimental,
distinto da probabilidade produzida pelo modelo e sem configurar classificação
clínica. Prevê-se, para o módulo de acompanhamento, a integração a uma API para
persistência e gerenciamento dos dados. A integração funcional já existente, em
um mesmo aplicativo, entre questionário, estimativa experimental e
acompanhamento do pré-natal constitui uma contribuição de engenharia do
trabalho, independentemente do desempenho preditivo alcançado pelo modelo.

Acrescenta-se a relevância acadêmica: o trabalho consolida um pipeline
experimental reproduzível — contrato de dados, geração controlada de dados
sintéticos, protocolo de treinamento e validação, métricas adequadas a classes
desbalanceadas e integração de software — que poderá ser reutilizado em etapas
futuras com dados reais, sob os devidos requisitos éticos e de consentimento.

## 1.4 Objetivos

### 1.4.1 Objetivo geral

Desenvolver um aplicativo móvel para coleta estruturada dos Determinantes Sociais
da Saúde e acompanhamento do pré-natal, construir um Índice de Vulnerabilidade
dos DSS (IV-DSS) para caracterização dos perfis representados no dataset
sintético, e desenvolver um modelo de aprendizado de máquina — treinado e
avaliado sobre um dataset sintético — capaz de estimar a propensão à
descontinuidade do acompanhamento pré-natal.

### 1.4.2 Objetivos específicos

1. Modelar os DSS em um contrato de dados canônico, versionado e reproduzível.
2. Construir um Índice de Vulnerabilidade dos DSS (IV-DSS), baseado nas
   dimensões investigadas, para caracterizar o nível de vulnerabilidade social
   dos perfis representados no dataset sintético.
3. Desenvolver o aplicativo Flutter com o questionário dos Determinantes Sociais
   da Saúde e o módulo de acompanhamento do pré-natal, integrando este último a
   uma API para persistência e gerenciamento dos dados.
4. Definir a variável-alvo experimental utilizada no estudo sintético,
   distinguindo-a da futura operacionalização longitudinal com dados reais.
5. Gerar um dataset sintético reproduzível (seed fixa), com dependências
   probabilísticas controladas e explicitamente definidas entre os DSS e o
   desfecho sintético.
6. Aplicar e avaliar técnicas de aprendizado de máquina para estimar a propensão
   à descontinuidade do acompanhamento pré-natal.
7. Avaliar os modelos por métricas adequadas a classes desbalanceadas.
8. Integrar o questionário dos Determinantes Sociais da Saúde ao serviço de API
   e ao modelo de aprendizado de máquina, estabelecendo o fluxo Flutter → API →
   ML para obtenção da estimativa experimental de propensão à descontinuidade do
   acompanhamento pré-natal.

## 1.5 Estrutura do trabalho

Além desta introdução, o trabalho organiza-se em cinco capítulos. O Capítulo 2
apresenta a fundamentação teórica, abordando o pré-natal e a saúde materna, os
Determinantes Sociais da Saúde, a vulnerabilidade e os índices compostos, o
aprendizado de máquina supervisionado e os trabalhos relacionados. O Capítulo 3
descreve a metodologia, abrangendo o tipo de pesquisa, as dimensões dos DSS
adotadas, a construção do IV-DSS, a modelagem dos dados, a população e a
variável-alvo, a geração do dataset sintético, a seleção de variáveis, os
modelos, o treinamento e a validação, as métricas, o procedimento de validação da
integração entre aplicativo, API e modelo, e os aspectos éticos e limitações. O
Capítulo 4 detalha o desenvolvimento da solução, com a arquitetura e os eixos
funcionais do aplicativo e a integração com a API e o modelo. O Capítulo 5
apresenta e discute os resultados experimentais e a validação da implementação de
software. O Capítulo 6 conclui o trabalho, retomando os objetivos, sintetizando
contribuições e limitações e indicando trabalhos futuros.

---

# CONTROLE INTERNO DE CITAÇÕES — NÃO ENTRA NA MONOGRAFIA

| Citação usada | ID na matriz | Seção | Afirmação sustentada | Verificada? |
|---|---|---|---|---|
| OMS (2016) — *WHO recommendations on antenatal care for a positive pregnancy experience* | 29 | 1.1; 1.3 | Pré-natal como componente central e diretriz internacional de prevenção | Sim |
| Brasil (2024) — Portaria GM/MS nº 5.350/2024 (Rede Alyne) | 31 | 1.1 | Política nacional de atenção materno-infantil; captação oportuna e mínimo de consultas (referência normativa/contextual) | Sim |
| OMS (2019) — *Trends in maternal mortality 2000 to 2017* | 19 | 1.1; 1.3 | Tendência/panorama da mortalidade materna global | Sim |
| OMS (2024) — *Maternal mortality (fact sheet)* | 18 | 1.1; 1.3 | Mortalidade materna global | Sim |
| Rosa; Silveira; Costa (2014) | 03 | 1.1; 1.2; 1.3 | Fatores associados à não realização do pré-natal | Sim |
| Viellas et al. (2014) | 26 | 1.1; 1.2; 1.3 | Assistência/adequação pré-natal no Brasil | Sim |
| Degli Esposti et al. (2020) | 28 | 1.1; 1.2; 1.3 | Desigualdades sociais e geográficas no desempenho do pré-natal | Sim |
| Santorio et al. (2024) | 04 | 1.1; 1.2 | Determinantes sociais na realização do pré-natal (PNS) | Sim |
| Buss; Pellegrini Filho (2007) | 01 | 1.1 | DSS como conceito e agenda | Sim |
| CNDSS (2008) | 07 | 1.1 | Causas sociais das iniquidades em saúde | Sim |
| Solar; Irwin (2010) | 08 | 1.1 | Framework conceitual dos DSS | Sim |
| OMS (2025) — *World report on social determinants of health equity* | 22 | 1.1 | Equidade em saúde e DSS | Sim |
| Alves; Terazima; Lima (2025) | 06 | 1.1 | IA na saúde pública/SUS (perspectiva geral) | Sim |
| Feroz; Perveen; Aftab (2017) | 38 | 1.1 | mHealth como apoio ao pré-natal e pós-parto | Sim |
| Iyawa; Dansharif; Khan (2021) | 41 | 1.1 | Aplicativos móveis para autocuidado/gestão na gravidez | Sim |
| Brasil (2020) — Estratégia de Saúde Digital 2020–2028 | 09 | 1.1 | Diretrizes de saúde digital no Brasil (contexto) | Sim |

> **Nota de auditoria:** 16 referências distintas citadas (todas com metadata VALIDADA na
> matriz, exceto Santorio et al. (2024), registrada como CONFLITO DE METADATA já
> corrigido — ID 04). As instituições "OMS" e "WHO" referem-se à mesma entidade
> (Organização Mundial da Saúde); os títulos originais constam na coluna "Citação
> usada" para desambiguação. As chamadas autor-data de pessoas físicas seguem a
> NBR 10520:2023 (sobrenomes com iniciais maiúsculas); siglas institucionais
> (OMS, CNDSS) permanecem em caixa alta. A redação preserva, em cada estudo
> citado, a definição operacional própria do desfecho (não realização,
> inadequação, início tardio ou descontinuidade), sem tratá-las como sinônimos.
