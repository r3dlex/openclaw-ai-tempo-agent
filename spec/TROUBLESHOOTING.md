# Troubleshooting

> Common issues, root causes, and fixes for the Tempo Agent stack.

## Backend Startup

### Phoenix won't start

| Symptom | Cause | Fix |
|---|---|---|
| `eaddrinuse` on port 4000 | Another process on the port | `lsof -i :4000` and kill the stale process, or set `PORT` to a different value |
| `(Mix) Could not start application` | Missing deps or config | Run `cd backend && mix deps.get` then verify `.env` is sourced |
| `(RuntimeError) :crypto not available` | Erlang built without OpenSSL | Reinstall Erlang/OTP with OpenSSL support |
| DataStore crash on boot | Missing or malformed JSON in `data/` | Verify JSON files exist and are valid; create empty `[]` files if needed |

### DataStore GenServer crashes

The DataStore loads JSON files from `data/` on startup. Common causes:

- Missing `data/` directory — create it: `mkdir -p data`
- Invalid JSON — validate with `jq . data/augment_usage.json`
- File permissions — ensure the backend process can read `data/*.json`

## API Token Issues

### Tokens not working

| Symptom | Cause | Fix |
|---|---|---|
| 401 from data source APIs | Expired or invalid token | Regenerate the token and update `.env` |
| Empty data responses | Token lacks required scopes | Check API documentation for required permissions |
| Token appears in logs | Logging level too verbose | Set `LOG_LEVEL=info` and never log request headers |

All API tokens must be configured via environment variables only. Never hardcode tokens in source files.

## Data Format Errors

### Aggregation returns empty results

1. Check that JSON files exist in `data/`: `ls -la data/*.json`
2. Validate JSON format: `jq . data/<file>.json`
3. Verify the DataStore has loaded data: `GET /status` should show file counts
4. Check for schema mismatches — each record needs at minimum a timestamp and user field

### Dashboard shows no data

1. Verify the backend is running: `curl http://localhost:4000/status`
2. Check the API response: `curl http://localhost:4000/api/analytics`
3. Check browser console for CORS errors — ensure the dashboard origin is allowed
4. Verify the dashboard `VITE_API_URL` environment variable points to the backend

## IAMQ Integration

### Registration fails

```
[MQ] Registration failed: :econnrefused
```

The IAMQ service is not running or unreachable.

| Check | Command |
|---|---|
| IAMQ is running | `curl http://127.0.0.1:18790/health` |
| Correct URL configured | Verify `IAMQ_HTTP_URL` in `.env` |
| Gateway intercepting localhost | Use the host LAN IP instead of `127.0.0.1` |

### Heartbeat timeout

The agent sends heartbeats every `IAMQ_HEARTBEAT_MS` (default 60s). If IAMQ marks the agent as offline:

- Check WebSocket connection: logs will show `[MqWsClient]` reconnection attempts
- Verify `IAMQ_WS_URL` points to port `18793` (WebSocket), not `18790` (HTTP)

### Messages not arriving

1. Confirm registration: `GET http://127.0.0.1:18790/agents` should list `tempo_agent`
2. Check the sender used the correct `to` field: `tempo_agent`
3. Verify polling is active: `IAMQ_POLL_MS` (default 30s)

## Dashboard Build

### `npm run build` fails

| Symptom | Cause | Fix |
|---|---|---|
| TypeScript errors | Type mismatches | Fix the type errors shown in the build output |
| Missing dependencies | `node_modules` out of date | Run `cd dashboard && npm ci` |
| Vite config error | Invalid `vite.config.ts` | Check Vite docs for correct configuration |

## Related

- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- API reference: [API.md](API.md)
- Safety rules: [SAFETY.md](SAFETY.md)

---
*Owner: tempo_agent*
