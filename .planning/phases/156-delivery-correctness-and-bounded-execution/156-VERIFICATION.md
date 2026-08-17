---
phase: 156-delivery-correctness-and-bounded-execution
verified: 2026-08-17T06:10:00Z
status: gaps_found
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "Concurrent core and inbound rate-limit activity admits the exact configured capacity while retaining fixed-point refill semantics and bounded fail-closed state."
  gaps_remaining:
    - "Core `mix ci` is red on a Phase 156 planning-artifact comment."
  regressions: []
gaps:
  - truth: "The Phase 156 integration surface leaves the core CI gate green."
    status: failed
    reason: "Fresh `mix ci` exits 20 at Credo. `lib/mailglass/outbound.ex:660` contains the Phase 156 implementation comment `Plan 156-03`, which violates the repository's `NoPlanningArtifactComments` check."
    artifacts:
      - path: "lib/mailglass/outbound.ex"
        issue: "A Phase 156 source comment is rejected by the live required CI gate."
    missing:
      - "Replace the planning-artifact wording with behavior-focused rationale and rerun `mix ci`."
deferred:
  - truth: "Inbound repository-wide formatting gate passes."
    addressed_in: "Phase 159"
    evidence: "Phase 159 owns deterministic fail-closed engineering gates. `mix format --check-formatted` still reports the same pre-existing, non-156 inbound files."
  - truth: "Migration-generator uses the repository clock abstraction."
    addressed_in: "Phase 159"
    evidence: "The second fresh CI warning is `lib/mailglass/migration_generator.ex:239`, introduced by Phase 155 (`36d2c2b4`), outside this phase's files and requirements."
---

# Phase 156: Delivery Correctness and Bounded Execution Verification Report

**Phase Goal:** Outbound delivery remains accurate, atomic, privacy-safe, and bounded under concurrency, provider failures, and saturated local execution.

**Verified:** 2026-08-17T06:10:00Z

**Status:** gaps_found

**Re-verification:** Yes — after limiter gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Concurrent core and inbound rate-limit activity never overspends, retains fractional time, and bounds/reclaims attacker-controlled keys. | ✓ VERIFIED | Core limiter suite: 18 tests, 0 failures. The new 100-call/50-capacity restart barriers and clock-regression assertions pass. Five fresh combined inbound runs (91 tests each) all pass. |
| 2 | A durable batch atomically records delivery state, events, rendered private payload metadata, and jobs, or fails with no stranded queued work. | ✓ VERIFIED | Live `insert_batch/2` builds jobs into the same Multi before `Repo.multi/1`; fresh 128-test core Phase 156 suite passed atomicity and idempotency coverage. |
| 3 | Saturated Task fallback reports rejected admission rather than falsely claiming queued delivery. | ✓ VERIFIED | Both application trees use `max_children: 10`; core and inbound dispatch code inspect each start result and return typed `:dispatch_unavailable`; fresh focused suites pass. |
| 4 | Provider retry/discard, serialized error privacy, and tracking telemetry are closed and truthful. | ✓ VERIFIED | Swoosh has finite status/reason mapping; the worker retries only `retry_class: :transient`; tracking branches on ledger result and preserves fail-open HTTP. Fresh core focused tests pass. |
| 5 | Persisted/job closed-set strings cannot allocate arbitrary atoms. | ✓ VERIFIED | Core `ProviderName` and inbound provider/source clauses are finite, wired into replay/worker execution, and their focused decoder/durable-evidence tests pass. |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified)

## Required Artifacts and Key Links

All fifteen plan-declared artifacts are present and substantive. All declared key links are live. The tracking tool's pattern check still misses `event_ledger().append(attrs)`, but source inspection verifies it at `lib/mailglass/tracking/plug.ex:115`, with `Mailglass.Events` as its default at line 133; passing tracking telemetry tests exercise the seam.

| Area | Evidence |
| --- | --- |
| Rate limiting | `AtomicBucket` uses complete-tuple ETS CAS and routes exhausted CAS contention through owner-serialized `consume_contended`; both owners call `ensure_table/0` before admission/contended consumption. |
| Durable batches | `Mailglass.OptionalDeps.Oban.insert_all/3` receives the Ecto Multi and generated jobs; `Outbound` commits the complete Multi once. |
| Fallback | Core/inbound supervisors are capped at 10 and explicit refusal results flow to typed errors. |
| Retry/privacy/telemetry | Closed Swoosh classification, worker cancellation, one outbound span owner, and ledger-outcome tracking telemetry remain wired. |
| Decoders | Literal provider/source mappings are wired to replay, persisted load, and Oban worker paths. |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- |
| Core restart, 100/50 capacity, fixed-point clock regression | `mix test test/mailglass/rate_limiter_test.exs test/mailglass/rate_limiter_supervision_test.exs --warnings-as-errors` | 18 tests, 0 failures | ✓ PASS |
| Repeated integrated inbound lifecycle/concurrency proof | Five repeated combined inbound focused runs | 5 × 91 tests, 0 failures | ✓ PASS |
| Full core Phase 156 focused behavior | Fresh Phase 156 focused core suite with `--warnings-as-errors` | 128 tests, 0 failures, 2 skips | ✓ PASS |
| Core no-optional compile, formatting, diff | `mix compile --no-optional-deps --warnings-as-errors`; `mix format --check-formatted`; `git diff --check` | Exit 0 | ✓ PASS |
| Inbound no-optional compile | `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` | Exit 0 | ✓ PASS |
| Inbound format | `cd mailglass_inbound && mix format --check-formatted` | Fails only on unchanged pre-existing repository-wide drift | ⚠️ DEFERRED to Phase 159 |
| Core package CI | `mix ci` | Exit 20 at Credo on a Phase 156 source comment | ✗ FAIL |

## Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
| --- | --- | --- | --- |
| EXEC-01 | 156-01 / 156-06 | ✓ SATISFIED | Exact core/inbound capacity and monotonic fractional-time regressions pass, including restart-plus-contention barriers. |
| EXEC-02 | 156-01 / 156-06 | ✓ SATISFIED | Owners enforce cap, idle eviction, periodic sweep, and fail-closed admission. |
| EXEC-03 | 156-02 | ✓ SATISFIED | One Multi transaction covers projections, events, metadata, and Oban jobs; rollback/replay tests pass. |
| EXEC-04 | 156-03 | ✓ SATISFIED | Both fallback paths are bounded and honest under saturation/failure. |
| EXEC-05 | 156-04 | ✓ SATISFIED | Closed transient/permanent table drives worker retry/cancel behavior. |
| EXEC-06 | 156-04 | ✓ SATISFIED | Provider-body/message/recipient sentinel coverage passes across serialized and persisted errors. |
| EXEC-07 | 156-04 | ✓ SATISFIED | Tracking telemetry distinguishes successful versus failed ledger writes while HTTP stays fail-open. |
| EXEC-08 | 156-05 | ✓ SATISFIED | Finite provider/source decoding and atom-count regression coverage pass. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| `lib/mailglass/outbound.ex` | 660 | `Plan 156-03` planning-artifact comment | 🛑 Blocker | Fresh required core CI rejects it via Credo and exits 20. |

## Deferred Items

Inbound repository-wide formatting remains a Phase 159 item and is unchanged outside this phase. The migration-generator clock warning was introduced in Phase 155 and is also carried to the quality-gate phase. Neither deferral excuses the Phase 156 comment that currently blocks core CI.

## Gaps Summary

The behavioral limiter gap is closed: both independently released packages now pass exact restart/contention and monotonic-clock proof, including five repeated integrated inbound runs. The phase is not certified because a Phase 156 source comment leaves the root required CI command red. Replace that comment with behavior-focused wording and re-run `mix ci`; no product or UI change is required.

---

_Verified: 2026-08-17T06:10:00Z_

_Verifier: gsd-verifier_
