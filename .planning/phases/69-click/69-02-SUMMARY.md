---
phase: 69-click
plan: "02"
subsystem: docs
tags: [demo, docs, exunit, dx-03]
requires:
  - phase: 69-click
    provides: canonical scope and language decisions for click-around UX/docs
provides:
  - Canonical demo README quickstart, persona/JTBD, seeded stories, click path, and boundary language
  - Executable docs contract test that fails closed on wording and route drift
affects: [phase-70-browser-evidence, demo-docs]
tech-stack:
  added: []
  patterns: [textual docs-contract assertions via ExUnit and File.read!]
key-files:
  created: [reference/demo_app/test/mailglass_demo/docs_contract_test.exs]
  modified: [reference/demo_app/README.md]
key-decisions:
  - "Kept canonical demo truth in reference/demo_app/README.md only (D-07/D-08)."
  - "Kept verification purely text-based with no DOM/browser coupling (D-13 to D-15)."
patterns-established:
  - "Pin critical docs language and routes with exact-string contract assertions."
requirements-completed: [DX-03]
duration: 2min
completed: 2026-06-01
---

# Phase 69 Plan 02: Click-Around UX and Docs Summary

**Canonical demo docs now pin quickstart, click-path, seeded stories, reset semantics, and boundary claims with executable ExUnit contract checks.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-01T22:43:34Z
- **Completed:** 2026-06-01T22:45:14Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Expanded `reference/demo_app/README.md` into the canonical Phase 69 quickstart and click guide with required sections and exact boundary/reset sentences.
- Added `reference/demo_app/test/mailglass_demo/docs_contract_test.exs` as a fail-closed textual contract for sections, commands, routes, stories, reset wording, and boundary language.
- Verified targeted and full demo-app test suites pass with warnings-as-errors.

## Task Commits

1. **Task 1: Expand the demo README into the canonical quickstart and what-to-click guide** - `5d154a1b` (docs)
2. **Task 2: Add a docs contract test that fails closed on quickstart, route, and boundary drift** - `1f96a27f` (test)

## Files Created/Modified
- `reference/demo_app/README.md` - Canonical quickstart, persona/JTBD, seeded data, click flow, dependency mode, and strict demo boundary wording.
- `reference/demo_app/test/mailglass_demo/docs_contract_test.exs` - ExUnit text assertions over README contract tokens.

## Decisions Made
- None - followed plan as specified.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed README path resolution in docs contract test**
- **Found during:** Task 2 verification
- **Issue:** `File.read!` pointed at `test/README.md` and failed compilation.
- **Fix:** Updated path from `../README.md` to `../../README.md`.
- **Files modified:** `reference/demo_app/test/mailglass_demo/docs_contract_test.exs`
- **Verification:** `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/docs_contract_test.exs --warnings-as-errors` passed.
- **Committed in:** `1f96a27f`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No scope creep; correction required to make contract test executable.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None.

## Verification Results

- `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/docs_contract_test.exs --warnings-as-errors` -> PASS (2 tests, 0 failures)
- `cd reference/demo_app && MIX_ENV=test mix test --warnings-as-errors` -> PASS (17 tests, 0 failures)

## Self-Check: PASSED

- Found file: `.planning/phases/69-click/69-02-SUMMARY.md`
- Found commit: `5d154a1b`
- Found commit: `1f96a27f`
