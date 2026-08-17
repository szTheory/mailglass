---
phase: 157-inbound-database-and-lifecycle-hardening
verified_at: 2026-08-17T06:47:15-04:00
status: gaps_found
requirements_checked: [INB-01, INB-02, INB-03, INB-04, INB-05, INB-06, INB-07, DATA-01, DATA-02, DATA-03, DATA-04, DATA-05, DATA-06, DATA-07, DATA-08]
---

# Phase 157 Verification

## Goal-backward verdict

**Gaps found.** The implemented source and focused plan evidence cover the intended controls, including the final SES/migration fixes (`daee21c6`, `04c9a8e7`, `80f1fc4c`). However, the final combined core verification command was not clean: after migration tests recreate `citext`, later database tests failed because Postgrex retained a stale type OID. Inbound verification was paused to avoid concurrent shared-database execution and has not been rerun after the final Plan 09 commit. Phase completion should therefore remain unconfirmed until isolated, ordered core and inbound suites pass.

## Requirement evidence

| Requirement | Verdict | Live evidence |
|---|---|---|
| INB-01 | Implemented, final suite pending | `mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex`, `s3_fetcher.ex`, and core `webhook/providers/ses/cert_cache*` enforce owner-mediated single flight, finite cache, strict URL policy, timeout and capped streaming body. `daee21c6` activates the final response cap. |
| INB-02 | Implemented, final suite pending | `mailglass_inbound/lib/mailglass_inbound/s3_fetcher.ex` and `s3_fetcher/ex_aws_s3.ex` use metadata-first `head/3`, configured 40 MiB cap, and post-fetch guard. |
| INB-03 | Implemented, final suite pending | `mailglass_inbound/lib/mailglass_inbound/s3_fetcher/retry.ex` has the closed transient/permanent classifier; Plan 02 summary records focused proof. |
| INB-04 | Implemented, final suite pending | `ingress/plug.ex`, `ingress/persist.ex`, `internal/replay.ex`, and V02 persist terminal authenticated evidence before provider-stopping acknowledgement; Plan 05 replay/plug tests are the regression set. |
| INB-05 | Implemented, final suite pending | `ingress/verified_request.ex`, `ingress/provider.ex`, provider SES, and ingress Plug pass an explicit verified value; Plan 01 documents no process-dictionary handoff. |
| INB-06 | Implemented, final suite pending | `mailglass_inbound/lib/mailglass_inbound/router.ex` uses literal AST decoding; `router_test.exs` rejects variables, calls, interpolation, captures and macros. |
| INB-07 | Implemented, final suite pending | SES cert and Mailgun replay ETS owners cap admission; inbound rate limiter tests cover cap/expiry/restart. |
| DATA-01 | Implemented, final suite pending | inbound V02 plus `ingress/persist.ex` dual reads/writes SHA-256 and bounded advisory-locked keyset backfill. |
| DATA-02 | Implemented, final suite pending | `ingress/persist.ex` compares stored fingerprint/SHA fields and V02 owns matching indexes. |
| DATA-03 | Implemented, final suite pending | `lib/mailglass/suppression_store.ex`, `suppression_store/{ecto,ets}.ex` expose optional positional bulk lookup with fallback. |
| DATA-04 | Implemented, final suite pending | `lib/mailglass/suppression.ex` and `outbound.ex` deduplicate/chunk bounded batch preflight. |
| DATA-05 | Implemented, final suite pending | `lib/mailglass/suppression/resync.ex` implements keyset pages, deduplicated keys, bulk state loads and chunk upsert; Plan 07 summary records focused proof. |
| DATA-06 | Implemented, final suite pending | `lib/mailglass/webhook/pruner.ex` and inbound `internal/prune.ex` use bounded ordered `FOR UPDATE SKIP LOCKED`; V06/V02 add matching retention indexes. |
| DATA-07 | Partial verification | `webhook/ingest.ex` bulk-loads and reuses delivery structs (query-count regression); `webhook_event.ex`/V06 preserve immutable `raw_signed_body`. The final decoded-payload seam remains a review risk unless separately covered by the final tests. |
| DATA-08 | Implemented, final suite pending | Core V06 and inbound V02 are additive; generated wrapper/host migration proof is covered by Plan 09 commits, including recovery hardening `04c9a8e7` and final host handoff `80f1fc4c`. |

## Test evidence

- Earlier scoped evidence recorded in 157-01 through 157-09 summaries includes passing focused provider, S3, router, persistence/replay, suppression, prune, migration, and generated-host tests.
- Fresh final core attempt: `mix test test/mailglass/webhook/pruner_test.exs test/mailglass/webhook/ingest_test.exs test/mailglass/suppression_test.exs test/mailglass/suppression_store/ecto_test.exs test/mailglass/suppression_store/ets_test.exs test/mailglass/outbound/deliver_many_test.exs test/mailglass/migration_test.exs test/mailglass/shipped_migration_divergence_test.exs --warnings-as-errors`.
- Result: **94 tests, 35 failures**. The affected tests failed setup with `citext probe exhausted ... cache lookup failed for type ...` after migration tests; this is shared test-database/type-cache contamination, not an assertion failure in the Phase 157 behaviours. It is nevertheless a blocking verification failure.
- Inbound final command was intentionally not run after the coordination instruction to avoid parallel shared-database suites.

## Residual risks / required follow-up

1. Run migration tests in a separate process/database lifecycle, then run the remaining core Phase 157 tests in a fresh process; demonstrate no citext OID contamination.
2. After Plan 09 owner confirms no further database changes, run the inbound focused suite serially: ingress plug/SES provider, S3 fetcher, router/rate limiter, persist/replay, prune and migrations, plus no-optional-deps compile.
3. Confirm the final webhook decoded-payload/parse-once path with an explicit parse-count test across verification, normalization and ingest; current bulk-load and raw-body evidence tests do not by themselves prove that end-to-end count.

## Scope confirmation

No admin/operator UI behavior, styling, navigation, LiveView, or dashboard work was verified or changed. This artifact covers only inbound, database/lifecycle, webhook, migration, suppression, and generated-host correctness.
