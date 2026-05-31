---
phase: 59-ci-trust-lanes-checkpoint-evidence
reviewed: 2026-05-28T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - scripts/check_clean_baseline_hex_only.sh
  - test/scripts/required_checks_test.exs
  - .github/workflows/gate-self-test.yml
  - .github/workflows/ci.yml
  - scripts/setup_branch_protection.sh
findings:
  critical: 2
  warning: 3
  info: 1
  total: 6
status: issues_found
---

# Phase 59: Code Review Report

**Reviewed:** 2026-05-28
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Five files were reviewed covering the Phase 59 CI trust lane additions: a bash/Elixir script that validates `mix.lock` Hex-source purity, a gate-self-test workflow extended with a parameterized `check_name` input, an ExUnit test keeping `REQUIRED_CHECKS` and the print-expected heredoc in sync, the new `trust_lane_repo_head` CI job, and the updated `setup_branch_protection.sh`.

Two blockers were found: a shell-injection vulnerability in the inline Elixir script (the lockfile path argument is interpolated unsanitised into a double-quoted heredoc string) and the `actions/setup-node` action is not pinned to a commit SHA in direct violation of the project's mandatory SHA-pinning policy. Three warnings cover the `check_name` expression-injection surface in gate-self-test.yml, the fact that `check_clean_baseline_hex_only.sh` is never invoked from `ci.yml` (leaving the script as dead infrastructure), and a fragile string-split parser in the ExUnit sync test. One info item notes a missing `set -e` guard for the `elixir` subprocess exit code.

---

## Critical Issues

### CR-01: Shell injection via unquoted `LOCK_PATH` interpolation into Elixir heredoc

**File:** `scripts/check_clean_baseline_hex_only.sh:15`

**Issue:** `LOCK_PATH` is accepted from `$1` (caller-controlled) and then interpolated bare inside a double-quoted `elixir -e "..."` string. The shell expands `$LOCK_PATH` before passing the string to Elixir. A path containing shell metacharacters — e.g. `$(command)`, backticks, or a double-quote — breaks out of the Elixir string literal and executes arbitrary shell commands. Because `set -euo pipefail` is active, the injected string only needs to avoid triggering `pipefail` to succeed silently.

Concrete attack path (local developer machine, CI ephemeral): if a developer invokes the script with a CI-generated artifact path that is itself constructed from untrusted content (e.g. a Hex package name with a surprising character), the inline `elixir -e` shell fragment is exploitable.

Affected lines:
```
LOCK_PATH="${1:-mix.lock}"          # line 7 — unsanitised
...
elixir -e "
  lock = File.read!(\"$LOCK_PATH\") |> ...    # line 15 — interpolation
```

**Fix:** Write the lockfile path into a temporary variable that is passed to Elixir via an environment variable (never interpolated into the script string), or use a heredoc with process substitution so the path stays in the shell layer and is never embedded in the Elixir source text:

```bash
LOCK_PATH="${1:-mix.lock}"

MAILGLASS_LOCK_PATH="$LOCK_PATH" elixir -e '
  lock_path = System.fetch_env!("MAILGLASS_LOCK_PATH")
  lock = File.read!(lock_path) |> Code.eval_string() |> elem(0)

  required = [
    {"mailglass", :hex},
    {"mailglass_admin", :hex},
    {"mailglass_inbound", :hex}
  ]

  Enum.each(required, fn {name, expected_source} ->
    case Map.get(lock, String.to_atom(name)) do
      tuple when is_tuple(tuple) and elem(tuple, 0) == expected_source ->
        IO.puts("Hex-first OK: #{name} resolved via :hex (version: #{elem(tuple, 2)})")
      tuple when is_tuple(tuple) ->
        IO.puts(:stderr, "Hex-first violation: #{name} resolved via #{inspect(elem(tuple, 0))}, expected :hex")
        System.halt(1)
      nil ->
        IO.puts(:stderr, "Hex-first violation: #{name} missing from #{lock_path}")
        System.halt(1)
    end
  end)
'
```

Note: switching from `"` to `'` for the outer `-e` quoting also eliminates the entire interpolation class — shell metacharacters inside single quotes are never evaluated.

---

### CR-02: `actions/setup-node` not pinned to a commit SHA — violates mandatory project policy

**File:** `.github/workflows/ci.yml:641` and `.github/workflows/ci.yml:715`

**Issue:** Both `operator_browser_gate` and `preview_capture_advisory` jobs reference `actions/setup-node@v4`, a mutable floating tag. CLAUDE.md states: **"All third-party GitHub Actions MUST be pinned to commit SHA. Dependabot watches both mix.lock and .github/workflows/."** Every other action in ci.yml and gate-self-test.yml is pinned. This pair was presumably pre-existing but the Phase 59 diff adds jobs that run alongside these unpinned steps; shipping this phase without fixing the pre-existing violation leaves the repo inconsistent and continues to expose the supply chain risk.

**Fix:** Pin to the current v4 SHA (as of 2026-05 the canonical v4.1.0 SHA is `1d0c2531`; verify with `gh api /repos/actions/setup-node/git/refs/tags/v4.1.0`):

```yaml
# operator_browser_gate (line 641) and preview_capture_advisory (line 715)
uses: actions/setup-node@1d0c25312f3e4e4f7432e90dd91ef68d83a92e09  # v4.1.0
```

Replace both occurrences. The exact SHA should be verified against the current tag at merge time; the principle is that a floating `@v4` tag is a BLOCKER per project policy.

---

## Warnings

### WR-01: `check_name` workflow_dispatch input is interpolated into a `run:` shell script without quoting — expression injection risk

**File:** `.github/workflows/gate-self-test.yml:123`

**Issue:** The `check_name` input is used directly in a `--jq` filter string passed to `gh pr checks`:

```yaml
--jq '.[] | select(.name | startswith("${{ inputs.check_name }}")) | .state'
```

`inputs.check_name` is a free-text `workflow_dispatch` input. GitHub Actions evaluates `${{ ... }}` expressions and substitutes the raw string before the shell sees it. A value containing a single quote breaks out of the jq string literal; a value containing `')) | halt_error(//` would alter the jq program itself. While this input is restricted to users who have `workflow_dispatch` permission on the repo (typically maintainers), the CLAUDE.md convention treats injection surfaces as blockers regardless of who controls the input. The same value is also echo'd into the step summary (lines 127, 132, 138, 143, 166) — less critical since it is not evaluated, but still emits unsanitised content.

**Fix:** Move the check name into an environment variable and reference it from within the jq expression using `$ENV.CHECK_NAME`:

```yaml
- name: Poll for Tests check completion
  if: ${{ !inputs.cleanup_only }}
  id: poll
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    PR: ${{ steps.open-pr.outputs.pr }}
    BRANCH: ${{ steps.create-branch.outputs.branch }}
    CHECK_NAME: ${{ inputs.check_name }}
  run: |
    DEADLINE=$((SECONDS + 1500))
    while [ $SECONDS -lt $DEADLINE ]; do
      STATUS=$(gh pr checks "$PR" --required --json name,state \
        --jq '.[] | select(.name | startswith($ENV.CHECK_NAME)) | .state' \
        | head -1)
      case "$STATUS" in
        FAILURE|FAILED|CANCELLED|TIMED_OUT)
          echo "${CHECK_NAME} check returned ${STATUS} — gate is enforcing halt-on-failure"
          ...
```

This eliminates the expression-injection surface because `$ENV.CHECK_NAME` is resolved inside jq's own runtime rather than being substituted as raw text by the Actions expression engine.

---

### WR-02: `check_clean_baseline_hex_only.sh` is never invoked from `ci.yml` — new script is dead infrastructure

**File:** `scripts/check_clean_baseline_hex_only.sh` (whole file) / `.github/workflows/ci.yml` (trust_lane_repo_head job)

**Issue:** The script was introduced in Phase 59 as the Hex-source guard for `reference/host_app/mix.lock`, but there is no step in any CI workflow that calls it. The `trust_lane_repo_head` job in `ci.yml` runs `mix verify.reference_host.journey` and `bash scripts/check_trust_runner_checkpoint.sh` but never invokes `check_clean_baseline_hex_only.sh`. The script is also absent from the gate-self-test workflow. The planning artefacts (`59-VALIDATION.md`, the pending TODO) acknowledge this is a Wave-0 item deferred until after republish, but as shipped the script provides zero automated enforcement — the trust lane evidence it is meant to produce is never generated in CI.

**Fix:** Add a dedicated step in `trust_lane_repo_head` after the `Install deps` step (or as a separate job step following `Run reference-host trust journey`):

```yaml
- name: Validate reference-host Hex-source purity
  working-directory: reference/host_app
  run: bash ../../scripts/check_clean_baseline_hex_only.sh
```

The `reference/host_app/mix.lock` will already be present in the checkout at this point. This step should come *after* `mix deps.get` so the lockfile is current.

---

### WR-03: `parse_required_checks` parser silently returns wrong results if `REQUIRED_CHECKS=(` appears elsewhere in the script

**File:** `test/scripts/required_checks_test.exs:37-42`

**Issue:** `parse_required_checks/1` splits the script source on the literal string `"REQUIRED_CHECKS=(\n"`. This is a single-occurrence guard, not a structural parser. If anyone adds a comment containing `REQUIRED_CHECKS=(`, a function name, or a second array with that prefix (e.g. for a different package's setup script, or a test fixture), `String.split/3` with `parts: 2` will silently split at the wrong boundary and the test will either crash (from a failed pattern match on the 2-element list) or — worse — return an empty set and pass vacuously.

The same fragility applies to `parse_print_expected_bullets/1`'s split on `"cat <<'TEXT'\nExpected required status checks:\n"`.

**Fix:** Use a more defensive parser that validates exactly one match was found:

```elixir
defp parse_required_checks(source) do
  parts = String.split(source, "REQUIRED_CHECKS=(\n", parts: 2)
  assert length(parts) == 2,
    "parse_required_checks: could not find REQUIRED_CHECKS=( in #{@script_path}"
  [_before, rest] = parts
  [chunk | _] = String.split(rest, "\n)", parts: 2)

  Regex.scan(~r/"([^"]+)"/, chunk)
  |> Enum.map(fn [_full, name] -> name end)
  |> MapSet.new()
end
```

Alternatively, use `Regex.run` with a multiline capture group spanning the array body, which is both explicit and unambiguous. The assert inside a private function is acceptable here since it fires during test setup, not production.

---

## Info

### IN-01: `System.halt/1` exit is not propagated to the outer bash script — `set -euo pipefail` may not protect callers

**File:** `scripts/check_clean_baseline_hex_only.sh:29`

**Issue:** Inside the inline Elixir script, `System.halt(1)` terminates the BEAM with exit code 1. Because `set -euo pipefail` is active in the outer bash script and `elixir -e "..."` is the last command on its own line (not part of a pipeline), `set -e` will propagate a nonzero exit and abort the script correctly. This is fine for the normal exit path.

However, if the `elixir` binary itself fails to start (e.g., not found on PATH, OOM), the error is identical in form to a `System.halt(1)` from within the script. The script has no step that distinguishes "elixir not available" from "Hex-source violation." This is unlikely in CI (elixir is installed earlier in the job) but can mislead local users running the script outside the CI environment.

A brief note in the error output would help:

```bash
if ! command -v elixir &>/dev/null; then
  echo "check_clean_baseline_hex_only: 'elixir' not found on PATH" >&2
  exit 1
fi
```

Add this before line 14 (the `elixir -e` invocation).

---

_Reviewed: 2026-05-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
