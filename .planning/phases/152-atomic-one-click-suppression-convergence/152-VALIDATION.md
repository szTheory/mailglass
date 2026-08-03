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
