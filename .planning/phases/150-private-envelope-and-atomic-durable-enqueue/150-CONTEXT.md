# Phase 150: Private Envelope and Atomic Durable Enqueue - Context

**Gathered:** 2026-08-02 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make every durable async request mean what `:queued` says: after Phase 149 preflight and rendering, Mailglass persists one complete, private, versioned outbound envelope together with its public Delivery projection, queued ledger event, and canonical `mailglass_outbound` Oban job in one transaction. This phase owns envelope fidelity, private storage, atomic enqueue, Oban readiness, explicit non-durable Task.Supervisor selection, and legacy queued-payload compatibility. Provider-wire equivalence, dispatch outcome classification, payload scrubbing/retention, and missing-payload terminal handling belong to Phase 151.

</domain>

<decisions>
## Implementation Decisions

### Private payload boundary
- **D-01:** Add a Mailglass-owned, schema-prefixed `Mailglass.Outbound.Payload` persistence boundary with one payload per delivery. Store the versioned private envelope there, never in adopter-visible `Delivery.metadata`, ledger payloads, telemetry, logs, or Oban arguments.
- **D-02:** Keep the public Delivery projection intentionally non-sensitive. New enqueue writes preserve only adopter-supplied public metadata there and remove the current `rendered_html`, `rendered_text`, `subject`, `headers`, and `recipient_field` reconstruction keys.
- **D-03:** The payload record carries tenant and delivery identity, envelope version/integrity facts, the private envelope, and lifecycle timestamps needed by Phase 151. It is private transport state, not a sent-message snapshot or new admin surface.

### Versioned envelope codec
- **D-04:** Build the envelope only after Phase 149 preflight, rendering, compliance/tracking preparation, and adapter-route selection. The worker reconstructs immutable prepared input from that envelope and never re-renders templates, rereads assigns/process state, or reselects a changed route.
- **D-05:** Version 1 round-trips the documented async-supported surface: the sole recipient in its native `to`/`cc`/`bcc` field, sender, reply-to, subject, headers, HTML, plaintext, stream, tags, public Mailglass metadata, selected adapter reference, attachments, and supported JSON-safe provider options.
- **D-06:** Use an explicit allowlisted codec rather than generic term or struct serialization. Functions, PIDs, arbitrary structs, executable assigns/private state, unknown fields, and non-JSON-safe provider options fail before persistence with `%Mailglass.SendError{type: :serialization_failed}` and bounded non-PII context.
- **D-07:** Materialize supported Swoosh attachments at enqueue so retries do not depend on mutable node-local paths or uploads. Data-backed attachments persist their bytes; readable path/upload-backed attachments are read once and stored with filename, content type, disposition, CID, and headers. Missing, unreadable, malformed, or otherwise unsupported attachment forms fail explicitly before queueing; fields are never dropped.
- **D-08:** JSON-safe provider options support only recursively bounded JSON values with deterministic key normalization. Secrets or adapter runtime configuration remain behind the persisted adapter reference and are never copied into the envelope.

### Atomic durable enqueue
- **D-09:** The Oban path uses one prefix-aware `Ecto.Multi` to insert Delivery, append the queued Event, insert Payload, and insert the `Mailglass.Outbound.Worker` job. Any step failure rolls back every step; only a committed four-part result returns `%Delivery{status: :queued}`.
- **D-10:** Oban job arguments remain exactly stable identifiers and tenant context—`delivery_id` and `mailglass_tenant_id`. The worker queue remains the compile-time canonical `:mailglass_outbound` queue.
- **D-11:** `deliver_many/2` must not retain its current post-commit `Oban.insert_all/1` stranded-work window. Each eligible one-recipient message reuses the same per-envelope atomic enqueue boundary while preserving the public per-message result semantics; atomicity is per envelope, not an all-or-nothing batch transaction.

### Adapter readiness and explicit non-durability
- **D-12:** Selecting `async_adapter: :oban` is fail-closed. Missing optional dependency, unavailable/unusable integration, wrong canonical queue configuration, or job insertion failure returns a typed `%Mailglass.SendError{type: :adapter_failure}` with a stable non-PII `reason_class`; it never falls back to Task.Supervisor and never reports queued work.
- **D-13:** `async_adapter: :task_supervisor` remains available only when explicitly selected. It is documented and checked as non-durable development/test behavior, and production readiness must reject it.
- **D-14:** Keep all optional Oban calls behind `Mailglass.OptionalDeps.Oban` so the no-optional-dependencies compile contract remains green. Extend that gateway with readiness/query helpers rather than introducing bare Oban references across the core.

### Legacy queued rows
- **D-15:** New jobs are payload-first and never write private reconstruction data to Delivery metadata. A narrowly identified legacy reader may reconstruct pre-v2.4 queued rows from the old metadata keys so an upgrade does not strand already queued work, but it must not claim complete v1 envelope fidelity.
- **D-16:** Legacy compatibility is prefix-safe and forward-only: migrations add the private table without rewriting incomplete historical metadata into a falsely complete envelope. Phase 151 owns removal/scrubbing and bounded retention after the compatibility window.

### the agent's Discretion
- Exact payload column decomposition versus a versioned JSONB envelope, provided tenant scoping, prefixing, integrity/version checks, and Phase 151 lifecycle hooks remain explicit.
- Exact bounded `reason_class` atoms and validation helper boundaries beneath the locked public SendError types.
- Exact per-envelope orchestration used by `deliver_many/2`, provided no delivery/event/payload can commit without its corresponding Oban job.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone contract
- `.planning/ROADMAP.md` — Phase 150 goal, success criteria, dependencies, and boundary with Phase 151.
- `.planning/REQUIREMENTS.md` — Authoritative ENVL-01, ENVL-02, and ENVL-04 through ENVL-08 acceptance contract.
- `.planning/STATE.md` — v2.4 scope locks, canonical queue, and generated-host proof bar.
- `.planning/phases/149-first-send-contract-foundation/149-CONTEXT.md` — Locked preflight, rendering, recipient, tenancy, and typed-error decisions that precede envelope creation.

### Milestone research
- `.planning/research/ARCHITECTURE.md` — Durable envelope boundary, codec constraints, atomic enqueue shape, legacy reader, and privacy separation.
- `.planning/research/STACK.md` — Existing Ecto/Oban/Swoosh integration recommendations and canonical `mailglass_outbound` queue.
- `.planning/research/SUMMARY.md` — Phase 150 delivery slice, attachment default, and legacy migration research gaps.
- `.planning/research/PITFALLS.md` — Verified partial-rehydration, public-metadata privacy, stranded-batch, and queue-readiness failure modes.

### Runtime and compatibility seams
- `lib/mailglass/outbound.ex` — Current preparation, metadata persistence, Oban Multi, batch post-commit insertion, and legacy rehydration implementation.
- `lib/mailglass/outbound/worker.ex` — Stable job argument and canonical queue contract.
- `lib/mailglass/outbound/delivery.ex` — Public projection and adopter metadata boundary.
- `lib/mailglass/optional_deps/oban.ex` — Optional-dependency-safe Oban gateway and tenancy restoration.
- `lib/mailglass/migrations/postgres.ex` and `lib/mailglass/migrations/postgres/v01.ex` through `v05.ex` — Versioned schema-prefix-aware migration system.
- `docs/api_stability.md` — Stable error matching and worker compatibility contract.
- `guides/production-go-live-checklist.md` and `guides/getting-started.md` — Production queue/readiness and explicit Task.Supervisor documentation seams.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.Outbound.prepare_outbound_message/1` already establishes the correct post-render, post-compliance/tracking preparation point and stable delivery ID.
- `Mailglass.Outbound.resolve_async_adapter_ref/2` already selects and validates a persistable adapter reference before enqueue.
- `Mailglass.OptionalDeps.Oban.insert/3` already composes a worker changeset into an `Ecto.Multi` without breaking optional-dependency compilation.
- `Mailglass.Repo.multi/1`, `Repo.multi_opts/1`, `Events.append_multi/3`, and the versioned Postgres migration runner provide the existing prefix-aware transaction/migration patterns.
- Swoosh's `%Swoosh.Email{}` and `%Swoosh.Attachment{}` provide the canonical field inventory and attachment-content reader needed by an allowlisted codec.

### Established Patterns
- Public failures are exception structs matched by type atom; error context is bounded and excludes recipient/message content.
- Provider calls remain outside database transactions. Phase 150 changes enqueue atomicity only and does not move dispatch into a transaction.
- All Mailglass-owned table access uses configured schema-prefix options and tenant scoping rather than relying on `search_path`.
- Worker args intentionally contain no message content or arbitrary adopter structs.
- Tests use Oban manual/inline modes with a real `oban_jobs` table and `async: false` isolation for transactional queue assertions.

### Integration Points
- `lib/mailglass/outbound.ex` — replace `base_delivery_attrs/3` private metadata leakage, add envelope creation, compose payload insertion, remove Oban-to-Task fallback, and route batch enqueue through the atomic seam.
- `lib/mailglass/outbound/worker.ex` — load payload by stable delivery/tenant identity while preserving the existing job args and queue.
- `lib/mailglass/optional_deps/oban.ex` — expose fail-closed readiness and transaction-safe insertion without bare optional references.
- `lib/mailglass/migrations/postgres.ex` plus a new version module — create the payload table and indexes under the configured prefix.
- `test/mailglass/outbound/deliver_later_test.exs`, `worker_test.exs`, migration tests, and generated/config contract tests — prove round-trip fidelity, rollback, prefix safety, queue drift, explicit fallback, and legacy reads.
- Production/getting-started/jobs documentation — replace the stale `:mailglass` queue example with `:mailglass_outbound` and state the durable/non-durable boundary exactly.

</code_context>

<specifics>
## Specific Ideas

- Treat the envelope codec as a small explicit protocol with `version`, `dump`, and `load` seams so unsupported future versions fail closed instead of being guessed.
- Prove codec correctness with structural round trips over each supported Swoosh field and negative tests for functions, arbitrary structs, unreadable attachment paths, and non-JSON-safe provider options.
- Prove transaction rollback by forcing each of payload and Oban insertion to fail and asserting zero Delivery, Event, Payload, and Job rows for that delivery ID.

</specifics>

<deferred>
## Deferred Ideas

- Sync/async wire-equivalence consolidation and provider input comparison — Phase 151.
- Retryable/terminal/uncertain dispatch outcome classification — Phase 151.
- Payload scrubbing, expiry, pruning, and missing/corrupt/scrubbed payload terminal semantics — Phase 151.
- Recipient fan-out, external object-storage attachment references, sent-message snapshots, and admin payload viewing remain out of v2.4 scope.

</deferred>

---

*Phase: 150-private-envelope-and-atomic-durable-enqueue*
*Context gathered: 2026-08-02*
