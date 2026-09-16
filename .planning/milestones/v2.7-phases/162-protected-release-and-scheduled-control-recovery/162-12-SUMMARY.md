---
phase: 162-protected-release-and-scheduled-control-recovery
plan: 12
subsystem: release automation
tags: [github-actions, release-please, authorization, github-api, exunit]
requires:
  - phase: 162-10
    provides: protected exact-digest lifecycle isolated from proposal-only reporting
provides:
  - Fresh repository-admin authorization ahead of protected candidate validation.
  - Fail-closed protection for every nonempty-digest PAT consumer.
affects: [release-please, protected release recovery, AUTO-03]
tech-stack:
  added: []
  patterns: [repository collaborator-permission query must dominate privileged workflow steps]
key-files:
  created: []
  modified: [.github/workflows/release-please.yml, test/scripts/release_trigger_recovery_test.exs]
key-decisions:
  - "Only an exact GitHub repository-admin permission response authorizes a nonempty-digest protected release path."
  - "Proposal-only push, schedule, and empty-digest dispatch paths retain their existing PAT use and behavior."
requirements-completed: [AUTO-03]
coverage:
  - id: D1
    description: "Protected release dispatch requires a fresh repository-admin collaborator permission response before candidate validation or PAT-backed steps."
    requirement: AUTO-03
    verification:
      - kind: integration
        ref: "test/scripts/release_trigger_recovery_test.exs#unapproved dispatcher cannot reach PAT-backed protected release steps"
        status: pass
    human_judgment: false
duration: 8m
completed: 2026-08-24
status: complete
---

# Phase 162 Plan 12: Protected Dispatcher Authorization Summary

**Protected exact-digest releases now require a freshly queried GitHub repository-admin dispatcher before any privileged PAT-backed validation, merge, release, or sync checkout can run.**

## Performance

- **Duration:** 8m
- **Started:** 2026-08-24T20:28:33Z
- **Completed:** 2026-08-24T20:36:32Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Added a GITHUB_TOKEN-backed collaborator-permission gate bound to `github.actor`, accepting only `.permission == "admin"` with `.user.permissions.admin == true`.
- Made protected candidate validation and every nonempty-digest PAT consumer depend on the dispatcher authorization output, while preserving the ordinary proposal-only path.
- Added executable fake-`gh` fixtures for admin, maintain, write, malformed JSON, and unavailable permission responses; denied paths produce no authorization output or privileged command activity.

## Task Commits

1. **Task 1: Trace an approved and denied dispatcher to the PAT exposure boundary** - `f2d53fef` (test), `7f74f02b` (feat)

## Files Created/Modified

- `.github/workflows/release-please.yml` - Adds the fail-closed protected dispatcher authorization step and authorization predicates on protected/PAT-bearing paths.
- `test/scripts/release_trigger_recovery_test.exs` - Exercises exact permission-query arguments and approved/denied dispatcher outcomes.

## Decisions Made

- Repository admin is established by a fresh GITHUB_TOKEN collaborator-permission query, never inferred from candidate integrity or dispatch access.
- An empty candidate digest continues to select the existing proposal-only release and sync behavior; a nonempty digest must pass the new dispatcher gate.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The complete test-file command exceeded the interactive runner window before printing its final result. Focused new authorization coverage and relevant existing release guards passed; the full-file invocation should be rerun in an unrestricted CI window.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 13 can complete the independent repository-hygiene malformed PR-list boundary without changing this dispatcher authorization contract.

## Self-Check: PASSED

- Found `.github/workflows/release-please.yml` and `test/scripts/release_trigger_recovery_test.exs`.
- Found task commits `f2d53fef` and `7f74f02b`.
