---
phase: 11-rfc-8058-list-unsubscribe
plan: 02
subsystem: deliverability
tags: [rfc-8058, unsubscribe, credo, swoosh, boundary]
requires:
  - phase: 11-01
    provides: unsubscribe token generation and URL building via `Mailglass.Compliance.Unsubscribe`
provides:
  - message-aware outbound compliance wrapper for stream-conditional unsubscribe injection
  - atomic `List-Unsubscribe` and `List-Unsubscribe-Post` mutation path
  - custom Credo rule blocking ad hoc unsubscribe header writes
affects: [outbound, compliance, lint, phase-11]
tech-stack:
  added: []
  patterns:
    - message-aware compliance wrapping after render and before tracking rewrite
    - custom Credo module/function-stack traversal for domain invariants
key-files:
  created:
    - credo_checks/require_atomic_unsubscribe_headers.ex
    - test/credo_checks/require_atomic_unsubscribe_headers_test.exs
  modified:
    - lib/mailglass/compliance.ex
    - lib/mailglass/outbound.ex
    - lib/mailglass.ex
    - .credo.exs
    - test/mailglass/compliance_test.exs
key-decisions:
  - "Kept `add_rfc_required_headers/1` email-only and introduced `apply_outbound_headers/1` as the message-aware seam."
  - "Allowed only `Mailglass.Compliance.inject_unsubscribe_headers/2` to mutate RFC 8058 headers and made partial pre-set pairs a no-op rather than auto-completing them."
  - "Expanded scope minimally to `Mailglass.Outbound` and the root boundary export so unsubscribe injection runs in the real send pipeline."
patterns-established:
  - "Outbound compliance headers are applied after render while stream and tenant context are still available."
  - "Lint rules for mail-specific invariants track module/function context and validate the blessed mutation path structurally."
requirements-completed: [UNSUB-02]
duration: 8min
completed: 2026-04-28
---

# Phase 11 Plan 02: RFC 8058 atomic unsubscribe seam Summary

**Message-aware outbound compliance now injects RFC 8058 unsubscribe headers atomically and strict lint blocks any ad hoc header mutation path.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-28T09:24:24Z
- **Completed:** 2026-04-28T09:31:58Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `Mailglass.Compliance.apply_outbound_headers/1` and `inject_unsubscribe_headers/2` so unsubscribe injection stays stream-aware while RFC-generic headers remain email-level.
- Routed the outbound preflight through the new compliance wrapper before tracking rewrites, covering sync, async, and batch preflight paths.
- Added `Mailglass.Credo.RequireAtomicUnsubscribeHeaders` and focused tests so non-atomic unsubscribe header writes fail lint.

## Task Commits

Each task was committed atomically:

1. **Task 1: Introduce the message-aware compliance wrapper and atomic injection path** - `2b03f6d` (test), `c951310` (feat)
2. **Task 2: Enforce atomic unsubscribe headers with a custom Credo check** - `52c39f3` (test), `afa55ed` (feat)

## Files Created/Modified

- `lib/mailglass/compliance.ex` - added the message-aware outbound wrapper, atomic injector, and stream-conditional unsubscribe branching.
- `lib/mailglass/outbound.ex` - applied outbound compliance headers in the real delivery preflight before tracking rewrites.
- `lib/mailglass.ex` - exported `Mailglass.Compliance` and `Mailglass.Compliance.Unsubscribe` for the outbound boundary dependency.
- `credo_checks/require_atomic_unsubscribe_headers.ex` - new custom Credo rule for RFC 8058 header mutation.
- `.credo.exs` - registered the new custom check in the strict config.
- `test/mailglass/compliance_test.exs` - added stream-conditional and atomic unsubscribe behavior coverage.
- `test/credo_checks/require_atomic_unsubscribe_headers_test.exs` - added lint-rule coverage for allowed and disallowed header writes.

## Decisions Made

- Kept `add_rfc_required_headers/1` unchanged as the `%Swoosh.Email{}` primitive and introduced `apply_outbound_headers/1` instead of overloading email-level RFC injection with stream logic.
- Treated a pre-existing half-configured unsubscribe pair as immutable in the injector so the blessed path never silently “repairs” a non-atomic caller.
- Used the mailable-exported `__mailglass_unsubscribe__/0` opt-in seam for `:operational` messages until later Phase 11 slices add broader unsubscribe configuration surfaces.

## Deviations from Plan

### Scope Expansion

- Expanded the declared file scope to `lib/mailglass/outbound.ex` and `lib/mailglass.ex`.
- Reason: the new compliance seam had to run inside the actual outbound pipeline, and Boundary required exporting `Mailglass.Compliance` for that dependency.
- Impact: minimal adjacent change only; no architectural change.

### Verification Caveat

- `mix credo --strict` does not pass for the repo as a whole because of pre-existing issues outside `11-02` scope plus an existing warning in `lib/mailglass/compliance/unsubscribe_controller.ex`, which belongs to a later Phase 11 slice.
- Logged in `.planning/phases/11-rfc-8058-list-unsubscribe/deferred-items.md`.

---

**Total deviations:** 0 auto-fixed
**Impact on plan:** Delivered the planned behavior. The only scope expansion was the minimum needed to execute the new seam in production code.

## Issues Encountered

- Full-repo `mix credo --strict` surfaced pre-existing readability failures and an existing unsubscribe-controller scoping warning unrelated to this plan. Scoped strict Credo on the touched files passed cleanly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The unsubscribe controller and router slices can now depend on a single atomic header writer and a lint gate that prevents drift.
- Full-repo strict Credo cleanup remains outstanding outside this plan’s scope.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/11-rfc-8058-list-unsubscribe/11-02-SUMMARY.md`
- Commits verified: `2b03f6d`, `c951310`, `52c39f3`, `afa55ed`
