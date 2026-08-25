---
phase: 162-protected-release-and-scheduled-control-recovery
plan: 02
subsystem: protected release workflow reporting
tags: [github-actions, release-please, release-policy, evidence, exunit]
requires:
  - phase: 162-01
    provides: protected-release reconciliation and retained proposal evidence
provides:
  - bounded proposal-only control result artifacts with trigger provenance
  - pass, blocked, cannot-check, and pending outcome reporting before non-pass exits
  - executable release-authority regression coverage
affects: [162-05, 164-repository-truth-reconciliation-and-closeout]
tech-stack:
  added: []
  patterns: [artifact-first non-pass reporting, proposal-only authority boundary, fake-gh workflow fixtures]
key-files:
  created: []
  modified:
    - .github/workflows/release-please.yml
    - test/scripts/release_trigger_recovery_test.exs
key-decisions:
  - "The proposal result JSON is the sole source for its summary and artifact, and is written before any non-pass exit."
  - "Ordinary release-please entries remain proposal-only; the existing exact candidate-digest protected dispatch remains the sole merge boundary."
metrics:
  duration: 9m
  completed: 2026-08-22
  tasks_completed: 1
  files_modified: 2
status: complete
---

# Phase 162 Plan 02: Proposal-Only Release Control Results Summary

**Release-please now records one bounded, inspectable proposal result for ordinary control and schedule paths before reporting a non-pass, without expanding any release authority.**

## Accomplishments

- Added pass, blocked, cannot-check, and pending proposal-result handling with separate event and run provenance.
- Made the workflow summary render the persisted JSON rather than recomputing its outcome, then uploads that JSON unconditionally.
- Added executable fixture coverage for successful capture, identity mismatch, and unavailable GitHub evidence, plus static guards for the protected authority chain.

## Task Commits

1. **Task 1 RED:** `897b79d5` — failing proposal-result contract coverage.
2. **Task 1 GREEN:** `424c9af7` — artifact-first proposal-only reporting implementation.
3. **Rule 1 formatting correction:** `3217eae0` — formatted the fixture after the formatter found a layout violation.

## Verification

- `mix test test/scripts/release_trigger_recovery_test.exs:310 --trace` — passed.
- `mix test test/scripts/release_trigger_recovery_test.exs test/scripts/release_policy_contract_test.exs --seed 0` — passed.
- `mix format --check-formatted test/scripts/release_trigger_recovery_test.exs` — passed.
- `git diff --check` — passed.

## Decisions Made

- Treat a missing proposal as an explicit blocked result and inaccessible capture evidence as cannot-check; neither can activate release authority.
- Preserve pending scheduled evidence when an applicable scheduled observation has not elapsed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Formatting] Formatted the new fixture helper**
- **Found during:** Task 1 verification
- **Issue:** `mix format --check-formatted` identified a formatting violation in the new temporary-result fixture.
- **Fix:** Applied the formatter’s required line wrapping and spacing.
- **Files modified:** `test/scripts/release_trigger_recovery_test.exs`
- **Commit:** `3217eae0`

**Total deviations:** 1 auto-fixed. **Impact:** Formatting only; no behavior changed.

## Known Stubs

None.

## Self-Check: PASSED

- Both implementation files exist and all three task commits are present.
- The focused proposal-result contract passes and no merge, tag, or release command was added outside the existing protected dispatch chain.
