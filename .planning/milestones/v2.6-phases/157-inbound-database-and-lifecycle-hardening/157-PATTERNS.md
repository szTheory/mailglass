# Phase 157: Inbound, Database, and Lifecycle Hardening - Pattern Map

**Mapped:** 2026-08-17  
**Scope:** `mailglass_inbound`, root `lib/` and `test/`, migration/test scripts. `mailglass_admin` intentionally excluded.  
**Upstream inputs:** No phase-local `CONTEXT.md` or `RESEARCH.md` exists yet; requirements INB-01..07 and DATA-01..08 plus the Phase 157 roadmap success criteria are the locked scope.

## File Classification

| New/modified file(s) | Role | Data flow | Closest existing analog | Match |
|---|---|---|---|---|
| `mailglass_inbound/lib/.../ingress/providers/ses.ex`, `ingress/plug.ex`, SES tests | provider / request controller | request-response, file-I/O | current SES provider and `Mailglass.Webhook.Providers.SES` | exact surface, requires hardening |
| `mailglass_inbound/lib/.../s3_fetcher/{ex_aws_s3,retry}.ex`, tests | adapter / utility | file-I/O, retry | current S3 seam | exact surface, requires cap/classification |
| `mailglass_inbound/lib/.../ingress/{provider,request,plug}.ex`, provider tests | behaviour / controller | request-response | core `lib/mailglass/webhook/{provider,plug}.ex` | role-match |
| `mailglass_inbound/lib/.../router.ex`, router tests | macro / config validator | transform | current router DSL | exact surface, unsafe evaluation to replace |
| `mailglass_inbound/lib/.../rate_limiter/table_owner.ex`, application/config/tests | state owner / config | event-driven | current inbound owner; core `Mailglass.RateLimiter.TableOwner` | exact |
| `mailglass_inbound/lib/.../ingress/persist.ex`, `inbound_records/inbound_evidence.ex`, V02 migration, persistence tests | service / model / migration | CRUD | current persistence transaction and V01 dispatcher | exact, expand/contract needed |
| `lib/mailglass/suppression_store.ex`, `{ecto,ets}.ex`, `suppression/resync.ex`, tests | behaviour / stores / service | CRUD, batch | `SuppressionStore.Ecto`, `Resync` | exact surfaces |
| root delivery batch worker/service and tests | service | batch | existing delivery transaction/batch paths | role-match; planner must locate current delivery batch call sites before edits |
| `mailglass_inbound/lib/.../internal/prune.ex`, root `webhook/pruner.ex`, migrations/tests | service / worker / migration | batch | inbound prune | exact inbound; root pruner is legacy anti-pattern |
| `lib/mailglass/webhook/{ingest,plug}.ex`, webhook tests | service / controller | request-response, batch | `Webhook.Ingest` | exact surface, needs bulk load / raw-body preservation |
| `mailglass_inbound/lib/.../migration.ex`, `migrations/postgres.{ex,v02.ex}`, core migration generator/tests/docs | config / migration | schema evolution | inbound V01 + core version dispatcher | exact package convention |

## Pattern Assignments

### INB-01, INB-02, INB-03, INB-04 — SES verification, S3, durable permanent evidence

**Primary analogs:**

- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:65-165` owns the provider request envelope, typed rescue allowlist, telemetry stop metadata, and provider response semantics.
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex:50-75` performs SNS type dispatch only after `verify_envelope!/2`; `:Notification` currently extracts MIME during verification.
- `mailglass_inbound/lib/mailglass_inbound/s3_fetcher/retry.ex:1-108` is the bounded retry/error translation seam; `s3_fetcher/ex_aws_s3.ex:16-39` is the optional-dependency adapter seam.
- `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex:39-104` is the canonical durable transaction shape.

**Copy:** verify first, classify with closed typed errors, respond with PII-free static JSON, and use the single `Telemetry.ingress_span` outer surface. Preserve the explicit `500` retry signal for transient faults and the permanent `422` distinction (`ingress/plug.ex:142-160`), but add durable evidence creation before a permanent authenticated acknowledgement. Do not log raw error terms/changesets; `persist_and_dispatch/6` and `log_persist_failure/1` at `ingress/plug.ex:280-397` are the model.

**Required change, not a copy:** SES currently obtains raw MIME before tenant resolution (`ingress/plug.ex:65-103`) and materializes an entire S3 response (`s3_fetcher/ex_aws_s3.ex:23-26`). Bound pre-verification certificate/SNS work (single flight, timeout, response size, strict trusted paths, negative cache) and reject `Content-Length`/streamed size above the configurable 40 MiB default before creating a full binary. Unknown exhausted retry results must retain permanent `:s3_fetch_failed`, not be relabelled as transient.

### INB-05 — explicit verified request handoff

**Analog to preserve:** `Mailglass.Webhook.Plug` has the desired outer ordering: raw bytes → verification → tenant resolution → normalization → ingest under `Tenancy.with_tenant/2` (`lib/mailglass/webhook/plug.ex:117-157`).

**Anti-pattern to remove:** `mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex:47, 50-65, 285-320` uses `Process.put/get` (`@pd_key`) to carry `{payload, raw_mime, warnings}` from `verify!/2` to `normalize/1`, including a fallback re-fetch. `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex:39-67` also declares a mixed `verify!/2` and legacy `verify!/3` transition. Plan a single explicit verified-request/result struct/value through provider verification, tenant resolution, normalize, and persistence; preserve public legacy provider compatibility only where support contracts require it, then remove internal arity coupling.

### INB-06 — literal-only route macro

**Current target:** `mailglass_inbound/lib/mailglass_inbound/router.ex:51-66` expands the mailbox but executes caller AST with:

```elixir
{evaluated_opts, _binding} = Code.eval_quoted(opts, [], __CALLER__)
validated = validate_route_opts!(expanded_mailbox, evaluated_opts)
```

**Copy downstream validation:** `validate_route_opts!/2` at `router.ex:80-93` and `validate_matcher/1` at `router.ex:97-104` define the allowed post-literal values; `router/matcher.ex:9-31` preserves ordered first-match behavior.

**Required change:** replace unrestricted evaluation with an AST literal decoder accepting only literal keyword lists, strings, `nil`, and literal regex AST (and a validated literal mailbox alias/module). Reject variables, calls, interpolation, captures, and arbitrary quoted expressions at compile time. Keep the existing public `route/2` declaration syntax, `Route` output, order, and source location.

### INB-07 — bounded attacker-keyed ETS/cache state

**Analog:** `mailglass_inbound/lib/mailglass_inbound/rate_limiter/table_owner.ex:53-154` supplies the intended bounded-owner convention: named ETS owner, `max_keys`, idle sweep, `insert_new` admission, and fail-closed denial when still full. `rate_limiter.ex:61-95` keeps the hot CAS path mailbox-free and error metadata PII-free.

**Apply to:** inbound rate-limit ETS plus core SES certificate cache and Mailgun replay cache (`lib/mailglass/webhook/providers/ses/cert_cache/*`, `mailgun_replay_cache/*`), because inbound SES intentionally reuses core trust/cache machinery (`ingress/providers/ses.ex:21-37`). Keep cache APIs and supervisor ownership stable for root-package callers.

## DATA Pattern Assignments

### DATA-01 — SHA-256 MIME dedupe expand/contract

**Current analog/target:** `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex:116-230, 427-456` selects duplicates with `fragment("md5(?)", inbound_evidence.raw_mime)` and writes `:crypto.hash(:md5, raw_mime)`. V01 creates a generated `md5(raw_mime)` column and provider partial unique indexes (`migrations/postgres/v01.ex:80-145`). `InboundEvidence.changeset/1` maps those exact constraint names (`inbound_records/inbound_evidence.ex:46-66`).

**Required migration pattern:** never change V01 or other shipped migrations. Add V02 under the version dispatcher, expand with nullable explicit SHA-256 bytes/encoded column and compatible indexes using migration lock/statement bounds; dual-write new evidence; dual-read SHA-256 first then legacy MD5 during transition; backfill in bounded commits; later contract only after compatibility window. Update all three together: persistence query, evidence changeset constraint translation, and versioned migration/index names. Existing installs and fresh V01 installs must both converge.

### DATA-02, DATA-03, DATA-04 — indexed suppression lookups and bounded batch delivery

**Analog:** `lib/mailglass/suppression_store.ex:31-49` is the public behaviour contract. Add an optional positional bulk lookup callback (for example `check_many/2`) without breaking stores implementing only `check/2`/`record/2`; fallback must chunk and retain current outcome/order semantics.

**Anti-pattern:** `lib/mailglass/suppression_store/ecto.ex:102-117` casts the indexed `address` column with `fragment("?::text", e.address)`. Compare the typed parameter/cast instead; never apply a function to the indexed side. Preserve tenant scope, expiry predicate, and current `:not_suppressed | {:suppressed, entry} | {:error, term}` outcomes from lines 47-96.

**Resync target:** `lib/mailglass/suppression/resync.ex:86-137` loads every candidate then calls `existing_status/2` per row, and `maybe_apply/2` inserts per row. Replace with stable paging, candidate-key deduplication, one bulk existing-row load per page, and bounded upsert chunks. Maintain `run/1` result fields/dry-run behavior (`resync.ex:28-48`) and tenant scoping.

### DATA-05 — suppression resync

Use `Ecto.Query` with deterministic ordering (`occurred_at`, `id` at `resync.ex:94-96`) as the pagination tie-breaker. Batch boundaries must not alter totals, duplicate treatment, candidates summaries, or halt-on-real-write-error semantics. Add store conformance tests for both bulk-capable Ecto and legacy/no-bulk fake/ETS implementations.

### DATA-06 — retention in bounded SKIP LOCKED batches with matching indexes

**Inbound gold analog:** `mailglass_inbound/lib/mailglass_inbound/internal/prune.ex:155-224` pins one session with `Repo.checkout`, takes/release a session advisory lock in `try/after`, deletes child-first, and uses `LIMIT 1000 FOR UPDATE SKIP LOCKED` subqueries. Retain independent commits per batch and explicit inbound schema prefix.

**Root target / anti-pattern:** `lib/mailglass/webhook/pruner.ex:91-104` uses one unbounded `Repo.delete_all`; refactor to the inbound pattern, suitable root schema prefix, source/status/age indexes, and bounded telemetry counts. Keep existing `:infinity` behavior and Oban/no-Oban public module surface.

### DATA-07 — webhook bulk state loading and raw signed bytes

**Analog:** `lib/mailglass/webhook/plug.ex:117-157` retains raw bytes for verification and sends the same `raw_body` into `ingest_multi/3`; `Webhook.Ingest.ingest_multi/3` uses one transaction with `SET LOCAL statement_timeout = '2s'` and `lock_timeout = '500ms'` (`lib/mailglass/webhook/ingest.ex:145-160`).

**Required change:** parse JSON once per request/batch and retain the exact original `raw_body` for signature/audit/replay. Replace per-event delivery state lookup (`ingest.ex:299-309`, and provider-message lookup `450-470`) with one bounded batch query keyed by provider/message IDs and an in-memory map. Preserve duplicate/no-op/orphan/projector semantics, final status flip, and post-commit broadcasts.

### DATA-08 — future migration policy

**Analog:** `mailglass_inbound/lib/mailglass_inbound/migration.ex:24-87` uses a public stable wrapper → adapter dispatcher → version modules pattern; `migrations/postgres/v01.ex:1-189` threads validated `prefix:` through DDL. Core has the same public API in `lib/mailglass/migration.ex:22-106`.

**Policy:** append new VNN modules; do not edit V01 or shipped historical migrations. For populated tables use expand/contract, bounded `SET LOCAL lock_timeout` / `statement_timeout` in migration transactions where appropriate, `CREATE INDEX CONCURRENTLY` outside transaction where supported, then bounded backfill jobs/commands and later constraint validation. Explicitly test upgrade and fresh-install dispatch paths.

## Shared Patterns and Compatibility Boundaries

| Boundary | Required rule |
|---|---|
| Core ↔ inbound | Inbound may reuse core `Mailglass.Webhook.Providers.SES` verification/trust/cache seams but must not duplicate their supervision. Keep core cache APIs compatible because core webhooks use them too. |
| Inbound ↔ root suppression | `Ingress.Persist` calls configured root `:mailglass, :suppression_store` before its inbound DB transaction (`ingress/persist.ex:39-52`); never hold core and inbound repo connections in that transaction concurrently. |
| Schema prefixes | Direct inbound repository calls use `MailglassInbound.Repo`/`schema_opts`; direct checked-out raw host-repo paths qualify tables inline (`internal/prune.ex:14-26`). Caller-supplied `:prefix` remains authoritative via `Keyword.put_new`. |
| Public package API | Preserve `MailglassInbound.Ingress.Plug`, provider config keys, `S3Fetcher` test seam, router declaration syntax, `SuppressionStore` existing callbacks/results, Oban worker stubs, migration wrappers, and telemetry event names/PII-safe metadata. |
| Errors/logs | Use closed type atoms and static egress. Never inspect/serialize raw MIME, request bodies, recipient addresses, changeset values, or provider errors into HTTP/log metadata. |

## Likely Plan Splits and Dependencies

1. **Inbound verification/value boundary (INB-01..06):** SES certificate/SNS bounds, S3 size/classification, durable authenticated permanent evidence, explicit verified-request handoff, and router AST validation. This must establish the new verified value before provider/plug tests are rewritten.
2. **Cache and rate-limit state (INB-07):** shared root cert/replay caches and inbound ETS admission/sweep. Can proceed beside the verification refactor but must integrate with its cache APIs.
3. **MIME transition and migration foundation (DATA-01, DATA-08):** V02 dispatcher/migration, SHA-256 dual read/write, bounded backfill and upgrade tests. Must precede removal of legacy fingerprint reads/indexes.
4. **Suppression/delivery scale path (DATA-02..05):** behaviour extension + indexed Ecto query correction, batch delivery call sites, paged resync. Depends on the optional callback/fallback contract before consumers use bulk lookup.
5. **Retention/webhook scale path (DATA-06..07):** adopt inbound batch deletion in core pruner, add indexes/migration policy, batch webhook state load and parsed JSON reuse. Depends on migration policy for production-safe indexes.

## Verification Commands

Run focused package tests while implementing, then the package gates:

```bash
cd mailglass_inbound && mix test test/mailglass_inbound/ingress/ses_provider_test.exs test/mailglass_inbound/ingress/plug_test.exs test/mailglass_inbound/s3_fetcher_test.exs test/mailglass_inbound/persistence_test.exs test/mailglass_inbound/router_test.exs test/mailglass_inbound/rate_limiter_test.exs test/mailglass_inbound/internal/prune_test.exs test/mailglass_inbound/migrations_test.exs --warnings-as-errors
cd mailglass_inbound && mix verify.support_contract.inbound
cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors
mix test test/mailglass/suppression_store test/mailglass/suppression test/mailglass/webhook --warnings-as-errors
mix verify.schema_prefix
mix ci.full
```

Add/extend upgrade-from-V01, fresh-install, bounded-object, unknown-S3-exhaustion, durable-permanent-failure, no-process-dictionary, literal-AST rejection, max-key eviction/admission, query/index-plan, pagination, `SKIP LOCKED`, raw-byte equality, and legacy-store fallback tests. Do not run `mailglass_admin` tests for this phase.

## No Analog Found

| Work item | Reason / planner guidance |
|---|---|
| Explicit verified-request struct | Current provider contract is deliberately transitional and has no clean inbound analog; model control flow on core webhook plug but define a new private inbound value. |
| SHA-256 dual-read/write + bounded backfill | Current implementation is MD5-only; create a new forward migration/backfill path, never mutate V01. |
| Literal AST decoder | Existing DSL uses unsafe `Code.eval_quoted`; implement a narrow compile-time decoder with adversarial macro tests. |

## Metadata

**Analog search scope:** `mailglass_inbound/lib`, `mailglass_inbound/test`, root `lib`, root `test`, root/inbound Mix configuration and migrations.  
**Primary files scanned:** 24 source modules plus focused test/config references.  
**Pattern extraction date:** 2026-08-17.
