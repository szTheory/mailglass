---
phase: 13-v0-2-release-ceremony
plan: 01
subsystem: release-docs
tags: [changelog, release-notes, runbook, migration]
requires: []
provides:
  - curated mailglass 0.2.0 release narrative as the migration front door
  - coordinated mailglass_admin 0.2.0 release note
  - maintainer rollback wording aligned with the public release story
affects: [CHANGELOG.md, mailglass_admin/CHANGELOG.md, MAINTAINING.md]
tech-stack:
  added: []
  patterns: [migration-first changelog, coordinated sibling release note]
key-files:
  created: [.planning/phases/13-v0-2-release-ceremony/13-01-SUMMARY.md]
  modified: [CHANGELOG.md, mailglass_admin/CHANGELOG.md, MAINTAINING.md]
key-decisions:
  - "Kept the categorized Added/Changed/Fixed ledger under a maintainer-written migration front door instead of replacing the ledger entirely."
  - "Framed rollback as a git-clean or disposable-worktree workflow rather than implying cleanup of arbitrary dirty trees."
patterns-established:
  - "Release-day changelog entries lead with upgrade truth, not generated commit archaeology."
requirements-completed: [REL-13]
completed: 2026-04-28
---

# Phase 13 Plan 01: Curated v0.2 release narrative and coordinated maintainer rollback wording

**The v0.2 changelog now acts as the adopter-facing migration front door, `mailglass_admin` has a coordinated sibling entry, and the maintainer runbook uses the same explicit rollback contract the public release notes promise.**

## Accomplishments
- Rewrote the `mailglass` `0.2.0` changelog entry around breaking changes, exact upgrade flow, dependency floor, ambiguous-case handling, rollback, and immediate behavior changes.
- Added the coordinated `mailglass_admin` `0.2.0` release note clarifying that adopters should bump both sibling packages together and follow the core upgrade guide.
- Updated `MAINTAINING.md` so release fallback and rollback wording match the public release contract.

## Task Commits
1. **Task 1: Rewrite the `mailglass` `0.2.0` changelog entry as the migration front door** - `78ad635`
2. **Task 2: Add the coordinated `mailglass_admin` release note and align maintainer rollback wording** - `b912bf0`

## Verification
- `rg -n "mix mailglass\\.upgrade\\.v0_2|update_swoosh/2|rollback|breaking" CHANGELOG.md`
- `rg -n "mailglass_admin|coordinated|rollback|workflow_dispatch" mailglass_admin/CHANGELOG.md MAINTAINING.md`

## Deviations from Plan
None.

## Self-Check: PASSED
- Verified the required release-note sections and coordinated rollback wording exist on disk.
- Verified commits `78ad635` and `b912bf0` exist in git history.
