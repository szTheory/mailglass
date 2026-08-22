---
phase: 162-protected-release-and-scheduled-control-recovery
reviewed: 2026-08-22T15:31:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - .github/workflows/post-publish-smoke.yml
  - .github/workflows/release-please.yml
  - .github/workflows/repo-hygiene.yml
  - dev/mix/tasks/mailglass.repo.hygiene.ex
  - test/mailglass/publish/post_publish_smoke_contract_test.exs
  - test/mix/tasks/mailglass.repo.hygiene_test.exs
  - test/scripts/phase_162_release_reconciliation_test.exs
  - test/scripts/release_trigger_recovery_test.exs
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 162: Code Review Report

**Reviewed:** 2026-08-22T15:31:00Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

The new evidence paths are not executable on their normal success paths. The proposal-capture step overwrites its output-emitting `EXIT` trap, causing every capture that reaches worktree setup to be reported as `cannot-check`; and the smoke workflow requires a resolution artifact that it only creates for one blocked schedule state. Consequently, successful published/dispatch/scheduled smoke runs fail at artifact upload before downstream proof jobs can start. The focused tests pass because they inspect fragments or supply synthetic step outputs rather than exercise these workflow paths.

## Critical Issues

### CR-01: Proposal capture replaces the trap that publishes its control result

**File:** `.github/workflows/release-please.yml:453`
**Issue:** The capture step installs `trap emit_capture_outputs EXIT`, but line 487 installs a second `EXIT` trap for worktree cleanup. In Bash, the latter replaces the former. Every path that creates the candidate worktree—including the normal successful capture path—therefore never writes `result_status=pass`, identity fields, or `captured=true` to `GITHUB_OUTPUT`. The following result writer defaults the run to `cannot-check`, and line 609 fails it. A real proposal-only run can never succeed and a known identity mismatch is misclassified as `cannot-check`.

**Fix:** Use one cleanup/output trap, or explicitly chain both operations:

```bash
cleanup_capture() {
  git worktree remove --force "$candidate_root" >/dev/null 2>&1 || true
  emit_capture_outputs
}
trap cleanup_capture EXIT
```

Install this only after `candidate_root` is initialized (or guard the cleanup for an empty value), and add an integration test that runs the capture script through worktree creation and asserts its GitHub outputs and the emitted artifact are `pass`.

### CR-02: The smoke workflow makes normal runs fail because its required artifact is never written

**File:** `.github/workflows/post-publish-smoke.yml:217`
**Issue:** `Upload post-publish resolution` always runs with `if-no-files-found: error`, but `post-publish-resolution.json` is written only in the scheduled, authorized-but-unpublished branch at lines 134–149. A normal protected dispatch, a completed scheduled canary, and even the intentional release-event no-op create no file. The upload step then fails `resolve-completed-target`; all dependent smoke jobs are skipped. This violates both the successful no-op contract and artifact-before-fail recovery behavior.

**Fix:** Write one resolution artifact for every trigger/result before any exit, including `pass`, release-event `pending/no-op`, `blocked`, and `cannot-check` cases; then keep the artifact upload required. For example, initialize an atomic result file at the start of the resolver and use a single `EXIT` handler to serialize the final status/reason before the upload step.

## Warnings

### WR-01: Contract tests can pass while the two workflow failures above remain

**File:** `test/scripts/release_trigger_recovery_test.exs:347`
**Issue:** The test executes only the isolated result-writer script with synthetic `CAPTURE_STATUS` and `CAPTURE_REASON` values. It never executes the capture step, so it cannot detect that line 487 replaces the output trap. Likewise, the smoke contract test at `test/mailglass/publish/post_publish_smoke_contract_test.exs:82` checks text presence but never verifies that a successful resolver path writes the artifact required at line 217. The focused suite passes despite both production paths being broken.

**Fix:** Add executable workflow-script tests with a fake `gh`/git worktree fixture: assert a successful capture emits all five outputs and yields a `pass` artifact; separately execute resolver success/no-op/blocked branches and assert each produces valid JSON before the upload contract is evaluated.

---

_Reviewed: 2026-08-22T15:31:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
