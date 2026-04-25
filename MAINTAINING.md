# Maintaining Mailglass

This document covers the release flow and maintenance protocols for Mailglass.

## Release Flow

Mailglass uses [Release Please](https://github.com/googleapis/release-please) to automate versioning and changelogs.

1. Merge feature branches into `main` using Conventional Commits.
2. Release Please will open a "Release PR" with the version bump and updated `CHANGELOG.md`.
3. Merging the Release PR triggers the `publish-hex` workflow.
4. The `publish-hex` workflow is environment-gated and requires manual approval in the GitHub Actions UI.

## Snapshot Update Protocol

When the installer output or golden files change:

1. Run `mix verify.installer.golden`.
2. If the failure is expected, update the golden files in `test/fixtures/`.
3. Commit the updated fixtures with a `chore: update installer golden files` message.

## Required Checks

Before merging any PR, ensure:
- `mix compile --warnings-as-errors`
- `mix test --warnings-as-errors`
- `mix credo --strict`
- `mix dialyzer`
- `mix docs --warnings-as-errors`
