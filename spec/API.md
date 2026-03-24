# API.md - Phoenix API Endpoints

> HTTP API served by the Elixir/Phoenix backend on port 4000.
> All endpoints are under `/api/v1/`.

## Health Check

### GET /api/v1/health

Returns backend status.

```json
{
  "status": "ok",
  "service": "tempo",
  "version": "0.1.0"
}
```

## Analytics Endpoints

All analytics endpoints are scoped by data source. Currently supported: `augment`.

### GET /api/v1/analytics/sources

Lists available data sources.

```json
{
  "sources": ["augment"]
}
```

### GET /api/v1/analytics/:source/summary

Returns high-level summary metrics for a data source.

```json
{
  "source": "augment",
  "total_credits": 4523891,
  "total_users": 45,
  "active_users": 42,
  "days_tracked": 59,
  "average_credits_per_user": 100530.91
}
```

### GET /api/v1/analytics/:source/users

Returns per-user statistics, sorted by total credits descending.

```json
{
  "source": "augment",
  "users": [
    {
      "email": "alice@example.com",
      "total_credits": 542310,
      "average_daily": 10846.2,
      "days_active": 50,
      "last_active": "2026-01-21"
    }
  ]
}
```

### GET /api/v1/analytics/:source/daily

Returns daily aggregate statistics, sorted chronologically.

```json
{
  "source": "augment",
  "daily": [
    {
      "date": "2025-11-24",
      "total_credits": 234567,
      "user_count": 38
    }
  ]
}
```

### GET /api/v1/analytics/:source/raw

Returns raw data points (limited to first 100 records).

```json
{
  "source": "augment",
  "count": 2134,
  "data": [...]
}
```

## Error Responses

All endpoints return errors in a consistent format:

```json
{
  "error": "unsupported source"
}
```

| HTTP Status | Meaning |
|-------------|---------|
| 200 | Success |
| 400 | Invalid source or parameter |
| 500 | Internal server error |

## CORS

The API allows requests from `http://localhost:4200` (Angular dev) and `http://localhost:4000`.
In production, nginx handles the proxy so CORS is not needed.

## Related

- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Testing: [TESTING.md](TESTING.md)
- Troubleshooting: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---
*Owner: tempo_agent*
