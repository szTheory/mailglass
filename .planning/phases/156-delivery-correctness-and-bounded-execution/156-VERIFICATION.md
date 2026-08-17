---
phase: 156-delivery-correctness-and-bounded-execution
verified: 2026-08-17T05:25:00Z
status: gaps_found
score: 4/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Concurrent core and inbound rate-limit activity admits the exact configured capacity while retaining fixed-point refill semantics and bounded fail-closed state."
    status: partial
    reason: "The combined inbound focused suite deterministically exercises a current false-denial race: its 50-capacity concurrent limiter test observed 46 and 49 successful admissions on separate fresh runs. The same test passes in isolation, so the issue is a lifecycle/contention interaction, not an intentionally lower configured limit."
    artifacts:
      - path: "lib/mailglass/rate_limiter/atomic_bucket.ex"
        issue: "The bounded 32-attempt CAS loop returns denial under legitimate concurrent contention; owner-restart activity also permits TableOwner to crash on ETS lookup after its table disappears."
      - path: "mailglass_inbound/lib/mailglass_inbound/rate_limiter/table_owner.ex"
        issue: "handle_call/3 uses an unguarded ETS lookup while the named table can be absent during its restart window, contributing to the lifecycle race."
    missing:
      - "Make owner admission safe when the ETS table has disappeared and ensure subsequent callers converge on the recreated table without crashing the owner."
      - "Replace contention-exhaustion false denials with a bounded, correctness-preserving retry/admission strategy that still never overspends or exceeds the key cap."
      - "Add a deterministic regression that combines owner restart with 50+ concurrent inbound checks and proves exactly capacity successes, then run the whole inbound focused limiter suite repeatedly."
deferred:
  - truth: "Inbound repository-wide formatting gate passes."
    addressed_in: "Phase 159"
    evidence: "Phase 159 goal: 'Maintainers receive one deterministic, fail-closed merge signal backed by complete quality checks and maintainable validation infrastructure.' The current `mix format --check-formatted` failure names pre-existing files outside Phase 156's implementation set."
---

# Phase 156: Delivery Correctness and Bounded Execution Verification Report

**Phase Goal:** Outbound delivery remains accurate, atomic, privacy-safe, and bounded under concurrency, provider failures, and saturated local execution.

**Verified:** 2026-08-17T05:25:00Z

**Status:** gaps_found

**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Concurrent core and inbound rate-limit activity is exact, fixed-point, bounded, and restart-safe. | ✗ FAILED | `mailglass_inbound/test/mailglass_inbound/rate_limiter_test.exs:197` failed twice in combined current-suite runs: expected 50 successes, observed 46 and 49. Isolated runs passed, proving a nondeterministic lifecycle/contention defect. |
| 2 | A durable batch atomically persists deliveries, events, rendered private metadata, and Oban jobs, with rollback and idempotent replay. | ✓ VERIFIED | `Outbound.insert_batch/2` constructs one `Ecto.Multi`, calls `maybe_insert_batch_jobs/2` before `Repo.multi/1`, and the fresh 110-test core focused run passed its atomicity/replay coverage. |
| 3 | Saturated core and inbound Task fallback reports an unavailable dispatch rather than a queued claim. | ✓ VERIFIED | Both applications configure `Task.Supervisor` with `max_children: 10`; adapters inspect `start_child` outcomes and return privacy-safe `:dispatch_unavailable`. Core and inbound fallback suites passed. |
| 4 | Retry classification is closed, permanent outcomes discard, errors are private, and dispatch/tracking telemetry is truthful. | ✓ VERIFIED | Swoosh maps only explicit transport/timeout/429/5xx shapes to `:transient`; the worker cancels all other outcomes; `Tracking.Plug` branches on `event_ledger().append/1`; 110 core focused tests passed. |
| 5 | Persisted/job strings enter through finite decoders and cannot create arbitrary atoms. | ✓ VERIFIED | `ProviderName` has literal five-value clauses; inbound provider/source decoders return closed errors before execution; core/inbound decoder and durable route binding/restart/tamper/recovery tests passed. |

**Score:** 4/5 truths verified (0 present-but-behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mailglass/rate_limiter/atomic_bucket.ex` | Shared CAS fixed-point engine | ⚠️ PARTIAL | Exists, substantive, and both facades call it; the bounded retry path produces demonstrated false denials under integrated contention. |
| `lib/mailglass/rate_limiter/table_owner.ex` and inbound equivalent | Bounded owner-mediated admission/sweep | ⚠️ PARTIAL | Defaults and sweeping are present, but the owner has an unguarded ETS lookup during a table-restart window. |
| `lib/mailglass/optional_deps/oban.ex` and `lib/mailglass/outbound.ex` | One transaction including jobs | ✓ VERIFIED | `insert_all/3` adds jobs to the existing Multi, then `Repo.multi/1` supplies the sole commit boundary. |
| `lib/mailglass/outbound/async_adapter/task_supervisor.ex` and inbound execution | Honest bounded fallback | ✓ VERIFIED | All `start_child` result shapes normalize to explicit accepted/refused outcomes. |
| `lib/mailglass/adapters/swoosh.ex`, `outbound/worker.ex`, `tracking/plug.ex` | Closed outcomes, privacy, and telemetry truth | ✓ VERIFIED | Explicit finite status/reason mapping, `retry_class` worker branch, and ledger-outcome telemetry are live. |
| `lib/mailglass/webhook/provider_name.ex`, inbound execution/worker | Finite provider/source decoding | ✓ VERIFIED | Literal maps are wired into replay, persisted-record loading, and worker source decoding. |

## Key Link Verification

All PLAN-declared links are present in the live source except the tooling pattern for tracking, which is a false negative: `Tracking.Plug` calls `event_ledger().append(attrs)` at line 115 and defaults that seam to `Mailglass.Events` at line 133. This is wired and covered by the passing tracking tests.

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core focused Phase 156 behavior | `mix test` over limiter, durable batch, fallback, retry/privacy, telemetry, tracking, and replay files with `--warnings-as-errors` | 126 tests, 0 failures, 2 skips | ✓ PASS |
| Core non-limiter Phase 156 behavior | Fresh durable/fallback/retry/privacy/telemetry/replay suite | 110 tests, 0 failures, 2 skips | ✓ PASS |
| Inbound limiter with other Phase 156 behavior | `cd mailglass_inbound && mix test` focused limiter/fallback/decoder/durable route files with `--warnings-as-errors` | 89 tests, 1 failure — expected 50 successes, got 46 | ✗ FAIL |
| Inbound limiter plus direct Phase 156 cases | Fresh compile then focused limiter/fallback/decoder suite | 33 tests, 1 failure — expected 50 successes, got 49 | ✗ FAIL |
| Inbound non-limiter Phase 156 behavior | Focused fallback/decoder/durable route suites | 80 tests, 0 failures | ✓ PASS |
| Core no-optional compile, format, diff | `mix compile --no-optional-deps --warnings-as-errors`, `mix format --check-formatted`, `git diff --check` | Exit 0 | ✓ PASS |
| Inbound no-optional compile | `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` | Exit 0 | ✓ PASS |
| Core package CI | `mix ci` | Exit 0 | ✓ PASS |
| Inbound package CI/format | `cd mailglass_inbound && mix ci` | Fails before tests on pre-existing repository-wide formatting drift | ⚠️ DEFERRED to Phase 159 |

## Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
| --- | --- | --- | --- |
| EXEC-01 | 156-01 | ✗ BLOCKED | Fixed-point CAS code and isolated refill tests exist, but exact configured admissions fail in integrated inbound concurrency runs. |
| EXEC-02 | 156-01 | ✓ SATISFIED | Table owners use default 100,000 key cap, one-hour expiry, 60-second sweep, idle purge, and fail-closed admission; dedicated bound tests pass. |
| EXEC-03 | 156-02 | ✓ SATISFIED | One Multi holds delivery/event/job writes and rollback/replay tests pass. |
| EXEC-04 | 156-03 | ✓ SATISFIED | Ten-child limits and typed rejected-spawn handling are implemented and tested in both packages. |
| EXEC-05 | 156-04 | ✓ SATISFIED | Finite retry mapping and permanent worker cancellation are implemented and tested. |
| EXEC-06 | 156-04 | ✓ SATISFIED | Sentinel tests cover JSON, message, context, and persisted `last_error`; no provider-body preview remains. |
| EXEC-07 | 156-04 | ✓ SATISFIED | Ledger success/failure chooses `recorded`/`failed` telemetry while HTTP stays fail-open. |
| EXEC-08 | 156-05 | ✓ SATISFIED | Core and inbound provider/source maps are literal and warmed atom-count regressions pass. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| `lib/mailglass/rate_limiter/table_owner.ex` | 2-25 | Module documentation still says it has no `handle_call/3` and uses `:ets.update_counter/4`, although it now has serialized admission and CAS is elsewhere. | ⚠️ Warning | Misleading internal maintenance documentation; update while closing the limiter gap. |
| `mailglass_inbound/lib/mailglass_inbound/rate_limiter/table_owner.ex` | 2-25 | Mirrored stale implementation documentation. | ⚠️ Warning | Same maintenance hazard. |

## Deferred Items

Repository-wide inbound formatting is deliberately covered by Phase 159's engineering-gate goal. It does not excuse the Phase 156 limiter failure, which remains an actionable blocker.

## Gaps Summary

Phase 156 cannot be certified yet. The private limiter has the intended fixed-point CAS structure and never demonstrated overspending, but its finite retry/restart handling can reject legitimate capacity in an integrated inbound workload. That breaks the phase's required accurate/exact concurrent admission proof and leaves its focused suite red.

Closure should make `TableOwner.handle_call/3` tolerate an absent table, remove the lifecycle race that leaves contention callers denied, and add a deterministic restart-plus-barrier test that proves exactly capacity admissions repeatedly for both packages. Re-run the two combined inbound commands above, both no-optional compiles, format/diff checks, and package CI after the repair.

---

_Verified: 2026-08-17T05:25:00Z_

_Verifier: gsd-verifier_
