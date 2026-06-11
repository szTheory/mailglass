---
phase: 79-verification-and-visual-regression-hardening
plan: "04"
subsystem: release-ceremony
tags: [mix.exs, release-please, hex, mailglass_inbound, linked-versions]

# Dependency graph
requires:
  - phase: 79-03
    provides: 79-GAP-CLOSEOUT.md with all five sev-4 rows CLOSED
  - phase: 79-02
    provides: extended e2e suite (10 tests, all green)
  - phase: 79-01
    provides: check-conformance.sh exits 0 (5-gate conformance)
provides:
  - mailglass_inbound/mix.exs pins {:mailglass, "== 1.5.0"} in MIX_PUBLISH branch
  - All four Phase 79 verification gates confirmed green simultaneously
  - Release-ceremony prepare-only posture documented (pipeline owns hex.publish)
affects:
  - hands-free Release Please pipeline (1.4.5 → 1.5.0 linked-group bump + inbound 1.1.5 → 1.1.6 patch)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inbound exact-pin re-pin is the ONLY pre-publish ceremony step; Release Please owns version bumps + CHANGELOG"

key-files:
  created: []
  modified:
    - mailglass_inbound/mix.exs

key-decisions:
  - "Phase 79 is prepare-only: no mix hex.publish, no hand-merge of Release Please PR, no manual CHANGELOG edits"
  - "release-please-config.json linked group contains only mailglass+mailglass_admin; mailglass_inbound remains independent (patch-bump trigger)"
  - "Inbound exact-pin update from == 1.4.5 to == 1.5.0 prevents adopter dependency conflict post-release"

patterns-established:
  - "Release ceremony: update inbound exact-pin in mix.exs via chore(79): commit; Release Please detects conventional commits and opens the version-bump PR automatically"

requirements-completed:
  - VERIF-04

# Metrics
duration: 10min
completed: 2026-06-04
---

# Phase 79 Plan 04: Release Ceremony Preparation Summary

**mailglass_inbound exact-pin updated from == 1.4.5 to == 1.5.0; all four Phase 79 verification gates confirmed green; prepare-only release ceremony complete — pipeline owns the Hex publish**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-06-04T22:13:00Z
- **Completed:** 2026-06-04T22:23:00Z
- **Tasks:** 2
- **Files modified:** 1 (mailglass_inbound/mix.exs)

## Accomplishments

- Updated `mailglass_inbound/mix.exs` line 116: `{:mailglass, "== 1.4.5"}` → `{:mailglass, "== 1.5.0"}` (MIX_PUBLISH branch only; dev path unchanged)
- Confirmed all three Wave 1 gates green: check-conformance.sh exits 0, Playwright 10/10, 79-GAP-CLOSEOUT.md has 9 CLOSED rows (>= 5)
- Full verification pass: mix verify.preview exits 0 (189 tests, 0 failures, 2 excluded); mix test --seed 0 exits 0; Playwright 10/10
- release-please-config.json confirmed unchanged (mailglass_inbound NOT in linked-versions components array)
- .release-please-manifest.json confirmed unchanged (Release Please owns this file)
- No mix.lock drift; no demo_app contamination; only mailglass_inbound/mix.exs in the staged diff

## Release-Ceremony Readiness

### What Phase 79 prepared

- Inbound exact-pin pre-updated to `== 1.5.0`, preventing a stale `== 1.4.5` dependency conflict after the release
- Conventional-commit history (feat/fix/chore from Phases 75-79) is in place to trigger the Release Please linked-group 1.4.5 → 1.5.0 minor bump for mailglass+mailglass_admin
- The chore(79): commit above also serves as the inbound patch-bump trigger (1.1.5 → 1.1.6)

### What the pipeline owns (NOT Phase 79)

- `mix hex.publish` — hands-free pipeline only
- Release Please PR — auto-opened by bot when conventional commits land on main
- Auto-merge on green CI — Release Please PR merges when all CI checks pass
- CHANGELOG edits — Release Please writes them
- `.release-please-manifest.json` version bumps — Release Please owns this file
- hex-publish fan-out — triggered from a Release Please release event

### Current manifest state (pre-pipeline)

```json
{ ".": "1.4.5", "mailglass_admin": "1.4.5", "mailglass_inbound": "1.1.5" }
```

### Target state after Release Please pipeline runs

```json
{ ".": "1.5.0", "mailglass_admin": "1.5.0", "mailglass_inbound": "1.1.6" }
```

(mailglass + mailglass_admin bump via linked-versions plugin; mailglass_inbound bumps independently as a patch)

## Task Commits

Each task was committed atomically:

1. **Task 1: Confirm Wave 1 gates green and update inbound exact-pin** - `144e037d` (chore)
2. **Task 2: Run full verify.preview and confirm release-ceremony readiness** - documented in plan metadata commit

**Plan metadata:** (docs commit — this SUMMARY + state updates)

## Files Created/Modified

- `/Users/jon/projects/mailglass/mailglass_inbound/mix.exs` - Bumped MIX_PUBLISH exact-pin from `== 1.4.5` to `== 1.5.0`; dev path branch untouched

## Decisions Made

- Prepare-only posture confirmed: Phase 79 updates the exact-pin only; the hands-free Release Please pipeline owns all publish/version/changelog automation
- `release-please-config.json` linked group is mailglass + mailglass_admin only (mailglass_inbound independent); no change made or needed

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. All four verification gates passed on first run.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 79 is the last plan in the v1.7 milestone. All four plans complete:

- 79-01: check-conformance.sh (5-gate conformance) — DONE
- 79-02: Extended e2e suite (10 tests) — DONE
- 79-03: 79-GAP-CLOSEOUT.md authored (all 5 sev-4 rows CLOSED) — DONE
- 79-04: Release ceremony preparation (inbound exact-pin) — DONE

The v1.7 milestone is ready for `/gsd-complete-milestone`. The hands-free Release Please pipeline will detect the Phase 75-79 conventional commits on main and open the 1.4.5 → 1.5.0 linked-group release PR automatically.

---
*Phase: 79-verification-and-visual-regression-hardening*
*Completed: 2026-06-04*
