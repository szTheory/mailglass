---
phase: 41-sendgrid-ingress-and-mailbox-routing
plan: "02"
subsystem: inbound
tags: [inbound, mailbox, execution, routing, tdd]
requires:
  - phase: 41-sendgrid-ingress-and-mailbox-routing
    provides: verified SendGrid/Postmark ingress normalization with durable canonical and evidence persistence
provides:
  - post-commit mailbox execution for fresh ingress requests
  - append-only execution lineage shared by fresh handling and replay
  - failure classification for raises, exits, throws, and invalid mailbox returns
affects: [phase-41, ingress, replay, mailbox-routing]
tech-stack:
  added: []
  patterns: [post-commit mailbox runner, append-only execution lineage, durable-receive-then-execute]
key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/execution.ex
  modified:
    - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
    - mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs
    - mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs
key-decisions:
  - "Mailbox execution stays outside the receive transaction so durable canonical and evidence truth commit before any mailbox side effect runs."
  - "Fresh ingress only executes mailboxes for newly inserted records; duplicate receives acknowledge success without replaying mailbox side effects."
patterns-established:
  - "Ingress persistence returns the canonical record, evidence row, route result, and normalized message so post-commit execution can run without reopening transaction state."
  - "Mailbox failures are normalized into append-only `:failed` execution lineage rows rather than being treated as semantic mailbox outcomes."
requirements-completed: [STORE-02]
duration: 7min
completed: 2026-05-06
---

# Phase 41 Plan 02: Mailbox Routing Summary

**Fresh inbound ingress now executes matched mailboxes only after durable persistence and records every attempt in append-only execution lineage**

## Performance

- **Duration:** 7 min
- **Started:** 2026-05-06T12:43:33-04:00
- **Completed:** 2026-05-06T12:50:41Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Generalized replay history into a shared execution lineage model covering fresh routing, replay, semantic outcomes, and failed runs.
- Added an internal mailbox runner that validates the locked mailbox contract and classifies raises, exits, throws, and invalid returns as execution failures.
- Wired the ingress Plug to execute matched mailboxes only after persistence succeeds and to preserve `200` acknowledgement semantics for `:accept`, `:ignore`, `:reject`, `:bounce`, `:no_match`, and `:failed`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Generalize replay-only history into append-only execution lineage** - `a9c2a69`, `7b5e53f` (test, feat)
2. **Task 2: Add the post-commit mailbox runner and wire fresh ingress execution** - `accdade`, `c1df869` (test, feat)

## Files Created/Modified
- `mailglass_inbound/lib/mailglass_inbound/execution.ex` - Internal runner for fresh mailbox execution and failure classification.
- `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` - Returns the post-commit payload needed for routing and mailbox execution.
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` - Invokes mailbox execution only after durable ingress persistence succeeds.
- `mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs` - Covers matched, unmatched, semantic, and failed execution recording.
- `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` - Proves post-commit execution ordering and `200` acknowledgement semantics.

## Decisions Made

- Kept mailbox execution as an internal post-commit step instead of extending the public mailbox API or widening ingress response semantics.
- Used the append-only execution lineage boundary for both semantic outcomes and failure metadata so the canonical inbound row remains immutable receive truth.

## Verification

- `cd mailglass_inbound && mix test test/mailglass_inbound/replay_test.exs test/mailglass_inbound/mailbox_execution_test.exs --warnings-as-errors` — passed
- `cd mailglass_inbound && mix test test/mailglass_inbound/mailbox_execution_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` — passed

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Parallel verification attempts briefly contended on the shared Mix build lock; both required plan verification commands were rerun to completion without code changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Fresh Postmark and SendGrid ingress now persist receive truth, route mailboxes, and append execution lineage without mutating canonical inbound rows.
- Ready for `41-03` on top of a real post-commit execution path and shared lineage storage.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-02-SUMMARY.md`.
- Task commits `a9c2a69`, `7b5e53f`, `accdade`, and `c1df869` exist in git history.

---
*Phase: 41-sendgrid-ingress-and-mailbox-routing*
*Completed: 2026-05-06*
