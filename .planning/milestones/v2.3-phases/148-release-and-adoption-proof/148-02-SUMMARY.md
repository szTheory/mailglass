---
phase: 148-release-and-adoption-proof
plan: 02
subsystem: release-infrastructure
tags: [github-actions, release-please, hex, exunit]
requires:
  - phase: 148-01
    provides: protected core/admin release fan-out and release proof ledger
provides:
  - Manifest-diff-gated inbound release synchronization
  - Sanitized prepublish Phase 148 proof artifact
affects: [148-03, release-ceremony, published-consumer-proof]
tech-stack:
  added: []
  patterns: [fail-closed manifest ownership predicate, allowlisted release artifact, workflow contract tests]
key-files:
  created: []
  modified:
    - .github/workflows/release-please.yml
    - .github/workflows/publish-hex.yml
    - test/scripts/release_trigger_recovery_test.exs
    - test/scripts/linked_release_concurrency_test.exs
decisions:
  - Compare the release-branch inbound manifest version to origin/main and synchronize inbound-owned paths only on a real inbound version delta.
  - Persist only release ref/SHA, fixed package versions, command labels, and outcomes in the protected release proof artifact.
metrics:
  duration: 6m
  completed: 2026-08-01
  tasks_completed: 2
  files_modified: 4
status: complete
---

# Phase 148 Plan 02: Release PR Boundary and Protected Proof Summary

Release Please now keeps core/admin-only release PRs out of inbound-owned files, and the protected prepublish path uploads a credential-free artifact for the canonical release proofs.

## Tasks Completed

1. **Keep inbound-owned files out of a core/admin-only release PR** — `777d2b6d`
   - Added a fail-closed `INBOUND_CHANGED` predicate by comparing the release branch inbound manifest value with `origin/main`.
   - Kept core/admin README pin synchronization unconditional while gating inbound README, installation-guide, publish-summary, paths, and commit wording on a genuine inbound delta.
   - Added the Release Please workflow contract covering both release ownership paths.

2. **Upload sanitized protected prepublish evidence** — `349cb397`
   - Added the exact focused suppression/docs and package-local operator test commands to `prepublish-summary`.
   - Writes `tmp/release-proof/phase-148.json` with only ref, SHA, package versions, proof labels, and pass outcomes.
   - Uploads `phase-148-release-proof-${{ github.run_id }}` with the existing pinned action, error-on-missing behavior, and 90-day retention; no Hex credential binding is added to these steps.

## Verification

- `mix test test/scripts/release_trigger_recovery_test.exs test/scripts/linked_release_concurrency_test.exs --warnings-as-errors` — passed (17 tests, 0 failures).
- `actionlint .github/workflows/release-please.yml .github/workflows/publish-hex.yml` — passed.

## Decisions Made

- Inbound artifact updates are owned exclusively by a manifest delta for `mailglass_inbound`, never inferred from linked core/admin versions.
- The retained prepublish proof is allowlisted JSON rather than command output or an environment snapshot.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- All four modified workflow and contract-test files exist.
- Task commits `777d2b6d` and `349cb397` exist in the repository history.
