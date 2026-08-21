---
phase: 156
plan: 05
subsystem: persisted-job-boundaries
tags: [atom-safety, webhook-replay, inbound, oban]
status: complete
requires: [156-04]
provides: [finite-provider-maps, closed-source-decoding]
affects: [webhook-replay, inbound-execution-worker]
tech-stack:
  added: []
  patterns: [literal-finite-decoder, permanent-invalid-job-cancel, warmed-atom-count-regression]
key-files:
  created:
    - lib/mailglass/webhook/provider_name.ex
  modified:
    - lib/mailglass/webhook/replay.ex
    - mailglass_inbound/lib/mailglass_inbound/execution.ex
    - mailglass_inbound/lib/mailglass_inbound/execution/worker.ex
    - test/mailglass/webhook/replay_test.exs
    - mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs
    - mailglass_inbound/test/mailglass_inbound/worker_test.exs
decisions:
  - Core webhook providers are decoded through a five-value literal map; inbound persisted providers use an independent four-value map.
  - Inbound execution accepts only fresh and replay job sources; absent source alone defaults to fresh.
  - Corrupt inbound source values cancel permanently before the worker loads or executes work.
metrics:
  tasks_completed: 2
  tests: 20
  completed: 2026-08-17
---

# Phase 156 Plan 05: Closed Persisted and Job Value Decoding Summary

Persisted provider and Oban source strings now enter Mailglass only through finite literal maps, so corrupt external values cannot grow the BEAM atom table or run downstream work.

## Completed Work

- Added `Mailglass.Webhook.ProviderName` with five explicit core provider encoders/decoders and routed replay through it, retaining `:unknown_provider` for corrupt stored webhook rows.
- Reworked inbound record reconstruction to decode the four inbound provider names before evidence loading and return `{:error, :invalid_job_args}` for corrupt data.
- Replaced inbound worker `String.to_atom/1` source conversion with only `fresh` and `replay`; only absent source gets the existing `:fresh` default.
- Made corrupt source jobs return `{:cancel, :permanent_failure}` before loader or execution seams run.
- Added warmed high-cardinality invalid-value tests that hold `:erlang.system_info(:atom_count)` steady, plus valid-shape and no-execution spies.

## Verification

- `mix test test/mailglass/webhook/replay_test.exs --warnings-as-errors` — 8 tests, 0 failures.
- `cd mailglass_inbound && mix test test/mailglass_inbound/mailbox_execution_test.exs test/mailglass_inbound/worker_test.exs --warnings-as-errors` — 12 tests, 0 failures.
- Core and inbound `mix compile --no-optional-deps --warnings-as-errors` — passed.
- Targeted `mix format --check-formatted` and `git diff --check` — passed.

## TDD Gate Compliance

- RED: provider-map tests failed because `Mailglass.Webhook.ProviderName` did not exist; invalid persisted-provider loading failed with `:not_found`; invalid worker sources incorrectly executed successfully.
- GREEN: `a668142e` implemented finite core/inbound provider decoding; `53ecf326` implemented closed worker-source decoding and permanent cancellation.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- Confirmed the seven listed source and test files exist with the finite decoder changes.
- Confirmed implementation commits `a668142e` and `53ecf326` exist.
