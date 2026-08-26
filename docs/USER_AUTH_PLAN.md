# FASE 8C-PLAN — Plano técnico de identidade e autenticação (USER)

> **Natureza:** fase exclusivamente de **auditoria e planejamento**. Nenhuma
> dependência foi instalada, nenhum arquivo de código foi alterado, nenhum model,
> repository, service, endpoint ou migration foi criado. Este documento registra
> o estado **real** auditado e propõe a implementação futura de identidade e
> autenticação para a **FASE 8C-IMP**.
>
> **Abreviações de veredito** usadas ao longo do texto:
> - **DECIDIDO** — definido nesta fase (a 8C-IMP não deve reabrir).
> - **RECOMENDADO** — recomendação técnica com justificativa; a 8C-IMP pode
>   adotar diretamente, salvo objeção registrada.
> - **EM ABERTO** — ponto deliberadamente adiado, com decisão de contorno
>   registrada para não bloquear.
> - **FORA DO ESCOPO** — explicitamente excluído desta fase.

---

## 1. Objetivo, natureza, escopo e prioridades

**Objetivo.** Preparar, de forma documental, a **primeira implementação real**
de identidade/autenticação no backend FastAPI do projeto **Meu Bebê**, criando a
base técnica sobre a qual as relações futuras `USER → GESTANTE → GESTAÇÃO →
recursos` serão construídas. O plano deve ser preciso o suficiente para que a
**FASE 8C-IMP** execute sem decisões arquiteturais improvisadas.

**Natureza.** Fase de **auditoria + planejamento**. Nada é implementado, nada é
alterado, nada é commitado. A única entrega é este documento
(`docs/USER_AUTH_PLAN.md`).

**Escopo incluído (planejamento).**

- Auditoria do estado real de autenticação no backend e do código legado no
  Flutter (somente leitura).
- Definição do modelo `USER` (identidade/autenticação).
- Hash de senha Argon2id, política de senha e verificação.
- Modelo de tokens JWT (access + refresh), TTL e claims.
- Rotação simples de refresh token e revogação de sessão.
- Semântica de logout.
- Especificação de 5 endpoints (`register`, `login`, `refresh`, `logout`, `me`).
- Primeira migration Alembic (tabelas `users` e `auth_refresh_sessions`).
- Configuração/segredos, tratamento de erros, logging, matriz de testes.
- Plano de implementação da 8C-IMP e critérios de aceite.

**Fora do escopo desta fase (implementação e planejamento detalhado).**

- `GESTANTE` (e qualquer dado obstétrico/gestação) — seção 19.
- Integração Flutter de autenticação real — seção 19.
- Alterar o contrato DSS congelado — seção 19.

### 1.1 Prioridades do projeto (anti-overengineering)

**DECIDIDO.** O objetivo arquitetural **não** é reproduzir os mecanismos de
segurança de sistemas de produção de grande escala. A complexidade adotada deve
ser **proporcional à finalidade** do TCC. Ordem de prioridade:

1. funcionamento correto;
2. organização suficiente;
3. demonstração clara (para a banca);
4. manutenção simples;
5. segurança essencial;
6. integração com o restante do sistema;
7. compatibilidade com o cronograma do TCC.

O foco científico principal do TCC **continua sendo**: DSS → Flutter → API → ML
→ estimativa experimental de propensão à descontinuidade do pré-natal. O
acompanhamento pré-natal e a autenticação devem ser **funcionais**, com
complexidade proporcional à sua finalidade — nunca "nível enterprise".

---

## 2. Estado atual auditado da autenticação

### 2.1 Backend (verificado, não inferido)

| Item | Valor auditado |
|---|---|
| Módulo de autenticação | **Inexistente** — não há `auth/`, `services/` nem `repositories/` em `api/src/meu_bebe_api/`. |
| Modelos ORM de domínio | **Zero** — `Base.metadata.tables` é vazio (confirmado por `test_db_base.py`). |
| Migrations Alembic | **Zero revisões** — `api/alembic/versions/` contém apenas `.gitkeep`. |
| Bibliotecas de auth | **Nenhuma** — `pyproject.toml` não declara `passlib`, `bcrypt`, `argon2-cffi`, `pwdlib`, `pyjwt`, `python-jose`. |
| Campo de identidade no DSS | **Nenhum** — `DssPayload` (1.13, 48 variáveis) não tem `user_id`, `gestante_id`, `gestacao_id`, token nem auth. |
| Endpoint DSS | `POST /api/v1/risk-estimate` — **stateless**, sem auth, sem persistência. |
| Middleware de auth global | **Nenhum** — auth é aplicada apenas se/quando uma rota a declarar. |
| Infraestrutura de persistência | SQLAlchemy 2.x síncrono + psycopg 3 + Alembic prontos (FASE 8B), porém inertes (sem engine quando `DATABASE_URL` vazio). |

**Conclusão:** o backend **não possui autenticação** hoje. O único endpoint
funcional (`risk-estimate`) é deliberadamente anônimo e persistência-independente.

### 2.2 Flutter (auditado somente para contexto — NÃO alterar)

O código legado de autenticação no Flutter é **decorativo/não funcional**:

- `UserRepositoryImpl.login` faz `POST /auth {email,password}` e espera
  `{"access_token": ...}` — endpoint **que não existe** no backend.
- `UserLoginServiceImpl` armazena o `access_token` em **SharedPreferences**
  (chave `ACCESS_TOKEN_KEY`, em `LocalStorageConstants`) — armazenamento **não
  seguro** (não usa `flutter_secure_storage`).
- `LoginController.login` chama o service e, no sucesso, navega para `routeTab`
  — mas a chamada está **comentada** na tela: `LoginPage` navega diretamente
  (`Modular.to.pushReplacementNamed(routeTab)`) sem autenticar.
- "Criar nova conta" (`ChipLogin`) navega para `routeForm` (o questionário DSS),
  **não** para um cadastro de conta.
- "Sair" (`profile_page.dart`) apenas navega para `routeLogin`, sem revogar
  token nem limpar sessão.
- `AuthInterceptor` injeta `Authorization: Bearer` **somente** quando
  `extra['DIO_AUTH_KEY'] == true`; o token vem de SharedPreferences.
- `PrivacyLogInterceptor` registra apenas método/caminho/status/duração (sem
  corpo nem `Authorization`) — bom, mas o antigo `LogInterceptor` citado na
  FASE 8A é dívida registrada.
- Credenciais de demonstração **hardcoded** nos `TextEditingController` de
  `login_page.dart` (`fms@oab.am.gov.br` / `fms1622030013`).
- Modelo legado `UserData` usa `int id` (não UUID) com `name/email/phone`.

> Todo esse código permanece **fora do escopo** de alteração nesta fase e na
> 8C-IMP (seção 19).

### 2.3 Compatibilidade de bibliotecas com Python 3.14.5

| Biblioteca | Versão atual | Python 3.14 | Uso pretendido |
|---|---|---|---|
| `pwdlib` | 0.3.1 | **Sim** (`requires-python >=3.10`, classifier 3.14) | Hash de senha (Argon2id) |
| `argon2-cffi` | 25.1.0 | **Sim** (wheels ativos, mantido) | Backend Argon2 subjacente ao `pwdlib[argon2]` |
| `PyJWT` | 2.13.0 | **Sim** (desde 2.11.0) | Emitir/validar JWT |
| `email-validator` | (mantido) | **Sim** | Validação `EmailStr` do Pydantic |

Nenhuma destas será **instalada** agora (seção 5).

---

## 3. Escopo do modelo `USER`

**DECIDIDO.** `USER` representa **identidade + autenticação**. Nada além disso.

### 3.1 Campos do `USER` (não incluir mais nada)

| Campo | Tipo (Python/ORM) | PostgreSQL | Regras |
|---|---|---|---|
| `id` | `uuid.UUID` | `UUID` PK | UUID v4 **gerado no servidor** (Python `uuid.uuid4()` como default do ORM; nunca `gen_random_uuid()`) |
| `email` | `str` | `VARCHAR(320)` | **NOT NULL, UNIQUE**; normalizado (seção 3.2) |
| `password_hash` | `str` | `TEXT` NOT NULL | String PHC do Argon2id (nunca senha em claro) |
| `is_active` | `bool` | `BOOLEAN` NOT NULL | `DEFAULT true` |
| `created_at` | `datetime` | `TIMESTAMPTZ` NOT NULL | UTC, default `now` |
| `updated_at` | `datetime` | `TIMESTAMPTZ` NOT NULL | UTC, default `now` + `onupdate` |

**Proibido incluir em `USER`** (DECIDIDO): nome, CPF, CNS, data de nascimento,
endereço, dados obstétricos, qualquer dado de `GESTANTE` ou `GESTAÇÃO`. Esses
pertencerão a `GESTANTE` (fase posterior), numa relação **USER 1—1 GESTANTE**.

### 3.2 Normalização e unicidade de e-mail

**DECIDIDO.**

- Login/cadastro usam **e-mail + senha**.
- Normalização: `email.strip().lower()` antes de armazenar e antes de buscar.
- A unicidade é garantida em **dois níveis**: validação no service (busca antes
  de inserir) **e** constraint `UNIQUE` no banco (`uq_users_email`).
- Documenta-se a simplificação de *lowercase* do local-part (tecnicamente o
  local-part é *case-sensitive* por RFC, mas a prática comum — e a prevenção de
  duplicidade por diferença de caixa — justifica `lower()`; impacto prático nulo
  para o TCC).

---

## 4. Hash de senha — Argon2id

**DECIDIDO** (biblioteca, algoritmo, formato e funções).

- **Algoritmo:** **Argon2id** (variante recomendada pela OWASP para hashing de
  senha; resiste a ataques de GPU *e* de canal lateral).
- **Biblioteca:** **`pwdlib`** com o extra `argon2` (`pip install
  "pwdlib[argon2]"`), que usa `argon2-cffi` como backend. `pwdlib` oferece
  `PasswordHash.recommended()` e uma API `hash`/`verify` estável e rehashável,
  superior ao uso direto de `argon2-cffi` por já encapsular a evolução de
  parâmetros. (Alternativa registrada: `argon2-cffi` puro — funciona, porém
  exige mais código próprio. `passlib` foi **descartado**: projeto sem
  manutenção ativa.)
- **Formato do hash:** string **PHC** auto-descritiva
  `$argon2id$v=19$m=...,t=...,p=...$<salt_b64>$<hash_b64>`, contendo algoritmo,
  parâmetros, salt e digest. É o que o `argon2-cffi` produz e o que
  `password_hash` armazena integralmente.
- **Parâmetros:** usar os **defaults recomendados** do `argon2-cffi`/`pwdlib`
  para Argon2id (a referência OWASP interativa é m≥19 MiB, t=2, p=1). Não
  inventar parâmetros próprios; manter os defaults da biblioteca.

### 4.1 Funções (contrato interno)

```python
def hash_password(plaintext: str) -> str:
    """Retorna a string PHC Argon2id. Nunca loga nem retorna a senha."""

def verify_password(plaintext: str, phc_hash: str) -> bool:
    """Comparação em tempo constante. Wrong password → False (não levanta)."""
```

- `verify_password` **captura** a exceção de não-verificação e retorna `False`
  (nunca propaga o erro interno nem distingue "hash malformado" para o chamador
  HTTP).
- Rehash oportunista (`PasswordHash.needs_update`) fica **EM ABERTO** (não
  obrigatório no primeiro corte).

### 4.2 Política de senha

**DECIDIDO** (sem regras artificiais de composição).

- **Mínimo 8, máximo 128 caracteres** (o teto limita custo/DoS; Argon2id não tem
  o limite de 72 bytes do bcrypt).
- **Sem** exigência artificial de maiúscula + número + símbolo (sem justificativa
  técnica; alinhado a NIST SP 800-63B, que favorece comprimento sobre composição).
- Validação de tamanho no **Pydantic** (`min_length`/`max_length`): senha
  vazia/curta/longa → `422 VALIDATION_ERROR`, **antes** do service.
- **Nunca** armazenar senha em claro. **Nunca** logar senha nem `password_hash`.

---

## 5. Dependências novas (auditadas — NÃO instalar agora)

| Dependência | Função | Por quê | Compat. Python 3.14.5 | Alternativa |
|---|---|---|---|---|
| `pwdlib[argon2]` | Hash Argon2id | API estável, `recommended()`, rehash | Sim (0.3.1) | `argon2-cffi` puro |
| `PyJWT` | Emitir/validar JWT (HS256) | Padrão de facto, mantido | Sim (2.13.0) | `python-jose` (manutenção lenta) |
| `email-validator` | Validação `EmailStr` | Validação robusta de e-mail no Pydantic | Sim | `str` + regex mínima |

- A 8C-IMP adicionará essas dependências ao `pyproject.toml` **somente** na fase
  de implementação, com `pip install` real e verificação de wheel para 3.14.
- Nenhuma dependência nova é instalada nesta fase.

---

## 6. Tokens JWT — access + refresh

**DECIDIDO** (biblioteca, algoritmo, claims, tipos).

- **Biblioteca:** `PyJWT`.
- **Algoritmo:** **HS256** (HMAC-SHA256), segredo simétrico forte. Para um único
  serviço que emite **e** valida os próprios tokens, chave simétrica é a solução
  de menor complexidade. (RS256/assimétrica é **desnecessária** aqui.)

### 6.1 Claims

**Access token** (curto, `Authorization: Bearer <access>`):

| Claim | Valor |
|---|---|
| `sub` | `id` do `USER` (UUID v4 como string) |
| `type` | `"access"` |
| `iat` | emitido em (UTC, epoch) |
| `exp` | expiração (UTC, epoch) |

**Refresh token** (longo):

| Claim | Valor |
|---|---|
| `sub` | `id` do `USER` (UUID v4 como string) |
| `type` | `"refresh"` |
| `jti` | UUID v4 único do token (identificador persistido — seção 8) |
| `iat` | emitido em |
| `exp` | expiração |

### 6.2 `iss` / `aud` (omitidos nesta versão)

**DECIDIDO: omitir `iss` e `aud` nesta versão.** Justificativa:

- Trata-se de **um único serviço** que emite **e** valida os próprios tokens;
  não há terceiro verificador nem múltiplas audiences reais.
- HS256 + `type` obrigatório + `exp` + `jti` já cobrem o risco relevante para o
  TCC (separação access × refresh, expiração e identificação de sessão).
- Adicionar `iss`/`aud` exigiria configuração extra **sem benefício concreto**
  para o projeto, contrariando a prioridade anti-overengineering (seção 1.1).

Caso o projeto venha a ter múltiplos serviços/ambientes, `iss`/`aud` podem ser
reintroduzidos pontualmente (mudança localizada na emissão/validação).

### 6.3 Separação obrigatória de tipos (DECIDIDO)

- **Access não pode ser usado em `/refresh`** (a rota rejeita `type != "refresh"`).
- **Refresh não pode ser usado como access** (`get_current_user` rejeita
  `type != "access"`).
- A regra de tipo é **sempre** validada na decodificação, antes de qualquer
  leitura de banco.

---

## 7. TTL dos tokens

**DECIDIDO** (ajustável por `Settings`).

| Token | TTL | Justificativa |
|---|---|---|
| Access | **15 minutos** (900 s) | Curto o suficiente para limitar o raio de dano de um access roubado sem exigir *blacklist* de access no v1. |
| Refresh | **30 dias** (2 592 000 s) | Equilibra UX (não relogar a cada sessão) com a capacidade de revogação via `revoked_at` (seção 8). |

---

## 8. Rotação simples de refresh token e revogação de sessão

**DECIDIDO.** Modelo **simples**, sem família, sem `replaced_by`, sem detecção
sofisticada de replay e sem revogação em cascata.

### 8.1 Modelo `AUTH_REFRESH_SESSION`

| Campo | Tipo (Python/ORM) | PostgreSQL | Regras |
|---|---|---|---|
| `id` | `uuid.UUID` | `UUID` PK | UUID v4 servidor |
| `user_id` | `uuid.UUID` | `UUID` NOT NULL, **FK→users.id**, `ON DELETE CASCADE` | dono da sessão |
| `jti` | `uuid.UUID` | `UUID` **UNIQUE** | O `jti` do refresh token (identificador, não o JWT) |
| `created_at` | `datetime` | `TIMESTAMPTZ` NOT NULL | UTC |
| `expires_at` | `datetime` | `TIMESTAMPTZ` NOT NULL | UTC; ecoa `exp` do refresh |
| `revoked_at` | `datetime` | `TIMESTAMPTZ` NULL | `NULL` = ativa |

**Regra de persistência (DECIDIDO):** **nunca** armazenar o JWT completo em
claro. Persiste-se apenas **identificadores/metadados** (`jti`, `expires_at`,
`revoked_at`). O segredo e o token em si nunca vão ao banco.

### 8.2 Comportamento da rotação (DECIDIDO)

1. `POST /refresh` recebe um refresh token válido (assinatura, `exp`,
   `type="refresh"`, `jti` presente).
2. Carrega a sessão por `jti`.
3. **Não encontrada** → `401 TOKEN_INVALID`.
4. **`revoked_at IS NOT NULL`** → `401 TOKEN_REVOKED` (token antigo reutilizado;
   **sem** revogação em cascata).
5. **`expires_at < now`** → `401 TOKEN_EXPIRED`.
6. Carrega `USER` por `user_id`; valida `is_active` (senão `401`/`403`).
7. **Revoga a sessão utilizada** (`revoked_at = now`).
8. **Gera novo access** e **novo refresh** (novo `jti`); **persiste a nova
   sessão**.
9. **`commit`** atômico (revogação + inserção na mesma unidade de trabalho).
10. Retorna os novos tokens.

> Se um refresh antigo (já rotacionado) for reutilizado, a sessão correspondente
> tem `revoked_at` preenchido → o passo 4 responde `401`. **Não** há rastreamento
> de família nem revogação de outras sessões.

---

## 9. Semântica de logout

**DECIDIDO.**

- `POST /auth/logout` **recebe/identifica o refresh atual** e **marca a sessão
  como revogada** (`revoked_at = now`).
- O **access token existente permanece válido até sua expiração curta** (15 min).
- **Sem blacklist de access token** no v1 — limitação documentada e aceita
  (mitigada pelo TTL curto).
- Logout é **idempotente**: revogar uma sessão já revogada/inexistente não é
  erro (retorna sucesso, ex.: `204`).
- Após o logout, o cliente deve descartar access e refresh localmente (fora do
  escopo do backend).

### 9.1 Múltiplas sessões

**DECIDIDO.** Permite-se **naturalmente** mais de uma sessão por `USER` (ex.:
celular + outro dispositivo). Cada `login` cria uma nova sessão independente.
O logout de uma sessão **não** encerra as demais. **Não** implementar
gerenciamento de dispositivos nesta fase.

---

## 10. Endpoints de autenticação — visão geral

**DECIDIDO — prefixo definitivo `/api/v1/auth`.** Todos os endpoints de
autenticação usam o prefixo versionado **`/api/v1/auth`** (nunca `/auth/*`),
montados num `auth_router` incluído no `api_v1_router` (ao lado do
`risk_estimate_router`). Mantém coerência com `POST /api/v1/risk-estimate`.

| Método | Path | Auth | Papel |
|---|---|---|---|
| `POST` | `/api/v1/auth/register` | nenhuma | Cria `USER` e devolve tokens |
| `POST` | `/api/v1/auth/login` | nenhuma | Autentica e devolve tokens |
| `POST` | `/api/v1/auth/refresh` | refresh token | Rotaciona tokens |
| `POST` | `/api/v1/auth/logout` | refresh token | Revoga a sessão de refresh |
| `GET` | `/api/v1/auth/me` | access token | Retorna o `USER` autenticado |

- **Nenhuma** destas rotas altera o contrato DSS. **Nenhuma** autenticação é
  aplicada globalmente (não há middleware global); auth é declarada **somente**
  nas rotas que a exigem (`refresh`, `logout`, `me`).
- O prefixo `/api/v1/auth/*` **não** significa que `/api/v1/risk-estimate`
  passa a exigir autenticação. `POST /api/v1/risk-estimate` permanece:
  **público, stateless, sem token, sem banco, sem `USER`, sem `GESTANTE`, sem
  persistência.**

---

## 11. `POST /api/v1/auth/register`

**DECIDIDO — alternativa B: criar usuário E devolver tokens** (não apenas o
usuário). Justificativa: no v1 **não há verificação de e-mail**, então devolver
tokens imediatamente evita um segundo round-trip e já deixa a gestante
autenticada ao cadastrar.

### Request

```json
{ "email": "exemplo@dominio.com", "password": "senha-forte" }
```

- `email`: `EmailStr` (validação robusta; normalizado `strip().lower()`).
- `password`: `str`, 8–128 caracteres (seção 4.2).

### Response (201 Created)

```json
{
  "user": {
    "id": "<uuid>",
    "email": "exemplo@dominio.com",
    "is_active": true,
    "created_at": "<ISO8601 UTC>",
    "updated_at": "<ISO8601 UTC>"
  },
  "access_token": "<jwt>",
  "refresh_token": "<jwt>"
}
```

- `user` é a **identificação segura**: **nunca** `password_hash`/`password`.
- `created_at`/`updated_at` em ISO 8601 com offset UTC (`Z`/`+00:00`).

### Fluxo (service controla a transação — UM ÚNICO commit)

1. Normalizar e-mail (`strip().lower()`); validar entrada (Pydantic).
2. Buscar usuário por e-mail normalizado (repository); se existir →
   `409 DUPLICATE_EMAIL`.
3. `hash_password(plaintext)`.
4. Criar `USER`; repository adiciona **sem commit** (com `flush` se necessário
   para obter o `id`).
5. Gerar access token.
6. Gerar refresh token (novo `jti`).
7. Criar `AUTH_REFRESH_SESSION` (associada ao `user_id`); repository adiciona
   **sem commit**.
8. Service executa **UM ÚNICO `commit`** (USER + sessão na mesma unidade de
   trabalho).
9. Retornar `USER` seguro + tokens (`201`).

**Atomicidade (DECIDIDO).** Como a alternativa B cria o usuário **e** já
retorna tokens, `USER` e `AUTH_REFRESH_SESSION` são criados na **mesma
transação**. Se qualquer etapa falhar → **rollback integral**. Não há `USER`
parcialmente criado se a criação da sessão falhar (e vice-versa). Repository
continua **sem commit**; o service/use case continua dono da transação. Isso
não é aumento de complexidade — é apenas garantia de consistência.

### Tratamento de duplicidade (DECIDIDO)

- Validação de aplicação (passo 2) + `UNIQUE` no banco + captura de concorrência.
- Conflito concorrente de e-mail: `UNIQUE` do PostgreSQL → `IntegrityError` →
  **`rollback`** → **HTTP 409** (`DUPLICATE_EMAIL`), com mensagem sanitizada.

---

## 12. `POST /api/v1/auth/login`

**DECIDIDO** (fluxo e anti-enumeração).

### Fluxo

1. Normalizar e-mail (`strip().lower()`); validar (Pydantic).
2. Buscar usuário por e-mail (repository).
3. Se **não existe** → resposta de credencial inválida (ver abaixo).
4. `verify_password(password, user.password_hash)`.
5. Se **senha inválida** → mesma resposta de credencial inválida.
6. Validar `is_active`: se `False` → `403 ACCOUNT_INACTIVE`.
7. Criar access + refresh; persistir nova sessão de refresh.
8. `commit`; retornar tokens (`200`, mesma forma da seção 11).

### Anti-enumeração (DECIDIDO)

- Usuário inexistente **e** senha errada retornam **a mesma** resposta:
  `401 INVALID_CREDENTIALS`, com mensagem idêntica (ex.: "E-mail ou senha
  inválidos.").
- **Dummy hash:** pode-se executar uma verificação Argon2 *dummy* quando o
  usuário não existe, **se** a implementação permanecer simples. Não criar
  infraestrutura adicional apenas para isso.

### Status

| Situação | Status | Código |
|---|---|---|
| Sucesso | `200` | — (tokens + `user`) |
| E-mail inexistente | `401` | `INVALID_CREDENTIALS` |
| Senha errada | `401` | `INVALID_CREDENTIALS` |
| Credenciais corretas, `is_active=false` | `403` | `ACCOUNT_INACTIVE` |

---

## 13. `POST /api/v1/auth/refresh` — fluxo completo e atômico

**DECIDIDO.**

### Request

```json
{ "refresh_token": "<jwt>" }
```

### Fluxo (service controla `commit`/`rollback`)

1. Decodificar + verificar o refresh: assinatura, `exp`, `type == "refresh"`,
   `jti` presente. Falha → `401` (`TOKEN_INVALID`/`TOKEN_EXPIRED`).
2. Carregar sessão por `jti` (repository).
3. **Não encontrada** → `401 TOKEN_INVALID`.
4. **Revogada** (`revoked_at IS NOT NULL`) → `401 TOKEN_REVOKED` (reuso; sem
   cascata).
5. **Expirada** (`expires_at < now`) → `401 TOKEN_EXPIRED`.
6. Carregar `USER`; validar `is_active` (senão `401`/`403`).
7. **Revogar a sessão utilizada** (`revoked_at = now`).
8. **Gerar novo access** + **novo refresh** (novo `jti`); **persistir nova sessão**.
9. **`commit` atômico** (revogação + inserção na mesma unidade).
10. **Qualquer exceção** → `rollback` → `500` sanitizado (`TOKEN_ERROR`), sem
    vazar segredo/token/hash.

> A atomicidade garante que nunca fica uma janela em que a sessão antiga foi
> revogada sem a nova ter sido criada (o que deixaria o usuário deslogado) nem
> o inverso (duplicação de sessão válida).

---

## 14. `GET /api/v1/auth/me` + dependência `get_current_user`

**DECIDIDO.**

### Dependência `get_current_user`

- Requer `Authorization: Bearer <access>`.
- Decodifica/verifica: assinatura, `exp`, **`type == "access"`** (rejeita
  refresh — seção 6.3), `sub` presente.
- Localiza o `USER` por `sub`.
- Valida `is_active` (senão `401`/`403`).
- Retorna o objeto `USER` (para o handler da rota).
- **Não há** acesso a outro `USER`: a identidade é exclusivamente `sub`; sem
  ownership de `GESTANTE` ainda (fora do escopo).

### Response (`GET /auth/me` — 200)

```json
{
  "id": "<uuid>",
  "email": "exemplo@dominio.com",
  "is_active": true,
  "created_at": "<ISO8601 UTC>",
  "updated_at": "<ISO8601 UTC>"
}
```

- Nunca expõe `password_hash`. Não expõe `GESTANTE` (inexistente nesta fase).

### Status

| Situação | Status | Código |
|---|---|---|
| Sucesso | `200` | — |
| Access ausente/malformado/expirado/`type!=access` | `401` | `UNAUTHORIZED`/`TOKEN_INVALID`/`TOKEN_EXPIRED` |
| Usuário inativo | `403` | `ACCOUNT_INACTIVE` |

---

## 15. Primeira migration Alembic

**DECIDIDO** (schema real; **NÃO criar** o revision nesta fase).

### 15.1 Tabela `users`

| Coluna | Tipo PostgreSQL | Constraints/defaults |
|---|---|---|
| `id` | `UUID` | PK `pk_users`; default servidor (Python `uuid.uuid4()`) |
| `email` | `VARCHAR(320)` | `NOT NULL`, `UNIQUE` → `uq_users_email` |
| `password_hash` | `TEXT` | `NOT NULL` |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT true` |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, default `now()` UTC |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, default `now()` UTC + `onupdate` |

### 15.2 Tabela `auth_refresh_sessions`

| Coluna | Tipo PostgreSQL | Constraints/defaults |
|---|---|---|
| `id` | `UUID` | PK `pk_auth_refresh_sessions`; default servidor |
| `user_id` | `UUID` | `NOT NULL`, FK `fk_auth_refresh_sessions_user_id_users` → `users.id` `ON DELETE CASCADE` |
| `jti` | `UUID` | `NOT NULL`, `UNIQUE` → `uq_auth_refresh_sessions_jti` |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, default `now()` UTC |
| `expires_at` | `TIMESTAMPTZ` | `NOT NULL` |
| `revoked_at` | `TIMESTAMPTZ` | `NULL` |

### 15.3 Índices e convenções

- `ix_auth_refresh_sessions_user_id` (lookup por usuário).
- Nomes de constraints vêm da `naming_convention` única de `Base.metadata`
  (seção 16), garantindo `autogenerate` estável.

### 15.4 Regras de migration

- **UUID v4 gerado no Python** (`uuid.uuid4()` como `default=` da coluna ORM),
  **não** `gen_random_uuid()`.
- **Timestamps UTC** (`DateTime(timezone=True)`); nunca timezone local.
- `upgrade()`: cria `users` e depois `auth_refresh_sessions` (ordem respeita a FK).
- `downgrade()`: drop em ordem inversa.
- Revisar o revision manualmente antes de `alembic upgrade head` (política 8B).
- **NÃO criar migration nesta fase** (proibido).

---

## 16. Arquitetura em camadas preservada (8B)

**DECIDIDO.** A implementação de auth **mantém** a arquitetura congelada na 8B:

```
Router (contratos/DTO Pydantic — camada contracts/)
        ↓
Service / Use Case (caso de uso — auth_service)
        ↓
Repository (acesso a dados — user_repository, refresh_session_repository)
        ↓
SQLAlchemy 2.x Session (síncrona)
        ↓
psycopg (postgresql+psycopg://)
        ↓
PostgreSQL
```

Regras obrigatórias (herdadas da 8B-PLAN §14):

- **Repository NÃO faz `commit`** — apenas executa queries/ORM na `Session`.
- **Service controla `commit`/`rollback`** — uma operação de escrita = uma
  unidade de trabalho atômica.
- **`get_session` dependency fornece e fecha a `Session`** (yield + `finally`).
- Nenhum `autocommit` implícito; transação explícita.

Estrutura de arquivos **planejada** (NÃO criar agora):

```
src/meu_bebe_api/
├── auth/
│   ├── __init__.py
│   ├── security.py        (hash_password, verify_password, emit/verify JWT)
│   ├── dependencies.py    (get_current_user)
│   └── service.py         (auth_service: register/login/refresh/logout/me)
├── repositories/
│   ├── __init__.py
│   ├── user_repository.py
│   └── refresh_session_repository.py
├── models/  (ou db/models/)
│   ├── __init__.py
│   ├── user.py            (User)
│   └── auth_refresh_session.py
└── api/
    └── auth.py            (auth_router + endpoints)
```

(Nomes de diretório são sugestão; a 8C-IMP pode ajustar desde que preserve a
divisão Router→Service→Repository e as regras de transação.)

---

## 17. Configuração e segredos

**DECIDIDO** (campos, segredo e comportamento de indisponibilidade).

### 17.1 Novos campos em `Settings`

| Campo | Default | Descrição |
|---|---|---|
| `jwt_secret` | *(vazio)* | Segredo HS256. Vazio = auth **não configurada** (inerte). |
| `jwt_algorithm` | `HS256` | Algoritmo JWT. |
| `access_token_ttl_seconds` | `900` | TTL do access (15 min). |
| `refresh_token_ttl_seconds` | `2592000` | TTL do refresh (30 dias). |

> `iss`/`aud` são **omitidos** nesta versão (seção 6.2), logo não há campos
> `jwt_issuer`/`jwt_audience`.

### 17.2 Regras de segredo (DECIDIDO)

- `JWT_SECRET` **nunca** hardcoded, commitado, logado ou exposto em
  `ValidationError` (mesma disciplina da `DATABASE_URL` na 8B — mensagens
  genéricas, sem ecoar valor/campo).
- `.env` permanece no `.gitignore`; `.env.example` ganha **placeholder** apenas
  (`JWT_SECRET=` vazio ou marcador explícito `change-me`), **sem segredo real**.
- Recomenda-se segredo com alta entropia (≥ 32 bytes), gerado externamente.

### 17.3 Comportamento em indisponibilidade (DECIDIDO — fail-closed, sem acoplar o DSS)

| Situação | Comportamento |
|---|---|
| **(A) Auth não configurada** (`JWT_SECRET` vazio) | Endpoints de auth respondem `503 AUTH_NOT_CONFIGURED`. O processo **sobe normalmente** (subsistema inerte, mesmo padrão do `DATABASE_URL`). DSS inalterado. |
| **(B) `DATABASE_URL` não configurada** | Endpoints de auth (que dependem de banco) respondem `503 DATABASE_UNAVAILABLE` (`get_session` falha explicitamente). DSS inalterado. |
| **(C) PostgreSQL indisponível** | Endpoints de auth respondem `503 DATABASE_UNAVAILABLE` (erro de conexão sanitizado). DSS inalterado. |

- **FastAPI e o fluxo DSS permanecem independentes:** `/risk-estimate` **não** se
  torna dependente de banco; não há middleware global de auth; a auth é declarada
  apenas nas rotas `refresh`/`logout`/`me`.

---

## 18. Erros HTTP e logging

### 18.1 Erros HTTP (DECIDIDO)

Reutilizar o envelope `ErrorResponse {code, message, details}` já existente.
Novos códigos estáveis (sem expor stack/URL/usuário do banco/segredo/senha/hash/JWT):

| Código | HTTP | Contexto |
|---|---|---|
| `VALIDATION_ERROR` | `422` | Payload inválido (Pydantic) — **plano**, como hoje |
| `INVALID_CREDENTIALS` | `401` | Login: e-mail/senha inválidos (anti-enumeração) |
| `ACCOUNT_INACTIVE` | `403` | Credenciais válidas, `is_active=false` |
| `UNAUTHORIZED` | `401` | Access ausente/`type!=access` em rota protegida |
| `TOKEN_INVALID` | `401` | JWT malformado/assinatura inválida |
| `TOKEN_EXPIRED` | `401` | JWT/sessão expirada |
| `TOKEN_REVOKED` | `401` | Refresh reutilizado/já revogado |
| `DUPLICATE_EMAIL` | `409` | Registro com e-mail já existente |
| `AUTH_NOT_CONFIGURED` | `503` | `JWT_SECRET` ausente |
| `DATABASE_UNAVAILABLE` | `503` | Banco indisponível/não configurado (rotas de auth) |
| `TOKEN_ERROR` | `500` | Falha inesperada na emissão/validação (sanitizado) |

- **Não modificar** o envelope DSS congelado. Os novos `401`/`403`/`409` seguem o
  formato **plano** `{code, message, details}` (consistente com o `422`); o
  formato exato do `500`/`503` é definido na 8C-IMP sem alterar o DSS.

### 18.2 Logging (DECIDIDO)

**Nunca** logar:

- senha, `password_hash`, access token, refresh token, cabeçalho `Authorization`,
  `JWT_SECRET`, `DATABASE_URL` completa (com credenciais).

**Pode** logar:

- endpoint, método, status HTTP, **UUID do usuário** (após autenticado) e `jti`
  (identificador de sessão, não o token). Mascarar/omitir qualquer campo ambíguo.

A política de *whitelist* da 8B (§22) permanece: logar o mínimo, nunca "logar
tudo e filtrar depois".

---

## 19. Fora de escopo, guardas e roadmap

### 19.1 Flutter — FORA DO ESCOPO

- **Nenhuma** mudança em `LoginController`, token storage, `SharedPreferences`,
  navegação, tela de login, "Criar nova conta" ou "Sair".
- **Nenhuma** integração real de auth no cliente nesta fase nem na 8C-IMP.
- Registro do que o Flutter **deverá** fazer no futuro (não agora): consumir
  `register`/`login`, armazenar tokens de forma **segura**
  (`flutter_secure_storage`, **não** SharedPreferences), renovar access via
  `refresh`, efetuar logout revogando a sessão e estabelecer sessão antes de
  qualquer módulo persistente. Migrar o `int id` legado de `UserData` para UUID.

### 19.2 `GESTANTE` — FORA DO ESCOPO

- `GESTANTE` (nome, CPF, CNS, nascimento, endereço, dados obstétricos) e
  `GESTAÇÃO` **não** entram no `USER` nem nesta fase.
- Garantir **apenas** que `USER` seja compatível com uma futura relação
  **USER 1—1 GESTANTE** (o `id` UUID de `USER` servirá de referência).

### 19.3 Nota arquitetural — cadastro final (USER + GESTANTE)

**DECIDIDO (nota de arquitetura; NÃO implementar GESTANTE agora).**

A **FASE 8C implementa somente identidade/autenticação**. Entretanto, o
aplicativo final deverá possuir um fluxo funcional de cadastro que apresente à
usuária, num único processo percebido como "Criação de conta":

- **DADOS DE ACESSO** (e-mail + senha) → `USER`;
- **DADOS DA GESTANTE** (perfil pessoal) → `GESTANTE`.

A separação de backend continua:

- `USER` → identidade/autenticação;
- `GESTANTE` → perfil pessoal.

A futura **FASE 8D** implementará `GESTANTE + GESTAÇÃO`. Na integração Flutter
futura, o fluxo de *onboarding* poderá ser:

```
POST /auth/register       → tokens / USER
POST /gestantes/me        → criação do perfil GESTANTE
(→ criação/registro da GESTAÇÃO quando aplicável)
```

Para a usuária, isso **poderá aparecer como um único processo** de criação de
conta, embora internamente sejam recursos distintos.

### 19.4 Guarda absoluta do DSS — FORA DO ESCOPO de alteração

- `POST /api/v1/risk-estimate` continua funcionando **sem** login, sem
  `Authorization`, sem `user_id`/`gestante_id`/`gestacao_id`, sem banco e sem
  persistência.
- **Nenhum** middleware global de auth. Auth apenas nas rotas que a exigem.
- A indisponibilidade de auth/banco nunca afeta o DSS.

### 19.5 Impacto no TCC — somente planejamento documental futuro

- Impacto futuro previsto: **Capítulo 4** (implementação/resultados) e
  **Capítulo 5** (conclusão) poderão registrar a introdução de identidade e
  autenticação. **Nenhuma** alteração em DOCX ou `tcc2.md` nesta fase.

### 19.6 Roadmap funcional pós-8C

| Fase | Escopo |
|---|---|
| **8D** | `GESTANTE` + `GESTAÇÃO` |
| **8E** | Histórico obstétrico |
| **8F** | Consultas + exames |
| **8G** | Medicamentos + vacinas |
| **8H** | Plano de parto |
| **8I** | Persistência operacional da avaliação DSS, **sem** alterar o endpoint stateless congelado |
| **8J** | Integração Flutter com backend persistente/autenticação |

O objetivo final é que **cadastro, acompanhamento e plano de parto sejam
funcionais**. O **DSS permanece como foco científico principal**.

---

## 20. Plano de implementação da FASE 8C-IMP e critérios de aceite

Ordem proposta (nenhum passo executado agora):

1. **8C-IMP.1 — Dependências/configuração**
   - Adicionar `pwdlib[argon2]`, `PyJWT`, `email-validator` ao `pyproject.toml`
     (verificar wheels p/ Python 3.14) e instalar.
   - Adicionar `jwt_secret`/`jwt_algorithm`/TTLs ao `Settings` e placeholders ao
     `.env.example`.

2. **8C-IMP.2 — Modelos ORM**
   - `models/user.py` (`User`) e `models/auth_refresh_session.py`
     (`AuthRefreshSession`), herdando de `Base`, com UUID v4 Python e timestamps UTC.

3. **8C-IMP.3 — Primeira migration**
   - Gerar e **revisar manualmente** o revision que cria `users` e
     `auth_refresh_sessions`; `alembic upgrade head` no banco dev/teste.

4. **8C-IMP.4 — Segurança (hash + JWT)**
   - `auth/security.py`: `hash_password`, `verify_password`, emitir/validar access
     e refresh com `PyJWT` (HS256, `type` obrigatório).

5. **8C-IMP.5 — Repositories**
   - `user_repository` (find by email, create, find by id) e
     `refresh_session_repository` (create, find by jti, revoke), **sem commit**.

6. **8C-IMP.6 — Service**
   - `auth_service` com `register`, `login`, `refresh` (rotação simples), `logout`,
     `me` — controlando `commit`/`rollback` (transações atômicas).

7. **8C-IMP.7 — Rotas e dependency**
   - `api/auth.py` (`auth_router`) com os 5 endpoints; `dependencies.py`
     (`get_current_user`); incluir no `api_v1_router`.

8. **8C-IMP.8 — Erros e logging**
   - Mapear novos códigos (seção 18.1); garantir *whitelist* de log.

9. **8C-IMP.9 — Testes**
   - Implementar a matriz da seção abaixo (PostgreSQL real dedicado `meu_bebe_test`).

10. **8C-IMP.10 — Auditoria final**
    - `git diff --check` limpo, suíte verde, DSS inalterado, critérios de aceite
      verificados.

### 20.1 Matriz de testes (banco de teste = PostgreSQL REAL)

| Grupo | Casos representativos |
|---|---|
| **CONFIG** | `JWT_SECRET` vazio → auth inerte; TTL lidos de `Settings`; placeholder no `.env.example`; segredo nunca ecoado em erro de validação. |
| **MIGRATION** | `alembic upgrade head` cria `users` + `auth_refresh_sessions`; `downgrade` remove em ordem inversa; colunas/constraints/índices conferidos. |
| **REGISTER** | sucesso `201`; e-mail normalizado (`strip().lower()`); senha curta/longa → `422`; e-mail inválido → `422`; duplicado → `409` (inclusive corrida/`IntegrityError`); resposta **sem** `password_hash`. |
| **LOGIN** | sucesso `200` + tokens; e-mail inexistente **e** senha errada → mesma resposta `401 INVALID_CREDENTIALS`; `is_active=false` → `403`. |
| **PASSWORD HASHING** | hash é PHC Argon2id; `verify` em tempo constante; senha nunca em log. |
| **ACCESS TOKEN** | `/me` com access válido → `200`; expirado → `401`; `type=refresh` no `/me` → `401`; `sub` inexistente → `401`. |
| **REFRESH** | refresh válido rotaciona (antiga revogada, nova criada); refresh expirado → `401`; refresh revogado/reutilizado → `401` (**sem** cascata). |
| **LOGOUT** | revoga a sessão; idempotente; access continua válido até expirar (limitação). |
| **MÚLTIPLAS SESSÕES** | dois logins criam sessões independentes; logout de uma não revoga a outra. |
| **ME** | retorna só o próprio `USER`; sem `password_hash`; sem `GESTANTE`. |
| **TRANSAÇÃO** | rotação atômica (falha simulada → rollback, sem sessão órfã); repository não commita; service commita/rollback. |
| **SEGURANÇA** | senha/`password_hash`/token/`Authorization`/segredo nunca em log. |
| **REGRESSÃO DSS** | `/health` `200`, `/ready` contrato, `/risk-estimate` inalterado e independente de auth/banco (matriz DSS existente verde). |

> **Testes removidos por overengineering** (conceitos que deixaram de existir):
> `token family`, `family revocation`, `replay family`, `replaced_by`. Nenhum
> teste específico para esses mecanismos é criado.

> **Banco de teste:** PostgreSQL real dedicado (`meu_bebe_test`), **nunca**
> SQLite — mesmo princípio congelado na 8B-PLAN §19. Testes de auth dependentes
> de banco pulam explicitamente se `TEST_DATABASE_URL` indisponível.

### 20.2 Critérios de aceite da 8C-IMP

- [ ] Registro cria `USER` com e-mail normalizado e `password_hash` Argon2id (nunca claro).
- [ ] Login autentica e distingue anti-enumeração (`401` idêntico p/ e-mail/senha).
- [ ] Access e refresh são JWT HS256 com `type` obrigatório e separação estrita.
- [ ] Refresh rotaciona com revogação simples da sessão utilizada; reuso → `401`.
- [ ] Logout revoga a sessão; sem blacklist de access no v1 (documentado).
- [ ] `/me` + `get_current_user` retornam apenas o próprio `USER` ativo.
- [ ] Migration cria as duas tabelas com UUID v4 Python, FK `CASCADE`, índices e UTC.
- [ ] Arquitetura 8B preservada (repository sem commit; service commit/rollback; session por request).
- [ ] `JWT_SECRET`/`DATABASE_URL`/PostgreSQL ausentes → `503` controlado, sem afetar DSS.
- [ ] Nenhum segredo/senha/token/hash em log ou erro.
- [ ] `POST /api/v1/risk-estimate`, `/health`, `/ready` **inalterados**.
- [ ] `git diff --check` limpo; suíte verde (PostgreSQL real nos testes de auth).

---

> **Fim do plano da FASE 8C-PLAN.** Este documento é a única entrega desta fase.
> A implementação (FASE 8C-IMP) e o registro acadêmico serão realizados em fases
> posteriores, com autorização explícita. **NÃO COMMITAR.**
