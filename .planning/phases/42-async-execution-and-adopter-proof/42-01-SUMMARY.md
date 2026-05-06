---
phase: 42-async-execution-and-adopter-proof
plan: "01"
subsystem: inbound
tags: [mailglass_inbound, oban, task_supervisor, replay, ingress]
requires:
  - phase: 41-sendgrid-ingress-and-mailbox-routing
    provides: persist-first inbound truth, mailbox routing, and replay lineage constraints
provides:
  - shared async inbound execution seam with internal Oban worker dispatch
  - bounded Task.Supervisor fallback with once-per-node warning posture
  - ingress and replay rewired to one execution runner and lineage model
affects: [phase-42-docs, inbound-adoption, operator-trust]
tech-stack:
  added: []
  patterns: [package-local optional Oban gateway, internal worker wrapper, shared execution runner]
key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/application.ex
    - mailglass_inbound/lib/mailglass_inbound/execution/worker.ex
    - mailglass_inbound/test/mailglass_inbound/async_execution_test.exs
    - mailglass_inbound/test/mailglass_inbound/worker_test.exs
  modified:
    - mailglass_inbound/mix.exs
    - mailglass_inbound/lib/mailglass_inbound/execution.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
    - mailglass_inbound/lib/mailglass_inbound/internal/replay.ex
    - mailglass_inbound/lib/mailglass_inbound/optional_deps.ex
    - mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs
    - mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs
    - mailglass_inbound/test/mailglass_inbound/replay_test.exs
key-decisions:
  - "Oban job args keep only internal route facts plus record/evidence ids so durable workers can reconstruct the exact mailbox target without widening the public contract."
  - "Fallback execution remains post-persist Task.Supervisor work with explicit best-effort warning semantics and no fake durability."
patterns-established:
  - "Ingress persists first and then calls Execution.dispatch/2; request acknowledgments do not depend on mailbox completion."
  - "Fresh, replay, Oban worker, and fallback execution all converge on Execution.execute/2 with source tagging."
requirements-completed: [EXEC-01, EXEC-02]
duration: 6min
completed: 2026-05-06
---

# Phase 42 Plan 01 Summary

**Shared inbound async execution now prefers internal Oban jobs, falls back honestly to Task.Supervisor, and reuses one execution-lineage runner for fresh ingress and replay.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-06T18:28:07Z
- **Completed:** 2026-05-06T18:34:30Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments
- Added a package-owned `MailglassInbound.Application` with a dedicated task supervisor and once-per-node fallback warning posture.
- Split `MailglassInbound.Execution` into shared dispatch, load, and execute responsibilities plus an internal Oban worker wrapper.
- Rewired fresh ingress and internal replay to the shared execution seam so all trigger modes append through one truth model.

## Task Commits

1. **Task 1: Introduce one shared async dispatch seam with package-local Oban gateway support** - `5069051` (`test`), `547529c` (`feat`)
2. **Task 2: Rewire fresh ingress and replay to use the shared async execution seam** - `1d88d13` (`feat`)

## Files Created/Modified
- `mailglass_inbound/lib/mailglass_inbound/application.ex` - package runtime supervision and fallback warning emission
- `mailglass_inbound/lib/mailglass_inbound/execution.ex` - shared dispatch, payload loading, and unified execution runner
- `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex` - internal Oban worker wrapper over the shared runner
- `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex` - runtime mode selection and internal enqueue helper
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` - post-persist async dispatch hook
- `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` - replay reuse of the shared execution runner
- `mailglass_inbound/test/mailglass_inbound/async_execution_test.exs` - dispatch branching and fallback warning proof
- `mailglass_inbound/test/mailglass_inbound/worker_test.exs` - worker arg-shape and failure mapping proof
- `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` - async dispatch-after-persist proof
- `mailglass_inbound/test/mailglass_inbound/replay_test.exs` - shared replay runner proof

## Decisions Made
- Replay now delegates to `Execution.execute/2` with `source: :replay` instead of duplicating mailbox classification and insert logic.
- Internal Oban job args include the matched mailbox identity and route status because the current durable inbound record does not persist route truth before the first execution run.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Worked around missing executor `gsd-sdk query` subcommands**
- **Found during:** Plan bootstrap
- **Issue:** The local `gsd-sdk` binary in this repo exposes `run/auto/init` only, so the executor-specific `query` commands in the orchestration instructions were unavailable.
- **Fix:** Used the checked-in `.planning` artifacts directly for plan/state context and completed the phase with manual summary evidence instead of automated query-driven state handlers.
- **Files modified:** `.planning/phases/42-async-execution-and-adopter-proof/42-01-SUMMARY.md`
- **Verification:** Plan tasks and both verification commands completed successfully without the missing CLI surface.
- **Committed in:** pending summary commit

---

**Total deviations:** 1 auto-fixed (Rule 3: 1)
**Impact on plan:** No scope creep in runtime code. The implementation and verification match the plan; only the executor bookkeeping path fell back to manual handling.

## Issues Encountered
- Parallel plan verification runs briefly waited on the Elixir build directory lock from an earlier process in the same checkout. Waiting for the exact plan commands resolved it without changing the verification lane.

## User Setup Required

None - no external service configuration was required for this plan execution.

## Next Phase Readiness
- `mailglass_inbound` now has the async runtime seam needed for the docs/adopter proof follow-up work in Phase 42.
- `ADOPT-01` remains for a later plan in this phase; this plan completed the execution requirements only.

## Verification

- `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/worker_test.exs test/mailglass_inbound/mailbox_execution_test.exs --warnings-as-errors` — PASS (`10 tests, 0 failures`)
- `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/ingress/plug_test.exs test/mailglass_inbound/replay_test.exs test/mailglass_inbound/mailbox_execution_test.exs --warnings-as-errors` — PASS (`26 tests, 0 failures`)

## Self-Check: PASSED

---
*Phase: 42-async-execution-and-adopter-proof*
*Completed: 2026-05-06*
