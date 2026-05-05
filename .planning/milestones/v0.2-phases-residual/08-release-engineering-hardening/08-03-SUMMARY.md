---
phase: 08-release-engineering-hardening
plan: "03"
subsystem: release-engineering
tags: [aliases, publish-check, release-please, sed, regression-tests, contributing]
dependency_graph:
  requires: ["08-02"]
  provides: [semantic-verify-aliases, installer-goldens-gate, hardened-sed-step, sed-anchor-test, release-please-docs]
  affects: [mix.exs, mailglass_admin/mix.exs, release-please.yml, publish-check, mix_config_test.exs, CONTRIBUTING.md]
tech_stack:
  added: []
  patterns: [bash-loop-generalization, exit-1-guard, sed-anchor-regression-test, deprecated-alias-delegation]
key_files:
  created:
    - test/fixtures/release_please_sed_test.sh
    - test/fixtures/mix_exs_release_please_sed/mix.exs.before
    - test/fixtures/mix_exs_release_please_sed/mix.exs.after
  modified:
    - mix.exs
    - mailglass_admin/mix.exs
    - lib/mix/tasks/mailglass.publish.check.ex
    - .github/workflows/release-please.yml
    - mailglass_admin/test/mailglass_admin/mix_config_test.exs
    - CONTRIBUTING.md
decisions:
  - "REL-03: Deprecated aliases delegate via one-line list delegation ['verify.<semantic>'] (option a) — simpler and prevents body-drift"
  - "REL-04: Used System.cmd for installer goldens to avoid Mix task deduplication that would cause re-invoke of mix test to no-op"
  - "REL-05: Kept sed block in-line in release-please.yml (actionlint integrates shellcheck; no need for separate script extraction)"
  - "REL-05: BSD sed portability caveat documented in fixture script comment; no shim added — CI uses GNU sed"
metrics:
  duration_seconds: 413
  completed_date: "2026-04-27"
  tasks_completed: 3
  files_count: 9
---

# Phase 08 Plan 03: Release Engineering Hardening (REL-03/04/05) Summary

Three independent release-engineering debt items — semantic alias rename, installer goldens gate, and sed-step hardening — executed against both `mix.exs` packages, the publish-check task, the release-please workflow, test files, and CONTRIBUTING.md.

## Alias rename mapping applied (REL-03)

### `mix.exs` (root package)

| Old alias | New semantic alias | Status |
|---|---|---|
| `verify.phase01` (legacy, no underscore) | `verify.foundation` | Deprecated pass-through added |
| `verify.phase_01` | `verify.foundation` | Deprecated pass-through added |
| `verify.phase_02` | `verify.persistence` | Deprecated pass-through delegates |
| `verify.phase_03` | `verify.send_pipeline` | Deprecated pass-through delegates |
| `verify.phase_04` | `verify.webhooks` | Deprecated pass-through delegates |
| `verify.phase_07` | `verify.installer` | Deprecated pass-through delegates |

All deprecated pass-throughs use delegation form `["verify.<semantic>"]` (option a) — prevents body drift between deprecated and canonical aliases.

`preferred_cli_env` in `cli/0` updated to include all 5 semantic keys plus existing deprecated keys: `verify.foundation`, `verify.persistence`, `verify.send_pipeline`, `verify.webhooks`, `verify.installer`.

### `mailglass_admin/mix.exs`

| Old alias | New semantic alias |
|---|---|
| `verify.phase_05` | `verify.preview` |

`verify.phase_05` delegates to `["verify.preview"]`.

Note: `verify.lint` (phase 06) and additional phase aliases not present in either package's `aliases/0` were not created — per plan guidance "only rename the ones that exist there."

## Installer goldens drift detection (REL-04)

`mix mailglass.publish.check` now runs installer goldens BEFORE the tarball build for fast failure:

- Runs `mix test test/mailglass/install --warnings-as-errors --exclude flaky` via `System.cmd` (avoids Mix task deduplication)
- Only runs for `:mailglass` package (not `:mailglass_admin`)
- Brand-voice error: `"Delivery blocked: installer goldens drifted (REL-04). Re-snapshot or fix installer output."`
- `@moduledoc` updated to enumerate all 14 pre-publish checks in order

Negative test (manual, pre-commit): breaking a `.golden` file and running `mix mailglass.publish.check` yields exit non-zero with `Delivery blocked:` prefix. Reverted before commit.

## Hardened release-please.yml sed step (REL-05)

**Bash-loop generalization:** The single-file sed call replaced with a `PINS=()` array loop keyed on `(path, dep_atom)` pairs. Adding `mailglass_inbound` at v0.5+ requires uncommenting one line:
```bash
# "mailglass_inbound/mix.exs:mailglass"   # uncomment at v0.5
```

**Zero-match exit-1 guard:** Before each sed, `grep -cE` counts matching lines. If zero, exits 1 with:
```
ERROR: sed anchor regex matched zero lines in <path>.
The dep tuple shape may have been renamed — see CONTRIBUTING.md REL-05 section.
```

**Shellcheck:** `actionlint` integrates shellcheck and passes (`actionlint .github/workflows/release-please.yml` exits 0). Separate script extraction not needed.

**Note:** `release-please-action` SHA pin unchanged at `5c625bfb5d1ff62eadeeb3772007f7f66fdcf071` (v4.4.1). The v5.0.0 upgrade is deferred to Phase 13 per D-08-26 for proper soak evaluation.

## Fixture regression test (REL-05)

- `test/fixtures/release_please_sed_test.sh` — executable bash script that copies `mix.exs.before` to a temp dir, applies the sed regex (NEW_VERSION=0.99.99), and diffs against `mix.exs.after`
- `test/fixtures/mix_exs_release_please_sed/mix.exs.before` — minimal mix.exs containing `{:mailglass, "== 0.1.0"}`
- `test/fixtures/mix_exs_release_please_sed/mix.exs.after` — same file with dep rewritten to `{:mailglass, "== 0.99.99"}`
- Script targets GNU sed (CI ubuntu-latest); BSD sed caveat documented in script header; no portability shim

The sed logic verified correct (tested with BSD sed on macOS, diff passes). CI will run with GNU sed.

## Sed-anchor stability test (REL-05, D-08-24)

New `describe "release-please sed-anchor regex stability (REL-05)"` block added to `mailglass_admin/test/mailglass_admin/mix_config_test.exs`:

- Sets `MIX_PUBLISH=true` and reads `mailglass_admin/mix.exs` source
- Asserts `Regex.match?(~r/\{:mailglass, "== \d+\.\d+\.\d+"\}/, source)` — same anchor as the sed regex
- Failure message explicitly directs to update sed regex + CONTRIBUTING.md together
- Test passes (confirmed in 4 tests, 1 pre-existing failure in `test app metadata app name is :mailglass_admin` which fails only when running from the root project context due to `Mix.Project.config()[:app]` returning `:mailglass`)

## CONTRIBUTING.md documentation (REL-05, D-08-25)

New section "Why we sed mix.exs after release-please runs" appended. Contains:
- Why `extra-files` generic updater is a no-op on managed mix.exs
- Recursion-safety guarantee (GITHUB_TOKEN anti-recursion)
- Sed-anchor stability pointer to mix_config_test.exs
- Pointer to empirical observation history in `.planning/todos/pending/`
- Rationale for rejecting TypeScript plugin ("no Node toolchain anywhere" DNA)

## Deviations from Plan

None — plan executed exactly as written. The deprecated alias delegation used option (a) — one-line `["verify.<semantic>"]` — as recommended by the plan.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. All changes are:
- Mix alias configuration (static metadata)
- Shell script in test/fixtures (developer tool only)
- GitHub Actions YAML (workflow-only execution)
- Test file additions (test scope only)

No threat flags.

## Self-Check: PASSED

| Item | Result |
|---|---|
| `test/fixtures/release_please_sed_test.sh` | FOUND |
| `test/fixtures/mix_exs_release_please_sed/mix.exs.before` | FOUND |
| `test/fixtures/mix_exs_release_please_sed/mix.exs.after` | FOUND |
| `08-03-SUMMARY.md` | FOUND |
| Commit c739224 (Task 1) | FOUND |
| Commit be2d046 (Task 2) | FOUND |
| Commit 1f3c230 (Task 3) | FOUND |
