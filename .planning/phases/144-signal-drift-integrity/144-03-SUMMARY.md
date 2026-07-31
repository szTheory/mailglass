---
phase: 144-signal-drift-integrity
plan: 03
subsystem: conformance
tags: [bash, elixir, exunit, heroicons, hermetic-integration]
requires:
  - phase: 144-signal-drift-integrity
    provides: Existing ICON-EXISTS-GATE and signal-integrity phase contract
provides:
  - Bounded dynamic Heroicon extraction against the vendored inventory
  - Fail-closed diagnostics for non-finite dynamic icon expressions
  - Hermetic real-gate fixtures with guaranteed cleanup
affects: [admin-conformance, vendored-heroicons, ci-lane-contract]
tech-stack:
  added: []
  patterns: [real-shell-gate-fixtures, finite-static-expression-resolution, fail-closed-source-diagnostics]
key-files:
  created: [test/scripts/icon_exists_gate_test.exs]
  modified: [mailglass_admin/scripts/check-conformance.sh]
key-decisions:
  - "Use the existing vendored Heroicon key set as the sole inventory authority."
  - "Resolve only finite literal concatenation/interpolation and fail closed for non-finite dynamic expressions."
patterns-established:
  - "Conformance gate tests copy the real package layout and executable into a unique temporary fixture, register cleanup before writes, then assert removal after execution."
requirements-completed: [CONFORM-02]
metrics:
  duration: 3min
  completed: 2026-07-31
  status: complete
---

# Phase 144 Plan 03: Dynamic Icon Integrity Summary

**The real admin conformance executable now expands finite computed Heroicon names, rejects unresolved dynamic expressions, and proves both outcomes in self-cleaning isolated fixtures.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-31T20:56:58Z
- **Completed:** 2026-07-31T20:59:25Z
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments

- Extended `ICON-EXISTS-GATE` without replacing its inventory, diff, zero-scan, error-accumulator, or temporary-file lifecycle.
- Unioned literal icon references with finite concatenated and interpolated values at the `<.icon name={...}>` boundary.
- Added a source-location diagnostic that fails non-finite concatenation or interpolation instead of silently accepting an uncheckable icon reference.
- Added focused ExUnit coverage that runs copied real gates against complete package-layout fixtures, observes missing computed names, and verifies fixture roots are removed after both success and failure.

## Task Commits

1. **Task 1 RED: Dynamic icon gate specification** — `03e58f26` (`test`)
2. **Task 1 GREEN: Bounded dynamic icon extraction** — `668f574f` (`feat`)

## Files Created/Modified

- `mailglass_admin/scripts/check-conformance.sh` — finite dynamic-name extraction plus a fail-closed unresolved-expression report, retaining the vendored-key `comm` comparison.
- `test/scripts/icon_exists_gate_test.exs` — hermetic real-gate integration harness and negative/clean cleanup cases.

## Decisions Made

- The existing `heroicons-inline.js` inventory remains the sole source of truth; no icon registry or historical-name allowlist was added.
- Only finite source expressions are enumerated. Runtime-dependent names are a conformance failure with their fixture/source location and expression class.

## Verification

- `mix test test/scripts/icon_exists_gate_test.exs --warnings-as-errors` — 4 tests, 0 failures; includes computed missing-icon failure, unresolved-expression failure, clean fixture success, and post-run removal checks.
- `bash mailglass_admin/scripts/check-conformance.sh` — `OK: design-system conformance clean.`
- `mix verify.ci_lane_contract` — 126 tests, 0 failures.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The initial fixture omitted the real gate's required `assets/css/app.css`; the RED harness was corrected before the RED commit so it reproduces the complete executable layout. This was a test-fixture prerequisite, not a production deviation.

## User Setup Required

None — all evidence is hermetic and runs the real conformance executable locally.

## Next Phase Readiness

CONFORM-02 now has durable negative-control and cleanup evidence. The remaining Phase 144 plans can rely on the unchanged normal admin tree passing the same conformance command.

## Self-Check: PASSED

- Found `mailglass_admin/scripts/check-conformance.sh` and `test/scripts/icon_exists_gate_test.exs`.
- Found TDD commits `03e58f26` and `668f574f` in git history.
