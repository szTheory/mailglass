# Contributing to Mailglass

We welcome contributions! Mailglass is developed using a phase-based roadmap found in [`.planning/PROJECT.md`](.planning/PROJECT.md).

## Local Setup

1. Clone the repo.
2. Install dependencies: `mix deps.get`.
3. Setup the test database: `mix ecto.setup` (or `mix ecto.create -r Mailglass.TestRepo`).
4. Run tests: `mix test`.

## Development Workflow

1. Create a branch.
2. Implement your changes and add tests.
3. Run the full verification suite: `mix verify.phase_07`.
4. Submit a PR.

## Commit Guidelines

Use Conventional Commits:
- `feat: ...` for new features
- `fix: ...` for bug fixes
- `docs: ...` for documentation changes
- `chore: ...` for maintenance

## PR Expectations

- All CI checks must pass.
- New features must include documentation and tests.
- Maintain atomic commits.

## Why we sed mix.exs after release-please runs

Release Please's `extra-files` generic updater silently no-ops on a `mix.exs`
already managed by the `elixir` release-type. The `{:mailglass, "== <ver>"}`
pin in `mailglass_admin/mix.exs` therefore never gets rewritten by the action
itself.

`.github/workflows/release-please.yml` syncs the pin via a `sed` step on the
release-please PR branch after the action runs. This is the **steady-state
mitigation** rather than authoring a TypeScript plugin (which would violate
the "no Node toolchain anywhere" engineering DNA) or refactoring to
`version.exs` (which adds Hex tarball + `Code.eval_file` load-order risk).

**Recursion-safety guarantee:** the sync push uses `GITHUB_TOKEN`, which by
GitHub's anti-recursion guarantee does NOT trigger further workflow runs.

**Sed-anchor stability:** `mailglass_admin/test/mailglass_admin/mix_config_test.exs`
asserts the dep tuple in `mailglass_admin/mix.exs` matches the literal
`{:mailglass, "== <semver>"}` shape the sed regex anchors on. Any future
rename of the dep tuple form will fail this test loudly — update the sed
regex (in `release-please.yml`) and this section together.

**Pointer:** see `.planning/todos/pending/2026-04-26-release-please-extra-files-no-op-on-managed-mix-exs.md`
for the empirical observation history.
