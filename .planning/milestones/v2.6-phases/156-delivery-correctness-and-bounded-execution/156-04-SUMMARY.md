---
phase: 156
plan: 04
subsystem: delivery-observability
tags: [swoosh, oban, privacy, telemetry, tracking]
status: complete
requires: [156-03]
provides: [closed-retry-classification, private-provider-errors, truthful-tracking-telemetry]
affects: [outbound, swoosh-adapter, oban-worker, tracking]
tech-stack:
  added: []
  patterns: [closed-retry-table, finite-oban-outcomes, injected-ledger-seam, telemetry-acknowledgements]
key-files:
  created: []
  modified:
    - lib/mailglass/adapters/swoosh.ex
    - lib/mailglass/errors/send_error.ex
    - lib/mailglass/outbound/worker.ex
    - lib/mailglass/tracking/plug.ex
    - docs/api_stability.md
    - test/mailglass/adapters/swoosh_test.exs
    - test/mailglass/error_test.exs
    - test/mailglass/outbound/worker_test.exs
    - test/mailglass/outbound/telemetry_test.exs
    - test/mailglass/tracking/plug_test.exs
decisions:
  - Oban 2.23.1 permanent failures return `{:cancel, :permanent_failure}`; the finite reason avoids provider data in Oban logs.
  - Swoosh retries only known transport/timeouts, HTTP 429, and HTTP 500..599; ordinary HTTP 400..499 and unknown shapes fail closed permanently.
  - Tracking ledger outcomes select recorded versus failed telemetry while valid HTTP tracking responses remain fail-open.
metrics:
  tasks_completed: 2
  tests: 55
  completed: 2026-08-17
---

# Phase 156 Plan 04: Delivery Truth and Privacy Summary

Provider failures, Oban outcomes, error representations, and tracking telemetry now report bounded, privacy-safe truth rather than retrying or claiming success by default.

## Completed Work

- Replaced adapter-type retry behavior with an explicit `SendError.retry_class` decision table. Known transport failures, timeouts, HTTP 429, and HTTP 5xx retry; ordinary 4xx and unrecognized provider shapes stop permanently.
- Verified the locked local Oban 2.23.1 contract: `{:cancel, reason}` ends retrying. Permanent worker outcomes use the finite `:permanent_failure` reason.
- Removed provider response body and arbitrary reason-text construction from Swoosh error context and exception cause. Adversarial body, recipient, subject, and rendered-body sentinels are absent from context, message, JSON, and persisted `last_error`.
- Kept `SendError` JSON fields exactly `type`, `message`, and `context`, while documenting additive non-JSON `retry_class` behavior.
- Kept `Mailglass.Outbound.call_adapter/2` as the sole provider-dispatch span owner; direct Swoosh calls no longer add a duplicate nested span.
- Added an internal tracking ledger seam and outcome-aware telemetry: success emits `recorded`; returned error, unexpected result, and raised exception emit a finite `failed` class while preserving 200 GIF and 302 redirect behavior.

## Verification

- `mix test test/mailglass/error_test.exs test/mailglass/adapters/swoosh_test.exs test/mailglass/outbound/worker_test.exs test/mailglass/outbound/telemetry_test.exs test/mailglass/tracking/plug_test.exs --warnings-as-errors` — 55 tests executed, 0 failures.
- `mix format --check-formatted` — passed.
- `mix compile --no-optional-deps --warnings-as-errors` — passed.
- `git diff --check` — passed.

## TDD Gate Compliance

- RED: closed retry-class, provider sentinel, and tracking-outcome tests failed against the prior retry-all / body-preview / always-recorded behavior.
- GREEN: `f0c398a1` implemented retry and privacy behavior; `06fc8dea` implemented single-span and outcome-coupled tracking behavior.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected persisted-error test use of the narrow Repo facade.
- **Found during:** Task 1 verification.
- **Issue:** `Mailglass.Repo` intentionally exposes `get/2`, not `get!/2`.
- **Fix:** Used `Repo.get/2` in the persistence-sentinel regression test.
- **Files modified:** `test/mailglass/outbound/worker_test.exs`.
- **Commit:** `f0c398a1`.

## Self-Check: PASSED

- Confirmed all ten plan-listed production, test, and stability-document files were updated as applicable.
- Confirmed implementation commits `f0c398a1` and `06fc8dea` exist.
