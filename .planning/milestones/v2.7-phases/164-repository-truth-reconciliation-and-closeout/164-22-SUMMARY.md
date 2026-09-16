---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 22
subsystem: immutable-finalization-authority
tags: [git, finalization, installed-loader, repository-truth, maintainer-docs]
requires:
  - phase: 164-21
    provides: immutable captured-OID loader and exact Phase 164 numbered-history authority
provides:
  - removal of the unauthenticated project-local finalization extension
  - evidence-backed retired-extension ledger dispositions with retained loader replacement
  - one current installed-command contract for Phase 164 finalization
affects: [finalize-phase, repository-truth-ledger, MAINTAINING, TRTH-01, TRTH-02, TRTH-03]
actuals:
  tokens: 8816
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [installed pre-evaluation authority, evidence-backed executable retirement, current-versus-historical command boundary]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-22-SUMMARY.md
  modified:
    - MAINTAINING.md
    - .planning/ROADMAP.md
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv
    - scripts/validate_repository_truth.exs
    - test/scripts/phase_164_closeout_test.exs
    - test/scripts/phase_164_repository_truth_test.exs
    - test/mailglass/publish/maintaining_release_gate_contract_test.exs
key-decisions:
  - "The installed /Users/jon/.local/bin/mailglass-finalize-phase executable is the sole current Phase 164 verdict entry point; the removed project-local slash command is historical provenance only."
  - "Retired extension subjects remain exact ledger identities with historical remove dispositions and explicit replacement evidence naming scripts/mailglass_finalize_phase_loader.mjs."
patterns-established:
  - "Executable retirement preserves exact subject identity, origin plans, replacement authority, and regression coverage instead of erasing provenance."
  - "Current maintainer prose names only the installed absolute command; obsolete checkout commands may appear only below an explicit historical boundary."
requirements-completed: [TRTH-01, TRTH-02, TRTH-03]
coverage:
  - id: D1
    description: "The project-local finalization extension is absent, its two ledger identities retain complete removal/replacement provenance, and hostile recreation cannot affect direct loader execution."
    requirement: TRTH-02
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_closeout_test.exs#phase 164 installed boundary"
        status: pass
      - kind: integration
        ref: "test/scripts/phase_164_repository_truth_test.exs"
        status: pass
      - kind: other
        ref: "elixir scripts/validate_repository_truth.exs --repo /Users/jon/projects/mailglass --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv"
        status: pass
    human_judgment: false
  - id: D2
    description: "Maintainer and lifecycle documentation expose the installed absolute executable as the sole current authority while bounding the removed slash command to historical provenance."
    requirement: TRTH-01
    verification:
      - kind: unit
        ref: "test/mailglass/publish/maintaining_release_gate_contract_test.exs"
        status: pass
      - kind: integration
        ref: "test/scripts/phase_164_closeout_test.exs#finalization guidance keeps pre-verification and terminal proof non-circular"
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-09-10
status: complete
---

# Phase 164 Plan 22: Installed Finalization Authority Summary

**The mutable checkout extension is retired, with its exact provenance preserved, and all current guidance now routes Phase 164 verdicts through the installed immutable loader.**

## Performance

- **Duration:** 6 minutes
- **Started:** 2026-09-10T20:56:31Z
- **Completed:** 2026-09-10T21:02:18Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Removed both tracked `.gsd/extensions/finalize-phase` files and proved an untracked hostile recreation cannot influence a direct standalone-loader subprocess.
- Preserved the retired manifest and command as exact historical ledger subjects with Plan 164-11/21/22 provenance and the tracked immutable loader named as replacement.
- Published the exact normal and pre-verification installed-command forms in current maintainer guidance and documented captured-OID, private-authority-root, exact-history, cleanup, and terminal ordering.

## Task Commits

1. **Task 1: Remove the pre-authentication project extension without losing provenance** — `ac52c158` (RED), `e2298c6b` (GREEN)
2. **Task 2: Publish one current installed-command contract** — `2baf4203` (RED), `12688e77` (GREEN)

## Files Created/Modified

- `.gsd/extensions/finalize-phase/index.ts` — Removed unauthenticated checkout command bootstrap.
- `.gsd/extensions/finalize-phase/extension-manifest.json` — Removed obsolete project-local command manifest.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv` — Historical removal rows and explicit immutable-loader replacement evidence.
- `scripts/validate_repository_truth.exs` — Canonical validation for the two evidence-backed historical removals.
- `test/scripts/phase_164_closeout_test.exs` — Installed-boundary, hostile recreation, and lifecycle documentation regressions.
- `test/scripts/phase_164_repository_truth_test.exs` — Exact old/new ledger disposition and ignore-boundary contracts.
- `MAINTAINING.md` — Sole current installed command, source provenance, Plan 164-23 installation boundary, and superseded-command history.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md` — Installed trust root, captured OID, private authority, exact 01-24 set, and terminal lifecycle.
- `.planning/ROADMAP.md` — Phase 164 gap-closure inventory and post-protected-main installed terminal command.
- `test/mailglass/publish/maintaining_release_gate_contract_test.exs` — Whole-current-region installed authority contract.

## Decisions Made

- The absolute installed executable is the only current finalization command; the retired slash command cannot appear as a current alternative.
- Removal does not erase ledger identity. Both old subjects remain historical rows with exact origin and replacement evidence while only the standalone loader remains tracked and current.
- Plan 164-23 remains the installation authority; this plan documents the command but does not claim the external executable has already been installed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Extended the canonical ledger validator for evidence-backed executable retirement**

- **Found during:** Task 1
- **Issue:** The existing validator permitted historical removal only for the stale generated sweep, so removing the authenticated-bootstrap replacement subjects would make the canonical ledger structurally invalid.
- **Fix:** Added a subject-exact relationship for the two retired extension artifacts, admitted their exact provenance evidence, and updated their canonical semantic hashes.
- **Files modified:** `scripts/validate_repository_truth.exs`
- **Verification:** All 25 repository-truth tests passed and the direct validator reported `repository truth ledger: valid`.
- **Committed in:** `e2298c6b`

**2. [Rule 1 - Test bug] Made the historical-boundary assertion whitespace-stable**

- **Found during:** Task 2 GREEN verification
- **Issue:** The first assertion required prose words to remain on one physical line even though normal Markdown wrapping split them.
- **Fix:** Replaced the literal substring with a whitespace-tolerant regex while preserving the exact command and superseded-boundary requirement.
- **Files modified:** `test/mailglass/publish/maintaining_release_gate_contract_test.exs`
- **Verification:** All 5 maintainer release-gate contract tests passed.
- **Committed in:** `12688e77`

---

**Total deviations:** 2 auto-fixed (1 Rule 2, 1 Rule 1).
**Impact on plan:** Both changes were necessary to enforce the planned retirement and documentation boundaries; no product, API, schema, dependency, release, or external installation scope was added.

## Issues Encountered

- Focused Mix runs emitted the existing optional OTLP-exporter warning. It did not affect compilation or test results.

## TDD Gate Compliance

- Task 1 RED failed because the tracked extension still existed; GREEN removed it and passed installed-boundary, full repository-truth, validator, and diff checks.
- Task 2 RED failed because current guidance lacked the installed command and historical boundary; GREEN passed the tagged lifecycle and complete maintainer contracts.
- Both tasks have ordered `test(164-22)` then implementation commits; no refactor commit was needed.

## Verification

- Installed-boundary tag: 3 tests, 0 failures.
- Repository-truth suite: 25 tests, 0 failures.
- Maintainer release-gate contract: 5 tests, 0 failures.
- Canonical ledger validator: `repository truth ledger: valid`.
- Required Phase 164 roadmap assertions and `git diff --check`: passed.

## Known Stubs

None.

## User Setup Required

None in this plan. Plan 164-23 owns the blocking-human authenticated installation checkpoint.

## Next Phase Readiness

- Plan 164-23 can preflight and install the tracked loader at the documented external path without any project-local extension alternative remaining.
- Terminal evidence remains intentionally pending; this plan neither installed the executable nor ran pre-verification or terminal finalization.

## Self-Check: PASSED

- All retained changed files and this summary exist; both retired extension files are absent from the index and working tree.
- Commits `ac52c158`, `e2298c6b`, `2baf4203`, and `12688e77` are present in Git history.
- Fresh post-implementation verification passed every plan command and acceptance contract.
- No goal-blocking stub, new skipped test, unrun plan verification, or unplanned threat surface remains.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-10*
