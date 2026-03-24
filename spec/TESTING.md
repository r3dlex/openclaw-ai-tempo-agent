# Testing

> How to run and extend tests for the Tempo Agent.

## Test Suites

### Elixir (Backend)

**Location:** `backend/test/`
**Framework:** ExUnit

```bash
# Local
cd backend && mix deps.get && mix test

# With coverage
cd backend && mix test --cover
```

Test categories:
- DataStore GenServer lifecycle and data loading
- API endpoint responses (analytics, users, status)
- MqClient registration and heartbeat
- Data aggregation logic

### Dashboard (React)

**Location:** `dashboard/src/__tests__/` or colocated `*.test.tsx`
**Framework:** Vitest (or Jest)

```bash
# Local
cd dashboard && npm test

# With coverage
cd dashboard && npm test -- --coverage
```

Test categories:
- Component rendering (StatCard, UsageChart, UserTable, TopUsersChart)
- Data fetching and transformation
- Chart data formatting

### Docker (Full Stack)

```bash
# Backend tests in Docker
docker compose run --rm backend mix test

# Dashboard build check
docker compose run --rm dashboard npm run build
```

## CI (GitHub Actions)

**Workflow:** `.github/workflows/ci.yml`

| Job | What it runs |
|-----|-------------|
| `elixir` | `mix compile --warnings-as-errors && mix test` |
| `dashboard` | `npm ci && npm run build` |

CI runs on every push and pull request to `main`.

## Adding Tests

### For a new Elixir module

1. Create `backend/test/<module_name>_test.exs`
2. Test public API, error cases, and edge cases
3. Run: `cd backend && mix test test/<module_name>_test.exs`

### For a new React component

1. Create a test file next to the component: `ComponentName.test.tsx`
2. Test rendering, props, and user interactions
3. Run: `cd dashboard && npm test`

## Testing Principles

- **Test isolation.** Each test creates its own fixtures. No shared mutable state.
- **No secrets in tests.** Use fixture data, never real API tokens.
- **Structured results.** Backend tests verify JSON response shapes.

## Related

- Pipelines: [PIPELINES.md](PIPELINES.md)
- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- API: [API.md](API.md)

---
*Owner: tempo_agent*
