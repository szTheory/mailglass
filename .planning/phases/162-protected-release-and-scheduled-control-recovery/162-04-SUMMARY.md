---
phase: 162-protected-release-and-scheduled-control-recovery
plan: 04
subsystem: protected post-publish recovery
tags: [github-actions, release-policy, post-publish, artifact, exunit]
requires:
  - phase: 162-01
    provides: authorized-but-unpublished release reconciliation evidence
provides:
  - blocked scheduled post-publish resolution artifact for unpublished targets
  - identical job-summary and artifact evidence before fail-closed exit
  - contract coverage preserving immutable target and publication safeguards
affects: [162-05, 164-repository-truth-reconciliation-and-closeout]
tech-stack:
  added: []
  patterns: [artifact-first blocked result, immutable completed-target proof]
key-files:
  created: []
  modified:
    - .github/workflows/post-publish-smoke.yml
    - test/mailglass/publish/post_publish_smoke_contract_test.exs
key-decisions:
  - "An authorized target with publication:not_started is a scheduled blocked outcome, never a fallback-target or release authority."
  - "The persisted resolution JSON is rendered unchanged in the Actions summary and retained before the expected non-success exit."
requirements-completed: [AUTO-05]
coverage:
  - id: D1
    description: "Scheduled authorized/not-started resolution emits a bounded blocked artifact before failing closed."
    requirement: AUTO-05
    verification:
      - kind: unit
        ref: test/mailglass/publish/post_publish_smoke_contract_test.exs
        status: pass
      - kind: unit
        ref: test/scripts/verify_published_release_test.exs
        status: pass
    human_judgment: false
metrics:
  duration: 4m
  completed: 2026-08-22
  tasks_completed: 1
  files_modified: 2
status: complete
---

# Phase 162 Plan 04: Scheduled Post-Publish Resolution Summary

**Scheduled post-publish recovery now records one blocked, identity-bearing result for an authorized-but-unpublished target before it fails closed, while exact completed targets retain their immutable proof path.**

## Accomplishments

- Added a scheduled-only recovery branch that recognizes the policy's authorized/not-started state, writes `post-publish-resolution.json`, and exits non-success without selecting another ref.
- Recorded status, reason, event/run provenance, ledger/publication lifecycle, exact candidate versions, and the intentionally empty target ref in the blocked result.
- Rendered and uploaded that same JSON with `if: always()` before the expected failure ends the resolver job.
- Kept protected dispatch identity comparisons, immutable workflow/target checkouts, completed-target tag/SHA/content-digest verification, release-event no-op behavior, and downstream smoke gates intact.

## Task Commits

1. **Task 1 RED: Report scheduled unpublished targets before failing closed** — `cb7d7c71`
2. **Task 1 GREEN: Report scheduled unpublished targets before failing closed** — `751e89a1`

## Verification

- `mix test test/mailglass/publish/post_publish_smoke_contract_test.exs test/scripts/verify_published_release_test.exs --seed 0` — passed, 16 tests.
- `mix format --check-formatted test/mailglass/publish/post_publish_smoke_contract_test.exs` — passed.
- `git diff --check` and `git show --check HEAD` — passed.

## Decisions Made

- Treat scheduled `authorized` plus `publication:not_started` as `blocked` with reason `scheduled_target_not_published`; it cannot become completed proof or substitute `main`.
- Keep the artifact narrow and workflow-local: it is written only for the applicable scheduled lifecycle and contains no authority-granting data.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test assertion] Corrected the RED contract's ordering assertion**
- **Found during:** Task 1 GREEN verification
- **Issue:** The initial generic ordering helper matched an unrelated earlier `exit 1` in the resolver.
- **Fix:** Asserted the specific blocked-resolution write, evidence log, and immediately following fail-closed exit.
- **Files modified:** `test/mailglass/publish/post_publish_smoke_contract_test.exs`
- **Commit:** `751e89a1`

## Known Stubs

None.

## Self-Check: PASSED

- Both modified implementation and contract files exist on disk.
- RED commit `cb7d7c71` and GREEN commit `751e89a1` exist in Git history.
- No release, package publication, tag mutation, dependency addition, permission broadening, or new trust surface was introduced.
