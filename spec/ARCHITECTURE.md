# ARCHITECTURE.md - System Design

## Overview

The Tempo agent is an AI tool analytics platform that aggregates usage data from
Augment Code, GitHub Copilot, and Claude. It consists of an Elixir/Phoenix backend
and a React/Vite dashboard for visualization.

```
Data Sources -> Backend (Elixir/Phoenix) -> Dashboard (React/Vite)
                    |
                    +-> IAMQ (inter-agent messaging)
```

## Backend (Elixir/Phoenix)

**Location:** `backend/`
**Port:** 4000

The backend is an OTP application with the following supervision tree:

| Component | Module | Purpose |
|-----------|--------|---------|
| Application | `TempoAgent.Application` | OTP supervisor, starts all children |
| DataStore | `TempoAgent.DataStore` | GenServer managing JSON data files in `data/` |
| MqClient | `TempoAgent.MqClient` | IAMQ HTTP client (registration, heartbeat, polling) |
| MqWsClient | `TempoAgent.MqWsClient` | IAMQ WebSocket client for real-time push |
| Phoenix Endpoint | `TempoAgentWeb.Endpoint` | HTTP API on port 4000 |

### Data Storage

Usage data is stored as JSON files in the `data/` directory:

```
data/
  augment_usage.json    # Augment Code usage records
  copilot_usage.json    # GitHub Copilot usage records
  claude_usage.json     # Claude usage records
  users.json            # User activity index
```

The `DataStore` GenServer loads these files into memory on startup and provides
read/aggregate functions to the API layer.

## Dashboard (React/Vite)

**Location:** `dashboard/`
**Dev port:** 5173

Built with:

- React 18 + TypeScript
- Vite (build tooling)
- Recharts (chart library)

### Key Components

| Component | File | Purpose |
|-----------|------|---------|
| StatCard | `src/components/StatCard.tsx` | Summary metric cards |
| UsageChart | `src/components/UsageChart.tsx` | Time-series usage chart |
| UserTable | `src/components/UserTable.tsx` | Tabular user activity data |
| TopUsersChart | `src/components/TopUsersChart.tsx` | Bar chart of top users by usage |

The dashboard fetches data from the Phoenix API at `/api/analytics` and `/api/users`.

## Data Flow

```
[Augment Code API]  --+
[GitHub Copilot API] -+--> [DataStore GenServer] --> [Phoenix API] --> [React Dashboard]
[Claude API]         --+          |
                                  +---> [IAMQ Broadcast]
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
