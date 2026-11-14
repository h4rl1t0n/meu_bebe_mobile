# FASE 8B-PLAN — Plano técnico da infraestrutura de persistência da API

> **Natureza:** fase exclusivamente de **auditoria e planejamento**. Nenhuma
> dependência foi instalada, nenhum arquivo de código foi alterado, nenhuma
> migration/model/endpoint foi criado. Este documento registra o estado **real**
> auditado da API e propõe a infraestrutura futura de persistência para a
> **FASE 8B-IMP**.
>
> **Decisão pendente resolvida nesta fase:** o modo de acesso SQLAlchemy
> **síncrono × assíncrono** (deliberadamente em aberto na FASE 8A) é analisado e
> recomendado na seção 9.

---

## 1. Objetivo

Preparar, de forma documental, a introdução de **persistência real** no backend
FastAPI do projeto **Meu Bebê**, seguindo a arquitetura aprovada e congelada na
FASE 8A (`docs/PRENATAL_API_ARCHITECTURE_PLAN.md`):

```
FastAPI → SQLAlchemy 2.x → sessões/transações → Alembic → PostgreSQL
```

Esta fase **não** implementa nada. Ela decide os pontos técnicos em aberto e
descreve, com ordem e critérios de aceite, como será a **FASE 8B-IMP**.

---

## 2. Escopo

### Incluído (planejamento)

- Auditoria da API atual (estrutura, dependências, configuração, testes,
  health/readiness, lifecycle, logging).
- Decisão **sync × async** com justificativa técnica.
- Recomendação de driver PostgreSQL.
- Estratégia de configuração por ambiente.
- Proposta de estrutura SQLAlchemy (conceitual, **sem** criar arquivos).
- Política de lifecycle de sessão e de transações.
- Política de **UUID v4** e de **timestamps**.
- Planejamento de **Alembic** e da estratégia de migrations.
- Estratégia de testes com PostgreSQL e de ambiente local de desenvolvimento.
- Readiness do banco, logging/privacidade e tratamento de erros de banco.
- Plano de implementação da **FASE 8B-IMP** e critérios de aceite.

### Explicitamente excluído desta fase

- Instalar PostgreSQL, SQLAlchemy, Alembic ou qualquer driver.
- Alterar código, dependências, migrations, models, endpoints ou testes.
- Alterar Flutter, IA, DOCX ou qualquer documento existente.
- Projetar detalhadamente as tabelas das entidades de domínio (seção 21).
- Implementar autenticação, ownership ou qualquer rota nova.
- Migrar/sincronizar o SQLite legado do Flutter.

---

## 3. Estado atual auditado

Fatos verificados no repositório (não assumidos):

| Item | Valor auditado |
|---|---|
| Versão do Python em uso | **3.14.5** (`python --version`, `py -3.14 --version`) |
| FastAPI instalado | **0.141.1** (pyproject declara `fastapi>=0.110`) |
| Uvicorn instalado | 0.52.4 (`uvicorn[standard]>=0.29`) |
| Pydantic instalado | 2.13.4 (pydantic-settings 2.15.0) |
| pytest instalado | 9.1.1 |
| httpx instalado | 0.28.1 |
| Infraestrutura SQL (SQLAlchemy/psycopg/asyncpg/alembic) | **Nenhuma** |
| Arquivos Dockerfile / docker-compose | **Nenhum** (em todo o repositório) |
| Arquivos `requirements*.txt` / `alembic.ini` / `.sql` | **Nenhum** |
| Pacote ML (`meu_bebe_ml`) | Importável (editável, v0.1.0, instalado a partir de `../ia`) |
| Suíte de testes | **150 testes coletados** (`pytest --collect-only`) |

Conclusão: a API atual é **stateless**, **síncrona** e **sem qualquer
dependência de banco**. O contrato DSS (`POST /api/v1/risk-estimate`) é o único
endpoint funcional e **não** possui nenhuma persistência.

---

## 4. Estrutura real da API

Localização: `api/` (pacote sob `src/`, layout src).

```
api/
├── pyproject.toml
├── .env.example
├── .gitignore
├── README.md
├── API_CONTRACT_V1.md
├── FASE_4A_REPORT.md … FASE_4D_REPORT.md
├── src/
│   └── meu_bebe_api/
│       ├── __init__.py            (__version__ = "0.1.0")
│       ├── main.py                (fábrica create_app() + lifespan)
│       ├── config.py              (pydantic-settings Settings)
│       ├── api/
│       │   ├── __init__.py
│       │   ├── health.py          (GET /health)
│       │   ├── ready.py           (GET /ready + get_model_runtime)
│       │   ├── risk_estimate.py   (POST /api/v1/risk-estimate)
│       │   └── router.py          (api_v1_router, prefixo /api/v1)
│       ├── contracts/
│       │   ├── __init__.py
│       │   ├── dss.py             (DssPayload, DSS_SCHEMA_VERSION="1.13")
│       │   ├── errors.py          (ErrorResponse / ErrorDetail)
│       │   └── risk_estimate.py   (RiskEstimateResponse etc.)
│       ├── core/
│       │   ├── __init__.py
│       │   └── exception_handlers.py
│       └── ml/
│           ├── __init__.py
│           ├── adapter.py         (DssPayload → DataFrame X_MODEL)
│           ├── artifact.py        (path/manifest/SHA/compat)
│           ├── errors.py          (ModelError e subclasses)
│           └── runtime.py         (ModelRuntime)
└── tests/
    ├── conftest.py
    ├── fixtures/flutter_dss_payload_v1_13.json
    ├── test_adapter.py
    ├── test_artifact.py
    ├── test_dss_contract.py
    ├── test_error_contract.py
    ├── test_flutter_contract.py
    ├── test_health.py
    ├── test_http_contract.py
    ├── test_integration.py
    ├── test_openapi.py
    ├── test_ready.py
    ├── test_risk_estimate.py
    ├── test_risk_estimate_integration.py
    └── test_runtime.py
```

**Entrypoint:** `uvicorn meu_bebe_api.main:app --reload` (no `main.py`, a
instância de módulo `app = create_app()` é criada no final do arquivo).

**Pontos relevantes para a persistência futura:**

- A aplicação é montada por uma **fábrica** `create_app(settings=None,
  runtime=None)`, que já permite injeção de configuração e de runtime — o mesmo
  padrão será usado para injetar a engine/session no futuro.
- O estado compartilhado vive em `app.state` (`settings`, `model_runtime`,
  `runtime_override`). Uma futura `engine`/`session_factory` seguirá o mesmo
  mecanismo (`app.state`).
- As rotas atuais são **todas** `def` (síncronas) — ver seção 9.

---

## 5. Dependências atuais

`api/pyproject.toml` (`[project].dependencies`):

```
fastapi>=0.110
uvicorn[standard]>=0.29
pydantic>=2.7
pydantic-settings>=2.3
```

`[project.optional-dependencies].dev`:

```
pytest>=8.0
httpx>=0.27
```

As dependências de ML (scikit-learn, numpy, pandas, joblib, …) **não** são
duplicadas aqui: vêm do pacote `meu_bebe_ml`, instalado editável a partir de
`../ia` (conforme `README.md`).

**Não há** nenhuma dependência SQL/ORM/driver hoje. A introdução de persistência
acrescentará (na 8B-IMP): `sqlalchemy`, um driver PostgreSQL, `alembic` e — se o
ambiente local escolhido exigir — ferramentas de infra (Docker), conforme seções
10, 17 e 20.

---

## 6. Configuração atual

Arquivo: `src/meu_bebe_api/config.py`.

- Classe `Settings(BaseSettings)` via `pydantic-settings`, com
  `env_file=".env"`, `env_file_encoding="utf-8"`, `extra="ignore"` e
  `case_sensitive=False`.
- Accessor cacheado `get_settings()` (`@lru_cache`).
- Campos atuais (todos com default):

| Campo | Default |
|---|---|
| `app_name` | `meu-bebe-api` |
| `app_env` | `development` |
| `app_host` | `127.0.0.1` |
| `app_port` | `8000` |
| `app_log_level` | `INFO` |
| `app_docs_enabled` | `True` |
| `model_artifact_path` | `../ia/artifacts/models/selected_model_v1.joblib` |
| `model_manifest_path` | `../ia/artifacts/models/selected_model_v1_manifest.json` |
| `model_load_on_startup` | `True` |

`.env.example` reflete esses campos. O `.env` é ignorado pelo git (`.gitignore`).
Não há credenciais nem segredos versionados.

**Implicação:** a configuração de banco futura se encaixa naturalmente como
novos campos em `Settings` (ou uma sub-seção de settings), lidos do `.env` —
mantendo o mesmo mecanismo pydantic-settings já usado.

---

## 7. Suíte de testes atual

- **Framework:** `pytest` (9.1.1), configurado em `pyproject.toml` com
  `pythonpath = ["src"]` e `testpaths = ["tests"]`.
- **Cliente HTTP:** `fastapi.testclient.TestClient` (Starlette).
- **Organização:** 13 arquivos `test_*.py` + `conftest.py` + 1 fixture JSON.
- **Total coletado:** **150 testes** (`pytest --collect-only -q`), incluindo os
  casos expandidos por `@pytest.mark.parametrize`.

Contagem de funções de teste por arquivo:

| Arquivo | Funções `test_*` |
|---|---|
| test_adapter.py | 6 |
| test_artifact.py | 11 |
| test_dss_contract.py | 30 (muitos parametrizados) |
| test_error_contract.py | 5 |
| test_flutter_contract.py | 10 |
| test_health.py | 3 |
| test_http_contract.py | 14 |
| test_integration.py | 5 |
| test_openapi.py | 6 |
| test_ready.py | 8 |
| test_risk_estimate.py | 14 |
| test_risk_estimate_integration.py | 3 |
| test_runtime.py | 7 |

**Fixtures (`conftest.py`):**

- `settings_no_load` — `Settings(model_load_on_startup=False, _env_file=None)`
  (o `_env_file=None` isola os testes do `.env` local).
- `client` — `TestClient(create_app(settings_no_load))`.
- `client_with_validation_route` — cliente com uma rota `/_test/validate`
  somente-de-teste para exercitar o 422.
- `real_runtime` — `ModelRuntime` carregado com o modelo REAL uma única vez por
  sessão (`scope="session"`), usado pelos testes de integração/inferência.

**Como o ML é carregado nos testes:**

- Testes HTTP usam um **fake** (`FakeRuntime`) que replica a interface de
  `ModelRuntime` (sem carregar sklearn) — ver `test_risk_estimate.py`,
  `test_http_contract.py`, `test_flutter_contract.py`.
- Testes de integração usam `real_runtime` (modelo real em
  `ia/artifacts/models/`) — ver `test_integration.py`,
  `test_risk_estimate_integration.py`.

**Como as configurações são injetadas/substituídas:**

- Via `create_app(settings, runtime)` (injeção explícita na fábrica).
- Via `Settings(..., _env_file=None)` para evitar vazamento do `.env`.
- O runtime é substituído por `app.state.runtime_override` no lifespan.

**Observação de ambiente (não bloqueante):** a coleta emite um
`StarletteDeprecationWarning` sobre `httpx`/`testclient` ("install httpx2
instead"). Trata-se de um aviso de depreciação da biblioteca, **não** de uma
falha; não é objeto desta fase corrigi-lo.

---

## 8. Health e readiness atuais

### `GET /health` (liveness) — `api/health.py`

- Sempre `200`, **sem** dependência de modelo, banco ou qualquer recurso externo.
- Corpo: `status`, `service`, `api_version`, `dss_schema_version`.
- **Significado:** o processo da aplicação está vivo e respondendo.

### `GET /ready` (readiness) — `api/ready.py`

- Reflete **apenas** se o **modelo ML** carregou com sucesso.
- `200` com metadados sanitizados do modelo (`name`, `raw_feature_count`,
  `transformed_feature_count`) quando `runtime.is_ready`.
- `503` com envelope `MODEL_NOT_READY` em caso contrário (sem detalhes internos).
- **Não possui** nenhuma dependência externa hoje (não toca banco).

### Como o PostgreSQL participará da readiness (planejado)

- **HEALTH** continuará sendo o sinal de "processo vivo": **não** deve depender
  do banco.
- **READINESS** passará a considerar o banco **apenas** na medida em que houver
  endpoints que dependam dele — ver seção 21 para a recomendação detalhada.
- A indisponibilidade do banco **não** deve, nesta fase, derrubar o `/ready`
  global nem o endpoint DSS congelado (ver seções 2 e 21).

### Terminologia precisa do "fail-closed" do modelo

Distinção que evita leitura equivocada ("a API sobe mesmo sem modelo" **não**
significa que a inferência degrade):

- **PROCESSO DA API** → pode iniciar **sem** o artefato disponível, conforme o
  comportamento atual (a liveness `/health` não depende do modelo).
- **CAPACIDADE DE INFERÊNCIA** → permanece **fail-closed**: se o modelo não
  estiver `READY`, a API **não** produz estimativa falsa/degradada. `GET /ready`
  e `POST /api/v1/risk-estimate` indicam indisponibilidade via `503
  MODEL_NOT_READY`, exatamente como no contrato existente.

Isso **não** altera o comportamento atual; apenas qualifica a terminologia.

---

## 9. Decisão SQLAlchemy sync × async

### Contexto real (auditado)

- Todas as três rotas atuais (`health`, `ready`, `risk_estimate`) são **`def`
  síncronas** — nenhuma usa `async def`.
- A operação funcional crítica (`risk-estimate`) é a inferência de um
  `RandomForestClassifier` (`predict_proba`), que é **CPU-bound e síncrona**:
  não há I/O de rede/disco no caminho do endpoint.
- O volume esperado é o de um **TCC**: baixa concorrência, sem requisito de
  throughput ou de milhares de conexões simultâneas.
- A FASE 8A já registrou: *"Não há evidência técnica concreta no backend atual
  que exija sessões assíncronas"* (`PRENATAL_API_ARCHITECTURE_PLAN.md` §7.2).

### Comparação objetiva

| Critério | OPÇÃO A — sync (`Session`) | OPÇÃO B — async (`AsyncSession`) |
|---|---|---|
| Complexidade da API atual | Alinha-se (rotas já `def`) | Exigiria converter/rotear com `async def` |
| Volume esperado (TCC) | Sobra | Sobra (mas desnecessário) |
| Padrão dos endpoints | `def` + threadpool do FastAPI | `async def` + loop |
| Necessidade real de concorrência de I/O | Baixa/nenhuma | Baixa/nenhuma |
| Session lifecycle | `Session` + `yield` simples | `AsyncSession` + `async with`, `await` em tudo |
| Transações | `commit`/`rollback` síncronos | `await commit`/`await rollback` |
| Testes | `TestClient` síncrono (padrão atual) | Precisa de fixtures/event-loop async |
| Fixtures | Simples, sem loop | Loop async, `pytest-asyncio` |
| Alembic | `env.py` síncrono (padrão) | `env.py` assíncrono |
| Debugging | Mais simples | Mais difícil (coroutines/contexto) |
| Manutenção | Menor superfície | Maior superfície |
| Curva de complexidade | Baixa | Média/alta |
| Risco de async desnecessário | Nulo | Concreto (complexidade sem ganho) |
| Compatibilidade com a arquitetura atual | Total | Exigiria mudança de padrão |
| Evolução futura | Suficiente p/ TCC | Migração possível depois, se necessário |

### DECISÃO RECOMENDADA

**SYNC — SQLAlchemy 2.x síncrono (`Session` + driver PostgreSQL síncrono).**

### JUSTIFICATIVA

1. O backend atual é **inteiramente síncrono** (`def`); adotar `AsyncSession`
   exigiria converter o padrão das rotas sem qualquer benefício funcional.
2. A carga dominante (inferência RandomForest) é **CPU-bound**: mesmo que as
   rotas fossem `async def`, a inferência bloquearia o event loop e precisaria
   ser isolada em `run_in_executor` — anulando a vantagem do async.
3. Não há **I/O concorrente** (múltiplas chamadas de rede/banco simultâneas) que
   justifique async no escopo do TCC.
4. Session lifecycle, transações, testes e Alembic são **substancialmente mais
   simples** na variante síncrona, reduzindo risco de manutenção.
5. A solução síncrona satisfaz integralmente os requisitos do projeto com **a
   menor complexidade possível** — conforme orientação da própria FASE 8B-PLAN
   ("dar preferência à solução de menor complexidade que satisfaça o projeto").

### RISCOS (da escolha sync)

- **Migração futura para async**, se um dia houver requisito real de alta
  concorrência de I/O, exigirá refatorar a camada de sessão. Mitigação: isolar a
  criação de sessão em um único ponto (`session factory` + dependency), de modo
  que uma eventual migração seja localizada.
- **Bloqueio de threadpool** em operações de banco longas não é problema no
  volume do TCC; se surgir, a mitigação padrão é mover apenas as consultas
  pesadas para um executor dedicado.

---

## 10. Driver PostgreSQL recomendado

- **Recomendado:** **`psycopg` (psycopg 3)**, instalado como
  `psycopg[binary]` (wheels com libpq embutida).
- **Motivo:**
  - SQLAlchemy 2.x recomenda **psycopg3** como driver PostgreSQL preferencial
    (dialeto `postgresql+psycopg://`).
  - API síncrona **e** assíncrona num único pacote (a variante síncrona atende
    esta fase; a assíncrona ficaria disponível caso a decisão da seção 9 mude no
    futuro, sem trocar de driver).
  - Melhor ritmo de suporte a versões novas do Python (relevante porque o
    projeto usa **Python 3.14.5**, muito recente).
- **Compatibilidade:**
  - Python: **verificar disponibilidade de wheel para 3.14 no momento da
    instalação** (não congelar versão aqui). Fallback: instalação com `libpq`
    local ou, se wheel indisponível, avaliar `psycopg2-binary` — que tende a
    **defasar** mais cedo em Python novo.
  - SQLAlchemy 2.x: suportado nativamente.
- **Impacto em testes:** o mesmo driver atende o banco de teste (real PostgreSQL).
- **Impacto no deployment:** `psycopg[binary]` simplifica o deploy (não exige
  libpq no host), ao custo de um wheel maior.

> Alternativa registrada (não recomendada como principal): `psycopg2-binary`
> (psycopg2). Apenas fallback se `psycopg` não oferecer wheel para Python 3.14
> no momento da 8B-IMP.

---

## 11. Arquitetura futura da persistência

```
Router (contratos/DTO Pydantic — camada contracts/)
        ↓
Service / Use Case (caso de uso)
        ↓
Repository (acesso a dados, se houver necessidade de reuso)
        ↓
SQLAlchemy 2.x (Session síncrona)
        ↓
psycopg (dialeto postgresql+psycopg)
        ↓
PostgreSQL
```

### Proposta de estrutura de arquivos (conceitual — NÃO criar agora)

Abaixo, a estrutura que a 8B-IMP **poderá** adotar, respeitando o layout `src/`
existente. Nenhum arquivo foi criado.

```
api/
├── alembic.ini
├── alembic/
│   ├── env.py
│   ├── script.py.mako
│   └── versions/
├── src/meu_bebe_api/
│   ├── db/
│   │   ├── __init__.py
│   │   ├── base.py            (DeclarativeBase + naming_convention)
│   │   ├── engine.py          (create_engine a partir de settings)
│   │   ├── session.py         (sessionmaker + get_session dependency)
│   │   └── types.py           (se necessário: tipo UUID padrão)
│   └── (demais módulos atuais inalterados)
```

### Responsabilidades planejadas

- **`db/base.py`** — `DeclarativeBase` com `naming_convention` (nomes estáveis
  de constraints para o Alembic `autogenerate`); futuras entidades ORM herdarão
  dela.
- **`db/engine.py`** — criação do `Engine` (síncrono) a partir de
  `settings.database_url`; configuração de `pool_pre_ping` (recuperação de
  conexão morta) e `echo` controlado por `app_env`.
- **`db/session.py`** — `sessionmaker` (bound ao engine) + dependency
  `get_session()` que **yield** uma `Session` e a fecha em `finally`.
- **`db/types.py`** — apenas se for útil centralizar o tipo de UUID padrão
  (`sqlalchemy.Uuid(as_uuid=True)`); evitar abstração desnecessária.

**Regra:** nenhuma abstração adicional (ex.: camada de "unit of work" genérica,
repositórios base com CRUD genérico) será introduzida nesta fase. A estrutura é
proporcional ao TCC.

---

## 12. Configuração por ambiente

### Formato recomendado

**`DATABASE_URL` único** (URL SQLAlchemy), em vez de campos separados.

- Justificativa: é o formato consumido **diretamente** por `create_engine` e pelo
  `env.py` do Alembic; evita lógica de composição de host/porta/credenciais e
  reduz superfície de erro.
- Campos separados (`DB_HOST`, `DB_PORT`, …) são possíveis, mas adicionam código
  de montagem sem benefício para este projeto.

### Planejado

- **Desenvolvimento** (`app_env=development`): `DATABASE_URL` apontando para o
  PostgreSQL local (`postgresql+psycopg://…@localhost:5432/meu_bebe`).
- **Testes** (`app_env=test` ou variável de teste): banco dedicado
  `meu_bebe_test` (ou schema efêmero), **sem** tocar o banco de dev.
- **Produção** (`app_env=production`): URL fornecida pelo ambiente, **nunca**
  versionada.

### Regras de segurança

- **Nunca** versionar credenciais; `.env` permanece no `.gitignore`.
- `.env.example` ganhará um `DATABASE_URL` **placeholder** (sem senha real),
  documentando o formato.
- **Defaults seguros:** em um ambiente no qual a infraestrutura persistente está
  habilitada/configurada, o campo `database_url` é **obrigatório**.

### Distinção: configuração × disponibilidade (fail-fast sem acoplar o DSS)

Para eliminar ambiguidade, os três conceitos abaixo são **independentes**:

- **Validação de configuração (fail-fast):** `DATABASE_URL` **ausente** ou
  **sintaticamente inválida** em um ambiente onde a persistência está habilitada
  é **erro de configuração** e pode falhar de forma previsível na inicialização.
  Isso é validação de *string* (formato da URL), **não** teste de conexão.
- **Criação do engine (sem conexão obrigatória):** criar o `Engine` SQLAlchemy é
  uma operação **preguiçosa** — valida a configuração, mas **não** abre uma
  conexão obrigatória só para inicializar a aplicação. O processo FastAPI pode
  subir mesmo com o PostgreSQL **temporariamente indisponível**.
- **Disponibilidade em runtime (conexão efetiva):** a conexão real só ocorre
  quando (a) o subsistema persistente for **efetivamente utilizado**, ou (b) uma
  verificação **específica** de disponibilidade do banco for executada (ver seção
  21).

**Consequência para o DSS (congelado):** a indisponibilidade temporária do
PostgreSQL **não** impede o processo de subir e **não** torna
`POST /api/v1/risk-estimate` indisponível. Erro de banco afeta **apenas** os
recursos que dependem do banco, com comportamento controlado (seção 23), sem
quebrar o fluxo DSS. O endpoint DSS permanece **stateless, sem autenticação, sem
IDs, sem persistência e independente do PostgreSQL**.

---

## 13. Lifecycle da sessão

- A `Session` será criada **por requisição** (não global).
- A dependency `get_session()` (em `db/session.py`) fará:

  ```
  session = session_factory()
  try:
      yield session
  finally:
      session.close()
  ```

- O `Engine`/`session_factory` serão criados **uma vez** no startup (lifespan) e
  expostos via `app.state` (mesmo padrão atual de `app.state.settings`), para
  reuso entre requisições e testes.
- **Criação do engine ≠ conexão:** o `Engine` é criado de forma **preguiçosa**
  (`create_engine` não abre conexão imediatamente). A conexão efetiva ocorre
  apenas no primeiro uso da `Session` ou em uma verificação explícita de
  disponibilidade — o processo FastAPI sobe mesmo com o PostgreSQL
  temporariamente indisponível.
- **Fechamento:** sempre em `finally` (garante devolução da conexão ao pool mesmo
  em exceção).
- **Rollback em exceção:** a camada de serviço/uso é responsável por abortar a
  transação (ver seção 14); o `close()` da dependency devolve a conexão ao pool.

---

## 14. Política de transações

### Recomendação

**Padrão B — o caso de uso/service controla a transação**, com o **limite da
requisição** controlando o ciclo de vida da sessão (abertura/fechamento pela
dependency da seção 13).

- **Quem chama `commit`:** o **service/use case**, ao concluir com sucesso a
  operação de escrita.
- **Quem executa `rollback`:** o service, em caso de exceção de negócio/domínio;
  adicionalmente, a dependency ou um helper pode garantir `rollback` em exceções
  não tratadas antes do `close()`.
- **Quem fecha a sessão:** a dependency `get_session()` (sempre em `finally`).
- **Comportamento em exceções:** exceções de domínio → `rollback` + resposta
  sanitizada (seção 23); exceções inesperadas → `rollback` + 500 sanitizado.
- **Atomicidade:** uma operação de escrita = **uma** unidade de trabalho; sem
  commits espalhados em múltiplos pontos.

### Regra arquitetural

- **Nenhum `commit`** deve ocorrer fora do service/use case (repositories **não**
  committam; apenas executam queries e manipulam o ORM na sessão fornecida).
- **Nenhum `autocommit`** implícito; a transação é explícita.

> Escolheu-se **não** o padrão "repository executa commit" (C-A) por espalhar o
> controle de atomicidade, e **não** o "request boundary controla commit" puro
> (C-C) por acoplar a rota a detalhes de transação. O padrão B mantém a
> atomicidade no lugar certo (caso de uso) e o ciclo de vida no limite da
> requisição.

---

## 15. UUID v4

### Decisão congelada (FASE 8A)

- UUID v4 como chave primária das novas entidades persistentes.
- Gerado pelo **servidor**; Flutter representa como `String`.
- **Nunca** usar CPF como PK (nem como mecanismo de login).
- PostgreSQL deve usar o tipo **`UUID` nativo**.

### Recomendação de geração

- **Gerar no Python** (`uuid.uuid4()` como default da coluna ORM), **não** no
  PostgreSQL (`gen_random_uuid()`).
- Justificativa:
  - Independe de extensão do banco e de privilégios.
  - Comportamento idêntico em testes (inclusive se algum teste unitário usar
    banco substituto), mantendo os mesmos defaults.
  - Mantém a fonte de verdade da geração no servidor de aplicação, alinhado à
    decisão "servidor gera".
- **Tipo:** `sqlalchemy.Uuid(as_uuid=True)` → coluna `UUID` nativa no PostgreSQL.
- **Não** introduzir UUID v7 (mantém UUID v4).

---

## 16. Timestamps

### Política comum (`created_at` / `updated_at`)

- **Tipo:** `TIMESTAMPTZ` (`DateTime(timezone=True)`) no PostgreSQL.
- **Timezone:** armazenar **UTC**. Nunca armazenar timezone local no banco.
- **Geração de `created_at`:** no servidor, default `now()` em UTC
  (`datetime.now(timezone.utc)` ou `func.now()`), conforme a entidade.
- **Atualização de `updated_at`:** atualizada a cada escrita (`onupdate`).
- **Serialização futura:** **ISO 8601** (com offset `Z`/`+00:00`), na borda do
  contrato (DTOs Pydantic) — nunca transportar `dd/MM/yyyy`.

> `created_at`/`updated_at` são campos **de infraestrutura**, não de negócio;
> serão padronizados em todas as entidades futuras, sem duplicar a definição em
> cada modelo (via uma mixin/base declarativa na 8C/8D).

---

## 17. Alembic

### Configuração planejada (NÃO executar agora)

- **Localização:** `api/alembic/` + `api/alembic.ini` (na raiz de `api/`, fora de
  `src/`, como é convenção do Alembic).
- **`env.py`:** lerá `DATABASE_URL` a partir de `meu_bebe_api.config` (Settings)
  e importará a `metadata` de `meu_bebe_api.db.base`.
- **Acesso à metadata:** via **`Base.metadata`** único (uma única base
  declarativa), garantindo que o Alembic enxergue todas as tabelas.
- **URL:** usar a URL da aplicação (a mesma `DATABASE_URL`), evitando duplicação.
- **Migrations versionadas:** cada mudança de schema = um revision novo, com
  `down_revision` encadeado.
- **`autogenerate`:** usar como **ponto de partida**, mas **sempre revisar
  manualmente** antes de aplicar (o autogenerate não captura tudo, e qualquer
  diff deve ser deliberado).
- **Política:** nunca aplicar `alembic upgrade` sem revisar o revision gerado.

### Comandos NÃO executados nesta fase

`alembic init`, `alembic revision`, `alembic upgrade` — todos **adiados** para a
8B-IMP.

---

## 18. Estratégia de migrations

### Primeira migration — decisão explícita

**Decisão: alternativa B — não criar nenhum revision até a primeira entidade
real.**

Justificativa:

- Não há entidade de domínio na 8B (a fase é infraestrutural); criar um revision
  "vazio" apenas para demonstrar o Alembic seria uma marcação **artificial e sem
  valor de negócio**.
- Um *baseline vazio* (alternativa A) não agrega nada além do que a validação de
  configuração abaixo já entrega, e ainda criaria uma revisão sem conteúdo real a
  manter.

**Como a FASE 8B valida a configuração do Alembic sem uma migration de domínio:**

1. **Validação de configuração (sem conexão):** `alembic heads` e
   `alembic history` comprovam que `env.py` carrega, que `Settings` resolvem
   `DATABASE_URL` e que `Base.metadata` importa corretamente.
2. **Validação de conectividade (prova de URL/permissões):** uma conexão explícita
   de curta duração — o probe de disponibilidade (`SELECT 1`, seção 21) ou um
   `engine.connect()` no teste de infraestrutura — comprova que a URL é alcançável
   e que o papel do banco tem permissão.
3. A tabela de bookkeeping do Alembic (`alembic_version`) só passa a existir
   quando o **primeiro revision real** (criação de tabelas) for aplicado, na fase
   da primeira entidade (8C/8D).

> A 8B-IMP **não** cria revision nem tabela de domínio; a primeira migration com
> conteúdo nasce junto com o primeiro modelo ORM real.

---

## 19. Estratégia de testes com PostgreSQL

### Premissa

**Não** assumir SQLite em memória como substituto fiel de PostgreSQL. As
diferenças são materiais para este projeto: `UUID` nativo, `JSONB`, tipos
(`TIMESTAMPTZ`), constraints, SQL e comportamento específico do PostgreSQL.

### Recomendação

- **Banco de teste real (PostgreSQL)**, dedicado (`meu_bebe_test`), separado do
  banco de desenvolvimento.
- **Isolamento por teste:** usar o padrão SQLAlchemy de *join de transação
  externa* — uma `Connection` com uma transação aninhada aberta no início do
  teste e **rollback** ao final, para isolar o estado sem recriar o schema a cada
  teste.
- **Setup:** criar o schema uma vez por sessão de teste (via Alembic
  `upgrade head` no banco de teste), depois aplicar o padrão de rollback por
  teste.
- **Fixture de sessão de teste:** uma `session_factory` apontando para o banco de
  teste, exposta como fixture `pytest`.

### Sobre Docker

- O projeto **não possui** Docker/Compose hoje.
- **Não adicionar Docker** a menos que o ambiente local de desenvolvimento não
  permita um PostgreSQL nativo de forma simples (ver seção 20).
- Se introduzido, seria exclusivamente para **reprodutibilidade** do ambiente de
  dev/teste — nunca como dependência dos testes em si.

---

## 20. PostgreSQL local / desenvolvimento

### Opções avaliadas

1. **Instalação local** (PostgreSQL nativo no Windows) — **recomendada** por
   simplicidade e por não introduzir ferramenta nova no projeto.
2. **Docker Compose** (`docker-compose.yml` com `postgres`) — aceitável como
   alternativa quando a instalação local for indesejada/indisponível.
3. **Serviço externo** (nuvem) — **desnecessário** para o escopo do TCC.

### Recomendação

- Preferir **instalação local** com dois bancos: `meu_bebe` (dev) e
  `meu_bebe_test` (testes).
- Documentar **no README da API** os passos mínimos: criar os dois bancos e
  configurar `DATABASE_URL` no `.env`/`.env.example`.
- Se houver indisponibilidade local, introduzir **um único**
  `docker-compose.yml` com `postgres` (e `POSTGRES_DB`/`POSTGRES_USER`/`POSTGRES_PASSWORD`
  de exemplo), justificando explicitamente sua introdução — o projeto hoje não
  tem Docker.

> Princípios: **reprodutibilidade**, **simplicidade**, **poucos passos**,
> **documentação clara**.

---

## 21. Readiness do banco

### Semântica preservada

- **`GET /health`** → liveness da aplicação (processo vivo), **sem** banco.
- **`GET /ready`** → readiness **atual** do runtime/modelo ML (contrato existente
  congelado). **Não é alterado nesta fase.**
- A indisponibilidade do PostgreSQL **não** derruba automaticamente a readiness do
  modelo nem o endpoint DSS congelado: o DSS é stateless e independente do banco.

### Onde a disponibilidade do subsistema persistente será verificada

A disponibilidade do banco **não** é verificada no `/ready` global (que continua
sendo do modelo) nem no `/health`. Ela será verificada por um **probe específico
do subsistema persistente**, a definir na 8B-IMP, com as seguintes regras:

- **Não implementar** nesta fase e **não congelar** nome de endpoint agora
  (pode ser um probe interno de infraestrutura, um campo em um endpoint de
  diagnóstico futuro ou uma checagem no próprio ciclo das rotas dependentes de
  banco — decisão da 8B-IMP).
- O `SELECT 1` será o **probe barato** usado **apenas** quando essa verificação
  específica for executada (com timeout curto), **não** a cada `/health` e **não**
  como custo fixo de todo request.
- **Sem `SELECT 1` sem consumidor arquitetural:** a checagem só existe porque há
  um consumidor definido — (a) as rotas persistentes futuras, que devem falhar
  rápido com `503 DATABASE_UNAVAILABLE` quando o banco está fora, e (b) o teste
  de infraestrutura da 8B-IMP (prova de conectividade).

### Consequência

- **Endpoints que dependem do banco** → `503` sanitizado se o banco estiver
  indisponível, **apenas** nesses endpoints.
- **`/ready`** → continua refletindo o modelo; o banco permanece **soft/lazy**.
- Promover o banco a dependência **hard** do `/ready` global é decisão a
  **reavaliar** quando os endpoints persistidos se tornarem o tráfego principal
  (8C/8D+), não agora.

---

## 22. Logging e privacidade

### Auditoria do logging atual

- A API usa `logging.getLogger(__name__)` pontual (em `main`, `ready`,
  `risk_estimate`, `runtime`). **Não há** middleware/interceptor de log de
  requisição/resposta na API.
- O `LogInterceptor` citado na FASE 8A é uma preocupação do **Flutter** (cliente),
  não desta API. (Registrado como dívida futura na tabela de riscos da FASE 8A.)

### Regras para a camada de persistência (futura)

**Nunca** logar:

- senha ou `password_hash`;
- JWT / refresh token;
- payload completo com dados pessoais (DSS, CPF, nome, CNS);
- string de conexão contendo senha (`DATABASE_URL` com credenciais);
- respostas sensíveis (conteúdo de `GESTANTE`, `USER`, etc.).

**Boas práticas planejadas:**

- Em logs de erro de banco, registrar apenas **código/tipo de erro sanitizado**,
  nunca a query SQL completa nem valores de parâmetros sensíveis.
- `SQLAlchemy` com `echo=False` em produção (e `echo` só para debug local, nunca
  com dados reais).
- Qualquer futuro middleware/interceptor de log deve ser **whitelist** (logar
  apenas o mínimo), nunca "logar tudo e filtrar depois".

### Riscos registrados (não corrigidos nesta fase)

- Se a 8C/8D introduzir autenticação, será obrigatório auditar qualquer log de
  requisição para **não** vazar token/senha/payload. Ação futura, não agora.

---

## 23. Tratamento de erros de banco

### Planejado (não implementado agora)

| Situação | Resposta planejada |
|---|---|
| PostgreSQL indisponível | `503` `DATABASE_UNAVAILABLE` (sanitizado) |
| Erro de conexão | `503` `DATABASE_UNAVAILABLE` |
| `IntegrityError` / violação de constraint | `409` (ou `422`/`400` conforme o caso), mensagem sanitizada |
| Conflito (ex.: uniqueness) | `409` sanitizado |
| Transação abortada | `rollback` + `500` sanitizado (ou 409 se for conflito de negócio) |

### Regras

- **Nunca** expor stack trace, SQL interno, nomes de tabela/coluna internos ou
  mensagens brutas do driver ao Flutter.
- O envelope de erro atual (`ErrorResponse`) é **reutilizado**; não criar ainda
  envelopes específicos por domínio sem necessidade.
- Os códigos de erro de banco seguirão o mesmo padrão de "código estável interno
  + mensagem sanitizada HTTP" já usado para `MODEL_NOT_READY`/`INFERENCE_ERROR`.
- Erros de banco afetam **apenas** os recursos que dependem do banco; o fluxo DSS
  congelado (`POST /api/v1/risk-estimate`) **nunca** é afetado por falha de banco.

---

## 24. Riscos

| Risco | Impacto | Mitigação |
|---|---|---|
| Quebra do fluxo DSS congelado | Alto | Não tocar `risk-estimate`; persistência nunca acoplada ao endpoint DSS |
| Acoplar `DATABASE_URL`/engine ao endpoint DSS | Médio | Engine/session só em rotas novas; DSS permanece stateless |
| Python 3.14 sem wheel de driver PostgreSQL | Médio | Verificar wheel de `psycopg` na 8B-IMP; fallback `psycopg2-binary`/libpq |
| SQLite em memória divergir do PostgreSQL em testes | Médio | Testes de persistência usam PostgreSQL real dedicado |
| Migration aplicada sem revisão | Médio | Revisão manual obrigatória de todo revision antes de `upgrade` |
| Commit espalhado / transação inconsistente | Médio | Política da seção 14 (commit só no service/use case) |
| Vazamento de credenciais/dados em log | Médio | Regras da seção 22; `.env` fora do git; `echo=False` |
| Complexidade desnecessária (async) | Médio | Decisão SYNC (seção 9); estrutura proporcional ao TCC |
| Banco derrubar `/ready` global e afetar DSS | Médio | Readiness lazy (seção 21); DB só afeta endpoints que o usam |
| Docker introduzido sem necessidade | Baixo | Só se instalação local for inviável (seção 20) |

---

## 25. Fora de escopo (desta fase e das fases infraestruturais)

- **Não** alterar o contrato DSS (`schema_version=1.13`, `probability`,
  metadados, `notice`, sem threshold/classe/faixa/recomendação).
- **Não** adicionar autenticação/user_id/gestante_id/gestacao_id ao endpoint DSS.
- **Não** implementar offline-first, sincronização ou cache.
- **Não** migrar automaticamente os dados SQLite legados.
- **Não** remover o SQLite do Flutter (transição feature por feature, em fases
  posteriores).
- **Não** implementar soft delete por padrão (decisão FASE 8A).
- **Não** usar "multi-tenancy" para o mecanismo de ownership.
- **Não** modificar IA (`ia/`), Flutter (`lib/`, `test/`, `pubspec.yaml`) nem os
  documentos (`docs/*`).

---

## 26. Plano de implementação da FASE 8B-IMP

Ordem proposta (adaptada à realidade encontrada — nenhum passo executado agora):

1. **8B-IMP.1 — Dependências/configuração**
   - Adicionar `sqlalchemy`, `psycopg[binary]`, `alembic` ao `pyproject.toml`
     (verificando wheels p/ Python 3.14).
   - Adicionar `DATABASE_URL` ao `Settings` e ao `.env.example` (placeholder).

2. **8B-IMP.2 — Engine / Session / Base**
   - `db/base.py` (`DeclarativeBase` + `naming_convention`).
   - `db/engine.py` (`create_engine` síncrono, `pool_pre_ping`).
   - `db/session.py` (`sessionmaker` + `get_session` dependency).
   - Registrar engine/session_factory no `app.state` (lifespan).

3. **8B-IMP.3 — Alembic**
   - `alembic init`, `env.py` lendo `Settings` e `Base.metadata`.
   - Validar com `alembic upgrade head` (zero revisões de conteúdo).

4. **8B-IMP.4 — PostgreSQL de desenvolvimento/teste**
   - Bancos `meu_bebe` e `meu_bebe_test`; documentar passos no README.
   - (Opcional) `docker-compose.yml` se instalação local inviável.

5. **8B-IMP.5 — Readiness do banco**
   - Probe `SELECT 1` com timeout curto; rotas dependentes de banco → `503`
     sanitizado; `/ready` global **inalterado** nesta fase.

6. **8B-IMP.6 — Testes de infraestrutura**
   - Fixture de sessão apontando p/ `meu_bebe_test`; isolamento por rollback;
     testes de engine/sessão/transação/migration.

7. **8B-IMP.7 — Auditoria final**
   - `git diff --check` limpo, suíte verde, contrato DSS inalterado, critérios de
     aceite (seção 27) verificados.

> Cada passo termina com `git diff --check` limpo e testes verdes. **Nenhum
> commit** nesta fase; commit apenas mediante autorização explícita.

---

## 27. Critérios de aceite da FASE 8B-IMP

A 8B-IMP só será considerada concluída quando **todos** os itens abaixo forem
verificáveis:

- [ ] Configuração de banco **sintaticamente inválida/ausente** (em ambiente com
      persistência habilitada) falha de forma **previsível** (erro de
      configuração, sem crash silencioso).
- [ ] O processo FastAPI **inicia** mesmo com o PostgreSQL temporariamente
      indisponível (criação do engine **não** exige conexão no startup).
- [ ] O PostgreSQL pode ser alcançado por uma verificação **específica** de
      disponibilidade (probe `SELECT 1` com timeout), sem afetar `/health`/`/ready`.
- [ ] A indisponibilidade do banco afeta **apenas** os recursos que dependem dele,
      e **não** torna `POST /api/v1/risk-estimate` indisponível.
- [ ] A `Session` abre e fecha corretamente (dependency `get_session`).
- [ ] `rollback` funciona em caso de exceção.
- [ ] A infraestrutura Alembic funciona (`alembic upgrade head` valida a cadeia).
- [ ] Os testes de infraestrutura passam (engine/sessão/transação/migration).
- [ ] `GET /health` continua retornando `200` (liveness intacta).
- [ ] `GET /ready` mantém comportamento definido (readiness do modelo, contrato
      atual).
- [ ] `POST /api/v1/risk-estimate` continua funcionando e **inalterado**.
- [ ] Nenhum campo/contrato do DSS foi alterado (`schema_version` segue `1.13`).
- [ ] Nenhuma autenticação foi adicionada.
- [ ] Nenhuma entidade de domínio foi implementada prematuramente.
- [ ] `git diff --check` limpo.

---

> **Fim do plano da FASE 8B-PLAN.** Este documento é a única entrega desta fase.
> A implementação (FASE 8B-IMP) e o registro acadêmico do estado implementado
> (FASE 8B-DOC) serão realizados em fases posteriores, com autorização explícita.
