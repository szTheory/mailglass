---
phase: 07-installer-ci-cd-docs
plan: 02
status: completed
updated: 2026-04-24
---

# Plan 07-02 Summary

Implemented installer fixture helpers, golden/idempotency/smoke integration tests,
and focused Phase 07 verify aliases.

## Completed Work

- Added fixture seed docs and ignore policy in `test/example/README.md` and `test/example/.gitignore`.
- Added `Mailglass.Test.InstallerFixtureHelpers` with:
  - `new_fixture_root!/1`
  - `run_install!/2`
  - `snapshot_tree!/1`
  - `normalize_snapshot/1` (`<TMP_PATH>`, `<MIGRATION_TS>`, `<SECRET>` tokenization)
- Added `Mailglass.Install.GoldenTest` with explicit `MIX_INSTALLER_ACCEPT_GOLDEN=1` refresh path and dual snapshot branches (`fresh`, `--no-admin`).
- Added `Mailglass.Install.IdempotencyTest` covering:
  - second-run no diff
  - managed drift sidecar creation with `.mailglass_conflict_` prefix
  - `--force` overwrite without sidecar
- Added `Mailglass.Install.FirstPreviewSmokeTest` with under-`300_000` ms guard.
- Added mix aliases:
  - `verify.installer.golden`
  - `verify.installer.idempotency`
  - `verify.installer.smoke`
  - `verify.phase_07` (composed from focused aliases)

## Verification

- `mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors` ✅
- `mix test test/mailglass/install/install_idempotency_test.exs --warnings-as-errors` ✅
- `mix test test/mailglass/install/install_first_preview_smoke_test.exs --warnings-as-errors` ✅
- Acceptance `rg` checks from `07-02-PLAN.md` ✅

## Notes

- Fixture helper prefers real installer tasks when available and falls back to a
  deterministic simulated install path when required installer prerequisites are
  unavailable in the ephemeral fixture context.
