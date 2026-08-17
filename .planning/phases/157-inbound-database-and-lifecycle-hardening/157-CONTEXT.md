# Phase 157: Inbound, Database, and Lifecycle Hardening - Context

**Gathered:** 2026-08-17
**Status:** Ready for planning
**Mode:** Auto-generated from the approved v2.6 audit plan and code-backed assumptions analysis

<domain>
## Phase Boundary

Make authenticated inbound processing, persistence, webhook batching, suppression maintenance, and
retention safe under hostile cardinality and production-scale data. This phase owns INB-01..07 and
DATA-01..08. Changes are additive-only: existing v2 public façades and package independence remain
intact, shipped migrations are immutable, and admin/operator UI behavior is untouched.

</domain>

<decisions>
## Implementation Decisions

### Verified inbound pipeline and bounded network work
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

### Router and attacker-controlled state
- **D-07 — Literal-only router declarations:** `MailglassInbound.Router.route/2` expands mailbox aliases
  but never calls `Code.eval_quoted/3`. Route options accept only recursively validated literal AST,
  including literal strings and regex sigils, before the existing NimbleOptions/value checks.
- **D-08 — Every cache is finite:** SES certificate/negative entries, Mailgun replay tokens, and inbound
  rate-limit keys all have explicit cardinality and expiry behavior with deterministic overflow policy.
  Reuse the Phase 156 bounded ETS lifecycle patterns where they fit; do not create another unowned table.

### MIME and suppression data paths
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

### Retention, webhook ingestion, and migrations
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

### Agent's Discretion
- Internal module/table names, batch sizes, cache limits, timeout values, error helper placement, and
  compatibility adapter organization may follow the simplest existing conventions, provided limits are
  configurable where an adopter reasonably needs control and tests prove the default bounds.
- Prefer small explicit pipeline stages and reusable private services over adding behavior to the already
  broad public Plug/Outbound façades.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.Webhook.Providers.SES.verify_envelope!/2` is already shared by core and inbound, and its
  `TrustPolicy` validates SNS certificate/subscribe URLs before network I/O.
- Phase 156's atomic bucket/table-owner patterns provide bounded ETS lifecycle and restart tests.
- `MailglassInbound.Internal.Prune` already demonstrates session-pinned advisory locking and 1,000-row
  `SKIP LOCKED` deletes; core `Webhook.Pruner` can converge on that pattern.
- Ecto Multi, repo-prefix helpers, inbound replay records, installer/generated-host proofs, and explicit
  migration version dispatchers provide the transaction, compatibility, and upgrade seams.

### Known Failure Evidence
- SES certificate misses are check-then-act, direct `:httpc` requests; certificate and replay ETS tables
  have no maximum cardinality, response limit, negative cache, or single-flight miss handling.
- S3 retrieval returns an already materialized body and therefore cannot reject a known-oversized object
  before allocation. Unknown retry exhaustion is currently classified inconsistently.
- SES uses a process-dictionary stash between verify and normalize; Router uses `Code.eval_quoted/3`.
- MIME dedupe hashes/casts the data side with MD5; suppression lookup casts the indexed address column.
- Batch preflight performs one suppression lookup per message; resync loads the whole window and issues
  per-candidate reads/writes.
- Core prune is a single unbounded delete. Webhook ingest performs per-event delivery lookup and stores
  decoded JSON without retaining exact signed bytes.

### Integration Points
- Shared SES certificate service/cache and application supervision; inbound Plug/provider/pipeline;
  S3 gateway/retry/error; inbound persistence/evidence/replay; Router macros; core/inbound migration
  dispatchers and generator; suppression behavior/Ecto/ETS stores, Outbound batch preflight and resync;
  webhook ingest/event schema/pruner; full CI and generated Ecto-host upgrade proof.

</code_context>

<specifics>
## Specific Ideas

Acceptance proof must include certificate cold-burst single-flight and global saturation, negative-cache
and unique-key cardinality, pre-download S3 oversize rejection, transient/permanent retry matrices,
permanent-failure persistence-before-ack/replay, no process-dictionary coupling, macro side-effect
rejection, mixed old/new MIME rows, query-shape/index proof, bounded suppression query counts, multi-page
resync convergence, concurrent pruners, byte-exact webhook evidence, and generated-host upgrades from the
prior inbound/core versions.

</specifics>

<deferred>
## Deferred Ideas

Architecture-wide ownership refactoring belongs to Phase 158; repository-wide gate simplification,
coverage/Dialyzer/skip policy, dependency remediation, and CI noise belong to Phase 159; full adopter
certification and package release belong to Phase 160. Admin/operator UI changes remain out of scope.

</deferred>
