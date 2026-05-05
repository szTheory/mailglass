---
phase: 12-auto-suppression-soft-bounce-escalation
plan: 06
subsystem: compliance
tags: [suppression, postgres, webhooks, ecto, gdpr]
requires:
  - phase: 12-03
    provides: complaint and soft-bounce suppression semantics
  - phase: 12-05
    provides: public suppression telemetry and error context
provides:
  - public suppression removal guardrails for permanent reasons
  - complaint permanence validation at the changeset and Postgres layers
  - operator guidance for durable complaint suppression handling
affects: [suppression, webhook-operators, migrations, compliance]
tech-stack:
  added: []
  patterns: [tenant-scoped suppression removal, belt-and-suspenders complaint permanence]
key-files:
  created: [priv/repo/migrations/00000000000004_mailglass_v03.exs, .planning/phases/12-auto-suppression-soft-bounce-escalation/12-06-SUMMARY.md]
  modified: [lib/mailglass/suppression.ex, lib/mailglass/suppression/entry.ex, guides/webhooks.md, test/mailglass/suppression_test.exs, test/mailglass/suppression/entry_test.exs]
key-decisions:
  - "Used Mailglass.SendError type :preflight_rejected for permanent removal rejections to stay within the existing public error hierarchy."
  - "Added the missing repo wrapper migration for V03 because the complaint permanence constraint could not reach the test database otherwise."
patterns-established:
  - "Permanent suppression reasons reject removal through the public API instead of silently deleting rows."
  - "Complaint permanence is enforced in both Entry changesets and the underlying Postgres schema."
requirements-completed: [SUPP-05]
duration: 4min
completed: 2026-04-28
---

# Phase 12 Plan 06: Permanent complaint suppression guardrails for API removal, schema validation, and operator retention guidance

**Tenant-scoped suppression removal now rejects complaint and unsubscribe rows, complaint expiries are blocked before insert and in Postgres, and the webhook guide documents why complaint suppression outlives deletable source evidence.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-28T12:37:00Z
- **Completed:** 2026-04-28T12:40:48Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Added `Mailglass.Suppression.remove/2` with explicit permanent-reason rejection for complaint and unsubscribe suppressions.
- Enforced complaint permanence in `Mailglass.Suppression.Entry` so complaint rows cannot carry `expires_at`.
- Documented the GDPR/retention contract that source payload evidence may be deleted while the complaint suppression row remains durable.

## Task Commits

1. **Task 1: Add the public removal API and permanent-reason guards** - `864da90` (test), `c826622` (feat)
2. **Task 2: Enforce complaint permanence in Postgres and document the operator rule** - `e2cd4b7` (test), `7f83ed9` (feat)

## Files Created/Modified
- `lib/mailglass/suppression.ex` - Adds the public tenant-scoped removal API and structured permanent-reason rejection.
- `lib/mailglass/suppression/entry.ex` - Rejects complaint rows that attempt to set `expires_at`.
- `guides/webhooks.md` - Explains the durable complaint suppression contract for operators.
- `test/mailglass/suppression_test.exs` - Covers removal rejection and deletion of removable suppression reasons.
- `test/mailglass/suppression/entry_test.exs` - Covers complaint permanence at the changeset and DB layers.
- `priv/repo/migrations/00000000000004_mailglass_v03.exs` - Applies V03 to the test repo so the complaint permanence constraint is exercised.

## Decisions Made
- Used the existing `Mailglass.SendError` hierarchy for removal rejection instead of introducing a new public error type in this plan.
- Kept suppression removal tenant-scoped and explicit; there is no silent delete or re-consent path.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added the missing repo wrapper migration for V03**
- **Found during:** Task 2
- **Issue:** `priv/repo/migrations/` had no wrapper to advance the test database from V02 to V03, so the complaint permanence CHECK constraint in `lib/mailglass/migrations/postgres/v03.ex` never reached the test schema.
- **Fix:** Added `priv/repo/migrations/00000000000004_mailglass_v03.exs` to route the test repo through `Mailglass.Migration.up/0` and `down(version: 2)`.
- **Files modified:** `priv/repo/migrations/00000000000004_mailglass_v03.exs`
- **Verification:** `mix test test/mailglass/suppression/entry_test.exs test/mailglass/suppression_test.exs`
- **Committed in:** `7f83ed9`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required for correctness. No scope creep beyond making the planned Postgres invariant testable.

## Issues Encountered
None beyond the missing V03 wrapper migration, which was fixed inline.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Permanent complaint suppression semantics are enforced at the API, changeset, and database layers.
- Operator documentation now explains why complaint suppression rows outlive deletable source data.

## Self-Check: PASSED
- Found summary file on disk.
- Verified all `12-06` commits exist in git history.
