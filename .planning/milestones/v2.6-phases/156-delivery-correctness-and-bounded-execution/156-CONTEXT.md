# Phase 156: Delivery Correctness and Bounded Execution - Context

**Gathered:** 2026-08-16
**Status:** Ready for planning
**Mode:** Auto-generated from the approved v2.6 audit plan

<domain>
## Phase Boundary

Make outbound and tracking execution correct under concurrency, provider failure, and local saturation.
This phase owns atomic durable dispatch, bounded fallback execution and rate-limit state, closed retry
classification, privacy-safe errors, truthful tracking telemetry, and safe closed-set conversion. It does
not change admin/operator UI or broaden the public product surface beyond additive compatibility hooks.

</domain>

<decisions>
## Implementation Decisions

### Rate limiting and resource bounds
- **D-01 — Shared private engine:** Core and inbound use one private atomic compare-and-swap token-bucket engine behind their existing
  public/package façades; independently released packages must remain usable on their own.
- **D-02 — Exact refill arithmetic:** Refill math uses monotonic fixed-point time so concurrent callers cannot overspend and sub-token
  elapsed time is retained.
- **D-03 — Bounded defaults:** Default maximum cardinality is 100,000 keys, idle expiry is one hour, and sweep cadence is 60 seconds.
- **D-04 — Fail-closed admission:** At capacity, purge eligible idle entries first and fail closed if bounded capacity is still exhausted.

### Durable and fallback dispatch
- **D-05 — Atomic durable dispatch:** Oban remains the durable default. Delivery projection, event, private payload, and job insertion commit
  in one database transaction or the caller receives an error with no stranded queued row.
- **D-06 — Honest bounded fallback:** Task-supervisor fallback remains supported but is explicitly bounded to ten concurrent children per
  application by default. Every spawn result is inspected; saturation or supervisor failure is returned
  honestly and must never be reported as queued.

### Retry and privacy contract
- **D-07 — Additive dispatch error contract:** `Mailglass.SendError` gains the additive reason `:dispatch_unavailable` and additive
  `retry_class: :transient | :permanent | nil`; existing serialized fields remain compatible.
- **D-08 — Closed retry classes:** Transport errors, timeouts, HTTP 429, and HTTP 5xx retry. Permanent failures are discarded. Any
  provider-specific exceptional 4xx behavior must be explicit and adapter-aware rather than inferred by
  a broad fallback.
- **D-09 — Privacy-safe errors:** Serializable error context contains no provider response preview, recipient, or message content.

### Telemetry and closed values
- **D-10 — Truthful tracking telemetry:** Tracking remains fail-open at the HTTP boundary, but `recorded` telemetry is emitted only after a
  successful ledger write; failures receive distinct privacy-safe telemetry.
- **D-11 — One dispatch span:** A provider dispatch has one authoritative span; remove the duplicate Swoosh façade/adapter span.
- **D-12 — Finite value decoding:** Persisted and job strings map through finite explicit lookup functions. No unbounded `String.to_atom/1`
  conversion is permitted.

### the agent's Discretion
- Internal module placement, transaction composition, fixed-point scale, sweep implementation, and test
  fixture organization may follow the simplest existing package conventions that preserve compatibility.
- Tighten internal APIs where useful, but preserve documented core and inbound public façades.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- Core and inbound already expose rate-limiter façades and ETS-backed token buckets that can be driven by
  deterministic concurrency tests.
- `Mailglass.Outbound`, the Oban gateway/worker path, and the Task supervisor fallback already identify
  the durable and non-durable execution seams.
- `Mailglass.SendError`, provider adapters, tracking event ledger, and telemetry helpers provide the
  existing compatibility surface to extend.

### Known Failure Evidence
- Stale ETS read/add refill logic allowed 40 successful requests from a ten-token concurrent refill.
- Batch queueing could report success after partial persistence or an unchecked Task spawn.
- Swoosh treated permanent HTTP 4xx adapter failures as retryable and duplicated dispatch spans.
- Provider body previews could enter serialized `SendError.context`.
- Tracking ignored append failures before emitting `recorded`, and inbound execution paths used
  persisted strings with `String.to_atom/1`.

### Integration Points
- Core/inbound applications and supervisors, rate limiters, Outbound transaction orchestration, Oban
  job insertion and workers, Task supervisor gateway, provider adapters, SendError serialization,
  tracking ledger/telemetry, and inbound execution worker/provider decoding.

</code_context>

<specifics>
## Specific Ideas

Acceptance tests should reproduce the prior concurrency overspend, transaction rollback, saturated Task
supervisor, permanent-versus-transient provider outcome, privacy leak, false tracking telemetry, and
arbitrary-atom cases. Tests should use deterministic acknowledgements/barriers rather than sleeps.

</specifics>

<deferred>
## Deferred Ideas

Inbound certificate/S3/dead-evidence hardening, database lifecycle work, broad architecture factoring,
repository-wide quality gates, release certification, and all admin/operator UI work belong to later
phases or remain explicitly out of scope.

</deferred>
