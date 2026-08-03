---
phase: 152
slug: atomic-one-click-suppression-convergence
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-03
updated: 2026-08-03
---

# Phase 152 Validation Matrix

This file is the executable evidence index for Phase 152. Run focused commands after each task and the complete gates after Plan 03.

## Task validation

| Plan / task | Evidence | Focused command |
|---|---|---|
| 152-01 Task 1 | First valid POST, Delivery-derived scope, canonical event/suppression, verified conflict sentinel, bounded source/metadata, privacy no-ops | `mix test test/mailglass/compliance/unsubscribe_controller_test.exs --warnings-as-errors` |
| 152-01 Task 2 | Conflict refetch, event-only/suppression-only repair, injected rollback and empty 500 | `mix test test/mailglass/compliance/unsubscribe_controller_test.exs --warnings-as-errors` |
| 152-02 Task 1 | Commit-before-lifecycle/broadcast, separate compatibility Multi, best-effort failure, bounded created-only effects | `mix test test/mailglass/compliance/unsubscribe_controller_test.exs --warnings-as-errors` |
| 152-02 Task 2 | Serial/true-concurrent replay, uniqueness race, tenant isolation, hostile `search_path` | `mix test test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs test/mailglass/schema_prefix_hardening_test.exs --warnings-as-errors && mix verify.schema_prefix` |
| 152-02 Task 3 | Real Outbound preflight matrix for normalization, stream, transactional, and tenant isolation | `mix test test/mailglass/outbound/preflight_test.exs --warnings-as-errors` |
| 152-03 Task 1 | Unsubscribe guide, Lifecycle and Config lifecycle semantics, signature/config compatibility, API response/convergence contract | `mix test test/mailglass/docs/unsubscribe_guide_test.exs test/mailglass/compliance/unsubscribe_test.exs --warnings-as-errors` |
| 152-03 Task 2 | Production procedure, docs drift, and stability drift | `mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors && mix verify.docs.contract && mix verify.stability_contract` |

## Requirement coverage

| Requirement | Plans | Focused evidence |
|---|---|---|
| UNSUB-07 | 152-01, 152-03 | Controller/convergence integration plus docs/config contract tests |
| UNSUB-08 | 152-01, 152-02, 152-03 | Incomplete-pair/conflict tests plus serial and true-concurrent POST property tests |
| UNSUB-09 | 152-02, 152-03 | Real `Mailglass.Outbound.send/1` preflight matrix plus production docs contract |
| UNSUB-10 | 152-02, 152-03 | Callback/broadcast ordering/failure tests plus lifecycle stability contract |
| UNSUB-11 | 152-01, 152-02, 152-03 | Rollback injection, `mix verify.schema_prefix`, tenant/decoy tests, and documented contract |

## Threat coverage

| Threat | Verification |
|---|---|
| T-152-01 | Controller cases reject scope substitution and retain privacy-noop equivalence. |
| T-152-02 | Atomic pair, conflict refetch, incomplete-pair repair, and uniqueness tests. |
| T-152-03 | Invalid/expired/missing exact empty 200 versus injected DB empty 500 assertions. |
| T-152-04 | Named failure injection after transaction steps proves zero partial pair/effects. |
| T-152-05 | Lifecycle construction/returned-Multi failure remains post-commit and non-fatal. |
| T-152-06 | Callback/broadcast capture asserts bounded keys and absence of token/private content. |
| T-152-07 | Serial and barrier-coordinated replay counters prove one created-only emission. |
| T-152-08 | Hostile `search_path`, decoy/absent public rows, and other-tenant controls. |
| T-152-09 | Capturing adapter proves matching preflight blocks before provider boundary. |
| T-152-10 | Docs and stability contract tests bind published claims to runtime behavior. |
| T-152-11 | Docs-contract assertions reject verification procedures that expose sensitive request data. |
| T-152-12 | Lifecycle signature/config tests plus post-commit semantics assertions. |

## Multi-source coverage audit

| Source | ID | Feature / constraint | Plan | Status |
|---|---|---|---|---|
| GOAL | — | Valid RFC 8058 POST converges to tenant-safe stream suppression that immediately blocks matching sends | 01-03 | COVERED |
| REQ | UNSUB-07 | Atomic canonical event and address_stream suppression | 01, 03 | COVERED |
| REQ | UNSUB-08 | Replay/concurrency convergence and no duplicate effects | 01-03 | COVERED |
| REQ | UNSUB-09 | Immediate matching preflight block with scope isolation | 02, 03 | COVERED |
| REQ | UNSUB-10 | Commit before callback/broadcast | 02, 03 | COVERED |
| REQ | UNSUB-11 | Tenant/prefix safety and atomic non-success failure | 01-03 | COVERED |
| CONTEXT | D-01..D-03 | Delivery-only authority, audited lookup, privacy no-op | 01, 03 | COVERED |
| CONTEXT | D-04..D-07 | Atomic identities, replay, canonical conflicts, genuine failure | 01-03 | COVERED |
| CONTEXT | D-08..D-10 | Normalized Delivery-derived stream scope and real preflight | 01-03 | COVERED |
| CONTEXT | D-11..D-14 | Created-only bounded best-effort post-commit effects | 02, 03 | COVERED |
| CONTEXT | D-15..D-17 | Explicit prefix, hostile search_path, rollback/no effects | 01-03 | COVERED |
| CONTEXT | D-18..D-19 | Route/callback compatibility and complete contract matrix | 01-03 | COVERED |
| RESEARCH | — | Flat conflict-safe Multi with canonical prefix-explicit refetches | 01 | COVERED |
| RESEARCH | — | Legacy incomplete-pair repair and verified created sentinel | 01 | COVERED |
| RESEARCH | — | Separate `handle_event(Ecto.Multi.new(), attrs)` compatibility Multi | 02, 03 | COVERED |
| RESEARCH | — | True concurrent sandbox/barrier proof and hostile schema decoys | 02 | COVERED |
| RESEARCH | — | Real Outbound enforcement matrix | 02 | COVERED |

Deferred Phase 153 generated-host/release work, token redesign, new suppression scopes, GET semantics, Phase 151 payload work, and arbitrary-host exactly-once guarantees are intentionally excluded.

## Complete gates

Run in order after all three plans:

1. `mix format --check-formatted`
2. `mix test test/mailglass/compliance/unsubscribe_controller_test.exs test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs test/mailglass/outbound/preflight_test.exs test/mailglass/schema_prefix_hardening_test.exs test/mailglass/docs/unsubscribe_guide_test.exs test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs test/mailglass/compliance/unsubscribe_test.exs --warnings-as-errors`
3. `mix verify.schema_prefix`
4. `mix verify.docs.contract`
5. `mix verify.stability_contract`
6. `mix docs --warnings-as-errors`
7. `mix test --warnings-as-errors`

## Nyquist Audit 2026-08-03

| Metric | Count |
|---|---:|
| Requirements audited | 5 |
| Task samplers audited | 7 |
| Coverage gaps found | 1 |
| Gaps resolved | 1 |
| Escalated | 0 |

### Per-Task Behavioral Evidence

| Task ID | Requirement | Test type | Direct behavioral proof | Command | Status |
|---|---|---|---|---|---|
| 152-01-01 | UNSUB-07, UNSUB-08, UNSUB-11 | integration | First POST derives scope from the persisted Delivery, returns byte-empty 200, writes the canonical pair, and keeps invalid/tampered/expired/missing targets byte-empty 200 no-ops. | `mix test test/mailglass/compliance/unsubscribe_controller_test.exs --warnings-as-errors` | green (within 120-test matrix) |
| 152-01-02 | UNSUB-07, UNSUB-08, UNSUB-11 | integration/negative | Event-only and suppression-only repair, canonical conflict refetch, and injected post-event/post-suppression rollback prove an empty 500 with no partial pair. | `mix test test/mailglass/compliance/unsubscribe_controller_test.exs --warnings-as-errors` | green (within 120-test matrix) |
| 152-02-01 | UNSUB-08, UNSUB-10 | integration | Commit-observing lifecycle, callback/broadcast failure isolation, bounded attrs, and created-only effect assertions exercise post-commit ordering. | `mix test test/mailglass/compliance/unsubscribe_controller_test.exs --warnings-as-errors` | green (within 120-test matrix) |
| 152-02-02 | UNSUB-08, UNSUB-11 | property/integration | Serial generated replays and four-way barrier replays converge to one event/suppression and one effect; hostile `search_path` proves configured-schema-only event and suppression persistence across the insert/conflict-refetch path. | `mix test test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs test/mailglass/schema_prefix_hardening_test.exs --warnings-as-errors` | green (1 property; 4 schema tests) |
| 152-02-03 | UNSUB-09 | integration | A real signed POST followed by `Outbound.send/1` blocks only the matching normalized tenant/address/stream before the adapter, while unrelated-stream, transactional, and other-tenant controls send. | `mix test test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | green (within 120-test matrix) |
| 152-03-01 | UNSUB-07..11 | contract | Public route, byte-empty 200/500, Delivery-derived scope, lifecycle config/signature, and post-commit behavior remain executable documentation contracts. | `mix test test/mailglass/docs/unsubscribe_guide_test.exs test/mailglass/compliance/unsubscribe_test.exs --warnings-as-errors` | green (within 120-test matrix) |
| 152-03-02 | UNSUB-07..11 | contract/smoke | Production and stability contracts require the real one-click/preflight procedure, tenant/schema isolation, bounded support artifacts, and no Phase 153 exactly-once claim. | `mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors` | green (within 120-test matrix) |

### Gap Closed

| Gap ID | Requirement | Finding | Resolution | Verification |
|---|---|---|---|---|
| N-152-01 | UNSUB-11 / D-15..D-16 | The hostile-`search_path` replay test counted only configured/public event rows, so it did not directly prove the suppression insert and conflict-refetch stayed in the configured schema. | Extended `test/mailglass/schema_prefix_hardening_test.exs` to assert one configured-schema `address_stream`/`unsubscribe` suppression and zero public-schema rows after two POSTs. | Focused schema test: 4 tests, 0 failures; complete Phase 152 matrix: 1 property, 120 tests, 0 failures, 1 skipped. |

### Threat and Edge-Probe Audit

| Threats | Executed edge probe | Result |
|---|---|---|
| T-152-01, T-152-03 | Tampered/expired/missing tokens and Delivery-derived scope | Exact byte-empty privacy 200s; no durable event. |
| T-152-02, T-152-07 | Serial replay, four-way concurrent replay, and temporary-suppression promotion race | One canonical event, one active suppression, and one created-only effect. |
| T-152-04 | Injected failure after event and after suppression | Byte-empty 500; zero partial pair and no effects. |
| T-152-05, T-152-06 | Lifecycle/broadcast ordering, callback exception, invalid/failed returned Multi, bounded attrs | Durable pair is visible first; effects are best-effort and token/private payload is absent. |
| T-152-08 | Hostile `search_path`, public-schema absence/decoys, replay conflict path | Configured schema has exactly one event and one suppression; public has zero of both. |
| T-152-09 | Real `Outbound.send/1` after committed one-click POST | Matching preflight stops before Fake adapter; scope-isolation controls reach it. |
| T-152-10..12 | Docs/stability/operator contract sampling | Focused contracts passed and reject sensitive verification artifacts and arbitrary-host exactly-once claims. |

### Feedback Sampling and Gate Results

- Every one of the seven task entries has an automated, non-watch sampler; no sequence of three tasks lacks automated feedback.
- `mix verify.schema_prefix` ran its schema tests (4/4) and follow-up gate (69/69) green, then reported only existing unrelated Credo findings outside Phase 152 ownership. This is a warning on the umbrella command, not a requirement failure.
- The actual complete Phase 152 focused gate ran after the gap closure: **1 property, 120 tests, 0 failures, 1 pre-existing skipped test**.

## Manual-Only Verifications

All Phase 152 requirements have automated behavioral verification. Phase 153 retains generated-host/release proof and arbitrary-host exactly-once claims by explicit scope boundary.

## Validation Sign-Off

- [x] Every UNSUB-07..11 behavior has a directly executed behavioral proof.
- [x] Threat-register probes include privacy, rollback, concurrency, effect isolation, real preflight, and hostile-schema controls.
- [x] One genuine coverage gap was closed with a passing behavioral test.
- [x] No implementation files were modified during this audit.
- [x] No watch-mode commands; sampling continuity is complete.
- [x] Set `wave_0_complete: true`, `nyquist_compliant: true`, and `status: validated`.

**Approval:** validated — Nyquist-compliant
