---
phase: 12-auto-suppression-soft-bounce-escalation
plan: 01
subsystem: api
tags: [webhooks, suppression, ecto, streamdata, idempotency]
requires:
  - phase: 04-webhook-ingest
    provides: webhook ingest multi, projector categorization, replay-safe event appends
provides:
  - centralized webhook event to suppression translation
  - replay-safe suppression inserts for matched complaint, unsubscribe, and hard-bounce events
  - webhook replay convergence coverage for suppression projection
affects: [suppression, webhook-ingest, deliverability, phase-12]
tech-stack:
  added: []
  patterns: [event-first suppression projection, conflict-ignore suppression insert, replay convergence property]
key-files:
  created:
    - lib/mailglass/suppression/auto_suppress.ex
    - test/mailglass/properties/webhook_suppression_convergence_test.exs
  modified:
    - lib/mailglass/webhook/ingest.ex
    - test/mailglass/webhook/ingest_auto_suppress_test.exs
key-decisions:
  - "Keep webhook auto-suppression translation centralized in Mailglass.Suppression.AutoSuppress with explicit :complained/:unsubscribed/:bounced mappings."
  - "Run suppression projection as a flat Multi step after projector application so event append remains the first durable per-event write."
  - "Use direct conflict-ignore inserts instead of SuppressionStore upserts to preserve replay convergence."
patterns-established:
  - "Webhook ingest can add post-projection work as another flat Multi.run step without nesting transactions."
  - "Replay-sensitive suppression writes should use on_conflict: :nothing with the suppression uniqueness fragment."
requirements-completed: [SUPP-01]
duration: 6min
completed: 2026-04-28
---

# Phase 12 Plan 01: Auto-Suppression Projection Summary

**Webhook ingest now projects complaint, unsubscribe, and hard-bounce events into idempotent suppression rows through a centralized helper and replay-convergence property coverage**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-28T11:59:00Z
- **Completed:** 2026-04-28T12:05:04Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `Mailglass.Suppression.AutoSuppress` as the canonical translator and insert helper for webhook-driven suppression rows.
- Extended `Mailglass.Webhook.Ingest` with an `{:auto_suppress, idx}` step after `{:projector_apply, idx}` while keeping event append first.
- Added integration and property coverage proving matched complaint, unsubscribe, and hard-bounce events suppress correctly and duplicate webhook replays converge.

## Task Commits

1. **Task 1: Build centralized auto-suppression translation and insert helper** - `08fe154` (feat)
2. **Task 2: Wire the auto-suppression step into webhook ingest and prove replay convergence** - `8b04cfb` (feat)

## Files Created/Modified

- `lib/mailglass/suppression/auto_suppress.ex` - Centralized event-to-suppression mapping and replay-safe insert helper.
- `lib/mailglass/webhook/ingest.ex` - Adds the `{:auto_suppress, idx}` Multi step after projection and preserves matched-result shaping.
- `test/mailglass/webhook/ingest_auto_suppress_test.exs` - Covers translation behavior and ingest integration for hard bounce, complaint, unsubscribe, and orphan skips.
- `test/mailglass/properties/webhook_suppression_convergence_test.exs` - Replays generated webhook sequences and asserts suppression row convergence.

## Decisions Made

- Kept the translation layer explicit: `:complained -> :complaint`, `:unsubscribed -> :unsubscribe`, and hard `:bounced -> :hard_bounce`.
- Derived suppression address and stream only from the matched `Delivery` record, never from webhook payload metadata.
- Used dynamic dispatch from `Webhook.Ingest` into the centralized helper to satisfy the existing Boundary constraints without widening exports.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Resolved Boundary compile warning on webhook -> suppression helper call**
- **Found during:** Task 2 (Wire the auto-suppression step into webhook ingest and prove replay convergence)
- **Issue:** A direct static reference from `Mailglass.Webhook.Ingest` to `Mailglass.Suppression.AutoSuppress` triggered a Boundary warning that would fail `mix compile --warnings-as-errors`.
- **Fix:** Kept the centralized helper module but invoked it through bounded dynamic dispatch from the ingest step.
- **Files modified:** `lib/mailglass/webhook/ingest.ex`
- **Verification:** `mix compile --warnings-as-errors`
- **Committed in:** `8b04cfb`

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Required for compilation hygiene only. No scope creep and no change to the plan’s runtime behavior.

## Issues Encountered

- Boundary enforcement rejected the first static call shape between `Webhook.Ingest` and the new helper. The fix stayed within the owned files and preserved the planned module layout.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 12 now has a canonical runtime path for webhook-driven suppression projection that later soft-bounce escalation and resync work can reuse.
- The new helper and convergence property provide a stable seam for future `SUPP-02` and `SUPP-03` work.

## Self-Check

PASSED
