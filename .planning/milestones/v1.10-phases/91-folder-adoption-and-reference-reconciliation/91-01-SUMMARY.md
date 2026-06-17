---
phase: 91-folder-adoption-and-reference-reconciliation
plan: 01
subsystem: validation
tags: [brandbook, bash, gate, evidence]

requires: []
provides:
  - Phase-local adoption gate for canonical brandbook/
  - Phase 91 evidence record with Phase base and setup sections
  - Wave 0 validation metadata marked Nyquist-compliant
affects:
  - Phase 91 folder adoption
  - Phase 91 final verification

tech-stack:
  added: []
  patterns:
    - Phase-local Bash gate adapted from v1.9 quality gate
    - Evidence-led adoption transcript

key-files:
  created:
    - .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh
    - .planning/phases/91-folder-adoption-and-reference-reconciliation/91-gate-evidence.md
  modified:
    - .planning/phases/91-folder-adoption-and-reference-reconciliation/91-VALIDATION.md

key-decisions:
  - "Check 9 now validates Phase 91 adoption invariants instead of the obsolete frozen-codex baseline."
  - "The recorded Phase base is the post-gate commit used for adoption diff-scope evidence."

patterns-established:
  - "Phase 91 gate remains outside brandbook/ so canonical brand artifacts stay artifact-only."
  - "Final adoption scope is measured from the evidence file's Phase base hash."

requirements-completed: [FOLD-01, FOLD-02, FOLD-03]

duration: 10 min
completed: 2026-06-12
---

# Phase 91 Plan 01: Adoption Gate and Evidence Contract Summary

**Phase-local Bash gate and evidence transcript for adopting the fable brand book as canonical `brandbook/`**

## Performance

- **Duration:** 10 min
- **Started:** 2026-06-12T21:55:00Z
- **Completed:** 2026-06-12T22:05:37Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created `.planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` from the Phase 90 gate with `BB="brandbook"`.
- Replaced the frozen-codex Check 9 with Phase 91 adoption invariants for canonical folder presence, old codex file absence, active pointers, `.DS_Store`, and diff-scope allowlisting.
- Created `91-gate-evidence.md` with the required sections and syntax proof, then marked Wave 0 validation metadata complete.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the Phase 91 adoption gate** - `63701373` (chore)
2. **Task 2: Create the evidence record and close Wave 0 validation setup** - `ccb663fd` (chore)

**Plan metadata:** pending (docs commit)

## Files Created/Modified

- `.planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` - Phase 91 gate adapted to validate canonical `brandbook/`.
- `.planning/phases/91-folder-adoption-and-reference-reconciliation/91-gate-evidence.md` - Evidence transcript skeleton with Phase base and Wave 0 syntax proof.
- `.planning/phases/91-folder-adoption-and-reference-reconciliation/91-VALIDATION.md` - Wave 0 and Nyquist flags set true after gate syntax passed.

## Decisions Made

- Check 9 intentionally fails until later plans complete the folder move and reference reconciliation; Plan 91-01 verifies script structure and syntax only.
- `Phase base:` records the post-gate commit so the final Check 9 diff-scope proof focuses on adoption/reference/evidence work.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 0 is complete. Plan 91-02 can use the phase-local gate and evidence file while replacing `brandbook/` via Git operations.

## Self-Check: PASSED

- `bash -n .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` exited 0.
- `grep -n '^BB="brandbook"$' .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` printed one line.
- `91-gate-evidence.md` contains `Phase base:`, `Wave 0 Gate Setup`, and `Adoption Diff Scope`.
- `91-VALIDATION.md` frontmatter contains `wave_0_complete: true` and `nyquist_compliant: true`.

---
*Phase: 91-folder-adoption-and-reference-reconciliation*
*Completed: 2026-06-12*
