---
status: complete
mode: human-uat
phase: 32-replay-reconcile-hardening
source:
  - 32-VERIFICATION.md
started: 2026-05-05T16:57:48Z
updated: 2026-05-05T20:13:32Z
human_steps_required: 0
automation_deferred:
  - test: "Replay wording and ambiguity flow in the operator UI"
    reason: "Browser-level copy clarity and end-to-end operator flow completion are only partially represented by LiveView assertions."
  - test: "Oban-less maintenance fallback in an adopter-like environment"
    reason: "The code and focused tests verify the contract, but operator comprehension across logs/docs/CLI in a real support workflow still needs a human pass."
---

## Current Test

Validated via a real browser session against the synthetic operator server and
via a no-Oban consumer-context CLI run.

## Tests

### 1. Replay wording and ambiguity flow in the operator UI
expected: Exact-target deliveries read as ready, ambiguous deliveries require an explicit choice, and replay audit rows remain visually distinct with completed/new work or completed/no change wording.
result: [passed] Browser run on 2026-05-05 showed `Replay is ready. One exact webhook target is available for confirmation.`, `Replay is choice required.`, no confirm button until a target was selected (`before=0`, `after=1`), and timeline/header copy rendering `completed · new work` and `completed · no change`.

### 2. Oban-less maintenance fallback in an adopter-like environment
expected: App boot warns that webhook maintenance is manual without Oban, and `mix mailglass.reconcile` completes with linked/still unmatched wording without implying a per-delivery reconcile button.
result: [passed] Consumer-context server boot on 2026-05-05 emitted the manual-maintenance warning, and `mix mailglass.reconcile --tenant-id browser-tenant --batch-size 50` reported `scanned=5 linked=2 still_unmatched=3` with the explicit system-cron wording.

## Summary

total: 2
passed: 2
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None.
