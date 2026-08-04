---
phase: 150-private-envelope-and-atomic-durable-enqueue
plan: "04"
subsystem: outbound configuration
tags: [elixir, oban, configuration, production-readiness, documentation]
requires:
  - phase: 150-private-envelope-and-atomic-durable-enqueue
    provides: fail-closed Oban readiness for the canonical outbound queue
provides:
  - Explicit production-only durable async readiness preflight
  - Truthful adapter warnings without tightening ordinary application boot
  - Canonical go-live configuration and executable documentation smoke coverage
affects: [150-05-contract-sweep, 153-generated-host-proof, outbound-worker]
tech-stack:
  added: []
  patterns: [explicit production preflight separate from boot validation, canonical queue documentation tied to Worker.queue/0]
key-files:
  created: []
  modified:
    - lib/mailglass/config.ex
    - lib/mailglass/application.ex
    - guides/production-go-live-checklist.md
    - test/mailglass/config_test.exs
    - test/mailglass/application_test.exs
    - test/mailglass/docs_migration_smoke_test.exs
key-decisions:
  - "Production readiness is an explicit operator preflight and never an ordinary application-start requirement."
  - "Only the bounded ConfigError key and reason_class cross the readiness boundary."
patterns-established:
  - "Durable deployment documentation names the Worker.queue/0 token and is checked by an executable smoke test."
requirements-completed: [ENVL-07, ENVL-08]
coverage:
  - id: D1
    description: Production readiness rejects explicit Task.Supervisor and only accepts a canonical-ready default Oban instance.
    requirement: ENVL-07
    verification:
      - kind: unit
        ref: mix test test/mailglass/config_test.exs test/mailglass/application_test.exs --only phase_150_task:t150_04_01 --warnings-as-errors
        status: pass
    human_judgment: false
  - id: D2
    description: Go-live configuration selects Oban, uses only mailglass_outbound, and ties its preflight to bounded typed errors.
    requirement: ENVL-08
    verification:
      - kind: other
        ref: mix test test/mailglass/docs_migration_smoke_test.exs --only phase_150_task:t150_04_02 --warnings-as-errors
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-08-02
status: complete
---

# Phase 150 Plan 04: Production Readiness Boundary Summary

**A callable durable-deployment preflight now rejects non-durable Task.Supervisor, requires the canonical Oban queue, and leaves normal development/test boot unchanged.**

## Performance

- **Duration:** 9 min
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added `Mailglass.Config.production_readiness/0`, which turns the current explicit adapter and canonical Oban gateway result into bounded typed configuration errors.
- Kept `validate_at_boot!/0` and application startup free of production-only rejection while making their adapter warnings operationally truthful.
- Replaced the stale production queue example with the canonical `mailglass_outbound` configuration and a copy-pasteable readiness call.
- Added focused runtime and documentation smoke coverage for success, unavailable instance, empty queue, wrong queue, and explicit non-durable adapter cases.

## Task Commits

1. **Task 1: Enforce the explicit production-readiness boundary** — `35f07b6c` (RED), `c13bd1ae` (GREEN)
2. **Task 2: Make the production checklist exercise the readiness contract** — `3035f2ff` (RED), `a6dfa539` (GREEN)

## Files Created/Modified

- `lib/mailglass/config.ex` — exposes the production-only bounded readiness preflight.
- `lib/mailglass/application.ex` — distinguishes fail-closed unavailable Oban from explicit non-durable Task.Supervisor warnings.
- `guides/production-go-live-checklist.md` — documents exact durable adapter, canonical queue, and readiness call.
- `test/mailglass/config_test.exs` and `test/mailglass/application_test.exs` — pin preflight outcomes and boot separation.
- `test/mailglass/docs_migration_smoke_test.exs` — mechanically ties documentation to the worker queue and typed failure contract.

## Decisions Made

- Production durability remains an explicit deployment decision; ordinary boot validates schema only so development/test Task.Supervisor remains usable.
- Readiness errors expose only `key: :async_adapter` and a stable `reason_class`, never host or recipient details.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The Oban runtime rejects zero concurrency during configuration before readiness can run. Empty queue coverage therefore uses its valid `queues: []` configuration, while Oban itself guards invalid zero concurrency.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 150-05 can sweep the remaining contracts knowing that durable production configuration, boot separation, and the canonical queue token are now pinned. Phase 153 still owns generated-host proof of an actively polling consumer.

## Self-Check: PASSED

- Confirmed all six modified source, guide, and test files exist.
- Confirmed task commits `35f07b6c`, `c13bd1ae`, `3035f2ff`, and `a6dfa539` exist in git history.
