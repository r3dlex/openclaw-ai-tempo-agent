# HEARTBEAT.md

Tempo periodic checks. On every heartbeat poll, run through these tasks
in order. If nothing needs attention after all checks, reply `HEARTBEAT_OK`.

## MQ Tasks (Inter-Agent Message Queue)

The MQ is the primary channel for agent-to-agent communication.
Service: `$IAMQ_HTTP_URL` (default `http://127.0.0.1:18790`).
Protocol: see `openclaw-inter-agent-message-queue/spec/PROTOCOL.md`.

- [x] **Send heartbeat** — keep yourself visible to other agents
  ```
  POST http://127.0.0.1:18790/heartbeat
  {"agent_id": "tempo_agent"}
  ```

- [x] **Check inbox** — process unread messages from other agents
  ```
  GET http://127.0.0.1:18790/inbox/tempo_agent?status=unread
  ```
  For each unread message:
  1. Mark as read: `PATCH /messages/{id} {"status": "read"}`
  2. If `type: "request"` — act on it (analytics query, data refresh, etc.)
  3. Reply through the MQ with `replyTo` threading:
     ```
     POST http://127.0.0.1:18790/send
     {
       "from": "tempo_agent",
       "to": "{requesting_agent}",
       "type": "response",
       "subject": "Re: {original_subject}",
       "body": "{your response}",
       "replyTo": "{original_message_id}"
     }
     ```
  4. Mark original as acted: `PATCH /messages/{id} {"status": "acted"}`
  5. Also send to Telegram for human visibility (but MQ is primary)

- [x] **Check broadcast** — read system-wide announcements
  Broadcast messages appear in your inbox alongside direct messages.
  Read them, acknowledge internally, mark as `read`.

## Data Freshness

- [x] **Check data freshness** — are analytics stale?
  Check the last-updated timestamp for each data source:
  - Augment Code: should be < 6 hours old
  - GitHub Copilot: should be < 6 hours old
  - Claude: should be < 6 hours old
  If any source is stale, trigger a refresh. Log the refresh in your daily memory.

- [x] **Check for pending one-shot tasks** — review `spec/TASK.md`

## Report to User

Send a Telegram summary ONLY when there's something worth reporting:
- Data was refreshed with new metrics available.
  Example: "Analytics refreshed: 3 sources updated, 1,247 new events. Copilot acceptance rate up 5%."
- New insights or anomalies found.
  Example: "Anomaly detected: Claude usage dropped 60% yesterday. Possible API outage?"
- Errors or pipeline failures: report IMMEDIATELY.
- Do NOT send a message if nothing happened. Silent heartbeats are fine.

## Rules

- MQ replies go through `POST /send` with `replyTo` — never only Telegram
- Mark messages `read` immediately, `acted` after completing the request
- Keep heartbeat responses fast — batch checks, don't deep-dive on heartbeat
- If an analytics request will take time, reply with an acknowledgment first,
  then send the full response when ready

> For IAMQ message formats and capabilities, see `spec/COMMUNICATION.md`.
> For data freshness thresholds and pipeline details, see `spec/PIPELINES.md`.
