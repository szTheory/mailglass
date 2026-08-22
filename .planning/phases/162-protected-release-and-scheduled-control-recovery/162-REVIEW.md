---
phase: 162-protected-release-and-scheduled-control-recovery
reviewed: 2026-08-22T20:49:19Z
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
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 162: Code Review Report

**Reviewed:** 2026-08-22T20:49:19Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

The new scheduled control paths do not converge in their normal idle state. In particular, the hourly release workflow turns an expected absence of a release proposal into a required failing result, and the scheduled hygiene workflow asks GitHub CLI for a branch name that `actions/checkout` does not provide in its detached-HEAD checkout. The post-publish index polling also has an insufficient job timeout for its three serial waits.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Idle scheduled release runs are forced to fail

**File:** `.github/workflows/release-please.yml:92`

**Issue:** On every schedule trigger `candidate_digest` is empty, so preflight immediately writes `should_run=true` and exits without checking whether a proposal exists. That unconditionally runs `capture-proposal` (line 427); when the normal state has no open release PR, it sets `result_status=blocked` / `proposal_missing` (lines 474-477). The result-writer then exits non-zero for that status (lines 613-618). Consequently the hourly control-recovery workflow remains red whenever there is nothing to release, rather than producing the documented pending observation outcome. The existing recovery test hides this path: `run_preflight/3` injects a nonempty digest by default at `test/scripts/release_trigger_recovery_test.exs:813`.

**Fix:** Give schedules an explicit idle path. For example, have preflight query for an open release PR and write `should_run=false` when none exists; then have the result writer emit `pending/scheduled_observation_not_elapsed` for that skipped scheduled run. Add an executable test for an empty `CANDIDATE_DIGEST` plus an empty PR list and assert a successful/pending scheduled result.

### CR-02: Scheduled repo-hygiene cannot identify the checked-out branch

**File:** `dev/mix/tasks/mailglass.repo.hygiene.ex:160`

**Issue:** `actions/checkout` leaves the scheduled workflow detached at a commit (`.github/workflows/repo-hygiene.yml:22-25`), so `git branch --show-current` is empty. `ci_state/1` passes that empty string to `gh run list --branch` (lines 170-180), which either fails argument validation or returns an unrelated latest run. It therefore reports `cannot-check` or `blocked` instead of finding CI for the actual checked-out SHA. The daily scheduled hygiene control cannot become green in its intended execution environment.

**Fix:** Pass the default branch explicitly from the workflow (for example `REPOSITORY_DEFAULT_BRANCH: ${{ github.event.repository.default_branch }}`) and use it when available, or query CI by `--commit "$sha"` and verify that returned run's `headSha` equals `sha`. Add a detached-HEAD integration fixture to the task tests.

## Warnings

### WR-01: Index gate times out before its documented retries can finish

**File:** `.github/workflows/post-publish-smoke.yml:327`

**Issue:** `wait-for-index` has an eight-minute job timeout, but it performs three serial polling loops that each permit up to five minutes (`lines 350-385`). A normal propagation delay in the first two packages can make the job hit GitHub's hard timeout before it finishes checking the inbound package, even though each package remains within its own stated allowance.

**Fix:** Poll the three package endpoints concurrently with one shared deadline, or raise the job timeout to cover the serial maximum plus setup overhead (at least 16 minutes).

### WR-02: Stale branches are collected but never affect readiness

**File:** `dev/mix/tasks/mailglass.repo.hygiene.ex:321`

**Issue:** The audit calculates branches older than 30 days, but always returns a passing `:stale_branches` check at lines 323-328. Thus a stale inventory is reported as release-ready and cannot influence the aggregate result, despite this task being the repository hygiene release gate.

**Fix:** Return `:blocked` when `stale` is nonempty (or explicitly rename this to informational inventory and remove it from release-readiness claims). Add tests for both a fresh and an older-than-30-days branch.

---

_Reviewed: 2026-08-22T20:49:19Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
