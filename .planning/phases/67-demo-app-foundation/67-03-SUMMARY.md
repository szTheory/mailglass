---
phase: 67-demo-app-foundation
plan: 03
subsystem: demo
tags: [phoenix, demo-app, reset, verification-lane, playwright]
requires:
  - phase: 67-demo-app-foundation
    provides: Demo app foundation, health-gated compose startup, and scope-lock guardrails
provides:
  - Deterministic reset proof for seeded outbound/inbound/suppression/evidence/replay data counts
  - Demo-only scriptable reset endpoint for browser evidence runs
  - Root verify.phase67 lane with reusable Phase 67 trust checks
affects: [phase-68, demo-evidence, reference/demo_app]
tech-stack:
  added: []
  patterns: [demo-only reset endpoints, phase-scoped verify aliases, bounded evidence wording]
key-files:
  created:
    - .planning/phases/67-demo-app-foundation/67-03-SUMMARY.md
    - reference/demo_app/test/test_helper.exs
    - reference/demo_app/test/support/data_case.ex
    - reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs
  modified:
    - reference/demo_app/lib/mailglass_demo_web/router.ex
    - reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex
    - reference/demo_app/README.md
    - reference/demo_app/assets/e2e/demo.spec.js
    - mix.exs
key-decisions:
  - "Used deterministic business-key snapshots (counts, provider IDs, event types) instead of raw UUID identity equality."
  - "Added `POST /demo/evidence/reset` under MailglassDemoWeb with destructive wording and DemoData.reset!/0 backing."
  - "Implemented `mix verify.phase67` at repo root to bundle Phase 67 readiness checks into one reusable gate."
patterns-established:
  - "Demo evidence automation can reset state through a demo-only endpoint while preserving human `/demo/reset` flow."
  - "Phase-level readiness gates are encoded as root verify aliases with explicit source assertions."
requirements-completed: [DEMO-01, DEMO-02, DX-01, DX-02]
duration: 24min
completed: 2026-06-01
---

# Phase 67 Plan 03: Demo Reset Determinism and Verification Lane Summary

**Phase 67 now has executable deterministic reset proof plus a one-command `verify.phase67` lane and bounded `demo_browser_evidence.v1` wording for demo-only adoption evidence.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-06-01T15:58:00Z
- **Completed:** 2026-06-01T16:22:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Added demo-app reset determinism test proving repeated reset runs converge to the same outbound/inbound/suppression/evidence/replay counts and stable business keys.
- Added demo-only `POST /demo/evidence/reset` endpoint wired to `MailglassDemo.DemoData.reset!/0` with explicit destructive response wording.
- Added root `mix verify.phase67` alias running scope lock, demo-app tests, compose config validation, and compose source assertions.
- Updated demo README with destructive reset wording plus explicit `demo_browser_evidence.v1`/not-stable-public-API boundary language.

## Task Commits

1. **Task 1: Add scriptable deterministic reset proof** - `7a24342` (feat)
2. **Task 2: Add Phase 67 verification lane and bounded evidence wording** - `af68014` (feat)

## Files Created/Modified
- `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs` - Deterministic reset contract test for counts and stable seeded business keys.
- `reference/demo_app/test/support/data_case.ex` - SQL sandbox case template for demo-app DB tests.
- `reference/demo_app/test/test_helper.exs` - ExUnit bootstrap for demo-app tests.
- `reference/demo_app/lib/mailglass_demo_web/router.ex` - Added demo-only `POST /demo/evidence/reset` route.
- `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex` - Added `evidence_reset/2` JSON action with destructive reset warning.
- `mix.exs` - Added `verify.phase67` alias and preferred env mapping.
- `reference/demo_app/README.md` - Added destructive reset wording and bounded evidence artifact contract copy.
- `reference/demo_app/assets/e2e/demo.spec.js` - Added per-test reset call to evidence reset endpoint.

## Decisions Made
- Chose deterministic snapshot assertions based on counts and seeded domain keys because demo tables use UUIDs, making strict ID equality non-deterministic across resets.
- Kept both reset surfaces: existing human click path (`POST /demo/reset`) and scriptable evidence path (`POST /demo/evidence/reset`).
- Kept evidence boundary language in README explicit that artifacts are adoption evidence and not stable public API guarantees.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Bootstrapped missing demo test database during Task 1 verification**
- **Found during:** Task 1 verification
- **Issue:** `cd reference/demo_app && mix test` failed because `mailglass_demo_test` database did not exist.
- **Fix:** Ran `MIX_ENV=test mix ecto.create` and `MIX_ENV=test mix ecto.migrate` in `reference/demo_app`, then reran tests.
- **Files modified:** None (environment setup only)
- **Verification:** `cd reference/demo_app && mix test` passed.
- **Committed in:** N/A (environment-only unblock)

**2. [Rule 1 - Bug] Fixed verify alias shell execution in Task 2**
- **Found during:** Task 2 verification
- **Issue:** `mix verify.phase67` failed because `mix cmd` cannot parse `&&` without shell wrapping.
- **Fix:** Updated alias command to `cmd --cd reference/demo_app sh -c \"...\"`.
- **Files modified:** `mix.exs`
- **Verification:** `mix verify.phase67` passed after patch.
- **Committed in:** `af68014`

---

**Total deviations:** 2 auto-fixed (Rule 1: 1, Rule 3: 1)  
**Impact on plan:** Both fixes were necessary to satisfy required verification and keep the lane deterministic. No scope creep.

## Issues Encountered
None beyond the two auto-fixed items above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Deterministic reset + scriptable reset endpoint are available for browser evidence phases.
- Phase 67 proof lane can be rerun as `mix verify.phase67` before advancing to Phase 68.

## Self-Check: PASSED
- Confirmed file exists: `.planning/phases/67-demo-app-foundation/67-03-SUMMARY.md`
- Confirmed commits exist: `7a24342`, `af68014`
