---
phase: 164-repository-truth-reconciliation-and-closeout
reviewed: 2026-09-09T19:15:34Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - .gitignore
  - .gsd/extensions/finalize-phase/extension-manifest.json
  - .gsd/extensions/finalize-phase/index.ts
  - MAINTAINING.md
  - README.md
  - config/test_exceptions.exs
  - mailglass_admin/README.md
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_inbound/README.md
  - scripts/ci_monitor.cjs
  - scripts/closeout_repository_truth.sh
  - scripts/finalize_phase_164.sh
  - scripts/scheduled_control_evidence.sh
  - scripts/validate_repository_truth.exs
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/publish/maintaining_release_gate_contract_test.exs
  - test/scripts/phase_164_closeout_test.exs
  - test/scripts/phase_164_repository_truth_test.exs
  - test/scripts/scheduled_control_evidence_test.exs
  - test_js/ci-monitor.test.cjs
findings:
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
---

# Phase 164: Code Review Report

**Reviewed:** 2026-09-09T19:15:34Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

The reviewed contracts pass (90 tests, 0 failures, 1 pre-existing skip), but the final evidence boundary is not fail-closed. Terminal mode accepts a stale verifier result after arbitrary source changes, pre-verification mode does not enforce the Plan 13 integration precondition, and a new hostile-identity test can recursively delete a pre-existing sibling directory. Scheduled evidence also treats timestamps in the future as fresh.

The current checkout does not itself constitute terminal proof: `164-VERIFICATION.md` still has `status: gaps_found`, and local `HEAD` is ahead of `origin/main`. This is correctly rejected by today's preconditions, but does not mitigate the implementation defects below once those superficial state checks are satisfied.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01 [BLOCKER]: Terminal mode does not bind the passing verifier to the implementation it certifies

**File:** `/Users/jon/projects/mailglass/scripts/finalize_phase_164.sh:115-120`

**Issue:** `require_terminal_state` checks only that the verification frontmatter contains `status: passed`. It does not read an implementation SHA from the verifier, nor restrict the changes between verification and the terminal `HEAD` to known completion-metadata paths. Consequently, after any old passing `164-VERIFICATION.md` exists, arbitrary source changes can land, receive an ordinary green CI run, and still be declared terminally finalized without goal-level verification of those changes. The exact-current CI and ledger checks do not replace this missing binding: CI proves its configured tests passed, while the ledger validates row semantics rather than source contents.

**Fix:** Record the verified implementation SHA in `164-VERIFICATION.md`, parse it in `require_terminal_state`, and fail unless `git diff --name-only <verified-sha>..HEAD` contains only an explicit allowlist of phase-completion metadata. Alternatively, run goal verification against the final source tree and store a detached signed/hashed verifier result that the finalizer can bind to the current tree without creating another tracked write.

### CR-02 [BLOCKER]: Pre-verification can pass without the required Plan 13 repair being integrated

**File:** `/Users/jon/projects/mailglass/scripts/finalize_phase_164.sh:90-96`

**Issue:** Pre-verification hard-codes summaries `164-01` through `164-11`. Plan 164-14 explicitly requires Plan 13 tests and `164-13-SUMMARY.md` to be on protected main before capture, yet the executable gate never checks either Plan 12 or Plan 13. A clean protected-main commit containing only Plans 01-11 can therefore obtain `pre-verification evidence passed`, contrary to the current acceptance contract and the Plan 14 claim that the complete gap repair was integrated first.

**Fix:** Make the current pre-verification gate require summaries 01 through 13 (and preferably the expected numbered plan set plus the specific Plan 13 test paths tracked at `HEAD`). Add a process-level regression that removes `164-13-SUMMARY.md` from a disposable canonical fixture and proves evidence collection never starts.

### CR-03 [BLOCKER]: New test cleanup can recursively delete an unrelated sibling checkout

**File:** `/Users/jon/projects/mailglass/test/scripts/phase_164_closeout_test.exs:600-606`

**Issue:** The hostile-repository test constructs `prefix_collision` beside the real repository using `@repo_root <> "-gap-#{System.unique_integer(...)}`. `File.mkdir_p!/1` succeeds if that path already exists, and `on_exit` then unconditionally calls `File.rm_rf!/1`. `System.unique_integer/1` is only VM-local; after a restart or a prior interrupted run, the generated sibling path can already contain user data. Running the test can therefore destroy an unrelated directory outside the test's temporary root.

**Fix:** Allocate the prefix-collision fixture with a collision-safe exclusive temporary-directory primitive, or keep it under `temporary_root!()` and test the canonical-prefix logic through an injected canonical path. At minimum, fail if the candidate already exists, record that this invocation created it, and delete it only when that ownership marker is present.

## Warnings

### WR-01 [WARNING]: Future scheduled-run timestamps are accepted as fresh

**File:** `/Users/jon/projects/mailglass/scripts/scheduled_control_evidence.sh:348-352`

**Issue:** Freshness is tested only as `now - updated_at <= max_age`. A timestamp in the future yields a negative age and passes. The independent finalizer repeats the same one-sided predicate at `scripts/finalize_phase_164.sh:177-180`, so the second validation does not catch it. A malformed or clock-skewed upstream record can remain "current" indefinitely until wall time catches up, contradicting the documented fail-closed treatment of malformed evidence.

**Fix:** Parse the timestamp once and require `age >= 0 and age <= max_age` in both predicates, with a small explicitly documented clock-skew allowance if needed. Add fixtures for a far-future timestamp and an invalid timestamp to both the scheduled sweep and finalizer raw-source tests.

---

_Reviewed: 2026-09-09T19:15:34Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
