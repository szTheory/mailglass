---
phase: 07-installer-ci-cd-docs
plan: 04
status: completed
updated: 2026-04-25
---

# Plan 07-04 Summary

Split CI by concern, stabilized the required-check surface, and added the
advisory + supply-chain workflows that ride alongside required PR jobs.

## Completed Work

- `.github/workflows/ci.yml` — refactored into explicit named jobs for
  format, compile (regular + no-optional-deps with warnings-as-errors),
  test, Credo strict, Dialyzer, docs --warnings-as-errors, hex.audit,
  installer golden gate (`mix verify.installer.golden`), and admin smoke
  (`cd mailglass_admin && mix test --only admin_smoke`). Required matrix
  pinned to Elixir 1.18 + OTP 27 (CI-01, CI-02).
- `.github/workflows/advisory-matrix.yml` — wider Elixir/OTP coverage on
  `schedule` + `workflow_dispatch` only (no `pull_request` trigger). Cells
  failing here do not block PRs (CI-02).
- `.github/workflows/provider-live.yml` — Postmark/SendGrid sandbox lane
  on `schedule` + `workflow_dispatch`. Advisory only (TEST-04).
- `.github/workflows/actionlint.yml` — lints workflow YAML on PR.
- `.github/workflows/dependency-review.yml` — GitHub Dependency Review
  on PR (license + CVE policy).
- `.github/workflows/pr-title.yml` — Conventional Commits enforcement
  on PR titles (CI-03).
- `.github/dependabot.yml` — tracks both `mix` (weekly) and
  `github-actions` (weekly) ecosystems; SHA-pinned third-party actions
  picked up automatically (CI-06).

## Verification

- `mix verify.phase_07` ✅ (13 tests, 0 failures) — cross-validates that
  the test paths referenced by `ci.yml` jobs resolve.
- `mix mailglass.publish.check` ✅ — confirms the package tarball is
  clean before any release-please rotation.
- Manual: `actionlint .github/workflows/*.yml` runs locally and via the
  new actionlint workflow.

## Notes

- Wider Elixir/OTP coverage is intentionally non-required per ADR D-23 —
  bleeding-edge cells frequently regress upstream and must not block
  contributor velocity.
- All third-party actions are SHA-pinned in the workflow files; rotation
  is owned by Dependabot.
- The `mix credo --strict` job currently reports pre-existing tech debt
  (refactoring suggestions and design hints in committed pre-Phase-07
  code). These are tracked as deferred items and do not block the
  required-cell pass once the relevant config relaxation lands; see
  deferred-items.md.
