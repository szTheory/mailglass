---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 10
subsystem: repository-closeout
tags: [closeout, scheduled-controls, freshness, provenance, bash, exunit]
requires:
  - phase: 164-09
    provides: canonical closeout boundary and authoritative scheduled-evidence collection
provides:
  - registry-specific scheduled-control freshness preserved through closeout composition
  - sourceable production predicate with exact identity and provenance rejection coverage
affects: [164-11, 164-12, TRTH-03, repository-closeout]
actuals:
  tokens: 2038
  tasks: 1
  commits: 3
tech-stack:
  added: []
  patterns: [single freshness authority, sourceable bash predicate, adversarial provenance mutations]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-10-SUMMARY.md
  modified:
    - scripts/closeout_repository_truth.sh
    - test/scripts/phase_164_closeout_test.exs
key-decisions:
  - "The authoritative scheduled-control sweep remains the sole registry-specific age authority consumed by closeout."
  - "Closeout still independently rejects mismatched main SHA, event, branch, terminal status, workflow SHA, evidence validity, and policy-result provenance."
patterns-established:
  - "Composed evidence consumers validate identity and provenance without replacing an upstream registry-driven freshness verdict."
requirements-completed: [TRTH-03]
coverage:
  - id: D1
    description: "Closeout accepts authoritative daily evidence older than three hours while failing closed on identity and provenance mutations."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "mix test test/scripts/phase_164_closeout_test.exs test/scripts/scheduled_control_evidence_test.exs --warnings-as-errors --no-deps-check"
        status: pass
      - kind: other
        ref: "bash -n scripts/closeout_repository_truth.sh"
        status: pass
    human_judgment: false
duration: 3min
completed: 2026-08-28
status: complete
---

# Phase 164 Plan 10: Authoritative Scheduled Freshness Summary

**Closeout now preserves registry-specific scheduled freshness from the authoritative sweep while independently enforcing every exact identity and provenance invariant.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-08-28T20:25:23Z
- **Completed:** 2026-08-28T20:28:00Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Extracted `scheduled_report_is_acceptable` from the production closeout script behind a source-safe execution guard.
- Removed the duplicate blanket three-hour comparison without changing any configured maximum age or authoritative sweep behavior.
- Added an end-to-end fixture whose daily controls are four hours old plus independent rejection mutations for exact SHA, event, branch, completion, workflow SHA, evidence-valid provenance, and result status.

## Task Commits

The TDD task was committed atomically:

1. **RED: Add failing authoritative freshness and provenance contract** — `064dd996` (test)
2. **GREEN: Trust authoritative scheduled freshness in closeout** — `6e825d2e` (feat)

## Files Created/Modified

- `scripts/closeout_repository_truth.sh` — Sourceable scheduled-report predicate and guarded CLI using the authoritative sweep verdict without a second age threshold.
- `test/scripts/phase_164_closeout_test.exs` — Dynamic three-control freshness fixture and adversarial identity/provenance mutations against production code.

## Decisions Made

- Registry-specific age comparison remains exclusively in `scripts/scheduled_control_evidence.sh`, driven by `.github/scheduled-controls.json`.
- Closeout continues to require exact expected main SHA, schedule event, completed status, main branch, head and workflow SHA, evidence validity, and pass or evidence-backed blocked result shape.

## Verification

Passed:

```text
mix test test/scripts/phase_164_closeout_test.exs test/scripts/scheduled_control_evidence_test.exs --warnings-as-errors --no-deps-check
15 tests, 0 failures

bash -n scripts/closeout_repository_truth.sh
mix format --check-formatted test/scripts/phase_164_closeout_test.exs
git diff --check
```

The RED run failed at the new positive assertion before the production predicate existed; the same contract passed after GREEN.

## TDD Gate Compliance

- RED gate: `064dd996`
- GREEN gate: `6e825d2e`
- Refactor: not needed; the focused extraction remained clear and the full verification stayed green.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The tracked freshness repair is ready for normal protected integration and exact-SHA evidence capture in Plan 164-11.
- No workflow was dispatched or rerun, no authority changed, and configured ages remain `10800`, `129600`, and `129600` seconds.

## Self-Check: PASSED

- Both modified production/test files and this summary exist.
- Commits `064dd996` and `6e825d2e` exist in Git history.
- Focused ExUnit, Bash syntax, formatting, and diff checks pass.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-08-28*
