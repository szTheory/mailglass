---
phase: 03-transport-send-pipeline
plan: "03"
subsystem: preflight-stages
tags: [rate-limiter, suppression, stream, ets, supervisor-owned-ets, tdd, wave-3, d-22, d-23, d-24, d-25, d-28]
dependency_graph:
  requires: [phase-01-core, phase-02-persistence-tenancy, 03-01, 03-02]
  provides:
    - Mailglass.RateLimiter.check/3 (SEND-02 — :transactional bypass + ETS token bucket)
    - Mailglass.RateLimiter.Supervisor + TableOwner (first supervisor-owned ETS in mailglass)
    - Mailglass.Suppression.check_before_send/1 (SEND-04 — facade over SuppressionStore)
    - Mailglass.SuppressionStore.ETS (D-28 — behaviour parity with Ecto, test-speed impl)
    - Mailglass.SuppressionStore.ETS.Supervisor + TableOwner
    - Mailglass.Stream.policy_check/1 (D-25 — no-op seam, v0.5 DELIV-02 swaps impl)
    - api_stability.md §RateLimiter + §SuppressionStore.ETS + §Suppression + §Stream
  affects:
    - Plan 05 (Outbound.send/2 preflight pipeline consumes all three preflight stages)
    - Plan 06 (MailerCase wires suppression_store to ETS for test speed)
tech_stack:
  added: []
  patterns:
    - "Supervisor-owned ETS (init-and-idle TableOwner, OTP 27 opts) — first instance in mailglass"
    - ":ets.update_counter/4 compound op list for token bucket decrement"
    - "Restore-from-negative refill logic (counter floors at -1 on over-limit; recovery adds restore + elapsed refill)"
    - "Runtime store dispatch via Application.get_env/3 for suppression store"
    - "apply/3 in tests to bypass Elixir 1.18+ type-narrowing on intentional-misuse tests"
key_files:
  created:
    - lib/mailglass/rate_limiter.ex
    - lib/mailglass/rate_limiter/supervisor.ex
    - lib/mailglass/rate_limiter/table_owner.ex
    - lib/mailglass/suppression.ex
    - lib/mailglass/suppression_store/ets.ex
    - lib/mailglass/suppression_store/ets/supervisor.ex
    - lib/mailglass/suppression_store/ets/table_owner.ex
    - lib/mailglass/stream.ex
    - test/mailglass/rate_limiter_test.exs
    - test/mailglass/rate_limiter_supervision_test.exs
    - test/mailglass/suppression_store/ets_test.exs
    - test/mailglass/suppression_test.exs
    - test/mailglass/stream_test.exs
  modified:
    - docs/api_stability.md (§RateLimiter, §SuppressionStore.ETS, §Suppression, §Stream)
decisions:
  - "ETS compound op {2, total_add, capacity, capacity}, {3, 0, 0, now_ms}, {2, -1} — decrement returns actual value (-1 = over-limit, >=0 = allowed); capped refill prevents bucket exceeding capacity"
  - "Restore-from-negative refill: when counter is -1 (post-over-limit), add abs(tokens) to bring back to 0 before applying elapsed refill delta — required for bucket recovery after exhaustion"
  - "SuppressionStore.ETS.check/2 uses Enum.find_value over 3 lookup keys (address, domain, address_stream) — mirrors Ecto's OR-union but without SQL; returns first non-nil hit"
  - "Suppression.check_before_send/1 extracts primary_recipient from msg.swoosh_email.to tuple-or-binary — dual pattern match for Swoosh.Email compatibility"
  - "Stream test uses apply/3 to bypass Elixir 1.18 static type-narrowing on intentional FunctionClauseError test — same pattern as other struct-discrimination tests in codebase"
  - "SuppressionStore.ETS.record/2 falls back to {:error, :invalid_attrs} on non-map input (mirrors Ecto impl's WR-03 fallback pattern)"
metrics:
  duration: "17min"
  completed: "2026-04-23"
  tasks: 3
  files_created: 13
  files_modified: 1
---

# Phase 3 Plan 03: Preflight Stages Summary

**One-liner:** Three preflight stages for the Outbound.send/2 pipeline — RateLimiter (ETS token bucket with supervisor-owned table, :transactional bypass), Suppression facade (runtime store dispatch over SuppressionStore.ETS behaviour impl), and Stream.policy_check (no-op seam with v0.5 DELIV-02 forward contract).

## What Shipped

### Task 1: RateLimiter + Supervisor + TableOwner (SEND-02, D-22, D-23, D-24)

**`Mailglass.RateLimiter.check/3`** — Per-`{tenant_id, domain}` ETS token bucket:

- **`:transactional` bypass (D-24):** First function clause pattern-matches `:transactional` and returns `:ok` BEFORE any ETS access. Password-reset / magic-link / verify-email flows are never throttled regardless of bucket state. This is a reserved invariant, not a tunable.
- **Token bucket math (D-23):** Continuous leaky-bucket refill at `per_minute / 60_000` tokens/ms. Bucket is seeded at full capacity on first hit via `:ets.insert_new/2`.
- **Over-limit detection:** ETS compound op returns `-1` from the decrement step when tokens are exhausted (returns `>= 0` when allowed). `{:error, %RateLimitError{type: :per_domain, retry_after_ms: N}}` on over-limit.
- **Recovery from over-limit:** Counter floors at -1 after exhaustion. Next call computes `restore = abs(tokens)` to bring counter from -1 back to 0, then adds elapsed refill delta — recovery on the next call after sufficient time has elapsed.
- **Telemetry:** Single-emit `[:mailglass, :outbound, :rate_limit, :stop]` with `%{duration_us, allowed, tenant_id}` — no recipient domain in metadata (D-31 PII compliance).

**ETS compound op form (D-23):**

```elixir
:ets.update_counter(@table, key, [
  {2, total_add, capacity, capacity},  # refill + restore, capped at capacity
  {3, 0, 0, now_ms},                   # timestamp update (always triggers)
  {2, -1}                              # raw decrement — returns actual new value
], {key, capacity, now_ms})
```

**`Mailglass.RateLimiter.TableOwner`** — Init-and-idle GenServer, first supervisor-owned ETS in mailglass:

OTP 27 opts: `write_concurrency: :auto, decentralized_counters: true` — lock striping + per-scheduler counters for ≈1-3μs hot path.

**`Mailglass.RateLimiter.Supervisor`** — one_for_one, single child `TableOwner`. Picked up automatically by `Mailglass.Application` via `Code.ensure_loaded?/1` gate (I-08 — no edit to application.ex required).

Crash semantics (D-22): TableOwner crash → BEAM deletes ETS table → supervisor restarts TableOwner → init/1 recreates empty table. Counter reset is acceptable — worst case is 1 minute of burst allowance.

**Test coverage (10 tests):** transactional bypass + no ETS access, fresh bucket, 100-call burst + 101st fails, refill after 600ms sleep, tenant isolation, PII compliance on error context, telemetry emission, config override (capacity=5 vs capacity=500), supervision crash+restart, supervisor one_for_one structure.

### Task 2: Suppression Facade + SuppressionStore.ETS (SEND-04, D-28)

**`Mailglass.Suppression.check_before_send/1`** — Public facade:

- Extracts primary recipient from `msg.swoosh_email.to` (tuple or binary pattern match)
- Dispatches to `Application.get_env(:mailglass, :suppression_store, Mailglass.SuppressionStore.Ecto)`
- Returns `:ok` on `:not_suppressed`, `{:error, %SuppressedError{type: scope}}` on hit
- `SuppressedError` context: `%{tenant_id: _, stream: _}` only — no address, no email headers (T-3-03-03 mitigation)
- Telemetry: `[:mailglass, :outbound, :suppression, :stop]` with `%{hit, tenant_id}` — no PII

**`Mailglass.SuppressionStore.ETS`** — Behaviour parity with `Mailglass.SuppressionStore.Ecto`:

- `check/2`: 3-branch OR-union lookup matching Ecto's SQL query — `(tenant_id, address, :address, nil)`, `(tenant_id, domain, :domain, nil)`, `(tenant_id, address, :address_stream, stream)`. First hit wins.
- `record/2`: UPSERT via `:ets.insert/2` — overwrites existing key (equivalent to Ecto `on_conflict: {:replace, [...]}`).
- Expiry filter at read time: `not_expired?/2` uses `Mailglass.Clock.utc_now()` — expired entries silently skipped.
- `reset/0`: Test-only helper. Clears all entries via `:ets.delete_all_objects/1`.

**Supervisor + TableOwner:** Identical init-and-idle pattern to RateLimiter. ETS opts: `write_concurrency: :auto` without `decentralized_counters` (suppression lookups are reads, not counter updates — different hot path).

**Test coverage (12 tests):** empty table, address scope record+check, UPSERT re-record updates reason, domain scope suppresses all addresses at domain, address_stream scope matches only on stream, expiry filter, facade returns :ok/:error, store dispatch via config, telemetry PII compliance, SuppressedError context PII refutation, supervision crash+restart.

### Task 3: Mailglass.Stream no-op seam (D-25)

**`Mailglass.Stream.policy_check/1`** — No-op at v0.1:

- Returns `:ok` for all three streams (`:transactional | :operational | :bulk`)
- Pattern-matches `%Mailglass.Message{}` only — `FunctionClauseError` on raw map (enforced contract)
- Telemetry: `[:mailglass, :outbound, :stream_policy, :stop]` with `%{tenant_id, stream}`
- Moduledoc documents v0.5 DELIV-02 swap contract: callers do not change

**Why a no-op seam rather than omitting the stage:** The Plan 05 preflight pipeline is stable across versions. Adding `stream_policy` later would require inserting a stage mid-pipeline (breaking change). Shipping a no-op now locks the call-site contract.

**Test coverage (5 tests):** :ok for all three streams, telemetry emission with whitelisted metadata, FunctionClauseError on raw map (via `apply/3` to bypass Elixir 1.18 type-narrowing).

### api_stability.md Updates

Four new sections:

- `§RateLimiter` — locked `check/3` signature, `:transactional` bypass invariant, token bucket math, ETS table name reserved, TableOwner + Supervisor singletons documented (LINT-07 exceptions), telemetry shape, config shape.
- `§SuppressionStore.ETS` — behaviour parity contract, lookup algorithm, UPSERT behaviour, expiry filter, test override pattern, `reset/0` test-only designation.
- `§Suppression` — locked `check_before_send/1` signature, store-indirection pattern, recipient extraction, return shape, telemetry shape, SuppressedError context keys.
- `§Stream` — locked `policy_check/1` signature, no-op contract, v0.5 DELIV-02 stability guarantee, telemetry shape.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ETS compound op `{2, 0, capacity, refilled_val}` form incorrect for partial refill**

- **Found during:** Task 1 GREEN phase — Test 3 (101 calls) showed all 101 returning `:ok`
- **Issue:** The PATTERNS.md verbatim compound op `{2, 0, capacity, refilled_val}` adds 0 to tokens; the threshold `>= capacity` only triggers when bucket is AT capacity. Partial refill (tokens < capacity) was never applied. Combined with `{2, -1, 0, 0}` (incorrect floor semantics — collapses all positive values to 0), the bucket effectively had no capacity tracking.
- **Fix:** Replaced with `{2, total_add, capacity, capacity}, {3, 0, 0, now_ms}, {2, -1}` where `total_add` is computed outside ETS as `min(restore + refill_delta, capacity - tokens)`. The raw `{2, -1}` decrement returns the actual new value (-1 for over-limit, >=0 for allowed).
- **Files modified:** `lib/mailglass/rate_limiter.ex`

**2. [Rule 1 - Bug] ETS counter stays at -1 after over-limit — bucket never refills**

- **Found during:** Task 1 GREEN phase — Test 4 (refill after sleep) still failed after fix #1
- **Issue:** After over-limit, counter is stored as -1. Refill delta was computed from `tokens = -1`, giving `total_add = min(0 + 1, 2 - (-1)) = 1`. Op adds 1 to -1 = 0. Then decrement: 0 - 1 = -1. Bucket trapped at -1 forever.
- **Fix:** Added `restore = if tokens < 0, do: abs(tokens), else: 0` to bring the counter from negative back to 0 before applying the time-elapsed refill. `total_add = min(restore + refilled, capacity - tokens)`.
- **Files modified:** `lib/mailglass/rate_limiter.ex`

**3. [Rule 1 - Bug] Supervision test used `Mailglass.RateLimiter.Supervisor.which_children/1`**

- **Found during:** Task 1 GREEN phase — test called `Supervisor.which_children(sup_pid)` where `Supervisor` was aliased to `Mailglass.RateLimiter.Supervisor`, not `Elixir.Supervisor`
- **Fix:** Changed to `Elixir.Supervisor.which_children(sup_pid)` to call the OTP built-in
- **Files modified:** `test/mailglass/rate_limiter_supervision_test.exs`

**4. [Rule 1 - Bug] `build_message/1` default arg warning in suppression_test.exs**

- **Found during:** Task 2 GREEN phase — `--warnings-as-errors` flagged unused default arg
- **Fix:** Removed `\\ []` default since all call-sites pass arguments; changed to `defp build_message(attrs)`
- **Files modified:** `test/mailglass/suppression_test.exs`

**5. [Rule 1 - Bug] Stream FunctionClauseError test triggered Elixir 1.18 type-narrowing warning**

- **Found during:** Task 3 GREEN phase — `Stream.policy_check(%{stream: :bulk})` with `--warnings-as-errors` fails due to static type incompatibility warning
- **Fix:** Replaced `Stream.policy_check(%{stream: :bulk})` with `apply(Stream, :policy_check, [%{stream: :bulk}])` — bypasses static analysis while preserving the runtime FunctionClauseError contract. Same pattern as other struct-discrimination tests in codebase (documented in STATE.md decisions).
- **Files modified:** `test/mailglass/stream_test.exs`

## Threat Mitigations Verified

| Threat | Mitigation | Verified by |
|--------|-----------|-------------|
| T-3-03-01: Rate limiter bypass via crafted stream atom | `:transactional` is FIRST function clause; other atoms fall to ETS path | Test 1 (bypass + no ETS write) |
| T-3-03-02: PII in telemetry metadata | rate_limit metadata: `{allowed, tenant_id}` only; suppression metadata: `{hit, tenant_id}` only | Test 7 (rate_limiter) + Test 9 (suppression) |
| T-3-03-03: Cross-tenant suppression via forged lookup key | Suppression.check_before_send extracts tenant_id from Message struct (not caller-supplied); ETS key includes tenant_id | Test 10 (SuppressedError context has no address) |
| T-3-03-07: SuppressionStore.ETS leaking expired entries | `not_expired?/2` filter at read time | Test 6 (ets_test) |

**Open question resolution:** Monotonic_ms helper NOT added — real clock + generous assertion bounds (600ms sleep for 500ms refill) is sufficient per RESEARCH §4.3. Confirmed by Test 4 (refill) passing consistently.

## Known Stubs

None — all public API functions are fully implemented. `Stream.policy_check/1` is intentionally a no-op seam (not a stub) with documented v0.5 swap contract.

## Pre-existing Issues (Out of Scope)

`Mailglass.PersistenceIntegrationTest` Postgrex type cache staleness issue (1 flaky test) — pre-existing before Plan 03-03. Documented in Plan 02-06 deferred items. Not introduced by this plan.

## Self-Check: PASSED

Files created/present:
- lib/mailglass/rate_limiter.ex ✓
- lib/mailglass/rate_limiter/supervisor.ex ✓
- lib/mailglass/rate_limiter/table_owner.ex ✓
- lib/mailglass/suppression.ex ✓
- lib/mailglass/suppression_store/ets.ex ✓
- lib/mailglass/suppression_store/ets/supervisor.ex ✓
- lib/mailglass/suppression_store/ets/table_owner.ex ✓
- lib/mailglass/stream.ex ✓
- test/mailglass/rate_limiter_test.exs ✓
- test/mailglass/rate_limiter_supervision_test.exs ✓
- test/mailglass/suppression_store/ets_test.exs ✓
- test/mailglass/suppression_test.exs ✓
- test/mailglass/stream_test.exs ✓
- docs/api_stability.md (§RateLimiter, §SuppressionStore.ETS, §Suppression, §Stream) ✓

Commits:
- 6f48e3c: test(03-03): add failing tests for RateLimiter — RED phase ✓
- c04a7c8: feat(03-03): RateLimiter + Supervisor + TableOwner — supervisor-owned ETS token bucket ✓
- ce7fa24: test(03-03): add failing tests for Suppression + SuppressionStore.ETS — RED phase ✓
- 05d7b06: feat(03-03): Suppression facade + SuppressionStore.ETS + Supervisor + TableOwner ✓
- 3c13026: test(03-03): add failing tests for Mailglass.Stream — RED phase ✓
- 33e0fc9: feat(03-03): Mailglass.Stream no-op policy_check seam (D-25) ✓
