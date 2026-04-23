---
phase: 03-transport-send-pipeline
plan: "02"
subsystem: adapter-layer
tags: [adapter, fake, swoosh, pubsub, tdd, wave-2, d-13]
dependency_graph:
  requires: [phase-01-core, phase-02-persistence-tenancy, 03-01]
  provides:
    - Mailglass.Adapter behaviour (single @callback deliver/2, TRANS-01)
    - Mailglass.Adapters.Fake + Storage GenServer + Supervisor (TRANS-02, D-13 merge gate)
    - Mailglass.Adapters.Swoosh wrapper (TRANS-03)
    - Mailglass.Outbound.Projector.broadcast_delivery_updated/3 (SEND-05, D-04)
    - api_stability.md §Adapter + §Fake + §Projector.broadcast sections
  affects:
    - Plan 05 (Outbound.send/2 dispatches to adapters)
    - Plan 06 (TestAssertions reads Fake ETS surface)
    - Phase 4 (Webhook plug calls broadcast_delivery_updated/3 after commit)
tech_stack:
  added: []
  patterns:
    - "Swoosh.Adapters.Sandbox ownership pattern ($callers + allow-list + shared fallback)"
    - "ETS named table keyed by owner pid for per-process inbox isolation"
    - "GenServer monitors owner pids for auto-cleanup on DOWN"
    - "safe_broadcast/2 try/rescue for best-effort PubSub fan-out (D-04)"
    - "Swoosh.Adapter.deliver/2 direct call (not Mailer.deliver/1 — LINT-01)"
    - "dispatch_span/2 wraps every Swoosh adapter call for telemetry"
key_files:
  created:
    - lib/mailglass/adapter.ex
    - lib/mailglass/adapters/swoosh.ex
    - lib/mailglass/adapters/fake.ex
    - lib/mailglass/adapters/fake/storage.ex
    - lib/mailglass/adapters/fake/supervisor.ex
    - test/mailglass/adapter_test.exs
    - test/mailglass/adapters/swoosh_test.exs
    - test/mailglass/adapters/fake_test.exs
    - test/mailglass/adapters/fake_concurrency_test.exs
    - test/mailglass/outbound/projector_broadcast_test.exs
  modified:
    - lib/mailglass/outbound/projector.ex (added broadcast_delivery_updated/3)
    - test/mailglass/application_test.exs (un-skipped Fake.Supervisor presence test)
    - docs/api_stability.md (§Adapter + §Fake + §Projector.broadcast sections)
decisions:
  - "broadcast_delivery_updated/3 implemented in Task 2 (not Task 3) because Fake.trigger_event/3 calls it — the two tasks are interdependent; Task 3 adds only the projector_broadcast_test.exs"
  - "Fake.Storage checkout is idempotent (already-checked-out returns :ok not error) — matches Swoosh.Adapters.Sandbox.Storage but removes the {:error, :already_checked_out} error that would break setup idempotency"
  - "Test 5 (no-owner raises) uses spawn/1 not Task.async — Task.async sets $callers to [parent_pid] which resolves to the test owner; bare spawn has no $callers"
  - "normalized_payload/raw_payload in Test 13 use string keys — JSONB columns in Postgres deserialize with string keys; atom keys must not be asserted"
  - "Fake.Storage.allow/2 does not require owner to be checked out (unlike Swoosh.Sandbox) — more permissive to support allow-before-checkout patterns in LiveView hooks"
  - "Task 2 commit includes Projector.broadcast_delivery_updated/3 because Fake.trigger_event/3 calls it; deferring to Task 3 would leave Task 2 uncompilable"
metrics:
  duration: "19min"
  completed: "2026-04-23"
  tasks: 3
  files_created: 10
  files_modified: 3
---

# Phase 3 Plan 02: Adapter Layer + Fake Gate + Projector Broadcast Summary

**One-liner:** Mailglass.Adapter behaviour + Swoosh bridge with non-PII error normalization + Fake in-memory adapter (D-13 merge gate) with ETS ownership, trigger_event real write path, and Projector.broadcast_delivery_updated/3 post-commit PubSub fan-out.

## What Shipped

### Task 1: Mailglass.Adapter + Mailglass.Adapters.Swoosh

**`Mailglass.Adapter`** — single-callback behaviour (TRANS-01):
```elixir
@callback deliver(Mailglass.Message.t(), keyword()) ::
            {:ok, %{message_id: String.t(), provider_response: term()}} | {:error, Mailglass.Error.t()}
```

**`Mailglass.Adapters.Swoosh`** — bridge to any `Swoosh.Adapter` (TRANS-03):
- Calls `Swoosh.Adapter.deliver/2` directly (never `Swoosh.Mailer.deliver/1` — LINT-01)
- Maps `{:api_error, status, body}` → `%SendError{type: :adapter_failure, context: %{provider_status, body_preview (200B), provider_module, reason_class}}`
- Maps `{:error, :timeout}` → `reason_class: :transport`
- Synthetic `message_id` via `:crypto.strong_rand_bytes(16)` when provider returns no `:id`
- `dispatch_span/2` wraps every call for `[:mailglass, :outbound, :dispatch, :*]` telemetry
- PII policy enforced: 8 forbidden keys never appear in error context (property-tested over 50 error shapes)

### Task 2: Mailglass.Adapters.Fake + Storage + Supervisor

**`Mailglass.Adapters.Fake`** — in-memory adapter (TRANS-02, D-13 merge gate):
- Mirrors `Swoosh.Adapters.Sandbox` ownership model verbatim
- Records `%{message, delivery_id, provider_message_id, recorded_at}` per delivery
- `$callers` inheritance: `Task.async` child processes deliver automatically
- Explicit `allow/2` for LiveView/Oban worker cross-process delegation
- `set_shared/1` for global non-async E2E test mode
- `trigger_event/3` uses real `Events.append_multi/3 + Projector.update_projections/2` write path (D-03)
- `advance_time/1` delegates to `Clock.Frozen.advance/1`

**`Mailglass.Adapters.Fake.Storage`** — ETS + GenServer:
- Table `:mailglass_fake_mailbox` — `[:set, :named_table, :public, {:read_concurrency, true}]`
- Monitors owner pids; `{:DOWN, ...}` handler auto-checkins + deletes ETS bucket
- Divergences from `Swoosh.Adapters.Sandbox.Storage`: table name, stored value (full record map), `send(owner_pid, {:mail, msg})` not `{:email, email}`

**`Mailglass.Adapters.Fake.Supervisor`** — unconditionally started:
- Picked up automatically by `Mailglass.Application`'s `Code.ensure_loaded?/1` gate (I-08)
- No edit to `application.ex` required (confirmed by application test)

### Task 3: Projector.broadcast_delivery_updated/3

Added to `Mailglass.Outbound.Projector` (Phase 2 module, NOT breaking):
- Broadcasts `{:delivery_updated, delivery_id, event_type, meta}` to BOTH:
  - `Topics.events(tenant_id)` — tenant-wide stream
  - `Topics.events(tenant_id, delivery_id)` — per-delivery stream
- Best-effort: `safe_broadcast/2` wraps in `try/rescue` — never rolls back on PubSub failure
- `update_projections/2` signature unchanged — Phase 2 test suite green

### api_stability.md Updates

Three new sections:
- `§Adapter` — locked `deliver/2` callback signature + return shape contract
- `§Fake` — stored record shape, public API table, ETS table name, trigger_event/3 write-path guarantee, ownership model
- `§Projector.broadcast_delivery_updated` — locked signature, payload shape, broadcast topics, caller list

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Task 2 depends on broadcast_delivery_updated/3 from Task 3**

- **Found during:** Task 2 compilation — `Fake.trigger_event/3` calls `Projector.broadcast_delivery_updated/3` which doesn't exist yet.
- **Fix:** Implemented `broadcast_delivery_updated/3` as part of Task 2 commit. Task 3 then added only its own test file (`projector_broadcast_test.exs`).
- **Files modified:** `lib/mailglass/outbound/projector.ex` (Task 2 commit `e3a6288`)

**2. [Rule 1 - Bug] Test 5 "no owner raises" used Task.async which inherits $callers**

- **Found during:** Task 2 test run — `Task.async` sets `Process.get(:"$callers")` to `[parent_pid]`, so ownership resolution succeeds via the parent (which IS checked out), meaning the test never triggered the error.
- **Fix:** Replaced `Task.async/1` with bare `spawn/1` which has no `$callers`. Used send/receive pattern to get the result back.
- **Files modified:** `test/mailglass/adapters/fake_test.exs`

**3. [Rule 1 - Bug] Test 13 asserted atom keys on JSONB-deserialized payload**

- **Found during:** Task 2 test run — `event.normalized_payload.reject_reason` fails because Postgres JSONB deserializes to string keys. Assertion `event.normalized_payload.reject_reason == :bounced` fails as `"reject_reason"` key + `"bounced"` string value.
- **Fix:** Changed assertion to `event.normalized_payload["reject_reason"] == "bounced"` and `event.raw_payload == %{"raw" => "bounce body"}`.
- **Files modified:** `test/mailglass/adapters/fake_test.exs`

**4. [Rule 1 - Bug] Fake.Storage.allow/2 doesn't require owner to be checked out**

- **Found during:** Task 2 Test 6 design — Swoosh.Sandbox.Storage.allow/2 returns `{:error, :not_checked_out}` if the owner isn't registered. This would break LiveView/Playwright patterns where `allow/2` is called at plug time before the test checkout completes.
- **Fix:** Implemented `allow/2` without the owner-must-be-checked-out guard — more permissive, matches real-world LiveView sandbox usage.
- **Files modified:** `lib/mailglass/adapters/fake/storage.ex`

## Pre-existing Issues (Out of Scope)

Two pre-existing test failures exist in the full suite that are NOT introduced by this plan:

1. `Mailglass.TenancyTest` — `SingleTenant implements @behaviour Mailglass.Tenancy` — `function_exported?(Mailglass.Tenancy.SingleTenant, :scope, 2)` returns false. Pre-existing before Plan 02; deferred to `.planning/phases/03-transport-send-pipeline/deferred-items.md`.

2. `Mailglass.PersistenceIntegrationTest` — two tests fail intermittently in full-suite runs (pass in isolation). Known Postgrex type-cache staleness issue after citext extension recreation. Documented in Plan 02-06 deferred items.

## Known Stubs

None — all public API functions are fully implemented. `Projector.broadcast_delivery_updated/3` is complete; `trigger_event/3` uses the real write path.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: ets_cross_tenant | lib/mailglass/adapters/fake/storage.ex | :mailglass_fake_mailbox is a public ETS table readable by any process. Isolation is by owner pid (process), not tenant. T-3-02-01 mitigated by Test 14 (50 parallel processes, zero cross-process leakage). |

## Self-Check: PASSED

Files created/present:
- lib/mailglass/adapter.ex ✓
- lib/mailglass/adapters/swoosh.ex ✓
- lib/mailglass/adapters/fake.ex ✓
- lib/mailglass/adapters/fake/storage.ex ✓
- lib/mailglass/adapters/fake/supervisor.ex ✓
- lib/mailglass/outbound/projector.ex (broadcast_delivery_updated added) ✓
- test/mailglass/adapter_test.exs ✓
- test/mailglass/adapters/swoosh_test.exs ✓
- test/mailglass/adapters/fake_test.exs ✓
- test/mailglass/adapters/fake_concurrency_test.exs ✓
- test/mailglass/outbound/projector_broadcast_test.exs ✓
- docs/api_stability.md (§Adapter + §Fake + §Projector.broadcast) ✓

Commits:
- e956fca: feat(03-02): Mailglass.Adapter behaviour + Adapters.Swoosh wrapper ✓
- e3a6288: feat(03-02): Fake adapter + Storage GenServer + Supervisor + Projector broadcast ✓
- 37f8e76: test(03-02): Projector.broadcast_delivery_updated/3 integration tests ✓

Test counts:
- adapter_test.exs: 4 tests, 0 failures
- swoosh_test.exs: 10 tests, 0 failures
- fake_test.exs: 18 tests, 0 failures
- fake_concurrency_test.exs: 1 test, 0 failures
- projector_broadcast_test.exs: 6 tests, 0 failures
- projector_test.exs (Phase 2, unchanged): 11 tests, 0 failures
- Total plan-02 tests: 49 tests, 0 failures
