---
phase: 41-sendgrid-ingress-and-mailbox-routing
plan: "03"
subsystem: inbound
tags: [sendgrid, replay, docs, dedupe, execution]
requires:
  - phase: 41-sendgrid-ingress-and-mailbox-routing
    provides: verified SendGrid ingress plus post-commit mailbox execution and append-only execution lineage
provides:
  - SendGrid duplicate collapse on raw MIME fingerprinting
  - truthful replay over stored canonical and evidence truth
  - docs-contract proof for second-provider and replay posture
affects: [phase-41, replay, docs, operator-trust]
tech-stack:
  added: []
  patterns: [provider-specific dedupe anchors, replay-over-stored-truth, docs-contract enforcement]
key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/internal/replay.ex
    - mailglass_inbound/priv/repo/migrations/20260506220000_add_sendgrid_fingerprint_and_replay_contract_fields.exs
    - mailglass_inbound/docs/sendgrid_ingress.md
  modified:
    - mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
    - mailglass_inbound/lib/mailglass_inbound/inbound_records.ex
    - mailglass_inbound/lib/mailglass_inbound/inbound_records/execution_run.ex
    - mailglass_inbound/README.md
    - mailglass_inbound/docs/api_stability.md
    - mailglass_inbound/test/mailglass_inbound/replay_test.exs
    - mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
key-decisions:
  - "SendGrid duplicate truth anchors on raw MIME fingerprinting instead of overloading `provider_message_id`."
  - "Replay remains an internal rerun over stored canonical plus evidence truth and fails explicitly when prior matched mailbox identity is unavailable."
patterns-established:
  - "Replay resolves mailbox identity from the latest fresh matched execution lineage row rather than consulting mutable router state."
  - "Docs-contract tests enforce the exact shipped provider, replay, and verification posture so future docs drift cannot widen the public contract."
requirements-completed: [INGRESS-02, STORE-02]
duration: 10min
completed: 2026-05-06
---

# Phase 41 Plan 03: Replay And Contract Proof Summary

**SendGrid dedupe now keys off raw MIME truth, replay reruns stored inbound truth honestly, and the second-provider docs are locked by contract tests**

## Performance

- **Duration:** 10 min
- **Started:** 2026-05-06T16:54:31Z
- **Completed:** 2026-05-06T17:04:11Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Added provider-specific SendGrid duplicate collapse and an internal replay seam that reruns stored canonical plus evidence truth instead of faking a fresh receive.
- Extended execution lineage and replay tests so missing prior mailbox identity fails explicitly rather than silently rerouting.
- Published Phase 41 SendGrid and replay posture in package docs and locked it with docs-contract assertions.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add provider-specific SendGrid dedupe and truthful replay execution** - `ab1bc23`, `8d6f33b` (test, feat)
2. **Task 2: Publish honest second-provider docs and contract proof** - pending closeout commit in current worktree

## Files Created/Modified

- `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` - Internal replay runner over stored canonical and evidence truth.
- `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` - SendGrid-specific dedupe anchor on raw MIME fingerprints.
- `mailglass_inbound/priv/repo/migrations/20260506220000_add_sendgrid_fingerprint_and_replay_contract_fields.exs` - Migration for SendGrid fingerprint and replay support fields.
- `mailglass_inbound/docs/sendgrid_ingress.md` - Canonical SendGrid operator/adopter documentation.
- `mailglass_inbound/README.md` - Phase 41 package posture and second-provider execution story.
- `mailglass_inbound/docs/api_stability.md` - Stable/internal/deferred contract inventory updated for Phase 41.
- `mailglass_inbound/test/mailglass_inbound/replay_test.exs` - Duplicate, replay, and mailbox-default coverage.
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` - Contract assertions for SendGrid, replay, and verification claims.

## Decisions Made

- Kept replay as a package-local capability so stored-truth reruns ship without widening the stable API.
- Treated SendGrid raw MIME as the durable duplicate anchor, which keeps provider retries from triggering a second canonical receive or mailbox run.

## Verification

- `cd mailglass_inbound && mix test test/mailglass_inbound/replay_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` — passed
- `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs test/mailglass_inbound/replay_test.exs --warnings-as-errors` — passed

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The docs lane initially failed on exact string expectations for the SendGrid contract wording; the final wording was tightened to match the shipped posture without widening claims.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 41 now has truthful two-provider ingress, post-commit mailbox execution, replay semantics over stored truth, and docs/tests that lock the contract.
- Phase 42 can build async execution and adopter/operator proof on top of a complete honest inbound core slice.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-03-SUMMARY.md`.
- Task 1 commits `ab1bc23` and `8d6f33b` exist in git history.
- Both plan verification commands pass from the current workspace state.

---
*Phase: 41-sendgrid-ingress-and-mailbox-routing*
*Completed: 2026-05-06*
