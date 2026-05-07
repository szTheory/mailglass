---
phase: 38-release-rehearsal-and-proof-artifacts
plan: 02
subsystem: release-rehearsal
tags: [release, install, upgrade, smoke, docs]
requires:
  - plan: 38-01
    provides: committed prepublish proof bundle and publish summary exports
provides:
  - canonical install smoke and first-send executable proof
  - strict upgrade rehearsal evidence
  - proof bundle highlights for install and upgrade flows
affects: [phase-38-plan-03, release-workflows, getting-started, upgrade-guide]
tech-stack:
  added: []
  patterns: [workflow-test-mirror, strict-upgrade-rehearsal]
key-files:
  created: [test/mailglass/install/install_first_send_smoke_test.exs, .planning/phases/38-release-rehearsal-and-proof-artifacts/38-02-REHEARSAL-EVIDENCE.md]
  modified: [.github/workflows/post-publish-smoke.yml, test/mailglass/install/install_first_preview_smoke_test.exs, guides/getting-started.md, guides/upgrading-to-v1_0.md, test/mailglass/docs_migration_smoke_test.exs, .planning/phases/38-release-rehearsal-and-proof-artifacts/38-01-PREPUBLISH-PROOF.md]
key-decisions:
  - "Kept the fast no-Ecto host as the canonical release-window smoke gate."
  - "Added the first-send lane as secondary executable proof instead of replacing the canonical smoke workflow."
patterns-established:
  - "Release-day workflow YAML and repo-local smoke tests mirror the same install contract."
requirements-completed: [RELS-01, RELS-02]
completed: 2026-05-06
---

# Phase 38 Plan 02 Summary

## Outcome

The canonical install smoke remains the fast no-Ecto published-package lane,
the guide-backed first-send path now has executable proof, and the `0.3.x ->
1.0` upgrade guide is locked to the strict migration/stability verification
path.

## Completed Work

- Kept `.github/workflows/post-publish-smoke.yml` aligned with the canonical
  fresh-host `phx.new --no-ecto --no-mailer --install` gate.
- Tightened `test/mailglass/install/install_first_preview_smoke_test.exs` to
  mirror that workflow contract exactly.
- Added `test/mailglass/install/install_first_send_smoke_test.exs` as the
  secondary executable proof for `guides/getting-started.md`.
- Updated `guides/getting-started.md` to keep the Ecto-backed first-send lane
  on the stable `v1.x` surface and compile with warnings-as-errors.
- Updated `guides/upgrading-to-v1_0.md` and
  `test/mailglass/docs_migration_smoke_test.exs` so the canonical upgrade path
  names `mix verify.docs.migration`, `mix verify.stability_contract`, and the
  `Mailglass.Message.new/2` warning posture explicitly.
- Added `.planning/phases/38-release-rehearsal-and-proof-artifacts/38-02-REHEARSAL-EVIDENCE.md`
  and folded its highlights into `38-01-PREPUBLISH-PROOF.md`.

## Verification

- `mix test test/mailglass/install/install_first_preview_smoke_test.exs test/mailglass/install/install_first_send_smoke_test.exs test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors`
- `actionlint .github/workflows/post-publish-smoke.yml`
- `mix verify.docs.migration`
- `mix verify.stability_contract`
- `mix docs --warnings-as-errors`
- `cd mailglass_admin && mix docs --warnings-as-errors`

## Deviations

- The deeper first-send proof stays repo-local and guide-backed instead of
  becoming the canonical release-window GitHub Actions gate.
