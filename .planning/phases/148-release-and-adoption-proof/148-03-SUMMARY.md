---
phase: 148-release-and-adoption-proof
plan: 03
subsystem: release-evidence
tags: [release-proof, hex, exunit, actionlint, asvs]
requires:
  - phase: 148-01
    provides: protected core/admin release fan-out and proof ledger
  - phase: 148-02
    provides: linked release contract and sanitized protected proof artifact
provides:
  - Commit-bound local proof ledger with explicit release blockers
affects: [148-04, release-ceremony, published-consumer-proof]
tech-stack:
  added: []
  patterns: [bounded evidence ledger, fail-closed release gates, local-versus-published proof separation]
key-files:
  created:
    - .planning/phases/148-release-and-adoption-proof/148-03-SUMMARY.md
  modified:
    - .planning/phases/148-release-and-adoption-proof/148-RELEASE-PROOF.md
key-decisions:
  - Local path-mode evidence is never treated as published-package proof.
  - A dirty workspace, a version mismatch, or an unretained exit status remains a release blocker rather than being normalized to green.
metrics:
  duration: 8m
  completed: 2026-08-01
  tasks_completed: 2
  files_modified: 1
status: complete
---

# Phase 148 Plan 03: Pre-publication Evidence Summary

Captured bounded local release evidence while retaining every missing or red gate as an explicit blocker for the one-way release checkpoint.

## Tasks Completed

1. **Capture focused behavior and path-mode adoption evidence** — `f76db567`
   - Focused suppression/docs suite passed: 52 tests, 0 failures, 1 skipped.
   - Operator LiveView suite passed: 79 tests, 0 failures.
   - Recorded distinct unsubscribe, complaint, hard-bounce, B2C parse/package, live-refresh, and foreign-tenant rejection outcomes.
   - Recorded path-mode smoke as local-only and inconclusive because a final retained exit status was unavailable.

2. **Capture release-workflow and package preflight evidence** — `c1494cbf`
   - Linked-release, recovery, and post-publish workflow contracts passed: 21 tests, 0 failures.
   - Workflow syntax lint passed.
   - Recorded the core package allowlist failure, core/admin target-version mismatch, missing retained admin check exit, and red `mix ci` formatting gate.
   - Recorded `ASVS L1 unresolved high-severity findings: 3`.

## Verification

- `mix test test/mailglass/webhook/ingest_auto_suppress_test.exs test/mailglass/suppression_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors` — passed (52 tests, 0 failures, 1 skipped).
- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` — passed (79 tests, 0 failures).
- `mix test test/scripts/linked_release_concurrency_test.exs test/scripts/release_trigger_recovery_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs --warnings-as-errors` — passed (21 tests, 0 failures).
- `actionlint .github/workflows/publish-hex.yml .github/workflows/release-please.yml .github/workflows/post-publish-smoke.yml` — passed.
- `mix mailglass.publish.check --package mailglass` — blocked by the uncommitted B2C guide not yet in the core package allowlist.
- `mix ci` — blocked by pre-existing formatting failures in workflow-contract tests.

## Release Readiness

**No-go.** The ledger truthfully retains three high-severity unresolved findings: the local workspace is dirty rather than a clean commit-bound candidate, the release manifest is core/admin `2.3.0` rather than `2.4.0` and the core allowlist is red, and `mix ci` is red. Hex-mode proof remains pending; path-mode proof is not a substitute.

## Scope Boundaries

External B2C launch gates for Sigra, Chimeway, Parapet, Accrue, and host recovery remain separately recorded and excluded from this Mailglass release proof. No Crosswake surface or `crosswake_mailglass` package was added.

## Deviations from Plan

### Auto-fixed Issues

None.

### Evidence Constraints

1. **[Rule 3 - Blocking release evidence] Retained non-green preflight states**
   - **Found during:** Tasks 1 and 2
   - **Issue:** The candidate workspace contains user-owned uncommitted work; path/admin smoke exit statuses were not retained; package and CI gates are red; release versions are still 2.3.0.
   - **Resolution:** Recorded each state as inconclusive or blocked in the canonical ledger without modifying user-owned release content, formatting, manifest, or allowlist files.
   - **Files modified:** `.planning/phases/148-release-and-adoption-proof/148-RELEASE-PROOF.md`
   - **Commits:** `f76db567`, `c1494cbf`

**Total deviations:** 0 auto-fixed; 1 release-evidence constraint documented.

## Known Stubs

None.

## Self-Check: PASSED

- The canonical release-proof ledger and this summary exist on disk.
- Task commits `f76db567` and `c1494cbf` exist in repository history.
