<p align="center">
  <img src="assets/banner.svg" alt="openclaw-ai-tempo-agent" width="600">
</p>

# Openclaw AI Tempo Agent

Tempo is an autonomous Openclaw agent that connects multiple AI tool data sources to provide comprehensive, fine-grained usage analytics. It collects, aggregates, and visualizes data from Augment Code, GitHub Copilot, and Claude into unified dashboards and reports, then hands off analytics to the Librarian agent for archival.

## Features

- Collects usage data from Augment Code (credits, DAU, model/token usage, editor/language breakdown)
- GitHub Copilot and Claude usage support (planned)
- Phoenix/Elixir backend API with Angular 19 dashboard
- Daily data pipelines via GitHub Actions
- Registers as `tempo_agent` on IAMQ for inter-agent messaging

## Skills

| Skill | Description |
|-------|-------------|
| `usage_metrics_collect` | Triggers a data collection run and reports aggregated metrics to IAMQ |

Skills are stored in `skills/` and auto-improve via post-execution hooks and nightly batch processing. Workspace-level skills (`iamq_message_send`, `log_learning`, `improve_skill`) are available via the shared `../skills` volume.

## Architecture

- **Language**: Elixir/Phoenix (backend), Angular 19 (dashboard), Python/Poetry (pipelines)
- **IAMQ ID**: `tempo_agent`
- **Runtime**: Docker
- **Ports**: `4001` (API), `4200` (dashboard)

| Component | Technology | Port |
|-----------|-----------|------|
| Backend API | Elixir / Phoenix | 4001 |
| Dashboard | Angular 19 | 4200 |
| Data Pipelines | Python / Poetry | — |

## Setup

```bash
cp .env.example .env
# Edit .env with your API tokens
docker compose up
```

## Volume Mounts

| Mount | Purpose |
|-------|---------|
| `../skills-cli:/skills-cli:ro` | Shared skills CLI tooling |
| `../skills:/workspace/skills:rw` | Workspace-level shared skills |
| `./skills:/agent/skills:rw` | Agent-specific skills |

`EMBEDDINGS_URL=http://host.docker.internal:18795` is set automatically for semantic search.

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/v1/health` | Service health check |
| `GET /api/v1/analytics/sources` | List available data sources |
| `GET /api/v1/analytics/:source/summary` | High-level metrics |
| `GET /api/v1/analytics/:source/users` | Per-user statistics |
| `GET /api/v1/analytics/:source/daily` | Daily aggregates |

## Links

- [openclaw-inter-agent-message-queue](https://github.com/r3dlex/openclaw-inter-agent-message-queue) — IAMQ backbone
- [openclaw-main-agent](https://github.com/r3dlex/openclaw-main-agent) — Cross-agent orchestrator

## License

MIT — Copyright 2026 Redlex Gilgamesh
