---
phase: 161-canonical-workspace-and-evidence-preservation
plan: 01
subsystem: repository-stewardship-evidence
tags: [git, worktree, stash, refs, release-proof, preservation]
requires:
  - phase: 160-certification-documentation-and-release
    provides: local release-target and protected-publication proof artifacts
provides:
  - immutable pre-mutation workspace ledger covering canonical main and linked worktrees
  - stable stash, ref, divergent-range, release-proof, and unreachable-commit preservation evidence
  - Wave 0 validation map with reconciled inventory commands
affects: [phase-161-plan-02-assessment, phase-162-remote-release-recovery]
tech-stack:
  added: []
  patterns: [read-only-git-evidence, preservation-before-mutation, bytewise-object-ledger]
key-files:
  created:
    - .planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md
  modified:
    - .planning/phases/161-canonical-workspace-and-evidence-preservation/161-VALIDATION.md
decisions:
  - "Treat the orchestrator-created STATE.md diff as explicit workflow tracking while preserving the canonical production source verdict."
  - "Keep canonical main non-release-clean until Phase 162 settles its upstream drift despite a clean production source."
  - "Retain every dirty, detached, stash, and unreachable candidate pending Plan 02 assessment; none is cleanup-eligible."
metrics:
  duration: 12m
  tasks_completed: 2
  files_changed: 2
completed: 2026-08-22
status: complete
---

# Phase 161 Plan 01: Canonical Workspace and Evidence Preservation Summary

**Captured a durable, pre-mutation Git evidence ledger that establishes canonical `main`, all linked worktrees, preservation candidates, and the complete unreachable-commit set without altering repository state.**

## Accomplishments

- Established `/Users/jon/projects/mailglass` on `main` as the sole `CANONICAL` workspace, documenting its capture-time `0 behind / 17 ahead` state, non-release-clean verdict, and immutable seven-commit v2.6/v2.7 semantic subrange.
- Reconciled all six Git-registered worktrees, including the dirty detached release candidate and exact HEAD/status evidence for every path.
- Captured one stash, relevant release/archive refs and divergent ranges, five local release-proof artifacts, and 1,805 unreachable commits with `assessment pending / retain` dispositions.
- Completed Wave 0 validation after fresh worktree, stash, and fsck reconciliation: 6/6 worktrees, 1/1 stash, and 1,805/1,805 unreachable commits.

## Task Commits

1. **Task 1: Capture canonical `main` and the complete linked-worktree path end to end** — `54b26279` (`docs`)
2. **Task 2: Expand the snapshot across stash, ref, range, release, and object categories** — `37784240` (`docs`)

## Decisions Made

- Record the live upstream count as timestamped evidence while treating the fixed seven-commit semantic range—not the mutable total—as the durable D-05 explanation.
- Preserve the known orchestrator phase-start `STATE.md` diff transparently rather than presenting it as product work or silently excluding it.
- Hand remote release meaning to Phase 162; local release ledgers and publish summaries remain retained evidence only.

## Verification

- Passed the plan automated checks for ledger existence, all six `WT-*` rows, canonical/non-release-clean/seven-commit markers, stash count, and Wave 0 task map.
- Passed fresh reconciliation: `git worktree list --porcelain` matched 6 ledger rows; `git stash list` matched 1 row; `git fsck --no-reflogs --unreachable --no-dangling` matched 1,805 `OBJ-*` rows.
- No cleanup, ref creation, checkout, reset, merge, prune, removal, or force operation was run.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Expanded the unexpectedly large unreachable-commit set mechanically**
- **Found during:** Task 2
- **Issue:** Fresh fsck reported 1,805 unreachable commits; manually summarizing the set would not meet the one-row-per-commit preservation requirement.
- **Fix:** Generated stable bytewise `OBJ-*` ledger rows from the read-only fsck output, then reconciled the exact count.
- **Files modified:** `161-WORKSPACE-INVENTORY.md`
- **Verification:** 1,805 ledger rows equal 1,805 fresh fsck commits.
- **Commit:** `37784240`

**Total deviations:** 1 auto-fixed blocking issue. **Impact:** The ledger is larger but preserves complete evidence rather than collapsing an unsafe object set into an aggregate.

## Known Stubs

None.

## Self-Check: PASSED

- `161-WORKSPACE-INVENTORY.md` and `161-VALIDATION.md` exist.
- Both task commits (`54b26279`, `37784240`) exist in Git history.
- The final automated reconciliation passed in this execution.

## Next Phase Readiness

Plan 02 can assess the retained candidates using this ledger. Phase 162 must interpret remote PR, tag, Hex, and scheduled-control facts independently; this plan intentionally makes no remote release conclusion.
