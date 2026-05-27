# Phase 54 Green Main Evidence

Generated: 2026-05-27T06:18:00Z

## Local Verification

Passed:

- `actionlint .github/workflows/release-please.yml .github/workflows/publish-hex.yml .github/workflows/post-publish-smoke.yml .github/workflows/repo-hygiene.yml .github/workflows/ci.yml`
- `git diff --check`
- `mix compile --warnings-as-errors`
- `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors` - 8 tests, 0 failures.
- `GH_TOKEN="$(gh auth token)" GITHUB_REPOSITORY=szTheory/mailglass scripts/verify-branch-protection.sh main`

Branch protection result:

```text
OK: branch protection matches expected ruleset for szTheory/mailglass@main.
```

## PR #41 CI Evidence

PR: https://github.com/szTheory/mailglass/pull/41
Head SHA: `5f62410d9fe7fc6994ad916f90e4d72eb5c3725c`

Successful checks:

- `actionlint`
- `Conventional PR Title`
- `Format Check (Elixir 1.18 / OTP 27)`
- `Compile Warnings as Errors (Elixir 1.18 / OTP 27)`
- `Compile No Optional Deps (Elixir 1.18 / OTP 27)`
- `Support Contract Core (Elixir 1.18 / OTP 27)`
- `Mix Task Tests (Elixir 1.18 / OTP 27)`
- `Inbound Test (Elixir 1.18 / OTP 27)`
- `Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27)`
- `Credo Strict (Elixir 1.18 / OTP 27)`
- `Dialyzer (Elixir 1.18 / OTP 27)`
- `Docs Warnings as Errors (Elixir 1.18 / OTP 27)`
- `Hex Audit (Elixir 1.18 / OTP 27)`
- `Installer Golden Gate (Elixir 1.18 / OTP 27)`
- `Support Contract Admin (Elixir 1.18 / OTP 27)`
- `Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)`
- `Provider Compatibility Advisory (Elixir 1.18 / OTP 27)`

Failed check:

- `Core Full Suite Advisory (Elixir 1.18 / OTP 27)`
  - Run: https://github.com/szTheory/mailglass/actions/runs/26494042848
  - Job: https://github.com/szTheory/mailglass/actions/runs/26494042848/job/78017891451
  - Result: `mix test --warnings-as-errors` reported full-suite failures.

Local reproduction:

```text
mix test --warnings-as-errors
23 properties, 1120 tests, 51 failures, 7 skipped
```

Representative failures:

- Duplicate Credo test module names between `test/credo_checks/stream_policy_consistent_test.exs` and `test/mailglass/credo/stream_policy_consistent_test.exs`.
- Oban test setup failures: `Oban migrations have not been run. The oban_jobs table does not exist.`
- Follow-on sandbox owner failures: `{:badmatch, :already_shared}` in database-backed tests after earlier setup failures.

## Repo Hygiene JSON

Command:

```bash
GH_TOKEN="$(gh auth token)" GITHUB_REPOSITORY=szTheory/mailglass mix mailglass.repo.hygiene --check --format json
```

Result before advisory failure investigation:

```json
{
  "status": "blocked",
  "checks": [
    {"name": "git_state", "status": "pass"},
    {"name": "ci_state", "status": "blocked", "message": "No successful ci.yml run was found on this SHA."},
    {"name": "branch_protection", "status": "pass"},
    {"name": "pull_requests", "status": "blocked", "message": "1 open PR(s) require disposition before release."},
    {"name": "stale_branches", "status": "pass"},
    {"name": "release_workflows", "status": "pass"}
  ]
}
```

Current blocker:

Phase 54 cannot be marked complete yet. PR #41 should remain open until the advisory full-suite failure is fixed or explicitly accepted as non-blocking by project policy.

