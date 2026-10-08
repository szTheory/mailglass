---
phase: 168-shared-workspace-and-usable-baseline
plan: 10
subsystem: ui
tags: [tailwind-css, spacing, heex, exunit, playwright]

# Dependency graph
requires:
  - phase: 168-09
    provides: Shared operator and Preview baseline for the final UXF-03 gap closure
provides:
  - Six-template 4px spacing compliance across shared operator, Inbound, and Preview UI
  - Source, generated-CSS, and rendered computed-style regression checks
affects: [Phase 168 verification, UXF-03]

# Actuals (#2632)
actuals:
  tokens: 67201
  tasks: 2
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Guard named HEEx templates against half-step Tailwind spacing utilities and verify semantic CSS utility output."
    - "Use the existing Playwright browser lane for computed styles from served UI fixtures."

key-files:
  created:
    - .planning/phases/168-shared-workspace-and-usable-baseline/168-10-tdd-red-evidence.json
    - .planning/phases/168-shared-workspace-and-usable-baseline/168-10-playwright-red.xml
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
    - mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
    - mailglass_admin/test/mailglass_admin/token_parity_test.exs
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/priv/static/app.css

key-decisions:
  - "Reuse the approved --spacing-xs token at 4px through mt-xs and gap-xs utilities."
  - "Keep the rendered browser check in the existing advisory operator-browser lane."

patterns-established:
  - "Source tests enumerate the protected templates and identify the exact offending utility."
  - "Rendered acceptance reads computed style values from real browser fixtures."

requirements-completed: [UXF-03]

coverage:
  - id: D1
    description: "All 13 shared operator and Preview half-step spacing classes use existing 4px xs utilities; source, generated CSS, and rendered styles are checked deterministically."
    requirement: UXF-03
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/token_parity_test.exs#shared operator and Preview templates stay on the 4px spacing grid"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/flows.spec.js#Phase 168 shared spacing: operator icon and Preview scenario gap use 4px"
        status: pass
      - kind: other
        ref: "mix mailglass_admin.assets.build"
        status: pass
    human_judgment: false

# Metrics
duration: 8min
completed: 2026-10-08
status: complete
plan_head_before: 15f1b3baf9d0de575893b1a54ecd085df93370b4
plan_head_after: 6f15e8c8c6be3432503912021ed418ca8293e24f
commits: 3
---

# Phase 168 Plan 10: Shared 4px Spacing Summary

**The six shared operator and Preview templates now use the approved 4px xs grid, guarded by source, generated CSS, and rendered browser checks.**

## Performance

- **Duration:** 8 minutes
- **Started:** 2026-10-08T23:23:34Z
- **Completed:** 2026-10-08T23:31:52Z
- **Tasks:** 2
- **Files modified:** 11, including the two persisted RED evidence artifacts

## Accomplishments

- Replaced all eight operator and Inbound icon `mt-0.5` classes with `mt-xs`.
- Replaced both Preview feedback icon margins with `mt-xs` and all three scenario-list `gap-0.5` classes with `gap-xs`.
- Added a six-template source guard, source/bundle token and utility checks, and a focused browser assertion for computed 4px margin and row gap.
- Rebuilt `priv/static/app.css` so the served bundle reflects the source classes.

## Task Commits

1. **Task 1: Put shared operator and Inbound icon margins on the 4px grid** - `9e7b8c6d` (`fix`)
2. **Task 2 RED: Add the source/CSS contract and rendered spacing assertion** - `ae070fae` (`test`)
3. **Task 2 GREEN: Finish Preview spacing and rebuild the bundle** - `6f15e8c8` (`feat`)

## Files Created/Modified

- Six named HEEx templates: all 13 2px classes now use `mt-xs` or `gap-xs`.
- `mailglass_admin/test/mailglass_admin/token_parity_test.exs` - rejects half-step Tailwind spacing utilities across the six templates and verifies the source token and generated rules.
- `mailglass_admin/e2e/flows.spec.js` - checks 4px computed margin in rendered Inbound UI and 4px Preview scenario row gap.
- `mailglass_admin/priv/static/app.css` - regenerated bundle.
- `168-10-tdd-red-evidence.json` and `168-10-playwright-red.xml` - validated failing browser assertion evidence.

## TDD Gate Compliance

- **RED:** `mix test test/mailglass_admin/token_parity_test.exs --seed 1` ran 4 tests and failed the new target assertion on exactly two Preview `mt-0.5` classes and three `gap-0.5` classes. The focused Playwright target also failed as intended: the operator icon was 4px while the rendered Preview scenario list row gap was 2px. `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK` for the Playwright JUnit report.
- **GREEN:** Asset build and source/CSS contract passed; Playwright read a 4px computed margin and 4px computed Preview row gap.
- **REFACTOR:** None needed; the change only replaces spacing utilities and adds regression assertions.
- The first ExUnit RED attempt exposed a missing capture group in the new regex. The test was corrected and rerun before source implementation; the validated RED result is the five-class assertion failure above.

## Verification

- Task 1 focused component/shell command: 131 tests, 0 failures.
- Task 2 asset build and focused TokenParityTest: 4 tests, 0 failures.
- Plan final focused command: `mix mailglass_admin.assets.build`, then the three focused ExUnit files, then `npm run --silent test:operator-browser -- --grep "Phase 168 shared spacing"` — 135 ExUnit tests and 1 Playwright test passed.
- The browser job remains advisory outside CI Green. No owner UAT was required under D-52 because these criteria are deterministic.

## Decisions Made

- Reused the existing `--spacing-xs: 4px` token and its generated `mt-xs` / `gap-xs` utilities.
- Kept the rendered computed-style assertion in the existing Playwright suite without changing CI policy.

## Deviations from Plan

- The rendered operator-side margin sample uses the Inbound quick-view error icon from a named in-scope template. The deliveries orientation strip was not a stable icon target in the focused flow fixture; the Inbound fixture provided a deterministic rendered icon using the same approved `mt-xs` utility.
- Recorded in `.planning/WINDOWS.md` as deviation 47 and waived with the scope-equivalence rationale; it is not an open defect.

## Issues Encountered

- Chromium could not start inside the restricted sandbox because macOS denied a Mach port call. The same focused command ran successfully with sandbox escalation.
- Git metadata writes were sandbox-blocked; approved escalation allowed the three scoped commits. Unrelated planning changes remained unstaged.

## User Setup Required

None.

## Next Phase Readiness

The sole reported D-03 spacing truth is covered by deterministic source, generated-CSS, and browser evidence. Phase 168 can refresh verification for UXF-03.

---
*Phase: 168-shared-workspace-and-usable-baseline*
*Completed: 2026-10-08*

## Self-Check: PASSED

- Confirmed the summary, RED evidence, generated CSS, and JUnit report exist.
- Confirmed task commits `9e7b8c6d`, `ae070fae`, and `6f15e8c8` are ancestors of HEAD.
- Confirmed the plan ledger measures 3 commits from `15f1b3baf9d0de575893b1a54ecd085df93370b` through `6f15e8c8c6be3432503912021ed418ca8293e24f`.
