# PIPELINES.md - Data & CI Pipelines

## Overview

Pipelines for the Tempo agent handle data ingestion (Python/Poetry) and continuous integration (GitHub Actions).

## Data Ingestion Pipelines

**Location:** `pipelines/`
**Framework:** Python 3.12 + Poetry
**CLI:** `tempo-pipeline` (installed via `poetry install`)

| Pipeline | Source | Schedule | Status |
|----------|--------|----------|--------|
| Augment Code | Augment Analytics API | Daily 03:00 UTC | **Implemented** |
| GitHub Copilot | GitHub Copilot Metrics API | Daily | Planned |
| Claude | Anthropic Usage API | Daily | Planned |

### Running Pipelines

```bash
# Via pipeline_runner tool (used in CI/CD)
./tools/pipeline_runner --pipeline augment --output data/

# Via Poetry directly
cd pipelines && poetry run tempo-pipeline run --pipeline augment --output ../data/

# List available pipelines
./tools/pipeline_runner --list
```

### Pipeline Architecture

Each pipeline:
1. Authenticates with the source API (token from `.env`)
2. Fetches data with rate-limit-aware retry logic
3. Writes normalized JSON to `data/`
4. Returns a `PipelineResult` with success/failure status and record count

> For the full Python module structure, see `pipelines/src/tempo_pipelines/`.

### Augment Code Pipeline

Connects to the Augment Analytics API (enterprise-only). Endpoints used:

| Endpoint | Data |
|----------|------|
| `GET /analytics/v0/dau-count` | Daily active user counts (max 90 days) |
| `GET /analytics/v0/dau` | Active users for a specific date |
| `GET /analytics/v0/daily-usage` | Org usage metrics (lines, messages, completions) |
| `GET /analytics/v0/user-activity` | Per-user metrics with pagination |
| `GET /analytics/v0/daily-user-activity-by-editor-language` | Breakdown by editor and language |

Rate limit: 10 req/min with 20-request burst. Client implements exponential backoff.

## Continuous Integration

**Workflow:** `.github/workflows/ci.yml`

| Job | Language | What it runs |
|-----|----------|-------------|
| `backend` | Elixir | `mix deps.get`, `mix compile --warnings-as-errors`, `mix format --check-formatted`, `mix test` |
| `dashboard` | Angular | `npm ci`, `npm run build` |
| `pipelines` | Python | `poetry install`, `ruff check`, `ruff format --check`, `pytest` |

### Scheduled Pipeline Workflow

**Workflow:** `.github/workflows/pipeline.yml`

Runs daily at 03:00 UTC via `tools/pipeline_runner`. Also supports manual dispatch.
On success, commits updated data files to `data/`.

### Running CI Locally

```bash
# Backend
cd backend && mix deps.get && mix compile --warnings-as-errors && mix format --check-formatted && mix test

# Dashboard
cd dashboard && npm ci && npm run build

# Pipelines
cd pipelines && poetry install && poetry run ruff check . && poetry run pytest
```

## Related

- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Testing: [TESTING.md](TESTING.md)
- CI workflow: `../.github/workflows/ci.yml`
- Pipeline workflow: `../.github/workflows/pipeline.yml`

---
*Owner: tempo_agent*
