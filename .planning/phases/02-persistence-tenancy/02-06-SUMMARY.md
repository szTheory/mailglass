---
phase: 02-persistence-tenancy
plan: 06
subsystem: persistence
tags: [outbound, projector, suppression, integration, tenancy, optimistic-lock]

# Dependency graph
requires:
  - phase: 02-persistence-tenancy
    provides: "Mailglass.Outbound.Delivery schema + :lock_version (Plan 03); Mailglass.Events.Event schema + append/1 + append_multi/3 (Plan 03 + 05); Mailglass.Suppression.Entry schema + validate_scope_stream_coupling (Plan 03); Mailglass.Tenancy.current/0 + put_current/1 (Plan 04); Mailglass.Telemetry.persist_span/3 (Plan 01); Mailglass.Repo facade with SQLSTATE 45A01 translation (Plan 01); V01 DDL with mailglass_suppressions UNIQUE index + CHECK (Plan 02)"
provides:
  - "Mailglass.Outbound.Projector — single writer for Delivery projection columns per D-14. update_projections/2 returns an Ecto.Changeset chaining optimistic_lock(:lock_version) per D-18."
  - "D-15 monotonic rule set — last_event_type advances on every event; last_event_at is monotonic max; dispatched/delivered/bounced/complained/suppressed_at are set-once; terminal is a one-way latch (false → true on terminal event types, never flips back)."
  - "Mailglass.SuppressionStore behaviour — check/2 + record/2 callbacks. Closed-atom contract for pre-send lookup and add/update."
  - "Mailglass.SuppressionStore.Ecto — default Postgres-backed impl. check/2 performs the union lookup (address | domain | address_stream) with expiry filter; record/2 upserts on conflict_target (tenant_id, address, scope, COALESCE(stream, ''))."
  - "test/mailglass/persistence_integration_test.exs — phase-wide integration test proving all 5 ROADMAP Phase 2 success criteria + D-09 multi-tenant isolation hold end-to-end."
affects: [03-outbound (deliver/2 preflight + dispatch retry), 04-webhook (webhook plug Multi shape), 04-reconciler (Oban worker wrapping find_orphans + attempt_link + update_projections), 05-admin-liveview (queries via SuppressionStore.check/2 surface)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pattern 1: Pure-changeset projection transforms with telemetry wrap — Projector.update_projections/2 returns an Ecto.Changeset the caller plugs into Ecto.Multi.update. Monotonic rules live in changeset helper chain (maybe_set_later_event_type → maybe_set_later_at → maybe_set_once_timestamp → maybe_flip_terminal → optimistic_lock). Downstream callers compose without knowing about D-15 semantics."
    - "Pattern 2: Three-branch OR-union for suppression lookup — factored into union_predicates/4 clauses (with-stream vs without-stream). Ecto refuses compile-time `e.stream == ^nil`; the clause split keeps the stream-less branch tight and obvious. UPSERT conflict_target matches the Plan 02 migration's UNIQUE index definition character-for-character (COALESCE(stream, '') normalizes NULL vs '' so stream-less and streamed entries never alias)."
    - "Pattern 3: Per-test pool-poisoning probe — `probe_until_clean/5` in the integration test's `setup` block loops up to 5 harmless citext queries; any poisoned worker fails the probe, `disconnect_on_error_codes: [:internal_error]` in config/test.exs auto-disconnects it, and the next checkout lands a clean worker. Belt-and-suspenders with the config change. Full story + architectural fixes deferred to Phase 6 in deferred-items.md."
    - "Pattern 4: Phase-wide integration tests under Mailglass.DataCase (async: false) — prove N success criteria in a single file by organizing each criterion under its own describe block. The Multi shape Phase 4 will compose is written literally in the ROADMAP §4 test so Phase 4 can copy/paste the Multi body."

key-files:
  created:
    - "lib/mailglass/outbound/projector.ex — single writer for Delivery projection columns (124 lines)"
    - "lib/mailglass/suppression_store.ex — SuppressionStore behaviour (51 lines)"
    - "lib/mailglass/suppression_store/ecto.ex — default Ecto-backed SuppressionStore impl (119 lines)"
    - "test/mailglass/outbound/projector_test.exs — 11 tests covering monotonic rules, optimistic_lock, telemetry, PII refutation (241 lines)"
    - "test/mailglass/suppression_store/ecto_test.exs — 14 tests covering scopes, citext, tenant isolation, expiry, upsert, telemetry (253 lines)"
    - "test/mailglass/persistence_integration_test.exs — phase-wide integration test, 9 tests across 5 ROADMAP criteria + D-09 (305 lines)"
  modified:
    - "config/test.exs — added `disconnect_on_error_codes: [:internal_error]` to Mailglass.TestRepo config to mitigate Postgrex type cache poisoning after migration_test down-then-up"
    - ".planning/phases/02-persistence-tenancy/deferred-items.md — documented the Postgrex TypeServer cache issue + candidate Phase 6 fixes"

key-decisions:
  - "Projector `maybe_set_later_event_type/2` updates `last_event_type` UNCONDITIONALLY — it's a 'latest event' pointer, not a monotonic lifecycle fact. Per D-15: only timestamps and `terminal` follow the monotonic rule; `last_event_type` always advances to the incoming event's type. Documented in moduledoc + test `non-monotonic ordering: :opened BEFORE :delivered` covers the reorder case."
  - "`union_predicates/4` factored into two clauses (with-stream vs without-stream) because Ecto refuses compile-time `e.stream == ^nil`. Stream-less callers have no basis to match :address_stream-scoped entries anyway, so dropping the branch is correct behaviour. The code is more readable than a dynamic `or` with `^stream && e.stream == ^stream` ternary."
  - "`on_conflict: {:replace, [:reason, :source, :expires_at, :metadata]}` deliberately excludes `:tenant_id`, `:address`, `:scope`, `:stream`, `:id`, `:inserted_at` — re-adds keep identity stable, update mutable fields only. Admin re-adds are idempotent; a /delete + re-add would need to change the target row's identity which is a distinct operation (not shipped Phase 2)."
  - "Per-test `probe_until_clean/5` in the integration test instead of a `setup_all` TypeServer kill. Killing `Postgrex.TypeServer` processes in either migration_test's teardown or integration_test's setup_all cascaded into DBConnection 'awaited on another connection that failed to bootstrap types' across unrelated tests (property test, DataCase-using tests). The shared TypeServer is load-bearing; per-connection probing via `disconnect_on_error_codes` is surgical."
  - "Phase 2 integration test's ROADMAP §4 block is the canonical Phase 4 webhook Multi shape. The `Ecto.Multi.run(:delivery_update, ...)` step inspects `event.inserted_at` per Plan 05's sentinel to distinguish fresh insert from replay (on replay, skip the projector call). Phase 4 implementers can copy the Multi body verbatim."

patterns-established:
  - "Pattern 1: Projector as pure changeset transform with telemetry wrap (lib/mailglass/outbound/projector.ex) — any future projection-column changes fit this shape: add a helper in the changeset pipeline, update @terminal_event_types or timestamp_field_for/1 if needed, extend tests. No DB-level logic needed."
  - "Pattern 2: Behaviour + default-Ecto impl for persistence backends (lib/mailglass/suppression_store.ex + lib/mailglass/suppression_store/ecto.ex) — matches TemplateEngine + HEEx precedent from Phase 1. Adopters swap via `config :mailglass, suppression_store: MyApp.Impl`; future stores (ETS, Redis) implement the same behaviour."
  - "Pattern 3: Closed-atom-set helper dispatch — Projector's `timestamp_field_for/1` is the pattern for mapping event atoms to projection columns. Unknown events fall through to `_ -> nil` cleanly. Phase 4's webhook mappers will use the same dispatch style."
  - "Pattern 4: Composed Multi with Events.append_multi + Projector.update_projections — ROADMAP §4 integration test is the canonical shape. Phase 4 webhook handler wraps this in Mailglass.Repo.transact/1; Phase 3 dispatch retry does the same around Ecto.StaleEntryError."

requirements-completed: [PERSIST-01, PERSIST-04, TENANT-01, TENANT-02]

# Metrics
duration: 62min
completed: 2026-04-22
---

# Phase 02 Plan 06: Projector + SuppressionStore + Phase-wide Integration Test Summary

**Phase 2 closed. Mailglass.Outbound.Projector ships the single-writer projection module (D-14) with D-15 monotonic rules + D-18 optimistic locking wired via `optimistic_lock(:lock_version)`. Mailglass.SuppressionStore behaviour + Ecto default impl ship the three-branch OR-union pre-send lookup + idempotent admin-re-add upsert. The phase-wide integration test proves all 5 ROADMAP Phase 2 success criteria + D-09 multi-tenant isolation hold end-to-end. 34 new tests; full suite 212 tests + 2 properties (1 pre-existing Plan 04 flake, 1 skipped).**

## Performance

- **Duration:** 62 min
- **Started:** 2026-04-22T19:28:00Z (immediately after Plan 02-05)
- **Completed:** 2026-04-22T20:30:00Z
- **Tasks:** 3
- **Files created:** 6
- **Files modified:** 2

## Accomplishments

- **`Mailglass.Outbound.Projector.update_projections/2`** is the single entry point for writing `mailglass_deliveries` projection columns. Chains `optimistic_lock(:lock_version)` on every changeset; D-18's concurrent-dispatch race is now demonstrably unreachable (the test "concurrent update on stale delivery raises Ecto.StaleEntryError" proves it).
- **D-15 monotonic rule set** enforced at the Elixir layer via four helper functions in the changeset pipeline. Covered by 7 unit tests: first `:dispatched` sets stamp, second `:dispatched` does NOT overwrite, `:delivered` sets `terminal` to true, late `:opened` preserves both, `:opened` before `:delivered` still lets `:delivered` win its own timestamp, `terminal` never flips back on late `:opened` after `:bounced`, backward `occurred_at` doesn't regress `last_event_at`.
- **Telemetry on every Projector call** — `[:mailglass, :persist, :delivery, :update_projections, :stop]` with `tenant_id` + `delivery_id` metadata. PII-refutation test explicitly asserts the 8 forbidden keys (`:to :from :body :html_body :subject :headers :recipient :email`) never leak (D-31 whitelist).
- **`Mailglass.SuppressionStore` behaviour** exposes exactly two callbacks: `check/2` (pre-send lookup) + `record/2` (add/update). Phase 3's `Mailglass.Suppression.check_before_send/1` will thin-wrap `check/2`.
- **`Mailglass.SuppressionStore.Ecto`** default impl:
  - `check/2` performs the three-branch OR-union query from CONTEXT.md §specifics: address scope + domain scope + (conditionally) address_stream scope, with expiry filter, scoped by `tenant_id`, LIMIT 1.
  - `record/2` upserts with `on_conflict: {:replace, [:reason, :source, :expires_at, :metadata]}, conflict_target: {:unsafe_fragment, "(tenant_id, address, scope, COALESCE(stream, ''))"}` — admin re-adds are idempotent at the Elixir layer.
  - Telemetry on both paths — `[:mailglass, :persist, :suppression, :check | :record, :stop]`.
- **Phase-wide integration test** (`test/mailglass/persistence_integration_test.exs`) proves ALL 5 ROADMAP Phase 2 success criteria hold together in one file with the adopter-facing APIs (no raw SQL tricks). Also proves D-09 multi-tenant isolation via 50+50 events across two tenants with zero cross-tenant reads.
- **ROADMAP §4 block is the Phase 4 webhook Multi template** — literal Ecto.Multi shape Phase 4 will use, with `Events.append_multi + Projector.update_projections` composed and lock_version bump verified.
- Full test suite: **212 tests, 2 properties, 1 failure (pre-existing Plan 04 flake), 1 skipped**.
- Both compile lanes green: `mix compile --warnings-as-errors` and `mix compile --no-optional-deps --warnings-as-errors`.

## Task Commits

1. **Task 1: Outbound.Projector + unit tests (monotonic D-15 + optimistic_lock D-18 + telemetry + PII refutation)** — `85e00cf` (feat)
2. **Task 2: SuppressionStore behaviour + Ecto default impl + unit tests** — `795ffd7` (feat)
3. **Task 3: Phase-wide integration test proving all 5 ROADMAP criteria + D-09 multi-tenant isolation** — `74f052d` (test)

## Files Created

**6 created:**
- `lib/mailglass/outbound/projector.ex` — 124 lines
- `lib/mailglass/suppression_store.ex` — 51 lines
- `lib/mailglass/suppression_store/ecto.ex` — 119 lines
- `test/mailglass/outbound/projector_test.exs` — 241 lines, 11 tests
- `test/mailglass/suppression_store/ecto_test.exs` — 253 lines, 14 tests
- `test/mailglass/persistence_integration_test.exs` — 305 lines, 9 tests

**2 modified:**
- `config/test.exs` — added `disconnect_on_error_codes: [:internal_error]` to mitigate Postgrex type cache poisoning
- `.planning/phases/02-persistence-tenancy/deferred-items.md` — documented the TypeServer cache issue with candidate Phase 6 fixes

## Projector helper breakdown

The D-15 monotonic rules decompose into four changeset-stage helpers (each solves one sub-invariant):

| Helper | Field(s) | Rule | Why |
|---|---|---|---|
| `maybe_set_later_event_type/2` | `:last_event_type` | Always set to incoming event's type (if non-nil) | "Latest event" pointer, not a lifecycle fact — the caller's last observation wins. |
| `maybe_set_later_at/2` | `:last_event_at` | Monotonic max: only advance if incoming `occurred_at > current` | Handles out-of-order provider webhooks without regressing the observation window. |
| `maybe_set_once_timestamp/2` | `:dispatched_at` / `:delivered_at` / `:bounced_at` / `:complained_at` / `:suppressed_at` | Set ONCE when the matching type arrives; never overwrite | Lifecycle facts — the first occurrence of a kind is the authoritative timestamp. |
| `maybe_flip_terminal/2` | `:terminal` | One-way latch: false → true on terminal event types; never reverses | Terminal state is sticky — a late `:opened` after `:bounced` leaves `terminal: true`. |

The `timestamp_field_for/1` dispatch table maps event type atoms to their projection columns:

```elixir
defp timestamp_field_for(:dispatched), do: :dispatched_at
defp timestamp_field_for(:delivered), do: :delivered_at
defp timestamp_field_for(:bounced), do: :bounced_at
defp timestamp_field_for(:complained), do: :complained_at
defp timestamp_field_for(:suppressed), do: :suppressed_at
defp timestamp_field_for(_), do: nil
```

Non-lifecycle events (`:queued`, `:opened`, `:clicked`, `:deferred`, `:sent`, …) fall through cleanly to `nil` and don't touch any projection timestamp — only `last_event_type` and `last_event_at` move.

Every returned changeset ends with `Ecto.Changeset.optimistic_lock(:lock_version)` (D-18). Concurrent dispatchers racing on the same delivery get `Ecto.StaleEntryError` on the loser; Phase 3 will add the single-retry.

## SuppressionStore.Ecto `check/2` query shape + index consumption

The three-branch OR-union from CONTEXT.md §specifics:

```elixir
# Pseudo-Elixir — see lib/mailglass/suppression_store/ecto.ex for the real fragments.
from(e in Entry,
  where: e.tenant_id == ^tenant_id,
  where: is_nil(e.expires_at) or e.expires_at > ^now,
  where:
    (e.scope == :address and e.address == ^address) or
    (e.scope == :domain and e.address == ^recipient_domain) or
    (e.scope == :address_stream and e.address == ^address and e.stream == ^stream),
  limit: 1
)
```

Factored into two `union_predicates/4` clauses at the Elixir layer to avoid Ecto's compile-time `e.stream == ^nil` refusal:
- `union_predicates(base, addr, domain, nil)` — drops the `:address_stream` branch (stream-less callers can't match stream-scoped entries anyway).
- `union_predicates(base, addr, domain, stream)` — includes all three branches.

Index usage:
- `mailglass_suppressions_tenant_address_scope_idx` (UNIQUE, Plan 02) — supports the upsert in `record/2` (`conflict_target` matches character-for-character). Also helps the `address`-scope + `address_stream`-scope branches of `check/2` because `(tenant_id, address)` is a prefix.
- `mailglass_suppressions_tenant_address_idx` (Plan 02) — secondary index for the `domain`-scope branch where the query compares `address = recipient_domain`.
- `mailglass_suppressions_expires_idx` (Plan 02, partial WHERE `expires_at IS NOT NULL`) — supports the expiry filter efficiently for tenants that heavily use time-bounded suppressions.

Postgres's planner chooses per-branch execution plans; the three-OR union stays efficient up to the adopter's table size.

## Phase 4 hook points (webhook handler Multi shape)

The ROADMAP §4 integration test encodes the exact Multi shape Phase 4 will adopt. Copy/paste template:

```elixir
multi =
  Ecto.Multi.new()
  |> Mailglass.Events.append_multi(:event, event_attrs)
  |> Ecto.Multi.run(:delivery_update, fn _repo, %{event: event} ->
    cond do
      is_nil(delivery) ->
        # Orphan: event inserted with needs_reconciliation: true,
        # delivery_id: nil (Phase 4's Mailglass.Webhook.Plug orphan branch).
        {:ok, :orphan}

      is_nil(event.inserted_at) ->
        # Replay: inserted_at: nil is the sentinel for ON CONFLICT DO NOTHING
        # per Plan 05 moduledoc.
        {:ok, :replayed}

      true ->
        delivery
        |> Mailglass.Outbound.Projector.update_projections(event)
        |> Mailglass.Repo.update()
    end
  end)

Mailglass.Repo.transact(fn -> TestRepo.transaction(multi) end)
```

Phase 4's webhook plug composes the event attrs from provider payload + calls this Multi. SQLSTATE 45A01 translation fires if the plug ever mistakenly `Repo.update`s an event row — `Mailglass.Repo.update/2` in the Projector step catches it.

## Phase 3 hook points

- **`Mailglass.Outbound.deliver/2` preflight** calls `Mailglass.Suppression.check_before_send/1` (thin wrapper added in Phase 3 over `SuppressionStore.check/2`). On `{:suppressed, entry}` return, `deliver/2` short-circuits with a `%SuppressedError{}` — no send, no event, no delivery row.
- **`Mailglass.Outbound.deliver/2` dispatch path** wraps `Projector.update_projections` + `Events.append_multi` in `Mailglass.Repo.transact/1` so dispatch+event is atomic. On `Ecto.StaleEntryError` (concurrent dispatcher raced), Phase 3 adds a single retry with a fresh reload of the delivery.
- **`Mailglass.Outbound.deliver_later/2`** enqueues an Oban job that calls through the same Multi. The `Mailglass.Oban.TenancyMiddleware.wrap_perform/2` from Plan 04 restores the tenant context; inside the worker body, `Tenancy.current/0` returns the stamped value.

## Integration-test findings

- **`Mailglass.Repo.transact(fn -> TestRepo.transaction(multi) end)` wrapping pattern works in the happy path** — the test ROADMAP §4 block uses `TestRepo.transaction(multi)` directly (not wrapped in `Repo.transact`) because the test's assertion is on the happy-path return `{:ok, %{event: _, delivery_update: _}}`. Phase 3 and Phase 4 will adopt the wrapper pattern for SQLSTATE 45A01 translation on error paths; the normalized-return adapter (Multi 4-tuple → 2-tuple) is called out in Plan 05's summary as a Plan 06 deliverable but was deferred to Phase 3 per the same summary's scope decision. The Plan 06 integration test demonstrates the shape cleanly; the normalized-return wrapper lands in Phase 3's Outbound module alongside the first real mixed-failure-mode Multi.
- **Postgrex type cache under migration_test** — pre-existing architectural issue between migration_test.exs's down-then-up test and any subsequent test using citext via the shared connection pool. Plan 06 ships a per-test probe-and-disconnect mitigation (see Deviations). Full resolution deferred to Phase 6 with four candidate fixes documented in deferred-items.md.

## Phase 2 exit checklist

| # | ROADMAP criterion | Proof | Status |
|---|---|---|---|
| 1 | `assert_raise EventLedgerImmutableError` on UPDATE + DELETE | `test/mailglass/events_immutability_test.exs` (Plan 02) + `test/mailglass/persistence_integration_test.exs §1` (this plan) | ✓ green |
| 2 | StreamData 1000-sequence idempotency convergence | `test/mailglass/properties/idempotency_convergence_test.exs` (Plan 05) + integration §2 sanity coupling (this plan) | ✓ green |
| 3 | 3 schemas with `tenant_id` + SingleTenant default | Plan 03 per-schema tests + `test/mailglass/tenancy_test.exs` (Plan 04) + integration §3 (this plan) | ✓ green |
| 4 | `Events.append` is the only write path (D-02 revision: lint-time) | Plan 05 ships `append/1` + `append_multi/3`; integration §4 (this plan) exercises both; Phase 6 LINT-XX `NoRawEventInsert` enforces at lint time | ✓ green (runtime); Phase 6 adds lint-time backstop |
| 5 | `Mailglass.Migration` brings schemas into existence | Plan 02 migration tests + integration §5 (this plan) | ✓ green |

| Other invariants | Proof | Status |
|---|---|---|
| D-09 multi-tenant isolation | integration "Multi-tenant isolation (D-09)" block — 50 events per tenant, zero cross-tenant reads | ✓ green |
| D-14 single projector module | `Mailglass.Outbound.Projector` is the only module with `update_projections/2`; Phase 6 `NoProjectorOutsideOutbound` lint check will enforce | ✓ green (runtime); Phase 6 adds lint-time backstop |
| D-15 monotonic projection rules | `test/mailglass/outbound/projector_test.exs` (7 scenarios: first-dispatched, duplicate-dispatched, delivered-flips-terminal, late-opened, opened-before-delivered, terminal-sticky, backward-occurred_at) | ✓ green |
| D-18 optimistic locking | `test/mailglass/outbound/projector_test.exs "lock_version bumps"` + `"concurrent update raises Ecto.StaleEntryError"` | ✓ green |
| D-31 telemetry PII whitelist | Projector + SuppressionStore tests explicitly refute the 8 forbidden keys | ✓ green |

## Decisions Made

### Projector `last_event_type` updates unconditionally on every event

D-15 says "monotonic app-level rule" but only for LIFECYCLE facts (timestamps + terminal). `last_event_type` is a "what was the latest event" pointer, not a lifecycle fact — it advances on every incoming event regardless of type. The test `non-monotonic ordering: :opened BEFORE :delivered` demonstrates: `:opened` arrives → `last_event_type: :opened`; then `:delivered` arrives → `last_event_type: :delivered`. If a reviewer questions why `:opened` gets recorded as the last type when `:delivered` hasn't arrived yet, it's because the projector faithfully records the latest observation; D-15's monotonicity is about NOT losing lifecycle facts, not about ordering `last_event_type`.

### SuppressionStore.Ecto `union_predicates/4` split by stream presence

Ecto refuses compile-time `e.stream == ^nil` with "comparing with nil is forbidden as it is unsafe — use is_nil/1 instead". Two options: (a) build the predicate dynamically with `dynamic/2` macros + conditional logic, or (b) split into two function clauses matching stream-or-nil at function head. Chose (b) — cleaner, the with-stream clause is obviously correct, and the stream-less caller can't match `:address_stream`-scoped entries by definition so dropping that branch is correct behaviour (not a workaround). Comment in the module explains.

### Per-test `probe_until_clean/5` instead of global TypeServer kill

Three approaches tried before settling:
1. **`setup_all` restart TestRepo.** Broke subsequent tests with "could not lookup Ecto repo ... because it was not started" — Ecto registry doesn't re-register on restart.
2. **Kill all `Postgrex.TypeServer` processes.** Cascaded into `DBConnection.ConnectionError "awaited on another connection that failed to bootstrap types"` across the property test + DataCase-using tests. The shared TypeServer is load-bearing for in-flight bootstrap attempts.
3. **`disconnect_all` on underlying pool via `GenServer.call(manager, :pool)`.** Still got stale types because the disconnected workers re-fetched from the same stale TypeServer.
4. **Final: per-test `probe_until_clean/5` + `disconnect_on_error_codes: [:internal_error]` config.** Probe issues `SELECT address FROM mailglass_suppressions LIMIT 1` up to 5 times. Poisoned workers error once, auto-disconnect, sandbox grabs a replacement; clean workers succeed immediately. Surgical and sufficient.

### `Mailglass.SuppressionStore` has `record/2` not `record/1`

Plan CONTEXT.md §"Claude's Discretion" wrote `check/2 + record/1`. Widened `record` to 2-arity (`record_attrs, keyword()`) for symmetry with `check/2` and to give adopters an `opts` seam for future work (prefix, custom conflict targets, audit hooks). The plan's test bodies passed `Store.record(attrs)` everywhere, which still works because the impl declares `def record(attrs, opts \\ [])`. No adopter-visible change; the behaviour is more flexible.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Ecto refuses `e.stream == ^nil` at query-build time**

- **Found during:** Task 2 test run.
- **Issue:** Plan's verbatim `check/2` query had `(e.scope == :address_stream and e.address == ^address and e.stream == ^stream)`. When the caller passes no `:stream` in the lookup key, `stream = Map.get(key, :stream)` returns `nil`, and Ecto refuses: `ArgumentError: comparing e.stream with nil is forbidden as it is unsafe. If you want to check if a value is nil, use is_nil/1 instead`.
- **Fix:** Split into two private `union_predicates/4` clauses — one for `stream = nil` (drops the `:address_stream` branch entirely, since a stream-less caller has no basis to match stream-scoped entries), one for `stream = atom` (includes all three branches). Comment in the module explains why.
- **Files modified:** `lib/mailglass/suppression_store/ecto.ex`
- **Verification:** `mix test test/mailglass/suppression_store/ecto_test.exs --warnings-as-errors` → 14 tests, 0 failures.
- **Committed in:** `795ffd7` (Task 2).

**2. [Rule 3 — Blocking] Postgrex type cache stale after migration_test.exs down-then-up poisons subsequent test runs**

- **Found during:** Task 3 full-suite run.
- **Issue:** `test/mailglass/migration_test.exs "drops all three tables + trigger + function + citext in reverse order"` runs `Ecto.Migrator.run(..., :down, all: true)` + `:up, all: true`, which drops and recreates the `citext` extension. Postgres gives the recreated extension a fresh OID. The Postgrex connection pool's workers AND the shared `Postgrex.TypeServer` retain the pre-drop OID in their type caches. Any subsequent test that queries `mailglass_suppressions.address` (:citext) through a poisoned worker surfaces as `(Postgrex.Error) ERROR XX000 (internal_error) cache lookup failed for type NNNNNN`.
- **Fix (two-part mitigation):**
  1. `config/test.exs` adds `disconnect_on_error_codes: [:internal_error]` to the Mailglass.TestRepo config. Postgrex now auto-disconnects any worker that hits the stale-OID error; the next checkout reconnects with a fresh type bootstrap.
  2. `test/mailglass/persistence_integration_test.exs` adds a per-test `probe_until_clean/5` helper that issues `SELECT address FROM mailglass_suppressions LIMIT 1` up to 5 times. Poisoned workers fail the probe (triggering the disconnect-on-error above), clean workers succeed immediately. By the time each test body runs, the sandbox-owned worker is guaranteed clean.
- **Files modified:** `config/test.exs`, `test/mailglass/persistence_integration_test.exs`
- **Rejected alternatives:** (a) stopping + restarting the TestRepo in `setup_all` (registry loses Ecto's repo lookup), (b) killing all `Postgrex.TypeServer` processes (cascades into unrelated tests), (c) calling `Ecto.Adapters.SQL.disconnect_all/3` through the sandbox manager (intercepts the call with FunctionClauseError), (d) calling `DBConnection.disconnect_all/3` on the underlying pool directly (workers reconnect but re-fetch from the same stale TypeServer).
- **Deferred follow-up:** logged in `.planning/phases/02-persistence-tenancy/deferred-items.md` with 4 candidate Phase 6 architectural fixes (migrate off citext, narrow migration_test's scope, use `Sandbox.unboxed_run`, or `on_exit(:suite)` TestRepo restart).
- **Committed in:** `74f052d` (Task 3).

### Deferred Issues

**Pre-existing flaky test from Plan 04** — `test/mailglass/tenancy_test.exs:116` (`function_exported?/3` race condition). Failing ~1 in 3 runs under full suite. Logged in `deferred-items.md` since Plan 05. Fix is trivial (add `Code.ensure_loaded?/1` guard) but out-of-scope for Plan 06 per SCOPE BOUNDARY rule.

---

**Total deviations:** 2 auto-fixed (1 bug in plan-verbatim query build, 1 blocking test-infra interaction). Neither is architectural — both ship workable fixes in-band. The Projector and SuppressionStore modules themselves land exactly per the plan's `<projector_reference>` + CONTEXT.md §specifics.

**Impact on plan:** None to the shipping API surface. The `union_predicates/4` factoring is an internal implementation detail — the `check/2` contract and semantics are unchanged from the plan's spec. The pool-poisoning mitigation is test-infrastructure only; production adopters are unaffected (`disconnect_on_error_codes` is a per-repo config; the default `[]` is restored for adopters who don't configure it).

## Issues Encountered

Beyond the two deviations, no other issues. The Projector landed verbatim from the RESEARCH §Pattern 4 template; the SuppressionStore.Ecto landed from CONTEXT.md §specifics with one Ecto compatibility fix. The integration test revealed the Postgrex TypeServer issue when combining with the pre-existing migration_test down-then-up — a real Phase 6 architectural cleanup candidate.

## Downstream Landmines Flagged for Future Plans

- **Phase 3 (Outbound.deliver/2):**
  - Wraps `Projector.update_projections` + `Events.append_multi` in a single `Repo.transact`. Needs the "normalized-return wrapper" to collapse `Ecto.Multi.transaction/1`'s 4-tuple error into `Repo.transact/1`'s 2-tuple — Plan 05's summary calls this out as a Plan 06 deliverable; Plan 06 deferred it because Plan 06's integration test uses the happy-path `TestRepo.transaction(multi)` directly. Phase 3 is the right place to ship the wrapper alongside the first real mixed-failure-mode Multi (delivery lookup can 404, event changeset can be invalid, projector update can stale-entry).
  - On `Ecto.StaleEntryError` from optimistic_lock, Phase 3 dispatch worker reloads the Delivery and retries ONCE. D-18's rule: one retry, then fail-loud.
  - Preflight calls `Mailglass.Suppression.check_before_send/1` (thin wrapper over `SuppressionStore.check/2`). On `{:suppressed, entry}`, deliver/2 returns `{:error, %SuppressedError{}}` — Phase 3 adds this public function; Phase 2 ships the underlying SuppressionStore.
  - `deliver_later/2` enqueues Oban job; `Mailglass.Oban.TenancyMiddleware.wrap_perform/2` from Plan 04 restores tenant context; job body calls `deliver/2`.
- **Phase 4 (Webhook + Reconciler):**
  - Webhook plug composes the exact Multi shape documented in this plan's integration test ROADMAP §4 block. Copy/paste template is in the "Phase 4 hook points" section above.
  - `Mailglass.Oban.Reconciler.perform/1` wraps `Events.Reconciler.find_orphans/1` + `Events.Reconciler.attempt_link/2` + `Projector.update_projections/2` (per D-21: immutable events mean "reconciled" is a new event INSERT, not an update to the orphan).
  - The `disconnect_on_error_codes` config in `config/test.exs` is test-only; Phase 4 tests that touch citext follow the same pattern (probe-and-disconnect) when they compose with migration_test in the same suite.
- **Phase 5 (Admin LiveView):**
  - Admin "suppression list" table is backed by a `Mailglass.Suppression` context function that thin-wraps `SuppressionStore.check/2` + a list query. Plan 06 ships the underlying store; the admin context lands in Phase 5 alongside the LiveView.
  - "Deliveries by status" dashboard filters on `Delivery.terminal` + `Delivery.last_event_type` — those columns are the Projector's output. Phase 5 doesn't touch the Projector; it reads the projection.
- **Phase 6 (Custom Credo + Boundary):**
  - `NoProjectorOutsideOutbound` Credo check (D-14 enforcement) — AST match: `Repo.update(%Delivery{}, ...)` or `Mailglass.Repo.update(changeset_on_delivery, ...)` outside `lib/mailglass/outbound/projector.ex`.
  - `NoRawSuppressionStoreInLib` (extension of the D-14 pattern) — only `Mailglass.SuppressionStore` implementations and `Mailglass.Suppression.check_before_send/1` (Phase 3) can call `SuppressionStore.check/2` directly.
  - Fix the Postgrex TypeServer cache issue via one of the 4 candidate fixes in `deferred-items.md`. The `disconnect_on_error_codes` mitigation works but is a band-aid; resolving the underlying migration_test-vs-pool interaction is a Phase 6 CI hardening task.
  - Fix the pre-existing `tenancy_test.exs:116` flaky test (`function_exported?` race — add `Code.ensure_loaded?/1` guard).

## Threat Surface Scan

All Plan 06 threat register dispositions hold:

- **T-02-01 (Projector late-event / reordered-event handling) — mitigated.** Six test scenarios cover late-opened, opened-before-delivered, opened-after-bounced, duplicate-dispatched, backward-occurred_at, terminal-sticky.
- **T-02-02a (Projector optimistic lock bypass) — mitigated.** `optimistic_lock(:lock_version)` chained on every changeset; Phase 6 `NoProjectorOutsideOutbound` backstop planned. Stale-entry test proves the lock fires.
- **T-02-05a (SuppressionStore cross-tenant leak) — mitigated.** `check/2` REQUIRES `tenant_id` in lookup_key (function-head match); query's leading `where: e.tenant_id == ^tenant_id` + the Plan 02 UNIQUE index on `(tenant_id, address, scope, ...)` means cross-tenant rows never alias. Integration test "Multi-tenant isolation" proves explicitly.
- **T-02-05b (SuppressionStore upsert conflict target) — mitigated.** `conflict_target` is `(tenant_id, address, scope, COALESCE(stream, ''))` — matches the Plan 02 UNIQUE index character-for-character. Admin re-adds for same tenant replace mutable fields; cross-tenant rows with same address never collide.
- **T-02-01b (Tenancy.scope/2 default) — accepted.** SingleTenant resolver is a no-op; adopter resolvers inject `WHERE tenant_id = ?`. Integration test ROADMAP §3 proves `current/0` returns `"default"` when unstamped. Phase 6 `NoUnscopedTenantQueryInLib` Credo check planned as architectural enforcement.
- **T-02-06 (Telemetry metadata) — mitigated.** Projector span metadata: `tenant_id` + `delivery_id` (both in D-31 whitelist). SuppressionStore span metadata: `tenant_id`. PII-refutation test explicit in projector_test.exs.
- **T-02-13 (Reconciler DoS) — mitigated.** Out of scope for Plan 06; Plan 05's Reconciler tests prove `find_orphans/1` caps results via `:limit` and `:max_age_minutes`.

No new security-relevant surface introduced beyond the plan's documented `<threat_model>`. No threat flags.

## Next Phase Readiness

- `mix compile --warnings-as-errors` passes.
- `mix compile --no-optional-deps --warnings-as-errors` passes.
- `mix test --warnings-as-errors` → 212 tests, 2 properties, 1 failure (pre-existing Plan 04 flake in deferred-items.md), 1 skipped.
- All 3 Plan 06 tasks complete; Phase 2 is closed.
- `Mailglass.Outbound.Projector.update_projections/2` ready for Phase 3 dispatch + Phase 4 webhook ingest consumption.
- `Mailglass.SuppressionStore` behaviour + Ecto default impl ready for Phase 3 Outbound preflight (`Mailglass.Suppression.check_before_send/1` thin wrapper).
- ROADMAP Phase 2 criteria 1-5 all proven end-to-end; D-09 multi-tenant isolation proven in the capstone integration test.
- Phase 3 (Transport + Send Pipeline) is unblocked.

## Self-Check: PASSED

All 6 created files exist on disk:
- `lib/mailglass/outbound/projector.ex`
- `lib/mailglass/suppression_store.ex`
- `lib/mailglass/suppression_store/ecto.ex`
- `test/mailglass/outbound/projector_test.exs`
- `test/mailglass/suppression_store/ecto_test.exs`
- `test/mailglass/persistence_integration_test.exs`

All 3 task commits present in `git log --oneline`:
- `85e00cf` (Task 1 feat)
- `795ffd7` (Task 2 feat)
- `74f052d` (Task 3 test)

---
*Phase: 02-persistence-tenancy*
*Completed: 2026-04-22*
