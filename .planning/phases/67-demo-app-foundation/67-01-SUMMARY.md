---
phase: 67-demo-app-foundation
plan: 01
subsystem: demo
tags: [phoenix, demo-app, dependency-mode, scope-lock]
requires: []
provides:
  - Demo app dependency switching supports local-path default and published Hex smoke mode.
  - Reference host scope lock now fails on rich-demo marker drift.
affects: [reference/demo_app, reference/host_app, trust-boundary]
tech-stack:
  added: []
  patterns: [dual dependency mode, source-level scope lock checks]
key-files:
  created: [.planning/phases/67-demo-app-foundation/67-01-SUMMARY.md]
  modified:
    - reference/demo_app/mix.exs
    - reference/demo_app/README.md
    - reference/host_app/SCOPE.md
    - test/reference_host/scope_lock_contract_test.exs
key-decisions:
  - "Keep local path dependencies as default and tighten only Hex-mode inbound constraint to ~> 0.3.0."
  - "Enforce reference-host boundary by scanning host files for rich-demo markers."
patterns-established:
  - "Demo dependency mode is wiring-only and does not imply stable public API guarantees."
  - "Reference host boundary is contract-tested against rich-demo marker drift."
requirements-completed: [DEMO-01, DEMO-02]
duration: 19min
completed: 2026-06-01
---

# Phase 67 Plan 01: Demo App Foundation Summary

**Demo app now has executable local-vs-Hex dependency modes with current published constraints, and reference-host scope lock blocks rich-demo drift.**

## Performance

- **Duration:** 19 min
- **Started:** 2026-06-01T18:48:00Z
- **Completed:** 2026-06-01T19:07:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Tightened demo Hex dependency mode to current published constraints while preserving local-path default mode.
- Clarified demo README dependency mode intent: local iteration vs published-package smoke checks.
- Added executable boundary lock so `reference/host_app` fails tests if rich-demo markers appear.

## Task Commits

1. **Task 1: Tighten and document demo dependency mode** - `703a9ae` (fix)
2. **Task 2: Protect the reference-host boundary** - `ae05d0e` (test)

## Files Created/Modified
- `reference/demo_app/mix.exs` - Tightened Hex-mode inbound dependency constraint to `~> 0.3.0`.
- `reference/demo_app/README.md` - Clarified dependency mode wording and published-smoke command.
- `reference/host_app/SCOPE.md` - Explicitly routes rich click-around demo to `reference/demo_app`.
- `test/reference_host/scope_lock_contract_test.exs` - Added host-app source scan blocking rich-demo marker tokens.

## Decisions Made
- Kept dependency switching limited to demo-app wiring (`MAILGLASS_DEMO_DEPS`) and did not add any Mailglass public API surface.
- Enforced boundary drift via source token assertions for `MailglassDemo`, `Northstar Ops`, and `demo dashboard`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Provisioned local Postgres on `localhost:5432` for scope-lock test execution**
- **Found during:** Task 2 verification
- **Issue:** `mix test test/reference_host/scope_lock_contract_test.exs` failed because repo test boot could not connect to Postgres on `localhost:5432`.
- **Fix:** Started ephemeral local Postgres container (`mailglass-test-pg`) on `5432` and reran the test command.
- **Files modified:** None
- **Verification:** `mix test test/reference_host/scope_lock_contract_test.exs` passed (3 tests, 0 failures).
- **Committed in:** N/A (environment-only unblock)

---

**Total deviations:** 1 auto-fixed (Rule 3: 1)
**Impact on plan:** No scope creep; unblock was required to execute mandated verification.

## Issues Encountered
None beyond the transient local database availability gate resolved above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Dependency-mode and host-boundary foundations are in place for later demo compose/reset/evidence plans.
- No code blockers remain for Phase 67 follow-on plans.

## Self-Check: PASSED
- Confirmed file exists: `.planning/phases/67-demo-app-foundation/67-01-SUMMARY.md`
- Confirmed commits exist: `703a9ae`, `ae05d0e`
