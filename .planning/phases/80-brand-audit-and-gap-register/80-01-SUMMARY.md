---
phase: 80-brand-audit-and-gap-register
plan: 01
subsystem: brandbook
tags: [brand, audit, gap-register, brandbook, accessibility, repo-hygiene]
requires:
  - phase: 80-context
    provides: Locked Phase 80 decisions D-01 through D-21 and draft brandbook evidence.
provides:
  - Row-addressable Phase 80 brand audit and gap register.
  - Required BRAND-02 surface stress matrix.
  - Phase 81-84 handoff map and Phase 84 validation expectations.
affects: [brandbook, phase-81, phase-82, phase-83, phase-84]
tech-stack:
  added: []
  patterns: [stable brand-gap register, frozen-audit closeout, source-native brandbook]
key-files:
  created:
    - .planning/phases/80-brand-audit-and-gap-register/80-01-SUMMARY.md
  modified:
    - brandbook/brand-audit.md
key-decisions:
  - "Existing brandbook assets are draft inputs from commit 572f3eb2, not approved Phase 81-84 outputs."
  - "Severity 4-5 BRAND-GAP rows require explicit closure or documented deferral before Phase 84 closeout."
  - "Phase 80 approves only the audit/register gate; final tokens, logos, copy, specimens, package proof, and validation scripts remain downstream work."
patterns-established:
  - "BRAND-GAP-NN stable IDs are downstream citation anchors and should not be renumbered after publication."
  - "Phase 84 should close or explicitly defer audit rows without rewriting the frozen Phase 80 audit."
requirements-completed: [BRAND-01, BRAND-02]
duration: 8 min
completed: 2026-06-06
---

# Phase 80 Plan 01: Brand Audit and Gap Register Summary

**Row-addressable brand audit with required-surface stress matrix, stable BRAND-GAP register, and Phase 81-84 handoff gates**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-06T01:33:41Z
- **Completed:** 2026-06-06T01:41:08Z
- **Tasks:** 3
- **Files modified:** 1 source artifact, 1 summary artifact

## Accomplishments

- Recast `brandbook/brand-audit.md` as a Phase 80 audit gate that labels current `brandbook/` assets as draft inputs, not approved outputs.
- Added a strict BRAND-02 required-surface stress matrix covering GitHub, README, Hex.pm, HexDocs, docs UI, code/terminal snippets, landing page, social preview, favicon, small monochrome mark, dark/light mode, diagrams, and UI states.
- Created stable `BRAND-GAP-01` through `BRAND-GAP-12` rows with classification, severity, surface, evidence, rationale, target phase, and acceptance/closeout cue.
- Added Phase 81-84 handoff, deferred/future/legal notes, Phase 84 validation expectations, and an honest final quality gate.

## Task Commits

Each task was committed atomically:

1. **Task 1: Recast executive judgment and brand posture as an audit gate** - `513c7923` (`docs(80-01): recast brand audit posture`)
2. **Task 2: Add required-surface stress matrix and BRAND-GAP register** - `a9ce4423` (`docs(80-01): add brand gap register`)
3. **Task 3: Add Phase 81-84 handoff, deferred notes, validation expectations, and honest final gate** - `f270c4ee` (`docs(80-01): add brand audit handoff gate`)

## Files Created/Modified

- `brandbook/brand-audit.md` - Phase 80 executive audit, required-surface matrix, stable BRAND-GAP register, downstream handoff map, Phase 84 validation expectations, and final quality gate.
- `.planning/phases/80-brand-audit-and-gap-register/80-01-SUMMARY.md` - Plan execution summary and verification record.

## Decisions Made

- Kept the core brand center: "Mailglass makes email visible," "Mail you can see through," and "glass is a metaphor, not a visual excuse."
- Kept `mailglass_admin/docs/design-system.md` as the implemented product UI constraint source; the brandbook is not a second admin UI framework.
- Treated current SVGs as one credible draft direction only; Phase 82 owns logo comparison and approval.
- Recorded Mailglass Lite as deferred name-risk only; no legal/name strategy starts in Phase 80.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep; Phase 80 modified only the planned source artifact.

## Issues Encountered

Targeted Phase 80 checks passed. The broader `mix test` suite was run for context and finished with 1174 tests, 2 failures, 7 skipped. The two failures are outside this plan's write scope:

- `Mailglass.Publish.PostPublishSmokeContractTest` expects the publish workflow consumer-install block to contain `Run mix mailglass.install`.
- `Mailglass.DemoDataTest` reports a reference demo app dependency lock mismatch for `swoosh`; output suggests running `mix deps.get` in that app.

No failure points to `brandbook/brand-audit.md` or any Phase 80-edited source.

## Verification

- `gsd-sdk query frontmatter.validate .planning/phases/80-brand-audit-and-gap-register/80-01-PLAN.md --schema plan` - passed.
- `gsd-sdk query verify.plan-structure .planning/phases/80-brand-audit-and-gap-register/80-01-PLAN.md` - passed.
- `git diff --check -- brandbook/brand-audit.md` - passed.
- `rg` checks for draft-input language, classification vocabulary, `BRAND-GAP-*` rows, and required BRAND-02 surfaces - passed.
- Boundary diff against `brandbook/brand-book.md`, `brandbook/index.html`, tokens, SVG assets, examples, README, and package files - passed.
- `jq -e . brandbook/tokens.json` - passed.
- `xmllint --noout brandbook/assets/*.svg brandbook/examples/*.svg` - passed.
- `xmllint --html --noout brandbook/index.html` - returned success with existing HTML5 tag parser diagnostics.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 81 can consume the frozen audit/register to revise the source brandbook and token language. Phase 82-84 should cite the stable `BRAND-GAP-*` rows rather than reopening the audit structure.

## Self-Check: PASSED

- Key file exists: `brandbook/brand-audit.md`.
- Plan task commits exist in git history for `80-01`.
- SUMMARY.md exists and records all task commits.
- Requirements completed: `BRAND-01`, `BRAND-02`.
- Known residual risk is limited to unrelated full-suite failures documented above.

---
*Phase: 80-brand-audit-and-gap-register*
*Completed: 2026-06-06*
