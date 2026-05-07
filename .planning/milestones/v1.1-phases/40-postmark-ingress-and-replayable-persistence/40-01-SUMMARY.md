---
phase: 40-postmark-ingress-and-replayable-persistence
plan: "01"
subsystem: inbound
tags: [postmark, plug, ingress, normalization]
requires:
  - phase: 39
    provides: canonical inbound contract, router DSL, package-local storage foundation
provides:
  - verify-first Postmark ingress plug
  - sealed internal Postmark provider seam
  - exact raw-body capture for inbound verification
affects: [phase-40, phase-41, mailglass_inbound]
tech-stack:
  added: []
  patterns: [verify-first ingress, sealed provider normalization]
key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/ingress/caching_body_reader.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
    - mailglass_inbound/test/mailglass_inbound/ingress/caching_body_reader_test.exs
    - mailglass_inbound/test/mailglass_inbound/ingress/postmark_provider_test.exs
    - mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs
  modified: []
key-decisions:
  - "Kept the provider seam internal and conn-free while letting verify!/3 return evidence-friendly verification facts."
  - "Returned explicit JSON ingress outcomes so duplicates and rejections are honest without implying mailbox execution."
patterns-established:
  - "Inbound provider verification happens before tenant resolution, persistence, or route proof."
requirements-completed: [INGRESS-01]
duration: unknown
completed: 2026-05-06
---

# Phase 40-01 Summary

**Postmark requests now enter through one verify-first plug that captures exact bytes, authenticates before tenancy, and normalizes only into the locked `%MailglassInbound.InboundMessage{}` shape.**

## Performance

- **Duration:** unknown
- **Started:** 2026-05-06
- **Completed:** 2026-05-06
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added the package-local inbound body reader and sealed Postmark provider seam.
- Implemented verify-first plug orchestration with explicit success, rejection, tenant-failure, and config-failure responses.
- Added focused tests proving raw-body capture, Postmark verification, normalization, and plug response mapping.

## Task Commits

No task commits were created in this workspace run.

## Files Created/Modified

- `mailglass_inbound/lib/mailglass_inbound/ingress/caching_body_reader.ex` - captures exact request bytes into `conn.private[:raw_body]`.
- `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex` - defines the internal conn-free provider contract.
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex` - verifies Basic Auth, optionally enforces IP allowlisting, and normalizes Postmark payloads.
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` - verify-first ingress orchestration and explicit JSON response mapping.
- `mailglass_inbound/test/mailglass_inbound/ingress/caching_body_reader_test.exs` - proves raw-body capture behavior.
- `mailglass_inbound/test/mailglass_inbound/ingress/postmark_provider_test.exs` - proves verification and canonical normalization.
- `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` - proves request-level outcomes and persistence handoff shape.

## Decisions Made

- Reused the existing Mailglass webhook choreography, but kept the inbound provider output focused on one canonical message plus internal evidence.
- Lowercased normalized header keys so route compatibility uses the existing matcher semantics predictably.

## Deviations from Plan

None - plan executed within the intended scope.

## Issues Encountered

- The package had no fetched Hex dependencies initially, so `mix deps.get` was required before compile/test verification.

## User Setup Required

None - no external service configuration required for the codebase itself.

## Next Phase Readiness

Plan 40-02 can now persist verified and normalized Postmark ingress through a single transaction boundary.

---
*Phase: 40-postmark-ingress-and-replayable-persistence*
*Completed: 2026-05-06*
