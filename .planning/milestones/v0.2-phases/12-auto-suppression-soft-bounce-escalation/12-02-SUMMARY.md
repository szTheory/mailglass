---
phase: 12-auto-suppression-soft-bounce-escalation
plan: 02
subsystem: testing
tags: [credo, lint, webhooks, ast, tdd]
requires:
  - phase: 12-auto-suppression-soft-bounce-escalation
    provides: webhook ingest auto suppression step after projector apply
provides:
  - webhook ingest event-first ordering Credo guard
  - targeted AST regression coverage for suppression-before-event refactors
affects: [webhook-ingest, suppression, lint, phase-12]
tech-stack:
  added: []
  patterns: [module-scoped Credo AST traversal, event-first webhook ordering lint]
key-files:
  created:
    - credo_checks/multi_event_first_in_webhook_ingest.ex
    - test/mailglass/credo/multi_event_first_in_webhook_ingest_test.exs
  modified:
    - .credo.exs
key-decisions:
  - "Scope the lint guard narrowly to Mailglass.Webhook.Ingest instead of broad repo-wide text matching."
  - "Verify the ordering contract through AST markers for event append, projector categorize/apply, and auto suppress steps."
patterns-established:
  - "Mailglass Credo checks should follow the existing SourceFile.ast plus Macro.traverse pattern used by other custom checks."
  - "Webhook safety invariants that depend on code ordering can be enforced at lint time with focused AST markers."
requirements-completed: [SUPP-01]
duration: 5min
completed: 2026-04-28
---

# Phase 12 Plan 02: Event-First Webhook Ingest Lint Guard Summary

**A targeted Credo check now fails when webhook ingest moves suppression writes ahead of the durable event append and projector path**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-28T12:08:05Z
- **Completed:** 2026-04-28T12:13:02Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Added `Mailglass.Credo.MultiEventFirstInWebhookIngest` to enforce event-first ordering inside `Mailglass.Webhook.Ingest`.
- Registered the check in `.credo.exs` so `mix credo --strict` runs it with the rest of the repo’s custom lint rules.
- Added focused regression coverage with one valid snippet and one invalid suppression-before-event snippet.

## Task Commits

1. **Task 1: Implement and register the event-first ingest Credo check** - `3910486` (test), `ed6bd39` (feat)

## Files Created/Modified

- `credo_checks/multi_event_first_in_webhook_ingest.ex` - Custom Credo check that traverses the ingest AST and enforces the required ordering markers.
- `.credo.exs` - Registers the new check in strict Credo runs.
- `test/mailglass/credo/multi_event_first_in_webhook_ingest_test.exs` - Covers valid and invalid AST orderings.
- `.planning/phases/12-auto-suppression-soft-bounce-escalation/12-02-SUMMARY.md` - Execution record for this plan.

## Decisions Made

- Kept the check module-specific so unrelated `Ecto.Multi` pipelines elsewhere in the repo are not linted by accident.
- Used AST marker ordering instead of string scanning so the guard stays tied to real Elixir syntax.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix credo --strict` on a single temporary fixture emits expected module redefinition warnings because the repo loads custom checks from `credo_checks/`; they did not affect the custom-check verification result.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Webhook ingest now has a lint-time guard preventing future suppression-before-event regressions.
- Later Phase 12 plans can rely on this invariant when extending suppression behavior.

## Self-Check

PASSED
