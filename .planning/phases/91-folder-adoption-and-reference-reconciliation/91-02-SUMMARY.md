---
phase: 91-folder-adoption-and-reference-reconciliation
plan: 02
subsystem: brandbook
tags: [brandbook, git, folder-adoption, evidence]

requires:
  - phase: 91-folder-adoption-and-reference-reconciliation
    provides: Phase-local adoption gate and evidence contract from 91-01
provides:
  - Canonical fable brand book at brandbook/
  - Removed active brandbook-fable/ tree
  - Removed old codex-only brandbook artifacts from the active tree
  - Recorded ignored-file preflight and Git move evidence
affects:
  - Phase 92 surface propagation
  - Phase 93 HexDocs wiring

tech-stack:
  added: []
  patterns:
    - Git-tracked folder replacement with ignored-file preflight
    - Evidence-led folder adoption transcript

key-files:
  created:
    - brandbook/copy/copy-blocks.md
    - brandbook/copy/microcopy.md
    - brandbook/examples/landing-page.html
    - brandbook/examples/email-template.html
  modified:
    - brandbook/
    - .planning/phases/91-folder-adoption-and-reference-reconciliation/91-gate-evidence.md

key-decisions:
  - "The approved fable book is now the canonical active brandbook/ tree."
  - "The old codex brandbook exists only in Git history, not as an in-tree archive."
  - "The preflight commit from the crashed session was preserved and the plan was resumed from Task 2."

patterns-established:
  - "Run ignored/untracked preflight before tracked folder adoption."
  - "Use git rm plus git mv for canonical brandbook replacement; do not copy files manually."

requirements-completed: [FOLD-01, FOLD-03]

duration: 3h 9m wall-clock with crash recovery
completed: 2026-06-12
---

# Phase 91 Plan 02: Canonical Brandbook Folder Adoption Summary

**Approved fable artifacts moved into canonical `brandbook/` with old codex artifacts removed from the active tree**

## Performance

- **Duration:** 3h 9m wall-clock with crash recovery
- **Started:** 2026-06-12T22:07:41Z
- **Completed:** 2026-06-13T01:16:08Z
- **Tasks:** 2
- **Files modified:** 71

## Accomplishments

- Preserved the already-committed ignored-file preflight cleanup from the interrupted session.
- Removed the old tracked codex-era `brandbook/` tree and moved `brandbook-fable/` into canonical `brandbook/` with Git operations.
- Recorded both the preflight and folder-adoption proof in `91-gate-evidence.md`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Preflight ignored files before the Git move** - `5a3f4739` (chore)
2. **Task 2: Replace old brandbook/ with the fable folder via Git** - `84fe92ff` (chore)

**Plan metadata:** pending (docs commit)

## Files Created/Modified

- `brandbook/` - Canonical fable brand book artifact tree, replacing the old codex-era tree.
- `brandbook/copy/` - Fable copy library now available under the canonical path.
- `brandbook/examples/` - Fable specimens now available under the canonical path.
- `.planning/phases/91-folder-adoption-and-reference-reconciliation/91-gate-evidence.md` - Preflight and Git folder adoption transcript.

## Decisions Made

- Continued from the existing preflight commit rather than re-running `91-02` from scratch.
- Kept the prompt-era and archived provenance records untouched; this plan only changed the active brandbook tree and phase evidence.

## Deviations from Plan

None - plan executed exactly as written after crash recovery.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

The previous terminal session crashed after Task 1. Safe-resume inspection found `5a3f4739` without `91-02-SUMMARY.md`, so execution resumed from Task 2 instead of duplicating the completed preflight work.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 91-03 can now reconcile active source pointers against the canonical `brandbook/brand-book.md` path. Phase 92 and Phase 93 surfaces can rely on `brandbook/` as the stable post-adoption path.

## Self-Check: PASSED

- `test -f brandbook/brand-book.md` exited 0.
- `test -f brandbook/index.html` exited 0.
- `test -f brandbook/assets/logo-primary.svg` exited 0.
- `test ! -e brandbook-fable` exited 0.
- `test -z "$(git ls-files brandbook-fable)"` exited 0.
- Old codex-only paths including `brandbook/assets/concepts`, `brandbook/assets/options`, `brandbook/brand-audit.md`, and logo concept files do not exist.
- `git status --short -- brandbook brandbook-fable | grep '\.DS_Store'` printed no lines.

---
*Phase: 91-folder-adoption-and-reference-reconciliation*
*Completed: 2026-06-12*
