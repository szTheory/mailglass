---
phase: 144-signal-drift-integrity
plan: 04
subsystem: release-integrity
tags: [github-actions, github-concurrency, hex, exunit, workflow-contract]
requires:
  - phase: 141-lane-truth-foundation
    provides: CI lane-contract test seam used for durable workflow assertions
provides:
  - One static, non-cancelling concurrency group shared by linked release workflows
  - Contract coverage for already-published Hex package no-op behavior
affects: [release-workflows, hex-publishing, post-publish-smoke]
tech-stack:
  added: []
  patterns: [anti-vacuous workflow source parsers, in-memory legacy-pattern negative controls]
key-files:
  created: [test/scripts/linked_release_concurrency_test.exs]
  modified: [.github/workflows/publish-hex.yml, .github/workflows/post-publish-smoke.yml]
key-decisions:
  - "Use mailglass-linked-release-fanout as a static repository-wide group across publish and smoke workflows."
  - "Already-published packages remain successful skip paths with explicit Nothing to do logging."
patterns-established:
  - "Workflow contract parsers assert that the expected block exists before applying semantic assertions."
requirements-completed: [TRUTH-08]
coverage:
  - id: D1
    description: "Publish and post-publish workflows serialize through the same static non-cancelling group."
    requirement: TRUTH-08
    verification:
      - kind: integration
        ref: "mix test test/scripts/linked_release_concurrency_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Core, admin, and inbound Hex releases preserve explicit successful already-published no-op behavior."
    requirement: TRUTH-08
    verification:
      - kind: integration
        ref: "mix verify.ci_lane_contract"
        status: pass
    human_judgment: false
metrics:
  duration: 6min
  completed: 2026-07-31
  status: complete
---

# Phase 144 Plan 04: Linked Release Fan-out Integrity Summary

**Linked publish and smoke workflows now share one static non-cancelling lock, with executable proof that all three Hex packages retain successful no-op retries.**

## Performance

- **Duration:** 6 min
- **Completed:** 2026-07-31T21:06:00Z
- **Tasks:** 1/1
- **Files modified:** 3

## Accomplishments

- Replaced both release/tag-derived workflow locks with the common `mailglass-linked-release-fanout` group while keeping cancellation disabled.
- Added anti-vacuous ExUnit workflow parsing that rejects the previous ref/tag-scoped patterns in memory.
- Preserved all three `mix hex.info` guards, skip outputs, publish conditions, and added explicit `Nothing to do` successful log text for already-published versions.

## Task Commits

1. **Task 1: Serialize the complete linked-release fan-out without losing no-op success** — `cf8875d9` (`feat`)

## Files Created/Modified

- `.github/workflows/publish-hex.yml` — static linked-release concurrency and explicit successful registry no-op logs.
- `.github/workflows/post-publish-smoke.yml` — matching static concurrency contract.
- `test/scripts/linked_release_concurrency_test.exs` — anti-vacuous parser, semantic checks, and legacy-pattern negative controls.

## Decisions Made

- Used `mailglass-linked-release-fanout` unchanged in both workflows; it never interpolates a ref, release tag, or dispatch input.
- Retained cancellation as `false`, so a running linked-release workflow is never cancelled by a later event.
- Did not assert FIFO queue ordering, which GitHub Actions does not guarantee beyond equal-group serialization.

## Verification

- `mix test test/scripts/linked_release_concurrency_test.exs --warnings-as-errors` — 3 tests, 0 failures.
- `mix verify.ci_lane_contract` — 129 tests, 0 failures.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The initial RED run failed against the old workflow groups as intended; the focused contract then passed after the bounded workflow change.

## User Setup Required

None - all verification is hermetic and no release, UAT, or external service action was performed.

## Next Phase Readiness

The linked-release signal is protected by the standard CI lane contract. No human verification remains.

## Self-Check: PASSED

- Found `test/scripts/linked_release_concurrency_test.exs` and both modified workflow files.
- Found task commit `cf8875d9` in git history.
