---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 03
subsystem: documentation
tags: [readme, package-compatibility, manifests, docs-contract]
requires:
  - phase: 164-01
    provides: settled repository-truth closeout context
provides:
  - README compatibility sections bounded to the published core, admin, and inbound package lines
  - Manifest-derived docs-contract coverage for all current package constraints
affects: [adopter-documentation, package-releases, docs-contract]
tech-stack:
  added: []
  patterns: [read package @version values directly in documentation contract tests]
key-files:
  created: [.planning/phases/164-repository-truth-reconciliation-and-closeout/164-03-SUMMARY.md]
  modified: [README.md, mailglass_admin/README.md, mailglass_inbound/README.md, test/mailglass/docs_contract_test.exs]
key-decisions:
  - "Current compatibility guidance is scoped in each README and derives its expected major.minor values from package manifests."
  - "Historical and upgrade-bounded version evidence remains untouched."
metrics:
  duration: 3m
  completed_date: 2026-08-26
  tasks_completed: 1
  files_changed: 4
status: complete
---

# Phase 164 Plan 03: Manifest-derived package guidance Summary

Current core, admin, and inbound README compatibility guidance is now contract-checked against the three package manifests.

## Tasks Completed

1. **Derive current README compatibility claims from package manifests**
   - Added a RED/GREEN docs contract that parses each package `@version` directly from its `mix.exs` manifest.
   - Added scoped current-compatibility sections to the root, admin, and inbound READMEs.
   - Preserved manifests, Release Please state, publish summaries, and historical guidance unchanged.

## Verification

- `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors --no-deps-check` — passed (37 tests, 0 failures; 1 existing skipped test).
- `git diff --exit-code HEAD~2..HEAD -- mix.exs mailglass_admin/mix.exs mailglass_inbound/mix.exs .release-please-manifest.json release-please-config.json .planning/publish` — passed with no protected authority-file changes.

## TDD Gate Compliance

- RED: `93cfdf08` added the scoped manifest-derived contract; it failed because the README sections did not yet exist.
- GREEN: `d272e824` added the current compatibility sections and made the contract pass.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- Verified the three README files and `test/mailglass/docs_contract_test.exs` exist.
- Verified task commits `93cfdf08` and `d272e824` exist in git history.
