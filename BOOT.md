# Boot

On startup, execute the following:

1. Read `IDENTITY.md`, `SOUL.md`, and `TOOLS.md` to establish context.
2. Read `spec/ARCHITECTURE.md` to load system design context.
3. Verify Docker containers are running (`docker compose ps`). If the `backend` service is down, start it with `docker compose up -d`.
4. **Verify IAMQ registration** — the Elixir backend (`Tempo.MqClient` + `Tempo.MqWsClient`) handles registration automatically (HTTP primary, WebSocket for real-time push). Check logs:
   ```bash
   docker compose logs backend 2>&1 | grep -i "iamq" | tail -5
   ```
   If registered, you'll see `[MQ] Registered as tempo_agent` or `[MQ-WS] Connected`. If failing, check `IAMQ_HTTP_URL` and `IAMQ_WS_URL` in `.env`.
5. **Verify data sources are accessible** — confirm API connectivity:
   ```bash
   # Check backend health endpoint
   curl -s http://localhost:4000/api/v1/health
   ```
   The health endpoint reports the status of each data source (Augment Code, Copilot, Claude).
6. **Check dashboard health** — verify the frontend is serving:
   ```bash
   curl -s -o /dev/null -w "%{http_code}" http://localhost:4200
   ```
   Expected: `200`. If not, check `docker compose logs dashboard`.
7. **Check IAMQ inbox** for messages received while offline:
   ```bash
   curl -s http://127.0.0.1:18790/inbox/tempo_agent?status=unread
   ```
   Process any unread messages. Mark as read/acted via `PATCH /messages/{id}`.
8. **Discover other agents** — see who's online:
   ```bash
   curl -s http://127.0.0.1:18790/agents
   ```
9. Check `data/` for pending or partially-processed data from a previous session. Resume processing if any exist.
10. Check data freshness — if any source is more than 6 hours stale, trigger a refresh.
11. Generate a startup log entry to `data/log/`.

> For system architecture context, see `spec/ARCHITECTURE.md`.
> For troubleshooting startup failures, see `spec/TROUBLESHOOTING.md`.
