# Safety & Red Lines

> Non-negotiable rules for the Tempo Agent. These protect user privacy, keep secrets safe, and respect API limits.

## Data Privacy

- **Aggregate only in broadcasts.** Never expose individual user usage data in IAMQ broadcasts or public-facing summaries. All broadcast messages must contain aggregated metrics only.
- **Per-user data on request only.** Individual user activity is only returned via authenticated API endpoints or direct IAMQ requests from authorized agents.
- **No PII in logs.** User identifiers in logs must be anonymized or pseudonymized. Never log full email addresses or personal names.

## Credential Security

- **API tokens are env-only.** All tokens for Augment Code, GitHub Copilot, and Claude APIs are resolved from environment variables. Never hardcode, never commit.
- **Never log tokens.** API tokens, session keys, and authentication headers must never appear in log output, error messages, or IAMQ messages.
- **All credentials from `.env`.** Configuration variables: `AUGMENT_API_TOKEN`, `GITHUB_TOKEN`, `ANTHROPIC_API_KEY`. No hardcoding, no fallback defaults for secrets.

## Rate Limiting

- **Respect API rate limits.** Each data source has its own rate limits. The agent must implement backoff and retry logic, never brute-force retries.
- **Max polling frequency.** Do not poll any external API more than once per 15 minutes unless explicitly configured otherwise.
- **Log rate limit events.** When a rate limit is hit, log the event and broadcast a notice via IAMQ so peer agents are aware.

## Data Integrity

- **Validate before storing.** All incoming data must be validated against the expected schema before writing to `data/` JSON files.
- **No data deletion via API.** The API is read-only. Data files are managed through the ingestion pipeline only.
- **Backup before overwrite.** When updating `data/` files, write to a temp file first, then atomically rename.

## Failure Modes

| Condition | Action |
|-----------|--------|
| Data source API rate limited | Back off, log, retry after cooldown |
| Data source API unreachable | Serve stale data, log warning |
| Malformed data from source | Reject record, log error, continue with valid data |
| IAMQ unreachable | Continue serving dashboard and API, skip messaging |
| DataStore crash | Supervisor restarts GenServer, reloads from disk |

The agent must never crash entirely due to a single data source failure. Isolate failures and continue serving available data.

## Logging

- Log all data fetches with timestamp, source, record count, and result status
- **No secrets in logs.** Redact tokens, API keys, and authentication headers
- JSON structured logging (gitignored)

## Related

- Communication (IAMQ message rules): [COMMUNICATION.md](COMMUNICATION.md)
- Troubleshooting: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)

---
*Owner: tempo_agent*
