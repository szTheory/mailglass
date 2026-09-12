---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 40
subsystem: repository-truth-validation
tags: [elixir, git-index, lstat, symlink, repository-truth, tdd]
status: complete
requires:
  - phase: 164-39
    provides: reconciled exact-one tracked-subject ledger and terminal-gate evidence
provides:
  - lstat-gated tracked worktree authority that never follows symlinks
  - closed regular Git index mode policy for 100644 and 100755
  - public API and CLI regressions for external symlinks and non-regular index objects
  - complete exact-path, stage, framing, adjacency, ordering, and mode regression matrix
affects: [164-41, repository-truth-verification, terminal-closeout]
actuals:
  tokens: 2237
  tasks: 2
  commits: 3
plan_head_before: c0204d980ef359052ec71de06804298235372703
tech-stack:
  added: []
  patterns:
    - lstat type authority before Git index identity validation
    - exact-one stage-0 path record followed by closed regular-mode validation
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-40-SUMMARY.md
  modified:
    - scripts/validate_repository_truth.exs
    - test/scripts/phase_164_repository_truth_test.exs
key-decisions:
  - "Tracked ledger subjects must be lstat regular files before any Git-index claim is evaluated; symlinks and all other entry types share the stable tracked_subject_not_regular failure."
  - "Only exact-one stage-0 records in modes 100644 and 100755 establish tracked Git identity; other structurally valid modes receive tracked_subject_invalid_index_mode."
patterns-established:
  - "Worktree-before-index trust chain: lstat proves local type without following links, then literal pathspec Git output proves exact regular-object identity."
  - "Failure-class ordering: framing and syntax remain malformed, path/stage/cardinality remain identity mismatch, and mode is classified only for an otherwise exact record."
requirements-completed: [TRTH-02]
coverage:
  - id: D1
    description: "External-target tracked symlinks fail identically and without target disclosure through Ledger.validate/3 and the standalone CLI."
    requirement: TRTH-02
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_repository_truth_test.exs#phase 164 validator file identity — 3 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: "Both regular Git blob modes pass while symlink, gitlink, and other structurally valid non-regular modes fail without weakening exact path, stage, ordering, or framing behavior."
    requirement: TRTH-02
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_repository_truth_test.exs — 39 tests, 0 failures"
        status: pass
      - kind: integration
        ref: "elixir scripts/validate_repository_truth.exs --repo /Users/jon/projects/mailglass --ledger .planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv — repository truth ledger: valid"
        status: pass
    human_judgment: false
duration: 7m
completed: 2026-09-12
---

# Phase 164 Plan 40: Tracked Regular-Object Trust Anchor Summary

**Repository truth now accepts tracked subjects only when both the worktree entry and exact stage-0 Git record prove a regular file, with bounded public failures for symlink and non-regular object attacks.**

## Performance

- **Duration:** 7 minutes
- **Started:** 2026-09-12T02:17:01Z
- **Completed:** 2026-09-12T02:24:18Z
- **Tasks:** 2
- **Tracked files modified:** 2

## Accomplishments

- Replaced symlink-following regularity checks with `File.lstat/1`, rejecting missing, symlink, directory, device, and other non-regular tracked entries before index validation.
- Restricted otherwise-exact stage-0 Git records to modes `100644` and `100755`, with a stable `tracked_subject_invalid_index_mode` tag for non-regular modes.
- Added public API and standalone CLI regressions for a real mode-120000 symlink whose target lives outside the disposable clone, including bounded, subject-relative, stack-free diagnostics.
- Expanded the staged-record matrix across real 100755 executable, 120000 symlink, and 160000 gitlink entries while retaining literal, metacharacter, prefix-adjacent, newline, duplicate, reordered, malformed, missing, and non-stage-0 contracts.

## Task Commits

1. **Task 1 RED: Define external tracked-symlink public contracts** — `5f8acdfd` (test)
2. **Task 1 GREEN: Reject non-regular worktree and Git-index subjects** — `8810c419` (feat)
3. **Task 2: Complete the regular and non-regular index-mode matrix** — `cd5e3c11` (test)

The plan summary and tracking metadata are committed separately after self-check and state synchronization.

## TDD Gate Compliance

- **RED:** `5f8acdfd` added the public API/CLI symlink contracts. The targeted API test failed because `Ledger.validate/3` returned `:ok` for a mode-120000 external symlink; the persisted record returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **GREEN:** `8810c419` added the lstat and regular-index-mode gates. The tracer passed 3 tests with 0 failures before and after commit.
- **Expansion:** `cd5e3c11` broadened the matrix over behavior delivered by Task 1. No second production change or artificial failing state was introduced; the complete file passed 39 tests with 0 failures.
- **REFACTOR:** No separate refactor commit was needed; the validator changes remained narrow and the full focused suite stayed green.

## Files Created/Modified

- `scripts/validate_repository_truth.exs` — enforces lstat regularity and the closed 100644/100755 Git index mode set.
- `test/scripts/phase_164_repository_truth_test.exs` — exercises public symlink rejection plus regular/non-regular staged-record identity matrices.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-40-SUMMARY.md` — records execution, TDD evidence, verification, and downstream handoff.

## Decisions Made

- Worktree type is authoritative before Git index identity: no symlink target or other non-regular entry may reach the index gate.
- Mode validation occurs only after one structurally valid, stage-0, byte-identical path record is selected, preserving existing malformed and identity-mismatch classes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Execute the current validator source in the disposable CLI regression**

- **Found during:** Task 1 GREEN verification
- **Issue:** The first test draft invoked the validator script copied into the clone before the GREEN source commit, so it kept exercising the pre-fix implementation even though the disposable repository and ledger were correct.
- **Fix:** Execute the current repository validator source while passing the disposable clone as `--repo` and its canonical copied ledger as `--ledger`.
- **Files modified:** `test/scripts/phase_164_repository_truth_test.exs`
- **Verification:** The tagged tracer passed 3 tests with 0 failures and retained the real mode-120000 fixture.
- **Committed in:** `8810c419`

**2. [Rule 1 - Bug] Reconcile stale legacy state position after official state handlers**

- **Found during:** Plan metadata synchronization
- **Issue:** `state.advance-plan` parsed the stale legacy body as Plan 1 and advanced it to Plan 2 even though disk summaries and frontmatter showed Plan 40 complete.
- **Fix:** Reconciled `STATE.md` to the summary-derived totals: 63 of 70 plans complete, Plan 40 completed, and Plan 41 next.
- **Files modified:** `.planning/STATE.md`
- **Verification:** `roadmap.update-plan-progress` independently reported 40 of 44 Phase 164 plans complete, matching the summary count on disk.
- **Committed in:** Final metadata commit

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** The corrections ensure the CLI regression tests the implementation under development and that tracking reflects repository evidence, without changing repository authority, scope, or expected diagnostics.

## Issues Encountered

- Task 2 is coverage expansion over the closed mode policy required and implemented by Task 1. The new matrix was green immediately against that implementation, so no artificial second RED or unnecessary production edit was manufactured.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None. The lstat, Git-index, and diagnostic surfaces are the exact trust boundaries covered by T-164-155 through T-164-158 in the plan.

## User Setup Required

None.

## Next Phase Readiness

- Plan 164-41 can build its completed-plan metadata parsing and bounded non-Git diagnostics on the now-closed regular-object trust anchor.
- TRTH-02 and Phase 164 remain pending until all other plans declaring the shared requirement have summaries and ordinary verification passes.
- Terminal finalization was not invoked and no terminal evidence was produced.

## Self-Check: PASSED

- Both task-owned implementation files and this summary exist.
- Commits `5f8acdfd`, `8810c419`, and `cd5e3c11` resolve to committed objects.
- The measured pre-summary ledger count is 3 commits from `c0204d980ef359052ec71de06804298235372703`.
- The final focused run passed 39 tests with 0 failures, the canonical CLI printed `repository truth ledger: valid`, and `git diff --check` passed.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-12*
