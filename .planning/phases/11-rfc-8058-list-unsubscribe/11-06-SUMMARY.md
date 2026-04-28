---
phase: 11-rfc-8058-list-unsubscribe
plan: 06
subsystem: testing
tags: [streamdata, phoenix-token, phoenix-conntest, rfc-8058, property-tests]
requires:
  - phase: 11-01
    provides: unsubscribe token and URL service
  - phase: 11-02
    provides: stream-aware unsubscribe header injection
  - phase: 11-03
    provides: unsubscribe controller and lifecycle flow
  - phase: 11-04
    provides: mounted unsubscribe router contract
provides:
  - rotation, expiry, URL-safety, and stream-gating property coverage for unsubscribe tokens and headers
  - mounted POST replay convergence property coverage for one-click unsubscribe
affects: [UNSUB-05, compliance, property-testing]
tech-stack:
  added: []
  patterns: [StreamData invariants, mounted Phoenix endpoint property harness, host authority validation]
key-files:
  created:
    - test/mailglass/properties/unsubscribe_property_test.exs
    - test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs
  modified:
    - lib/mailglass/compliance/unsubscribe.ex
    - .planning/phases/11-rfc-8058-list-unsubscribe/11-06-SUMMARY.md
key-decisions:
  - "Unsubscribe URL generation now rejects scheme-bearing, path-bearing, whitespace-containing, and local/private hosts before emitting a one-click URL."
  - "POST replay convergence is proven through a mounted Phoenix endpoint with Sandbox auto mode and truncation between generated runs."
patterns-established:
  - "Property suites can drive Phoenix.Token rotation and expiry deterministically by overriding signed_at."
  - "Replay-heavy controller properties should use a mounted test endpoint plus TRUNCATE-based iteration isolation."
requirements-completed: [UNSUB-05]
duration: 4min
completed: 2026-04-28
---

# Phase 11 Plan 06: Property Test Summary

**StreamData coverage now proves unsubscribe secret rotation, expiry, URL hardening, stream header gating, and one-click POST replay convergence.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-28T09:52:00Z
- **Completed:** 2026-04-28T09:56:42Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added a property suite for token rotation, deterministic expiry, hostile-host rejection, oversized-link failure, and stream-conditional header injection.
- Hardened `Mailglass.Compliance.Unsubscribe` so tenant/global compliance hosts cannot smuggle schemes, paths, fragments, userinfo, whitespace, or local/private addresses into generated unsubscribe URLs.
- Added a mounted Phoenix endpoint property harness that proves repeated RFC 8058 POST replays converge to the same single durable `:unsubscribed` event.

## Task Commits

Each task was committed atomically:

1. **Task 1: RED/GREEN token, URL, and header property suite** - `7a72970` (test), `1c43ed3` (feat)
2. **Task 2: RED/GREEN POST replay convergence property suite** - `d5b30b9` (test), `a2dae1a` (test)

## Files Created/Modified
- `test/mailglass/properties/unsubscribe_property_test.exs` - Property coverage for rotation, expiry, URL safety, overflow guardrails, and stream header rules.
- `test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs` - Mounted endpoint convergence property for replayed unsubscribe POST requests.
- `lib/mailglass/compliance/unsubscribe.ex` - Host authority validation for generated unsubscribe URLs.

## Decisions Made
- Rejected unsafe compliance hosts at URL-build time instead of trusting tenant overrides, which closes the open-redirect and SSRF seam without widening the token payload.
- Drove expiry properties with explicit `signed_at` timestamps so the suite stays deterministic and fast.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Closed unsafe compliance-host acceptance in unsubscribe URL generation**
- **Found during:** Task 1 (RED/GREEN token, URL, and header property suite)
- **Issue:** `Mailglass.Compliance.Unsubscribe` accepted tenant/global hosts containing schemes, path/query fragments, whitespace, and local/private authorities, which let generated one-click URLs cross the plan's URL-safety boundary.
- **Fix:** Added authority validation before URL construction, rejecting malformed hosts plus localhost, loopback, link-local, and private IP literals.
- **Files modified:** `lib/mailglass/compliance/unsubscribe.ex`, `test/mailglass/properties/unsubscribe_property_test.exs`
- **Verification:** `mix test test/mailglass/properties/unsubscribe_property_test.exs`
- **Committed in:** `1c43ed3`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Required for UNSUB-05 correctness. No payload-shape expansion and no scope creep beyond the adjacent URL builder.

## Issues Encountered
- The POST replay property initially collided with the router `post` macro and then lacked `@endpoint` for `Phoenix.ConnTest`; both were harness issues resolved inside the test file before the green commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- UNSUB-05 now has property coverage across the highest-risk RFC 8058 invariants.
- Phase 11 can proceed to the remaining documentation and verification work without additional unsubscribe-flow test gaps.

## Self-Check: PASSED

---
*Phase: 11-rfc-8058-list-unsubscribe*
*Completed: 2026-04-28*
