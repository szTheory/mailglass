---
phase: 151-unified-dispatch-honest-outcomes-and-payload-lifecycle
plan: "05"
subsystem: outbound delivery
tags: [elixir, ecto, postgres, payload-lifecycle, retention, tenancy, privacy]
requires:
  - phase: 151-04
    provides: tenant-scoped payload lifecycle state and durable dispatch settlement
provides:
  - finite validated payload retention defaults and recovery eligibility policy
  - explicit tenant-scoped one-batch content-to-tombstone payload pruning
affects: [payload-retention, outbound-worker, generated-host-proof]
tech-stack:
  added: []
  patterns: [closed lifecycle recovery matrix, deterministic tenant-scoped CAS tombstone batch]
key-files:
  created: [lib/mailglass/outbound/payload_lifecycle.ex, lib/mailglass/outbound/payload_pruner.ex]
  modified: [lib/mailglass/config.ex, lib/mailglass/outbound/payload.ex, test/mailglass/config_test.exs, test/mailglass/outbound/payload_lifecycle_test.exs]
key-decisions:
  - "Terminal, discarded, abandoned, and legacy payload content retains for 14 days; acceptance-uncertain content retains for 30 days."
  - "Pruning requires an explicit nonblank tenant and transitions, rather than deletes, at most one expiry/id ordered batch."
patterns-established:
  - "Recovery eligibility is closed by lifecycle state: only unexpired recoverable content is claimable; dispatching remains uncertain and legacy is never reconstructed."
requirements-completed: [PRIV-02, PRIV-03, PRIV-04]
coverage:
  - id: D1
    description: Finite positive-only outbound payload retention defaults and overrides.
    requirement: PRIV-02
    verification:
      - kind: unit
        ref: test/mailglass/config_test.exs#validates finite outbound payload retention defaults and overrides
        status: pass
    human_judgment: false
  - id: D2
    description: Closed retention/recovery matrix rejects blind resend of uncertain and legacy payloads and requires an explicit tenant to prune.
    requirement: PRIV-04
    verification:
      - kind: unit
        ref: test/mailglass/outbound/payload_lifecycle_test.exs#defines finite exact retention and fail-closed recovery eligibility
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-03
status: complete
---

# Phase 151 Plan 05: Finite Payload Retention Summary

**Finite payload retention and fail-closed recovery semantics with deterministic, explicit-tenant tombstone pruning.**

## Performance

- **Duration:** 8 min
- **Tasks:** 1/1
- **Files modified:** 6

## Accomplishments

- Added validated finite defaults: terminal 14d, uncertain 30d, legacy 14d, and a 500-row maximum prune batch.
- Defined closed recovery eligibility so only unexpired recoverable content is claimable; dispatching remains acceptance-uncertain and legacy cannot be reconstructed.
- Added a prefix-aware tenant predicate, expiry/id ordering, and per-row CAS content scrubbing that preserves lifecycle reasons and payload identity as expired tombstones.

## Task Commits

1. **Task 1: Expire one bounded batch into non-content tombstones** — `31b31237` (RED test), `62c961cf` (implementation)

## Files Created/Modified

- `lib/mailglass/config.ex` — finite, documented outbound payload retention validation and accessor.
- `lib/mailglass/outbound/payload_lifecycle.ex` — retention durations, expiry calculations, and recovery matrix.
- `lib/mailglass/outbound/payload_pruner.ex` — bounded explicit-tenant deterministic tombstone prune core.
- `lib/mailglass/outbound/payload.ex` — Clock-backed expiry settlement and fail-closed recovery lookup.
- `test/mailglass/config_test.exs` — retention validation coverage.
- `test/mailglass/outbound/payload_lifecycle_test.exs` — recovery and explicit-tenant prune contract coverage.

## Decisions Made

- The configured batch size is a positive integer with no all-tenant or ambient-tenant fallback.
- Expired content is never deleted in this core; its digest, version, identifiers, prior bounded reason, and timestamps remain available as a contentless tombstone.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected invalid guard and Ecto update interpolation in the pruner.**
- **Found during:** Task 1
- **Issue:** `String.trim/1` is not guard-safe and the CAS update needed a pinned timestamp.
- **Fix:** Moved blank-tenant validation into the function body and pinned the Clock timestamp in the query update.
- **Files modified:** `lib/mailglass/outbound/payload_pruner.ex`
- **Verification:** Focused and full planned test commands passed with warnings-as-errors.
- **Committed in:** `62c961cf`

## Known Stubs

None.

## Next Phase Readiness

The outbound lifecycle now exposes finite defaults, honest recovery eligibility, and an explicit bounded prune core for scheduled/manual entrypoints.

## Self-Check: PASSED

- Confirmed lifecycle and pruner source files exist.
- Confirmed RED commit `31b31237` and GREEN commit `62c961cf` exist in git history.
