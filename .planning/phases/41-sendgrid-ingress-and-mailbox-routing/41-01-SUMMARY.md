---
phase: 41-sendgrid-ingress-and-mailbox-routing
plan: "01"
subsystem: ingress
tags: [sendgrid, inbound, plug, mime, testing]
requires:
  - phase: 40-postmark-ingress-and-replayable-persistence
    provides: verify-first ingress seam, canonical persistence handoff, and Postmark provider patterns
provides:
  - SendGrid provider verification and canonical normalization through the sealed ingress seam
  - Request struct support for provider-specific ingress payload shapes
  - Shared ingress Plug coverage for Postmark and SendGrid
affects: [phase-41, mailbox-execution, replay]
tech-stack:
  added: []
  patterns: [provider-specific ingress request struct, verify-before-tenant-resolution]
key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/ingress/request.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/providers/sendgrid.ex
    - mailglass_inbound/test/mailglass_inbound/ingress/sendgrid_provider_test.exs
  modified:
    - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex
    - mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs
key-decisions:
  - "Kept Postmark on the existing raw-body callback shape while adding a request struct for SendGrid's multipart/raw-MIME ingress facts."
  - "Required the SendGrid raw `email` MIME part and returned operator-helpful config errors instead of degrading to partial multipart parsing."
patterns-established:
  - "Ingress providers can normalize through a sealed provider module while preserving provider-only facts in evidence."
  - "The shared ingress Plug verifies provider auth before tenant resolution regardless of provider-specific request shape."
requirements-completed: [INGRESS-02]
duration: 8min
completed: 2026-05-06
---

# Phase 41: SendGrid Ingress And Mailbox Routing Summary

**SendGrid inbound verification and raw-MIME normalization now flow through the shared ingress Plug without widening the canonical `InboundMessage` contract**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-06T16:32:06Z
- **Completed:** 2026-05-06T16:40:13Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Added a sealed SendGrid provider that enforces shared-secret basic auth and normalizes raw MIME into the locked inbound shape.
- Introduced `MailglassInbound.Ingress.Request` so provider callbacks can carry multipart/raw-MIME facts honestly.
- Extended the shared ingress Plug and tests so SendGrid follows the same verify-first handoff boundary as Postmark.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build the sealed SendGrid provider around explicit auth and raw-MIME-first normalization** - `7c821ea`, `8b68f96` (test, feat)
2. **Task 2: Extend the ingress Plug to support SendGrid without widening the adopter-facing path** - `91c458d` (feat)

_Note: This plan used TDD for the provider path, so Task 1 includes separate RED and GREEN commits._

## Files Created/Modified

- `mailglass_inbound/lib/mailglass_inbound/ingress/request.ex` - Provider-specific ingress request struct for raw-body and multipart carriers.
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/sendgrid.ex` - Shared-secret verification plus raw-MIME parsing and evidence capture for SendGrid.
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` - Shared ingress seam updated to build provider requests and route SendGrid through verify-first handling.
- `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex` - Provider contract context updated for the request seam.
- `mailglass_inbound/test/mailglass_inbound/ingress/sendgrid_provider_test.exs` - Canonical SendGrid auth, MIME, and evidence coverage.
- `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` - End-to-end ingress Plug coverage for SendGrid success and failure paths.

## Decisions Made

- Preserved the existing Postmark callback shape so Phase 40 behavior stays stable while SendGrid uses the request struct seam.
- Kept provider-only fields such as spam verdicts, raw MIME, and attachment blobs in evidence instead of widening `%InboundMessage{}`.
- Returned a config error when SendGrid omits the raw MIME `email` part so operators get an explicit setup failure instead of lossy normalization.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first executor pass stopped after the RED-phase status check, so the remaining GREEN/refactor work was resumed from the existing commits rather than restarted.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The shared ingress seam now accepts truthful SendGrid requests and hands off canonical plus evidence data through the existing persistence boundary.
- Phase 41-02 can build mailbox execution on top of the verified SendGrid/Postmark ingress contract.

---
*Phase: 41-sendgrid-ingress-and-mailbox-routing*
*Completed: 2026-05-06*
