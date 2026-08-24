---
phase: 162-protected-release-and-scheduled-control-recovery
reviewed: 2026-08-24T18:49:30Z
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
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 162: Code Review Report

**Reviewed:** 2026-08-24T18:49:30Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

The release controls have a post-merge control-flow failure: the protected dispatch completes its merge/release path and then runs a proposal-capture step that requires the just-merged release PR to remain open. The repo-hygiene task also treats malformed successful `gh` output as a task crash and its `--apply` preservation claim does not cover uncommitted changes.

## Critical Issues

### CR-01: Protected release dispatch fails after it has merged the release PR

**Classification:** BLOCKER

**File:** `.github/workflows/release-please.yml:473`

**Issue:** `capture-proposal` runs for every non-scheduled trigger, including a `workflow_dispatch` with a nonempty protected candidate digest. It executes after `protected-merge` and the release action (lines 277-311). That path merges the exact release PR, so the query at line 511 for an *open* `release-please--branches--main` PR normally returns zero rows. Lines 518-521 then set `proposal_missing` and fail. The result writer and final gate turn that into a failed workflow after the protected release has already been merged/released. The tests only exercise proposal capture before merge and therefore miss this lifecycle.

**Fix:** Restrict proposal discovery/capture/result gating to proposal-only runs, or explicitly emit a successful/skipped protected-dispatch result. For example:

```yaml
if: ${{ steps.release-preflight.outputs.should_run == 'true' && github.event.inputs.candidate_digest == '' && (github.event_name != 'schedule' || steps.scheduled-proposal.outputs.should_capture == 'true') }}
```

Apply the same predicate (or an explicit protected-path result) to the result writer and final non-pass gate so a valid protected release is not evaluated as an absent proposal.

## Warnings

### WR-01: A malformed successful CI response crashes the hygiene command

**Classification:** WARNING

**File:** `dev/mix/tasks/mailglass.repo.hygiene.ex:182-185`

**Issue:** A zero-exit `gh run list` response is decoded with `Jason.decode!()`. A proxy/authentication error or malformed response that still exits zero raises and terminates the task instead of reporting the documented `cannot-check` result. This prevents the workflow from writing its structured audit JSON and obscures the recovery action.

**Fix:** Use `Jason.decode/1` and validate that the decoded value is a list; return `cannot_check(:ci_state, ...)` with the response/error details for decode failures.

### WR-02: `--apply` does not preserve dirty working-tree changes

**Classification:** WARNING

**File:** `dev/mix/tasks/mailglass.repo.hygiene.ex:95-98`

**Issue:** For a dirty repository, `--apply` only creates a branch at the existing `HEAD`. Git branches do not contain uncommitted or untracked changes, so this does not perform the documented preservation action for dirty local state. It then immediately re-audits the same dirty tree and returns blocked, leaving the user with a branch that cannot restore their edits.

**Fix:** Either make `--apply` create a recoverable patch/stash (and report its path/name) before any cleanup, or narrow the documentation and behavior so preservation branches are created only for committed-ahead work while dirty trees are explicitly left untouched and blocked.

---

_Reviewed: 2026-08-24T18:49:30Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
