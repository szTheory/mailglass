---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 30
subsystem: repository-truth-validation
tags: [elixir, exunit, filesystem-boundary, cli-diagnostics, repository-truth]
requires:
  - phase: 164-28
    provides: reconciled exact-one repository-truth validator and terminal lifecycle boundary
  - phase: 164-29
    provides: installed-authority proof and default controlled-host suite isolation
provides:
  - bounded exit-one diagnostics for empty and incomplete authority roots
  - ordered non-raising reads for all six required authority ignore subjects
  - exact-one ledger coverage for the Plan 164-29 root ExUnit boundary
affects: [phase-164-verification, terminal-finalization-readiness, TRTH-02]
actuals:
  tokens: 3219
  tasks: 2
  commits: 6
plan_head_before: 6379b28f1d2b345e163c254b54774433582888d5
tech-stack:
  added: []
  patterns: [ordered reduce-while filesystem validation, lstat-before-read, tagged non-raising CLI errors]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-30-SUMMARY.md
  modified:
    - scripts/validate_repository_truth.exs
    - test/scripts/phase_164_repository_truth_test.exs
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv
key-decisions:
  - "Authority ignore subjects are inspected in the declared order with lstat and File.read; missing, wrong-type, and symlink subjects never fall through to canonical repository files."
  - "Absent or non-regular subjects return missing_authority_subject, while regular-file read failures return unreadable_authority_subject with the original reason."
  - "Plan 164-29's test/test_helper.exs boundary is retained as exact-one ledger subject M-34 so canonical validation remains complete after its summary activated discovery."
patterns-established:
  - "Malformed authority input crosses the public CLI only as bounded relative-path tuples plus the stable usage line."
  - "Ordered reduce_while halts on the first missing subject and flattens parsed ignore rules only after every required read succeeds."
requirements-completed: [TRTH-02]
coverage:
  - id: D1
    description: "Existing empty authority roots exit exactly 1 with one stable missing-.gitignore diagnostic, one usage line, no exception formatting, and no filesystem writes."
    requirement: TRTH-02
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_repository_truth_test.exs#existing empty authority root returns one bounded deterministic CLI diagnostic"
        status: pass
    human_judgment: false
  - id: D2
    description: "All six authority ignore subjects are read without raising, stop at the first declared missing subject, and reject directory, symlink, unreadable, and malformed inputs with stable tagged data."
    requirement: TRTH-02
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_repository_truth_test.exs#phase 164 incomplete authority root (3 selected, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Canonical ledger validation retains malformed-ledger, exact-one, stage-0 identity, row-order, and canonical relationship behavior."
    requirement: TRTH-02
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_repository_truth_test.exs (28 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "elixir scripts/validate_repository_truth.exs --repo /Users/jon/projects/mailglass --ledger .planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv"
        status: pass
    human_judgment: false
duration: 11min
completed: 2026-09-10
status: complete
---

# Phase 164 Plan 30: Incomplete Authority Root Diagnostics Summary

**The standalone repository-truth validator now rejects every incomplete authority ignore-file set through ordered tagged data and a bounded exit-one CLI diagnostic, without weakening canonical exactness.**

## Performance

- **Duration:** 11 minutes
- **Started:** 2026-09-11T03:03:19Z
- **Completed:** 2026-09-11T03:14:36Z
- **Tasks:** 2
- **Files modified:** 3 production/test/evidence files

## Accomplishments

- Added a real CLI regression proving an existing empty authority root produces the exact `missing_authority_subject` diagnostic twice, never emits a stack trace, and remains empty.
- Replaced every raising ignore-file stream with declared-order `lstat` and `File.read` results covering partial prefixes, directories, symlinks, permission failures, and malformed parent paths.
- Preserved canonical ledger semantics and added the one missing Plan 164-29 `test/test_helper.exs` disposition required by completed-plan discovery.

## Task Commits

1. **Task 1 RED: Empty authority-root CLI regression** — `d6d844be`
2. **Task 1 GREEN: Bounded first-subject diagnostic** — `5c87cc90`
3. **Task 2 RED: Ordered prefix regression** — `f8b7fd3a`
4. **Task 2 RED: Wrong-type and unreadable regressions** — `b3571b2b`
5. **Task 2 GREEN: Ordered non-raising authority reads** — `d92b344e`
6. **Task 2 REFACTOR: Canonical formatter cleanup** — `602137de`

## Files Created/Modified

- `scripts/validate_repository_truth.exs` — reads every required authority subject without raising and propagates stable tagged failures.
- `test/scripts/phase_164_repository_truth_test.exs` — pins deterministic CLI output, ordered prefix failures, wrong types, symlinks, unreadable files, and malformed parents.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv` — adds exact-one M-34 coverage for the Plan 164-29 root suite boundary.

## Decisions Made

- Kept the singular authority-root architecture and the existing declared `@ignore_files` order.
- Classified missing, `:enotdir`, directories, and symlinks as `missing_authority_subject`; only failures reading an already-verified regular file carry `unreadable_authority_subject`.
- Preserved the public `main/1` return convention, bounded `inspect(reason)` output, and canonical-repository non-fallback rule.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reconciled the Plan 164-29 root suite subject**

- **Found during:** Task 2 complete verification
- **Issue:** Once `164-29-SUMMARY.md` activated completed-plan discovery, `test/test_helper.exs` became a required audited subject without an exact-one ledger row, so canonical validation failed closed.
- **Fix:** Added M-34 with Plan 164-29 evidence and bound its canonical relationship in the shared validator.
- **Files modified:** `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv`, `scripts/validate_repository_truth.exs`
- **Verification:** Full repository-truth suite passed 28 tests; the standalone canonical validator returned `repository truth ledger: valid`.
- **Committed in:** `d92b344e`

---

**Total deviations:** 1 auto-fixed (1 blocking exact-one reconciliation).
**Impact on plan:** The fix preserves the plan's exact-one and evidence-discoverability prohibitions; no validator semantics were weakened and no unrelated scope was added.

## Issues Encountered

- The final formatter check found one noncanonical line wrap in the new relationship map. `602137de` applied formatting while GREEN, after which the full suite and standalone validator passed again.

## TDD Gate Compliance

- RED evidence records for the empty root, ordered prefix, and wrong-type CLI behaviors each returned `RED_EVIDENCE_OK` before implementation.
- RED commits precede their GREEN commits; the optional REFACTOR commit was made only after 28 tests and canonical validation were green.

## Verification

- Focused incomplete-authority group: 3 tests, 0 failures, 25 excluded.
- Complete repository-truth contract: 28 tests, 0 failures, no skips.
- Canonical standalone validator: `repository truth ledger: valid`.
- `mix format --check-formatted` and `git diff --check`: passed.
- No canonical pre-verification or terminal finalization command was run.

## Known Stubs

None. This plan introduced no stubs, TODOs, FIXMEs, placeholder data, or skipped tests.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 164-30 closes the malformed authority-root verifier gap and is ready for Plan 164-31.
- Phase and TRTH requirement completion remain pending for Plans 164-31 through 164-34 and the established protected-main terminal lifecycle.
- Terminal finalization remains intentionally unexecuted.

## Self-Check: PASSED

- All three modified plan files and this summary exist.
- All six measured TDD task commits exist after `plan_head_before`.
- Coverage classification accepted all three deliverables as automated and passing.
- No stub, skipped-test, unrun-verification, or unplanned threat-surface entry remains.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-10*
