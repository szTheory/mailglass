---
phase: 11-rfc-8058-list-unsubscribe
plan: 01
subsystem: api
tags: [rfc8058, phoenix-token, unsubscribe, tenancy, nimble-options]
requires:
  - phase: 03-open-click-tracking
    provides: Phoenix.Token signing patterns and tracking endpoint resolution
provides:
  - Compliance config accessors for unsubscribe endpoint, host, mount path, secrets, redirect, max age, and lifecycle module
  - Lifecycle behaviour seam for transaction-local unsubscribe side effects
  - Unsubscribe token and URL service with current-secret verification first and previous-secret fallback
affects: [11-02, 11-03, 11-04, 11-05, 11-06]
tech-stack:
  added: []
  patterns: [validated config accessors, Phoenix.Token secret rotation fallback, optional tenancy host override]
key-files:
  created:
    - lib/mailglass/lifecycle.ex
    - lib/mailglass/compliance/unsubscribe.ex
  modified:
    - lib/mailglass/config.ex
    - lib/mailglass/tenancy.ex
    - test/mailglass/compliance/unsubscribe_test.exs
key-decisions:
  - "Compliance endpoint resolution falls back to Mailglass.Tracking.endpoint/0 so unsubscribe tokens inherit the existing Phoenix endpoint chain unless explicitly overridden."
  - "Unsubscribe verification returns {:error, :invalid | :expired} while URL generation raises ConfigError for oversize links."
patterns-established:
  - "Mailglass.Config owns all compliance config reads through narrow accessors."
  - "Unsubscribe verification always tries the current secret first, then iterates previous raw secrets."
requirements-completed: [UNSUB-01]
duration: 5 min
completed: 2026-04-28
---

# Phase 11 Plan 01: Core Unsubscribe Contract Summary

**RFC 8058 unsubscribe config, lifecycle seam, and Phoenix.Token URL service with raw-secret rotation fallback**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-28T09:18:07Z
- **Completed:** 2026-04-28T09:23:12Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Added a validated `:compliance` config subtree and public accessors in `Mailglass.Config` for later Phase 11 routing and controller work.
- Introduced `Mailglass.Lifecycle` plus a built-in no-op module so unsubscribe POST handling can compose adopter-side `Ecto.Multi` work in 11-03.
- Implemented `Mailglass.Compliance.Unsubscribe` with delivery-only tokens, current-secret verification first, previous raw secret fallback, tenant-aware host resolution, and a 900-byte URL guard.

## Task Commits

1. **Task 1: Add unsubscribe config, lifecycle, and tenancy contracts** - `2623a04` (`test`), `8443bd6` (`feat`)
2. **Task 2: Implement current-secret plus previous-secret unsubscribe tokens** - `f8a290d` (`test`), `806a120` (`feat`)
3. **Task 3: Cover rotation, expiry, and URL-length guards with focused unit tests** - `e86db98` (`test`)

## Files Created/Modified
- `lib/mailglass/config.ex` - Adds the compliance schema, runtime validation helper, and public unsubscribe config accessors.
- `lib/mailglass/lifecycle.ex` - Defines the transaction lifecycle behaviour and shipped no-op implementation for future unsubscribe multi composition.
- `lib/mailglass/tenancy.ex` - Adds the optional `compliance_host/1` callback and dispatcher helper for per-tenant unsubscribe host overrides.
- `lib/mailglass/compliance/unsubscribe.ex` - Signs and verifies delivery-only tokens and builds bounded unsubscribe URLs.
- `test/mailglass/compliance/unsubscribe_test.exs` - Covers config contracts, token verification outcomes, rotation fallback, tenant host override, tamper rejection, and the 900-byte guard.

## Decisions Made
- Reused `Mailglass.Tracking.endpoint/0` as the compliance endpoint fallback so unsubscribe signing stays aligned with the established Phoenix.Token endpoint chain.
- Kept the unsubscribe token payload to `delivery_id` only and exposed controller-friendly verify outcomes as atoms rather than exceptions.
- Treated overlong unsubscribe URLs as configuration/runtime errors and raised `%Mailglass.ConfigError{}` before any later header injection path could use them.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added missing `:tracking, endpoint` schema key**
- **Found during:** Task 1
- **Issue:** `Mailglass.Tracking.endpoint/0` already depended on `config :mailglass, :tracking, endpoint: ...`, but `Mailglass.Config` rejected that key during validation.
- **Fix:** Added the missing tracking endpoint entry to the config schema so validated compliance accessors could safely reuse the existing endpoint resolution chain.
- **Files modified:** `lib/mailglass/config.ex`
- **Verification:** `mix test test/mailglass/compliance/unsubscribe_test.exs --only config_contract`
- **Committed in:** `8443bd6`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Required for correctness. No scope creep beyond the existing tracking contract.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `Mailglass.Compliance.Unsubscribe` is ready for 11-02 header injection, 11-03 controller flows, and 11-04 router path-consistency checks.
- The lifecycle hook contract and compliance config accessors are stable; later slices can build on them without new direct config lookups.

## Self-Check: PASSED
- Verified summary and created source files exist on disk.
- Verified task commits `2623a04`, `8443bd6`, `f8a290d`, `806a120`, and `e86db98` exist in git history.
