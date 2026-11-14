# Meu Bebê — Aplicativo Mobile & Sistema Integrado

Aplicativo móvel (Flutter) integrado a backend REST (FastAPI) e pipeline analítico de Machine Learning (Python) que une, em uma mesma solução:

1. **Questionário dos Determinantes Sociais da Saúde (DSS)** — coleta estruturada de 48 variáveis em seis dimensões (educação, trabalho e renda, saneamento, acesso aos serviços de saúde, habitação e alimentação), conforme o schema congelado v1.13;
2. **Módulo de acompanhamento do pré-natal** — gerenciamento completo de dados da gestante, gestação ativa, histórico obstétrico, consultas, exames, medicamentos prescritos, vacinas, plano de parto detalhado e histórico de avaliações DSS;
3. **Estimativa experimental e análise de dados (ML / IA)** — inferência probabilística experimental de descontinuidade do acompanhamento pré-natal via modelo Random Forest, associada ao Índice de Vulnerabilidade Social (IV-DSS) e agrupamento não supervisionado por mapas auto-organizáveis (SOM).

> ⚠️ **Disclaimer:** a estimativa produzida é **estatística e experimental** —
> **não** é diagnóstico médico nem certeza de abandono. Não há classificação de
> baixo/médio/alto risco nem aplicação de threshold clínico. Os dados de treinamento
> são sintéticos e servem exclusivamente para validação técnica do pipeline.
> Consulte [`docs/tcc/tcc2.md`](docs/tcc/tcc2.md).

---

## Arquitetura Geral

O sistema adota uma arquitetura em três camadas desacopladas:

```
meu_bebe_mobile/
├── lib/                 # Aplicativo móvel Flutter (Dart)
│   └── app/
│       ├── core/        # Configurações, clientes REST (Dio), interceptors JWT, tema e helpers
│       ├── enum/        # Enums de domínio (escolaridade, tipo de parto, etc.)
│       ├── model/       # DTOs e modelos de domínio (gestante, consulta, exame, DSS, etc.)
│       ├── repositories/# Repositórios de acesso remoto via API REST (Dio + Result)
│       └── modules/     # Módulos e telas (Modular + MobX): auth, cadastro, pré-natal, DSS
├── api/                 # Backend REST FastAPI (Python 3.14)
│   ├── alembic/         # Migrações de banco de dados (revisões 0001 a 0007)
│   └── src/meu_bebe_api/# Rotas REST (/api/v1), autenticação JWT, modelos SQLAlchemy e ML runtime
├── ia/                  # Pacote de IA/ML meu-bebe-ml (Python)
│   ├── configs/         # Schemas YAML (schema_v1_13 e simulation_v1)
│   ├── src/meu_bebe_ml/ # Simulação (DGM), IV-DSS, pré-processamento, modelos e SOM
│   ├── scripts/         # Scripts de geração sintética, treino, calibração e SOM
│   └── artifacts/       # Artefatos congelados (modelos joblib, métricas e figuras do SOM)
├── docs/                # Documentação acadêmica (TCC2), planos de arquitetura e relatórios
└── test/                # Suíte de testes unitários e de integração do Flutter
```

> **Evolução da persistência:** O protótipo inicial utilizava SQLite local no Flutter.
> Na versão atual, **todo o legado SQLite foi completamente removido** do aplicativo móvel
> em favor de uma **arquitetura cliente-servidor centralizada**, na qual o backend FastAPI
> gerencia a persistência no PostgreSQL com controle transacional e autenticação segura.

---

## Pré-requisitos

- **Flutter SDK** (`^3.13.2` ou superior, Dart 3)
- **Python 3.12+** (recomendado **Python 3.14**)
- **PostgreSQL 14+** (bancos `meu_bebe` e `meu_bebe_test`)
- **Android Emulator** ou dispositivo físico Android configurado para depuração

---

## 1. Backend e API (FastAPI)

A API reside no diretório `api/` e utiliza arquitetura assíncrona/síncrona robusta com fail-closed para serviços não configurados.

### 1.1 Configuração e Instalação (Windows / PowerShell)

```powershell
# 1. A partir da raiz do repositório, entre no diretório da API
cd api

# 2. Crie e ative o ambiente virtual dedicado
py -3.14 -m venv .venv
.\.venv\Scripts\Activate.ps1

# 3. Instale as dependências da API e o pacote de IA em modo editável
pip install -e ".[dev]"
pip install -e ..\ia

# 4. Configure o arquivo de ambiente (.env)
cp .env.example .env
```

Edite o `.env` gerado e defina as variáveis essenciais:
```env
APP_NAME=meu-bebe-api
APP_HOST=127.0.0.1
APP_PORT=8000
DATABASE_URL=postgresql+psycopg://postgres:senha@localhost:5432/meu_bebe
TEST_DATABASE_URL=postgresql+psycopg://postgres:senha@localhost:5432/meu_bebe_test
JWT_SECRET=sua_chave_secreta_com_minimo_32_bytes_de_alta_entropia
```

### 1.2 Execução das Migrações e Inicialização

```powershell
# Aplicar todas as migrações no banco PostgreSQL
alembic upgrade head

# Iniciar o servidor de desenvolvimento
python -m uvicorn meu_bebe_api.main:app --host 127.0.0.1 --port 8000 --reload
```

A documentação interativa OpenAPI/Swagger estará acessível em:
`http://127.0.0.1:8000/docs`.

### 1.3 Catálogo de Endpoints Principais

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET`  | `/health` | Liveness probe do serviço |
| `GET`  | `/ready`  | Readiness probe do modelo de ML (conferência SHA-256 e pipeline) |
| `POST` | `/api/v1/auth/register` | Cadastro de novos usuários |
| `POST` | `/api/v1/auth/login` | Autenticação (emissão de Access Token JWT + Refresh Session) |
| `POST` | `/api/v1/auth/refresh` | Renovação de token de acesso via refresh token |
| `GET`  | `/api/v1/auth/me` | Dados do usuário autenticado |
| `GET`/`PUT` | `/api/v1/gestantes/me` | Consulta e atualização do perfil da gestante |
| `GET`/`POST` | `/api/v1/gestacoes` | Listagem e cadastro de gestações da gestante |
| `GET`  | `/api/v1/gestacoes/ativa` | Recuperação da gestação ativa corrente |
| `GET`/`PUT` | `/api/v1/historico-obstetrico` | Histórico obstétrico anterior |
| `GET`/`POST` | `/api/v1/gestacoes/{id}/consultas` | CRUD de consultas pré-natais |
| `GET`/`POST` | `/api/v1/gestacoes/{id}/exames` | CRUD de exames laboratoriais e de imagem |
| `GET`/`POST` | `/api/v1/gestacoes/{id}/medicamentos` | CRUD de medicamentos prescritos |
| `GET`/`POST` | `/api/v1/gestacoes/{id}/vacinas` | Registro e acompanhamento vacinal |
| `GET`/`PUT` | `/api/v1/gestacoes/{id}/plano-parto` | Plano de parto estruturado |
| `GET`/`POST` | `/api/v1/gestacoes/{id}/avaliacoes-dss` | Histórico e registro de questionários DSS vinculados |
| `POST` | `/api/v1/risk-estimate` | Estimativa probabilística experimental de descontinuidade |

> Para detalhes completos dos contratos e modelos Pydantic, veja [`docs/api/README.md`](docs/api/README.md) e [`docs/api/API_CONTRACT_V1.md`](docs/api/API_CONTRACT_V1.md).

---

## 2. Aplicativo Mobile (Flutter)

O aplicativo móvel foi desenvolvido com **Flutter**, utilizando **Flutter Modular** para injeção de dependências e roteamento, **MobX** para gerência de estado e **Dio** para comunicação HTTP com interceptors transparentes de renovação de sessão e privacidade de log.

### 2.1 Preparação do Ambiente e Geração de Código

Na raiz do repositório:

```bash
# 1. Obter pacotes do Flutter
flutter pub get

# 2. Gerar arquivos reativos do MobX (*.g.dart)
dart run build_runner build --delete-conflicting-outputs
```

### 2.2 Execução no Emulador Android

O emulador Android acessa o host local através do endereço especial `10.0.2.2`. Ambas as variáveis de ambiente devem ser fornecidas via `--dart-define`:

```bash
flutter run -d emulator-5554 \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8000
```

> **Dica:** O arquivo [`.vscode/launch.json`](.vscode/launch.json) já contém perfis prontos para executar no Emulador (`10.0.2.2:8000`) ou em Dispositivo Físico (`192.168.x.x:8000`), bastando pressionar <kbd>F5</kbd> no VS Code.

### 2.3 Execução em Dispositivo Físico via Wi-Fi

Para rodar em um celular físico conectado na mesma rede Wi-Fi que o computador:
1. Obtenha o IP da máquina na rede local (ex.: `192.168.1.15`).
2. Execute o app passando o IP:
```bash
flutter run \
  --dart-define=API_BASE_URL=http://192.168.1.15:8000 \
  --dart-define=BACKEND_BASE_URL=http://192.168.1.15:8000
```

---

## 3. Componente de IA/ML (`ia/`)

O módulo `ia/` empacota a biblioteca Python `meu_bebe_ml`. Seu objetivo no escopo do TCC2 é validar o pipeline metodológico e analítico:

1. **Geração Sintética (DGM)**: Geração de 5.000 amostras reproduzíveis (`seed=42`) com base nas 48 variáveis do questionário DSS 1.13 e cálculo do desfecho probabilístico não causal.
2. **Índice de Vulnerabilidade Social (IV-DSS)**: Índice descritivo contínuo $[0, 1]$ calculado em pipeline analítico próprio, ponderando as 6 dimensões.
3. **Modelos Preditivos**: Comparação sistemática entre Regressão Logística, Random Forest e XGBoost sob validação cruzada estratificada. O modelo **Random Forest** foi selecionado com base no PR-AUC médio e congelado.
4. **Agrupamento Não Supervisionado (SOM)**: Redes neurais de mapas auto-organizáveis de Kohonen para identificar perfis de gestantes e correlacionar grupos ao IV-DSS e às estimativas do modelo.

Para detalhes dos scripts de execução e geração de artefatos, consulte [`ia/README.md`](ia/README.md).

---

## 4. Testes Automatizados e Qualidade

O projeto possui ampla cobertura de testes em todas as camadas:

### 4.1 Testes do Aplicativo Flutter
```bash
# Análise estática
flutter analyze

# Execução dos testes unitários, de widgets e de contratos HTTP
flutter test
```

### 4.2 Testes do Backend (FastAPI)
```powershell
cd api
pytest
```

---

## 5. Índice de Documentação

A documentação do repositório foi unificada e organizada por projetos dentro do diretório `docs/`:

- **[Guia Central de Documentação](docs/README.md)** — Hub geral de navegação de todos os projetos e documentos.
- **[Documentação do Aplicativo Mobile](docs/app/README.md)** — Arquitetura Flutter, camada de rede Dio e relatórios de auditoria.
  - **[Integração Mobile ↔ API](docs/app/FLUTTER_API_INTEGRATION.md)** — Arquitetura de consumo HTTP, clientes Dio isolados e proteção de dados.
- **[Documentação da API Backend](docs/api/README.md)** — Manual de arquitetura FastAPI, PostgreSQL, migrations Alembic e autenticação JWT.
  - **[Contrato HTTP DSS v1](docs/api/API_CONTRACT_V1.md)** — Especificação formal do payload DSS 1.13 e endpoint de estimativa.
- **[Documentação do Pacote de ML](docs/ia/README.md)** — Especificação metodológica, DGM, IV-DSS, Random Forest e agrupamento SOM.
  - **[Planejamento do Dataset Sintético](docs/ia/planejamento_dataset_sintetico.md)** — Formulação matemática e parametrização do DGM.
- **[Monografia Acadêmica TCC2](docs/tcc/README.md)** — Guia da monografia, capítulos, matriz bibliográfica e apresentações.
  - **[Texto Completo do TCC2](docs/tcc/tcc2.md)** — Monografia definitiva completa.
