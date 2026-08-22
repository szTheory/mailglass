---
phase: 162-protected-release-and-scheduled-control-recovery
plan: 07
subsystem: ci
tags: [github-actions, release-policy, post-publish, immutable-target, exunit]
requires:
  - phase: 162-05
    provides: Protected release reconciliation and exact immutable target contracts
provides:
  - One bounded post-publish resolution artifact for every supported trigger and resolver outcome
  - Executable workflow-shell fixtures for pass, blocked, cannot-check, and pending no-op paths
affects: [post-publish-smoke, release-recovery, phase-163]
tech-stack:
  added: []
  patterns: [artifact-first resolver outcomes, guarded EXIT fallback, extracted workflow-shell fixtures]
key-files:
  created: []
  modified:
    - .github/workflows/post-publish-smoke.yml
    - test/mailglass/publish/post_publish_smoke_contract_test.exs
key-decisions:
  - "Initialize schedule and protected-dispatch evidence as cannot-check before resolver work, then finalize only truthful pass or blocked outcomes."
  - "Keep release events successful pending no-ops with intentionally empty target identity and no downstream proof outputs."
requirements-completed: [AUTO-05]
coverage:
  - id: D1
    description: "Every supported post-publish trigger reaches mandatory upload with one bounded resolution artifact."
    requirement: AUTO-05
    verification:
      - kind: integration
        ref: test/mailglass/publish/post_publish_smoke_contract_test.exs#post-publish resolver paths materialize one bounded resolution before upload
        status: pass
    human_judgment: false
  - id: D2
    description: "Only the existing immutable target guard can serialize pass and emit downstream resolver outputs."
    requirement: AUTO-05
    verification:
      - kind: integration
        ref: test/mailglass/publish/post_publish_smoke_contract_test.exs#real resolver shell preserves pass blocked and cannot-check resolution semantics
        status: pass
    human_judgment: false
metrics:
  duration: 16m
  completed: 2026-08-22
status: complete
---

# Phase 162 Plan 07: Post-Publish Resolution Artifact Summary

**Post-publish recovery now serializes a single truthful pass, blocked, cannot-check, or pending artifact before the existing mandatory upload boundary.**

## Performance

- **Duration:** 16m
- **Started:** 2026-08-22T20:28:00Z
- **Completed:** 2026-08-22T20:44:48Z
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments

- Initialized supported schedule and protected-dispatch paths with a bounded cannot-check artifact, so setup or resolver failures can no longer omit required evidence.
- Finalized pass only after the existing exact version, identity, SHA/tag, digest, and target-guard checks; retained nonzero blocked and cannot-check behavior.
- Kept release events as successful pending no-ops with empty target fields, and added extracted-shell fixtures for every supported outcome.

## Task Commits

1. **Task 1: Execute every resolver outcome through one resolution artifact and upload boundary** — `d91958cf` (RED test), `e7f0e292` (GREEN implementation)

## Files Created/Modified

- `.github/workflows/post-publish-smoke.yml` — writes and finalizes the resolution schema before summary/upload.
- `test/mailglass/publish/post_publish_smoke_contract_test.exs` — executes classification and resolver bodies with isolated policy/guard shims.

## Decisions Made

- The classification step writes the initial artifact so failures before the resolver are still uploadable; the resolver atomically replaces it only with final truthful outcomes.
- A guarded EXIT handler records `cannot-check/resolver_failed` only when the resolver has not already finalized pass or blocked evidence.

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

- **RED:** `d91958cf` proved the missing release-event artifact path.
- **GREEN:** `e7f0e292` implemented artifact-first serialization and made the behavioral fixtures pass.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 162's AUTO-05 workflow contract is ready for re-verification. Phase 163 timeout repairs remain out of scope.

## Self-Check: PASSED

- Confirmed both modified files exist and the RED/GREEN commits are present in git history.
- Focused post-publish contract suite passed: 12 tests, 0 failures.

---
*Phase: 162-protected-release-and-scheduled-control-recovery*
*Completed: 2026-08-22*
