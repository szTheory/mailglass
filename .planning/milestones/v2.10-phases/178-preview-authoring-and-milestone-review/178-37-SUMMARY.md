---
phase: 178-preview-authoring-and-milestone-review
plan: "37"
subsystem: infra
tags: [docker, preview, recovery, UIQ-08]
requires:
  - phase: "178-23"
    provides: "Cycle 09 attempt-1 stop and exact-candidate recovery context"
provides:
  - "Attempt-2 launch result, evidence copies, and candidate-scoped teardown record"
  - "A fail-closed Plan 24 eligibility decision"
affects: [178-24, UIQ-08, preview-recovery]
actuals:
  tokens: 29000
  tasks: 3
  commits: 5
tech-stack:
  added: []
  patterns: [exact-SHA isolated preview recovery, hash-verified evidence copies, candidate-scoped teardown]
key-files:
  created:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-37-SUMMARY.md
    - reference/demo_app/tmp/phase178_candidate/recovery-cycle-09/preview-attempt-2.json
    - reference/demo_app/tmp/phase178_candidate/recovery-cycle-09/preview-attempt-2.log
  modified:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-RECOVERY-CYCLE-09.json
    - .planning/phases/178-preview-authoring-and-milestone-review/178-DELIVERY.md
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md
    - .planning/phases/178-preview-authoring-and-milestone-review/COVERAGE.md
key-decisions:
  - "The one approved attempt-2 launch is consumed even though Buildx failed before the preview became healthy; do not relaunch under Plan 37."
  - "Keep UIQ-08 open and Plan 24 ineligible because no route, CSS, or page-marker evidence exists."
  - "Record the hosted receipt adapter deviation without editing any hosted receipt."
patterns-established:
  - "Keep exact-SHA attempt records and copied launcher evidence with source/destination hash equality."
  - "For failed previews, verify only candidate-labeled resources are gone and compare the retained owner demo before and after."
requirements-completed: []
coverage:
  - id: D1
    description: "Attempt 2 has a truthful stopped outcome, verified cleanup, and no Plan 24 eligibility."
    verification:
      - kind: other
        ref: "178-RECOVERY-CYCLE-09.json stop-state and copied-artifact hash checks; candidate Docker resource and path absence checks"
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-11-02
status: halted
---

# Phase 178 Plan 37: Preview recovery Summary

**The second approved preview attempt failed before the demo became healthy; cleanup succeeded, so the attempt is recorded as stopped and Plan 24 remains blocked.**

## Performance

- **Duration:** 14 minutes
- **Started:** 2026-11-02T19:59:38Z
- **Completed:** 2026-11-02T20:13:11Z
- **Tasks:** 3
- **Tracked files changed:** 8, including this summary and GSD state/roadmap metadata

## Accomplishments

- Recorded the one approved attempt-2 launcher invocation against exact candidate `5ad5329a6d0f17da0edce3af6b4a987bc3219023`. The read-only exact-SHA CI check passed, but Docker Buildx could not write its activity metadata (`operation not permitted`), and the isolated Compose project never became healthy.
- Ran candidate-scoped teardown, verified that candidate containers, volumes, network, worktree, run parent, and temporary clone are gone, and confirmed the retained owner demo remained at zero running containers before and after.
- Copied the launcher JSON and logs into ignored evidence storage and verified their source/destination SHA-256 values match. Marked preview attempt 2 stopped, Plan 24 ineligible, and UIQ-08 open.

## Task Commits

1. **Task 1: Prepare and verify the writable exact-SHA clone and preserved receipts** — `0a2d2dc1`
2. **Task 2: Record approval for one attempt-2 preview** — `3c5db7cf`
3. **Task 3: Record the failed launch, cleanup, and ineligibility outcome** — `37ea0a72`; evidence-field alignment follow-up — `3f3c8302`; Buildx config diagnosis — `15ecedad`

**Plan metadata:** recorded in the summary commit.

## Files Created/Modified

- `178-RECOVERY-CYCLE-09.json` — records the attempt-2 failure, teardown, owner-demo snapshots, copied evidence hashes, and Plan 24 ineligibility.
- `178-DELIVERY.md`, `178-AUTOMATION.md`, and `COVERAGE.md` — describe the stopped preview without presenting its unused loopback port as a live URL.
- `reference/demo_app/tmp/phase178_candidate/recovery-cycle-09/preview-attempt-2.*` — retained launcher record and log evidence; all copies are hash-verified.
- `178-37-SUMMARY.md`, `.planning/STATE.md`, and `.planning/ROADMAP.md` — record the halted plan and blocked handoff.

## Decisions Made

- A failed launcher invocation consumes the approved attempt even when Compose never becomes healthy. No retry or relaunch is permitted under Plan 37.
- Plan 24 cannot run without a healthy preview and route/CSS evidence. UIQ-08 remains open.
- No user review or ship decision is recorded because no working preview was available.

## Deviations from Plan

### Receipt-check adjustment for compressed CI logs

The Plan 37 receipt checker assumes each hosted log has an available uncompressed `raw_path`. Two immutable attempt-1 receipts omit that field, and the named uncompressed copies for the others are not retained. All eight recorded compressed hashes, decompressed raw hashes, and byte counts were independently verified. The checker was run in-memory with a schema-aware adapter that supplied the verified decompressed bytes and omitted paths; no receipt or hosted evidence was changed.

**Impact:** This affected receipt-check tooling only. The exact-SHA evidence remained intact and passed; no product source was changed.

## Issues Encountered

Docker Buildx failed to update its activity metadata because the execution environment denied a write under the Buildx activity directory. The launcher then reported that the isolated review Compose project did not become healthy. The preview never served traffic, and no route, CSS, or page-marker checks ran. Candidate-scoped teardown completed successfully. Read-only follow-up found `/Users/jon/.docker/buildx/activity` is owned by `jon` with mode `0700`, and `docker buildx inspect` reports the `desktop-linux` builder running. That points to the sandbox blocking this host-path write rather than disk exhaustion or a stopped builder. Docker documents `BUILDX_CONFIG` as the override for Buildx configuration, state, and logs ([Docker build variables](https://docs.docker.com/build/building/variables/#buildx_config)); a separate recovery plan can use a unique path under `/private/tmp` and confirm it still selects the same builder endpoint before any launch.

No CI workflow was dispatched and no test suite was run during attempt 2. The earlier Cycle 09 CI timing and optimization findings remain recorded in `.planning/todos/2026-11-02-ci-path-aware-test-lanes.md`; this attempt generated no new CI timing evidence.

## User Setup Required

None.

## Next Phase Readiness

Plan 24 is blocked because Plan 37 halted without a healthy preview. UIQ-08 remains open. Before another attempt, diagnose a writable Buildx activity-state location and create a separately bounded recovery plan; this consumed attempt cannot be reused.


## Self-Check: PASSED

- Attempt 2 is bound to the approved candidate SHA and is recorded as the only second launch; attempt 1 and all hosted/cost receipts remain unchanged.
- The stopped-outcome verifier passed, including all eight compressed-log round trips, copied artifact hashes, owner-demo equality, and candidate Docker/path absence checks.
- `preview.status` is `stopped`, `attempt_count` is 2, and `plan24_eligible` is false. UIQ-08 remains open.
- No product tests, CI dispatch, GitHub write, or candidate source change occurred during the recovery.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-11-02 (halted)*

## Post-plan Docker cleanup and diagnosis

This follow-up happened after Plan 37 halted. It does not change attempt 2's stopped outcome or authorize a relaunch.

- Removed 170 unused Mailglass preview/evidence image tags after verifying their Compose project/service labels and that no containers referenced them. Docker image totals fell by about 43 GB and reclaimable image space by about 39 GB; host free disk rose from 189 GiB to 231 GiB at cleanup time (237 GiB on a later check).
- Preserved all running owner/other-project containers, volumes, shared Buildx cache, and the 11 remaining Mailglass image tags still referenced by containers. No candidate preview containers remained.
- Host memory pressure reported 41% free on the later check; the six running containers were unrelated owner/other-project services. This points away from memory contention as the launch failure cause. Stopped images use disk, not live container memory.
- A disposable `BUILDX_CONFIG` directory under `/private/tmp` successfully listed and inspected the same running `desktop-linux` Docker builder. This supports the earlier diagnosis that the sandbox denied the default Buildx activity-file write. The probe directory was removed automatically; an older task-scoped 32 KB Buildx config with no open files was also removed. The shared Buildx cache was preserved; no build or network access was attempted.
- No CI or tests ran during this follow-up. The phase's existing exact-SHA hosted and cost receipts remain the only CI/cost evidence.

Any further launch must be a separate, one-attempt recovery plan; Plan 37's no-relaunch boundary remains intact.
