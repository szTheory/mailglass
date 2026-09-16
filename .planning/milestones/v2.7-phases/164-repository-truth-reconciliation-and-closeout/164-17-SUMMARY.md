---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 17
subsystem: repository-truth-finalization
tags: [git, elixir, gsd-extension, trust-boundary, immutable-execution]
requires:
  - phase: 164-16
    provides: whole-document maintainer authority reconciliation and the final Phase 164 gap inventory
provides:
  - literal-pathspec exact Git-index proof for every tracked repository-truth row
  - fail-closed standalone repository-truth CLI argument handling
  - full HEAD/index/worktree authentication of the phase shim and downstream gate script
  - private immutable execution and guaranteed cleanup of authenticated downstream HEAD bytes
affects: [phase-verification, terminal-finalization, TRTH-02, TRTH-03]
actuals:
  tokens: 5586
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [literal Git pathspec identity, transitive executable authentication, private immutable materialization]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-17-SUMMARY.md
  modified:
    - scripts/validate_repository_truth.exs
    - test/scripts/phase_164_repository_truth_test.exs
    - .gsd/extensions/finalize-phase/index.ts
    - test/scripts/phase_164_closeout_test.exs
key-decisions:
  - "Tracked ledger state requires a regular file plus one exact literal-pathspec Git-index return equal to the subject; filesystem presence alone is never repository proof."
  - "The finalize-phase extension authenticates both executable links but dispatches only a mode-0500 private materialization of the downstream HEAD blob, removed in finally."
patterns-established:
  - "Repository identity checks use argv-only Git calls with global literal-pathspec semantics and exact returned-path equality."
  - "Protected dispatch authenticates every transitive executable before materialization and never executes checkout bytes."
requirements-completed: [TRTH-02, TRTH-03]
coverage:
  - id: D1
    description: "Tracked ledger rows fail when their exact regular-file subject is absent from the Git index, including metacharacter and prefix-adjacent cases."
    requirement: TRTH-02
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_repository_truth_test.exs#phase 164 trust anchors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Standalone validator misuse exits nonzero while canonical invocation and Code.require_file module use remain correct."
    requirement: TRTH-02
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_repository_truth_test.exs#standalone CLI fails closed while requiring the module stays side-effect free"
        status: pass
    human_judgment: false
  - id: D3
    description: "The real finalize-phase handler rejects staged-new or divergent shim/downstream bytes and executes only cleaned-up private downstream HEAD bytes."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_closeout_test.exs#real extension handler authenticates and privately executes the complete HEAD chain"
        status: pass
    human_judgment: false
duration: 13min
completed: 2026-09-09
status: complete
---

# Phase 164 Plan 17: Immutable Repository Trust Anchors Summary

**Repository truth now derives tracked claims and finalizer execution from exact immutable Git authority under hostile but valid index and worktree states.**

## Performance

- **Duration:** 13 minutes
- **Started:** 2026-09-10T00:57:55Z
- **Completed:** 2026-09-10T01:10:29Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Bound every `state=tracked` ledger row to regular-file type and one byte-exact path returned by `git --literal-pathspecs ls-files --error-unmatch` in the target repository.
- Made no-argument, unknown-option, and one-missing-option validator invocations bounded nonzero failures while preserving side-effect-free module loading.
- Authenticated the exact phase shim and downstream finalizer as HEAD blobs with exact index membership and zero staged/unstaged divergence before dispatch.
- Executed only a restrictive private materialization of the downstream HEAD blob and removed the directory after successful and failed Bash execution.

## Task Commits

1. **Task 1: Trace a tracked ledger claim through exact Git-index evidence** — `3ed8a8b1` (RED), `67ecdc2d` (GREEN)
2. **Task 2: Authenticate and execute only the committed finalizer blob** — `59e48bb7` (RED), `093e3616` (GREEN), `4cb100f9` (regression-contract fix)

## Files Created/Modified

- `scripts/validate_repository_truth.exs` — Exact literal-pathspec index membership plus bounded standalone CLI entry behavior.
- `test/scripts/phase_164_repository_truth_test.exs` — Disposable-clone tracked/untracked, metacharacter, adjacency, and CLI/module regressions.
- `.gsd/extensions/finalize-phase/index.ts` — Dual-link HEAD authentication, restrictive private materialization, direct downstream dispatch, and guaranteed cleanup.
- `test/scripts/phase_164_closeout_test.exs` — Real-handler disposable-repository coverage for staged-new, staged/unstaged divergence, immutable bytes, exact arguments, and cleanup.

## Decisions Made

- A successful Git command is not sufficient evidence: normalized stdout must contain exactly the requested repository-relative path and nothing else.
- Git exit status 1 is reported as untracked membership, while other command failures retain a separate Git-failure category.
- The committed shim remains an authenticated command-selection contract, but Bash receives only the private downstream materialization path.
- Temporary finalizer directories are mode `0700`; materialized scripts are mode `0500` and are removed in `finally` for both result paths.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated the legacy dispatcher source contract after the behavioral implementation passed**

- **Found during:** Plan-level regression verification after Task 2
- **Issue:** The pre-existing source assertion still required the old mutable-checkout `pi.exec` expression and therefore failed against the secured dispatcher.
- **Fix:** Replaced it with assertions for literal-pathspec membership, HEAD blob reads, private Bash dispatch, allocation, and cleanup.
- **Files modified:** `test/scripts/phase_164_closeout_test.exs`
- **Verification:** Complete focused regression set passed with 102 tests, 0 failures, and 1 pre-existing historical skip.
- **Committed in:** `4cb100f9`

---

**Total deviations:** 1 auto-fixed bug.
**Impact on plan:** The correction keeps existing contract coverage aligned with the planned security behavior; no scope expanded.

## Issues Encountered

- The focused suite emits the existing optional OTLP-exporter warning and Node's experimental type-stripping warning from the behavioral TypeScript harness. Neither affects outcomes.
- The complete focused suite includes one pre-existing historical docs skip; it is not Phase 164 proof and was not introduced or modified by this plan.

## TDD Gate Compliance

- Task 1 RED reproduced false tracked certification, missing literal identity enforcement, and silent-success CLI misuse before GREEN.
- Task 2 RED proved the real handler dispatched a staged-new shim absent from HEAD before GREEN.
- Both GREEN implementations passed their task-scoped tagged suites before commit; no refactor commit was needed.

## Verification

- Complete plan suite: 102 tests, 0 failures, 1 pre-existing historical skip.
- Canonical direct validator: `repository truth ledger: valid`.
- Format check for all changed Elixir files: passed.
- `git diff --check`: passed.
- Both `phase_164_trust_anchor` groups selected nonzero tests and passed independently.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The verifier's remaining TRTH-02 and TRTH-03 trust-boundary defects now have direct behavioral proof at the production seams.
- Ordinary Phase 164 verification may be refreshed after integration. The separately governed terminal finalizer remains intentionally unrun and no protected evidence was refreshed by this plan.

## Self-Check: PASSED

- All four changed implementation/test files and this summary exist.
- Commits `3ed8a8b1`, `67ecdc2d`, `59e48bb7`, `093e3616`, and `4cb100f9` are present in Git history.
- Fresh complete plan verification passed after the last code change.
- No goal-blocking stub, new skipped test, unrun plan verification, or unplanned threat surface remains.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-09*
