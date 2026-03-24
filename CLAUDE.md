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
├── dashboard/           # React/Vite analytics UI
│   ├── src/             # React components and pages
│   ├── package.json     # Node dependencies
│   └── vite.config.ts   # Vite configuration
├── pipelines/           # Python/Poetry ETL pipelines
│   ├── pyproject.toml   # Poetry project definition
│   └── tempo_pipelines/ # Python package
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
│       └── ci.yml       # GitHub Actions CI pipeline
├── docker-compose.yml   # Full stack orchestration
├── Dockerfile           # Zero-install container
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
cd dashboard && npm install && npm run dev

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

## Dashboard (React/Vite)

- Location: `dashboard/`
- Purpose: Analytics visualization UI
- Run: `cd dashboard && npm install && npm run dev`
- Test: `cd dashboard && npm test`
- Build: `cd dashboard && npm run build`

## Pipelines (Python/Poetry)

- Location: `pipelines/`
- Purpose: Data ingestion, transformation, ETL from AI tool APIs
- Setup: `cd pipelines && poetry install`
- Run: `cd pipelines && poetry run python -m tempo_pipelines`
- Test: `cd pipelines && poetry run pytest`
- Lint: `cd pipelines && poetry run ruff check .`
- Format: `cd pipelines && poetry run ruff format .`

## Testing & CI

GitHub Actions (`.github/workflows/ci.yml`) runs on every push and PR:
- Elixir compile + tests
- Python lint (ruff) + tests (pytest)
- Dashboard build validation
- Docker build validation
- Secrets scan (blocks if hardcoded secrets or local paths found)

## Progressive Disclosure

For deeper topics, see `spec/`:
- **Architecture & ADRs**: `spec/ARCHITECTURE.md`
- **Data pipelines**: `spec/PIPELINES.md`
- **Scheduled tasks**: `spec/CRON.md`
- **One-shot tasks**: `spec/TASK.md`
- **Testing**: `spec/TESTING.md`
- **Troubleshooting**: `spec/TROUBLESHOOTING.md`
- **Lessons learned**: `spec/LEARNINGS.md`

## Sensitive Data Policy

- **NEVER** commit `.env`, credentials, API keys, or PII
- **NEVER** commit individual usage data — only aggregated/anonymized metrics
- User profile data is referenced via `$USER_DISPLAY_NAME` etc. in templates
- The `.gitignore` excludes: `.env`, `data/`, `memory/`, `.openclaw/`
- Before committing, run: `git diff --cached` and check for secrets
- CI will block merges if secrets or hardcoded paths are detected

## Conventions

- Elixir: Follow standard mix format, use doctests
- React: Functional components, hooks, TypeScript
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
