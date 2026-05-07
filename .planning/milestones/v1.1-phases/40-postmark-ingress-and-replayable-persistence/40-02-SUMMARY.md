---
phase: 40-postmark-ingress-and-replayable-persistence
plan: "02"
subsystem: database
tags: [postmark, persistence, ecto, idempotency]
requires:
  - phase: 40-01
    provides: verified Postmark ingress handoff and canonical normalized inbound message
provides:
  - canonical plus evidence persistence seam
  - Postmark ingress idempotency index
  - narrow route-compatibility proof after commit
affects: [phase-40, phase-41, mailglass_inbound]
tech-stack:
  added: []
  patterns: [single transaction persistence, duplicate-safe ingress]
key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
    - mailglass_inbound/priv/repo/migrations/20260506180000_add_postmark_ingress_idempotency.exs
    - mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs
  modified:
    - mailglass_inbound/lib/mailglass_inbound/repo.ex
    - mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex
provides-patterns:
  - duplicate-safe ingress persistence
requirements-completed: [INGRESS-01, STORE-01]
duration: unknown
completed: 2026-05-06
---

# Phase 40-02 Summary

**Verified Postmark ingress now persists as one canonical row plus one linked evidence row, collapses duplicates on the provider idempotency anchor, and returns route-compatibility proof without starting mailbox execution.**

## Performance

- **Duration:** unknown
- **Started:** 2026-05-06
- **Completed:** 2026-05-06
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added the inbound persistence seam that writes canonical and evidence truth in one transaction.
- Enforced Postmark duplicate collapse with a partial unique index on `(tenant_id, provider, provider_message_id)`.
- Added tests proving inserted versus duplicate semantics and no fresh-ingress replay lineage writes.

## Task Commits

No task commits were created in this workspace run.

## Files Created/Modified

- `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` - canonical/evidence persistence with duplicate detection and route proof.
- `mailglass_inbound/priv/repo/migrations/20260506180000_add_postmark_ingress_idempotency.exs` - partial unique index for duplicate-safe Postmark ingress.
- `mailglass_inbound/lib/mailglass_inbound/repo.ex` - extended package repo facade with `one/2` and `multi/2`.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex` - added duplicate constraint wiring for the new idempotency index.
- `mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs` - verifies atomic storage, duplicate collapse, and route-proof behavior.

## Decisions Made

- Kept route compatibility as a post-transaction proof so matcher behavior cannot affect durability.
- Left `raw_mime` nil unless the provider supplies it directly, rather than reconstructing MIME from parsed fields.

## Deviations from Plan

None - plan executed within the intended scope.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 40-03 can now document the real ingress/storage slice and lock it with docs-contract assertions.

---
*Phase: 40-postmark-ingress-and-replayable-persistence*
*Completed: 2026-05-06*
