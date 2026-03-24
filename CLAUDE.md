# CLAUDE.md - Developer Guide for the Tempo Agent

This file is for **you** (Claude Code / developer agents) working on this repository.
It is NOT read by the Tempo openclaw agent itself.

## What Is This Repo?

An OpenClaw agent called **Tempo** that autonomously collects, aggregates, and visualizes
AI tool usage analytics from Augment Code, GitHub Copilot, and Claude. It delivers unified
dashboards and reports to the user and hands off analytics to the **Librarian** agent for archival.

## Repo Layout

```
.
├── CLAUDE.md            # You are here (developer guide)
├── README.md            # Public-facing project documentation
├── AGENTS.md            # OpenClaw agent operational framework (read by Tempo)
├── IDENTITY.md          # Agent identity (read by Tempo)
├── SOUL.md              # Agent personality & protocols (read by Tempo)
├── USER.md              # User profile template (read by Tempo)
├── TOOLS.md             # Local environment notes (read by Tempo)
├── HEARTBEAT.md         # Periodic task definitions (read by Tempo)
├── BOOT.md              # Startup tasks (read by Tempo)
├── agent.yaml           # OpenClaw agent configuration
├── .env.example         # Environment variable template
├── backend/             # Elixir/Phoenix API server
│   ├── config/          # Elixir configuration
│   ├── lib/             # Application source
│   ├── test/            # Elixir tests
│   └── mix.exs          # Elixir project definition
├── dashboard/           # Angular 19 analytics UI
│   ├── src/             # Angular components, services, and pages
│   ├── package.json     # Node dependencies
│   └── angular.json     # Angular CLI configuration
├── pipelines/           # Python/Poetry ETL pipelines
│   ├── pyproject.toml   # Poetry project definition
│   ├── src/tempo_pipelines/ # Python package
│   └── tests/           # Pipeline tests
├── tools/               # CLI tooling
│   └── pipeline_runner  # CLI for executing pipelines in CI/CD
├── data/                # Raw and processed data files
│   └── augment_data.json
├── spec/                # Detailed specifications (progressive disclosure)
│   ├── ARCHITECTURE.md  # System design and ADR index
│   ├── PIPELINES.md     # Data pipeline architecture
│   ├── CRON.md          # Scheduled recurring tasks
│   ├── TASK.md          # One-shot task queue
│   ├── TESTING.md       # How to test the agent
│   ├── TROUBLESHOOTING.md  # Common issues and fixes
│   └── LEARNINGS.md     # Lessons learned over time
├── .github/
│   └── workflows/
│       ├── ci.yml       # GitHub Actions CI pipeline
│       └── pipeline.yml # Scheduled data pipeline workflow
├── docker-compose.yml   # Full stack orchestration (backend + dashboard + iamq)
├── Dockerfile           # Multi-stage build (backend + dashboard)
└── LICENSE              # MIT
```

## Two Audiences, Two Sets of Files

| Audience | Files | Purpose |
|----------|-------|---------|
| **Developers / Claude Code** | `CLAUDE.md`, `spec/*`, `tools/`, `Dockerfile`, `docker-compose.yml`, `README.md` | Build, test, improve the agent |
| **Tempo Agent (openclaw)** | `AGENTS.md`, `SOUL.md`, `IDENTITY.md`, `USER.md`, `TOOLS.md`, `HEARTBEAT.md`, `BOOT.md`, `spec/CRON.md`, `spec/TASK.md` | Runtime behavior and memory |

## Environment Variables

All configuration lives in `.env` (never committed). See `.env.example` for the full list.

Key variables:

| Variable | Purpose |
|----------|---------|
| `TEMPO_DATA_DIR` | Where data and reports are written |
| `LIBRARIAN_AGENT_WORKSPACE` | Path to the librarian agent for handoffs |
| `AUGMENT_API_KEY` | Augment Code API key |
| `AUGMENT_API_URL` | Augment Code API endpoint |
| `COPILOT_API_TOKEN` | GitHub Copilot metrics API token |
| `COPILOT_ORG` | GitHub organization for Copilot metrics |
| `CLAUDE_API_KEY` | Claude usage API key |
| `USER_DISPLAY_NAME`, `USER_LOCATION`, etc. | User PII kept out of git |
| `IAMQ_HTTP_URL` | Inter-Agent Message Queue service URL (default `http://127.0.0.1:18790`) |
| `IAMQ_AGENT_ID` | Agent ID in the IAMQ registry (default: `tempo_agent`) |
| `IAMQ_QUEUE_PATH` | Path to IAMQ file-based queue directory (fallback) |

## Docker Commands

```bash
# Start the full stack (backend + dashboard)
docker compose up -d

# Start backend only
docker compose up -d backend

# Run Elixir tests
docker compose exec backend mix test

# Run Python pipeline tests
cd pipelines && poetry run pytest

# Trigger a data refresh
docker compose exec backend mix tempo.refresh

# Run dashboard dev server
cd dashboard && npm install && npm start

# View backend logs
docker compose logs -f backend
```

## Inter-Agent Message Queue (IAMQ)

Tempo registers as `tempo_agent` on the IAMQ at `$IAMQ_HTTP_URL`.

```bash
# Check Tempo's inbox
curl http://127.0.0.1:18790/inbox/tempo_agent?status=unread

# List online agents
curl http://127.0.0.1:18790/agents

# Send a message
curl -X POST http://127.0.0.1:18790/send \
  -H "Content-Type: application/json" \
  -d '{"from":"tempo_agent","to":"librarian_agent","type":"request","priority":"NORMAL","subject":"...","body":"..."}'
```

## Backend (Elixir/Phoenix)

- Location: `backend/`
- Purpose: API server, data aggregation, agent logic
- Run: `cd backend && mix deps.get && mix phx.server`
- Test: `cd backend && mix test`
- Format: `cd backend && mix format`

## Dashboard (Angular 19)

- Location: `dashboard/`
- Purpose: Analytics visualization UI (standalone components, Chart.js via ng2-charts)
- Run: `cd dashboard && npm install && npm start`
- Test: `cd dashboard && npm test`
- Build: `cd dashboard && npm run build`
- Proxy: `/api` requests are proxied to `http://localhost:4000` via `proxy.conf.json`

## Pipelines (Python/Poetry)

- Location: `pipelines/`
- Purpose: Data ingestion, transformation, ETL from AI tool APIs
- Setup: `cd pipelines && poetry install`
- Run: `cd pipelines && poetry run python -m tempo_pipelines`
- Test: `cd pipelines && poetry run pytest`
- Lint: `cd pipelines && poetry run ruff check .`
- Format: `cd pipelines && poetry run ruff format .`

## Testing & CI

GitHub Actions runs on every push and PR:
- **ci.yml**: Elixir compile+format+test, Angular build, Python lint (ruff) + test (pytest)
- **pipeline.yml**: Scheduled daily data pipeline execution via `tools/pipeline_runner`

## Progressive Disclosure

Don't read everything upfront. Load context on demand from `spec/`:

| When you need | Read |
|---------------|------|
| System design, supervision tree, data flow | `spec/ARCHITECTURE.md` |
| Pipeline details, scheduling, Augment API endpoints | `spec/PIPELINES.md` |
| Phoenix API routes and response shapes | `spec/API.md` |
| Agent-to-agent IAMQ messaging | `spec/COMMUNICATION.md` |
| Security, privacy, rate limits | `spec/SAFETY.md` |
| How to run and write tests | `spec/TESTING.md` |
| Something is broken | `spec/TROUBLESHOOTING.md` |
| Past decisions and context | `spec/LEARNINGS.md` |

## Sensitive Data Policy

- **NEVER** commit `.env`, credentials, API keys, or PII
- **NEVER** commit individual usage data — only aggregated/anonymized metrics
- User profile data is referenced via `$USER_DISPLAY_NAME` etc. in templates
- The `.gitignore` excludes: `.env`, `data/`, `memory/`, `.openclaw/`
- Before committing, run: `git diff --cached` and check for secrets
- CI will block merges if secrets or hardcoded paths are detected

## Conventions

- Elixir: Follow standard mix format, use doctests
- Angular: Standalone components, Angular style guide, TypeScript strict mode
- Python: PEP 8 via ruff, type hints required, Poetry for deps
- All code must have tests
- Use environment variables for secrets (never commit them)

## Zero Install

Use `docker compose up` to run the entire stack without local dependencies.

## Contributing

1. Read this file and `spec/ARCHITECTURE.md`
2. Copy `.env.example` to `.env` and configure
3. Use `docker compose` for all service execution
4. Run tests before committing
5. Keep the Tempo agent autonomous — it makes its own decisions
6. Document learnings in `spec/LEARNINGS.md`
