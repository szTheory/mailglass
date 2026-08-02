---
phase: 150-private-envelope-and-atomic-durable-enqueue
plan: "03"
subsystem: outbound durability
tags: [oban, payload, worker, tenancy, privacy]
requires:
  - phase: 150-02
    provides: private Payload persistence and atomic durable enqueue
provides:
  - Payload-first, tenant-scoped worker recovery with a narrow legacy reader
  - Fail-closed explicit Oban readiness for the canonical outbound queue
affects: [151-unified-dispatch, generated-host-proof]
tech-stack:
  added: []
  patterns: [payload-first dispatch, optional dependency readiness gateway]
key-files:
  created: []
  modified:
    - lib/mailglass/outbound.ex
    - lib/mailglass/outbound/worker.ex
    - lib/mailglass/optional_deps/oban.ex
    - test/mailglass/outbound/worker_test.exs
key-decisions:
  - "Worker dispatch loads and validates the tenant-scoped private Payload before considering legacy metadata."
  - "Explicit :oban only succeeds after a configured instance advertises Worker.queue/0; it never falls back to Task.Supervisor."
patterns-established:
  - "Legacy queued compatibility requires queued status and the complete recognizable pre-v2.4 metadata marker set."
requirements-completed: [ENVL-04, ENVL-06, ENVL-08]
coverage:
  - id: D1
    description: Worker dispatch reconstructs immutable private payload input under restored tenancy rather than delivery metadata.
    requirement: ENVL-04
    verification:
      - kind: integration
        ref: mix test test/mailglass/outbound/worker_test.exs --only phase_150_task:t150_03_01 --warnings-as-errors
        status: pass
    human_judgment: false
  - id: D2
    description: Explicit Oban selection fails closed for an unavailable instance and does not use Task.Supervisor.
    requirement: ENVL-06
    verification:
      - kind: integration
        ref: mix test test/mailglass/outbound/deliver_later_test.exs test/mailglass/outbound/worker_test.exs --only phase_150_task:t150_03_02 --warnings-as-errors
        status: pass
    human_judgment: false
  - id: D3
    description: Canonical worker queue identity is checked through the optional Oban gateway and optional-dependency compilation remains clean.
    requirement: ENVL-08
    verification:
      - kind: other
        ref: mix compile --no-optional-deps --warnings-as-errors
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-08-02
status: complete
---

# Phase 150 Plan 03: Payload-First Worker and Fail-Closed Oban Summary

**Durable worker jobs now recover immutable tenant-scoped Payloads first, while explicit Oban enqueue fails closed unless its canonical queue is configured.**

## Performance

- **Duration:** 6 min
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added `Worker.queue/0` and dispatches durable jobs from digest-checked private payloads before any legacy bridge.
- Restricted metadata reconstruction to identified pre-v2.4 queued rows with the complete old marker set.
- Added optional-dependency-safe Oban readiness and removed the implicit Task.Supervisor fallback for explicit Oban selection.

## Task Commits

1. **Task 1: Dispatch immutable payload input under restored tenancy** — `d588eff9` (RED), `7faf6528` (GREEN)
2. **Task 2: Fail closed on unusable Oban and canonical queue drift** — `eae66dec` (RED), `176e9613` (GREEN)

## Files Created/Modified

- `lib/mailglass/outbound.ex` — payload-first worker dispatch, bounded legacy reader, and fail-closed adapter selection.
- `lib/mailglass/outbound/worker.ex` — canonical queue helper.
- `lib/mailglass/optional_deps/oban.ex` — safe instance/queue readiness and transaction-safe unavailable-dependency insertion failure.
- `test/mailglass/outbound/worker_test.exs` — worker queue, payload-first, and unavailable-instance regression coverage.
- `test/mailglass/outbound/deliver_later_test.exs` — explicit Oban no-fallback coverage.
- `test/mailglass/outbound/deliver_many_test.exs` — configured Oban test harness for the existing durable-batch assertion.
- `test/support/mailer_case.ex` — queue-configured Oban test setup for tagged Oban cases.
- `test/mailglass/core_send_integration_test.exs` — configured-Oban durable enqueue assertion replacing the stale inline-worker expectation.

## Decisions Made

- Private Payload is authoritative for durable jobs; only an absent Payload may enter the narrow, recognizable legacy bridge.
- The canonical queue comparison normalizes only existing atom/string queue names and never creates atoms from configuration.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated manual-mode batch harness for fail-closed readiness**
- **Found during:** Phase-wide verification.
- **Issue:** Oban's manual test mode intentionally clears runtime queue configuration, so the existing batch durability test could no longer satisfy the new truthful readiness contract.
- **Fix:** Started its test instance in disabled mode with the canonical configured queue.
- **Files modified:** `test/mailglass/outbound/deliver_many_test.exs`.
- **Verification:** Focused batch test and the phase-wide outbound verification suite pass.
- **Committed in:** `42436a48`.

**2. [Rule 1 - Bug] Repaired the core Oban integration harness after readiness enforcement**
- **Found during:** Post-wave full-suite gate.
- **Issue:** The old `:inline` Oban instance mode clears Oban's runtime queue list, making its claimed durable enqueue fail the canonical-queue readiness check.
- **Fix:** Tagged Oban cases start a queue-configured disabled instance; the core integration assertion now verifies truthful configured Oban enqueue rather than an inline-worker false green.
- **Files modified:** `test/support/mailer_case.ex`, `test/mailglass/core_send_integration_test.exs`.
- **Verification:** `mix test test/mailglass/core_send_integration_test.exs:103 --trace --warnings-as-errors`, Phase 150 outbound suite, no-optional-deps compile, and `mix test` pass.
- **Committed in:** `d85216f5`.

**Total deviations:** 2 auto-fixed (Rule 1).
**Impact on plan:** Test harness only; no production scope expanded.

## Issues Encountered

The focused outbound suite emits pre-existing Fake adapter ownership warnings from Task.Supervisor scenarios, but all 45 tests pass.

## Next Phase Readiness

Phase 151 can rely on the persisted private input and truthful durable enqueue boundary for outcome classification and payload lifecycle work.

## Self-Check: PASSED

- Confirmed all six listed source/test files and this summary exist.
- Confirmed commits `d588eff9`, `7faf6528`, `eae66dec`, `176e9613`, and `42436a48` exist in git history.
