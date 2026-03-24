# ARCHITECTURE.md - System Design

## Overview

The Tempo agent is an AI tool analytics platform that aggregates usage data from
Augment Code, GitHub Copilot, and Claude. It consists of three layers:

```
Data Sources -> Pipelines (Python/Poetry) -> data/ JSON files
                                               |
                                               v
                Backend (Elixir/Phoenix) -> Dashboard (Angular 19)
                    |
                    +-> IAMQ (inter-agent messaging)
```

## Backend (Elixir/Phoenix)

**Location:** `backend/`
**Port:** 4000

The backend is an OTP application with the following supervision tree:

| Component | Module | Purpose |
|-----------|--------|---------|
| Application | `Tempo.Application` | OTP supervisor, starts all children |
| DataStore | `Tempo.DataStore` | GenServer managing JSON data files in `data/` |
| MqClient | `Tempo.MqClient` | IAMQ HTTP client (registration, heartbeat, inbox polling, sending) |
| MqWsClient | `Tempo.MqWsClient` | IAMQ WebSocket client for real-time push |
| Analytics | `Tempo.Analytics` | User stats and daily aggregate computation |
| Augment Client | `Tempo.Sources.Augment` | Augment Code Analytics API client |
| Phoenix Endpoint | `TempoWeb.Endpoint` | HTTP API on port 4000 |
| Router | `TempoWeb.Router` | API routing under `/api/v1/` |

### Data Storage

Usage data is stored as JSON files in the `data/` directory, ingested by Python pipelines:

```
data/
  augment_data.json     # Augment Code usage records (credits, DAU, user activity)
  copilot/              # GitHub Copilot metrics (future)
  claude/               # Claude usage data (future)
  processed/            # Normalized, unified metrics
  reports/              # Generated analytics reports
```

The `Tempo.DataStore` GenServer loads these files into memory on startup and provides
read/aggregate functions to the API layer via `Tempo.Analytics`.

## Dashboard (Angular 19)

**Location:** `dashboard/`
**Dev port:** 4200

Built with:

- Angular 19 (standalone components)
- TypeScript (strict mode)
- Chart.js via ng2-charts

### Key Components

| Component | File | Purpose |
|-----------|------|---------|
| StatCard | `src/app/components/stat-card/stat-card.component.ts` | Summary metric cards |
| UsageChart | `src/app/components/usage-chart/usage-chart.component.ts` | Time-series line/bar chart with toggle |
| UserTable | `src/app/components/user-table/user-table.component.ts` | Sortable tabular user activity data |
| TopUsersChart | `src/app/components/top-users-chart/top-users-chart.component.ts` | Horizontal bar chart of top users |
| DashboardPage | `src/app/pages/dashboard/dashboard.component.ts` | Main page with source selector |
| AnalyticsService | `src/app/services/analytics.service.ts` | HTTP client for the Phoenix API |

The dashboard fetches data from the Phoenix API at `/api/v1/analytics/{source}/...`.
In dev mode, `proxy.conf.json` routes `/api` requests to `http://localhost:4000`.

## Pipelines (Python/Poetry)

**Location:** `pipelines/`

Data ingestion layer. Each pipeline fetches data from an AI tool API, normalizes
it, and writes JSON to the `data/` directory.

| Pipeline | Source | Status |
|----------|--------|--------|
| Augment Code | `tempo_pipelines.sources.augment` | Implemented |
| GitHub Copilot | (planned) | Planned |
| Claude | (planned) | Planned |

Run via CLI: `./tools/pipeline_runner --pipeline augment --output data/`
Scheduled via GitHub Actions: `.github/workflows/pipeline.yml` (daily at 03:00 UTC).

## Data Flow

```
[Augment Code API]  --+
[GitHub Copilot API] -+--> [Python Pipelines] --> [data/*.json]
[Claude API]         --+                              |
                                                      v
                                            [DataStore GenServer]
                                                      |
                                            [Phoenix API /api/v1/]
                                             /                \
                                   [Angular Dashboard]    [IAMQ Broadcast]
```

## IAMQ Integration

The agent registers as `tempo_agent` with the Inter-Agent Message Queue on startup.

- **MqClient** handles HTTP-based registration, heartbeat, inbox polling, and message sending.
- **MqWsClient** maintains a WebSocket connection for real-time message delivery.
- On IAMQ failure, the agent logs the error and continues operating. IAMQ is non-critical.

See `spec/COMMUNICATION.md` for message formats and capabilities.

## Related

- API endpoints: [API.md](API.md)
- Testing: [TESTING.md](TESTING.md)
- Communication: [COMMUNICATION.md](COMMUNICATION.md)
- Troubleshooting: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---
*Owner: tempo_agent*
