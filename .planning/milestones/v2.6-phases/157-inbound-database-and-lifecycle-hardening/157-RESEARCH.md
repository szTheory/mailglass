# Phase 157: Inbound, Database, and Lifecycle Hardening - Research

**Researched:** 2026-08-17  
**Domain:** Phoenix/Plug ingress, ETS lifecycle, Ecto/PostgreSQL data safety  
**Confidence:** HIGH for repository seams; MEDIUM for external operational guidance

## User Constraints

### Locked Decisions

#### Verified inbound pipeline and bounded network work
- **D-01 — One verified-request value:** Introduce one internal verified-request value that carries the
  exact signed request, decoded authenticated envelope, verification facts, and resolved provider
  content from verification through normalization and persistence. Remove production process-dictionary
  handoff and refetch behavior; retain legacy callback arities only as additive adapters.
- **D-02 — Verify before provider I/O:** SES signature verification remains before S3 retrieval. Resolve
  tenant scope after authentication and before content retrieval so authenticated permanent failures can
  be recorded durably with tenant ownership.
- **D-03 — Bounded shared certificate service:** The shared core SES verifier owns certificate retrieval
  for core and inbound. It provides per-URL single-flight, a small global concurrency bound, positive TTL,
  short negative caching, periodic/lazy expiry, bounded cardinality, strict existing SNS URL/path policy,
  finite request timeouts, and a finite certificate response limit. Sensible conservative defaults may be
  tuned internally without widening public API.
- **D-04 — Metadata-first S3 limit:** SES S3 retrieval checks object metadata before body download and
  rejects objects above a configurable 40 MiB default. Adapters must never fully materialize an object
  known to exceed the limit.
- **D-05 — Closed S3 classification:** Known transient transport, throttling, timeout, and not-ready
  outcomes retry within the existing finite attempt budget. Authorization, missing/oversized/malformed,
  and unknown exhausted outcomes retain the permanent `:s3_fetch_failed` family; retry exhaustion must
  not relabel an unknown permanent failure as `:s3_object_not_ready`.
- **D-06 — Durable dead evidence before acknowledgement:** After authentication and tenant resolution,
  every permanent inbound failure that will stop provider redelivery commits tenant-scoped raw signed
  bytes, authenticated envelope/facts, closed failure classification, and enough routing/content context
  for deterministic replay before the response is acknowledged. The schema/API shape may be internal,
  but replayability must be exercised end to end.

#### Router and attacker-controlled state
- **D-07 — Literal-only router declarations:** `MailglassInbound.Router.route/2` expands mailbox aliases
  but never calls `Code.eval_quoted/3`. Route options accept only recursively validated literal AST,
  including literal strings and regex sigils, before the existing NimbleOptions/value checks.
- **D-08 — Every cache is finite:** SES certificate/negative entries, Mailgun replay tokens, and inbound
  rate-limit keys all have explicit cardinality and expiry behavior with deterministic overflow policy.
  Reuse the Phase 156 bounded ETS lifecycle patterns where they fit; do not create another unowned table.

#### MIME and suppression data paths
- **D-09 — SHA-256 expand/contract:** Add an explicit binary SHA-256 MIME fingerprint beside the shipped
  MD5 generated field, dual-write new evidence, dual-read during transition, backfill in bounded resumable
  batches, then prefer the SHA-256 indexes. Existing installations and in-flight redeliveries must dedupe
  throughout; do not edit the shipped inbound V01 module.
- **D-10 — Index columns stay bare:** Fingerprint and suppression lookups compare normalized parameters
  to indexed columns. Do not wrap the indexed side in `md5`, casts, lowercasing, or other functions.
- **D-11 — Optional positional bulk lookup:** Add a backward-compatible optional suppression-store bulk
  capability returning results in input position. Stores without it use a bounded chunked `check/2`
  fallback. Batch delivery preserves input ordering and exact per-message outcome semantics while
  bounding database queries.
- **D-12 — Bounded resync:** Suppression resync keyset-pages events by `(occurred_at, id)`, deduplicates
  candidate keys, bulk-loads existing rows, and performs bounded conflict-safe upserts. Dry-run and
  existing/missing counts retain their documented meaning without loading the full time window.

#### Retention, webhook ingestion, and migrations
- **D-13 — Bounded indexed retention:** Core webhook pruning adopts finite `FOR UPDATE SKIP LOCKED`
  batches and single-run serialization. Inbound keeps child-first batched deletion. New additive indexes
  match status/source plus age/id selection so neither path devolves into full scans.
- **D-14 — One parse and one bulk delivery load:** Webhook ingest parses verified JSON once, derives all
  events from that value, bulk-loads matching deliveries once per provider batch, and preserves the exact
  signed raw body in a dedicated immutable binary field alongside the decoded payload.
- **D-15 — Future migration safety is executable:** New core/inbound versions use expand/contract for
  populated tables, bounded lock/statement timeouts, resumable data backfill, and concurrent indexes when
  upgrading populated installations. Generated wrappers must carry any Ecto transaction/lock attributes
  required for those policies. Shipped migration modules remain byte-for-byte unchanged.

### the agent's Discretion

- Internal module/table names, batch sizes, cache limits, timeout values, error helper placement, and
  compatibility adapter organization may follow the simplest existing conventions, provided limits are
  configurable where an adopter reasonably needs control and tests prove the default bounds.
- Prefer small explicit pipeline stages and reusable private services over adding behavior to the already
  broad public Plug/Outbound façades.

### Deferred Ideas (OUT OF SCOPE)

Architecture-wide ownership refactoring belongs to Phase 158; repository-wide gate simplification,
coverage/Dialyzer/skip policy, dependency remediation, and CI noise belong to Phase 159; full adopter
certification and package release belong to Phase 160. Admin/operator UI changes remain out of scope.

## Phase Requirements

| ID | Description | Research support |
|---|---|---|
| INB-01 | Bound SES certificate work before verification. | Core SES cert cache/current `:httpc` miss path is the shared seam. |
| INB-02 | Reject S3 objects over 40 MiB before materialization. | Add metadata/head capability before `GetObject`, then enforce the limit in the adapter/retry boundary. |
| INB-03 | Correct S3 transient/permanent evidence. | Preserve closed retry class and make unknown exhausted failures permanent-shaped. |
| INB-04 | Persist replayable evidence before acknowledged permanent failure. | Add a verified-failure durable insert path before 2xx acknowledgement. |
| INB-05 | One explicit verified-request value. | Replace SES process-dictionary stash and provider arity coupling with a request/result struct. |
| INB-06 | Literal-only router macros. | Validate quoted AST before evaluating/escaping route declaration data. |
| INB-07 | Bound replay/certificate/rate-limit caches. | Reuse Phase 156 ETS owner/admission pattern for all attacker-keyed tables. |
| DATA-01 | SHA-256 MIME transition. | Add a new nullable fingerprint column/index in a new inbound migration; dual-write/read and bounded backfill. |
| DATA-02 | Indexed fingerprint/suppression lookups. | Compare indexed columns directly; remove `md5(column)`/casts on indexed side. |
| DATA-03 | Positional bulk suppression lookup. | Add optional behaviour callback/capability probe and compatible chunked fallback. |
| DATA-04 | Bounded batch suppression work. | Preflight unique recipient keys in bounded chunks, map results back to input order. |
| DATA-05 | Bounded suppression resync. | Keyset/page ledger scan, dedupe candidates, bulk existing lookup, bounded upsert. |
| DATA-06 | Bounded indexed core/inbound pruning. | Both pruners need candidate indexes and `SKIP LOCKED` batch deletion. |
| DATA-07 | Batched webhook projections with exact signed body. | Preserve `conn.private[:raw_body]`; parse once and bulk-fetch matching deliveries. |
| DATA-08 | Future safe migration policy. | New operational migration policy/docs/tests; never edit shipped migration modules. |

## Summary

Phase 156 already supplies bounded ETS admission, table recreation, and finite persisted-value decoding. Phase 157 should extend those established mechanisms instead of introducing new supervisors, caches, or response contracts. The main present risks are concrete: core SES has a check-then-fetch certificate cache backed by an unbounded ETS table; inbound SES carries verified payload/MIME through the process dictionary; its S3 adapter always materializes the object; MD5 lookup applies a function to `raw_mime`; and core suppression/webhook paths execute N per-row database lookups. [VERIFIED: repository grep]

Treat verification as a pipeline that produces one explicit `%VerifiedRequest{}` (or equivalent opaque struct) containing provider, immutable raw body, verified facts, normalized input, and SES MIME extraction. The inbound Plug owns response policy. It must record authenticated terminal failure evidence transactionally before returning an acknowledgement that halts redelivery. Unauthenticated signature failures remain 401 and must create no evidence. [VERIFIED: `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`]

For persisted data, introduce only new versioned migration modules and generated-host migration tests. Existing `V01` is a fresh-install projection of historical inbound state and existing root `priv/repo/migrations` are immutable; alter neither. Existing installs need expand → backfill → read-prefer-new/legacy-fallback → enforce/remove-later stages. [VERIFIED: `mailglass_inbound/lib/mailglass_inbound/migrations/postgres/v01.ex`; `lib/mailglass/migration.ex`]

**Primary recommendation:** Plan independent vertical slices around (1) verified inbound/S3/cache boundaries, (2) durable terminal evidence and literal routes, (3) SHA-256/index and suppression batching, and (4) retention/webhook/migration policy, with generated-host migration proof as the final gate.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Raw inbound request preservation and signature verification | API / Backend | Client/Provider | Plug consumes exact bytes; provider verification is server-only. |
| SES certificate and S3 work | API / Backend | External AWS | Server controls limits, timeouts, single-flight and error taxonomy. |
| Router declaration safety | API / Backend | Build/Compiler | Macro validates compile-time AST; runtime only receives route data. |
| MIME deduplication and migration | Database / Storage | API / Backend | Schema/index owns uniqueness and lookup shape; ingress dual-writes. |
| Suppression preflight/resync | Database / Storage | API / Backend | Store owns positional/bulk lookup; outbound maps results to messages. |
| Retention and webhook projection | Database / Storage | API / Backend | PostgreSQL selects/locks/deletes batches; workers/plugs orchestrate. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---:|---|---|
| Ecto SQL | `~> 3.13` | migrations, queries, `Ecto.Multi` | Existing project dependency and all durable state uses it. [VERIFIED: `mailglass_inbound/mix.exs`] |
| PostgreSQL | host supplied (local 14.17) | indexed lookups, advisory locks, `SKIP LOCKED` | Project is explicitly Postgres-only. [VERIFIED: `mailglass_inbound/lib/mailglass_inbound/migration.ex`] |
| Plug | existing dependency | exact raw-body ingress | Existing caching body readers already retain signed bytes. [VERIFIED: `lib/mailglass/webhook/caching_body_reader.ex`] |
| Erlang `:ets`, `:httpc`, `:crypto` | OTP 28 locally | bounded in-memory tables, HTTPS cert fetch, SHA-256 | Existing stack; no new package is needed. [VERIFIED: repository source; local OTP 28] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---:|---|---|
| `ex_aws`, `ex_aws_s3` | existing optional `~> 2.7` / `~> 2.5` | S3 metadata/get operations | Keep optional gateway only; extend it with head-before-get. [VERIFIED: `mailglass_inbound/mix.exs`] |
| Oban | existing optional `~> 2.21` | optional scheduled prune | Preserve optional worker/stub boundary. [VERIFIED: `mailglass_inbound/mix.exs`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Existing ETS table-owner pattern | New cache server/package | Rejected: Phase 156 already proves bounded admission/recreation locally. [VERIFIED: Phase 156 summary] |
| New SHA-256 column | Rewrite generated MD5 column | Rejected: would modify shipped history/lock existing installs. [VERIFIED: roadmap scope] |
| Store bulk capability | Force all custom stores to implement bulk immediately | Rejected: public store compatibility requires chunked fallback. [ASSUMED] |

**Installation:** none. This phase must use the current dependencies; no Package Legitimacy Audit is required.

## Architecture Patterns

### System Architecture Diagram

```text
Provider HTTP request
  -> CachingBodyReader (exact raw body, bounded Plug limit)
  -> Ingress Plug
       -> provider verify: SNS URL policy -> bounded single-flight cert fetch -> signature
       -> produce VerifiedRequest (raw bytes + facts + normalized/SES MIME)
       -> tenant resolution -> bounded rate/cache admission -> literal route data
       -> persist record + evidence + route binding in one transaction
            -> terminal authenticated failure? persist replayable dead evidence first
       -> response policy (ack only after durable terminal outcome)
       -> async mailbox dispatch

Verified S3 notification
  -> HeadObject ContentLength <= configured 40 MiB
  -> bounded GetObject/retry -> raw MIME bytes -> SHA-256 dual-write/dedup

Batch outbound/webhook/prune
  -> unique keys/page ids -> indexed bulk read -> bounded chunk/Multi/lock
  -> projection/upsert/delete -> telemetry counts only
```

### Recommended Project Structure

```text
mailglass_inbound/lib/mailglass_inbound/
├── ingress/verified_request.ex       # explicit successful verification value
├── ingress/terminal_failure.ex       # durable authenticated-failure policy
├── s3_fetcher.ex                     # head + get behaviour boundary
└── migrations/postgres/v02.ex         # additive SHA-256/index migration
lib/mailglass/
├── suppression_store.ex               # optional bulk capability contract
├── suppression/resync.ex              # paged/bulk rebuild
└── webhook/{ingest,pruner}.ex         # batched projection/retention
```

### Pattern 1: Explicit verified request, no ambient handoff

**What:** `verify/…` returns a closed success value used exactly once by normalization/persistence; it owns raw bytes/facts/MIME and never uses `Process.put/get`.

**When to use:** all inbound providers, with compatibility adapters retained at public Plug/provider edges.

```elixir
# Source: repository pattern inferred from Ingress.Request and current SES handoff
with {:ok, %VerifiedRequest{} = verified} <- Provider.verify(request, config),
     {:ok, normalized} <- Provider.normalize(verified),
     {:ok, result} <- Persist.persist(normalized, tenant_id) do
  response_for(result)
end
```

### Pattern 2: Bounded, deduplicated database work

**What:** cap input chunk size, dedupe lookup keys, perform one indexed query/upsert per chunk, then rebuild results in caller input order.

**When to use:** `deliver_many`, suppression resync, webhook delivery matching, and pruning.

```elixir
keys = recipients |> Enum.uniq() |> Enum.chunk_every(@lookup_chunk)
rows = Enum.flat_map(keys, &store.bulk_check(&1, tenant_id))
result_by_key = Map.new(rows, &{&1.key, &1})
Enum.map(recipients, &Map.get(result_by_key, &1, :not_suppressed))
```

### Pattern 3: Expand/contract migration execution

**What:** deploy a nullable/additive schema and compatible code first; backfill in bounded resumable chunks; switch reads only once both forms exist; defer removal/enforcement to a later compatible release.

**When to use:** every populated-table change, especially SHA-256 columns/indexes.

**Anti-Patterns to Avoid**

- **`Code.eval_quoted/3` in public `route/2`:** current macro evaluates arbitrary caller AST. Accept literal module aliases, keyword list, strings, regex literals, tuples/lists made solely of literals; reject calls, variables, captures, aliases resolved by arbitrary expressions, and remote calls. [VERIFIED: `mailglass_inbound/lib/mailglass_inbound/router.ex`]
- **Function over indexed evidence/suppression column:** `fragment("md5(?)", inbound_evidence.raw_mime)` and `?::text` prevent the requested direct indexed-column shape. Query new stored fingerprint/address columns directly. [VERIFIED: `ingress/persist.ex`; `suppression_store/ecto.ex`]
- **Acknowledging before evidence:** a 2xx permanent response must follow, not precede, a committed durable failure record.
- **Whole-table `Repo.all`/`delete_all`:** current resync materializes all candidates and core pruner performs unbounded deletes. [VERIFIED: `suppression/resync.ex`; `webhook/pruner.ex`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| SNS crypto/trust policy | Separate inbound verifier | Existing `CoreSES.verify_envelope!` plus hardened cache seam | Keep byte-identical crypto policy. [VERIFIED: `ingress/providers/ses.ex`] |
| ETS contention/restart handling | Fresh per-cache ETS logic | Phase 156 AtomicBucket/table-owner admission/recreation patterns | Existing bounded lifecycle proof. [VERIFIED: Phase 156 summaries] |
| SHA-256 | Custom digest | `:crypto.hash(:sha256, raw_mime)` | OTP primitive; current core already uses it for SendGrid batch idempotency. [VERIFIED: `webhook/ingest.ex`] |
| Concurrent retention | bespoke loop/long transaction | indexed limited subquery + `FOR UPDATE SKIP LOCKED` + independent batches | Existing inbound structure, now also needed in core. [VERIFIED: inbound `internal/prune.ex`] |

## Common Pitfalls

### Pitfall 1: Cache miss stampede becomes pre-verification DoS

**What goes wrong:** `CertCache.fetch_public_key` returns `:miss`; every concurrent request fetches the same URL. The table has no cap and HTTPS response body is unbounded.  
**Avoid:** table-owner single-flight keyed by validated URL, hard in-flight cap, short negative TTL, request/connect timeout, maximum PEM bytes, and no cache insert for malformed/oversize responses. Retain URL trust validation before any network I/O. [VERIFIED: `lib/mailglass/webhook/providers/ses.ex`; `cert_cache.ex`]

### Pitfall 2: Unknown retry exhaustion appears transient

**What goes wrong:** `Retry.retryable?/1` retries unknown reasons, but currently raises `:s3_object_not_ready` at exhaustion, implying redelivery.  
**Avoid:** only known not-ready/network/5xx classes retry; unknown exhausted failure yields `:s3_fetch_failed` with internal cause, then follows durable terminal evidence policy. [VERIFIED: `s3_fetcher/retry.ex`]

### Pitfall 3: S3 size limit after body allocation

**What goes wrong:** current adapter accepts `{:ok, %{body: body}}` after full object materialization.  
**Avoid:** extend optional gateway/behaviour for `head_object` and reject `ContentLength > 40 * 1024 * 1024` before `get_object`; also defend against an adapter returning an oversized body. AWS documents `HeadObject` as metadata-only. [CITED: https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html]

### Pitfall 4: Migration-created index blocks or fails

**What goes wrong:** `CREATE INDEX CONCURRENTLY` cannot run inside a transaction and failed builds leave an invalid index.  
**Avoid:** document/add a separate out-of-transaction operational migration path with explicit lock/statement timeouts, check/recover invalid indexes, and prove fresh/upgrade host paths. [CITED: https://www.postgresql.org/docs/current/sql-createindex.html]

### Pitfall 5: Raw signed bytes are reconstructed from parsed JSON

**What goes wrong:** any decode/re-encode changes bytes used by HMAC/SNS verification.  
**Avoid:** preserve the existing `conn.private[:raw_body]` as authoritative and parse JSON once separately for batch normalization. [VERIFIED: `webhook/caching_body_reader.ex`; `webhook/plug.ex`]

## Code Examples

### S3 metadata gate

```elixir
# Source: AWS HeadObject semantics + existing optional ExAws gateway shape
with {:ok, %{content_length: bytes}} <- fetcher.head(bucket, key, opts),
     :ok <- ensure_max_bytes(bytes, max_bytes),
     {:ok, body} <- fetcher.fetch(bucket, key, opts),
     :ok <- ensure_max_bytes(byte_size(body), max_bytes) do
  {:ok, body}
end
```

### Index-friendly fingerprint read during transition

```elixir
# Prefer SHA-256; legacy MD5 remains only for pre-backfill rows.
from(e in InboundEvidence,
  where: e.tenant_id == ^tenant_id and e.provider == ^provider,
  where: e.raw_mime_sha256 == ^sha256 or
           (is_nil(e.raw_mime_sha256) and e.raw_mime_fingerprint == ^legacy_md5),
  select: e.inbound_record_id,
  limit: 1
)
```

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| MD5 generated fingerprint and `md5(raw_mime)` lookup | explicit SHA-256 bytes plus direct-column queries | cryptographic digest and index-friendly lookup. [VERIFIED: repository source] |
| one query per outbound message/resync candidate/webhook event | deduplicated bounded bulk reads | prevents linear query amplification. [VERIFIED: repository source] |
| unbounded core webhook delete | `SKIP LOCKED` bounded batches with matching composite indexes | stable retention under concurrent traffic. [ASSUMED] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Custom suppression stores can safely gain an optional bulk capability without a public-version break. | Standard Stack / DATA-03 | Planner must preserve callback compatibility or gate a new API. |
| A2 | A new inbound migration version (`V02`) is the next available dispatcher slot. | Project Structure | Verify dispatcher/catalog before implementation. |
| A3 | Core webhook retention should share inbound's session advisory-lock posture. | State of the Art | Lock ownership may need a distinct key/operational decision. |

## Open Questions (RESOLVED)

1. **Exact certificate-cache bounds and negative TTL**
   - What we know: Phase 156 uses 100,000-key, idle-expiring table owner admission; SES needs much lower, config-validated limits.
   - What's unclear: desired production values and whether a single global in-flight budget or per-URL + global cap is preferred.
   - Recommendation: use conservative defaults, validate max entries/in-flight/response bytes, and make only values—not policy—configurable.
   - **RESOLVED:** Use a per-URL single-flight coordinator plus a small configurable global in-flight cap, with conservative config-validated defaults for entry limits, positive/negative TTLs, timeouts, and response bytes. The policy is fixed; adopters may tune only bounded values.
2. **Durable inbound terminal-failure representation**
   - What we know: evidence/record/replay tables already persist raw material and execution lineage.
   - What's unclear: whether to add a dedicated failure status/record or reuse `ExecutionRun` before mailbox execution.
   - Recommendation: choose the smallest additive representation that the existing replay command can load without inventing admin UI.
   - **RESOLVED:** Extend the existing inbound evidence/replay representation additively in V02 with the minimum tenant-scoped terminal context, closed failure class, exact signed bytes, and verified facts needed by the existing replay path. Do not introduce a new operator/admin surface or a separate public API.
3. **Bulk suppression callback surface**
   - What we know: current `SuppressionStore` has only `check/2` and `record/2`.
   - What's unclear: whether the public behaviour is semver-frozen tightly enough to require capability detection instead of a callback.
   - Recommendation: introduce an optional `bulk_check/2` guarded by `function_exported?/3`, retaining bounded `check/2` chunks.
   - **RESOLVED:** Add an optional positional bulk capability detected with `function_exported?/3`; legacy stores that only expose `check/2` and `record/2` remain supported through configurable bounded chunks with identical positional results.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Elixir/OTP | compile/tests | ✓ | Elixir 1.19.5 / OTP 28 | — |
| PostgreSQL CLI | migration/query verification | ✓ | 14.17 | CI Postgres service |
| Docker | generated-host proof | ✓ | 29.5.2 | host-local proof scripts |
| AWS credentials/S3 | live adapter proof | ✗ (not inspected) | — | fake adapter tests |

**Missing dependencies with no fallback:** none for implementation tests. AWS live proof remains external/advisory.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit, Ecto SQL, StreamData property lanes |
| Config file | `test/test_helper.exs`, `mailglass_inbound/test/test_helper.exs` |
| Quick run command | `mix test test/mailglass/webhook/ingest_test.exs test/mailglass/suppression_store/ecto_test.exs --warnings-as-errors` |
| Full suite command | `mix ci` and `(cd mailglass_inbound && mix ci)` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| INB-01/07 | single-flight, cap, expiry, malformed/oversize cert responses | unit/concurrency | inbound/core focused SES cache tests | ❌ Wave 0 |
| INB-02/03 | HEAD rejects 40MiB+; classified retry exhaustion | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/s3_fetcher_test.exs` | ✅ extend |
| INB-04/05 | verified terminal evidence commits before acknowledgement; no process dictionary | integration | ingress Plug/persist tests | ✅ extend |
| INB-06 | literal AST accepted; executable AST rejected at compile time | compile/unit | router tests | ✅ extend |
| DATA-01/02 | dual read/write, direct-column lookup, bounded backfill | Postgres integration | inbound persistence/migration tests | ✅ extend |
| DATA-03/04/05 | bulk/fallback chunks preserve input outcomes | unit + DB | suppression/outbound/resync tests | ✅ extend |
| DATA-06 | concurrent pruners/batches use indexes | Postgres integration | core/inbound prune tests | ✅ extend |
| DATA-07 | raw bytes survive and batch uses bulk fetch | integration | webhook ingest/plug tests | ✅ extend |
| DATA-08 | new migration policy and shipped migration hashes unchanged | contract/generated-host | migration/hygiene tests | ✅ extend |

### Wave 0 Gaps

- [ ] SES cert cache single-flight/cap/negative-cache/response-limit tests.
- [ ] Verified-request/no-process-dictionary regression test.
- [ ] EXPLAIN or query-shape regression proving direct indexed fingerprint/suppression predicates.
- [ ] Generated-host upgrade test for SHA-256 expand/backfill compatibility and migration immutability hash.
- [ ] Core pruner concurrency/index tests.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | yes | SNS/provider signature verification before tenant work. |
| V3 Session Management | no | No interactive session state in scope. |
| V4 Access Control | yes | Tenant-scoped persistence and replay queries. |
| V5 Input Validation | yes | strict trusted SNS URL/path, literal macro AST, size limits, closed error values. |
| V6 Cryptography | yes | existing SNS X.509 verification and OTP SHA-256; never custom crypto. |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| forged SNS/cert URL SSRF | Spoofing | trust-policy validation before network I/O; bounded HTTPS retrieval. |
| unique attacker cache keys | Denial of service | ETS max admission, idle expiry, single-flight and negative cache. |
| oversized S3/MIME body | Denial of service | metadata size gate plus post-fetch defense. |
| macro code execution | Elevation of privilege | literal AST whitelist; no `Code.eval_quoted`. |
| acknowledgement drops durable evidence | Repudiation | commit evidence before terminal acknowledgement. |

## Sources

### Primary (HIGH confidence)

- Repository source and tests: SES verifier/cache, inbound Plug/S3/persist/router/pruner, suppression/outbound/resync, webhook ingest/pruner, migration dispatchers, and all Phase 156 summaries.

### Secondary (MEDIUM confidence)

- [PostgreSQL CREATE INDEX documentation](https://www.postgresql.org/docs/current/sql-createindex.html) - concurrent index restrictions, invalid-index recovery, operational tradeoffs.
- [Amazon S3 HeadObject API](https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html) - metadata-only content-length preflight.
- [Amazon SNS signature verification](https://docs.aws.amazon.com/sns/latest/dg/sns-verify-signature-of-message.html) - signature verification reference.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing locked project dependencies and code paths.
- Architecture: HIGH — direct seam inventory; MEDIUM for exact new public capability shape.
- Pitfalls: HIGH — reproducible current code shapes plus official PostgreSQL/S3 documentation.

**Research date:** 2026-08-17  
**Valid until:** 2026-09-16 (repository findings); re-check external operational documentation before release.
