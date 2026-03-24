# Learnings

> Timestamped log of discoveries, mistakes, and insights accumulated during development and operation.

## Format

Each entry follows this structure:

```
### YYYY-MM-DD — Short title

What happened, what was learned, and what changed as a result.
Optionally link to relevant specs, commits, or files.
```

Entries are appended chronologically. Never delete old entries — they are the project's institutional memory.

---

### 2026-03-24 — IAMQ integration requires separate HTTP and WS ports

The IAMQ service exposes two ports: HTTP on `:18790` and WebSocket on `:18793`. The Tempo agent's `MqClient` uses HTTP for registration, heartbeat, and inbox polling, while `MqWsClient` uses WebSocket for real-time push. Mixing up these ports causes silent connection failures.

When the OpenClaw gateway (Node.js) intercepts `127.0.0.1`, configure `IAMQ_HTTP_URL` and `IAMQ_WS_URL` with the host LAN IP instead.

> Troubleshooting: [spec/TROUBLESHOOTING.md](TROUBLESHOOTING.md#iamq-integration)
