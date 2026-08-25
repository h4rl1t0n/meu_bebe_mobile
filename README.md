# Meu Bebê — Aplicativo Mobile

Aplicativo móvel (Flutter) que integra, em uma mesma solução:

1. **Questionário dos Determinantes Sociais da Saúde (DSS)** — coleta
   estruturada de seis dimensões (educação, trabalho e renda, saneamento,
   acesso aos serviços de saúde, habitação e alimentação);
2. **Módulo de acompanhamento do pré-natal** — registro local (SQLite) de dados
   da gestante, gestação, consultas, exames, medicamentos, vacinas e plano de
   parto;
3. **Estimativa experimental (DSS)** — estimativa estatística experimental de
   descontinuidade do acompanhamento pré-natal, via API FastAPI + modelo de
   aprendizado de máquina (dados sintéticos/experimentais).

> ⚠️ **Disclaimer:** a estimativa produzida é **estatística e experimental** —
> **não** é diagnóstico médico nem certeza de abandono. Não há classificação de
> baixo/médio/alto risco. Os dados são sintéticos e servem apenas para validação
> técnica da metodologia. Ver `docs/tcc2.md`.

---

## Estrutura do repositório

```
meu_bebe_mobile/
├── lib/                 # Aplicativo Flutter (Dart)
│   └── app/
│       ├── core/        # Config, REST clients, interceptors, tema, helpers
│       ├── database/    # Banco local SQLite (sqflite)
│       ├── model/       # Entidades (gestante, usuário, consulta, etc.)
│       ├── repositories/# Acesso a dados (locais SQLite + HTTP DSS/login)
│       ├── services/    # Serviços (login)
│       └── modules/     # Módulos flutter_modular (login, formulário, main)
├── api/                 # Backend FastAPI (estimativa experimental DSS)
├── ia/                  # Pacote Python de ML (meu-bebe-ml)
├── docs/                # Documentação acadêmica (TCC2, planejamento)
├── test/                # Testes Flutter
└── android/ ios/        # Plataformas
```

---

## Pré-requisitos

- **Flutter** (Dart) — ver `pubspec.yaml` para a versão do SDK.
- **Python 3.14** (recomendado) para `api/` e `ia/`.
- **Android** (dispositivo físico ou emulador) para execução do app.

> O projeto atualmente possui somente os diretórios de plataforma `android/` e
> `ios/`. **Não há projeto Windows desktop configurado** (confirmado na Fase 5D:
> "No Windows desktop project configured"). A execução validada desta aplicação
> foi no **Android Emulator**.

---

## 1. Como executar a API (FastAPI)

A API está em `api/`. Instalação e execução (PowerShell/Windows):

```powershell
# a partir da raiz do repositório
cd api

# 1) criar e ativar o ambiente virtual (Python 3.14)
py -3.14 -m venv .venv
.\.venv\Scripts\Activate.ps1

# 2) instalar a API (dev) e o pacote de IA (editable)
pip install -e ".[dev]"
pip install -e ..\ia

# 3) executar (comando validado na Fase 5D)
python -m uvicorn meu_bebe_api.main:app --host 127.0.0.1 --port 8000
```

> `uvicorn meu_bebe_api.main:app --reload` pode ser usado **opcionalmente** em
> desenvolvimento (recarrega ao salvar), mas o comando principal validado é o
> acima (`python -m uvicorn ... --host 127.0.0.1 --port 8000`).

> Em outros sistemas (Linux/macOS), use `python3 -m venv .venv` e
> `source .venv/bin/activate` no lugar das duas linhas equivalentes acima.

Endpoints principais:

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET`  | `/health` | Status do serviço |
| `GET`  | `/ready`  | Disponibilidade do modelo |
| `POST` | `/api/v1/risk-estimate` | Estimativa experimental (DSS) |

A documentação interativa (Swagger) fica em `/docs`.

> Detalhes adicionais em `api/README.md`.

---

## 2. Como executar o aplicativo Flutter

```bash
# instalar dependências (na raiz do projeto Flutter)
flutter pub get

# listar os dispositivos disponíveis
flutter devices

# executar (define a URL da API DSS via --dart-define)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

**Configuração das URLs (via `--dart-define`):**

| Variável | Uso |
|----------|-----|
| `API_BASE_URL` | FastAPI atual do DSS (estimativa experimental de descontinuidade do pré-natal) |
| `BACKEND_BASE_URL` | Backend legado/separado utilizado pelo fluxo de login existente |

**Não há fallback entre `API_BASE_URL` e `BACKEND_BASE_URL`** — são destinos HTTP
independentes.

**Emulador Android (execução validada):**

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

> `emulator-5554` foi o **ID do dispositivo naquela execução** — **não é fixo**.
> Consulte o ID real com `flutter devices` e substitua. `10.0.2.2` é o alias do
> emulador Android para alcançar o host.

`127.0.0.1` é usado quando o cliente e a API rodam no **mesmo host**, mas a
execução validada desta aplicação foi **Android Emulator → `10.0.2.2`**.

> **API desligada** não trava o app — exibe mensagem amigável e permite retry.

---

## 3. Testes e análise estática

```bash
flutter analyze
flutter test
```

---

## 4. Banco local (offline) e direção futura

**HOJE:** o SQLite local (`sqflite`, arquivo `meu_bebe.db`, versão 1) é a
**fonte principal** do gerenciamento do pré-natal; não depende da API.

**VERSÃO FUTURA COM API:** a API/servidor passa a ser a **fonte principal**; a
migração pode ser **incremental por feature**. Persistência offline/sincronização
fica para **atualização futura** — **não** é implementada nesta versão.

Ver `lib/app/database/database.dart` e o relatório `FASE_6A_REPORT.md` para o
mapa do domínio e a modelagem conceitual do backend.

---

## 5. Documentação

- `docs/tcc2.md` — documento acadêmico principal (metodologia).
- `docs/planejamento_dataset_sintetico.md` — planejamento do dataset sintético.
- `api/API_CONTRACT_V1.md` — contrato da API.
- `FLUTTER_API_INTEGRATION.md` — integração Flutter ↔ API.
- `FASE_*.md` — relatórios das fases do projeto.
