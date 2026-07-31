---
phase: 144-signal-drift-integrity
reviewed: 2026-07-31T21:13:00Z
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
  critical: 1
  warning: 3
  info: 0
  total: 4
status: issues_found
---

# Phase 144: Code Review Report

**Reviewed:** 2026-07-31T21:13:00Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The branch-protection outcome seam correctly preserves non-clean outcomes as failures, and the focused contract suite passes (34 tests). However, the new release-recovery preflight invokes `gh` before the workflow checks out a repository and never supplies a repository explicitly. That breaks its tag/PR state detection in the scheduled and manual paths, defeating the idempotency/recovery behavior. The dynamic-icon gate and the contributor runbook also have material robustness/drift gaps.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Release-recovery preflight has no GitHub repository context

**File:** `.github/workflows/release-please.yml:42-44,71,91`
**Issue:** The preflight runs before any checkout and calls `gh release view` and `gh pr view` without `--repo` or `GH_REPO`. `GH_TOKEN` authenticates `gh`, but it does not select a repository; absent a checked-out git remote, these commands cannot resolve the target repository. Their errors are then interpreted as missing releases (`gh release view`) or intentionally discarded (`gh pr view ... || true`). Thus a scheduled/manual recovery can misclassify already-published tags as missing and rerun release-please, rather than safely no-op; an `autorelease: tagged` PR is also not reliably detected.

**Fix:** Bind the CLI to the workflow repository for the entire preflight (and add an equivalent fake-`gh` contract assertion):

```yaml
env:
  GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  GH_REPO: ${{ github.repository }}
  COMMIT_MESSAGE: ${{ github.event.head_commit.message }}
```

Alternatively pass `--repo "$GITHUB_REPOSITORY"` to each `gh release view` and `gh pr view` invocation.

## Warnings

### WR-01: Dynamic icon extraction only recognizes attributes on the opening-tag line

**File:** `mailglass_admin/scripts/check-conformance.sh:166-191`
**Issue:** The scan input is limited to lines matching `<.icon[[:space:]]+name={`. Valid multi-line HEEx is common (`<.icon` on one line and `name={...}` on the next), and is not parsed by this pattern. For a finite computed icon split across lines, the gate either misses the dynamic expression or reports the partial literal `hero-` as an unavailable icon. This turns a valid finite reference into a false failure and makes the advertised bounded-dynamic support formatting-dependent.

**Fix:** Parse icon components across lines (for example, collect each `<.icon ...>` tag through its closing `>` before extracting `name={...}`), then run the same finite-expression rules. Add a passing fixture with a multi-line finite expression and a vendored icon to lock the behavior.

### WR-02: The new icon contracts prove only rejection paths, not that a valid computed icon is accepted

**File:** `test/scripts/icon_exists_gate_test.exs:10-56`
**Issue:** Every dynamic fixture is deliberately invalid. The test suite consequently passes if the finite-expression parser rejects all computed icon forms, including valid ones; it does not test the intended success path. This is especially consequential because the parser is a handwritten shell recognizer rather than an Elixir/HEEx parser.

**Fix:** Add a fixture that uses a known vendored icon through each supported finite form (literal concatenation and interpolation) and assert a zero exit status. Include a multi-line attribute fixture if that syntax is supported.

### WR-03: Contributor instructions describe the old green/no-op behavior and wrong token identity

**File:** `CONTRIBUTING.md:143-145,187-202`
**Issue:** The runbook says the README-sync push uses `GITHUB_TOKEN`, while the workflow now checks out and pushes with `RELEASE_PLEASE_PAT` (`release-please.yml:126-137`) specifically to trigger CI. It also says the branch-protection workflow “no-ops and posts a notice” without `BRANCH_PROTECTION_PAT`, but the new reporter intentionally exits nonzero for `cannot_check` (`branch-protection-outcome.sh:77-89`). Following this documentation leads maintainers to expect green recovery behavior when automation is actually failing, and obscures the secret that governs the release synchronization path.

**Fix:** Update the wording to say the sync push uses `RELEASE_PLEASE_PAT` and triggers `pull_request: synchronize`; state that missing branch-protection credentials produce a visible failed `cannot_check` outcome, with the remediation steps already documented.

---

_Reviewed: 2026-07-31T21:13:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
