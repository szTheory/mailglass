---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 02
subsystem: documentation
tags: [release-policy, maintainer-guidance, protected-workflow, contracts]
requires: [164-01]
provides:
  - One authority-correct current release and recovery path for maintainers
  - An executable contract for protected authority and historical boundaries
affects: [MAINTAINING.md, protected-release-recovery]
tech-stack:
  added: []
  patterns: [documentation-as-contract, fail-closed-evidence, historical-boundary]
key-files:
  created: []
  modified:
    - MAINTAINING.md
    - test/mailglass/publish/maintaining_release_gate_contract_test.exs
decisions:
  - MAINTAINING.md now projects executable protected-release authority rather than granting its own authority.
  - Phase 38 and Phase 73 release procedures remain linked historical provenance, not a current alternative runbook.
metrics:
  duration: 3m
  completed_date: 2026-08-26
  tasks_completed: 1
  files_modified: 2
status: complete
---

# Phase 164 Plan 02: Authority-Correct Maintainer Release Guidance Summary

Maintainers now have one tested current protected release and recovery path that binds release authority to an exact candidate digest, repository-admin authorization, exact-run evidence, scheduled controls, and immutable post-publish validation.

## Tasks Completed

1. **Contract one current protected release and recovery path** — Added a RED/GREEN documentation contract, replaced stale hands-free release prose with a fail-closed current path, and marked the Phase 38/73 procedures as non-current historical provenance.

## Verification

- `mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs --warnings-as-errors --no-deps-check` — passed (2 tests).
- `mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --no-deps-check` — passed (37 executed, 1 existing skipped).
- `git diff -- .github/workflows scripts/release_policy.exs` — empty; no workflow or release-policy authority changed.

## Decisions Made

- Executable controls and identity-bound evidence remain authoritative; MAINTAINING.md explains, but does not broaden, their authority.
- Unavailable, malformed, pending, stale, wrong-SHA, or mismatched evidence is `cannot-check` or non-success.
- Historical Phase 38 and Phase 73 instructions remain discoverable but explicitly non-current, including their `~> 1.3` / `~> 1.0` smoke example.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- Both modified files exist and are represented by task commits `36c7c245` and `ef9c623a`.
- The focused and plan-level documentation contracts passed.
