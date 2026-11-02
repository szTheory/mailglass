---
phase: 178-preview-authoring-and-milestone-review
plan: "29"
subsystem: preview-delivery
tags: [curl, demo-auth, cookie-jar, offline-test]

# Dependency graph
requires:
  - phase: "178-28"
    provides: "Cycle 04 exact-SHA preview failure record and consumed-attempt boundary"
provides:
  - "Login-first route probes with one private temporary cookie jar"
  - "Offline regression coverage for redirect URL capture and cookie reuse"
affects: [UIQ-08, phase-178-owner-review]

# Actuals (#2632)
actuals:
  tokens: 6277
  tasks: 3
  commits: 3
plan_head_before: 14f3db0c1790bca1b231846438799ca4145b1a9f
plan_head_after: 06b5ebc0a1af0eddf18946c76e991ff9dd796ed7

# Tech tracking
tech-stack:
  added: []
  patterns: ["Bootstrap the synthetic operator session first; reuse a mode-0600 curl cookie jar in the mode-0700 temporary probe directory"]

key-files:
  created:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-29-PLAN.md
    - .planning/phases/178-preview-authoring-and-milestone-review/178-29-SUMMARY.md
  modified:
    - scripts/check_phase178_candidate.sh
    - scripts/test_check_phase178_candidate.sh

key-decisions:
  - "Preserve the exact-SHA, required-CI, HTTP-200, final-URL, CSS, isolation, and teardown gates while fixing only cookie handling and route order."
  - "Leave UIQ-08 open; any future candidate preview requires a fresh Cycle 05 exact-SHA approval for at most one local attempt."

requirements-completed: []
requirements-open: [UIQ-08]

# Coverage metadata
coverage:
  - id: D1
    description: "The login redirect and subsequent default routes share an ephemeral cookie jar while retaining the final HTTP status and effective URL."
    verification:
      - kind: unit
        ref: "bash scripts/test_check_phase178_candidate.sh#route-probe-cookie-jar-reuse"
        status: pass
      - kind: other
        ref: "bash -n scripts/check_phase178_candidate.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "The exact candidate preview passes its protected routes and page-marker checks after a fresh approval."
    requirement: "UIQ-08"
    verification: []
    human_judgment: true
    rationale: "Plan 29 is local-only and does not consume another preview attempt; a Cycle 05 approval and one future preview run are still required."

# Metrics
duration: 8m
completed: 2026-11-02
status: complete
---

# Phase 178 Plan 29: Cookie-Persistent Preview Route Probes Summary

**Demo login now seeds one private curl cookie jar before exact-SHA route probes, with offline coverage for the redirect and later session reuse.**

## Performance

- **Duration:** 8m
- **Started:** approximately 2026-11-02T05:08Z (executor timer was not captured)
- **Completed:** 2026-11-02T05:16Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Moved the documented `/demo/login?return_to=...` bootstrap to the first default route.
- Created a mode-0600 cookie jar inside a mode-0700 `PROBE_DIR`; every route probe passes the same file to curl's `--cookie` and `--cookie-jar` options. The temporary directory is removed on normal completion and on early exit.
- Kept redirect following, the three bounded HTTP attempts, final status/effective-URL capture, exact HTTP 200 acceptance, CSS comparison, required-CI lookup, preview isolation, and teardown behavior.
- Added a stub-curl regression case that writes a synthetic login cookie, checks the same-origin `/ops/mail?tenant_id=northstar` redirect result, and requires that cookie for all following default-route probes.
- Kept the browser candidate at `8e501960bc975ed44b632ba5c74522e0c5d66f8c`. No candidate source or hosted receipt was changed.
- Recorded the script hashes for the next exact-SHA checkpoint: launcher `e0ce9e159b69f7ee6289c040a6612520c18a70e8cc24ae2d0553535fae324d93`, self-test `f549821d13f0eb39d11f81fae45d86d3b6cc2a82041bc8e90d23975722563dd5`.

## Task Commits

1. **Task 1: Use one private cookie jar for route probes** — `5b184f15` (`fix`)
2. **Task 2: Add offline redirect-cookie coverage** — `76b7b25d` (`test`)
3. **Shared-jar path and permission assertions** — `06b5ebc0` (`fix`, follow-up hardening)

Plan and summary artifacts are committed separately as the plan metadata commit recorded in the execution report.

## Files Created/Modified

- `.planning/phases/178-preview-authoring-and-milestone-review/178-29-PLAN.md` — Plan 29 execution contract.
- `.planning/phases/178-preview-authoring-and-milestone-review/178-29-SUMMARY.md` — Local results, review, and the next approval boundary.
- `scripts/check_phase178_candidate.sh` — Login-first route probing with one private, ephemeral cookie jar.
- `scripts/test_check_phase178_candidate.sh` — Offline contract test using a stub curl command.

## Verification

- `bash -n scripts/check_phase178_candidate.sh` — passed.
- `bash -n scripts/test_check_phase178_candidate.sh` — passed.
- `bash scripts/test_check_phase178_candidate.sh` — passed all 12 checks, including `route-probe-cookie-jar-reuse`.
- The offline suite's curl stub proved jar reuse, 0600 jar mode, 0700 probe-directory mode, redirect following, final HTTP 200, and the expected same-origin effective URL. Docker and GitHub commands remained stubbed; no candidate preview was launched.
- Candidate commit `8e501960bc975ed44b632ba5c74522e0c5d66f8c` still resolves to the recorded SHA. The root executor's read-only check at 2026-11-02 05:14 UTC confirmed PR #317 remained open and draft, the target/main refs still matched Cycle 04, required checks were completed/success, and the Cycle 04 cost-disposition hash was unchanged.

## Independent Review

The independent read-only review found no blockers. It confirmed the login-first order, shared mode-0600 jar, temporary cleanup, unchanged HTTP 200/final-URL/CSS/CI/teardown gates, and useful offline coverage without new dependencies.

## Decisions Made

- Cycle 04's single preview attempt remains consumed after the login route returned HTTP 302. Its record says one attempt and `retry_or_relaunch: false`; Plan 29 did not make another candidate-bound preview invocation.
- UIQ-08 remains open. Before any future preview run, prepare a fresh Cycle 05 exact-SHA checkpoint that authorizes at most one local launcher attempt for candidate `8e501960bc975ed44b632ba5c74522e0c5d66f8c`.

## Deviations from Plan

None. The early-exit cleanup ensures the newly added synthetic cookie is removed with the temporary probe directory.

## Issues Encountered

The sandbox initially denied Git's `.git/index.lock` write. The scoped commits succeeded through the authorized Git operation after confirming only the assigned file paths were staged.

## Next Phase Readiness

Plan 29's local fix and offline evidence are complete. UIQ-08 is still open. The fresh, exact-SHA one-attempt Cycle 05 preview checkpoint is prepared in [178-29-APPROVAL.md](178-29-APPROVAL.md) and [178-RECOVERY-CYCLE-05.json](178-RECOVERY-CYCLE-05.json); direct user approval is required before launching it.

## Self-Check: PASSED

The launcher and self-test exist, all three task commits resolve in history, and the exact candidate SHA remains available and unchanged.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-11-02*
