# PIPELINES.md - CI & Data Pipelines

## Overview

Pipelines for the Tempo agent cover continuous integration and (future) data ingestion.

## Continuous Integration

**Workflow:** `.github/workflows/ci.yml`

CI runs on every push and pull request to `main`.

| Job | What it runs |
|-----|-------------|
| `elixir` | `mix deps.get`, `mix compile --warnings-as-errors`, `mix test` |
| `dashboard` | `npm ci`, `npm run build` |

### Running CI locally

```bash
# Backend
cd backend && mix deps.get && mix compile --warnings-as-errors && mix test

# Dashboard
cd dashboard && npm ci && npm run build
```

## Future: Data Ingestion Pipelines

Planned pipelines for automated data collection:

| Pipeline | Source | Schedule | Status |
|----------|--------|----------|--------|
| Augment Code ingestion | Augment API | Daily | Planned |
| GitHub Copilot ingestion | GitHub API | Daily | Planned |
| Claude usage ingestion | Anthropic API | Daily | Planned |
| Aggregation | Local JSON files | On-demand | Planned |

These pipelines will fetch usage data from each source, normalize the format,
and write to the `data/` directory for the DataStore GenServer to pick up.

## Lint

### Backend (Elixir)

```bash
cd backend && mix compile --warnings-as-errors
```

### Dashboard (TypeScript)

```bash
cd dashboard && npm run lint    # If configured
cd dashboard && npm run build   # Type checking via tsc
```

## Related

- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Testing: [TESTING.md](TESTING.md)
- CI workflow: `../.github/workflows/ci.yml`

---
*Owner: tempo_agent*
