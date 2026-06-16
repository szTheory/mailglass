---
phase: 103-verification-idempotent-closeout
plan: 02
subsystem: mailglass_admin
tags: [ratchet, quality-gate, baseline, tdd, closeout]
dependency_graph:
  requires: [103-01]
  provides: [schema-2-baseline, armed-ratchet, promotion-doc]
  affects: [mailglass_admin/docs/ui-baseline-scores.json, mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs, .planning/RATCHET-GAP-REGISTER.md]
tech_stack:
  added: []
  patterns: [schema-2 {prior,current} baseline, compare_baselines/2 activation, anti-vacuity run_id guard, block-scoped coverage tests]
key_files:
  created: []
  modified:
    - mailglass_admin/docs/ui-baseline-scores.json
    - mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs
    - .planning/RATCHET-GAP-REGISTER.md
decisions:
  - schema_version 2 JSON uses top-level pillar_rubric/grade_scale with {prior, current} blocks each carrying run_id + surfaces
  - Fresh re-score ran genuine 18-PNG capture (agent-browser 0.27.0); all 36 cells meet-or-beat prior; preview Motion+A11y rose 2→3 (CTA present, motion vocabulary applied)
  - Anti-vacuity guard placed in its own dedicated test "only-forward ratchet" (not setup_all)
  - Coverage tests iterate both ["prior","current"] blocks (validates migrated prior AND fresh current)
metrics:
  duration: "~11 minutes"
  completed: "2026-06-16T20:51:37Z"
  tasks_completed: 3
  files_modified: 3
---

# Phase 103 Plan 02: Activate Only-Forward Score Ratchet Summary

Schema-2 baseline committed with genuine fresh 18-PNG re-score (run_id `2026-06-16-phase-103`), `compare_baselines(b["prior"], b["current"])` armed at live call site, D-04 anti-vacuity guard active, and Seed Run Procedure promotion step documented.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Fresh 18-cell PNG re-run and structured 36-cell re-score | (gitignored PNGs; scores carried to Task 2) | tmp/ui-audit/*.png (18 files, gitignored) |
| 2 | Restructure JSON to schema-2 {prior, current} and arm the ratchet test | 563c3e18 | mailglass_admin/docs/ui-baseline-scores.json, mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs |
| 3 | Document the promotion step in the register Seed Run Procedure | f7f31a43 | .planning/RATCHET-GAP-REGISTER.md |

## Task 1: Fresh Re-Score Results

All 18 PNGs captured via `agent-browser 0.27.0` + `scripts/ui-audit.sh` against the running demo app on port 4015. Genuine 36-cell re-score against the six-pillar rubric:

| Surface | Pillar | Prior (light/dark) | Current (light/dark) | Delta |
|---------|--------|-------------------|----------------------|-------|
| deliveries | Spacing | 3/3 | 4/4 | +1/+1 (GAP-01, GAP-06 fixes) |
| deliveries | Radius | 4/4 | 4/4 | — |
| deliveries | Color | 4/4 | 4/4 | — |
| deliveries | Type | 3/3 | 4/4 | +1/+1 (GAP-07 tracking fix) |
| deliveries | Elevation | 4/4 | 4/4 | — |
| deliveries | Motion+A11y | 3/3 | 4/4 | +1/+1 (GAP-08/09 + Phase 102) |
| inbound | Spacing | 3/3 | 4/4 | +1/+1 (GAP-04 filter labels) |
| inbound | Radius | 4/4 | 4/4 | — |
| inbound | Color | 4/4 | 4/4 | — |
| inbound | Type | 3/3 | 4/4 | +1/+1 (GAP-04 type labels fixed) |
| inbound | Elevation | 4/4 | 4/4 | — |
| inbound | Motion+A11y | 3/3 | 4/4 | +1/+1 (Phase 101/102) |
| preview | Spacing | 3/3 | 4/4 | +1/+1 |
| preview | Radius | 4/4 | 4/4 | — |
| preview | Color | 4/4 | 4/4 | — |
| preview | Type | 3/3 | 4/4 | +1/+1 (Phase 99 text-xl→text-heading) |
| preview | Elevation | 4/4 | 4/4 | — |
| preview | Motion+A11y | 2/2 | 3/3 | +1/+1 (GAP-02 CTA + Phase 102; dark chrome in empty state still renders light) |

Anti-vacuity check A1: Every re-scored cell meets-or-beats its Phase 95 prior. Zero regressions.

## Task 2: Schema-2 Restructure + Ratchet Activation

**ui-baseline-scores.json** restructured to schema_version 2:
- Top-level `prior` block: `run_id: "2026-06-13-phase-95-baseline"` + original flat surfaces migrated unchanged (D-02)
- Top-level `current` block: `run_id: "2026-06-16-phase-103"` + fresh 36-cell re-score
- `pillar_rubric` and `grade_scale` remain at top level

**ratchet_baseline_test.exs** changes (pure ADD, `compare_baselines/2` at lines 87-104 unchanged):
1. Line 40 `if false` guard replaced with real test "only-forward ratchet: no cell regresses prior committed baseline" (D-03)
2. D-04 anti-vacuity guard: `assert b["prior"]["run_id"] != b["current"]["run_id"]`
3. `compare_baselines(b["prior"], b["current"])` called at live call site
4. Pitfall-1 fix: both coverage tests now iterate `block <- ["prior", "current"]` with `get_in(b, [block, "surfaces", ...])` (validates 72 cells across both blocks)
5. schema_version assertion bumped `== 1` → `== 2` (D-01)

**Verification:** `mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors`: 4 tests, 0 failures.

## Task 3: Promotion Step Documentation

Added "Promotion step (D-06)" subsection to RATCHET-GAP-REGISTER.md Seed Run Procedure covering:
- Copy entire current block verbatim into prior (freezes new floor)
- Write fresh measured run into current with new run_id
- Explicit statement that prior.run_id MUST differ from current.run_id (anti-vacuity guard enforces this)
- Reminder that PNGs remain gitignored; only JSON is committed

## Deviations from Plan

None - plan executed exactly as written. All D-decisions honored:
- D-02: prior block = Phase 95 scores migrated unchanged
- D-03: compare_baselines activated at call site (pure ADD, function body unchanged)
- D-04: anti-vacuity guard in its own test (Claude's discretion per context)
- D-05: rejected git-self-diff approach honored (committed baseline file used)
- D-06: promotion step documented

One observation: reference/demo_app/mix.lock drifted during `mix ecto.create` (Pitfall 5 / project memory `project_demo_app_swoosh_lock_drift.md`). Restored via `git checkout -- reference/demo_app/mix.lock` before committing; transitive drift not committed.

## Known Stubs

None. All 36 cells carry genuine integer scores 1-4 from the fresh re-score.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

Files confirmed present:
- FOUND: mailglass_admin/docs/ui-baseline-scores.json
- FOUND: mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs
- FOUND: .planning/RATCHET-GAP-REGISTER.md
- FOUND: .planning/phases/103-verification-idempotent-closeout/103-02-SUMMARY.md

Commits confirmed present:
- FOUND: 563c3e18 (feat: schema-2 JSON + armed ratchet)
- FOUND: f7f31a43 (docs: promotion step documentation)
