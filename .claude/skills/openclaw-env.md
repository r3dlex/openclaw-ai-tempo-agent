# OpenClaw Environment — Claude Code Skill

This skill gives Claude Code full context about the OpenClaw multi-agent ecosystem,
the Inter-Agent Message Queue (IAMQ) API, communication protocols, cron scheduling,
and development conventions. Read this before working on any OpenClaw agent repo.

---

## Ecosystem Overview

OpenClaw is a system of **14 autonomous agents** that communicate via IAMQ:

| Agent ID | Repo | Purpose |
|---|---|---|
| `mq_agent` | `openclaw-inter-agent-message-queue` | Central message bus + cron scheduler |
| `agent_claude` | `openclaw-agent-claude` | Claude AI assistant, executes tasks via Claude API |
| `tempo_agent` | `openclaw-ai-tempo-agent` | AI tool usage analytics (Augment, Copilot, Claude) |
| `gitrepo_agent` | `openclaw-gitrepo-agent` | Monitors git repos for activity, stale PRs, stats |
| `health_fitness_agent` | `openclaw-health-fitness` | Imports step/sleep data, generates fitness reports |
| `instagram_agent` | `openclaw-instagram-agent` | Instagram engagement automation |
| `journalist_agent` | `openclaw-journalist-agent` | News briefings and digests from RSS/web sources |
| `librarian_agent` | `openclaw-librarian-agent` | Indexes and organizes Obsidian vault + Atlassian |
| `mail_agent` | `openclaw-mail-agent` | Email tidy, digest, calendar via Himalaya/DavMail |
| `main` | `openclaw-main-agent` | Cross-agent pipeline orchestration |
| `podcast_agent` | `openclaw-podcast-agent` | Monitors RSS feeds, downloads new episodes |
| `sysadmin_agent` | `openclaw-sysadmin-agent` | Security audits, health checks, system monitoring |
| `workday_agent` | `openclaw-workday-agent` | Workday HR automation via browser (timesheet, tasks) |
| `herr_freud_agent` | `openclaw-herr-freud-agent` | Psychology/therapy session assistant |

All agents are **standalone repos** — independently deployable, no shared runtime.

---

## IAMQ HTTP API Reference

**Base URL:** `http://127.0.0.1:18790` (configurable via `IAMQ_HTTP_URL`)

### Agent Lifecycle

```
POST /register
Body: { "agent_id": "mail_agent", "description": "...", "capabilities": ["email"], "avatar": "📬" }
Response 200: { "status": "registered", "agent_id": "mail_agent" }

POST /heartbeat
Body: { "agent_id": "mail_agent" }
Response 200: { "status": "ok" }

GET /agents
Response 200: { "agents": [{ "id": "mail_agent", "description": "...", "last_seen": "ISO8601" }] }

GET /agents/:agent_id
Response 200: { "id": "mail_agent", "description": "...", "capabilities": [...], "last_seen": "..." }

PUT /agents/:agent_id
Body: { "description": "updated", "capabilities": ["email", "calendar"] }
Response 200: updated agent map

GET /status
Response 200: { "checkedAt": "ISO8601", "queues": {...}, "agents_online": [...] }
```

### Messaging

```
POST /send
Body: {
  "from": "mail_agent",
  "to": "librarian_agent",          -- or "broadcast" for all agents
  "subject": "archive_complete",
  "body": { "count": 42 },          -- string or object
  "priority": "normal",             -- "low" | "normal" | "high"
  "expires_in_seconds": 3600        -- optional TTL
}
Response 201: full message map

GET /inbox/:agent_id
Query: ?status=pending              -- optional filter: pending|read|acted|archived
Response 200: { "messages": [...] }

PATCH /messages/:id
Body: { "status": "read" }          -- or "acted" | "archived"
Response 200: { "status": "updated" }
```

### Push Delivery (Callbacks)

```
POST /callback
Body: { "agent_id": "mail_agent", "url": "http://localhost:9001/iamq" }
Response 200: { "status": "callback_registered" }

DELETE /callback
Body: { "agent_id": "mail_agent" }
Response 200: { "status": "callback_removed" }
```

### Cron Scheduling

```
POST /crons
Body: {
  "agent_id": "mail_agent",
  "name": "tidy_inbox",             -- used in subject: "cron::tidy_inbox"
  "expression": "30 6 * * *",       -- 5-field cron (UTC)
  "enabled": true
}
Response 201: { "id": "uuid", "agent_id": "mail_agent", "name": "tidy_inbox", ... }

GET /crons?agent_id=mail_agent      -- list (filter optional)
Response 200: { "crons": [...] }

GET /crons/:id
Response 200: cron entry map | 404

PATCH /crons/:id
Body: { "enabled": false }
Response 200: updated cron entry | 404

DELETE /crons/:id
Response 200: { "status": "deleted" } | 404
```

---

## IAMQ WebSocket API

**URL:** `ws://127.0.0.1:18793/ws` (configurable via `IAMQ_WS_URL`)

Connect and send JSON frames:

```json
{ "action": "register", "agent_id": "mail_agent", "description": "..." }
{ "action": "heartbeat", "agent_id": "mail_agent" }
{ "action": "send", "from": "...", "to": "...", "subject": "...", "body": "..." }
{ "action": "ack", "message_id": "uuid" }
```

Incoming push frames:
```json
{ "event": "message", "message": { ...full message map... } }
```

---

## Message Format

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "from": "mail_agent",
  "to": "librarian_agent",
  "subject": "archive_request",
  "body": "string or nested object",
  "priority": "normal",
  "status": "pending",
  "created_at": "2026-04-02T08:00:00Z",
  "expires_at": null
}
```

**Status lifecycle:** `pending` → `read` → `acted` | `archived`

---

## Cron Message Format (when a cron fires)

IAMQ delivers a standard inbox message to the agent:

```json
{
  "from": "iamq",
  "to": "mail_agent",
  "subject": "cron::tidy_inbox",
  "body": {
    "fired_at": "2026-04-02T06:30:00Z",
    "expression": "30 6 * * *",
    "cron_id": "uuid"
  },
  "priority": "normal"
}
```

Agents receive this via normal inbox polling or WebSocket push — **no special handling needed** beyond checking `subject` starts with `"cron::"`.

---

## Agent Naming Conventions

- **Agent IDs:** `snake_case` (e.g., `mail_agent`, `librarian_agent`)
- **Avatars:** emoji in metadata (e.g., `"avatar": "📬"`)
- **Capabilities:** array of strings (e.g., `["email", "calendar", "contacts"]`)
- **Cron schedule names:** `snake_case` matching the task (e.g., `tidy_inbox`, `morning_briefing`)
- **Cron subjects:** `cron::<name>` (e.g., `cron::tidy_inbox`)

---

## Registration Pattern — Elixir (using iamq_bindings sidecar)

```elixir
# In application.ex start/2 or a dedicated Registrar GenServer:
defmodule MyAgent.IamqRegistrar do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    register_with_iamq()
    register_crons()
    {:ok, %{}}
  end

  defp register_with_iamq do
    IamqBindings.register("my_agent", "Agent", "🤖", "What this agent does", ["capability1"])
  end

  defp register_crons do
    IamqBindings.register_cron("daily_task", "0 8 * * *")
    IamqBindings.register_cron("weekly_report", "0 9 * * 1")
  end
end
```

---

## Registration Pattern — Python

```python
import httpx
import os

IAMQ_URL = os.getenv("IAMQ_HTTP_URL", "http://127.0.0.1:18790")
AGENT_ID = os.getenv("IAMQ_AGENT_ID", "my_agent")

def register():
    httpx.post(f"{IAMQ_URL}/register", json={
        "agent_id": AGENT_ID,
        "description": "What this agent does",
        "capabilities": ["capability1"],
        "avatar": "🤖",
    })

def heartbeat():
    httpx.post(f"{IAMQ_URL}/heartbeat", json={"agent_id": AGENT_ID})

def register_cron(name: str, expression: str):
    httpx.post(f"{IAMQ_URL}/crons", json={
        "agent_id": AGENT_ID,
        "name": name,
        "expression": expression,
        "enabled": True,
    })

def poll_inbox():
    r = httpx.get(f"{IAMQ_URL}/inbox/{AGENT_ID}", params={"status": "pending"})
    return r.json().get("messages", [])
```

---

## Cron Schedules by Agent

| Agent | Schedule Name | Expression | Purpose |
|---|---|---|---|
| `journalist_agent` | `morning_briefing` | `0 8 * * 1-5` | Morning news digest Mon–Fri |
| `journalist_agent` | `evening_digest` | `0 18 * * *` | Evening summary daily |
| `mail_agent` | `tidy_inbox` | `30 6 * * *` | Tidy inbox daily 06:30 UTC |
| `mail_agent` | `digest` | `0 7 * * *` | Generate digest daily 07:00 UTC |
| `health_fitness_agent` | `import_steps` | `0 23 * * *` | Import Health Connect data |
| `health_fitness_agent` | `weekly_report` | `0 8 * * 1` | Weekly fitness report Monday |
| `tempo_agent` | `augment_pipeline` | `0 2 * * *` | Augment data pipeline 02:00 UTC |
| `sysadmin_agent` | `security_audit` | `0 3 * * *` | Security scan 03:00 UTC |
| `sysadmin_agent` | `health_check` | `*/15 * * * *` | Health check every 15 min |
| `workday_agent` | `timesheet_sync` | `30 17 * * 1-5` | Timesheet sync 17:30 Mon–Fri |
| `herr_freud_agent` | `openclaw-herr-freud-agent` | Psychology/therapy session assistant |
| `librarian_agent` | `reindex_vault` | `0 4 * * *` | Reindex Obsidian vault 04:00 UTC |
| `gitrepo_agent` | `repo_scan` | `0 1 * * *` | Repository scan 01:00 UTC |
| `instagram_agent` | `engage_morning` | `0 9 * * *` | Morning engagement 09:00 UTC |
| `instagram_agent` | `engage_evening` | `0 19 * * *` | Evening engagement 19:00 UTC |
| `podcast_agent` | `check_episodes` | `0 6 * * *` | Check new episodes 06:00 UTC |

---

## Development Conventions

### TDD
- Write tests **first** (RED), then implement (GREEN), then refactor
- ExUnit for Elixir, pytest for Python
- Coverage threshold: **≥90%** enforced in CI

### Elixir standards
- `mix format` — enforced in CI (`mix format --check-formatted`)
- Every `defmodule` needs `@moduledoc`, every public `def` needs `@doc`
- ExDoc: `mix docs` runs in CI; `doc/` is gitignored
- OTP: use GenServer + supervision trees; never raw `spawn`

### Python standards
- `ruff check` + `ruff format --check` — enforced in CI
- Type hints required; Poetry for dependency management
- Line length: 100 chars max

### CI requirements
- All PRs must pass CI before merge
- No force-pushes to `main`
- Commit messages: imperative mood, reference spec if applicable

### Spec files
Every repo has `spec/` with:
`ARCHITECTURE.md`, `API.md`, `COMMUNICATION.md`, `CRON.md`, `PIPELINES.md`,
`SAFETY.md`, `TESTING.md`, `TROUBLESHOOTING.md`, `LEARNINGS.md`

### Sensitive data
- Never commit `.env`, API keys, credentials, PII
- Tests may contain mock emails/phones — these are excluded from secret scanning
- Use `git diff --cached` before every commit

---

## Standard Spec File Outlines

### ARCHITECTURE.md
System design, component diagram, data flow, dependencies, deployment model.

### API.md
All external interfaces: IAMQ messages accepted (subject, body format), HTTP endpoints if any, CLI commands.

### COMMUNICATION.md
How this agent uses IAMQ: what messages it sends, what it listens for, heartbeat cadence, callback URL if used.

### CRON.md
Each scheduled job: name, expression, purpose, handler module/function, expected duration, failure handling.

### PIPELINES.md
CI/CD: how to build, test, lint, deploy. GitHub Actions workflow summary.

### SAFETY.md
What this agent will NOT do. Rate limits, human approval requirements, data it never touches.

### TESTING.md
How to run tests, coverage threshold, mocking strategy, test database setup.

### TROUBLESHOOTING.md
Common failure modes and fixes. Especially: "no such table", port conflicts, missing env vars.

### LEARNINGS.md
Operational lessons. Things that surprised us. Gotchas for future developers.
