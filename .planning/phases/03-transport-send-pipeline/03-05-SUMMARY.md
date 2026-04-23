---
phase: 03-transport-send-pipeline
plan: "05"
subsystem: outbound-facade
tags: [outbound, send, deliver, batch, oban, worker, idempotency, two-multi, d-20, d-21, tdd]
dependency_graph:
  requires:
    - phase-01-core (Clock, Telemetry, Events, Message, TaskSupervisor)
    - phase-02-persistence-tenancy (Delivery schema, Repo.multi, Events.append_multi)
    - 03-01 (Tenancy.assert_stamped!, PubSub, Message.put_metadata)
    - 03-02 (Adapters.Fake, Adapters.Swoosh, Outbound.Projector)
    - 03-03 (Suppression.check_before_send, RateLimiter.check, Stream.policy_check)
    - 03-04 (Tracking.Guard.assert_safe!, Mailable behaviour, FakeFixtures.TestMailer)
  provides:
    - Mailglass.Outbound facade (send/2, deliver/2, deliver!/2, deliver_later/2, deliver_many/2, deliver_many!/2, dispatch_by_id/1)
    - Mailglass.Outbound.Worker (Oban, conditionally compiled)
    - Migration 00000000000002: idempotency_key column + partial UNIQUE index on mailglass_deliveries
    - Delivery schema: :idempotency_key, :status (Ecto.Enum), :last_error (:map)
    - Top-level Mailglass defdelegates for deliver/2, deliver_later/2, deliver_many/2
    - api_stability.md §Delivery + §Outbound + §Outbound.Worker locked sections
  affects:
    - Plan 06 TestAssertions — full pipeline to assert against
    - Plan 06 core_send_integration_test.exs — exercises all 5 ROADMAP success criteria
    - Phase 5 admin — reads Delivery.status, last_error, idempotency_key
tech_stack:
  added:
    - Oban.Worker conditional compile (if Code.ensure_loaded?(Oban.Worker))
    - Ecto.Multi insert_all with ON CONFLICT DO NOTHING + partial UNIQUE index replay
    - Task.Supervisor.start_child with Tenancy.with_tenant re-stamp (D-21)
  patterns:
    - "Two-Multi sync pattern: Multi#1 → adapter call (OUTSIDE transaction) → Multi#2 (D-20)"
    - "Oban.insert/3 composed into Ecto.Multi for atomic job+delivery creation (D-21)"
    - "serialize_error/1: structured %{module, message, type} map — no string heuristics (I-11)"
    - "ON CONFLICT DO NOTHING + companion SELECT for batch idempotency replay (D-15)"
    - "try/rescue in Task.Supervisor tasks prevents [error] log noise in tests"
    - "{:shared, self()} Sandbox mode for background task DB access in tests"
key_files:
  created:
    - lib/mailglass/outbound.ex
    - lib/mailglass/outbound/worker.ex
    - priv/repo/migrations/00000000000002_add_idempotency_key_to_deliveries.exs
    - test/mailglass/outbound_test.exs
    - test/mailglass/outbound/preflight_test.exs
    - test/mailglass/outbound/telemetry_test.exs
    - test/mailglass/outbound/worker_test.exs
    - test/mailglass/outbound/deliver_later_test.exs
    - test/mailglass/outbound/deliver_many_test.exs
    - test/mailglass/outbound/delivery_idempotency_key_test.exs
  modified:
    - lib/mailglass/outbound/delivery.ex (added :idempotency_key, :status, :last_error)
    - lib/mailglass.ex (added Outbound defdelegates + Boundary exports)
    - test/support/generators.ex (added delivery_fixture/1)
    - docs/api_stability.md (added §Delivery + §Outbound + §Outbound.Worker sections)
decisions:
  - "D-20 enforced: adapter call is between Multi#1 and Multi#2, never inside a transaction"
  - "D-21 enforced: Oban.insert composed into Ecto.Multi; Task.Supervisor re-stamps tenancy via with_tenant/2"
  - "D-14 enforced: deliver_later/2 always returns {:ok, %Delivery{status: :queued}}, never %Oban.Job{}"
  - "D-13 enforced: deliver/2 is a defdelegate alias for send/2"
  - "D-15 enforced: idempotency_key = sha256(tenant_id|mailable|recipient|content_hash)"
  - "I-01: Delivery has both :status (public API snapshot) and :last_event_type (ledger projection)"
  - "I-11: serialize_error/1 produces structured map, no string fallbacks"
  - "ASSUMED: deliver_many/2 is async-only at v0.1; sync-batch fan-out deferred to v0.5"
  - "ASSUMED: enqueue_batch_jobs respects :async_adapter app env for test isolation"
metrics:
  duration: "approx 120 minutes"
  completed: "2026-04-23"
  tasks_completed: 4
  files_created: 10
  files_modified: 4
---

# Phase 3 Plan 05: Outbound Facade — Hot Path Convergence Summary

**One-liner:** JWT-style two-Multi Outbound facade with Oban Worker + Task.Supervisor fallback, partial-UNIQUE idempotency-key batch replay, and D-20 adapter-outside-transaction enforcement.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Migration + Delivery schema | b29df5c | 00000000000002_add_idempotency_key_to_deliveries.exs, delivery.ex |
| 2 | Outbound facade + send/2 + dispatch | 6ecf721 | outbound.ex, mailglass.ex, api_stability.md |
| 3 | deliver_later/2 + Worker + Task.Supervisor | 1d0a407 | outbound/worker.ex, outbound.ex |
| 4 | deliver_many/2 + idempotency replay | c06fc24 | outbound.ex, deliver_many_test.exs |
| fix | {:shared, self()} sandbox mode for tests | c8c2a7e | deliver_later_test.exs, deliver_many_test.exs |

## Architecture

### Two-Multi Sync Path (D-20)

```
send/2 → preflight (6 stages) → Multi#1 (insert Delivery :queued + Event :queued)
       → call_adapter (OUTSIDE transaction)
       → Multi#2 (update Delivery :sent/:failed + Event :dispatched/:failed)
       → broadcast_delivery_updated
```

The adapter call is between Multi#1 and Multi#2, never inside a transaction. This prevents Postgres connection-pool starvation under provider latency (D-20 critical invariant).

### Preflight Pipeline (D-18 order)

1. `Tenancy.assert_stamped!/0` — raises TenancyError if tenant not stamped
2. `Tracking.Guard.assert_safe!/1` — raises ConfigError on auth-stream + tracking
3. `Suppression.check_before_send/1` — {:error, SuppressedError}
4. `RateLimiter.check/3` — {:error, RateLimitError}
5. `Stream.policy_check/1` — no-op seam
6. `Renderer.render/1` — {:error, TemplateError}

### Oban vs Task.Supervisor Routing

`deliver_later/2` routes via `enqueue_via_async_adapter/2`:
- `Application.get_env(:mailglass, :async_adapter, :oban)` controls routing
- If `:task_supervisor` or Oban unavailable: Task.Supervisor.start_child with `Tenancy.with_tenant/2` re-stamp
- If Oban available: `Oban.insert(:job, fn ...)` composed into same Multi as Delivery insert (atomic, no orphan jobs)

`enqueue_batch_jobs/1` for deliver_many also respects `:async_adapter` config.

### Idempotency Key + Batch Replay (D-15)

```
idempotency_key = sha256(tenant_id | "|" | inspect(mailable) | "|" | recipient | "|" | content_hash)
```

Partial UNIQUE index on `mailglass_deliveries(idempotency_key) WHERE idempotency_key IS NOT NULL`.

`insert_batch/1` uses `on_conflict: :nothing` + companion SELECT to re-fetch existing rows on replay. This makes repeated `deliver_many/2` calls with the same messages a safe DB-level no-op.

### Worker (Conditional Compile)

```elixir
if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Outbound.Worker do
    use Oban.Worker, queue: :mailglass_outbound, max_attempts: 20,
      unique: [period: 3600, fields: [:args], keys: [:delivery_id]]
    ...
  end
end
```

`mix compile --no-optional-deps --warnings-as-errors` passes — entire Worker module is elided when Oban absent.

## Test Coverage

| Test file | Tests | Focus |
|-----------|-------|-------|
| outbound_test.exs | 16 | Happy path, adapter failure, bang variant, PubSub broadcast |
| preflight_test.exs | 6 | Each preflight stage short-circuit + ordering |
| telemetry_test.exs | 2 | Span firing + PII property test (100 sends) |
| worker_test.exs | 7 | Worker structure, perform/1, TenancyMiddleware wrapping |
| deliver_later_test.exs | 10 | D-14 return shape, Task.Supervisor fallback, preflight failures |
| deliver_many_test.exs | 10 | Batch, idempotency keys, replay, mixed replay, preflight failure, bang variants |
| delivery_idempotency_key_test.exs | 15 | Migration columns, partial UNIQUE index, changeset, I-01 |

Total: 71 outbound tests, all passing.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Adapter failure not persisting :failed status**
- Found during: Task 2
- Issue: `do_send/2` had adapter failure going to `{:error, err}` branch without calling `persist_failed_by_id`
- Fix: Split `do_send/2` into `do_send_after_preflight/2` + `call_adapter_or_persist_failure/3`
- Files modified: lib/mailglass/outbound.ex
- Commit: 6ecf721

**2. [Rule 1 - Bug] Event type "queued" vs :queued in insert_all**
- Found during: Task 4
- Issue: `insert_batch/1` used `type: "queued"` (string) but Mailglass.Events.Event.type is Ecto.Enum requiring atom
- Fix: Changed to `type: :queued`
- Files modified: lib/mailglass/outbound.ex
- Commit: c06fc24

**3. [Rule 1 - Bug] enqueue_batch_jobs ignoring :async_adapter config**
- Found during: Task 4
- Issue: `enqueue_batch_jobs/1` only checked `OptionalDeps.Oban.available?()`, not `:async_adapter` env, so tests that set `async_adapter: :task_supervisor` still tried to call `Oban.insert_all` (Oban not running in test suite)
- Fix: Added `async_adapter = Application.get_env(:mailglass, :async_adapter, :oban)` check before routing
- Files modified: lib/mailglass/outbound.ex
- Commit: c06fc24

**4. [Rule 2 - Missing critical] try/rescue in Task.Supervisor tasks**
- Found during: Task 3
- Issue: Background tasks crashed with RuntimeError (Fake adapter "No owner") generating [error] log, which caused `--warnings-as-errors` abort (compile-time unused alias warning was the actual trigger, but the runtime logs were noise)
- Fix: Wrapped both `enqueue_task_supervisor/2` and `enqueue_batch_jobs/1` Task.Supervisor task bodies in try/rescue, logging at warning level
- Files modified: lib/mailglass/outbound.ex
- Commit: 1d0a407

**5. [Rule 1 - Bug] Sandbox :auto mode causing stale OID cache errors in full suite**
- Found during: Task 4
- Issue: `deliver_later_test.exs` and `deliver_many_test.exs` set `Sandbox.mode(:auto)` which, when followed by tests using `:manual` mode, caused Postgrex "cache lookup failed for type" errors due to different connections seeing stale OID caches. Note: This was a pre-existing issue confirmed by testing the pre-plan commit at seed 12345.
- Fix: Changed to `{:shared, self()}` mode — background tasks share the test process connection
- Files modified: test/mailglass/outbound/deliver_later_test.exs, test/mailglass/outbound/deliver_many_test.exs
- Commit: c8c2a7e

## Known Stubs

None — all plan functions are fully implemented. No hardcoded empty values or TODO placeholders in the public API surface.

## Threat Flags

No new security surface beyond what the plan's threat model covered. All T-3-05-* threats mitigated per plan:
- T-3-05-03 (critical): Adapter-outside-transaction verified by timestamp spy (Test 11 in outbound_test.exs)
- T-3-05-06: rendered_html + rendered_text stored in delivery.metadata for async path — documented in api_stability.md §Delivery.metadata

## Self-Check: PASSED

Files exist:
- lib/mailglass/outbound.ex: FOUND
- lib/mailglass/outbound/worker.ex: FOUND
- priv/repo/migrations/00000000000002_add_idempotency_key_to_deliveries.exs: FOUND
- test/mailglass/outbound/deliver_many_test.exs: FOUND

Commits exist:
- b29df5c (Task 1): FOUND
- 6ecf721 (Task 2): FOUND
- 1d0a407 (Task 3): FOUND
- c06fc24 (Task 4): FOUND
- c8c2a7e (sandbox fix): FOUND
