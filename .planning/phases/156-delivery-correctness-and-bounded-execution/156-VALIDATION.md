---
phase: 156
slug: delivery-correctness-and-bounded-execution
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-16
---

# Phase 156 — Validation Strategy

> Deterministic proof for concurrent resource bounds, database/queue atomicity, fallback admission, retry/privacy behavior, telemetry truth, and finite decoding.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit, Ecto/PostgreSQL, Oban testing, `:telemetry_test` |
| Core quick run | `mix test test/mailglass/rate_limiter_test.exs test/mailglass/outbound/deliver_many_test.exs test/mailglass/adapters/swoosh_test.exs test/mailglass/tracking/plug_test.exs --warnings-as-errors` |
| Inbound quick run | `cd mailglass_inbound && mix test test/mailglass_inbound/rate_limiter_test.exs test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/worker_test.exs --warnings-as-errors` |
| Full package gates | `mix ci` and `cd mailglass_inbound && mix ci` |
| No-optional gate | `mix compile --no-optional-deps --warnings-as-errors` |
| Feedback target | Focused commands under 60 seconds; full package gates at phase verification |

## Sampling Rate

- After every task: run its exact focused command.
- After each wave: run all focused commands introduced through that wave plus `mix format --check-formatted`.
- Before phase verification: run both full package gates and the no-optional compile from a clean build.
- Concurrency proofs use barriers, injected clocks, monitored processes, or telemetry acknowledgements—never elapsed sleeps or permissive final states.

## Per-Task Verification Map

| Task ID | Wave | Requirements | Behavior under proof | Automated command | Wave-0 prerequisite |
|---------|------|--------------|----------------------|-------------------|---------------------|
| 156-01-01 | 1 | EXEC-01, EXEC-02 | Exact core refill success count, retained fraction, idle purge, full-table denial, sweep/restart | `mix test test/mailglass/rate_limiter_test.exs test/mailglass/rate_limiter_supervision_test.exs --warnings-as-errors` | Add injected-clock/barrier/cap fixtures before engine edits |
| 156-01-02 | 1 | EXEC-01, EXEC-02 | Inbound parity through shared engine with package-local table/config/error | `cd mailglass_inbound && mix test test/mailglass_inbound/rate_limiter_test.exs --warnings-as-errors` | Extend existing inbound limiter test first |
| 156-02-01 | 2 | EXEC-03 | Delivery/event/rendered metadata/job commit together; job failure rolls all back | `mix test test/mailglass/outbound/deliver_many_test.exs --warnings-as-errors` | Add named Oban Multi failure seam and DB count assertions first |
| 156-02-02 | 2 | EXEC-03 | Identical/mixed replay adds jobs/events only for newly inserted rows | `mix test test/mailglass/outbound/deliver_many_test.exs test/mailglass/outbound/delivery_idempotency_key_test.exs --warnings-as-errors` | Extend replay fixtures first |
| 156-03-01 | 3 | EXEC-04 | Ten held core tasks accepted, eleventh/dead supervisor fails typed; batch projection truthful | `mix test test/mailglass/application_test.exs test/mailglass/error_test.exs test/mailglass/outbound/deliver_later_test.exs test/mailglass/outbound/deliver_many_test.exs --warnings-as-errors` | Add supervisor barrier helper and error contract tests first |
| 156-03-02 | 3 | EXEC-04 | Inbound ten-child cap and typed saturation/failure result | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs --warnings-as-errors` | Extend existing injected supervisor seam first |
| 156-04-01 | 4 | EXEC-05, EXEC-06 | Retry decision table, Oban retry/discard, response/recipient/message sentinel absent everywhere | `mix test test/mailglass/error_test.exs test/mailglass/adapters/swoosh_test.exs test/mailglass/outbound/worker_test.exs --warnings-as-errors` | Add status matrix, worker outcome, JSON/last_error sentinel cases first |
| 156-04-02 | 4 | EXEC-07 | One dispatch span; tracking success/failure telemetry follows ledger while response is fail-open | `mix test test/mailglass/outbound/telemetry_test.exs test/mailglass/adapters/swoosh_test.exs test/mailglass/tracking/plug_test.exs --warnings-as-errors` | Add ledger injection and telemetry acknowledgements first |
| 156-05-01 | 5 | EXEC-08 | Core/inbound stored-provider finite mapping and unchanged warmed atom count | `mix test test/mailglass/webhook/replay_test.exs --warnings-as-errors && (cd mailglass_inbound && mix test test/mailglass_inbound/mailbox_execution_test.exs --warnings-as-errors)` | Add supported/invalid/atom-count cases first |
| 156-05-02 | 5 | EXEC-08 | Job source finite mapping, missing default, invalid stop-before-execute, unchanged atom count | `cd mailglass_inbound && mix test test/mailglass_inbound/worker_test.exs --warnings-as-errors` | Add worker source table and invalid execution spy first |
| 156-06-01 | 6 | EXEC-01 | Core absent-table recovery plus restart and exact 50-of-100 contended admission | `mix test test/mailglass/rate_limiter_test.exs test/mailglass/rate_limiter_supervision_test.exs --warnings-as-errors` | Add monitored restart/barrier regression before engine/owner edits |
| 156-06-02 | 6 | EXEC-01 | Inbound lifecycle parity and five consecutive combined focused green runs | `cd mailglass_inbound && for run in 1 2 3 4 5; do mix test test/mailglass_inbound/rate_limiter_test.exs test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/mailbox_execution_test.exs test/mailglass_inbound/worker_test.exs --warnings-as-errors || exit 1; done` | Add exact 50-of-100 restart regression before inbound owner edit |

## Wave 0 Requirements

- [ ] Deterministic clock and release-barrier cases in both existing rate-limiter suites.
- [ ] Test-only small-cap/expiry options for both table owners; production defaults remain 100,000 / one hour / 60 seconds.
- [ ] Named Oban Multi failure seam and pre/post row/event/job count assertions in `deliver_many_test.exs`.
- [ ] Core/inbound supervisor occupancy barriers with release cleanup.
- [ ] `SendError` compatibility, provider decision table, worker outcome, and privacy sentinel cases.
- [ ] Tracking ledger-result injection plus success/failure telemetry handlers.
- [ ] Supported/invalid provider/source tables plus warmed atom-count assertions.
- [ ] Real core/inbound owner-restart plus 100-caller/50-capacity barriers and absent-table owner-call cases.

Wave 0 is performed test-first within each corresponding task; no implementation precedes its failing behavior proof.

## Multi-Source Coverage Audit

| Source | ID | Feature / constraint | Plan | Status |
|--------|----|----------------------|------|--------|
| GOAL | — | Accurate, atomic, private, bounded delivery under concurrency/failure/saturation | 01–05 | COVERED |
| REQ | EXEC-01 | Exact concurrent refill, fractional retention, and lifecycle/contention closure | 01, 06 | COVERED |
| REQ | EXEC-02 | Idle eviction, bounded ETS, fail closed | 01 | COVERED |
| REQ | EXEC-03 | Delivery/event/private metadata/job atomicity | 02 | COVERED |
| REQ | EXEC-04 | Bounded honest fallback | 03 | COVERED |
| REQ | EXEC-05 | Closed provider retry/discard | 04 | COVERED |
| REQ | EXEC-06 | Privacy-safe serialized/persisted errors | 04 | COVERED |
| REQ | EXEC-07 | Truthful fail-open tracking telemetry | 04 | COVERED |
| REQ | EXEC-08 | Finite persisted/job decoders | 05 | COVERED |
| CONTEXT | D-01..D-04 | Shared CAS engine, fixed point, exact bounds/admission | 01 | COVERED |
| CONTEXT | D-05 | One Oban transaction | 02 | COVERED |
| CONTEXT | D-06..D-07 | Ten-child fallback and additive error contract | 03 | COVERED |
| CONTEXT | D-08..D-11 | Retry, privacy, telemetry, one span | 04 | COVERED |
| CONTEXT | D-12 | Finite mappings | 05 | COVERED |
| RESEARCH | Patterns 1–2 / Pitfall 1 | Exact CAS plus owner-mediated missing-key admission | 01 | COVERED |
| RESEARCH | Pattern 3 / Pitfall 2 / private payload question | Multi job insertion; rendered delivery metadata is current private payload | 02 | COVERED |
| RESEARCH | Pattern 4 / Pitfall 5 | Bounded Task supervisor and deterministic barriers | 03 | COVERED |
| RESEARCH | Patterns 5–6 / Pitfalls 3–4 | Retry/privacy/telemetry outcome coupling | 04 | COVERED |
| RESEARCH | Finite decoder rules | Core replay and inbound provider/source conversion | 05 | COVERED |

Excluded correctly: certificate/S3/dead-evidence work, database lifecycle, broad architecture factoring, repository-wide gates, release certification, all admin/operator UI, and non-persisted/UI/compile-time atom conversions.

## Manual-Only Verifications

None. All Phase 156 behavior is automatable locally.

## Validation Sign-Off

- [x] Every implementation task has a fresh automated command.
- [x] Every requirement and locked decision maps to an executable test path.
- [x] Transaction failure, saturation, privacy leak, false telemetry, and atom-growth negative controls are explicit.
- [x] No sleep-based or permissive-state acceptance is allowed.
- [x] Independent package façades/releases and no-optional compilation are preserved.
- [x] Admin/operator UI is absent from every file list.
- [x] `nyquist_compliant: true` is set.

**Approval:** ready for Wave-0-first execution.
