---
phase: 149-first-send-contract-foundation
plan: "02"
subsystem: outbound preflight
tags: [elixir, swoosh, outbound, validation, privacy, oban]
requires:
  - phase: 149-01
    provides: "Pure resolver-aware preflight before outbound effects"
provides:
  - "Exact one-recipient native Swoosh envelope contract across to, cc, and bcc"
  - "Bounded typed body-shape rejection before rendering, limits, persistence, jobs, or dispatch"
affects: [149-03, 149-04, outbound, async-delivery]
tech-stack:
  added: []
  patterns:
    - "Pure preflight returns bounded reason atoms and counts without user-authored envelope or body values"
    - "Negative-control integration tests observe renderer, limiter, persistence, queue, supervisor, and Fake adapter boundaries"
key-files:
  created: []
  modified:
    - lib/mailglass/outbound/preflight.ex
    - test/mailglass/outbound/preflight_test.exs
    - test/mailglass/outbound/deliver_later_test.exs
key-decisions:
  - "Count native to, cc, and bcc entries exactly as supplied; no selection, deduplication, sorting, or recipient fan-out occurs."
  - "A body is accepted only when at least one HTML or plaintext field is supported and nonblank; unsupported shapes take precedence over empty shapes when no usable body remains."
patterns-established:
  - "Preflight context exposes only reason_class plus recipient_count or body_state, never recipient or body values."
requirements-completed: [FIRST-03, FIRST-04, FIRST-07]
coverage:
  - id: D1
    description: "Exactly one native to, cc, or bcc recipient is accepted, while zero and every multi-recipient shape reject without mutation."
    requirement: FIRST-03
    verification:
      - kind: unit
        ref: "test/mailglass/outbound/preflight_test.exs#preflight recipient cardinality"
        status: pass
    human_judgment: false
  - id: D2
    description: "Recipient and body rejection occurs before renderer telemetry, limiter telemetry, delivery persistence, Oban insertion, Task.Supervisor dispatch, and Fake adapter delivery."
    requirement: FIRST-04
    verification:
      - kind: integration
        ref: "test/mailglass/outbound/preflight_test.exs#preflight ordering; test/mailglass/outbound/deliver_later_test.exs#preflight failures"
        status: pass
    human_judgment: false
  - id: D3
    description: "Empty, whitespace-only, unsupported, and invalid-UTF-8 body shapes return bounded preflight errors, while supported Unicode plaintext and supported HTML pass unchanged."
    requirement: FIRST-07
    verification:
      - kind: unit
        ref: "test/mailglass/outbound/preflight_test.exs#preflight body contract"
        status: pass
    human_judgment: false
metrics:
  duration: 4m
  completed: 2026-08-02
status: complete
---

# Phase 149 Plan 02: First-Send Contract Foundation Summary

**Shared outbound preflight now accepts exactly one untouched native envelope recipient and rejects invalid recipient/body shapes with bounded errors before any outbound side effect.**

## Performance

- **Duration:** 4m
- **Started:** 2026-08-02T13:50:00-04:00
- **Completed:** 2026-08-02T13:54:00-04:00
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Enforced exact recipient cardinality across native `to`, `cc`, and `bcc` fields without selecting, normalizing, deduplicating, reordering, or dropping entries.
- Added bounded preflight error context for recipient counts and body states, excluding recipient and content values from the public error surface.
- Proved rejected sync and async inputs do not render, consume rate-limit state, create delivery artifacts or Oban jobs, spawn a task, or dispatch through the Fake adapter.

## Task Commits

1. **Task 1: Enforce exact native envelope cardinality** - `6667089e` (test), `8d570d33` (feat)
2. **Task 2: Reject before rendering and every outbound side effect** - `28dc3808` (test), `aaa84aa6` (feat), `b8f7f9de` (refactor)

## Files Created/Modified

- `lib/mailglass/outbound/preflight.ex` - Counts all native recipient fields and classifies supported, empty, and unsupported bodies before effects.
- `test/mailglass/outbound/preflight_test.exs` - Pins cardinality, body boundaries, non-PII contexts, and synchronous negative controls.
- `test/mailglass/outbound/deliver_later_test.exs` - Pins async zero-row, zero-job, zero-task, and zero-Fake-delivery rejection behavior.

## Decisions Made

- Recipient cardinality is the unmodified total of `List.wrap(to) ++ List.wrap(cc) ++ List.wrap(bcc)`; duplicate values remain separate entries.
- When no usable body exists, unsupported values produce `body_state: :unsupported`; otherwise blank/nil bodies produce `body_state: :empty`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The prior body gate collapsed unsupported inputs into an empty-body error. Test-first coverage exposed the mismatch and the planned implementation now distinguishes bounded `:empty` and `:unsupported` states.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 149-03 can rely on a pure, effect-free shared preflight contract while it proves renderer parity and plaintext behavior.

## Self-Check: PASSED

- Confirmed task commits `6667089e`, `8d570d33`, `28dc3808`, `aaa84aa6`, and `b8f7f9de` exist.
- Confirmed `lib/mailglass/outbound/preflight.ex` and both focused outbound test files exist.
