---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 41
subsystem: repository-truth-validation
tags: [elixir, frontmatter, git-identity, fail-closed, tdd]
status: complete
requires:
  - phase: 164-40
    provides: exact regular worktree and Git-index identity for tracked ledger subjects
provides:
  - order-independent structural files_modified parsing limited to opening plan frontmatter
  - stable missing and malformed completed-plan metadata tags through API and CLI
  - early tagged rejection of existing non-Git repository roots
  - complete adjacency, ordering, emptiness, indentation, duplication, delimiter, and scalar regression matrix
affects: [164-44, repository-truth-verification, terminal-closeout]
actuals:
  tokens: 4577
  tasks: 2
  commits: 6
plan_head_before: 51be677a198e2399a940e38824c92481a5ff1fdd
tech-stack:
  added: []
  patterns:
    - opening-frontmatter line/state parsing with tagged result propagation
    - repository directory validation followed by explicit Git work-tree identity validation
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-41-SUMMARY.md
  modified:
    - scripts/validate_repository_truth.exs
    - test/scripts/phase_164_repository_truth_test.exs
key-decisions:
  - "Completed-plan artifact discovery accepts an empty list only for a standalone explicit files_modified: [] declaration; every missing, scalar, duplicate, misindented, unterminated, or delimiter-invalid shape fails with a stable tag."
  - "repo_root must pass git rev-parse --is-inside-work-tree before any ls-files call, while authority_root remains a directory-only policy fixture boundary."
patterns-established:
  - "Tagged metadata composition: plan_files_modified/1 returns {:ok, paths} or a plan-relative error that phase_artifacts/1 and audit_subjects/2 preserve unchanged."
  - "Split root trust: repository identity is Git-backed, policy authority is filesystem-backed, and neither is allowed to inherit the other's requirement."
requirements-completed: [TRTH-02]
coverage:
  - id: D1
    description: "Completed-plan files_modified metadata is structural, order-independent, explicit-empty-aware, and fail-closed through public parser, audit, and CLI boundaries."
    requirement: TRTH-02
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_repository_truth_test.exs#phase 164 completed-plan metadata — 4 tests, 0 failures"
        status: pass
      - kind: integration
        ref: "mix test test/scripts/phase_164_repository_truth_test.exs --only phase_164_plan_metadata --only phase_164_git_identity — 6 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: "Existing non-Git repository roots return a tagged API error and one bounded stack-free CLI diagnostic without requiring authority_root to be a Git repository."
    requirement: TRTH-02
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_repository_truth_test.exs#phase 164 Git repository identity — 2 tests, 0 failures"
        status: pass
      - kind: integration
        ref: "test/scripts/phase_164_repository_truth_test.exs — 45 tests, 0 failures"
        status: pass
    human_judgment: false
duration: 9m
completed: 2026-09-12
---

# Phase 164 Plan 41: Structural Plan Metadata and Git Root Validation Summary

**Repository truth now derives completed-plan artifacts from validated opening frontmatter and rejects non-Git repository roots with stable bounded API and CLI diagnostics.**

## Performance

- **Duration:** 9 minutes
- **Started:** 2026-09-12T03:32:50Z
- **Completed:** 2026-09-12T03:42:15Z
- **Tasks:** 2
- **Tracked files modified:** 2

## Accomplishments

- Replaced the `files_modified`-to-`autonomous` regex boundary with a public structural parser that accepts reordered dash lists and only an actually empty explicit `[]` value.
- Preserved exact plan-relative missing and malformed tags through completed-plan discovery, audit composition, validation, and standalone CLI rendering.
- Split Git-backed `repo_root` validation from directory-only `authority_root` validation, rejecting non-Git roots before tracked-subject discovery.
- Expanded public regressions across adjacent, non-adjacent, reordered, nested, explicit-empty, blank, scalar, indentation, duplicate-key, delimiter, and unterminated-list shapes.

## Task Commits

1. **Task 1 RED: Define structural completed-plan metadata contracts** — `7041ba6d` (test)
2. **Task 1 GREEN: Parse and propagate completed-plan metadata structurally** — `adac5f76` (feat)
3. **Task 2 RED: Define non-Git-root and full metadata-shape contracts** — `ec7301ea` (test)
4. **Task 2 GREEN: Validate Git identity before tracked discovery** — `341b501b` (feat)
5. **Rule 1 RED: Reject list entries hidden after explicit empty metadata** — `797602a3` (test)
6. **Rule 1 GREEN: Fail closed on content following explicit empty metadata** — `413584c5` (fix)

The plan summary and GSD tracking metadata are committed separately after self-check and state synchronization.

## TDD Gate Compliance

- **Task 1 RED:** Three targeted assertions proved reordered paths were omitted, the public parser seam was absent, and malformed values collapsed into successful empty discovery. `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK` with `target_test_failed`.
- **Task 1 GREEN:** The same metadata group passed 3 tests with 0 failures after the structural parser and tagged propagation landed.
- **Task 2 RED:** The non-Git API target captured the current `MatchError` and failed against the required `invalid_git_repository` result; five adjacent metadata and authority assertions passed. The evidence checker returned `RED_EVIDENCE_OK`.
- **Task 2 GREEN:** The combined tagged groups passed 6 tests with 0 failures after early Git identity validation and tagged `ls-files` handling.
- **Rule 1 RED/GREEN:** A post-GREEN hostile shape demonstrated that list entries after explicit `[]` were silently ignored. Its evidence returned `RED_EVIDENCE_OK`; the narrow fix restored 6/6 focused and 45/45 full-file results.
- **REFACTOR:** No separate refactor commit was needed; parsing and root-validation helpers remained narrow and every cleanup occurred while GREEN.

## Files Created/Modified

- `scripts/validate_repository_truth.exs` — structurally parses completed-plan metadata, propagates exact tags, validates Git identity early, and returns tagged tracked-subject command failures.
- `test/scripts/phase_164_repository_truth_test.exs` — proves public parser, audit, CLI, non-Git root, plain authority, and metadata-shape behavior.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-41-SUMMARY.md` — records TDD evidence, verification, deviations, and downstream readiness.

## Decisions Made

- Treat only a standalone `files_modified: []` declaration as empty; trailing list content invalidates it instead of being ignored.
- Report plan paths from the `.planning/` boundary so temporary authority roots never leak into diagnostics.
- Require Git work-tree identity only for `repo_root`; keep `authority_root` usable as an independent ignore-policy fixture.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rejected list entries hidden after explicit empty metadata**

- **Found during:** Task 2 post-GREEN fail-closed review
- **Issue:** `files_modified: []` returned an empty success even when indented dash entries followed before the next key, allowing malformed evidence to disappear.
- **Fix:** Added a failing shape-matrix case, validated its RED evidence, and rejected non-comment content following an explicit empty declaration.
- **Files modified:** `scripts/validate_repository_truth.exs`, `test/scripts/phase_164_repository_truth_test.exs`
- **Verification:** Focused groups passed 6 tests with 0 failures; the full file passed 45 tests with 0 failures.
- **Committed in:** `797602a3`, `413584c5`

**2. [Rule 1 - Bug] Reconciled stale plan position left by state synchronization**

- **Found during:** Plan metadata synchronization
- **Issue:** The official state handlers advanced the narrative position to Plan 44 and counted 66 completed plans, but left frontmatter `current_plan: 40` and the body progress counter at 63.
- **Fix:** Reconciled both stale fields to the handler's summary-derived current position and completed-plan count, while restoring the pre-existing unstaged `.planning/state.json` bytes unchanged.
- **Files modified:** `.planning/STATE.md`
- **Verification:** `state.advance-plan` reported Plan 44 of 44; `state.update-progress` reported 66 of 70 completed plans; `roadmap.update-plan-progress` reported 43 of 44 Phase 164 summaries.
- **Committed in:** Final metadata commit

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** The corrections close a directly related fail-open metadata shape and keep planning state internally consistent without expanding implementation scope.

## Issues Encountered

None.

## Authentication Gates

None.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Plan 164-44 can consume stable completed-plan metadata and Git-root diagnostics when reconciling final verification evidence.
- TRTH-02 remains subject to the shared-ID readiness gate until every declaring Phase 164 plan has a summary.
- No completion-only terminal state or finalization command was advanced.

## Self-Check: PASSED

- Both task-owned implementation files and this summary exist.
- Commits `7041ba6d`, `adac5f76`, `ec7301ea`, `341b501b`, `797602a3`, and `413584c5` resolve to committed objects.
- The measured pre-summary ledger count is 6 commits from `51be677a198e2399a940e38824c92481a5ff1fdd`.
- The final focused run passed 6 tests with 0 failures, the full file passed 45 tests with 0 failures, coverage classification reported both deliverables auto-covered, and the canonical CLI printed `repository truth ledger: valid` after summary activation.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-12*
