# Phase 163: Deterministic Release-Path Timeout Repairs - Pattern Map

**Mapped:** 2026-08-26  
**Files analyzed:** 6 likely modified files  
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/mailglass/properties/idempotency_convergence_test.exs` | test | batch / database property | `test/mailglass/properties/webhook_idempotency_convergence_test.exs` | exact |
| `test/mailglass/properties/webhook_idempotency_convergence_test.exs` | test | batch / database property | `test/mailglass/properties/idempotency_convergence_test.exs` | exact |
| `lib/mailglass/webhook/ingest.ex` | service | request-response / transactional CRUD | `lib/mailglass/webhook/replay.ex` | role-match |
| `mailglass_admin/test/support/operator_browser_server.ex` | test-support fixture server | event-driven / readiness | `mailglass_admin/test/support/admin_bootstrap.ex` | role-match |
| `mailglass_admin/playwright.config.cjs` | config | event-driven / web-server lifecycle | `mailglass_admin/package.json` | partial (runner boundary) |
| `mailglass_admin/e2e/gallery-matrix.spec.js` | browser E2E test | event-driven / matrix transform | `mailglass_admin/e2e/structural.spec.js` | role-match |

`lib/mailglass/webhook/ingest.ex` and `mailglass_admin/playwright.config.cjs` are conditional seams, not pre-authorized fixes: modify either only after focused reproduction attributes the failure to its transaction-local or readiness boundary. `.github/workflows/ci.yml` and `mailglass_admin/package.json` are integration references and must remain unchanged.

## Pattern Assignments

### `test/mailglass/properties/idempotency_convergence_test.exs` (test, batch/database property)

**Analog:** `test/mailglass/properties/webhook_idempotency_convergence_test.exs`

**Imports and property contract** (analog lines 38-48):

```elixir
use ExUnit.Case, async: false
use ExUnitProperties

import Ecto.Query

alias Mailglass.{Tenancy, TestRepo}
alias Mailglass.Events.Event
alias Mailglass.Webhook.{Ingest, WebhookEvent}

@moduletag :property
@moduletag timeout: :infinity
```

**Per-owner sandbox and fixture lifecycle** (analog lines 50-86):

```elixir
setup context do
  _owner =
    Mailglass.TestSupport.SandboxOwnership.checkout!(
      repo: TestRepo,
      shared: true,
      context: context,
      ownership_timeout: 10 * 60_000,
      settle_attempts: 600,
      settle_interval_ms: 10
    )

  Mailglass.TestSupport.CitextProbe.run(repo: TestRepo)
  :ok = Tenancy.put_current("prop-test-tenant")

  TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
  TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])

  on_exit(fn ->
    TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
    Tenancy.clear()
  end)

  :ok
end
```

**Apply locally:** retain the target’s own sanctioned checkout shape at lines 133-163: `sandbox: false`, `shared: true`, its ten-minute owner bound, and `TRUNCATE ... CASCADE` before and after. If attribution instrumentation is necessary, put it around the demonstrated query/step without changing checkout options, cleanup, generator, or property count.

**Invariant pattern** (target lines 169-205):

```elixir
check all(
        events <- list_of(event_attrs_gen(), min_length: 1, max_length: 20),
        replay_count <- integer(1..10),
        max_runs: 1000
      ) do
  TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
  fresh_keys = Enum.map(events, &apply_and_key/1)
  fresh_snapshot = snapshot()
  # reset, replay, snapshot
  assert fresh_snapshot == replayed_snapshot
end
```

### `test/mailglass/properties/webhook_idempotency_convergence_test.exs` (test, batch/database property)

**Analog:** `test/mailglass/properties/idempotency_convergence_test.exs`

**Imports / non-transactional property fixture pattern** (analog lines 120-163):

```elixir
use ExUnit.Case, async: false
use ExUnitProperties

import Ecto.Query

alias Mailglass.Events
alias Mailglass.Events.Event
alias Mailglass.TestRepo
alias Mailglass.TestSupport.SandboxOwnership

@moduletag timeout: :infinity

setup context do
  _owner =
    SandboxOwnership.checkout!(
      repo: TestRepo,
      shared: true,
      sandbox: false,
      context: context,
      ownership_timeout: 10 * 60_000
    )

  TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
  on_exit(fn -> TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", []) end)
  :ok
end
```

**Core 1,000-run property pattern** (target lines 118-193):

```elixir
check all(
        events <- list_of(event_gen(), min_length: 1, max_length: 10),
        replay_count <- integer(1..10),
        max_runs: 1000
      ) do
  TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
  TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])

  for event <- events, _ <- 1..replay_count do
    {:ok, _result} = Ingest.ingest_multi(:postmark, raw_body, [event])
  end

  assert webhook_event_count == unique_provider_event_count
  assert event_count == unique_provider_event_count
end
```

**Error/diagnostic boundary:** use the existing call site at target line 137 as the narrow observation seam for `%Postgrex.Error{postgres: %{code: :query_canceled}}`; capture structured SQLSTATE and a non-PII step/query label. Do not change lines 64-84 (owner checkout, settle bound, tenant setup, or cleanup) unless evidence points there.

### `lib/mailglass/webhook/ingest.ex` (service, request-response / transactional CRUD)

**Analog:** `lib/mailglass/webhook/replay.ex` (same webhook transaction-local database-guard pattern; search result lines 66-67).

**Imports and transaction boundary** (target lines 89-97, 153-172):

```elixir
import Ecto.Query

alias Ecto.Multi
alias Mailglass.{Clock, Config, Events, IdempotencyKey, Repo}
alias Mailglass.Events.Event
alias Mailglass.Outbound.{Delivery, Projector}
alias Mailglass.Tenancy

result =
  Repo.transact(fn ->
    _ = Repo.query!("SET LOCAL statement_timeout = '2s'", [])
    _ = Repo.query!("SET LOCAL lock_timeout = '500ms'", [])

    deliveries_by_message = load_deliveries(provider, events, tenant_id)
    multi = build_multi(provider, raw_body, decoded_payload, events, tenant_id, deliveries_by_message)

    case Repo.multi(multi) do
      {:ok, changes} -> {:ok, finalize_changes(changes, events)}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end)
```

**Structured result handling** (target lines 180-188):

```elixir
case result do
  {:ok, finalized} ->
    :ok = emit_per_event_signals(provider, finalized, tenant_id)
    :ok = emit_duplicate_signal(provider, finalized)
    {:ok, finalized}

  {:error, _reason} = err ->
    err
end
```

**Apply only if proven:** any change belongs inside this `Repo.transact/1` session/query seam and must preserve `SET LOCAL`, finite bounds, `Repo.multi/1` result tuples, and post-commit telemetry. Do not add a rescue that matches error text, global database settings, retries, or an expanded job timeout.

### `mailglass_admin/test/support/operator_browser_server.ex` (test-support fixture server, event-driven/readiness)

**Analog:** `mailglass_admin/test/support/admin_bootstrap.ex` (server-owner lifecycle; referenced by target lines 21-30).

**Boot-stage evidence and ownership pattern** (target lines 11-30):

```elixir
def run! do
  IO.puts("[operator-browser-server] booting")

  port =
    System.get_env("BROWSER_SERVER_PORT", "4101")
    |> String.to_integer()

  IO.puts("[operator-browser-server] port=#{port} — starting :mailglass app")
  {:ok, _} = Application.ensure_all_started(:mailglass)
  IO.puts("[operator-browser-server] :mailglass started — running AdminBootstrap.setup_all")
  AdminBootstrap.setup_all(port: port, server: true, pool: :sandbox, ensure_repo: true)

  owner = AdminBootstrap.start_server_owner!(ownership_timeout: @server_ownership_timeout)
  IO.puts("[operator-browser-server] sandbox owner started — timeout=#{@server_ownership_timeout} pid=#{inspect(owner)}")

  IO.puts("[operator-browser-server] AdminBootstrap done — seeding fixtures")
  OperatorFixtures.seed_browser_scenario!()
end
```

**Readiness probe / failure reporting pattern** (target lines 42-75):

```elixir
case :gen_tcp.connect(~c"127.0.0.1", port, [:binary, active: false], 2_000) do
  {:ok, sock} ->
    :gen_tcp.close(sock)
    IO.puts("[operator-browser-server] tcp probe OK — port #{port} is bound")

  {:error, reason} ->
    IO.puts("[operator-browser-server] FAIL tcp probe — port #{port} not bound (#{inspect(reason)})")
end

for path <- ["/ops/browser-ready", "/ops/browser-login?tenant_id=browser-tenant"] do
  # probe and print status or structured inspected reason
end

IO.puts("[operator-browser-server] ready at #{url}")
Process.sleep(:infinity)
```

**Apply locally:** preserve this single process, bounded TCP probe, existing `/ops/browser-ready` path, server owner lifecycle, and stage-labelled output. Add only timing evidence that distinguishes a completed readiness path from test-body execution; no second endpoint or polling mechanism.

### `mailglass_admin/playwright.config.cjs` (config, event-driven/web-server lifecycle)

**Analog:** `mailglass_admin/package.json` (runner invocation and single-worker contract, lines 1-10).

**Runner and bounded server lifecycle pattern** (target lines 10-42):

```javascript
module.exports = defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  expect: { timeout: 5_000 },
  retries: process.env.CI ? 1 : 0,
  use: { baseURL, trace: "on-first-retry" },
  webServer: {
    command: 'MIX_ENV=test mix run --no-halt -e "MailglassAdmin.TestSupport.OperatorBrowserServer.run!()"',
    cwd: __dirname,
    url: `${baseURL}${browserReadyPath}`,
    timeout: 300_000,
    reuseExistingServer: !process.env.CI,
    stdout: "pipe",
    stderr: "pipe"
  }
});
```

**External runner contract** (`mailglass_admin/package.json` lines 4-6):

```json
"test:operator-browser": "mix mailglass_admin.assets.build && playwright test --config=playwright.config.cjs --workers=1"
```

**Apply only if proven:** retain the config-wide 30-second default, CI retry policy, trace policy, 300-second `webServer.timeout`, and the package script’s `--workers=1`. If readiness evidence identifies a true config seam, make the smallest finite, local readiness adjustment; otherwise leave this file untouched.

### `mailglass_admin/e2e/gallery-matrix.spec.js` (browser E2E test, event-driven/matrix transform)

**Analog:** `mailglass_admin/e2e/structural.spec.js` (same Playwright locator, geometry, and explicitly bounded wait conventions; e.g. lines 343-354 define `settledBoundingBox`).

**Imports and reusable assertion helpers** (target lines 1, 60-79):

```javascript
const { test, expect } = require("@playwright/test");

async function openGallery(page) {
  await page.goto("/dev/mail/gallery");
  await expect(page.getByRole("heading", { name: "Component Gallery", level: 1 })).toBeVisible();
}

async function assertNoHorizontalOverflow(locator, label) {
  await expect(locator, `${label} visible`).toBeVisible();
  const overflow = await locator.evaluate(el => el.scrollWidth - el.clientWidth);
  expect(overflow, `${label} horizontal overflow (scrollWidth - clientWidth)`).toBeLessThanOrEqual(1);
}
```

**Live discovery and fail-closed coverage guard** (target lines 112-126, 163-172):

```javascript
async function discoverGalleryCells(page) {
  const ids = await page.locator("[data-testid^='gallery-']").evaluateAll(nodes =>
    nodes
      .map(node => node.getAttribute("data-testid"))
      .filter(id => id && id.startsWith("gallery-") && !id.endsWith("-system"))
  );
  return Array.from(new Set(ids)).filter(id => !COMPOSED_INNER_TESTIDS.has(id));
}

const cells = await discoverGalleryCells(page);
expect(cells.length, "gallery exposes specimen cells").toBeGreaterThan(50);
for (const stress of STRESS_CELLS) {
  expect(cells, `gallery includes stress cell ${stress}`).toContain(stress);
}
```

**Matrix and stress-test contract** (target lines 174-203, 205-231):

```javascript
for (const width of MATRIX_WIDTHS) {
  await page.setViewportSize({ width, height: MATRIX_HEIGHT });
  for (const cellTestId of cells) {
    await expect(page.getByTestId(cellTestId), `${cellTestId} cell @${width}`).toBeVisible();
    for (const theme of MATRIX_THEMES) {
      const wrapper = themeWrapper(page, cellTestId, theme);
      if (enforceOverflow) await assertNoHorizontalOverflow(wrapper, `${cellTestId} ${theme} @${width}`);
      if (width === 320) await assertNotClippedAt320(wrapper, `${cellTestId} ${theme}`);
    }
  }
}
```

**Apply locally:** if body-duration measurement proves that this one spec needs a local deadline, set it at the individual test/describe boundary while retaining both tests, all four widths, three themes, live discovery, `> 50` guard, stress cells, overflow checks, and 320px clipping checks. Do not change the config-global timeout or reduce loops.

## Shared Patterns

### Sandbox ownership and cleanup

**Source:** `test/support/sandbox_ownership.ex` lines 453-487  
**Apply to:** both property files and browser server owner setup

```elixir
owner = Ecto.Adapters.SQL.Sandbox.start_owner!(repo, opts)

ExUnit.Callbacks.on_exit(fn ->
  :ok = Ecto.Adapters.SQL.Sandbox.stop_owner(owner)

  if shared? do
    assert_manual!(repo, caller,
      attempts: settle_attempts,
      interval_ms: settle_interval_ms
    )
  end
end)

owner
```

The registration must remain immediately after acquisition. Never replace it with ad-hoc checkout/release logic or turn the previously established per-owner bound into a global policy.

### Structured database error boundary

**Source:** `lib/mailglass/webhook/ingest.ex` lines 153-188  
**Apply to:** property diagnostic capture and any proven ingest repair

Capture structured `%Postgrex.Error{postgres: %{code: :query_canceled}}` metadata and the actual operation/step; preserve `{:ok, _}` / `{:error, reason}` result tuples. Do not match error strings or include raw message content in durable diagnostics.

### Browser boot versus body timing

**Source:** `mailglass_admin/test/support/operator_browser_server.ex` lines 7-75; `mailglass_admin/playwright.config.cjs` lines 22-42  
**Apply to:** the server support, config only if proven, and gallery spec

Server readiness is already observable through stage prints, TCP, and `/ops/browser-ready`; Playwright body work begins only after that web-server readiness contract succeeds. Measure/report those phases separately before choosing a finite local bound.

### Immutable integration gates

**Source:** `.github/workflows/ci.yml` lines 366-448 and 907-979  
**Apply to:** final evidence, not implementation

```yaml
# Core Deterministic Suite
- name: Run deterministic core suite
  run: mix test --warnings-as-errors

# Operator Browser Gate
- name: Run operator browser gate
  working-directory: mailglass_admin
  run: npm run test:operator-browser
```

The CI job topology and `timeout-minutes: 30` limits are protected integration constraints, not repair levers.

## No Analog Found

None. Every permitted seam has a direct local pattern. The exact SQLSTATE source and gallery timeout stage are intentionally unproven; the planner must schedule unmodified reproduction/capture before selecting which conditional seam, if any, changes.

## Metadata

**Analog search scope:** `test/mailglass/properties/`, `test/support/`, `lib/mailglass/webhook/`, `mailglass_admin/e2e/`, `mailglass_admin/test/support/`, `mailglass_admin/playwright.config.cjs`, `mailglass_admin/package.json`, `.github/workflows/ci.yml`  
**Files scanned:** 16 focused source/config files  
**Pattern extraction date:** 2026-08-26
