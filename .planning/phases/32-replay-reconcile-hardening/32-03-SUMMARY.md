---
phase: 32-replay-reconcile-hardening
plan: 03
requirements-completed: [MAT-01]
completed: 2026-05-05
---

# Phase 32 Plan 32-03 Summary

## Outcome

Webhook reconciliation now runs through one canonical
`Mailglass.Webhook.Reconciler.reconcile/2` function whether Oban is
installed or not. Oban-backed installs can still schedule background
sweeps through the worker entrypoint, while Oban-less installs can run
the same maintenance sweep via `mix mailglass.reconcile` and get honest
`linked` versus `still unmatched` results.

## Changes

- Refactored `Mailglass.Webhook.Reconciler` so `reconcile/2` is always
  compiled, while `perform/1` remains optional-dep gated behind Oban.
  After phase verification exposed a consumer compile failure, rewrote
  the module to use the same top-level conditional definition pattern
  as the other Oban-optional modules so adopter projects compile cleanly
  without `Oban.Worker`.
- Updated `Mailglass.Application` warning copy to describe the truthful
  fallback contract: no background maintenance without Oban, but manual
  reconcile and prune tasks still work and should be scheduled via
  system cron or another job runner.
- Updated `mix mailglass.reconcile` to call the canonical reconciler in
  both modes and report `scanned`, `linked`, and `still_unmatched`
  counts instead of exiting when Oban is absent.
- Extended `test/mailglass/webhook/reconciler_test.exs` so the
  append-only reconcile behavior remains covered regardless of worker
  availability, and added
  `test/mix/tasks/mailglass_reconcile_test.exs` for Oban-present and
  Oban-absent task output semantics.
- Aligned `guides/webhooks.md` and `guides/webhook-troubleshooting.md`
  with the background-first maintenance story and explicit
  Oban-less/system-cron fallback guidance.

## Verification

- `mix test test/mailglass/webhook/reconciler_test.exs test/mix/tasks/mailglass_reconcile_test.exs --warnings-as-errors`
- `mix compile --no-optional-deps --warnings-as-errors`
- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors`
- `rg -n "mailglass\\.reconcile|system cron|linked|still unmatched|Oban" lib/mailglass/application.ex lib/mix/tasks/mailglass.reconcile.ex guides/webhooks.md guides/webhook-troubleshooting.md`

## Deviations

- The initial reconcile refactor passed root tests but still broke a
  consumer compile path without Oban. Verification caught the issue, and
  the phase was corrected in-place by switching `reconciler.ex` to the
  established top-level optional-dependency stub pattern.

## Commits

- `f964dae` — `fix(32-03): unify reconcile maintenance path`
- `cabc145` — `fix(32-03): align reconcile fallback docs and tests`
