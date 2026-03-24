# API.md - Phoenix API Endpoints

> HTTP API served by the Elixir/Phoenix backend on port 4000.

## Endpoints

### GET /api/analytics

Returns aggregated analytics across all AI tools.

**Response:**

```json
{
  "total_sessions": 142,
  "by_tool": {
    "copilot": { "sessions": 68, "active_users": 12 },
    "claude": { "sessions": 45, "active_users": 8 },
    "augment": { "sessions": 29, "active_users": 5 }
  },
  "period": {
    "start": "2026-03-17T00:00:00Z",
    "end": "2026-03-24T00:00:00Z"
  },
  "generated_at": "2026-03-24T10:30:00Z"
}
```

**Query parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `period` | string | `week` | Time period: `day`, `week`, `month` |
| `tool` | string | all | Filter by tool: `copilot`, `claude`, `augment` |

### GET /api/users

Returns user activity data.

**Response:**

```json
{
  "users": [
    {
      "id": "user_001",
      "display_name": "Alice",
      "total_sessions": 34,
      "last_active": "2026-03-24T09:15:00Z",
      "tools_used": ["copilot", "claude"]
    }
  ],
  "total": 15,
  "generated_at": "2026-03-24T10:30:00Z"
}
```

**Query parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `sort` | string | `total_sessions` | Sort field: `total_sessions`, `last_active`, `display_name` |
| `order` | string | `desc` | Sort order: `asc`, `desc` |
| `limit` | integer | 50 | Max results (1-100) |

### GET /status

Health check endpoint. Returns backend status and data freshness.

**Response:**

```json
{
  "status": "ok",
  "uptime_seconds": 3600,
  "data_sources": {
    "augment": { "records": 120, "last_updated": "2026-03-24T08:00:00Z" },
    "copilot": { "records": 340, "last_updated": "2026-03-24T08:00:00Z" },
    "claude": { "records": 210, "last_updated": "2026-03-24T08:00:00Z" }
  },
  "iamq_connected": true
}
```

## Error Responses

All endpoints return errors in a consistent format:

```json
{
  "error": "invalid_parameter",
  "message": "Unknown tool: foo. Valid values: copilot, claude, augment"
}
```

| HTTP Status | Meaning |
|-------------|---------|
| 200 | Success |
| 400 | Invalid query parameter |
| 500 | Internal server error |

## CORS

The API allows requests from the dashboard origin (configurable via `DASHBOARD_URL` env var, default `http://localhost:5173`).

## Related

- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Testing: [TESTING.md](TESTING.md)
- Troubleshooting: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---
*Owner: tempo_agent*
