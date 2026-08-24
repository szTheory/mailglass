---
phase: 162-protected-release-and-scheduled-control-recovery
reviewed: 2026-08-24T19:55:51Z
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
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 162: Code Review Report

**Reviewed:** 2026-08-24T19:55:51Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

The release workflow correctly binds the candidate identity to policy and the exact PR head, but its claimed protected dispatch boundary is not actually protected from users who can manually run repository workflows. The hygiene task also has an unhandled malformed-response path that prevents its promised `cannot-check` result and evidence artifact.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Any workflow dispatcher can spend the maintainer PAT to merge and release an authorized candidate

**File:** `.github/workflows/release-please.yml:171-289`
**Issue:** `workflow_dispatch` accepts the candidate digest as its only release authority. That digest is not secret: it is read from the protected repository ledger and is also emitted into workflow artifacts/results. The job has no protected `environment`, actor/organization allowlist, or separate approval gate, yet it exposes `RELEASE_PLEASE_PAT` and executes `gh pr merge --admin` at lines 258-266 before creating releases at lines 279-294. Consequently, any collaborator permitted to dispatch workflows can supply the current authorized digest and cause the maintainer PAT to bypass branch protection and publish the release. The existing exact-head/digest checks prove integrity of the candidate, not authorization of the person initiating the privileged action.

**Fix:** Put the merge/release portion in a job protected by an environment with required release-maintainer reviewers, and scope `RELEASE_PLEASE_PAT` to that job only. For example:

```yaml
  protected-release:
    needs: validate-protected-dispatch
    environment: protected-release
    permissions:
      contents: write
      pull-requests: write
    # Place gh pr merge and release-please here; keep validation in a
    # token-minimal job and pass only validated outputs forward.
```

Alternatively, enforce an explicit actor/team authorization check before any PAT-backed step, but an environment approval is the durable GitHub-enforced control.

## Warnings

### WR-01: A successful but malformed `gh pr list` response crashes the hygiene task instead of reporting `cannot-check`

**File:** `dev/mix/tasks/mailglass.repo.hygiene.ex:290-304`
**Issue:** `pull_requests/1` calls `Jason.decode!/1` whenever `gh` exits zero. A proxy, GitHub CLI regression, or an unexpected successful non-JSON response raises, aborting the Mix task, and prevents `repo-hygiene.json` from being produced. The workflow then cannot summarize or upload its diagnostic artifact. This differs from `ci_state/1`, which treats malformed JSON as `cannot-check`; the tests only cover that safer CI path.

**Fix:** Decode defensively and preserve the raw response only as diagnostics:

```elixir
case Jason.decode(json) do
  {:ok, prs} when is_list(prs) ->
    check(:pull_requests, if(Enum.empty?(prs), do: :pass, else: :blocked), pr_message(prs),
      %{open_count: length(prs), prs: prs})

  _ ->
    cannot_check(:pull_requests, "Open PR state returned a malformed response; inspect GitHub access and retry.", %{})
end
```

Add malformed and non-list `gh pr list` fixtures to `mailglass.repo.hygiene_test.exs` and assert that both the JSON result and workflow artifact remain available.

---

_Reviewed: 2026-08-24T19:55:51Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
