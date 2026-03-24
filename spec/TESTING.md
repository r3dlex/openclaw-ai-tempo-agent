# Testing

> How to run and extend tests for the Tempo Agent.

## Test Suites

### Elixir (Backend)

**Location:** `backend/test/`
**Framework:** ExUnit

```bash
cd backend && mix deps.get && mix test

# With coverage
cd backend && mix test --cover
```

Test categories:
- `Tempo.Analytics` computation logic (user stats, daily aggregates)
- `TempoWeb.AnalyticsController` API endpoint responses
- `TempoWeb.HealthController` health check
- `Tempo.DataStore` GenServer lifecycle and data loading

### Angular (Dashboard)

**Location:** `dashboard/src/**/*.spec.ts`
**Framework:** Karma + Jasmine

```bash
cd dashboard && npm install && npm test
```

Test categories:
- Component rendering (StatCard, UsageChart, UserTable, TopUsersChart)
- AnalyticsService HTTP calls
- DashboardComponent integration

### Python (Pipelines)

**Location:** `pipelines/tests/`
**Framework:** pytest + respx (HTTP mocking)

```bash
cd pipelines && poetry install && poetry run pytest

# With coverage
cd pipelines && poetry run pytest --cov=tempo_pipelines
```

Test categories:
- `AugmentClient` API interactions (mocked with respx)
- Pipeline execution writes correct output files
- Error handling for API failures

### Linting

```bash
# Elixir
cd backend && mix format --check-formatted

# Python
cd pipelines && poetry run ruff check .
cd pipelines && poetry run ruff format --check .
```

## CI (GitHub Actions)

**Workflow:** `.github/workflows/ci.yml`

| Job | What it runs |
|-----|-------------|
| `backend` | `mix compile --warnings-as-errors && mix format --check-formatted && mix test` |
| `dashboard` | `npm ci && npm run build` |
| `pipelines` | `ruff check && ruff format --check && pytest` |

CI runs on every push and pull request to `main`.

## Adding Tests

### For a new Elixir module

1. Create `backend/test/<path>/<module_name>_test.exs`
2. `use ExUnit.Case, async: true`
3. Test public API, error cases, and edge cases
4. Run: `cd backend && mix test test/<path>/<module_name>_test.exs`

### For a new Angular component

1. Create `component-name.component.spec.ts` next to the component
2. Use `TestBed.configureTestingModule` with standalone component imports
3. Test rendering, inputs, and user interactions
4. Run: `cd dashboard && npm test`

### For a new Python pipeline

1. Create `pipelines/tests/test_<source>.py`
2. Use `@respx.mock` to mock HTTP calls
3. Test success, failure, and rate-limit scenarios
4. Run: `cd pipelines && poetry run pytest tests/test_<source>.py`

## Testing Principles

- **Test isolation.** Each test creates its own fixtures. No shared mutable state.
- **No secrets in tests.** Use fixture data and mock HTTP, never real API tokens.
- **Structured results.** Backend tests verify JSON response shapes.

## Related

- Pipelines: [PIPELINES.md](PIPELINES.md)
- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- API: [API.md](API.md)

---
*Owner: tempo_agent*
