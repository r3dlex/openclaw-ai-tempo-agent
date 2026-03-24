# Communication

> How the Tempo Agent communicates with peer agents via IAMQ.

## IAMQ Registration

The agent registers on startup with the Inter-Agent Message Queue at `$IAMQ_HTTP_URL`.

```json
{
  "agent_id": "tempo_agent",
  "capabilities": [
    "analytics_report",
    "usage_summary",
    "tool_usage_stats",
    "user_activity",
    "copilot_analytics",
    "augment_analytics",
    "claude_analytics"
  ]
}
```

## Incoming Messages

The Tempo agent handles the following request types from peer agents:

| Request type | Description | Response |
|-------------|-------------|----------|
| `analytics` | Request aggregated analytics across all tools | Full analytics summary |
| `usage` | Request usage data for a specific tool or time range | Filtered usage report |
| `report` | Request a formatted usage report | Markdown-formatted report |
| `status` | Request agent health and data freshness | Status with last-updated timestamps |

### Example incoming request

```json
{
  "from": "agent_claude",
  "to": "tempo_agent",
  "type": "request",
  "priority": "NORMAL",
  "subject": "Weekly Usage Report",
  "body": {
    "action": "report",
    "period": "week",
    "tools": ["copilot", "claude", "augment"]
  }
}
```

## Outgoing Messages

### Usage Summary Broadcast

The agent periodically broadcasts aggregated usage summaries to all agents.

```json
{
  "from": "tempo_agent",
  "to": "broadcast",
  "type": "info",
  "priority": "NORMAL",
  "subject": "AI Tool Usage Summary — 2026-03-24",
  "body": "Total sessions: 142 | Copilot: 68 | Claude: 45 | Augment: 29\nTop tool: GitHub Copilot (48%)\n\nFull report available via request."
}
```

Keep broadcast bodies under 500 characters. Detailed data is available on request only.

## Graceful Degradation

When IAMQ is unreachable:

1. Log the connection failure
2. Continue serving the dashboard and API normally
3. Skip broadcasting and message handling
4. Retry on next heartbeat cycle

The agent must never fail its core analytics function because IAMQ is down.

## Peer Agents

| Agent | Relationship |
|-------|-------------|
| `agent_claude` | Requests usage reports, receives summaries |
| `gitrepo_agent` | Receives Copilot usage data context |
| `broadcast` | Receives periodic usage summaries |

## Related

- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- API: [API.md](API.md)
- Safety rules for data in messages: [SAFETY.md](SAFETY.md)

---
*Owner: tempo_agent*
