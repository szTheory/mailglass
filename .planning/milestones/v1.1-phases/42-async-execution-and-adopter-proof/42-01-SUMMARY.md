---
phase: 42-async-execution-and-adopter-proof
plan: "01"
subsystem: inbound
tags: [async-execution, oban, fallback, replay]
requires:
  - phase: 41
    provides: truthful SendGrid ingress, mailbox routing, replay over stored truth
provides:
  - shared async execution dispatcher
  - internal Oban worker with package-local gateway
  - bounded Task.Supervisor fallback with explicit warning posture
affects: [phase-42, mailglass_inbound]
tech-stack:
  added: []
  patterns: [shared execution seam, optional dependency gateway, best-effort fallback]
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
    - mailglass_inbound/test/mailglass_inbound/replay_test.exs
key-decisions:
  - "Kept all direct Oban interaction behind MailglassInbound.OptionalDeps.Oban and an internal worker so no Oban job shape leaks into the public contract."
  - "Made Task.Supervisor fallback explicitly best-effort, once-per-node warned, and recovery-oriented via replay rather than pretending it is durable."
patterns-established:
  - "Fresh ingress dispatches asynchronously after persistence succeeds, while replay reuses the same execution runner with lineage source preserved."
requirements-completed: [EXEC-01, EXEC-02]
duration: unknown
completed: 2026-05-06
---

# Phase 42-01 Summary

**`mailglass_inbound` now dispatches persisted inbound work asynchronously through one shared seam, preferring durable Oban execution when available and falling back honestly to supervised best-effort tasks when it is not.**

## Performance

- **Duration:** unknown
- **Started:** 2026-05-06
- **Completed:** 2026-05-06
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added a shared `MailglassInbound.Execution.dispatch/2` seam with a package-owned application supervisor and internal Oban worker.
- Extended the optional dependency gateway so execution mode selection and enqueue behavior stay package-local.
- Rewired fresh ingress and internal replay to share one execution truth model while preserving duplicate short-circuiting and replay lineage.
- Added focused tests for Oban dispatch, Task.Supervisor fallback, worker job loading, ingress async behavior, and replay reuse.

## Task Commits

- `5069051` - failing async execution seam coverage
- `547529c` - shared async execution seam, worker, application wiring, and fallback warning posture
- `1d88d13` - ingress and replay rewired to the shared execution seam

## Files Created/Modified

- `mailglass_inbound/lib/mailglass_inbound/application.ex` - package supervisor plus once-per-node fallback warning.
- `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex` - internal Oban worker wrapper over the shared runner.
- `mailglass_inbound/lib/mailglass_inbound/execution.ex` - dispatch/load/execute seam spanning fresh, replay, Oban, and fallback paths.
- `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex` - package-local execution mode and enqueue helpers.
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` - async post-persist dispatch for fresh ingress.
- `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` - replay routed through the shared execution runner with `:replay` lineage.
- `mailglass_inbound/test/mailglass_inbound/async_execution_test.exs` - dispatch and fallback proof lane.
- `mailglass_inbound/test/mailglass_inbound/worker_test.exs` - worker arg loading and result mapping proof lane.
- `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` - fresh ingress async handoff assertions.
- `mailglass_inbound/test/mailglass_inbound/replay_test.exs` - replay lineage and shared execution assertions.

## Decisions Made

- Preserved persist-first receive semantics by dispatching only after canonical/evidence truth is written.
- Kept replay internal and execution-source aware so fresh durable async, fresh fallback async, and replay all write one lineage model.

## Deviations from Plan

None - plan executed within the intended scope.

## Issues Encountered

- The local `gsd-sdk` installation in this environment does not expose the workflow `query` interface, so the phase summary had to be written manually rather than by the planned helper command.

## User Setup Required

None - no external service configuration required for the codebase itself.

## Next Phase Readiness

Plan 42-02 can now document the real adoption and operator story for durable Oban execution versus bounded fallback behavior.

---
*Phase: 42-async-execution-and-adopter-proof*
*Completed: 2026-05-06*
