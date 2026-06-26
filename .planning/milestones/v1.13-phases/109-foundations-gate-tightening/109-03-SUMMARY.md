---
phase: 109-foundations-gate-tightening
plan: "03"
subsystem: ui
tags: [tailwind, daisyui, phoenix-liveview, design-system, ratchet]
requires:
  - phase: 109-02
    provides: "Semantic layer, focus-ring, overlay, and admin-root utilities with current admin code clean"
provides:
  - "Hard conformance gates for z-index, focus-ring, root isolation, token-scope, radius, shadow, border, and arbitrary sizing"
  - "Extended type-scale gate covering text-xl, text-2xl, and text-3xl while preserving text-base-content"
  - "Ratchet baseline schema v3 with light, dark, and system theme axes"
  - "System baseline cells seeded from existing light scores without a pillar re-score"
affects: [phase-109, phase-110, phase-116, mailglass_admin, admin-design-system]
tech-stack:
  added: []
  patterns:
    - "Conformance gates remain BASH_SOURCE-anchored and aggregate failures through one errors counter"
    - "Ratchet system cells are shape coverage only until the later full re-score phase"
key-files:
  created:
    - .planning/phases/109-foundations-gate-tightening/109-03-SUMMARY.md
  modified:
    - mailglass_admin/scripts/check-conformance.sh
    - mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs
    - mailglass_admin/docs/ui-baseline-scores.json
key-decisions:
  - "The border conformance gate uses a raw palette whitelist rather than a generic token-scale regex so semantic DaisyUI tokens like border-base-300 remain allowed."
  - "The ratchet schema v3 system axis copies each block's light score and preserves prior/current run IDs to avoid a Phase 109 pillar re-score."
patterns-established:
  - "Design-system gate additions live in the existing CI-invoked conformance script instead of separate ad hoc scans."
  - "Ratchet coverage treats light, dark, and system as explicit required cells in both prior and current baselines."
requirements-completed: [FND-01, FND-02, FND-03, FND-05]
duration: 8 min
completed: 2026-06-18
status: complete
---

# Phase 109 Plan 03: Conformance Gates And Ratchet Schema Summary

**Hard admin design-system gates now fail closed on foundation regressions, and the ratchet baseline has an explicit system theme axis without re-scoring.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-18T17:06:00Z
- **Completed:** 2026-06-18T17:13:19Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Extended `mailglass_admin/scripts/check-conformance.sh` with hard gates for raw z-index, focus-ring idioms, missing admin root isolation, theme hook/storage/picker creep, raw radius, raw shadow, raw border, and arbitrary size/spacing utilities.
- Extended the existing TYPE gate to reject `text-xl`, `text-2xl`, and `text-3xl` while keeping the boundary-aware `text-base-content` exclusion intact.
- Updated the ratchet ExUnit test to schema version 3 with `["light", "dark", "system"]` themes and 54 required cells per block.
- Added `system` scores to every prior/current surface-pillar object by copying the matching light score, preserving both run IDs and all existing light/dark judgments.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add hard gates to the existing conformance script** - `4377c146` (test)
2. **Task 2: Bump ratchet schema to v3 and seed system cells without re-scoring** - `956d5008` (test)

**Plan metadata:** this summary commit

## Files Created/Modified

- `mailglass_admin/scripts/check-conformance.sh` - Adds the new fail-closed conformance gates while preserving BASH_SOURCE-rooted lib discovery, the shared `errors` counter, and the final aggregate exit block.
- `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs` - Asserts schema v3, light/dark/system coverage, 54-cell completeness, valid score range, and only-forward comparisons.
- `mailglass_admin/docs/ui-baseline-scores.json` - Moves to schema v3 and adds system scores copied from each block's light values.

## Decisions Made

- The border gate rejects known raw Tailwind palette scales (`red-500`, `slate-200`, etc.) rather than any `*-NNN` suffix. The generic form would incorrectly reject semantic DaisyUI tokens such as `border-base-300`, which the plan acceptance criteria explicitly allows.
- The ratchet system axis is seeded from light values in both prior and current blocks. This is coverage shape work only; the full pillar re-score remains deferred to the ratchet phase.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced the over-broad plan border regex with a palette-specific gate**

- **Found during:** Task 1 (Add hard gates to the existing conformance script)
- **Issue:** The plan's standalone verification regex used `[a-z]+-[0-9]{2,3}` for border colors, which flags semantic `border-base-300` classes even though the acceptance criteria says `border-base-*` must remain valid.
- **Fix:** Implemented the committed `BORDER-GATE` with an explicit raw Tailwind palette list while preserving semantic `border`, `border-base-*`, `border-primary`, `border-secondary`, `border-error`, and related semantic tokens.
- **Files modified:** `mailglass_admin/scripts/check-conformance.sh`
- **Verification:** `bash mailglass_admin/scripts/check-conformance.sh` and package-root `bash scripts/check-conformance.sh` both returned `OK: design-system conformance clean.`
- **Committed in:** `4377c146`

---

**Total deviations:** 1 auto-fixed (blocking plan-regex defect).
**Impact on plan:** The implemented gate matches the stated acceptance criteria and avoids a false positive on the existing semantic border contract.

## Issues Encountered

`mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors` emitted expected optional Oban warnings only; all tests passed.

## User Setup Required

None - no external service configuration required.

## Verification

- `bash mailglass_admin/scripts/check-conformance.sh` -> `OK: design-system conformance clean.`
- `cd mailglass_admin && bash scripts/check-conformance.sh` -> `OK: design-system conformance clean.`
- `rg -n 'Z-INDEX-GATE|FOCUS-RING-GATE|SCOPE-GATE|TOKEN-SCOPE-GATE|RADIUS-GATE|SHADOW-GATE|BORDER-GATE|SIZE-GATE|text-xl|text-2xl|text-3xl|errors=0|BASH_SOURCE' mailglass_admin/scripts/check-conformance.sh` -> required gate labels and anchors found.
- `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors` -> 4 tests, 0 failures.
- `node -e 'const fs=require("fs"); const b=JSON.parse(fs.readFileSync("mailglass_admin/docs/ui-baseline-scores.json","utf8")); const fail=(m)=>{throw new Error(m)}; if (b.schema_version!==3) fail("schema"); if (b.prior.run_id!=="2026-06-13-phase-95-baseline") fail("prior run_id"); if (b.current.run_id!=="2026-06-16-phase-103") fail("current run_id"); for (const block of ["prior","current"]) { for (const pillars of Object.values(b[block].surfaces)) { for (const scores of Object.values(pillars)) { if (!Object.prototype.hasOwnProperty.call(scores,"system")) fail("system missing"); if (scores.system!==scores.light) fail("system changed"); } } }'` -> passed.

## Self-Check: PASSED

Both tasks are committed, the tightened conformance script is cwd-independent, the ratchet test enforces 54 cells across both blocks, preserved run IDs are verified, and no pillar re-score artifact was introduced.

## Next Phase Readiness

Ready for Plan 109-04 to add the structural WCAG/system Playwright proof and run the final Phase 109 validation battery. FND-05 still receives that structural proof in 109-04 even though this plan completed the conformance and ratchet portions of the requirement.

---
*Phase: 109-foundations-gate-tightening*
*Completed: 2026-06-18*
