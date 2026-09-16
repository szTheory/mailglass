---
phase: 164-repository-truth-reconciliation-and-closeout
reviewed: 2026-09-12T00:49:51Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - scripts/validate_repository_truth.exs
  - test/mailglass/docs_contract_test.exs
  - test/scripts/phase_164_closeout_test.exs
  - test/scripts/phase_164_repository_truth_test.exs
findings:
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
---

# Phase 164: Code Review Report

**Reviewed:** 2026-09-12T00:49:51Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

The new installed-authority reconciliation is not ready to ship. The explicit controlled-host alias passes all seven selected tests, but the repository-only scoped suite fails five tests because its so-called disposable production fixtures retain the real canonical checkout and therefore depend on live `HEAD == origin/main` state. On an exact-main checkout those same tests can proceed into the real pre-verification finalizer instead of exercising their fixture mutations.

The repository-truth validator also accepts tracked symlinks whose bytes live outside the repository and silently drops completed-plan file inventories when their YAML layout does not exactly match one regex. A separate malformed `--repo` path still escapes the CLI's controlled diagnostic contract with a stack trace. T-164-109 remains intentionally pending and is not classified as a defect here.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01 (BLOCKER): Tracked symlinks to mutable external files satisfy repository truth

**File:** `/Users/jon/projects/mailglass/scripts/validate_repository_truth.exs:786-800`

**Issue:** `ensure_tracked_subjects_exist/2` uses `File.regular?/1`, which follows symlinks, while `validate_staged_index_output/2` accepts any six-digit Git mode. A stage-0 symlink entry (`120000`) whose target is a regular file therefore passes as a tracked durable subject. This lets repository truth depend on mutable bytes outside Git. Replacing tracked `README.md` in a shared clone with a symlink to an external temporary file and staging it caused the public CLI to exit 0 with `repository truth ledger: valid`.

**Fix:** Use `File.lstat/1` and require `type: :regular`, and reject non-regular Git index modes before accepting the stage-0 record. For example:

```elixir
with {:ok, %File.Stat{type: :regular}} <- File.lstat(Path.join(repo_root, subject)),
     :ok <- tracked_subject_in_index(repo_root, subject) do
  :ok
else
  _ -> {:error, {:tracked_subject_not_regular, subject}}
end
```

In `validate_staged_index_output/2`, accept only the repository's allowed regular-file modes (for example `100644` and `100755`) and add an external-target symlink regression.

### CR-02 (BLOCKER): Repository-only loader attacks target the live canonical checkout and can dispatch the real finalizer

**File:** `/Users/jon/projects/mailglass/test/scripts/phase_164_closeout_test.exs:1717-1802`

**Issue:** The repository-only group calls `production_installed_fixture!/2`, which deliberately leaves `CANONICAL_REPOSITORY` set to `/Users/jon/projects/mailglass` (`:2670-2678`), and then invokes that copied loader with `164 --pre-verification` (`:2795-2810`). The fixture checkout and its deleted plans, moving HEAD, or hostile extension are consequently not the repository the loader authenticates. On the current clean `main` at `f845d785...` while `origin/main` is `52c07a50...`, all five tests failed on the unrelated real-checkout error `HEAD does not equal origin/main`; the scoped run finished with 136 tests, 5 failures, 1 skipped, and 11 excluded. On a clean exact-main checkout, the copied loader can instead authenticate and dispatch the actual canonical pre-verification scripts, causing network access and ignored evidence writes during a repository-only test. The accepted-error allowlist also lets feature-branch CI pass before any named fixture attack is reached.

**Fix:** Make each negative test authenticate a fully disposable repository and assert the specific mutation-induced rejection. Do not invoke the production `164 --pre-verification` path from the repository-only lane. Keep production-constant/installed-object assertions in the explicit controlled-host selection, or expose a side-effect-free validation seam for testing. Then require `mix verify.ci_lane_contract` to pass from both a feature checkout and a local `main` that is ahead of `origin/main`.

### CR-03 (BLOCKER): Malformed completed-plan metadata silently removes files from the required audit set

**File:** `/Users/jon/projects/mailglass/scripts/validate_repository_truth.exs:861-887`

**Issue:** `plan_files_modified/1` returns `[]` whenever its layout-sensitive regex does not match. It therefore treats malformed or merely reordered YAML exactly like an intentionally empty inventory. A completed plan containing `files_modified:`, a real path, an intervening frontmatter field, and then `autonomous:` was accepted by `audit_subjects/2`, but its declared path was absent from the returned subject set. An updated ledger can consequently omit that tracked file while the completeness comparison has no missing subject to report, violating the fail-closed exact-disposition contract. The new test helper correctly fails on an unparsable list, but production retains the silent fallback.

**Fix:** Parse frontmatter as YAML and return a tagged error when `files_modified` is missing, malformed, or not a list. Thread `{:error, {:invalid_plan_metadata, plan}}` through `phase_artifacts/1`, `audit_subjects/2`, and `main/1`; reserve an empty list only for an explicit `files_modified: []`. Add regressions for reordered keys, intervening keys, invalid scalar values, and missing metadata.

## Warnings

### WR-01 (WARNING): Existing non-Git `--repo` directories still crash the public validator

**File:** `/Users/jon/projects/mailglass/scripts/validate_repository_truth.exs:805-806,856-858`

**Issue:** `ensure_repository/1` accepts any directory, then `tracked_subjects/2` pattern-matches on a successful `git ls-files`. With a directory containing all six ignore authorities but no `.git`, the CLI exits 1 through an uncaught `MatchError` and prints a stack trace from line 857 instead of its bounded `repository truth ledger: ...` diagnostic and usage line. The recent incomplete-authority fix does not cover this neighboring public input boundary.

**Fix:** Verify repository identity with a non-raising Git command before enumeration, or return `{:ok, subjects} | {:error, reason}` from `tracked_subjects/2` and thread the error through `audit_subjects/2`. Add a CLI regression requiring one deterministic `invalid_repository` diagnostic and no exception trace.

---

_Reviewed: 2026-09-12T00:49:51Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
