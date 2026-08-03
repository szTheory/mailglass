---
phase: 151-unified-dispatch-honest-outcomes-and-payload-lifecycle
plan: "02"
subsystem: outbound delivery
tags: [elixir, swoosh, dispatch-outcomes, privacy, retry-safety]
requires:
  - phase: 150-private-envelope-and-atomic-durable-enqueue
    provides: typed envelope and durable dispatch foundation
provides:
  - closed accepted/retryable/terminal/uncertain dispatch classification
  - privacy-bounded outcome projection and structured Swoosh evidence
affects: [151-04 worker outcome settlement, outbound dispatch]
tech-stack:
  added: []
  patterns: [closed structural outcome contract, conservative provider-evidence classification]
key-files:
  created: [lib/mailglass/outbound/dispatch_outcome.ex, test/mailglass/outbound/dispatch_outcome_test.exs]
  modified: [lib/mailglass/adapters/swoosh.ex, test/mailglass/adapters/swoosh_test.exs]
key-decisions:
  - "Only structured 4xx/5xx evidence and explicit before-acceptance transport evidence can establish terminal or retryable outcomes."
  - "Safe projections expose a closed reason class and bounded correlation identifier, never raw provider bodies or exception text."
patterns-established:
  - "DispatchOutcome.classify/1 defaults opaque adapter evidence to uncertain."
requirements-completed: [DISP-01]
coverage:
  - id: D1
    description: "Closed dispatch classifier preserves accepted results and maps structured provider evidence conservatively."
    requirement: DISP-01
    verification:
      - kind: unit
        ref: "mix test test/mailglass/outbound/dispatch_outcome_test.exs test/mailglass/adapters/swoosh_test.exs --only phase_151_task:t151_02_01 --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Swoosh retains its callback-compatible result shape while adding bounded dispatch evidence."
    requirement: DISP-01
    verification:
      - kind: unit
        ref: "test/mailglass/adapters/swoosh_test.exs#provider error context adds only bounded dispatch evidence"
        status: pass
    human_judgment: false
duration: 2min
completed: 2026-08-03
status: complete
---

# Phase 151 Plan 02: Closed Dispatch Outcome Contract Summary

**Closed, conservative outbound outcome classification that preserves Swoosh compatibility while excluding raw provider material from safe projections.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-08-03T02:40:00Z
- **Completed:** 2026-08-03T02:42:04Z
- **Tasks:** 1/1
- **Files modified:** 4

## Accomplishments

- Added `Mailglass.Outbound.DispatchOutcome` with accepted values plus closed retryable, terminal, and uncertain outcomes.
- Classified only reliable structured HTTP and explicit pre-acceptance transport evidence; opaque evidence defaults to uncertain.
- Added a safe projection that carries only closed reason classes and bounded correlation facts.
- Added Swoosh `dispatch_evidence` context without changing its public adapter callback or response compatibility.

## Task Commits

1. **Task 151-02-01: Classify Swoosh evidence without changing the adapter contract** — `ee95598c` (test, RED) and `5b110177` (feat, GREEN)

## Files Created/Modified

- `lib/mailglass/outbound/dispatch_outcome.ex` — closed outcome constructors, classifier, and safe projection.
- `lib/mailglass/adapters/swoosh.ex` — additive bounded provider evidence and malformed-status guard.
- `test/mailglass/outbound/dispatch_outcome_test.exs` — classification, privacy, and text-matching contract tests.
- `test/mailglass/adapters/swoosh_test.exs` — Swoosh evidence compatibility coverage.

## Decisions Made

- Unknown adapter errors, timeouts, exits, malformed values, and unproven transport failures are uncertain to prevent duplicate sends.
- Provider response bodies and exception causes remain available only in existing internal error compatibility fields; they are excluded from the new safe projection.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test fixture] Corrected the suppression error type in the terminal-classification test.**
- **Found during:** Task 151-02-01
- **Issue:** The test constructed `SuppressedError` with unsupported `:email` type.
- **Fix:** Used the supported `:address` type.
- **Files modified:** `test/mailglass/outbound/dispatch_outcome_test.exs`
- **Verification:** Focused tagged suite passed.
- **Committed in:** `5b110177`

## Issues Encountered

The `state.advance-plan` helper could not parse this repository's legacy `STATE.md` plan-counter format. Other state, roadmap, metric, decision, and requirement updates completed successfully.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 151-04 can consume `DispatchOutcome.classify/1` and match only the closed class/reason contract when settling worker results.

## Self-Check: PASSED

- Created classifier and test files exist.
- RED and GREEN commits `ee95598c` and `5b110177` exist in git history.
