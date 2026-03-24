# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics.

## Services

| Service | URL | Purpose |
|---------|-----|---------|
| Backend API | `http://localhost:4000` | Elixir/Phoenix data aggregation and API |
| Dashboard | `http://localhost:4200` | Angular 19 analytics visualization |
| IAMQ HTTP | `$IAMQ_HTTP_URL` (default `http://127.0.0.1:18790`) | Inter-agent messaging (HTTP) |
| IAMQ WS | `$IAMQ_WS_URL` (default `ws://127.0.0.1:18793/ws`) | Inter-agent messaging (WebSocket) |

## Data Sources

| Source | Type | Config |
|--------|------|--------|
| Augment Code | REST API | `AUGMENT_API_TOKEN`, `AUGMENT_API_URL` in `.env` |
| GitHub Copilot | REST API | `COPILOT_API_TOKEN`, `COPILOT_ORG` in `.env` |
| Claude | REST API | `CLAUDE_API_KEY` in `.env` |
| Local files | JSON/CSV | `data/` directory |

## Data Directory

```
data/
├── augment_data.json      # Raw Augment Code usage data
├── copilot/               # Raw Copilot metrics
├── claude/                # Raw Claude usage data
├── processed/             # Normalized, unified metrics
├── reports/               # Generated analytics reports
└── log/                   # Processing logs
```

## Inter-Agent Message Queue (IAMQ)

The IAMQ service at `$IAMQ_HTTP_URL` (default `http://127.0.0.1:18790`) connects
all OpenClaw agents. The backend auto-registers on startup and sends heartbeats
every 2 minutes. Data refresh completions are announced to the queue.

```bash
# Check your inbox
curl http://127.0.0.1:18790/inbox/tempo_agent?status=unread

# List online agents
curl http://127.0.0.1:18790/agents

# Send a message to another agent
curl -X POST http://127.0.0.1:18790/send \
  -H "Content-Type: application/json" \
  -d '{"from":"tempo_agent","to":"librarian_agent","type":"request","priority":"NORMAL","subject":"...","body":"..."}'
```

## Docker Commands

```bash
# Start all services (backend + dashboard + iamq sidecar)
docker compose up -d

# Start backend only
docker compose up -d backend

# Run backend tests
cd backend && mix test

# Run Python pipeline tests
cd pipelines && poetry run pytest

# Run data pipeline
./tools/pipeline_runner --pipeline augment --output data/

# Run dashboard dev server
cd dashboard && npm install && npm start

# View logs
docker compose logs -f backend
```

## Environment-Specific Notes

_(Add local setup details here: custom API endpoints, rate limits, preferred report formats, etc.)_

---

Keep shared skills and local setup separate. This is your cheat sheet.

> For deeper details:
> - System design: `spec/ARCHITECTURE.md`
> - Data pipelines: `spec/PIPELINES.md`
> - API endpoints: `spec/API.md`
> - Troubleshooting: `spec/TROUBLESHOOTING.md`
