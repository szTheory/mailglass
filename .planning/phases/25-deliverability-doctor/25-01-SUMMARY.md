---
phase: 25-deliverability-doctor
plan: "01"
subsystem: infra
tags: [deliverability, dns, otp, mix-task, stream_data]
requires: []
provides:
  - schema-versioned deliverability result contract with closed statuses
  - OTP-backed DNS resolver seam with normalized TXT, MX, and CNAME outputs
  - one-domain runtime entrypoint that preserves resolver uncertainty as data
affects: [deliverability, mix-task, admin, formatter]
tech-stack:
  added: []
  patterns: [closed result contract, OTP resolver seam, deterministic process-local test stub]
key-files:
  created:
    - lib/mailglass/deliverability/result.ex
    - lib/mailglass/deliverability/resolver.ex
    - lib/mailglass/deliverability.ex
    - test/support/deliverability_resolver_stub.ex
    - test/mailglass/deliverability/result_test.exs
    - test/mailglass/deliverability_test.exs
    - test/mailglass/properties/deliverability_status_property_test.exs
  modified:
    - test/mailglass/properties/deliverability_status_property_test.exs
key-decisions:
  - "Use Mailglass.Deliverability.Result as the only summary counter so human and JSON renderers cannot drift."
  - "Use OTP :inet_res.resolve/3 behind Mailglass.Deliverability.Resolver to retain NXDOMAIN and timeout semantics instead of flattening them into empty answers."
  - "Keep run/1 limited to fact collection and resolver-error capture in this plan so later protocol analyzers can extend the same contract without changing the runtime entrypoint."
patterns-established:
  - "Deliverability runtime modules return plain data maps and never expose raw DNS tuples or charlists."
  - "Resolver uncertainty is recorded in resolver_errors, not raised."
requirements-completed: [DOCTOR-01, DOCTOR-02, DOCTOR-03]
duration: 5min
completed: 2026-05-01
---

# Phase 25 Plan 01: Deliverability Runtime Contract Summary

**Schema-versioned deliverability results with a closed status contract, OTP DNS resolver seam, and one-domain runtime fact collection for future `mix mail.doctor` analyzers**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-01T20:29:45Z
- **Completed:** 2026-05-01T20:34:38Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Added `Mailglass.Deliverability.Result` as the shared contract for domain, selectors, findings, summary buckets, facts, and resolver errors.
- Added `Mailglass.Deliverability.Resolver` plus `Mailglass.Deliverability.run/1` so one-domain doctor runs can collect SPF, DKIM, DMARC, MX, and BIMI DNS facts without Repo or admin dependencies.
- Added deterministic runtime coverage with a process-local resolver stub, contract unit tests, and a status-domain property suite.

## Task Commits

Each task was committed atomically:

1. **Task 1: Define the shared deliverability result contract and deterministic test stub** - `85124e5` (feat)
2. **Task 2: Add the resolver seam and top-level runtime orchestration** - `e6eb695` (feat)

## Files Created/Modified
- `lib/mailglass/deliverability/result.ex` - closed result helpers, summary counting, fact defaults, and resolver-error normalization
- `lib/mailglass/deliverability/resolver.ex` - resolver behaviour and OTP-backed TXT/MX/CNAME adapter
- `lib/mailglass/deliverability.ex` - one-domain runtime orchestration over the resolver seam
- `test/support/deliverability_resolver_stub.ex` - deterministic resolver fixture module for later analyzer and CLI tests
- `test/mailglass/deliverability/result_test.exs` - contract coverage for schema version, summary counting, and malformed input rejection
- `test/mailglass/deliverability_test.exs` - runtime coverage for blank domains, selector passthrough, fact buckets, and resolver_errors
- `test/mailglass/properties/deliverability_status_property_test.exs` - property coverage for closed statuses and `cannot_verify` preservation

## Decisions Made
- `Mailglass.Deliverability.run/1` returns a `Result` map directly instead of building an intermediate task-specific shape.
- Resolver callbacks stay small and protocol-neutral: TXT, MX, and CNAME only.
- Domain input is normalized per invocation, but DKIM selectors are preserved as explicit caller input rather than guessed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed brittle map-key ordering from the status property test**
- **Found during:** Task 2 overall verification
- **Issue:** The property suite asserted raw `Map.keys/1` order, which is not a stable contract and failed during the combined verification run.
- **Fix:** Updated the property assertion to compare the sorted summary-key set instead of insertion order.
- **Files modified:** `test/mailglass/properties/deliverability_status_property_test.exs`
- **Verification:** `mix test test/mailglass/deliverability/result_test.exs test/mailglass/properties/deliverability_status_property_test.exs test/mailglass/deliverability_test.exs --warnings-as-errors`
- **Committed in:** `e6eb695`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** No scope creep. The fix made the planned property coverage deterministic under the combined test run.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later protocol analyzers can consume the stable `facts` and `resolver_errors` buckets without changing the result schema or runtime entrypoint.
- The deterministic resolver stub is in place for SPF, DKIM, DMARC, MX, and BIMI analyzer tests.
- `Mailglass.Deliverability.run/1` intentionally returns empty `findings` in this plan; later plans should populate findings from the collected facts rather than reshaping the contract.

---
*Phase: 25-deliverability-doctor*
*Completed: 2026-05-01*
