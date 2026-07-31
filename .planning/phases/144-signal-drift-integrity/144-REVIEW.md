---
phase: 144-signal-drift-integrity
reviewed: 2026-07-31T21:33:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - .github/workflows/ci.yml
  - .github/workflows/branch-protection-drift.yml
  - scripts/branch-protection-outcome.sh
  - test/scripts/branch_protection_truth_test.exs
  - test/scripts/required_checks_test.exs
  - dev/mix/tasks/mailglass.repo.hygiene.ex
  - test/mix/tasks/mailglass.repo.hygiene_test.exs
  - mailglass_admin/scripts/check-conformance.sh
  - test/scripts/icon_exists_gate_test.exs
  - .github/workflows/publish-hex.yml
  - .github/workflows/post-publish-smoke.yml
  - test/scripts/linked_release_concurrency_test.exs
  - CONTRIBUTING.md
  - test/scripts/release_trigger_recovery_test.exs
  - .github/workflows/release-please.yml
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 144: Code Review Report

**Reviewed:** 2026-07-31T21:33:00Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The earlier review findings are resolved: unsupported dynamic icon expressions now fail closed, the icon test covers those forms, and repo hygiene treats an unresolved upstream as non-success while preserving an independently dirty state as blocked. The focused contract suite passes (39 tests), but the new release recovery preflight still cannot execute reliably in a real GitHub runner and also turns GitHub API failures into a release attempt. Both defects break the intended zero-human, fail-closed recovery path.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Release preflight reads the manifest without checking out the repository

**Classification:** BLOCKER

**File:** `.github/workflows/release-please.yml:40-70`
**Issue:** The first job step is the preflight, but it runs `jq ... .release-please-manifest.json` at line 69 before any `actions/checkout` step. GitHub-hosted runners begin with an empty workspace, so this affects push, scheduled, and manually dispatched runs—not only the paths called out in the comment. Because `jq` is inside process substitution for `mapfile`, its failure is not propagated by `set -e`; `expected_tags` is empty and line 89 then records `should_run=false`. Consequently, the hourly/manual recovery silently no-ops instead of creating the releases it is supposed to restore. The purported no-checkout contract test masks the defect by manually copying the manifest into its temporary directory at `test/scripts/release_trigger_recovery_test.exs:82-84`.

**Fix:** Check out the triggering ref before the preflight, then make manifest parsing explicitly fail if it cannot produce one or more tag names. For example:

```yaml
- name: Checkout release configuration
  uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
  with:
    ref: ${{ github.sha }}
```

Then read the manifest with a normal command whose exit status is checked (or validate `expected_tags` is nonempty). Replace the hermetic fixture's manual manifest copy with a test that asserts the workflow has a checkout before the preflight and a negative execution test for a missing manifest.

### CR-02: GitHub API failures are treated as missing releases and permit release creation

**Classification:** BLOCKER

**File:** `.github/workflows/release-please.yml:74-103`
**Issue:** Any non-zero result from `gh release view` is recorded as a missing tag (lines 75-79), and `gh pr view` errors are discarded with `|| true` (line 95). A timeout, permission failure, rate limit, or GitHub outage therefore produces an all-missing tag set and empty labels, after which the preflight emits `should_run=true` (line 103). This is fail-open automation: it invokes release-please precisely when the checks that establish current release state could not be performed.

**Fix:** Distinguish an authenticated, authoritative not-found response from all other `gh` failures, and exit non-zero for the latter. A simpler robust approach is to fetch/validate the required release and PR data with `gh api`, preserving stderr/status, and only classify a confirmed 404 as absent. Add hermetic cases for API/authorization failure that assert the preflight exits non-zero and never writes `should_run=true`.

---

_Reviewed: 2026-07-31T21:33:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
