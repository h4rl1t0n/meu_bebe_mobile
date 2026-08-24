# API_CONTRACT_V1 — Contrato HTTP congelado (Flutter ↔ API)

**Versão do contrato:** v1 · **Data:** 2026-08-23 · **Status:** congelado
(aguardando revisão da FASE 4D)

Este documento é a referência **única e normativa** do contrato HTTP que o app
Flutter deverá consumir na próxima fase (via `Dio`). Ele foi produzido na
FASE 4D a partir da auditoria somente-leitura do Flutter (`lib/`) contra a API
(`api/`). Nenhuma implementação de cliente faz parte deste contrato.

> **Escopo do contrato:** somente os três endpoints documentados abaixo.
> Não há autenticação, CORS, persistência, rate limiting nem base URL neste
> contrato. Não há endpoint de classificação (`/predict`, `/classify`, etc.).

---

## 1. Versões (dois conceitos independentes)

| Conceito | Valor | Onde vive |
|---|---|---|
| Versão do **serviço** (API) | `0.1.0` | `meu_bebe_api.__version__` (exposta em `/health`) |
| Versão do **contrato de dados** (DSS) | `1.13` | `DSS_SCHEMA_VERSION` e `DssPayload.schema_version` |

A versão do contrato de dados **não é** a versão do serviço. O Flutter já usa
`DssSchema.schemaVersion = '1.13'` — o mesmo literal, mantido idêntico.

---

## 2. Endpoints

| Método | Path | Papel |
|---|---|---|
| `GET` | `/health` | Liveness (não depende do modelo). Sempre `200`. |
| `GET` | `/ready` | Readiness (depende do modelo carregado). `200`/`503`. |
| `POST` | `/api/v1/risk-estimate` | Estimativa probabilística experimental. |

**Não existem aliases.** `POST /api/v1/risk-estimate` é o único caminho
funcional. `/api/v1/health`, `/api/v1/ready` e qualquer `/predict`,
`/inference`, `/estimate`, `/classify` retornam `404`.

Documentação interativa (`/docs`, `/redoc`, `/openapi.json`) existe apenas
quando `APP_DOCS_ENABLED=true` (padrão). Desabilitar a documentação **não**
desabilita os endpoints funcionais.

---

## 3. `POST /api/v1/risk-estimate`

### 3.1 Método e Content-Type

- **Método:** `POST` (qualquer outro método → `405`).
- **Request:** `Content-Type: application/json`.
- **Response:** sempre `Content-Type: application/json`.

### 3.2 Corpo da requisição (request)

O corpo é o payload `DssPayload` **diretamente** — sem *wrapper* como
`{"questionnaire": {...}}`. É exatamente o JSON aninhado e versionado produzido
por `FormularioData.toMap()` no Flutter.

```json
{
  "schema_version": "1.13",
  "educacao":    { ... },   // 6 campos
  "trabalho":    { ... },   // 10 campos
  "saneamento":  { ... },   // 7 campos
  "saude":       { ... },   // 9 campos
  "habitacao":   { ... },   // 9 campos
  "alimentacao": { ... }    // 7 campos
}
```

**Total: 48 variáveis** em 6 dimensões + `schema_version`. A fixture canônica
está em `api/tests/fixtures/flutter_dss_payload_v1_13.json` (fonte de verdade
dos nomes/códigos aceitos).

### 3.3 Regras de contrato do payload

- `extra = "forbid"` em todos os níveis: campo desconhecido → `422`.
- **Booleanos** são estritos (`true`/`false`/`null`; nunca `1`/`0`/`"true"`).
- **Categóricos** usam código canônico snake_case (nunca o rótulo exibido).
- **Múltipla escolha** é `list[Enum]`; `[]` = não respondido. `null` **não** é
  aceito, exceto em `trabalho.beneficios_trabalho` (null estrutural).
- **Exclusividade:** o código exclusivo (`sem_dificuldades`,
  `nenhum_dos_listados`, `sem_melhorias`, `sem_cuidados`, `sem_beneficios`)
  não pode vir combinado com outro código na mesma lista.
- **Null estrutural:** `trabalho.empregado=true` exige `tipo_emprego` e
  `beneficios_trabalho` não-vazio; `empregado=false` exige `motivo_desemprego`.
  `saneamento.frequencia_coleta_lixo != regular` exige
  `destino_lixo_sem_coleta`.
- **Invariante de Habitação:** `numero_dormitorios <= numero_comodos`;
  `numero_pessoas/comodos/dormitorios` são inteiros estritos `>= 1`.

### 3.4 Referência completa dos 48 campos

| Dimensão | Campo | Tipo (JSON) |
|---|---|---|
| **educacao** | `estuda_atualmente` | `bool \| null` |
| | `escolaridade` | `enum \| null` (Escolaridade) |
| | `situacao_estudos_gestacao` | `enum \| null` (SituacaoEstudosGestacao) |
| | `dificuldades_educacao` | `array<enum>` (DificuldadeEducacao) |
| | `entende_orientacoes_saude` | `bool \| null` |
| | `fez_curso_qualificacao_profissional` | `bool \| null` |
| **trabalho** | `empregado` | `bool \| null` |
| | `tipo_emprego` | `enum \| null` (TipoEmprego) |
| | `faixa_renda` | `enum \| null` (FaixaRenda) |
| | `trabalho_permite_pre_natal` | `bool \| null` |
| | `ambiente_trabalho_seguro` | `bool \| null` |
| | `tem_pausas_descanso` | `bool \| null` |
| | `beneficios_trabalho` | `array<enum> \| null` (BeneficioTrabalho) |
| | `motivo_desemprego` | `enum \| null` (MotivoDesemprego) |
| | `recebe_beneficio_social` | `bool \| null` |
| | `impacto_gestacao_trabalho` | `enum \| null` (ImpactoGestacaoTrabalho) |
| **saneamento** | `fonte_agua` | `enum \| null` (FonteAgua) |
| | `interrupcoes_agua` | `bool \| null` |
| | `esgotamento_sanitario` | `enum \| null` (EsgotamentoSanitario) |
| | `frequencia_coleta_lixo` | `enum \| null` (FrequenciaColetaLixo) |
| | `destino_lixo_sem_coleta` | `enum \| null` (DestinoLixoSemColeta) |
| | `problema_saude_agua` | `bool \| null` |
| | `cuidados_vetores` | `array<enum>` (CuidadoVetor) |
| **saude** | `distancia_ubs` | `enum \| null` (DistanciaUBS) |
| | `faltou_consulta` | `bool \| null` |
| | `acesso_ubs` | `enum \| null` (AcessoUBS) |
| | `cadastrada_ubs` | `bool \| null` |
| | `servicos_pre_natal` | `array<enum>` (ServicoPreNatal) |
| | `exames_pre_natal_completos` | `bool \| null` |
| | `vacinas_em_dia` | `bool \| null` |
| | `avaliacao_pre_natal` | `enum \| null` (AvaliacaoPreNatal) |
| | `dificuldades_saude` | `array<enum>` (DificuldadeSaude) |
| **habitacao** | `tipo_moradia` | `enum \| null` (TipoMoradia) |
| | `material_moradia` | `enum \| null` (MaterialMoradia) |
| | `numero_pessoas` | `int` (`>= 1`) |
| | `numero_comodos` | `int` (`>= 1`) |
| | `numero_dormitorios` | `int` (`>= 1`, `<= numero_comodos`) |
| | `itens_residencia` | `array<enum>` (ItemResidencia) |
| | `seguranca_residencia` | `enum \| null` (SegurancaResidencia) |
| | `melhorias_desejadas` | `array<enum>` (MelhoriaMoradia) |
| | `facil_acesso_saude` | `bool \| null` |
| **alimentacao** | `refeicoes_por_dia` | `enum \| null` (RefeicoesPorDia) |
| | `deixou_de_comer_falta_dinheiro` | `bool \| null` |
| | `alimentos_consumidos` | `array<enum>` (AlimentoConsumido) |
| | `fonte_alimentos` | `array<enum>` (FonteAlimentos) |
| | `mudanca_alimentacao_gestacao` | `bool \| null` |
| | `usa_suplementos` | `bool \| null` |
| | `avaliacao_alimentacao` | `enum \| null` (AvaliacaoAlimentacao) |

> Os códigos canônicos de cada enum estão em
> `api/src/meu_bebe_api/contracts/dss.py` (espelho fiel dos catálogos Flutter
> em `lib/app/modules/formulario/catalog/*_options.dart`).

---

## 4. Respostas

### 4.1 `200` — sucesso

```json
{
  "result": { "target": "descontinuou_pre_natal", "probability": 0.222 },
  "model": {
    "name": "random_forest",
    "schema_version": "1.13",
    "raw_feature_count": 34,
    "transformed_feature_count": 96
  },
  "notice": "Estimativa estatística experimental baseada em dados sintéticos; não constitui diagnóstico médico nem certeza de descontinuidade do pré-natal."
}
```

- `result.probability` é um `float` **finito** em `[0,1]`, **sem
  arredondamento**, sem percentual. O Flutter poderá formatar futuramente.
- `result.target` é apenas o **nome da variável resposta** do experimento — não
  é uma afirmação de que o desfecho ocorreu.
- `model` é **sanitizado**: sem caminho, SHA, timestamp, versões de
  bibliotecas, `classes_`, hiperparâmetros ou features.
- **Sem threshold**, sem classe, sem faixa de risco, sem recomendação.

### 4.2 `422` — validação (formato **plano**)

```json
{
  "code": "VALIDATION_ERROR",
  "message": "Requisição inválida",
  "details": [
    { "loc": ["body", "educacao", "escolaridade"], "msg": "...", "type": "..." }
  ]
}
```

- O `details` carrega apenas `loc`/`msg`/`type` — **nunca** o valor rejeitado
  (`input`) nem o corpo bruto (privacidade).

### 4.3 `503` — modelo não carregado (formato **envelope**)

```json
{
  "error": {
    "code": "MODEL_NOT_READY",
    "message": "Modelo de inferência indisponível.",
    "details": []
  }
}
```

### 4.4 `500` — falha inesperada de inferência (formato **envelope**)

```json
{
  "error": {
    "code": "INFERENCE_ERROR",
    "message": "Não foi possível calcular a estimativa.",
    "details": []
  }
}
```

> **Diferença deliberada (congelada):** o `422` usa o formato **plano**
> `{code, message, details}` (herdado da FASE 4A), enquanto `500`/`503` usam o
> **envelope** `{"error": {...}}` (herdado da FASE 4B). Esta diferença **não
> deve ser uniformizada** nesta fase; o cliente deve tratá-las de forma
> distinta.

---

## 5. `/health` e `/ready`

### `GET /health` — sempre `200`

```json
{
  "status": "ok",
  "service": "meu-bebe-api",
  "api_version": "0.1.0",
  "dss_schema_version": "1.13"
}
```

Não declara estado do modelo.

### `GET /ready` — `200` ou `503`

`200` (modelo carregado):

```json
{
  "status": "ready",
  "service": "meu-bebe-api",
  "model": { "name": "random_forest", "raw_feature_count": 34, "transformed_feature_count": 96 }
}
```

`503` (modelo ausente/incompatível):

```json
{ "error": { "code": "MODEL_NOT_READY", "message": "Modelo de inferência indisponível.", "details": [] } }
```

---

## 6. Matriz HTTP consolidada

| Método/Path | Situação | Status | Content-Type | Corpo |
|---|---|---|---|---|
| `GET /health` | sempre | `200` | `application/json` | `{status, service, api_version, dss_schema_version}` |
| `GET /ready` | modelo OK | `200` | `application/json` | `{status, service, model}` |
| `GET /ready` | modelo ausente | `503` | `application/json` | `{error:{...}}` (MODEL_NOT_READY) |
| `POST /api/v1/risk-estimate` | payload válido | `200` | `application/json` | `{result, model, notice}` |
| `POST /api/v1/risk-estimate` | payload inválido | `422` | `application/json` | plano `{code, message, details}` |
| `POST /api/v1/risk-estimate` | modelo não pronto | `503` | `application/json` | `{error:{...}}` (MODEL_NOT_READY) |
| `POST /api/v1/risk-estimate` | falha de inferência | `500` | `application/json` | `{error:{...}}` (INFERENCE_ERROR) |
| `POST /api/v1/risk-estimate` | corpo ausente / JSON malformado | `422` | `application/json` | plano (VALIDATION_ERROR) |
| qualquer outro método no path | — | `405` | `application/json` | `{code: HTTP_ERROR, ...}` |
| path inexistente | — | `404` | `application/json` | `{code: NOT_FOUND, message, details:[]}` |

---

## 7. Semântica e limitações (obrigatórias)

- **Dados sintéticos:** o modelo foi desenvolvido/avaliado sobre dados
  sintéticos; a saída é uma estimativa **experimental**.
- **Não é diagnóstico médico** nem previsão clínica validada.
- **Sem threshold operacional** e **sem classificação**: apenas a
  probabilidade (`float` em `[0,1]`).
- **Sem persistência:** a API é *stateless*; nenhum questionário é armazenado,
  logado ou ecoado na resposta.
- **Privacidade:** nenhuma resposta ecoa o questionário; erros não vazam o
  valor rejeitado nem stack trace.

---

## 8. Guia futuro de integração (Flutter / Dio)

Diretrizes para a próxima fase (não implementadas aqui):

- **Base URL:** não é definida por este contrato (configurar no app).
- **Sem autenticação e sem CORS** no contrato atual.
- Serializar o `FormularioData` com **`toMap()`** (aninhado) — **nunca**
  `toFlatMap()` (visão interna `dimensao.campo`, sem `schema_version`).
- Tratar **4 famílias de resposta** no cliente: `200` (ler
  `result.probability`), `422` (plano), `500`/`503` (envelope `{"error":…}`).
- Não interpretar `probability` como classe/classe de risco; exibir como
  número em `[0,1]`.
