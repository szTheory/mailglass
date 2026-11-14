---
phase: 178-preview-authoring-and-milestone-review
plan: "28"
subsystem: preview-delivery
tags: [github-actions, playwright, browser-evidence, cost-disposition]

# Dependency graph
requires:
  - phase: "178-27"
    provides: "Exact candidate with the native scroll-completion wait"
provides:
  - "Cycle 04 exact-SHA hosted workflow receipts and bounded stop record"
  - "Reproducible candidate-bound cost and count disposition"
  - "Truthful preview failure handoff, with UIQ-08 left open"
affects: [UIQ-06, UIQ-07, UIQ-08, phase-178-owner-review]

# Actuals (#2632)
actuals:
  tokens: 28866
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns: ["Derive cost from a stable hosted snapshot so the candidate-cycle record can later capture preview outcome without a circular hash"]
key-files:
  created:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-COST-DISPOSITION.json
    - .planning/phases/178-preview-authoring-and-milestone-review/178-DELIVERY.md
  modified:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-RECOVERY-CYCLE-04.json
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md
    - .planning/phases/178-preview-authoring-and-milestone-review/178-VERIFICATION.md
    - .planning/phases/178-preview-authoring-and-milestone-review/COVERAGE.md
    - .planning/debug/operator-inbound-scroll-178.md
key-decisions:
  - "Accept the D-12 placement disposition only for this preapproved owner-review cycle, retaining all measured overages, expected counts, and existing gates."
  - "Treat the one preview launch as consumed after its required login return route returned HTTP 302; do not retry or relaunch."
  - "Close UIQ-06/UIQ-07 from exact hosted and reproducible cost evidence; leave UIQ-08 open until a newly approved preview passes route and page-marker checks."
patterns-established:
  - "Keep immutable raw hosted logs and hash any deterministic parser-normalized derivative with its source provenance."
requirements-completed: [UIQ-06, UIQ-07]
requirements-open: [UIQ-08]

# Coverage metadata
coverage:
  - id: D1
    description: "Exact-SHA hosted fidelity and connected interaction evidence for Cycle 04"
    requirement: UIQ-06
    verification:
      - kind: integration
        ref: "https://github.com/szTheory/mailglass/actions/runs/41388571351; retained Operator and Demo artifacts listed in 178-RECOVERY-CYCLE-04.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "Candidate-bound cold/warm cost and count disposition with the supported D-12 placement rationale"
    requirement: UIQ-07
    verification:
      - kind: other
        ref: "178-COST-DISPOSITION.json; stable-snapshot and cost regenerations compared byte-identical over 45 hashes"
        status: pass
    human_judgment: false
  - id: D3
    description: "Owner-review preview on the exact candidate with all routes and page markers verified"
    requirement: UIQ-08
    verification:
      - kind: automated_ui
        ref: "reference/demo_app/tmp/phase178_candidate/candidate-8e501960.json; single launch failed because the /demo/login return route returned HTTP 302"
        status: fail
    human_judgment: true
    rationale: "No live preview remains for owner inspection; route/auth behavior must be classified and all route/page-marker gates must pass in a newly approved successor cycle."

# Metrics
plan_head_before: 4c42b169b98dcca09f8df2ce20f13f555aac8493
plan_head_after: 4a8d329a561abf7fa012cb9b14d9a95b05c9a1a4
commits: 3
duration: 63min
completed: 2026-11-02
status: complete
---

# Phase 178 Plan 28: Cycle 04 Hosted Pass and Preview Route Stop Summary

**Cycle 04 passed exact-SHA hosted checks and reproducible cost review, then stopped its single preview attempt when the login return route returned HTTP 302.**

## Performance

- **Duration:** 63 minutes (04:04:43–05:07:38 UTC)
- **Started:** 2026-11-02T04:04:43Z
- **Completed:** 2026-11-02T05:07:38Z
- **Tasks:** 3
- **Files modified:** 7 in the task evidence commit

## Accomplishments

- Verified the approved candidate `8e501960bc975ed44b632ba5c74522e0c5d66f8c`, pushed it once, updated only the draft PR #317 body once, and dispatched `ci.yml` once. Exactly eight workflow runs completed at attempt 1; every expected workflow and the required Phase 178 CI gates passed. No retry, rerun, cancellation, or extra dispatch occurred.
- Captured raw run/job/log/artifact evidence. Both candidate CI runs matched the expected Operator and Demo counts. The exact `workflow_dispatch` Demo artifact bound the cost pilot to the candidate; the PR artifact's merge revision is recorded separately.
- Regenerated the cost disposition from the stable hosted snapshot and confirmed byte-for-byte output across 45 hashed inputs. The supported D-12 placement rationale retains all observed overages and all gates/counts. UIQ-06 and UIQ-07 are satisfied.
- Used the one conditionally authorized preview launch. It exited 1 because `/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar` returned HTTP 302. Five other routes returned 200 and built/served CSS matched. Page-marker checks did not run. Candidate-scoped containers, volumes, network, worktree, and run directory were cleaned up; the retained owner demo was untouched. UIQ-08 remains open.

## Exact hosted workflow receipts

| Run | Workflow/event | Attempt | Result |
|---|---|---:|---|
| `41386942453` | CI / pull_request | 1 | success |
| `41386942472` | Guard Release Trigger / pull_request | 1 | success |
| `41386939769` | PR Title / pull_request_target | 1 | success |
| `41386942395` | Actionlint / pull_request | 1 | success |
| `41386942424` | Advisory Matrix / pull_request | 1 | success; configured forward-compatibility lane skipped for this event |
| `41388399949` | Guard Release Trigger / PR body edit | 1 | success |
| `41388400355` | PR Title / PR body edit | 1 | success |
| `41388571351` | CI / workflow_dispatch | 1 | success |

## Cost disposition

Relative to baseline run `40414024714`, PR CI wall-to-green time was 802 seconds versus 1241 (-439 s), and summed runner time was 106.1667 versus 100.6833 minutes (+5.4833). Dispatch wall-to-green time was 1007 seconds (-234 s), and runner time was 116.9667 minutes (+16.2833), exceeding the 10-minute budget by 6.2833 minutes. The cold pilot took 599531 ms wall time (299531 ms above the 5-minute limit, while staying within its 10-runner-minute limit); warm took 293725 ms and stayed within limits. The approved D-12 placement disposition applies to this one owner-review cycle only. The evidence does not claim routine PR budget compliance or remove any gate.

## Preview stop and next actor

The terminal launcher record is `reference/demo_app/tmp/phase178_candidate/candidate-8e501960.json`, SHA-256 `29850312cdc0adb772d1541f9c81a9ee345f88b66e469464a2e535eb3f7cecf9`. Cycle 04 now records `preview.status=stopped`, the exact failure route, missing marker checks, and teardown. No preview URL is currently live. The Phase 178 owner/planner is next: classify the login return route's expected authentication/redirect behavior and, if necessary, scope a successor plan. Any new candidate or preview attempt needs fresh approval; Cycle 04's one attempt must not be repeated.

## Task commits

1. **Task 178-28-01: Verify candidate-bound Cycle 04 authorization** — `8b484ca9` (`docs(178-28): record Cycle 04 preflight verification`).
2. **Task 178-28-02: Execute the hosted sequence** — `7c064ef1` (`docs(178-28): record exact-SHA hosted pass`).
3. **Task 178-28-03: Measure cost and record preview stop** — `4a8d329a` (`docs(178-28): record Cycle 04 preview stop`).

## Deviations from plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Made cost regeneration independent of the mutable Cycle 04 result record**
- **Found during:** Task 178-28-03 (cost regeneration)
- **Issue:** The cost generator initially hashed the Cycle 04 record that also had to store the generated cost hash and later preview result, which made a final byte-reproducibility check self-referential.
- **Fix:** Added a deterministic, separately hashed snapshot derivation for the candidate, preflight, hosted authority, and hosted run receipts. The cost generator consumes that stable snapshot; the final record remains free to capture the terminal preview result.
- **Files modified:** Ignored Cycle 04 evidence helpers and stable snapshot under `reference/demo_app/tmp/phase178_candidate/recovery-cycle-04/`; committed output records the generator method and input hashes in `178-COST-DISPOSITION.json`.
- **Verification:** Regenerated the stable snapshot from the final Cycle 04 record and compared it byte-identically; regenerated the cost output byte-identically over the 45 hashed inputs.
- **Committed in:** `4a8d329a` (the committed record and disposition; temporary helper files remain ignored evidence).

The plan's preview failure path completed as designed: the launcher was not repeated, the exact route failure was recorded, UIQ-08 remains open, and the next actor is documented.

## Issues encountered

The launcher rejected the `/demo/login` return route's HTTP 302 response. CSS and the other five route probes passed; marker checks were skipped because the required route gate had already failed. The reason for this redirect is unclassified and is left for a successor plan.

## Next phase readiness

Cycle 04 hosted evidence and cost disposition are complete and reproducible. Phase 178 is not ready for the owner preview or ship/no-ship judgment until UIQ-08 is closed by an authorized successor preview with all route and marker checks passing.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-11-02*

## Self-Check: PASSED

All listed plan artifacts exist, task commits `8b484ca9`, `7c064ef1`, and `4a8d329a` are ancestors of HEAD, the Cycle 04 record parses and matches the retained failed candidate record, and stable-snapshot plus cost regeneration compare byte-identically. No task commit deleted a tracked file.
