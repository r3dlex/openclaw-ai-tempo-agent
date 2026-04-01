<p align="center">
  <img src="assets/banner.svg" alt="openclaw-ai-tempo-agent" width="600">
</p>

# Openclaw AI Tempo Agent

Tempo is an autonomous Openclaw agent that connects multiple AI tool data sources to provide comprehensive, fine-grained usage analytics. It collects, aggregates, and visualizes data from Augment Code, GitHub Copilot, and Claude into unified dashboards and reports.

## Supported Data Sources

| Source | Data Collected | Status |
|--------|---------------|--------|
| **Augment Code** | Credits, DAU, user activity, model/token usage, editor/language breakdown | Active |
| **GitHub Copilot** | Completions, chat usage, lines suggested/accepted, seat management | Planned |
| **Claude** | Conversations, tokens, model usage | Planned |

## Architecture

| Component | Technology | Location | Port |
|-----------|-----------|----------|------|
| Backend API | Elixir / Phoenix | `backend/` | 4000 |
| Dashboard | Angular 19 | `dashboard/` | 4200 |
| Data Pipelines | Python / Poetry | `pipelines/` | -- |
| Pipeline Runner | Shell CLI | `tools/pipeline_runner` | -- |
| IAMQ Client | Elixir (built into backend) | `backend/lib/tempo/mq_*.ex` | -- |

## Quick Start (Zero Install)

```bash
cp .env.example .env
# Edit .env with your API tokens
docker compose up
```

This starts:
- Backend API at `http://localhost:4000`
- Dashboard at `http://localhost:4200`
- IAMQ sidecar for inter-agent messaging

## Development Setup

### Backend (Elixir)

```bash
cd backend
mix deps.get
mix phx.server
```

### Dashboard (Angular)

```bash
cd dashboard
npm install
npm start
```

### Pipelines (Python)

```bash
cd pipelines
poetry install
poetry run tempo-pipeline run --pipeline augment --output ../data/
```

## Data Pipelines

Pipelines ingest data from AI tool APIs and write normalized JSON to `data/`. Run via GitHub Actions (daily at 03:00 UTC) or locally:

```bash
./tools/pipeline_runner --pipeline augment --output data/
```

## API Endpoints

All under `/api/v1/`:

| Endpoint | Description |
|----------|-------------|
| `GET /api/v1/health` | Service health check |
| `GET /api/v1/analytics/sources` | List available data sources |
| `GET /api/v1/analytics/:source/summary` | High-level metrics |
| `GET /api/v1/analytics/:source/users` | Per-user statistics |
| `GET /api/v1/analytics/:source/daily` | Daily aggregates |
| `GET /api/v1/analytics/:source/raw` | Raw data (first 100 records) |

## Inter-Agent Messaging (IAMQ)

Tempo registers as `tempo_agent` on the Openclaw Inter-Agent Message Queue. The backend handles registration, heartbeats, inbox polling (HTTP), and real-time push (WebSocket) automatically.

## CI/CD

- **ci.yml** -- Runs on push/PR: Elixir compile+format+test, Angular build, Python lint+test
- **pipeline.yml** -- Scheduled daily data pipeline with auto-commit of results

## Project Documentation

| File | Audience | Purpose |
|------|----------|---------|
| `CLAUDE.md` | Developers / Claude Code | Build, test, improve the agent |
| `AGENTS.md` | Tempo Agent (runtime) | Operational framework |
| `SOUL.md` | Tempo Agent (runtime) | Personality and protocols |
| `spec/` | Both | Architecture, API, pipelines, testing, safety |

## License

MIT -- Copyright 2026 Redlex Gilgamesh
