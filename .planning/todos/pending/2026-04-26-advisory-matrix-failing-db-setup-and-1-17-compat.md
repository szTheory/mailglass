---
created: 2026-04-26T18:20:00.000Z
title: Advisory Matrix workflow failing — missing DB setup + Elixir 1.17 compile incompatibility
area: ci
files:
  - .github/workflows/advisory-matrix.yml (test step missing ecto.create + 1.17 compile failure)
priority: v0.1.2
---

## Problem

`Advisory Matrix` workflow is RED on every push to main and every PR. Two distinct failures:

### Failure A — Elixir 1.18 / OTP 27 job

```
[error] Postgrex.Protocol failed to connect: ** (Postgrex.Error) FATAL 3D000
        (invalid_catalog_name) database "mailglass_test" does not exist
[error] Could not create schema migrations table.
** (DBConnection.ConnectionError) [Elixir.Mailglass.TestRepo] connection not available
##[error]Process completed with exit code 1.
```

`advisory-matrix.yml` runs `mix test --warnings-as-errors --exclude provider_live`
but the workflow never executes `mix ecto.create` (or `MIX_ENV=test mix ecto.setup`)
before tests. The Postgres service container is up, but the `mailglass_test`
database isn't created.

The main `ci.yml` workflow handles this correctly (CI is green on the same SHAs);
Advisory Matrix is missing the equivalent step. Likely an oversight from when the
matrix was added.

### Failure B — Elixir 1.17 / OTP 26 job

```
##[group]Run mix compile --warnings-as-errors
##[error]Process completed with exit code 1.
```

The compile step itself fails on Elixir 1.17. Likely 1.18-only syntax somewhere
in the codebase (set-theoretic types, `defp` features, or stdlib calls
introduced in 1.18). Need full log to identify the file.

## Why this matters

The "Advisory" name implies the matrix is informational, not blocking — and
publish-hex doesn't gate on it. But:

1. It's been red on **every push** for some unknown stretch of time. Notification
   noise + erodes trust in CI signals.
2. PR review sees "checks failed" and has to mentally filter "but it's just the
   advisory one." That's load.
3. If we **do** want to claim Elixir 1.17 / OTP 26 support, Failure B is a real
   bug that would block actual 1.17 adopters.

## Solution paths

### Path 1 — Drop Elixir 1.17 from the matrix; fix the DB setup

If we don't actually claim 1.17 support, removing that matrix row eliminates
Failure B entirely. Then add the missing DB setup steps for 1.18:

```yaml
- name: Create test database
  run: mix ecto.create
  env:
    MIX_ENV: test
- name: Run advisory tests
  run: mix test --warnings-as-errors --exclude provider_live
```

Net result: Advisory Matrix goes green and stays green.

### Path 2 — Keep 1.17 in the matrix; fix BOTH issues

Run advisory in continue-on-error mode for now, then:

1. Diagnose the 1.17 compile failure (`gh run view <id> --log` to get full output).
2. Either fix the codebase to support 1.17 OR adjust the matrix.
3. Add the DB setup step.

### Path 3 — Mark 1.17 as continue-on-error

Acknowledge it as advisory-only (the workflow's whole point) by adding
`continue-on-error: ${{ matrix.elixir == '1.17' }}` so the job runs but doesn't
fail the workflow. Still surfaces drift signals via the run logs.

## Recommendation

**Path 1** unless there's an explicit decision to support 1.17. The library
already declares `elixir: "~> 1.18"` in `mix.exs` (per `mailglass_admin/mix.exs:12`
and likely the same in core), so 1.17 isn't currently supported anyway. Dropping
the row matches reality.

## Acceptance criteria

- Advisory Matrix is green on main HEAD.
- The 1.18 job runs `mix ecto.create` (or equivalent) before `mix test`.
- If 1.17 is dropped: only the 1.18/OTP 27 row remains in the matrix.
- If 1.17 is kept: the codebase compiles cleanly under both 1.17 and 1.18.

## Verification

After the fix lands:

```sh
gh run list --repo szTheory/mailglass --workflow advisory-matrix.yml --limit 3 \
  --json conclusion --jq '.[].conclusion'
# Should show: ["success", "success", "success"] (or the recent green tail)
```

## Belt-and-suspenders

If we keep multiple Elixir versions in the matrix long-term, add a periodic
"matrix drift detector" (e.g. a weekly cron job) that opens an issue if the
matrix has been red for more than N consecutive runs. Same pattern as the
post-publish-smoke tracker, scoped to Advisory Matrix.
