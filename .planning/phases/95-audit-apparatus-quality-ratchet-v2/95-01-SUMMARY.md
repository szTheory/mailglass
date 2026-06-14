---
phase: 95-audit-apparatus-quality-ratchet-v2
plan: 01
subsystem: planning
tags: [gap-register, quality-ratchet, design-system, audit, planning-artifact]

# Dependency graph
requires:
  - phase: 94-token-re-baseline-onto-canonical-brand
    provides: corrected brand token baseline; gates-first commit discipline (D-08/D-10)
provides:
  - ".planning/RATCHET-GAP-REGISTER.md — header-only v1.11 GAP register with stable IDs and anti-churn contract"
  - "Citation anchor for downstream Phases 98-103 build tasks (sev>=3 gate)"
  - "Idempotent re-run semantics documented (active Phase 103)"
  - "Seed run procedure documented so future maintainers can produce a run_id"
affects:
  - "Phases 98-103 (all build tasks must cite a sev>=3 row from this register)"
  - "Phase 95 Plans 02-04 (subsequent apparatus layers reference this register)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GAP register: milestone-root placement (not phase-buried) for cross-phase citation durability"
    - "Stable-ID carry-forward: fresh register with restart-at-GAP-01, frozen v1.7 register untouched"
    - "Anti-churn gate as documented review rule (not a script) — mirrors v1.7 74-GAP-REGISTER.md precedent"

key-files:
  created:
    - .planning/RATCHET-GAP-REGISTER.md
  modified: []

key-decisions:
  - "D-02 carried: Fresh register at .planning/RATCHET-GAP-REGISTER.md (milestone-root); IDs restart at GAP-01; v1.7 74-GAP-REGISTER.md is frozen — DO NOT reopen"
  - "9-column schema: 7 v1.7 columns plus status, run_id, first_seen_run for idempotent ratchet semantics"
  - "Anti-churn citation gate is a documented review rule (not a shell script) — same as v1.7 precedent"
  - "D-01 canonical 6 pillars: Spacing/Radius/Color/Type/Elevation/Motion+A11y from design-system.md:104-121"

patterns-established:
  - "GAP register header-only commit: apparatus scaffolding lands green before seed rows are populated (D-08 step 1)"
  - "first_seen_run immutability: set on initial discovery, never changed — enables cross-run traceability"

requirements-completed:
  - RATCHET-02

# Metrics
duration: 5min
completed: 2026-06-14
---

# Phase 95 Plan 01: RATCHET-GAP-REGISTER Scaffolding Summary

**v1.11 GAP register header with 9-column schema, anti-churn contract (Phases 98-103, sev>=3), idempotent re-run semantics, and seed run procedure — citation anchor ready for all downstream build phases**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-14T04:22:00Z
- **Completed:** 2026-06-14T04:24:38Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `.planning/RATCHET-GAP-REGISTER.md` at the milestone root — milestone-scoped location ensures it spans Phases 95-103 as the single citation anchor
- Full 9-column schema (7 from v1.7 precedent + `status`, `run_id`, `first_seen_run`) with column descriptions and table header ready for data rows
- Anti-churn contract verbatim (Phases 98-103 re-targeted): "MUST cite a row at severity >= 3 or no merge"
- Idempotent re-run semantics documented: regressed cell reopens, confirmed-fixed skipped, open same-finding skipped
- D-01 six conformance pillars listed with descriptions (Spacing/Radius/Color/Type/Elevation/Motion+A11y)
- Severity rubric 1-5 with Phase 103 closeout blocking criteria (sev-4/5 blocks closeout)
- Seed run procedure (5-step) with `run_id` format documented for future maintainers
- Header-only file (no data rows) — rows populated by Plan 95-04 after seed run

## Task Commits

1. **Task 1: Create RATCHET-GAP-REGISTER.md with full schema and anti-churn contract** - `3218306d` (feat)

**Plan metadata:** TBD (docs commit)

## Files Created/Modified

- `.planning/RATCHET-GAP-REGISTER.md` - v1.11 GAP register header with full schema and anti-churn contract; no data rows yet

## Decisions Made

No new decisions — plan executed as specified. All decisions (D-01 pillar set, D-02 register location/schema/restart, D-08 commit order) were pre-settled in CONTEXT.md and RESEARCH.md. The anti-churn gate as a documented review rule (not a script) was confirmed as the v1.7 precedent-matching approach per RESEARCH.md.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `.planning/RATCHET-GAP-REGISTER.md` exists with stable IDs and anti-churn contract — Plan 95-02 can wire the ExUnit baseline assertion referencing this register
- Plan 95-02 (score-baseline ExUnit assertion) and Plan 95-03 (Playwright structural spec) can proceed immediately
- Plan 95-04 (seed run) populates the data rows into this register

---
*Phase: 95-audit-apparatus-quality-ratchet-v2*
*Completed: 2026-06-14*
