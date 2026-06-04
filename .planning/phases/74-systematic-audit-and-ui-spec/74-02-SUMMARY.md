---
phase: 74-systematic-audit-and-ui-spec
plan: 02
subsystem: ui
tags: [e2e, playwright, audit, assertion-inventory, before-baseline]

requires:
  - phase: 74-01
    provides: gap register (74-GAP-REGISTER.md) and frozen UI-SPEC (74-UI-SPEC.md) which define ripple-risk vocabulary for this inventory

provides:
  - "74-ASSERTION-INVENTORY.md: AUDIT-03 before-baseline with every test() heading, heading/copy/testid assertion, and seed-count baseline with file:line and ripple-risk annotation"
  - "18 gitignored PNG path references under tmp/ui-audit/ (D-06: binaries never committed)"

affects:
  - Phase 75 (IA-03 ripple: must update heading assertions for "Deliveries"/"Inbound records"/"Northstar Ops" if IA vocabulary changes)
  - Phase 78 (SEED-02 ripple: seed row indices and POST /demo/evidence/reset contract)
  - Phase 79 (VERIF-01: diffs against this before-baseline)

tech-stack:
  added: []
  patterns:
    - "Assertion inventory pattern: every e2e test() block catalogued by file:line with ripple-risk column (HIGH/Medium/Low) keyed to build phase"
    - "D-06 PNG path reference pattern: committed text inventory of screenshot paths, never committed binaries"

key-files:
  created:
    - .planning/phases/74-systematic-audit-and-ui-spec/74-ASSERTION-INVENTORY.md
  modified: []

key-decisions:
  - "HIGH-ripple heading assertions identified: getByRole(heading, Deliveries) appears in BOTH operator.spec.js:19 and demo.spec.js:28 — must be updated together in Phase 75 if IA renames the surface"
  - "operator-empty-detail testid (operator.spec.js:32/34) is Medium-ripple: Phase 75 Operator Overview may replace the empty-detail slot"
  - "Seed row indices 1/2/3 in operator.spec.js are Phase 78 ripple: any seed reorder must update indices in the same commit"
  - "POST /demo/evidence/reset beforeEach contract is the canonical seed-reset seam; Phase 78 SEED-02 must keep the endpoint response ok() intact"

patterns-established:
  - "Ripple inventory pattern: before any build phase changes headings or seeds, consult 74-ASSERTION-INVENTORY.md to identify which e2e assertions must be updated in the same commit"

requirements-completed: [AUDIT-03]

duration: 12min
completed: 2026-06-04
---

# Phase 74 Plan 02: Assertion Inventory Summary

**AUDIT-03 before-baseline committed: 5 operator.spec.js tests and 3 demo.spec.js tests fully inventoried with file:line, assertion kind, exact asserted values, and HIGH/Medium/Low ripple-risk annotations keyed to Phases 75 and 78**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-04T02:10:00Z
- **Completed:** 2026-06-04T02:22:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Read both e2e spec files in full; catalogued every test() heading, heading/copy/testid assertion, and seed-count baseline with source file:line
- Identified 4 HIGH-ripple assertions (heading "Deliveries" appears in two spec files and must be updated together; "Inbound records" and "Northstar Ops" are Phase 75 ripple candidates)
- Recorded seed-count baseline and the POST /demo/evidence/reset contract as the Phase 78 SEED-02 change surface
- Listed the complete testid prior-baseline for both spec files (11 testids in operator.spec.js, 7 in demo.spec.js) so Phase 75 additions are deliberate
- Listed 18 gitignored PNG path references per D-06 (3 surfaces x 3 viewports x 2 themes); no binaries committed

## Task Commits

1. **Task 1: Author 74-ASSERTION-INVENTORY.md** - `e6c6e5fb` (docs)

**Plan metadata:** (committed below)

## Files Created/Modified

- `.planning/phases/74-systematic-audit-and-ui-spec/74-ASSERTION-INVENTORY.md` — 287-line AUDIT-03 before-baseline; three sections: operator.spec.js inventory, demo.spec.js inventory, PNG path references

## Decisions Made

- "Deliveries" heading assertion appears in BOTH spec files (operator.spec.js:19 in openOperator helper, and demo.spec.js:28) — Phase 75 must update both files in a single commit if the heading is renamed; this ripple linkage is now explicit
- operator-empty-detail testid is Medium-risk because the Operator Overview `:overview` action (Phase 75) is expected to replace or supplement the empty-detail slot
- demo.spec.js uses `getByText("Deliveries", { exact: true })` at line 16 (not a heading role assertion) — a separate ripple point from the heading assertion at line 28

## Deviations from Plan

None - plan executed exactly as written. Zero spec files modified, zero production code changed.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 79 can diff against 74-ASSERTION-INVENTORY.md as the before-baseline after build phases 75-78 complete
- Phase 75 must consult the HIGH-ripple rows before finalizing any heading-copy changes; the dual-file "Deliveries" heading linkage is the primary coordination risk
- Phase 78 must update seed row indices (operator.spec.js lines 95/124/154) in the same commit as any seed reorder

---
*Phase: 74-systematic-audit-and-ui-spec*
*Completed: 2026-06-04*
