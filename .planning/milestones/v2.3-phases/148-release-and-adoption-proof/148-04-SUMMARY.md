---
phase: 148-release-and-adoption-proof
plan: 04
subsystem: release-automation
tags: [release-please, hex, ci, concurrency, branch-protection]
provides:
  - Protected linked core/admin 2.4.0 release with inbound excluded
  - Exact release-target validation and non-deadlocking release fan-out
affects: [148-05, release-ceremony, post-publish-smoke]
key-files:
  created:
    - .planning/phases/148-release-and-adoption-proof/148-04-SUMMARY.md
  modified:
    - .planning/release-target.json
    - .github/workflows/release-please.yml
    - .github/workflows/publish-hex.yml
status: complete
completed: 2026-08-02
---

# Phase 148 Plan 04: Protected Release Summary

Released `mailglass` and `mailglass_admin` 2.4.0 through the protected,
tag-bound automation path. `mailglass_inbound` remained at 2.1.1 and its
publish job was skipped.

## Delivered

- Exact release target validation for core/admin 2.4.0 with inbound fixed at
  2.1.1.
- Release Please PR [#169](https://github.com/szTheory/mailglass/pull/169)
  auto-merged at `80986b95a2c98d4be12859eb69af5b6b9b3e6762`.
- GitHub releases created for
  [core](https://github.com/szTheory/mailglass/releases/tag/mailglass-v2.4.0)
  and [admin](https://github.com/szTheory/mailglass/releases/tag/mailglass_admin-v2.4.0).
- Protected publish runs
  [30727822863](https://github.com/szTheory/mailglass/actions/runs/30727822863)
  and [30727823211](https://github.com/szTheory/mailglass/actions/runs/30727823211)
  passed tag validation, exact-SHA CI, dual-schema checks, package preflight,
  branch-protection verification, and the protected `hex-publish` environment.
- `publish-core` and `publish-admin` succeeded; `publish-inbound` was skipped.

## Autonomous Repairs

- Made the missing-`gh` fixture portable in PR
  [#167](https://github.com/szTheory/mailglass/pull/167).
- Promoted Mix Task Tests into the CI/release truth set and corrected summary
  isolation in PR [#168](https://github.com/szTheory/mailglass/pull/168).
- Synchronized inbound compatibility evidence without bumping inbound in PR
  [#178](https://github.com/szTheory/mailglass/pull/178).
- Fixed the publish/smoke concurrency deadlock in PR
  [#180](https://github.com/szTheory/mailglass/pull/180).
- Configured the encrypted branch-protection verification credential and
  reran the gate; no release override was used.

## Verification

- Protected core/admin release-event publish workflows: success.
- Core/admin GitHub releases: public, non-draft, non-prerelease.
- Inbound 2.4.0 GitHub release/tag: absent.
- Sanitized artifact: `phase-148-release-proof-30727823211`.

## Scope

Machine gates authorized publication. No human UAT was required, no local
`mix hex.publish` was used, and no Crosswake surface was added.
