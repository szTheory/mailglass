# Phase 150: Private Envelope and Atomic Durable Enqueue - Research

**Researched:** 2026-08-02
**Domain:** Durable outbound email serialization, PostgreSQL transactions, and optional Oban integration
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Private payload boundary
- **D-01:** Add a Mailglass-owned, schema-prefixed `Mailglass.Outbound.Payload` persistence boundary with one payload per delivery. Store the versioned private envelope there, never in adopter-visible `Delivery.metadata`, ledger payloads, telemetry, logs, or Oban arguments.
- **D-02:** Keep the public Delivery projection intentionally non-sensitive. New enqueue writes preserve only adopter-supplied public metadata there and remove the current `rendered_html`, `rendered_text`, `subject`, `headers`, and `recipient_field` reconstruction keys.
- **D-03:** The payload record carries tenant and delivery identity, envelope version/integrity facts, the private envelope, and lifecycle timestamps needed by Phase 151. It is private transport state, not a sent-message snapshot or new admin surface.

#### Versioned envelope codec
- **D-04:** Build the envelope only after Phase 149 preflight, rendering, compliance/tracking preparation, and adapter-route selection. The worker reconstructs immutable prepared input from that envelope and never re-renders templates, rereads assigns/process state, or reselects a changed route.
- **D-05:** Version 1 round-trips the documented async-supported surface: the sole recipient in its native `to`/`cc`/`bcc` field, sender, reply-to, subject, headers, HTML, plaintext, stream, tags, public Mailglass metadata, selected adapter reference, attachments, and supported JSON-safe provider options.
- **D-06:** Use an explicit allowlisted codec rather than generic term or struct serialization. Functions, PIDs, arbitrary structs, executable assigns/private state, unknown fields, and non-JSON-safe provider options fail before persistence with `%Mailglass.SendError{type: :serialization_failed}` and bounded non-PII context.
- **D-07:** Materialize supported Swoosh attachments at enqueue so retries do not depend on mutable node-local paths or uploads. Data-backed attachments persist their bytes; readable path/upload-backed attachments are read once and stored with filename, content type, disposition, CID, and headers. Missing, unreadable, malformed, or otherwise unsupported attachment forms fail explicitly before queueing; fields are never dropped.
- **D-08:** JSON-safe provider options support only recursively bounded JSON values with deterministic key normalization. Secrets or adapter runtime configuration remain behind the persisted adapter reference and are never copied into the envelope.

#### Atomic durable enqueue
- **D-09:** The Oban path uses one prefix-aware `Ecto.Multi` to insert Delivery, append the queued Event, insert Payload, and insert the `Mailglass.Outbound.Worker` job. Any step failure rolls back every step; only a committed four-part result returns `%Delivery{status: :queued}`.
- **D-10:** Oban job arguments remain exactly stable identifiers and tenant context—`delivery_id` and `mailglass_tenant_id`. The worker queue remains the compile-time canonical `:mailglass_outbound` queue.
- **D-11:** `deliver_many/2` must not retain its current post-commit `Oban.insert_all/1` stranded-work window. Each eligible one-recipient message reuses the same per-envelope atomic enqueue boundary while preserving the public per-message result semantics; atomicity is per envelope, not an all-or-nothing batch transaction.

#### Adapter readiness and explicit non-durability
- **D-12:** Selecting `async_adapter: :oban` is fail-closed. Missing optional dependency, unavailable/unusable integration, wrong canonical queue configuration, or job insertion failure returns a typed `%Mailglass.SendError{type: :adapter_failure}` with a stable non-PII `reason_class`; it never falls back to Task.Supervisor and never reports queued work.
- **D-13:** `async_adapter: :task_supervisor` remains available only when explicitly selected. It is documented and checked as non-durable development/test behavior, and production readiness must reject it.
- **D-14:** Keep all optional Oban calls behind `Mailglass.OptionalDeps.Oban` so the no-optional-dependencies compile contract remains green. Extend that gateway with readiness/query helpers rather than introducing bare Oban references across the core.

#### Legacy queued rows
- **D-15:** New jobs are payload-first and never write private reconstruction data to Delivery metadata. A narrowly identified legacy reader may reconstruct pre-v2.4 queued rows from the old metadata keys so an upgrade does not strand already queued work, but it must not claim complete v1 envelope fidelity.
- **D-16:** Legacy compatibility is prefix-safe and forward-only: migrations add the private table without rewriting incomplete historical metadata into a falsely complete envelope. Phase 151 owns removal/scrubbing and bounded retention after the compatibility window.

### the agent's Discretion
- Exact payload column decomposition versus a versioned JSONB envelope, provided tenant scoping, prefixing, integrity/version checks, and Phase 151 lifecycle hooks remain explicit.
- Exact bounded `reason_class` atoms and validation helper boundaries beneath the locked public SendError types.
- Exact per-envelope orchestration used by `deliver_many/2`, provided no delivery/event/payload can commit without its corresponding Oban job.

### Deferred Ideas (OUT OF SCOPE)
- Sync/async wire-equivalence consolidation and provider input comparison — Phase 151.
- Retryable/terminal/uncertain dispatch outcome classification — Phase 151.
- Payload scrubbing, expiry, pruning, and missing/corrupt/scrubbed payload terminal semantics — Phase 151.
- Recipient fan-out, external object-storage attachment references, sent-message snapshots, and admin payload viewing remain out of v2.4 scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ENVL-01 | Private versioned payload; ID-only Oban args | Payload schema, allowlisted codec, worker load order, metadata boundary |
| ENVL-02 | Round-trip supported async surface | V1 JSON contract and attachment materialization matrix |
| ENVL-04 | Immutable prepared input before async boundary | Build envelope after `prepare_outbound_message/1` and route selection |
| ENVL-05 | Four local facts commit together or none | One prefix-aware `Ecto.Multi`, including Oban changeset insertion |
| ENVL-06 | `:oban` fails closed | Optional gateway readiness predicate and typed adapter error mapping |
| ENVL-07 | Explicit Task.Supervisor is non-durable | Branch only on explicit selection; docs/readiness contract test |
| ENVL-08 | Canonical queue has no drift | Worker constant, gateway readiness check, docs/config contract test |
</phase_requirements>

## Summary

Use one Mailglass-private payload row as the durable boundary: a versioned JSONB envelope plus explicit tenant/delivery identity, integrity facts, and timestamps. Build it only after Phase 149 has completed preflight, rendering, compliance/tracking rewrites, delivery-ID stamping, and persisted adapter-route resolution. The public Delivery remains an operational projection with adopter metadata only; Oban receives only delivery and tenant identifiers. [VERIFIED: repository `lib/mailglass/outbound.ex`, `worker.ex`, `delivery.ex`]

The existing single-send Oban multi already atomically writes Delivery, queued Event, and Job, but omits Payload. The current batch flow commits delivery/event rows and calls `Oban.insert_all/1` afterward, which can strand queued rows. Replace both durable paths with one reusable per-envelope multi; Ecto executes Multi operations in order and rolls back earlier successful operations when a later operation fails. [VERIFIED: repository `lib/mailglass/outbound.ex`] [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html]

**Primary recommendation:** Add `Outbound.Payload` and `Outbound.Envelope` now, use a V1 explicit JSON codec and materialized attachment bytes, and make the sole durable enqueue path `Delivery -> queued Event -> Payload -> Oban Job` through the optional-dependency gateway.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Prepared-envelope construction and validation | API / Backend | — | It consumes rendered in-memory data before persistence and rejects unsafe serialization. [VERIFIED: repository `lib/mailglass/outbound.ex`] |
| Private payload persistence | Database / Storage | API / Backend | One prefix-scoped row per Delivery makes recovery durable and access-bounded. [VERIFIED: repository migration and Repo patterns] |
| Atomic enqueue | API / Backend | Database / Storage | The backend composes the transaction; PostgreSQL commits or rolls back its local writes together. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] |
| Job execution/readiness | API / Backend | Database / Storage | Oban uses the host Repo and executes jobs from its configured queue. [CITED: https://oban.hexdocs.pm/Oban.html] |
| Public projection/privacy boundary | API / Backend | Database / Storage | Delivery metadata is adopter-visible; private reconstruction state must not be stored there. [VERIFIED: repository `lib/mailglass/outbound/delivery.ex`] |

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists. Project constraints applied from `CLAUDE.md`: keep all Oban references behind `Mailglass.OptionalDeps.Oban`; retain the no-optional-dependencies compilation lane; all Mailglass-owned table access must use schema-prefix options and tenant scoping; errors use structured `%Mailglass.Error{}` types with no PII in context; provider calls remain outside database transactions; and `mailglass_outbound` is canonical. [VERIFIED: repository `CLAUDE.md`, `repo.ex`]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto / Ecto SQL | `3.14.1` / `3.14.0` locked; Ecto 3.14.1 released 2026-07-09 | Prefix-aware `Ecto.Multi` for local durability | Existing Repo facade exposes `multi/1` and step-level `multi_opts/1`; Multi gives rollback semantics needed for the four-part enqueue. [VERIFIED: repository `mix.lock`, `lib/mailglass/repo.ex`; CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] |
| Oban | `2.23.0` locked; released 2026-05-27 | Optional durable host-owned job queue | `Worker.new/2` creates an insertable job changeset, including in a transaction. [VERIFIED: repository `mix.lock`; CITED: https://oban.hexdocs.pm/Oban.Worker.html] |
| Swoosh | `1.26.3` locked; released 2026-07-05 | Prepared provider message and attachment representation | Existing canonical email representation contains the supported envelope fields. [VERIFIED: repository `mix.lock`, `deps/swoosh/lib/swoosh/email.ex`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Mailglass.OptionalDeps.Oban` | repo-native | Optional-dependency boundary | Extend with readiness/config helpers and transactional insertion only; never add bare `Oban.*` references elsewhere. [VERIFIED: repository `lib/mailglass/optional_deps/oban.ex`] |
| PostgreSQL JSONB (`:map`) | PostgreSQL 14.17 CLI available | Versioned private envelope storage | Store V1 normalized JSON envelope in one private table; use normal scalar columns for identity/version/timestamps. [VERIFIED: local environment `psql --version`; VERIFIED: repository migrations] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Private JSONB envelope table | Generic serialization into Oban args | Rejected: it violates the ID-only job contract and accepts unsafe process/executable state. [VERIFIED: repository Context D-06/D-10] |
| Per-envelope `Ecto.Multi` for batch | Existing post-commit `insert_all/1` | Rejected: a successful delivery/event commit can exist without a job. [VERIFIED: repository `lib/mailglass/outbound.ex`] |
| Explicit Task.Supervisor branch | Implicit fallback when Oban is missing | Rejected: it turns a durable request into non-durable best effort. [VERIFIED: repository Context D-12/D-13] |

**Installation:** No packages are installed in this phase. [VERIFIED: repository `mix.exs`, Context scope]

## Package Legitimacy Audit

Not applicable: Phase 150 adds no external dependency. Ecto, Oban, and Swoosh are existing locked dependencies, not new package recommendations. [VERIFIED: repository `mix.exs`, `mix.lock`]

## Architecture Patterns

### System Architecture Diagram

```text
deliver_later / each deliver_many item
  -> Phase 149 preflight + render + compliance/tracking
  -> stamp delivery_id + resolve persisted adapter_ref
  -> Envelope.dump_v1 (allowlist + materialize attachments)
       -> serialization error => no DB row, event, payload, or job
  -> OptionalDeps.Oban.ready?
       -> not ready => SendError(:adapter_failure), no queued work
  -> one Repo.multi / Ecto.Multi
       -> Delivery (public metadata only)
       -> queued Event
       -> Outbound.Payload (private envelope)
       -> Worker.new(%{delivery_id, mailglass_tenant_id}) + Oban insert
       -> commit => queued Delivery
       -> any failure => rollback all four

Worker(delivery_id, tenant_id)
  -> restore tenant
  -> Payload.load_v1 first
       -> Payload absent => narrowly scoped legacy metadata reader
  -> Phase 151 dispatch/lifecycle ownership
```

The current code already prepares before `resolve_async_adapter_ref/2`, inserts the Delivery/Event/Job in one single-send multi, and uses only stable job identifiers. The plan should preserve that ordering while adding envelope build and Payload insertion before job insertion. [VERIFIED: repository `lib/mailglass/outbound.ex`, `worker.ex`]

### Recommended Project Structure

```text
lib/mailglass/outbound/
├── envelope.ex       # V1 dump/load, JSON validation, attachment materialization
├── payload.ex        # private schema, changeset, tenant/delivery lookup
├── worker.ex         # ID-only args; payload-first recovery entrypoint
└── delivery.ex       # remains public projection; no private content
lib/mailglass/migrations/postgres/
└── v06.ex            # payload table/indexes under configured prefix
```

### Pattern 1: Explicit V1 codec

**What:** `Envelope.dump/1` emits a map headed by an integer/string version and only known JSON fields. `Envelope.load/1` accepts V1 exactly, reconstructs a `%Swoosh.Email{}` with the original recipient field, and rejects unknown/malformed versions rather than guessing. [VERIFIED: repository Context D-04..D-08]

**When to use:** Every new durable Oban enqueue and every payload-backed worker read.

**Example:**

```elixir
# Source: locked Phase 150 Context + Swoosh.Email field contract
with {:ok, envelope} <- Mailglass.Outbound.Envelope.dump(prepared, adapter_ref),
     {:ok, payload_attrs} <- Mailglass.Outbound.Payload.from_envelope(envelope, prepared) do
  # compose only after all non-DB validation/materialization succeeded
end
```

Codec rules: use strings for JSON map keys; preserve the recipient-field discriminator (`"to" | "cc" | "bcc"`); normalize atom/string public metadata keys deterministically; permit only bounded maps/lists, strings, finite numbers, booleans, and null in `provider_options`; and reject Swoosh `assigns`/`private`, functions, PIDs, arbitrary structs, and unknown values as `:serialization_failed`. [VERIFIED: repository Context D-05/D-06/D-08]

### Pattern 2: Materialize attachments before the transaction

**What:** Convert every supported `%Swoosh.Attachment{}` to a data-backed V1 attachment before DB work. Swoosh represents attachments with `data` or `path`, and its content helper reads `data || File.read!(path)`; a path/upload therefore cannot be retried safely on another node unless its bytes are copied at enqueue. [VERIFIED: repository `deps/swoosh/lib/swoosh/attachment.ex`; CITED: https://swoosh.hexdocs.pm/Swoosh.Email.html]

**When to use:** Within `Envelope.dump/1`, before constructing the Multi.

**Example:**

```elixir
# Source: locked Phase 150 Context; adapt exact field validation to Swoosh 1.26.3
case safe_attachment_content(attachment) do
  {:ok, bytes} -> {:ok, %{filename: filename, content: bytes, content_type: type, ...}}
  {:error, reason} -> {:error, SendError.new(:serialization_failed, context: %{reason_class: reason})}
end
```

Do not call a raising content function without rescue/normalization; do not retain a path, `%Plug.Upload{}`, or a function as the durable representation. [VERIFIED: repository Context D-07; VERIFIED: repository `deps/swoosh/lib/swoosh/attachment.ex`]

### Pattern 3: Reusable atomic durable enqueue

**What:** Have `enqueue_oban/3` and each eligible `deliver_many/2` item call the same helper that receives only an already prepared message, adapter ref, and dumped envelope. The helper adds four named operations in exactly this order: `:delivery`, `:event_queued`, `:payload`, `:job`. [VERIFIED: repository Context D-09/D-11]

**When to use:** `async_adapter: :oban` only.

**Example:**

```elixir
# Source: Ecto.Multi + existing Mailglass prefix convention
Ecto.Multi.new()
|> Ecto.Multi.insert(:delivery, Delivery.changeset(%Delivery{id: delivery_id}, public_attrs), Repo.multi_opts())
|> Events.append_multi(:event_queued, fn %{delivery: d} -> queued_event(d, tenant_id, ik) end)
|> Ecto.Multi.insert(:payload, Payload.changeset(%Payload{}, payload_attrs), Repo.multi_opts())
|> Mailglass.OptionalDeps.Oban.insert(:job, fn %{delivery: d} ->
  Worker.new(%{"delivery_id" => d.id, "mailglass_tenant_id" => tenant_id})
end)
|> Repo.multi()
```

Every step that writes a Mailglass table needs `Repo.multi_opts()`; the gateway must preserve transaction insertion rather than returning the unchanged Multi when `:oban` was explicitly selected but unavailable. [VERIFIED: repository `lib/mailglass/repo.ex`, `optional_deps/oban.ex`; CITED: https://ecto.hexdocs.pm/Ecto.Multi.html]

### Anti-Patterns to Avoid

- **Metadata reconstruction for new rows:** remove the five private keys from `base_delivery_attrs/3`; only the isolated legacy reader may inspect them. [VERIFIED: repository Context D-02/D-15]
- **Payload insert after `Repo.multi/1`:** it recreates the stranded-work window and violates ENVL-05. [VERIFIED: repository Context D-09]
- **Batch `insert_all` then jobs:** it cannot meet per-envelope atomicity without a separate transaction per eligible message. [VERIFIED: repository `lib/mailglass/outbound.ex`]
- **Readiness inferred only from `Code.ensure_loaded?/1`:** a compiled module does not prove a running host Oban instance or canonical queue. [VERIFIED: repository Context D-12; CITED: https://oban.hexdocs.pm/Oban.html]
- **Dispatch inside this transaction:** provider calls remain out of scope and must stay outside database transactions. [VERIFIED: repository `CLAUDE.md`, Context boundary]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Local all-or-nothing writes | Custom compensation/rollback code | `Ecto.Multi` through `Repo.multi/1` | Ecto reports the failed operation and rolls back earlier successes. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] |
| Durable execution record | A second queue/outbox/broker | Existing host-owned Oban job in the same Multi | Already pinned and the worker has stable ID-only args. [VERIFIED: repository `mix.lock`, `worker.ex`] |
| Email field model | A parallel Mailglass email struct | Explicit map codec around `%Swoosh.Email{}` | Swoosh owns the canonical provider message surface. [CITED: https://swoosh.hexdocs.pm/Swoosh.Email.html] |
| Attachment path durability | Node-local path references | Persisted attachment bytes | Swoosh paths are resolved by filesystem read at send time. [VERIFIED: repository `deps/swoosh/lib/swoosh/attachment.ex`] |

**Key insight:** The custom work is intentionally narrow—an allowlisted transport codec—not a general serializer. General term serialization would make unknown executable or process-local state durable, which the locked contract forbids. [VERIFIED: repository Context D-06]

## Common Pitfalls

### Pitfall 1: Return queued after only a partial durable write

**What goes wrong:** Delivery/event can commit while Payload or job does not, leaving a public `:queued` claim with no recoverable work. [VERIFIED: repository Context D-09]

**How to avoid:** Validate/dump before the multi; put Payload and Oban insertion in the same multi; force each failure in tests and assert zero rows/jobs for the delivery ID. [CITED: https://ecto.hexdocs.pm/Ecto.Multi.html]

### Pitfall 2: Treat path/upload attachments as durable

**What goes wrong:** A retry reads a mutated or unavailable local file and no longer matches the prepared message. [VERIFIED: repository `deps/swoosh/lib/swoosh/attachment.ex`]

**How to avoid:** Read once at enqueue with bounded error handling; persist data plus filename/content-type/type/CID/headers; fail pre-queue if it cannot be represented. [VERIFIED: repository Context D-07]

### Pitfall 3: Fail open from Oban to Task.Supervisor

**What goes wrong:** Current `available?/0` path falls back to Task.Supervisor, so `:oban` callers can receive queued work that vanishes at process/node loss. [VERIFIED: repository `lib/mailglass/outbound.ex`]

**How to avoid:** Branch exactly: explicit `:task_supervisor` permits non-durable behavior; `:oban` requires gateway readiness and returns `SendError(:adapter_failure)` on any readiness/insertion failure. [VERIFIED: repository Context D-12/D-13]

### Pitfall 4: Queue-name drift

**What goes wrong:** Worker declares `:mailglass_outbound`, but the production guide currently shows `:mailglass`; jobs may persist but never execute. [VERIFIED: repository `worker.ex`, `guides/production-go-live-checklist.md`]

**How to avoid:** Make the worker queue the single canonical source exposed by a helper (or inspect `Worker.__opts__/0` inside the gateway), assert configured queue presence/readiness, and update guide/config contract tests. [VERIFIED: repository Context D-10/D-12]

### Pitfall 5: Claim legacy metadata is V1 complete

**What goes wrong:** Existing rehydration only reconstructs recipient, subject, body, headers, and module-dependent metadata; it loses fields such as attachments/reply-to/provider options. [VERIFIED: repository `lib/mailglass/outbound.ex`]

**How to avoid:** Payload-first for all new rows; narrowly identify no-payload pre-v2.4 queued rows for a temporary legacy reader; do not backfill incomplete metadata as V1. [VERIFIED: repository Context D-15/D-16]

## Code Examples

### Fail-closed adapter selection

```elixir
# Source: locked Phase 150 Context
case async_adapter do
  :task_supervisor -> enqueue_task_supervisor(prepared, adapter_ref, opts)
  :oban ->
    with :ok <- OptionalDeps.Oban.ready?(canonical_queue: Worker.queue()),
         {:ok, envelope} <- Envelope.dump(prepared, adapter_ref) do
      enqueue_oban_atomically(prepared, adapter_ref, envelope)
    end
  _ -> {:error, SendError.new(:adapter_failure, context: %{reason_class: :async_adapter_invalid})}
end
```

The exact gateway API is discretionary, but readiness must distinguish dependency absent, integration unavailable, and canonical queue unavailable without exposing configuration secrets. [VERIFIED: repository Context D-12/D-14]

### Payload-first worker load

```elixir
# Source: locked Phase 150 Context
with {:ok, delivery} <- load_delivery(delivery_id),
     {:ok, prepared} <- Payload.load_prepared(delivery) do
  dispatch_prepared(delivery, prepared)
else
  {:error, :payload_not_found} -> load_legacy_pre_v24_queued_message(delivery)
  {:error, error} -> {:error, error}
end
```

The legacy branch must be restricted to a recognizably old, queued row and is intentionally incomplete; Phase 151 owns missing/corrupt/scrubbed terminal behavior. [VERIFIED: repository Context D-15/D-16]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Partial private message snapshot in public `Delivery.metadata` | Versioned separate payload plus public projection | Phase 150 | Enables recovery without exposing queue content in the normal metadata bag. [VERIFIED: repository Context D-01/D-02] |
| `deliver_many/2` post-commit `Oban.insert_all/1` | Per-envelope transactional job insertion | Phase 150 | Removes stranded queued deliveries from job-insertion failure. [VERIFIED: repository Context D-11] |
| Implicit missing-Oban Task fallback | Explicit Task choice; `:oban` fail closed | Phase 150 | Makes durable API semantics truthful. [VERIFIED: repository Context D-12/D-13] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A lightweight Oban queue-readiness query can reliably distinguish a running canonical queue in every supported host topology. | Architecture Patterns / fail-closed selection | Gateway may need a narrower “integration configured” contract plus the generated-host execution proof in Phase 153. |

All remaining material claims are repository-verified or cited from official documentation.

## Open Questions

1. **Exact Oban readiness predicate**
   - What we know: Oban 2.23 exposes configuration and queue inspection APIs, while the project needs failure before its own job is reported queued. [CITED: https://oban.hexdocs.pm/Oban.html]
   - What's unclear: Whether a transient producer state should reject enqueue or whether configuration plus a successful transactional insert is sufficient for ENVL-06.
   - Recommendation: Plan a focused gateway test seam with injected outcomes. Treat missing dependency, unregistered instance, wrong queue config, and insert failure as fail-closed; do not require proving a worker is actively polling inside the transaction.

2. **Payload integrity fact**
   - What we know: D-03 requires an integrity/version fact but leaves representation discretionary.
   - What's unclear: Whether integrity is a SHA-256 checksum column, a checksum inside the envelope, or both.
   - Recommendation: Store `envelope_version` and a SHA-256 hex digest over canonical encoded envelope bytes as columns; verify before load. This is an implementation recommendation derived from the locked integrity requirement. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | compile and test | ✓ | Elixir 1.19.5 / Mix 1.19.5 | — [VERIFIED: local environment] |
| PostgreSQL CLI | migration/prefix test support | ✓ | 14.17 | — [VERIFIED: local environment] |
| Oban dependency | durable path/manual worker tests | ✓ in lock/deps | 2.23.0 | Explicit Task.Supervisor only for non-durable dev/test behavior. [VERIFIED: repository `mix.lock`] |
| Docker | optional local production-shaped host setup | ✓ | 29.5.2 | Local Postgres. [VERIFIED: local environment] |

**Missing dependencies with no fallback:** None identified for implementation. [VERIFIED: local environment]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (repository-native) [VERIFIED: repository `test/`] |
| Config file | `test/test_helper.exs`; shared `Mailglass.MailerCase`/`DataCase` support [VERIFIED: repository `test/`] |
| Quick run command | `mix test test/mailglass/outbound/deliver_later_test.exs test/mailglass/outbound/worker_test.exs --warnings-as-errors` [VERIFIED: repository test layout] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: repository `mix.exs`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ENVL-01 | New durable enqueue keeps private fields out of Delivery/Event/args and writes exactly one Payload | integration | `mix test test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | ✅ extend |
| ENVL-02 | V1 round trips addresses, bodies, headers, metadata/tags, route, attachments, safe options; rejects unsupported terms | unit + integration | `mix test test/mailglass/outbound/envelope_test.exs --warnings-as-errors` | ❌ Wave 0 |
| ENVL-04 | Prepared render/route survives config/template change before worker execution | manual-Oban integration | `mix test test/mailglass/outbound/worker_test.exs --warnings-as-errors` | ✅ extend |
| ENVL-05 | Payload/job failure rolls back Delivery/Event/Payload/job; batch is atomic per item | transactional integration | `mix test test/mailglass/outbound/deliver_later_test.exs test/mailglass/outbound/deliver_many_test.exs --warnings-as-errors` | ✅ extend |
| ENVL-06 | Explicit `:oban` unavailable, unready, queue drift, or insert failure returns typed error and no work | unit + integration | `mix test test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | ✅ extend |
| ENVL-07 | Explicit Task path is documented non-durable and rejected by production-readiness seam | config/doc contract | `mix test test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors` | ✅ extend |
| ENVL-08 | Worker, guide, generated config and readiness use `mailglass_outbound` | contract | `mix test test/mailglass/outbound/worker_test.exs test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors` | ✅ extend |

### Sampling Rate

- **Per task commit:** focused commands above, plus `mix compile --no-optional-deps --warnings-as-errors` for gateway/worker changes. [VERIFIED: repository `CLAUDE.md`, `optional_deps/oban.ex`]
- **Per wave merge:** `mix test --warnings-as-errors`.
- **Phase gate:** full suite green and migration/prefix tests before verification.

### Wave 0 Gaps

- [ ] `test/mailglass/outbound/envelope_test.exs` — V1 structural round trips, bounds, unsupported values, attachment materialization.
- [ ] Add transaction-failure injection seam/tests for Payload and gateway job insert—assert all four stores are empty after rollback.
- [ ] Extend `test/mailglass/migration_test.exs` and `schema_prefix_hardening_test.exs` for V06 create/down, payload table indexes, hostile `search_path`, and no false backfill.
- [ ] Update manual Oban tests to `async: false`; MailerCase documents this global-mode requirement. [VERIFIED: repository `test/support/mailer_case.ex`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No new human/service authentication surface. [VERIFIED: phase scope] |
| V3 Session Management | no | No browser session surface. [VERIFIED: phase scope] |
| V4 Access Control | yes | Tenant-scoped Payload lookup and configured schema prefix; worker restores tenant from ID-only args. [VERIFIED: repository Context D-01/D-10/D-16] |
| V5 Input Validation | yes | Allowlisted codec; recursively bounded JSON; reject unsafe attachment/options before persistence. [VERIFIED: repository Context D-06..D-08] |
| V6 Cryptography | yes | Use platform `:crypto` SHA-256 only if storing the required integrity digest; never hand-roll cryptography. [ASSUMED] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Rendered content/tokens exposed in public metadata or jobs | Information Disclosure | Private Payload table; ID-only job args; explicit assertion over Delivery/Event/telemetry data. [VERIFIED: repository Context D-01/D-02/D-10] |
| Executable/unsafe term made durable | Tampering / Denial of Service | Allowlist and JSON-safe bounded validation; no atom creation from persisted input. [VERIFIED: repository Context D-06] |
| Cross-tenant payload read | Information Disclosure | Tenant identity on payload and tenant scope on every lookup; prefix-aware multi operations. [VERIFIED: repository Context D-01/D-16, `repo.ex`] |
| False durable success from missing/miswired Oban | Repudiation / Availability | Fail-closed readiness, transactional job insertion, and queue-name contract checks. [VERIFIED: repository Context D-09/D-12] |

## Sources

### Primary (HIGH confidence)

- Repository: `150-CONTEXT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md` — locked scope and acceptance contract.
- Repository: `lib/mailglass/outbound.ex`, `outbound/worker.ex`, `outbound/delivery.ex`, `optional_deps/oban.ex`, `repo.ex`, migration runner, and tests — current seams and concrete gaps.
- Repository dependency sources: `deps/swoosh/lib/swoosh/attachment.ex` and `email.ex` — installed Swoosh 1.26.3 attachment/read behavior and field surface.

### Secondary (MEDIUM confidence)

- [Ecto.Multi v3.14.1](https://ecto.hexdocs.pm/Ecto.Multi.html) — transactional operation ordering, failure/rollback, and callbacks.
- [Oban v2.23.0](https://oban.hexdocs.pm/Oban.html) and [Oban.Worker v2.23.0](https://oban.hexdocs.pm/Oban.Worker.html) — queue/config APIs, job changesets, transactional insertion, and result semantics.
- [Swoosh.Email](https://swoosh.hexdocs.pm/Swoosh.Email.html) — public field and attachment API documentation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — exact locked versions verified in `mix.lock`; official docs checked.
- Architecture: HIGH — locked Context plus current implementation identifies exact seams and transaction defect.
- Pitfalls: HIGH — direct current-code evidence, especially metadata reconstruction, fallback, queue drift, and batch post-commit insertion.

**Research date:** 2026-08-02
**Valid until:** 2026-09-01 for repository findings; re-check official Oban APIs before execution if dependency lock changes.
