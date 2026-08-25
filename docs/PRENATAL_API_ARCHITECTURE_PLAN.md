# FASE 8A — Arquitetura da API do acompanhamento pré-natal

> **Natureza desta fase:** planejamento e modelagem. **NÃO** foram implementados:
> ORM, schemas Pydantic novos de produção, migrations, endpoints novos, JWT,
> banco PostgreSQL, repositories REST do Flutter, clientes HTTP novos, sync,
> cache nem alterações de UI. Este documento é o artefato técnico principal da
> FASE 8A e fundamenta-se em três auditorias de leitura do código real
> (backend `api/`, e módulos Flutter `lib/app/`).
>
> **Regra de proteção:** o contrato DSS congelado (`POST /api/v1/risk-estimate`,
> schema `1.13`, 48 variáveis, `X_model=34`, `X_sens=36`, DGM, dataset sintético,
> modelo Random Forest selecionado, métricas e IV-DSS) **não é alterado** nesta
> fase. Nenhum artefato de IA, classe de risco, threshold operacional ou
> classificação clínica é criado.

---

## 1. Objetivo

Definir a **arquitetura-alvo e o plano de transição** para que a fonte de verdade
do módulo de acompanhamento pré-natal deixe de ser o SQLite local do aplicativo
Flutter e passe a ser um **backend persistente** (PostgreSQL + API FastAPI),
preservando o fluxo DSS → API → ML já implementado e congelado.

Entregáveis desta fase (todos documentais, sem código):

1. Auditoria do estado atual do backend FastAPI.
2. Auditoria do código de autenticação legado.
3. Auditoria do modelo local Flutter (banco, modelos, repositórios, serviços).
4. Mapeamento do modelo local atual → domínio futuro.
5. Modelo de domínio futuro (entidades, cardinalidades, ownership).
6. Desenho inicial dos recursos REST (sem implementar).
7. Ordem de implementação futura.
8. Riscos e decisões pendentes.

---

## 2. Estado atual

### 2.1 Flutter

O `MainModule` expõe uma página com **quatro abas** (`NavigationBar` +
`TabBarView`): **Home**, **Gestação**, **Parto** e **Perfil**. O `MainController`
guarda o índice da aba ativa e o nome da gestante (lido de
`gestationRepository.getPregnant()?.name`).

| Aba | Funcionalidades | Persistência local |
|-----|-----------------|--------------------|
| **Home** | Consultas; exames; vacinas (catálogo + toggle); medicamentos; informações básicas (100% estático) | `appointment`, `exam`, `vaccine`, `medication` |
| **Gestação** | Identificação da gestante; dados da gestação atual (DUM/1ª USG → IG e DPP derivadas em exibição); local/profissional do pré-natal; consultas; exames; histórico obstétrico | `pregnant`, `current_pregnancy`, `previous_pregnancy`, `appointment`, `exam` |
| **Parto** | Plano de parto: identificação/histórico/gestação atual (contexto) + expectativas, momento do parto, alívio da dor, nascimento, observações, resumo | `expectation`, `birth_moment`, `pain_relief`, `birth`, `observations` (contexto reutiliza `pregnant`/`previous_pregnancy`/`current_pregnancy`) |
| **Perfil** | Dados pessoais (edita `pregnant` + `user`); notificações (estático); configurações (estado local, sem persistência); sobre (estático); sair (navegação apenas) | `pregnant`, `user` |

> Nota de auditoria: **IG** (idade gestacional) e **DPP** (data provável do
> parto) **não são persistidas** — são calculadas em tempo de exibição a partir
> da DUM (`last_menstrual_period` + 280 dias).

### 2.2 SQLite

- Pacote **`sqflite`**, SQL bruto via API de query-builder (`db.insert`,
  `db.update`, `db.query`, `db.delete`) — **sem** Drift/codegen.
- Singleton `DB.instance` (`lib/app/database/database.dart`).
- Arquivo **`meu_bebe.db`**, **versão `1`**.
- `PRAGMA foreign_keys = ON` é executado, mas **nenhuma** `FOREIGN KEY` é
  declarada — nenhuma tabela se referencia.
- `_upgradeDB` é um stub vazio → **sem migrações**; qualquer evolução de schema
  exige recriação do banco.
- **13 tabelas**, **sem** índices explícitos, **sem** `UNIQUE`/`CHECK`.

| Tabela | PK | Observação |
|--------|----|-----------|
| `pregnant` | `id INTEGER PRIMARY KEY` | gestante — registro único (responsabilidade mista) |
| `user` | `id INTEGER PRIMARY KEY` | usuário — registro único; **sem** senha |
| `current_pregnancy` | `id INTEGER PRIMARY KEY` | gestação atual — registro único |
| `previous_pregnancy` | `id INTEGER PRIMARY KEY` | histórico obstétrico — registro único |
| `expectation` | `id INTEGER PRIMARY KEY` | 7 colunas enum `DEFAULT 1` — registro único |
| `birth` | `id INTEGER PRIMARY KEY` | nascimento — registro único |
| `birth_moment` | `id INTEGER PRIMARY KEY` | momento do parto — registro único |
| `pain_relief` | `id INTEGER PRIMARY KEY` | alívio da dor — registro único |
| `observations` | `id INTEGER PRIMARY KEY` | observações — registro único |
| `appointment` | `id INTEGER PRIMARY KEY AUTOINCREMENT` | consultas — lista |
| `exam` | `id INTEGER PRIMARY KEY AUTOINCREMENT` | exames — lista |
| `medication` | `id INTEGER PRIMARY KEY AUTOINCREMENT` | medicamentos — lista |
| `vaccine` | `id INTEGER PRIMARY KEY` | vacinas — lista (pré-cadastrada) |

> Somente `appointment`, `exam` e `medication` usam `AUTOINCREMENT`. As demais
> usam `INTEGER PRIMARY KEY` (alias do rowid). Não há `FOREIGN KEY` em nenhuma
> tabela.

### 2.3 API FastAPI

- **Stack:** FastAPI `>=0.110`, Uvicorn `>=0.29`, Pydantic `>=2.7`
  (`pydantic-settings` `>=2.3`); dev: pytest + httpx. **Sem** SQLAlchemy,
  asyncpg, psycopg, alembic, passlib/bcrypt, python-jose/pyjwt — **nenhuma**
  biblioteca de ORM/migrations/auth.
- **Assemblagem** (`api/src/meu_bebe_api/main.py`): factory
  `create_app(settings, runtime)`; lifespan registra o `ModelRuntime`; routers
  `health_router` (`GET /health`), `ready_router` (`GET /ready`) e
  `api_v1_router` (`prefix="/api/v1"` → `risk_estimate_router`).
- **Config** (`config.py`): `pydantic-settings` (`Settings`, `env_file=".env"`,
  `extra="ignore"`); campos operacionais (`app_name`, `app_env`, `app_host`,
  `app_port`, `app_log_level`, `app_docs_enabled`, `model_artifact_path`,
  `model_manifest_path`, `model_load_on_startup`). **Sem** DB URL, **sem**
  segredo, **sem** token.
- **Endpoints:** `GET /health` (status + `dss_schema_version`), `GET /ready`
  (disponibilidade do modelo), `POST /api/v1/risk-estimate` (estimativa). Sem
  CORS, sem middleware, sem persistência.
- **Contratos:** Pydantic v2 com `extra="forbid"`, `StrictBool`/`StrictInt`,
  `Literal["1.13"]`, enums `str`/`Enum` com código snake_case. Erros em envelope
  `{code, message, details}` (422) ou `{"error": {...}}` (500/503).
- **ML runtime** (`ml/runtime.py`): carrega o artefato congelado
  (`ia/artifacts/models/selected_model_v1.joblib`), valida manifest + SHA-256 +
  compatibilidade de bibliotecas, e expõe apenas `predict_probability` → `float`
  em `[0,1]`. **Sem** threshold, **sem** `predict()`, **sem** classificação.

### 2.4 Autenticação existente/legada

- A tela de login **existe visualmente**, mas **não há autenticação real**.
- **"Entrar"**: valida o formulário e **navega direto** para `routeTab`
  (`Modular.to.pushReplacementNamed(routeTab)`); a chamada real
  `controller.login(...)` está **comentada**.
- **"Criar nova conta"**: navega para `routeForm` (o **questionário DSS**), não
  cria conta.
- **"Sair"**: apenas `Modular.to.navigate(routeLogin)` — **não** limpa token,
  **não** limpa dados locais, **não** encerra sessão.
- **Código legado/parcial** (não conectado à UI):
  - `UserRepositoryImpl` → `POST /auth` (`{email, password}` → espera
    `{"access_token": ...}`) via `RestClient` (`DioForNative`), **sem** o getter
    `.auth` (o `AuthInterceptor` não injetaria o header).
  - `UserLoginServiceImpl.execute` → grava `access_token` em `SharedPreferences`
    (`LocalStorageConstants.accessToken = 'ACCESS_TOKEN_KEY'`).
  - `LoginController.login` → `loginService.execute` → navega em sucesso.
  - `AuthInterceptor` → adiciona `Authorization: Bearer <token>` **somente** se
    `options.extra['DIO_AUTH_KEY'] == true`.
- **Endereçamento frágil:** `RestClient.baseUrl` usa `Env.backendBaseUrl` =
  `String.fromEnvironment('BACKEND_BASE_URL')`, **sem fallback** e **sem leitura
  do `env.json`** (o arquivo existe mas é dormente). Não existe endpoint `/auth`
  na API atual — se o login fosse religado, falharia.
- **Débito de privacidade:** o `RestClient` de login usa `LogInterceptor`
  (`requestBody: true, responseBody: true`) → logaria credenciais em texto plano,
  ao contrário do cliente DSS (`PrivacyLogInterceptor`, que nunca loga corpo).

> **Não reutilizar automaticamente.** Esse código não compõe um sistema de
> autenticação completo e não deve ser tratado como correto; será **auditado** e
> reaproveitado apenas no que fizer sentido (seção 6).

### 2.5 Fluxo DSS já congelado

`POST /api/v1/risk-estimate` (único endpoint funcional versionado):

- Recebe o payload `DssPayload` schema `1.13` (48 variáveis em 6 dimensões).
- **Stateless**, **sem** autenticação, **sem** `user_id`/`gestante_id`/
  `gestacao_id`, **sem** persistência da avaliação.
- Retorna apenas `result.target` + `result.probability` (float `[0,1]`) +
  `model` (metadados) + `notice` (aviso metodológico).
- **Não** retorna classe de risco, **não** retorna threshold.
- Implementado e validado de ponta a ponta (Fases 4D/5A–5D); **não deve ser
  alterado nesta fase**.

Cliente Flutter correspondente: `RiskEstimateRestClient` (`API_BASE_URL`,
`PrivacyLogInterceptor`) + `RiskEstimateRepositoryImpl`, com mapeamento de
falhas por `RiskEstimateDioExceptionMapper` (422/503/500/timeout/conexão/etc.).

---

## 3. Problemas arquiteturais atuais

1. **Persistência local como fonte única.** Todo o acompanhamento pré-natal vive
   apenas no SQLite do dispositivo; não há backend persistente para esse domínio.
2. **Falta de ownership.** Nenhuma tabela referencia `user_id`, `gestante_id` ou
   `gestacao_id`; não há como responder "de quem é este registro".
3. **Falta de relações formais.** `PRAGMA foreign_keys = ON` sem nenhuma
   `FOREIGN KEY`; integridade referencial inexistente.
4. **Modelo implicitamente monousuário.** Tabelas de registro único lidas com
   `query(..., limit: 1)` + `maps.first`; a associação entre registros existe
   apenas pela premissa "1 dispositivo = 1 gestante = 1 gestação".
5. **Autenticação inexistente/incompleta.** Login decorativo; token gravado mas
   nunca lido; sem sessão, sem cadastro, sem refresh, sem logout real.
6. **Entidades locais que misturam conceitos.** `PregnantData` mistura pessoa
   (nome, nascimento, CPF, nome social, CNS) com logística do pré-natal (local,
   profissional, contato); `current_pregnancy` e `previous_pregnancy` são duas
   tabelas soltas que, juntas, fragmentam o conceito de "gestação"/"histórico".
7. **Inconsistências de IDs.**
   - 🔴 **CRÍTICO — perda silenciosa da primeira gravação:** `CurrentGestationPage`
     e `HistoryPage` montam `id: 1` (em vez de `id: 0` no primeiro insert); como
     `saveGestation`/`saveHistory` só inserem quando `id == 0`, a primeira
     gravação faz `UPDATE` em linha inexistente (0 linhas afetadas, sem checagem)
     e **perde os dados**.
   - **Sentinel `id == 0` frágil:** todos os models emitem `'id': id` no `toMap()`
     (inclusive `0`); como o retorno do `db.insert` é usado em `copyWith(id: id)`,
     o sentinel não é efetivamente limpo; somado ao `INSERT OR REPLACE`, as
     tabelas de registro único funcionam "por acidente".
   - **Vacinas:** seed com ids fixos `0..6`, mas apenas `id == 0` insere; as
     demais (`id 1..6`) caem no branch de `UPDATE` contra tabela vazia → **apenas
     `HB_1` materializa** (as outras 6 nunca persistem).
   - **`expectations_page.dart`** usa fallback `id: _controller.expectations?.id ?? 1`
     (padrão `1` em vez de `0`), inconsistente com as telas irmãs.
8. **Campos de UI que não são persistidos.** Em "Meus Dados", os dropdowns
   `maritalStatus`, `education` e `income` alimentam controllers mas **não** são
   gravados em nenhuma tabela — são descartados silenciosamente ao salvar.
9. **Stubs/funções decorativas.** `HomeController` é um stub (`test`/`showTest`);
   `ChildbirthController` é vazio; "Compartilhar" do plano de parto não é
   implementado; "Acompanhante" no resumo é hardcoded `'Não definido'` (o valor
   real `expectation.companion` é coletado mas não consumido).
10. **Formato legado de dados.** Enums persistidos por **ordinal** (`.index`),
    booleanos como **inteiro 0/1**, datas como **String `dd/mm/yyyy`** (sem
    `DateTime`), e `created_at` emitido como `null` no insert (o `DEFAULT
    CURRENT_TIMESTAMP` não é aplicado quando a coluna é anulável e o map envia
    null explícito).
11. **Sem exclusão em registros únicos.** Os repositórios de registro único não
    têm `delete`; não há `findById` em nenhum repositório.
12. **Camada de serviço inconsistente.** Serviço existe **apenas** para login;
    os controllers do pré-natal chamam os repositórios diretamente.
13. **Nomenclatura de arquivo inconsistente.** `_impl.dart` (maioria) vs
    `_sqlite.dart` (appointments/exams), embora as classes sejam `*RepositoryImpl`.
14. **Rotas com typos** (`routeIndetificacao`, `routeGravidezAtual`) e rota
    definida mas não usada (`routeUpdateChildbirth`).

> Nenhum desses problemas será **corrigido** nesta fase (somente documentados);
> eles fundamentam o modelo-alvo e a estratégia de transição.

---

## 4. Modelo de domínio futuro

Domínio-alvo (mesmo consolidado na FASE 6A, seção R). **Nenhuma entidade foi
inventada** — cada bloco corresponde a uma tabela local real, reorganizada com as
chaves estrangeiras ausentes. `UUID` = chave primária das novas entidades (ver
seção 7).

```
USER 1─1 GESTANTE
GESTANTE 1─N GESTACAO
GESTANTE 1─1 HISTORICO_OBSTETRICO
GESTACAO 1─N CONSULTA
GESTACAO 1─N EXAME
GESTACAO 1─N MEDICACAO
GESTACAO 1─N VACINA
GESTACAO 1─0..1 PLANO_DE_PARTO
GESTACAO 1─N AVALIACAO_DSS
```

**Regra de ownership (única e uniforme):** as entidades-filhas da gestação
(`CONSULTA`, `EXAME`, `MEDICACAO`, `VACINA`, `PLANO_DE_PARTO`, `AVALIACAO_DSS`)
referenciam **apenas** `gestacao_id`. O caminho até a usuária é obtido por
`entidade → GESTACAO → GESTANTE → USER`, sem duplicar `gestante_id`/`user_id`
nas tabelas-filhas.

### 4.1 USER

- **Responsabilidade:** identidade/autenticação (conta de acesso).
- **Cardinalidade:** `1 ─ 1 GESTANTE`.
- **Ownership:** raiz do ownership.
- **Atributos conceituais:** `id` (UUID), `email` (único), `password_hash`,
  `estado_conta`, `telefone` (se a regra de produto exigir), timestamps.
- **Dependências:** nenhuma (raiz).
- **Origem Flutter:** `user`/`UserData` (`id`, `name`, `email`, `phone`) — mas
  **sem** senha; o `name` de `UserData` não deve ser fonte de verdade do nome
  pessoal (a fonte é `GESTANTE`).

### 4.2 GESTANTE

- **Responsabilidade:** perfil pessoal da gestante (pessoa).
- **Cardinalidade:** `USER 1 ─ 1 GESTANTE`; `GESTANTE 1 ─ N GESTACAO`;
  `GESTANTE 1 ─ 1 HISTORICO_OBSTETRICO`.
- **Ownership:** ligada a `USER` por `user_id` (FK, única).
- **Atributos conceituais:** `id` (UUID), `user_id` (FK), `name`, `birth_date`
  (`date`), `cpf` (opcional, sem PK), `social_name`, `national_health_card`.
- **Dependências:** `USER`.
- **Origem Flutter:** `pregnant`/`PregnantData` — mas **somente** os campos de
  pessoa (nome, nascimento, CPF, nome social, CNS). Os campos de logística
  (`prenatal_place`, `professional_name`, `prenatal_place_contact`) migram para
  `GESTACAO`.

### 4.3 GESTACAO

- **Responsabilidade:** episódio gestacional com identidade própria.
- **Cardinalidade:** `GESTANTE 1 ─ N GESTACAO`; `GESTACAO 1 ─ N` para
  `CONSULTA`/`EXAME`/`MEDICACAO`/`VACINA`/`AVALIACAO_DSS`; `GESTACAO 1 ─ 0..1
  PLANO_DE_PARTO`.
- **Ownership:** `gestante_id` (FK).
- **Atributos conceituais:** `id` (UUID), `gestante_id` (FK),
  `last_menstrual_period` (`date`), `first_ultrasound` (`date`),
  `prenatal_place`, `professional_name`, `prenatal_place_contact`,
  `reference_maternity` (distinto de `prenatal_place`, para eliminar a duplicação
  atual), timestamps.
- **Dependências:** `GESTANTE`.
- **Origem Flutter:** `current_pregnancy`/`CurrentPregnancyData` (DUM, 1ª USG) +
  a parte de logística de `pregnant`. Uma gestação concluída pode permanecer
  registrada como gestação histórica real.

### 4.4 HISTORICO_OBSTETRICO

- **Responsabilidade:** histórico obstétrico **agregado** (GPA) da gestante.
- **Cardinalidade:** `GESTANTE 1 ─ 1 HISTORICO_OBSTETRICO`.
- **Ownership:** `gestante_id` (FK).
- **Atributos conceituais:** `id` (UUID), `gestante_id` (FK), `pregnancy_number`,
  `given_birth_number`, `abortions_number`, timestamps.
- **Dependências:** `GESTANTE`.
- **Origem Flutter:** `previous_pregnancy`/`PreviousPregnancy`. ⚠️ **Não**
  representa uma gestação anterior individual — **não** transformar os três
  contadores em gestações passadas individuais.

### 4.5 CONSULTA

- **Responsabilidade:** consulta de pré-natal de uma gestação.
- **Cardinalidade:** `GESTACAO 1 ─ N CONSULTA`.
- **Ownership:** `gestacao_id` (FK).
- **Atributos conceituais:** `id` (UUID), `gestacao_id` (FK), `title`,
  `appointment_date` (`date`), `description`, timestamps.
- **Dependências:** `GESTACAO`.
- **Origem Flutter:** `appointment`/`Appointment` (lista; `title`/`appointment_date`/
  `description`).

### 4.6 EXAME

- **Responsabilidade:** exame de pré-natal de uma gestação.
- **Cardinalidade:** `GESTACAO 1 ─ N EXAME`.
- **Ownership:** `gestacao_id` (FK).
- **Atributos conceituais:** `id` (UUID), `gestacao_id` (FK), `title`,
  `exam_date` (`date`), `description`, timestamps.
- **Dependências:** `GESTACAO`.
- **Origem Flutter:** `exam`/`Exam` (lista). Manter como entidade **distinta** de
  `CONSULTA` (semânticas e ciclos de vida diferentes: o exame evolui para
  resultado/laudo/anexo).

### 4.7 MEDICACAO

- **Responsabilidade:** medicamento do acompanhamento de uma gestação.
- **Cardinalidade:** `GESTACAO 1 ─ N MEDICACAO`.
- **Ownership:** `gestacao_id` (FK).
- **Atributos conceituais:** `id` (UUID), `gestacao_id` (FK), `name`, `dose`,
  `medication_time` (texto livre no MVP), timestamps.
- **Dependências:** `GESTACAO`.
- **Origem Flutter:** `medication`/`Medication` (lista). Não inventar campos de
  periodicidade/dose/horário estruturados.

### 4.8 VACINA

- **Responsabilidade:** checklist vacinal **contextual ao pré-natal** de uma
  gestação.
- **Cardinalidade:** `GESTACAO 1 ─ N VACINA`.
- **Ownership:** `gestacao_id` (FK).
- **Atributos conceituais:** `id` (UUID), `gestacao_id` (FK), `name`, `used`
  (`boolean`), timestamps.
- **Dependências:** `GESTACAO`.
- **Origem Flutter:** `vaccine`/`VaccineData` (catálogo pré-cadastrado + toggle
  `used`). Para o MVP, associar o checklist à `GESTACAO`; a separação
  catálogo/registro longitudinal fica para evolução futura (não implementar
  agora).

### 4.9 PLANO_DE_PARTO

- **Responsabilidade:** preferências/expectativas do parto **de uma gestação**
  (agregate).
- **Cardinalidade:** `GESTACAO 1 ─ 0..1 PLANO_DE_PARTO`.
- **Ownership:** `gestacao_id` (FK).
- **Atributos conceituais:** `id` (UUID), `gestacao_id` (FK), e sub-estruturas:
  `expectation` (7 preferências), `birth_moment` (via/anestesia/episiotomia/
  posição), `pain_relief` (desejo + 8 métodos), `birth` (corte/coleta/células/
  contato/amamentação/restrições/banho), `observations` (texto livre),
  timestamps.
- **Dependências:** `GESTACAO`.
- **Origem Flutter:** 5 tabelas de registro único — `expectation`, `birth_moment`,
  `pain_relief`, `birth`, `observations`. A **Identificação/História/Gestação
  atual** da UI de Parto são **contexto externo** (reutilizam `GESTANTE`,
  `HISTORICO_OBSTETRICO`, `GESTACAO`) e **não** são copiadas para dentro do
  plano. A forma física (tabela com colunas vs `JSONB`) é decisão da FASE 8B —
  ver seção 7.
- **Natureza:** captura **preferência/plano**, **não** o desfecho real do parto.

### 4.10 AVALIACAO_DSS

- **Responsabilidade:** futura persistência **operacional** da avaliação DSS,
  associada à gestação.
- **Cardinalidade:** `GESTACAO 1 ─ N AVALIACAO_DSS`.
- **Ownership:** `gestacao_id` (FK).
- **Atributos conceituais:** `id` (UUID), `gestacao_id` (FK), `schema_version`,
  `payload` (respostas DSS), `probability`, `model_name`, `model_version`,
  `created_at`.
- **Dependências:** `GESTACAO`.
- **Origem Flutter:** nenhuma tabela local hoje — o fluxo DSS é stateless (não
  persiste). É a ponte futura entre o acompanhamento e o eixo DSS.

> ⚠️ `AVALIACAO_DSS` **não altera** o contrato congelado
> `POST /api/v1/risk-estimate` (seção 9). A persistência operacional **não**
> autoriza, por si, o uso dos dados como dataset científico (seção 14).

---

## 5. Mapeamento do modelo local atual → modelo futuro

| Origem atual (modelo/tabela) | Problema atual | Entidade futura | Estratégia |
|---|---|---|---|
| `PregnantData` → `pregnant` | Responsabilidade mista: pessoa + logística do pré-natal | `GESTANTE` (pessoa) + `GESTACAO` (logística) | Separar responsabilidades: `name`/`birth_date`/`cpf`/`social_name`/`national_health_card` → `GESTANTE`; `prenatal_place`/`professional_name`/`prenatal_place_contact` → `GESTACAO` |
| `UserData` → `user` | Identidade de acesso **sem** senha, sem vínculo | `USER` | Modelar conta com `email` único + `password_hash`; o `name` de `UserData` deixa de ser fonte de verdade (passa a `GESTANTE`) |
| `CurrentPregnancyData` → `current_pregnancy` | Registro único local, id fixo `1` no save (🔴 perde 1ª gravação), sem vínculo | `GESTACAO` | Episódio gestacional com identidade própria (UUID) e `gestante_id` |
| `PreviousPregnancy` → `previous_pregnancy` | Agregado obstétrico solto; id fixo `1` no save (🔴) | `HISTORICO_OBSTETRICO` | **Não** fabricar gestações individuais a partir dos 3 contadores (GPA) |
| `Appointment` → `appointment` | Lista sem vínculo; data como String | `CONSULTA` | Adicionar `gestacao_id`; data `date`/ISO 8601 |
| `Exam` → `exam` | Lista sem vínculo; rótulo "nascimento" na UI; data como String | `EXAME` | Entidade distinta; adicionar `gestacao_id` |
| `Medication` → `medication` | Lista sem vínculo; `medication_time` texto livre | `MEDICACAO` | Adicionar `gestacao_id`; manter texto livre no MVP |
| `VaccineData` → `vaccine` | Catálogo + toggle; seed com ids 0..6 (só `HB_1` persiste) | `VACINA` (checklist da gestação) | Adicionar `gestacao_id`; `used` como boolean real |
| `Expectation` → `expectation` | 7 enums por ordinal; registro único | `PLANO_DE_PARTO.expectation` | Consolidar no aggregate; enums por string estável |
| `BirthMoment` → `birth_moment` | 3 enums + posição por ordinal; registro único | `PLANO_DE_PARTO.birth_moment` | Consolidar no aggregate; enums por string estável |
| `PainRelief` → `pain_relief` | 1 enum + 8 bools 0/1; registro único | `PLANO_DE_PARTO.pain_relief` | Consolidar no aggregate; booleanos reais |
| `Birth` → `birth` | 4 enums por ordinal + 2 bools 0/1; registro único | `PLANO_DE_PARTO.birth` | Consolidar no aggregate; enums/booleanos tipados |
| `Observations` → `observations` | texto livre; registro único | `PLANO_DE_PARTO.observations` | Consolidar no aggregate |
| `RiskEstimateRepository` (HTTP) | Já integrado (DSS→API→ML), stateless | `AVALIACAO_DSS` (persistência futura) | Manter fluxo congelado; adicionar persistência associada à `GESTACAO` em rota autenticada futura |

> **Casos fora do domínio persistente:** `InformationPage` (informações básicas),
> `NotificacoesPage`, `ConfiguracoesPage` e `SobreAppPage` são estáticos/estado
> local e **não** possuem modelo/tabela — não migram. Os dropdowns `maritalStatus`,
> `education`, `income` de "Meus Dados" hoje não persistem; a decisão de
> incorporá-los ao domínio (`GESTANTE`) é **aberta** e depende do autor/produto.

---

## 6. Identidade e autenticação

Separação conceitual obrigatória:

- **AUTENTICAÇÃO** ("quem é?"): verifica a identidade da usuária.
- **AUTORIZAÇÃO** ("pode acessar este recurso?"): valida ownership sobre o
  recurso (seção 6.7).

### 6.1 Fluxo de cadastro

1. Usuária fornece `email` + `senha` (+ confirmação).
2. Servidor valida unicidade do `email`, aplica `password_hash` (Argon2id).
3. Cria `USER` (estado `ativo`/`pendente_confirmacao` a definir) e,
   conceitualmente, vincula/ou cria a `GESTANTE` associada (1:1).
4. Devolve sessão (access + refresh) — ou exigência de confirmação de e-mail,
   se a regra de produto assim decidir (decisão aberta).

> **CPF não é PK nem login.** CPF é dado de perfil (`GESTANTE.cpf`), opcional;
> a chave primária é `UUID`. Não assumir que CPF será credencial.

### 6.2 Login

- `POST` de login recebe `email` + `senha`; o servidor compara com o
  `password_hash` (Argon2id, em tempo constante).
- Em sucesso, emite **access token** (curta duração) + **refresh token** (longa
  duração).

### 6.3 Sessão / access token

- Candidato principal: **JWT** de acesso (claims mínimas: `sub` = `user_id`,
  `exp`, `iat`, `scope`/`type`), assinado com chave do servidor.
- O Flutter guarda o access token em memória/`SharedPreferences` e o envia como
  `Authorization: Bearer <token>`.

### 6.4 Refresh

- Endpoint dedicado troca um refresh token válido por um novo par.
- **Decisão aberta:** rotação de refresh token (revogar o antigo a cada uso)
  vs. token opaco de longa duração. Fica para a subfase de implementação, com
  justificativa de segurança.

### 6.5 Logout

- Cliente descarta tokens; servidor revoga o refresh token (se a estratégia
  adotada mantiver estado de revogação). O "Sair" atual (navegação) é substituído
  por logout real.

### 6.6 Recuperação de sessão

- Refresh token permite retomar sessão sem nova senha; expirado o refresh, a
  usuária refaz login. Recuperação de senha ("esqueceu a senha") é **fora do
  MVP** (atualmente um toast de contato).

### 6.7 Relação User/Gestante e autorização por ownership

- `USER 1 ─ 1 GESTANTE`; o `user_id` está apenas em `GESTANTE`.
- Para toda rota de dados persistidos, a autorização resolve o caminho
  `USER autenticado → GESTANTE → GESTACAO → recurso`:
  1. A dependência `get_current_user` lê o JWT e carrega o `USER`.
  2. Carrega a `GESTANTE` do usuário (`gestante.user_id == user.id`).
  3. Para rotas de gestação, carrega a `GESTACAO` e verifica
     `gestacao.gestante_id == gestante.id`.
  4. Recursos-filhos da gestação são acessados **somente** através da gestação
     do próprio usuário.
- Violação de ownership → `404` (não revelar existência) ou `403` (decisão de
  contrato a fechar; recomenda-se `404` para não vazar existência).

> **Terminologia:** isso é **controle de propriedade/autorização** de registros,
> **não** "multi-tenancy".

### 6.8 Reaproveitamento do legado

- `UserRepositoryImpl`/`UserLoginServiceImpl`/`LoginController` documentam a
  **intenção** do fluxo, mas serão **reescritos** contra os novos endpoints e o
  novo modelo de sessão (access + refresh).
- `AuthInterceptor` (injeção condicional via `DIO_AUTH_KEY`) é **reaproveitável**
  como mecanismo de anexar o header; deve ser adaptado para o novo token.
- **Dívida futura (não implementada nesta fase):** auditar o `LogInterceptor`
  existente no cliente de login e, na futura implementação de autenticação,
  **não registrar body** contendo senha, token ou dados pessoais, removendo ou
  desabilitando o logging sensível (substituir por `PrivacyLogInterceptor`).

---

## 7. Persistência backend

### 7.1 Banco

- **PostgreSQL** como banco persistente do backend (relacional, transacional,
  suporte a UUID nativo, `JSONB`, constraints e indexação adequadas ao domínio
  relacional com ownership).

### 7.2 ORM

- **Arquitetura principal congelada:** PostgreSQL + **SQLAlchemy 2.x** + **Alembic**.
- **SQLAlchemy 2.x** é a escolha por maturidade, suporte estável a PostgreSQL e
  por **não acoplar** a camada ORM à camada de contratos Pydantic (o projeto já
  trata `contracts/` como camada distinta, com `extra="forbid"` e DTOs versionados).
- **SQLModel não é a escolha principal** neste planejamento: unifica ORM e
  Pydantic, conflitando com o princípio "DTO de entrada ≠ entidade ORM ≠ DTO de
  resposta" (seção 10).
- **Modo de acesso (sync vs async) = decisão de infraestrutura a validar antes da
  implementação.** Não há evidência técnica concreta no backend atual que exija
  sessões assíncronas; a escolha considerará simplicidade, driver PostgreSQL,
  padrão atual da API e estratégia de testes.

### 7.3 Migrations

- **Alembic** para migrations versionadas e reproduzíveis — alinhado à cultura do
  projeto (artefatos versionados, manifests, seeds fixas).

### 7.4 Identificadores (UUID)

- **Adotar UUID v4** como chave primária das novas entidades persistentes.
- O **servidor** gera o UUID (default na inserção); o Flutter o representa como
  `String`. Isso evita dependência de geração no cliente e mantém a API como
  fonte de verdade. **Validar** a representação Dart (String) antes de congelar.

### 7.5 Timestamps, constraints, integridade

- `created_at`/`updated_at` (`timestamptz`) preenchidos pelo servidor.
- `FOREIGN KEY` com `ON DELETE` explícito (provável `RESTRICT`/`CASCADE`
  conforme a entidade — decisão por subfase).
- Unicidade onde o domínio exigir (ex.: `USER.email` único). `UNIQUE` de
  `GESTANTE.cpf` **somente** se a regra de produto o exigir (não assumir).
- `NOT NULL`/`CHECK` para os campos obrigatórios.

### 7.6 Delete físico × soft delete

- **Não adicionar soft delete por padrão.** Adotar delete físico a menos que haja
  requisito real (ex.: auditoria, retenção regulatória). Para `AVALIACAO_DSS`,
  avaliar retenção como registro operacional — decisão aberta.

### 7.7 Forma física do PLANO_DE_PARTO

- Duas opções (decisão FASE 8B): (a) tabela única com colunas para os ~5 grupos;
  (b) `JSONB` para os sub-blocos (`expectation`, `birth_moment`, `pain_relief`,
  `birth`) + coluna de texto para `observations`. Recomenda-se avaliar `JSONB`
  para os sub-blocos enumerados (as preferências evoluem por adição de campos),
  mantendo a raiz `PLANO_DE_PARTO` relacional com `gestacao_id`.

---

## 8. Recursos REST propostos

> **Proposta inicial — NÃO implementar.** Segue o prefixo `/api/v1` já adotado e
> o vocabulário de domínio em pt-BR. Nomes de recurso em kebab-case
> (`plano-parto`, `avaliacoes-dss`), campos em snake_case pt-BR — coerente com o
> contrato DSS. A alternativa em inglês (`/pregnancies`, `/appointments`) fica
> registrada como opção a confirmar na FASE 8B.

| Recurso | GET | POST | PATCH/PUT | DELETE |
|---|---|---|---|---|
| `/api/v1/auth/register` | — | criar conta + sessão | — | — |
| `/api/v1/auth/login` | — | login + tokens | — | — |
| `/api/v1/auth/refresh` | — | renovar tokens | — | — |
| `/api/v1/auth/logout` | — | revogar sessão | — | — |
| `/api/v1/me` | perfil do usuário | — | — | — |
| `/api/v1/gestantes/me` | perfil da gestante | criar (se ausente) | atualizar perfil | — |
| `/api/v1/gestacoes` | listar gestações | criar gestação | — | — |
| `/api/v1/gestacoes/{gestacao_id}` | detalhar | — | atualizar | (a definir) |
| `/api/v1/gestantes/me/historico-obstetrico` | obter | — | atualizar (PUT/PATCH) | — |
| `/api/v1/gestacoes/{gestacao_id}/consultas` | listar | criar | — | — |
| `/api/v1/gestacoes/{gestacao_id}/consultas/{consulta_id}` | obter | — | atualizar | excluir |
| `/api/v1/gestacoes/{gestacao_id}/exames` | listar | criar | — | — |
| `/api/v1/gestacoes/{gestacao_id}/exames/{exame_id}` | obter | — | atualizar | excluir |
| `/api/v1/gestacoes/{gestacao_id}/medicamentos` | listar | criar | — | — |
| `/api/v1/gestacoes/{gestacao_id}/medicamentos/{medicamento_id}` | obter | — | atualizar | excluir |
| `/api/v1/gestacoes/{gestacao_id}/vacinas` | listar | criar (checklist) | — | — |
| `/api/v1/gestacoes/{gestacao_id}/vacinas/{vacina_id}` | obter | — | atualizar (`used`) | excluir |
| `/api/v1/gestacoes/{gestacao_id}/plano-parto` | obter | criar | atualizar (upsert) | (a definir) |
| `/api/v1/gestacoes/{gestacao_id}/avaliacoes-dss` | listar | criar | — | — |
| `/api/v1/gestacoes/{gestacao_id}/avaliacoes-dss/{avaliacao_id}` | obter | — | — | (a definir) |

**Observações de desenho:**

- **`HISTORICO_OBSTETRICO`** pertence à `GESTANTE` (1:1), **não** à `GESTACAO`;
  representa dados agregados (nº de gestações, partos, abortos) e **não** uma
  gestação passada individual. Recurso exposto em
  `/api/v1/gestantes/me/historico-obstetrico` com `GET` + `PUT`/`PATCH`.
- **`PLANO_DE_PARTO`** é 0..1 por gestação → `GET`/`POST`/`PATCH` (upsert), sem
  coleção.
- **`AVALIACAO_DSS`** persiste a estimativa associada à gestação (futuro); o
  contrato de escrita **não** é o `DssPayload` 1.13 diretamente — ver seção 9.
- **DELETE de `GESTACAO`**: propõe-se **não** expor exclusão no MVP (evitar perda
  acidental); manter `PATCH` para encerrar/marcar. Decisão aberta.
- **Convenção de resposta:** envelope de erro reutiliza `ErrorResponse`/
  `ErrorEnvelope` já existentes; sucesso usa `response_model` Pydantic tipado.
- **Granularidade:** sub-recursos aninhados sob `gestacoes/{id}` garantem
  ownership por construção da URL (seção 6.7).

---

## 9. Relação com o endpoint DSS congelado

- **`POST /api/v1/risk-estimate` permanece congelado.** Nenhuma alteração agora:
  mantém `DssPayload` 1.13, stateless, sem identidade, sem persistência, sem
  classe de risco/threshold.
- **Futuro (não decidido, não implementado):** um fluxo autenticado persistente
  poderá ser exposto como, por exemplo,
  `POST /api/v1/gestacoes/{gestacao_id}/avaliacoes-dss` (ou
  `/gestacoes/{gestacao_id}/risk-estimate`), com header `Authorization` e
  **reaproveitando** o `DssPayload` 1.13 como corpo, **sem** alterar o endpoint
  congelado.
- **Avaliação das alternativas (sem quebrar 4D/5A–5D):**
  1. **Manter o endpoint anônimo + criar rota autenticada separada** (recomendado):
     o eixo experimental continua intacto; a persistência é uma rota nova sob o
     domínio da gestação.
  2. **Estender o endpoint existente** — **descartado** (violaria o contrato
     congelado e as Fases 4D/5A).
  3. **Substituir por rota autenticada** — **descartado** (quebraria o fluxo
     Flutter atual já validado).
- O `PrivacyLogInterceptor` e a resposta como **probabilidade** `[0,1]` +
  `notice` permanecem invariantes em qualquer evolução.

---

## 10. Contratos e DTOs futuros

### 10.1 Princípios

- **DTO de entrada ≠ entidade ORM**: o que a API recebe (Pydantic) não é o que o
  ORM persiste.
- **DTO de resposta ≠ model Flutter**: a resposta da API não espelha as classes
  Dart; o Flutter mapeia para seus próprios models.
- **Enums por strings estáveis** (códigos snake_case, como no DSS), **nunca** por
  ordinal.
- **Datas em ISO 8601** (`YYYY-MM-DD` / `timestamptz`), **não** `dd/MM/yyyy`.
- **Booleanos reais** (`true`/`false`), **não** `0/1`.
- **IDs estáveis** como `UUID` em string.
- **Nullability explícita** (campo ausente vs `null`); `extra="forbid"` nos
  contratos.
- **Validação de domínio** no backend (regras de invariantes, como já ocorre no
  `DssPayload`).
- **Campos calculados** (IG, DPP) não são transportados como campos persistidos;
  podem ser calculados no servidor quando aplicável.

### 10.2 Problemas atuais a corrigir na transição

| Problema atual (Flutter) | Correção no contrato futuro |
|---|---|
| Enums persistidos por ordinal (`.index`) | Enums por string estável versionável |
| Datas `dd/MM/yyyy` (String) | ISO 8601 / `date`/`datetime` |
| Booleanos `0/1` | Booleanos reais |
| Tabelas de registro único (single-record) | Entidades com UUID + coleções (1:N) |
| `created_at` nulo por envio explícito | `created_at`/`updated_at` preenchidos pelo servidor |
| IDs locais `int` | UUIDs públicos |

---

## 11. Estratégia de transição Flutter

**Objetivo:** a API passa a ser a **fonte de verdade** do acompanhamento
pré-natal; o SQLite deixa de ser fonte primária, feature por feature.

- **NÃO** remover toda persistência local de uma vez.
- **NÃO** implementar offline-first/sincronização nesta fase.
- **NÃO** assumir `SQLite → DTO → POST` automático como requisito do MVP.
- **NÃO** implementar migração automática dos dados SQLite antigos.

**Padrão por feature (baixo risco):**

1. Manter a **interface** do repositório (`XRepository`) estável — os controllers
   continuam chamando os mesmos métodos.
2. Criar uma **implementação REST** (`XRepositoryImpl` remoto) que consome os
   novos endpoints, mantendo a assinatura da interface.
3. Trocar a injeção da implementação (SQLite → REST) no módulo de DI
   (`*_module.dart` / `core_module.dart`).
4. Validar a feature contra o servidor (testes de integração Flutter → API →
   PostgreSQL).
5. Quando validada, a API torna-se a fonte principal daquela feature; a
   implementação SQLite correspondente é desativada/removida (em subfase
   posterior, não simultaneamente à ativação da REST).

> A retirada do SQLite e qualquer cache/offline são tratadas **somente depois**,
> como evolução separada (ver seção 12, itens 13–14).

---

## 12. Ordem recomendada de implementação

Sequência proposta (auditada sobre a ordem da FASE 6A e a hipótese inicial):

| # | Etapa | Justificativa |
|---|-------|---------------|
| 1 | **Infraestrutura de persistência backend** (PostgreSQL, ORM, Alembic, base de settings/DB) | Pré-requisito de tudo; sem schema, nada persiste |
| 2 | **Autenticação** (cadastro, login, access/refresh, logout) | Habilita identidade; ownership depende de identidade |
| 3 | **USER + GESTANTE** (perfil, `gestantes/me`) | Separa identidade de pessoa; base do ownership |
| 4 | **GESTACAO** (`gestacoes`) | Núcleo do domínio; todos os filhos dependem de `gestacao_id` |
| 5 | **HISTORICO_OBSTETRICO** | Pertence a `GESTANTE`; migra `previous_pregnancy` |
| 6 | **CONSULTA** e **EXAME** (listas com `gestacao_id`) | Primeiras coleções 1:N; baixa complexidade |
| 7 | **MEDICACAO** | Coleção 1:N |
| 8 | **VACINA** (checklist com `used`) | Coleção 1:N; resolve o bug do seed |
| 9 | **PLANO_DE_PARTO** (aggregate das 5 tabelas) | Maior consolidação; exige decisão de forma física (7.7) |
| 10 | **Associação/persistência DSS** (`AVALIACAO_DSS`) | Nova rota autenticada; **não** toca o endpoint congelado |
| 11 | **Flutter consumindo a nova API** (feature por feature) | Migração de código, mantendo interfaces |
| 12 | **Retirada progressiva do SQLite** como fonte de verdade | Somente após validação por feature |
| 13 | **Offline/cache/sync** | Apenas posteriormente, como evolução separada |

> **Paralelizações possíveis:** 5 (histórico) pode avançar em paralelo após 3
> (`GESTANTE`, já que pertence à gestante); 6–9 (listas/plano) avançam após 4
> (`GESTACAO`). A ordem exata será detalhada nas subfases FASE 8B em diante.

---

## 13. Estratégia de testes futura

Pirâmide mínima:

- **API (backend):**
  - **Unitários:** contratos Pydantic (validação/invariantes), mapeamento
    DTO→domínio.
  - **Service/domain:** regras de negócio e ownership.
  - **Repository/database:** persistência contra PostgreSQL (ou container de
    teste), constraints e unicidade.
  - **Endpoints:** respostas, status e envelopes de erro.
  - **Auth:** cadastro/login/refresh/logout.
  - **Ownership:** acesso negado (404/403) a recursos de outra usuária.
- **Flutter:**
  - **Repository/client:** implementações REST com Dio mockado (contratos de
    requisição/resposta e mapeamento de falhas).
  - **Controller:** lógica de estado (MobX) com repositório fake.
  - **Widget** quando necessário (fluxos de formulário/navegação).
- **Integração:** Flutter → API → PostgreSQL (round-trip real por feature).
- **E2E DSS/ML existente permanece separado** (não é reexecutado aqui).

---

## 14. Segurança e privacidade

Escopo técnico (sem análise jurídica extensa):

- **Password hashing:** Argon2id (parâmetros OWASP), nunca senha em texto plano,
  nunca em log.
- **Token:** access de curta duração + refresh; revogação no logout; transporte
  somente via `Authorization` header sobre HTTPS.
- **HTTPS em produção** obrigatório (dados pessoais e de saúde).
- **Dados pessoais:** mínimo necessário; tratar `cpf`, `email`, `national_health_card`
  e payload DSS como sensíveis.
- **Mínimo privilégio:** cada rota exige apenas o escopo necessário.
- **Autorização:** ownership estrito por `USER → GESTANTE → GESTACAO` (seção 6.7).
- **Logs sem dados sensíveis (requisito futuro, não implementado nesta fase):**
  na implementação de autenticação, auditar o `LogInterceptor` existente e
  **nunca** logar corpo/headers com dados pessoais (senha, token, CPF, payload
  DSS), removendo ou desabilitando o logging sensível e adotando
  `PrivacyLogInterceptor` em todo cliente autenticado.
- **LGPD como requisito de engenharia:** base legal, finalidade, minimização e
  direito de acesso/exclusão a considerar no desenho das rotas e do armazenamento.
- **Separação entre persistência operacional e uso científico:** os dados
  operacionais reais **não** se tornam automaticamente dataset científico.
  Qualquer uso científico futuro exige consentimento, privacidade/LGPD,
  metodologia e aprovação ética — fora do escopo desta fase.

---

## 15. Decisões congeláveis

| Decisão | Proposta | Evidência | Pode congelar? |
|---|---|---|---|
| Banco persistente = PostgreSQL | Adotar PostgreSQL | Domínio relacional com ownership; UUID/JSONB/constraints nativos | **Congelada** |
| ORM = SQLAlchemy 2.x + Alembic | Adotar SQLAlchemy 2.x (SQLModel descartado como principal); DTO ≠ entidade; sync/async a validar | Maturidade; separação da camada `contracts/`; cultura de versionamento | **Congelada** (exceto modo sync/async) |
| IDs = UUID v4 (servidor) | Adotar UUID v4 | Multi-usuário; sem enumeração; sem colisão entre ambientes | **Congelada** (validar representação Dart) |
| Password hashing = Argon2id | Adotar Argon2id | Recomendação OWASP atual | **Já sustentada** |
| Token = JWT access + refresh | Adotar access curto + refresh longo | Padrão para API; desacopla sessão | **Depende de implementação** (estratégia de refresh/rotação) |
| Ownership por `gestacao_id` (sem FKs redundantes) | Caminho `USER→GESTANTE→GESTACAO→recurso` | Evita duplicação de FKs; FASE 6A | **Já sustentada** |
| Enums por string, datas ISO 8601, bool reais | Adotar no backend | Evita ordinal/0-1/dd-MM-yyyy do legado | **Já sustentada** |
| Soft delete | **Não** por padrão | Sem requisito real | **Já sustentada** |
| DELETE de `GESTACAO` no MVP | Não expor; usar PATCH | Evitar perda acidental | **Depende do autor/produto** |
| Nome de recursos REST (pt-BR vs inglês) | Proposta pt-BR kebab-case | Coerência com domínio pt-BR e contrato DSS | **Depende do autor** (confirmar 8B) |
| Forma física do `PLANO_DE_PARTO` (colunas vs JSONB) | Avaliar JSONB para sub-blocos | Preferências evoluem por adição | **Depende de implementação** (8B) |
| Unicidade/obrigatoriedade do CPF | Não assumir PK/login; unicidade só se produto exigir | CPF é dado de perfil | **Depende do autor** |
| Recuperação de senha | Fora do MVP | Custo/complexidade adicional | **Depende do autor** |
| Ambiente PostgreSQL (local/container/cloud) | Definir infra de dev/teste | Requer infraestrutura | **Depende de infraestrutura** |
| Retenção/delete de `AVALIACAO_DSS` | A definir | LGPD/uso operacional | **Depende do autor + LGPD** |

---

## 16. Riscos

| Risco | Impacto | Mitigação |
|---|---|---|
| Quebra do fluxo DSS (endpoint congelado) | Alto | Não tocar `risk-estimate`; evolução por rota autenticada separada |
| Acoplamento auth ↔ risk-estimate | Médio | Manter DSS anônimo/stateless; auth aplicada só nas novas rotas |
| Migração abrupta do SQLite | Alto | Migração feature por feature; manter interfaces; validar antes de desativar SQLite |
| Inconsistência de dados (dupla fonte durante transição) | Médio | Fonte de verdade explícita por feature; não escrever nas duas ao mesmo tempo |
| Ownership incorreto (vazamento entre usuárias) | Crítico | Autorização central no caminho `USER→GESTANTE→GESTACAO`; testes de ownership |
| Duplicação User/Gestante | Médio | `USER 1─1 GESTANTE`; `user_id` só em `GESTANTE`; fonte de verdade do nome em `GESTANTE` |
| Enums incompatíveis (ordinal legado × string novo) | Médio | Mapeamento explícito; nunca transportar enum por ordinal |
| Datas (dd/MM/yyyy × ISO 8601) | Médio | Converter na borda do contrato; validar timezone |
| Plano de parto excessivamente acoplado | Médio | Aggregate `PLANO_DE_PARTO`; contexto (identificação/histórico/gestação) fora do aggregate |
| Premature offline/sync | Alto | Adiar explicitamente; não implementar nesta versão |
| Bug de ID local (`id:1`/seed vacinas) herdado na migração | Médio | Corrigir na implementação REST (não migrar o bug); revisar sentinel `id==0` |
| Vazamento de credenciais por `LogInterceptor` (dívida **não** corrigida nesta fase) | Médio | Ação futura: auditar e remover/desabilitar logging sensível (adotar `PrivacyLogInterceptor`) na implementação de auth |

---

## 17. Plano de implementação

Divisão da FASE 8 em subfases pequenas e auditáveis (numeração proposta, sujeita
à revisão após aprovação desta arquitetura):

- **FASE 8A (esta):** arquitetura e planejamento — auditorias, domínio, REST,
  transição, riscos, decisões.
- **FASE 8B — Modelagem contratual e de persistência:** fechar decisões da seção
  15; desenhar schemas Pydantic (DTOs) e modelo ORM (tabelas/constraints) +
  migrations Alembic; contrato de auth (token/refresh); forma física do
  `PLANO_DE_PARTO`; nomenclatura final dos recursos REST.
- **FASE 8C — Infraestrutura e autenticação:** Postgres + ORM + migrations;
  cadastro/login/refresh/logout; ownership como dependência reutilizável.
- **FASE 8D — Núcleo do domínio:** `USER`, `GESTANTE`, `GESTACAO`,
  `HISTORICO_OBSTETRICO` + rotas e testes.
- **FASE 8E — Entidades da gestação:** `CONSULTA`, `EXAME`, `MEDICACAO`, `VACINA`,
  `PLANO_DE_PARTO` + rotas e testes.
- **FASE 8F — Associação DSS persistida:** `AVALIACAO_DSS` (rota autenticada),
  sem tocar o endpoint congelado.
- **FASE 8G — Consumo Flutter:** repositories REST por feature, mantendo
  interfaces; testes de integração Flutter → API → PostgreSQL.
- **FASE 8H — Retirada do SQLite como fonte de verdade** (progressiva).
- **FASE 8I (posterior):** offline/cache/sync — somente como evolução separada.

> Cada subfase deve terminar com `git diff --check` limpo e testes verdes; o
> commit é feito somente mediante autorização explícita.

---

## 18. Impacto acadêmico futuro

> Nenhum documento acadêmico é alterado nesta fase. Abaixo, apenas o que deverá
> ser atualizado em uma subfase **FASE 8A-DOC**, após congelamento da arquitetura.

Mapeamento para `docs/tcc2.md` (não modificar agora) e para o DOCX mestre:

| Seção da monografia (DOCX §5.2) | Impacto previsto |
|---|---|
| **3 Metodologia → 3.11** (validação da integração Flutter→API→ML) | Registrar a futura validação do **novo** eixo autenticado/persistente, sem descrever o endpoint congelado de forma equivocada |
| **4 Desenvolvimento da Solução → 4.1** (arquitetura) | Atualizar o diagrama/descrição para incluir o backend persistente (PostgreSQL + auth + rotas CRUD) |
| **4.3 / 4.4 / 4.5 / 4.7** (eixo 2, armazenamento, autenticação, arquitetura futura) | Descrever a migração SQLite → API, o ownership e a autenticação real (substituindo o texto atual de "proposta futura") |
| **5 Resultados → 5.9** (validação da implementação de software) | Adicionar os resultados de validação dos novos endpoints e do consumo Flutter |
| **Diagramas** (arquitetura, ER) | Atualizar o modelo ER (USER/GESTANTE/GESTACAO/...) e o diagrama de arquitetura (3 componentes + persistência) |
| **3.12 / 5.10 / 6.2** (limitações) | Refletir a nova fronteira operacional × científica e a separação persistência × dataset |
| **DOCX mestre** (`docs/TCC2_MESTRE_Harliton_Martins.docx`) | Regenerar os capítulos afetados após a redação definitiva |

> **Ponto central a preservar:** o texto acadêmico deve continuar distinguindo
> **estado atual implementado** (pré-natal local/offline, login decorativo, DSS
> stateless) de **arquitetura futura/proposta**, e reafirmar que a persistência
> operacional **não** autoriza uso científico dos dados reais.

---

## Verificação

- `git diff --check` limpo.
- `git status --short`: somente `?? docs/PRENATAL_API_ARCHITECTURE_PLAN.md`.
- Nenhum arquivo de `lib/`, `api/`, `ia/`, `test/` ou dos docs congelados foi
  modificado.
- **NÃO COMMITAR.**
