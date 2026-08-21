---
phase: 157
slug: inbound-database-and-lifecycle-hardening
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-17
validated: 2026-08-21
---

# Phase 157 — Validation Strategy

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit, Ecto/PostgreSQL, deterministic process barriers, query-count/EXPLAIN contracts |
| Inbound focused | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress test/mailglass_inbound/s3_fetcher_test.exs test/mailglass_inbound/router_test.exs test/mailglass_inbound/migrations_test.exs --warnings-as-errors` |
| Core focused | `mix test test/mailglass/webhook test/mailglass/suppression_store test/mailglass/suppression test/mailglass/outbound/preflight_test.exs --warnings-as-errors` |
| Generated host | `MAILGLASS_PATH="$PWD" bash scripts/generated_ecto_host_proof.sh` |
| Full phase gates | `mix ci.full`; `cd mailglass_inbound && mix ci`; both no-optional compiles |

Tests are written red first inside each implementation task. Concurrency uses barriers/injected clocks; query bounds use instrumented stores or telemetry; migration truth uses real PostgreSQL and generated Host.Repo wrappers.

## Plan / Wave Verification Map

| Plan | Wave | Requirements | Focused proof |
|---|---:|---|---|
| 157-01 | 1 | INB-05 | explicit verified value, ordered no-ambient pipeline |
| 157-02 | 2 | INB-02, INB-03 | HEAD-before-GET and closed retry matrix |
| 157-03 | 1 | INB-01, INB-07 | cert single-flight/global cap/limits plus replay-cache bounds |
| 157-04 | 1 | INB-06 | literal macro adversaries plus inherited inbound ETS bounds |
| 157-05 | 3 | INB-04, DATA-01, DATA-02 | V02 mixed-row/backfill/index and durable terminal replay |
| 157-06 | 1 | DATA-03, DATA-04 | optional bulk/fallback and exact batch outcomes |
| 157-07 | 2 | DATA-05 | keyset multi-page resync and bounded upsert |
| 157-08 | 1 | DATA-06, DATA-07 | locked prune batches and parse-once/bulk webhook evidence |
| 157-09 | 4 | DATA-08 | populated generated-host upgrades and migration hashes |

## Wave 0 Requirements

- [ ] Cert-cache injected HTTP/clock/barrier fixtures and response-byte accumulator.
- [ ] Explicit verified-request stale-state/refetch spies and Plug call-order spies.
- [ ] S3 metadata/get counters and closed retry table.
- [ ] Router compile-string side-effect sentinel.
- [ ] V02 mixed legacy/new rows, bounded backfill interruption, query-plan fixture.
- [ ] Instrumented native/legacy suppression stores and forced-small-page resync data.
- [ ] Core pruner concurrency barriers/EXPLAIN fixture and webhook parse/query counters.
- [ ] Generated-host populated V05/V01 fixture and pre-phase shipped-migration hashes.

## Multi-Source Coverage Audit

| Source | ID | Plan | Status |
|---|---|---|---|
| GOAL | secure, bounded, replayable, efficient inbound/data lifecycle | 01-09 | COVERED |
| REQ | INB-01 | 03 | COVERED |
| REQ | INB-02, INB-03 | 02 | COVERED |
| REQ | INB-04 | 05 | COVERED |
| REQ | INB-05 | 01 | COVERED |
| REQ | INB-06 | 04 | COVERED |
| REQ | INB-07 | 03 (plus 04 limiter regression) | COVERED |
| REQ | DATA-01, DATA-02 | 05 | COVERED |
| REQ | DATA-03, DATA-04 | 06 | COVERED |
| REQ | DATA-05 | 07 | COVERED |
| REQ | DATA-06, DATA-07 | 08 | COVERED |
| REQ | DATA-08 | 09 | COVERED |
| CONTEXT | D-01, D-02 | 01 | COVERED |
| CONTEXT | D-03 | 03 | COVERED |
| CONTEXT | D-04, D-05 | 02 | COVERED |
| CONTEXT | D-06 | 05 | COVERED |
| CONTEXT | D-07 | 04 | COVERED |
| CONTEXT | D-08 | 03, 04 | COVERED |
| CONTEXT | D-09, D-10 | 05, 06 | COVERED |
| CONTEXT | D-11 | 06 | COVERED |
| CONTEXT | D-12 | 07 | COVERED |
| CONTEXT | D-13, D-14 | 08 | COVERED |
| CONTEXT | D-15 | 09 | COVERED |
| RESEARCH | explicit verified value / bounded S3 and caches | 01-03 | COVERED |
| RESEARCH | literal decoder / SHA expand-contract | 04-05 | COVERED |
| RESEARCH | positional bulk / paged resync | 06-07 | COVERED |
| RESEARCH | bounded retention / parse-once webhook / real-host migration | 08-09 | COVERED |

Excluded correctly: Phase 158 ownership refactors; Phase 159 broad gates/dependencies; Phase 160 release certification; all admin/operator UI. No `mailglass_admin/` file is owned by any plan.

## Sign-Off

- [x] Every implementation task has an automated command.
- [x] All 15 requirements and D-01..D-15 map to behavior proof.
- [x] Public v2 façades, package independence, Phase 156 behavior, schema prefixes, and shipped migration immutability are explicit invariants.
- [x] Generated-host upgrade proof is load-bearing and cannot be replaced by repo-local TestRepo or hand-written DDL.
- [x] No package installs or human-only verification are required.

## Validation Audit 2026-08-21

Phase verification and the milestone-wide `mix ci` gate confirm the planned automated coverage was implemented and remains green.

| Metric | Count |
|---|---:|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
