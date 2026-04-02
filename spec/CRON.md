# Cron Schedules — openclaw-ai-tempo-agent

## Overview

The Tempo agent runs a daily data pipeline to fetch and aggregate AI tool usage
metrics from Augment Code, GitHub Copilot, and Claude. All crons are registered
with IAMQ on startup and delivered as `cron::` messages.

## Schedules

### daily_pipeline
- **Expression**: `0 2 * * *` (02:00 UTC daily)
- **Purpose**: Fetch fresh usage data from all configured AI tool APIs (Augment,
  Copilot, Claude), transform and load into the Phoenix backend, update dashboard.
- **Trigger**: Delivered via IAMQ message `cron::daily_pipeline`
- **Handler**: `tempo_pipelines` Python package → `run_daily_pipeline()`; also
  invocable via `docker compose exec backend mix tempo.refresh`
- **Expected duration**: 2–5 minutes (network-bound; Augment API can be slow)
- **On failure**: Pipeline logs error to `$TEMPO_DATA_DIR/logs/`; IAMQ broadcast
  `pipeline_failed` message to `agent_claude`; retry next day automatically

### weekly_report
- **Expression**: `0 9 * * 1` (09:00 UTC Monday)
- **Purpose**: Generate a formatted weekly usage report summarising AI tool costs,
  top users, and trend vs previous week. Sends summary to user via Telegram.
- **Trigger**: Delivered via IAMQ message `cron::weekly_report`
- **Handler**: `tempo_pipelines.reports.weekly_report()`
- **Expected duration**: 30 seconds (reads from local DB, no external calls)
- **On failure**: Log error; skip silently (non-critical)

## Cron Registration

This agent registers its crons with IAMQ on startup via `POST /crons`:

```json
[
  {"subject": "cron::daily_pipeline",  "expression": "0 2 * * *"},
  {"subject": "cron::weekly_report",   "expression": "0 9 * * 1"}
]
```

The registration is performed in the Phoenix application's `on_mount` callback
or equivalent boot step (`BOOT.md`).

## Manual Trigger

```bash
# Trigger pipeline manually via scheduler service
docker compose exec backend mix tempo.refresh

# Or via Python pipeline runner
cd pipelines && poetry run python -m tempo_pipelines
```

---

**Related:** `spec/PIPELINES.md`, `spec/ARCHITECTURE.md`, `spec/COMMUNICATION.md`

## References

- [IAMQ Cron Subsystem](https://github.com/r3dlex/openclaw-inter-agent-message-queue/blob/main/spec/CRON.md) — how cron schedules are stored and fired
- [IAMQ API — Cron endpoints](https://github.com/r3dlex/openclaw-inter-agent-message-queue/blob/main/spec/API.md#cron-scheduling)
- [IamqSidecar.MqClient.register_cron/3](https://github.com/r3dlex/openclaw-inter-agent-message-queue/tree/main/sidecar) — Elixir sidecar helper
- [openclaw-main-agent](https://github.com/r3dlex/openclaw-main-agent) — orchestrates cron-triggered pipelines
