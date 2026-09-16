---
phase: 161-canonical-workspace-and-evidence-preservation
plan: 03
subsystem: repository-stewardship
tags: [git, preservation, evidence, reconciliation, workspace]
requires:
  - phase: 161-02
    provides: evidence-backed archive/remove disposition ledger
provides:
  - collision-safe exact-OID preservation refs for every archive identity
  - fail-closed machine reconciliation for Phase 161 cleanup eligibility
affects: [phase-161-cleanup, phase-162-release-recovery]
tech-stack:
  added: [bash]
  patterns: [exact-oid-preservation, fail-closed-reconciliation, preserve-before-cleanup]
key-files:
  created:
    - 161-PRESERVATION-RECONCILIATION.tsv
    - 161-verify-preservation-reconciliation.sh
    - 161-03-SUMMARY.md
  modified:
    - 161-WORKSPACE-INVENTORY.md
key-decisions:
  - "All 12 archive identities have independent named preservation refs; no eligible remove row exists."
  - "WT-03's dirty publish-summary evidence remains retained and unresolved release interpretation stays with Phase 162."
metrics:
  tasks_completed: 2
  files_modified: 3
status: complete
---

# Phase 161 Plan 03: Preservation Boundary Summary

**Every archive/remove-eligible identity now reconciles to a verified recovery anchor, with no cleanup or original-evidence consumption.**

## Accomplishments

- Created 12 collision-safe `preserve/phase-161-*` branches, each bound to its assessed full commit OID.
- Added a one-to-one TSV ledger and shared verifier that fails closed on empty, duplicate, missing, malformed, or mismatched preservation evidence.
- Confirmed complete reconciliation: 12 eligible archive/remove rows, 12 required refs, zero handoffs, zero not-required rows, and pending zero.
- Rechecked the detached dirty release worktree: its three publish-summary changes and binary diff hash remain intact; no preservation commit was needed because it is retained, not eligible for removal.

## Task Commits

1. **Task 1: Create collision-safe recoverable refs for ref-addressable candidates** — `21a56483` (`feat`)
2. **Task 2: Commit dirty evidence safely or bind it to a concrete handoff** — `74e03d1d` (`docs`)

## Verification

- `bash .planning/phases/161-canonical-workspace-and-evidence-preservation/161-verify-preservation-reconciliation.sh partial ...` passed: 12 eligible, 12 required, 12 refs.
- `bash .planning/phases/161-canonical-workspace-and-evidence-preservation/161-verify-preservation-reconciliation.sh complete ...` passed: 12 eligible, 12 required, 12 refs.
- All preservation refs resolve to their recorded full OIDs; canonical branch remains `main`; the original stash `024fc1ba0379d6bfb9b466fab407d94a94a2fa5a` remains listed.
- `WT-03` remains detached at `d0369ba76c1f5d033d4d10b804050fa76c784756` with the recorded binary diff hash `75ea168315ebff101a2dd060499f86a73f688ca5597837bb22dec1dc5b16ce69`.
- `git diff --check` passed.

## Decisions Made

- Preserve every archive source identity independently, including range identities that share an OID with their archive-ref source.
- Do not infer a remove candidate for any uncertain, dirty, stash, unreachable, release, or remote-facing evidence; Phase 162 still owns remote/release truth.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Verification] Corrected the dirty-worktree path check before final reconciliation**
- **Found during:** Task 2
- **Issue:** Initial read-only diff command omitted the `.planning/publish/` path prefix and produced an empty digest.
- **Fix:** Re-ran it against the exact inventoried paths; the recorded hash and three modified paths matched.
- **Files modified:** None
- **Verification:** Exact binary diff hash and path list passed.
- **Commit:** `74e03d1d`

**Total deviations:** 1 auto-fixed verification issue. **Impact:** No repository state or evidence was altered.

## Known Stubs

None.

## Self-Check: PASSED

- `161-WORKSPACE-INVENTORY.md`, `161-PRESERVATION-RECONCILIATION.tsv`, and `161-verify-preservation-reconciliation.sh` exist.
- Task commits `21a56483` and `74e03d1d` exist in Git history.
