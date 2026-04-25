---
phase: 07-installer-ci-cd-docs
plan: 03
status: completed
updated: 2026-04-25
---

# Plan 07-03 Summary

Landed the docs spine: ExDoc-driven guides, governance files, and executable
docs contracts that keep the published docs synchronized with the live API.

## Completed Work

- ExDoc configuration in `mix.exs` (DOCS-01):
  - `main: "getting-started"`, complete `extras:` with grouped sections,
    stable `source_ref: "v#{@version}"`.
  - `skip_undefined_reference_warnings_on:` covers extras that reference
    project planning artifacts.
  - `skip_code_autolink_to:` neutralizes broken autolinks to external
    Swoosh/Ecto internals and intentionally hidden Mailglass modules so
    `mix docs --warnings-as-errors` stays green.
- Nine guides under `guides/` (DOCS-01..DOCS-04):
  - `getting-started.md`, `authoring-mailables.md`, `components.md`,
    `preview.md`, `webhooks.md`, `multi-tenancy.md`, `telemetry.md`,
    `testing.md`, `migration-from-swoosh.md`.
- Maintainer/governance files at repo root (DOCS-05):
  - `MAINTAINING.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`,
    `LICENSE`, `CHANGELOG.md`.
- Docs contract tests:
  - `test/mailglass/docs_contract_test.exs` — references in guides resolve
    to real mix tasks, config keys, and module surface.
  - `test/mailglass/docs_migration_smoke_test.exs` — raw-Swoosh-to-mailglass
    migration parity (DOCS-03).
  - `test/support/docs_helpers.ex` — shared helpers for both contracts.

## Verification

- `mix docs --warnings-as-errors` ✅ (0 warnings)
- `mix verify.docs.contract` ✅
- `mix verify.docs.migration` ✅
- `mix verify.phase_07` ✅ (13 tests, 0 failures across installer + docs)

## Notes

- The `skip_code_autolink_to:` list documents the intentional cross-refs to
  hidden modules (`Mailglass.Outbound.Worker`, `Mailglass.Application.start/2`,
  `Mailglass.TemplateEngine.HEEx.render/3`) and external dep internals
  (`Swoosh.Adapter.deliver/2`, `Swoosh.Mailer.deliver/1`,
  `Swoosh.Adapters.Sandbox.Storage`, `Ecto.Repo.rollback/1`). Each entry is
  prose-mention only; no link target exists in the local doc tree.
- `mix verify.phase_07` is collapsed to a single `mix test` invocation
  (covers `test/mailglass/install/`, `docs_contract_test.exs`,
  `docs_migration_smoke_test.exs`) — chaining the per-file aliases trips
  Mix's task-deduplication and only the first `mix test` call would run.
