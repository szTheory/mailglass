---
phase: 13-v0-2-release-ceremony
plan: 02
subsystem: release-validation
tags: [upgrade, installer, smoke, fixtures, workflow]
requires: []
provides:
  - committed happy-path and ambiguous-case upgrade fixtures for v0.2
  - warning assertions that point adopters to the migration guide and escape hatch
  - a committed local smoke contract aligned with the release-day workflow shape
affects: [lib/mix/tasks/mailglass.upgrade.v0_2.ex, mix.exs, test/mailglass/upgrade/v0_2_test.exs, test/mailglass/install/install_first_preview_smoke_test.exs, .github/workflows/post-publish-smoke.yml]
tech-stack:
  added: []
  patterns: [fixture-backed codemod proofs, workflow-aligned preview smoke contract]
key-files:
  created:
    - .planning/phases/13-v0-2-release-ceremony/13-02-SUMMARY.md
    - test/fixtures/upgrade/v0_2_supported_before.ex
    - test/fixtures/upgrade/v0_2_supported_after.ex
    - test/fixtures/upgrade/v0_2_ambiguous_before.ex
    - test/fixtures/upgrade/v0_2_ambiguous_after.ex
  modified:
    - lib/mix/tasks/mailglass.upgrade.v0_2.ex
    - mix.exs
    - test/mailglass/upgrade/v0_2_test.exs
    - test/mailglass/install/install_first_preview_smoke_test.exs
    - .github/workflows/post-publish-smoke.yml
key-decisions:
  - "Used committed fixture files instead of inline strings so the happy-path and sentinel ambiguous case are durable release artifacts."
  - "Promoted Igniter from dev/test-only to a shipped non-runtime dependency because the public upgrade task must compile in consumer apps."
patterns-established:
  - "Ambiguous codemod warnings must point adopters to the migration guide and `Mailglass.Message.update_swoosh/2` explicitly."
requirements-completed: [REL-14]
completed: 2026-04-28
---

# Phase 13 Plan 02: Adopter walkthrough proofs for upgrade fixtures and smoke alignment

**Phase 13 now has committed happy-path and ambiguous-case codemod proofs, the public warning contract points at the migration guide, and the local smoke test explicitly mirrors the release-day install/compile/boot workflow shape.**

## Accomplishments
- Replaced inline codemod samples with committed upgrade fixtures covering the supported setter path and a sentinel ambiguous provider-option path.
- Updated the upgrade task so ambiguous warnings include the migration-guide URL and the `Mailglass.Message.update_swoosh/2` escape hatch.
- Fixed a release-blocking packaging issue by shipping `Igniter` as a non-runtime dependency; without that, consumer apps could not compile `mailglass` and therefore could not run `mix mailglass.upgrade.v0_2`.
- Tightened the local preview smoke seam so it asserts the installer output and the release workflow still advertise the same install -> compile -> boot -> `/dev/mail/` contract.

## Verification
- `mix test test/mailglass/upgrade/v0_2_test.exs test/mailglass/install/install_idempotency_test.exs test/mailglass/install/install_first_preview_smoke_test.exs`

## Deviations from Plan

### Auto-fixed Issues

**1. [Blocking] Shipped `Igniter` for consumer compilation**
- **Found during:** real generated-host smoke rehearsal
- **Issue:** `mailglass` exposed `Mix.Tasks.Mailglass.Upgrade.V0_2`, but `Igniter` was declared `only: [:dev, :test]`, so consumer apps failed to compile the dependency before they could run the upgrade task.
- **Fix:** Changed `{:igniter, "~> 0.7"}` to a shipped `runtime: false` dependency in `mix.exs`.
- **Impact:** Required for the public upgrade contract to be publishable and for release-day consumer smoke to be credible.

## Self-Check: PASSED
- Verified the focused Phase 13 test bundle passes with 10 tests, 0 failures, 2 skipped.
- Verified the release-day smoke workflow still contains the install, compile, and `/dev/mail/` preview checks the local proof depends on.
