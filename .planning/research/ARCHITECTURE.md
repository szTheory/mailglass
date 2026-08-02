# Architecture Research

**Domain:** v2.4 outbound first-adopter correctness for a Phoenix transactional-email library
**Researched:** 2026-08-02
**Confidence:** HIGH for the current-state inventory and proposed boundaries; MEDIUM for third-party worker behavior (official current documentation was checked, but Mailglass pins may differ).

## Recommended Architecture

Keep the existing `Message -> Renderer -> Outbound -> Delivery/Event -> Adapter` shape. The corrective change is to make the durable boundary an explicit, private, one-recipient **OutboundEnvelope**, rather than treating the public Delivery metadata bag as a partial message snapshot. This is an additive correction, not a new transport subsystem.

```
 caller
   │ %Message{Swoosh.Email}
   ▼
 Tenant preflight ──► recipient/envelope validation ──► suppression/rate/stream
   │                         │                              │
   │                         └── one recipient only          └── current state checks
   ▼
 Renderer (truthful options; no invented bodies)
   ▼
 outbound preparation (delivery id, tracking, RFC 8058 headers)
   ▼
 Envelope codec ───────────► private durable payload
   │                               │
   │                               ├── Delivery projection + queued Event
   │                               └── Oban job {delivery_id, tenant_id}
   ▼
 sync adapter call                    async Worker
   │                                      │
   └────────────── same reconstructed envelope ──────────────┘
                                          ▼
                          retry classifier -> retry | cancel | success
                                          ▼
                    dispatch/failure Event + Delivery projection; scrub payload

 RFC 8058 POST -> verified token -> Delivery (unscoped lookup only) -> one Multi:
   unsubscribe Event + address_stream Suppression + optional lifecycle hook
```

### Current vs. new responsibilities

| Component | Current responsibility | v2.4 responsibility |
|---|---|---|
| `Mailglass.Message` | Public, mutable authoring wrapper around `Swoosh.Email`. | Remains public input only. Do not serialize it or adopter metadata wholesale. Add/centralize supported-envelope validation at the outbound boundary. |
| `Mailglass.Tenancy` | SingleTenant returns `"default"` from `current/0`, but `Outbound` calls `assert_stamped!/0`, so unstamped first sends still raise. | Expose one preflight that resolves the effective tenant: implicit `"default"` only when the configured resolver is SingleTenant; otherwise require an explicit process stamp. The resolved id is then the only tenant value used by the transaction and job args. |
| `Mailglass.Renderer` | Always derives plaintext from HTML and always sets both bodies; options are passed only to HEEx rendering. | Define body truth: preserve an explicitly supplied text body; render/in-line HTML only when supplied; generate text only when documented option/policy says to. Return a rendered message whose bodies are exactly the bytes to dispatch and persist. |
| `Mailglass.Outbound` | Preflights, renders, persists projection data; async stores only `rendered_html`, `rendered_text`, `subject`, and headers inside public `Delivery.metadata`. | Own `Envelope.build/1`, the one-recipient rule, private payload insert, and one commit that contains projection/event/payload/job. Both sync and async dispatch through `Envelope.to_message/1`. |
| `Delivery` | Operator-facing mutable send projection and adopter metadata; `recipient` is silently the first `to` address. | Stays the non-secret projection. It must not be the source of wire reconstruction and should retain only allowed operator facts after send. |
| `Outbound.Payload` (new schema/module) | Does not exist. | Private, internal durable data: versioned canonical envelope, lifecycle state, `scrubbed_at`, and bounded retention timestamp. It is never returned by public delivery APIs, telemetry, events, or admin listing. |
| `Outbound.Worker` | Loads a Delivery by ID and returns `{:error, ...}` for all failures, making permanent/configuration failures retry up to 20 times. | Loads envelope by delivery ID under restored tenant; maps classified outcomes to `:ok`, `{:error, retryable_reason}`, or `{:cancel, terminal_reason}`. It never treats a missing/scrubbed payload as recoverable. |
| `UnsubscribeController` / `AutoSuppress` | POST appends an `:unsubscribed` event and lifecycle callback; webhook projection has a separate auto-suppression path. | The POST transaction itself inserts the stream-scoped suppression with conflict-safe idempotency. The event and suppression either both commit or neither commits. AutoSuppress remains the webhook-only projection mechanism. |
| Reference host / journey runner | Existing usage proof covers installation, send, webhook, and operator paths. | A generated, production-shaped host becomes a release proof consumer: no test-only adapter or helper shortcut; it uses public configuration, migration and send seams. |

## Durable Envelope Boundary

### One-recipient contract

Validate before suppression, rendering, persistence, and provider selection:

1. exactly one normalized envelope recipient;
2. no additional `to`, `cc`, or `bcc` recipient that would make the SMTP envelope multi-recipient;
3. reject unsupported message shapes with a structured `SendError`, rather than silently choosing `[first | _]`.

This is deliberately a **validation-first** design, not a v2.4 fan-out feature. Fan-out would require per-recipient rendering/tracking/unsubscribe identities and distinct delivery rows. Silently accepting a multi-recipient email is the incorrect alternative because it records and suppresses only one address while Swoosh can send to several.

### Envelope contents and codec

Persist a versioned map (for example `payload_version: 1`) sufficient to reconstruct the exact supported `Swoosh.Email` passed to `Mailglass.Adapters.Swoosh`: normalized recipient mailbox, `from`, `reply_to`, subject, HTML body, text body, headers, attachments and any other documented, serializable Swoosh wire field. Store Mailglass dispatch facts separately: tenant id, stream, mailable identity/function where needed, delivery id, adapter ref, and an allowlisted immutable metadata subset.

The codec must reject functions, PIDs, arbitrary structs, non-serializable attachments, and unknown future fields at enqueue time. It must also have round-trip tests comparing the supported Swoosh fields from the sync prepared message to `Envelope.to_message/1`; comparing only rendered body strings is insufficient. If an attachment representation cannot be made durable without copying or retaining adopter-owned bytes, declare it unsupported for `deliver_later/2` until a bounded object-storage/reference contract exists. Never fall back to dropping it.

`Delivery.metadata` currently mixes adopter metadata and rendered private content. Move the four current reconstruction keys out of it through a migration/backfill-compatible read: new code reads the payload table first, old queued rows can read legacy metadata only during a short compatibility window, and scrubber removes both legacy private keys and the new private payload. Do not copy arbitrary adopter metadata into the private payload.

### Durable enqueue transaction

For Oban, make enqueue atomic:

```
Repo.transaction / Ecto.Multi (with explicit Mailglass schema prefix)
  insert Delivery projection
  append queued Event
  insert Outbound.Payload
  insert Oban Worker job {delivery_id, mailglass_tenant_id}
commit -> return queued Delivery
```

If any step fails, none is durable; specifically never return `:queued` after a payload insert without a job. `Ecto.Multi` transaction semantics suit this local database atomicity, while the adapter remains outside the transaction to preserve the existing pool/latency boundary. Task.Supervisor is not durable and cannot satisfy this contract: retain it only as an explicitly non-durable development/test adapter, or make `deliver_later/2` fail closed when Oban is unavailable in production.

The existing batch path inserts database rows in one transaction and calls `Oban.insert_all` after commit, creating a stranded queued-delivery window. For v2.4's documented one-recipient path, route `deliver_many/2` through the same per-envelope atomic enqueue (or explicitly keep batch out of the correctness guarantee); do not leave it implicitly equivalent.

## Renderer Truth Boundary

The renderer must model three distinct supported cases instead of overwriting them all:

| Input | Result to persist and dispatch |
|---|---|
| HTML only | Render/in-line HTML, then generate plaintext only if the documented automatic-text option is enabled. |
| Explicit HTML + explicit text | Preserve explicit text exactly; transform only HTML. |
| Text only | Preserve text; do not invent an empty/derived HTML part. |

The chosen renderer options must be part of the synchronous prepared message before `Envelope.build/1`, not re-evaluated in the worker. That makes retries repeat a wire-equivalent immutable envelope rather than re-rendering against changed templates, config, time, or assigns.

## Retry, Failure, and Privacy Semantics

### Retry classifier

Create an internal `Outbound.Retry` classifier at the adapter boundary. It consumes normalized `Mailglass.SendError` context, not provider-specific string messages.

| Result class | Worker result | Delivery/event action |
|---|---|---|
| accepted by provider | `:ok` | dispatch projection/event, scrub payload after this transaction commits |
| transient transport, timeout, provider 5xx, explicit deferral | `{:error, safe_reason}` | retain payload; record attempt-safe failure telemetry/event if desired; Oban schedules retry |
| malformed envelope, missing/scrubbed payload, unresolvable persisted adapter, 4xx recipient/configuration/auth error | `{:cancel, safe_reason}` | terminal `:failed` projection + event; scrub immediately or on bounded terminal-retention policy |
| persistence failure after provider acceptance | retry reconciliation, not blind provider resend | retain payload and use an explicit uncertain-dispatch/reconciler state keyed by idempotency/delivery id |

The last row is important: provider success followed by Multi#2 failure is not safely retryable as another send. This existing sync/async two-Multi shape has at-least-once dispatch semantics; the library should surface/repair the ambiguous state rather than promise exactly once. Oban documents `{:error, reason}` as retryable and `{:cancel, reason}` as non-retrying, so classification belongs before the worker return.

### Payload lifecycle

`Outbound.Payload` is an internal sensitive store, not a new audit record. Its state machine is `queued -> dispatching? -> dispatched|terminal`, with `scrubbed_at` independent from the public delivery status.

* On successful dispatch, commit delivery/event outcome first, then clear envelope body/header/attachment data in the same outcome Multi (or a transactionally coupled scrub step); leave only lifecycle timestamps and non-content integrity/version facts.
* On retryable failure, retain it only through the retry window.
* On terminal failure, scrub according to the explicit short retention policy, not indefinite operator convenience.
* A periodic pruner deletes scrubbed/timed-out payload rows and fails closed if a queued row's payload has expired. It must be tenant-scoped and schema-prefixed.

No plaintext recipient, subject, body, headers, attachment bytes, or provider error body belongs in telemetry, event normalized payload, public Delivery metadata, or a default admin surface. Existing Swoosh error normalization already avoids most message fields; preserve that boundary when adding retry causes.

## Atomic Unsubscribe Convergence

The controller's token lookup is intentionally unscoped before it knows the tenant; retain the narrow audit breadcrumb and immediately re-stamp `delivery.tenant_id`. In one `Repo.multi`, do all of:

1. append the idempotent `:unsubscribed` event keyed `unsubscribe:<delivery_id>`;
2. resolve the canonical event on conflict;
3. `AutoSuppress.build_attrs(canonical_event, delivery)` and insert its `:address_stream` entry using the existing unique conflict target;
4. run the configured lifecycle hook only if it is contractually transaction-safe.

The canonical event enables replay idempotency, while the suppression unique index makes duplicate POSTs no-ops. The transaction guarantees no committed unsubscribe event without its enforceable suppression. `Suppression.check_before_send/1` remains a fresh preflight check for both sync and async enqueue; do not attempt to cancel already accepted provider requests. RFC 8058 requires a tokenized HTTPS URI that identifies recipient/list, no cookies/auth context, and no redirect for POST; the existing signed token and 200 empty response are compatible once the atomic write is fixed.

## Generated-host Proof Boundary

Use a generated Phoenix host under a disposable directory/database as the external consumer, rather than adding more library-only fixtures. It must:

1. install published package constraints, run `deps.get`, compile and migrations;
2. configure `Mailglass.Repo`, Oban with the `:mailglass_outbound` queue, a production-shaped Swoosh adapter/test endpoint, compliance host/signing, and default SingleTenant—without `Tenancy.put_current/1`;
3. invoke only public APIs for one sync and one async one-recipient message, then compare captured provider email fields with expected rendered text/HTML/headers and prove no extra recipient;
4. post the RFC 8058 endpoint twice, prove one stream suppression and that a future send is suppressed;
5. prove a retryable and terminal adapter outcome, payload scrub/retention behavior, feedback ingest, and production operator mount;
6. fail release when host configuration, generated code, migration prefixing, or public seams drift.

Keep the host's assertions outside production library code. Its job is integration proof, not a second framework API or a replacement for focused unit/property tests.

## Alternatives Considered

| Design | Decision | Why |
|---|---|---|
| Continue storing a partial snapshot in `Delivery.metadata` | Reject | It already loses `from`, reply-to, attachments and recipient cardinality; it also exposes durable private content through a public projection. |
| Serialize `%Message{}` into Oban args | Reject | Functions/assigns/structs may be non-JSON-safe and payload content would live in the job table without the lifecycle/pruning contract. |
| Re-render in worker from mailable module | Reject | Code, templates, assigns, config, and time can change after enqueue; it cannot prove wire equivalence. |
| Fan out multi-recipient mail inside this milestone | Defer | Correct fan-out is a larger product feature with per-recipient delivery, suppression and unsubscribe semantics. v2.4 validates exactly one recipient. |
| Make only the event idempotent on one-click POST | Reject | It leaves suppression asynchronously dependent on another projection and allows a committed opt-out that future sends do not enforce. |
| Retry every adapter failure | Reject | Permanent configuration/recipient failures consume 20 attempts and retain private content unnecessarily; ambiguous post-acceptance failures can duplicate mail. |
| Use Task.Supervisor as a production fallback | Reject for durable contract | A spawned task has no transactional relation to delivery persistence and is lost on process/node failure. |

## Recommended Project Structure

```
lib/mailglass/
├── outbound.ex                     # public orchestration; no payload internals exposed
├── outbound/
│   ├── delivery.ex                 # public projection
│   ├── envelope.ex                 # supported fields, validation, codec, reconstruction
│   ├── payload.ex                  # private schema and lifecycle persistence
│   ├── retry.ex                    # normalized retry/cancel/uncertain classification
│   ├── payload_pruner.ex           # bounded cleanup task/service
│   └── worker.ex                   # ID-only Oban adapter over dispatch/retry result
├── compliance/
│   └── unsubscribe_controller.ex   # event + suppression atomic Multi
└── migrations/postgres/
    └── v06.ex                      # payload table/indexes; compatibility migration

reference/host_app/                 # generated-host template/proof harness, public APIs only
```

## Dependency-ordered Build Plan

1. **Contract and preflight foundation.** Specify supported `Swoosh.Email` fields, exact one-recipient validation, effective single-tenant resolution, and renderer body semantics. Add direct tests first; all later work consumes these facts.
2. **Envelope + schema migration.** Add the private payload schema, codec round-trip tests, delivery migration/backfill compatibility, and atomic `Delivery + Event + Payload + Oban` enqueue. Ensure all raw `Ecto.Multi` callbacks use `Repo.multi_opts()` for the configured schema.
3. **Unified dispatch + retry classification.** Make sync and worker call the same reconstructed envelope path; add terminal/retryable/uncertain outcomes and preserve the external adapter-call-outside-transaction rule.
4. **Lifecycle privacy.** Add success/terminal scrub, expired payload fail-closed behavior, bounded pruner, and guards preventing payload data from delivery metadata/telemetry/admin/event stores.
5. **One-click convergence.** Extend the existing unsubscribe Multi with stream suppression insertion and replay tests under hostile `search_path`; keep webhook AutoSuppress separate.
6. **Generated host and release gate.** Generate/configure the clean host after public semantics settle, then use it for the end-to-end proofs above. This must come last because it is a consumer of the real migration/configuration/contracts, not a substitute for them.

## Integration and Compatibility Hazards

| Hazard | Mitigation |
|---|---|
| Existing queued deliveries lack a payload row | Transitional legacy reader for pre-v2.4 rows, metrics for remaining rows, then remove only after the documented retention window. New rows must never use metadata reconstruction. |
| `metadata` atom vs string keys | Canonicalize at envelope build; do not replay arbitrary metadata values. |
| `Delivery` idempotency key currently hashes only recipient and body | Include the canonical envelope/version or retain current public semantics intentionally; never allow the same key to bind two materially distinct envelopes. |
| Oban queue absent/misconfigured in host | Startup/doctor preflight and generated-host assertion must prove `:mailglass_outbound` is running before calling it durable. |
| Transactional lifecycle callback has external side effects | Keep it out of the unsubscribe transaction unless the existing lifecycle contract proves it is DB-only/idempotent; external side effects need an outbox-like post-commit mechanism. |
| Existing `AutoSuppress` is webhook-focused | Reuse its deterministic attrs/conflict target, but invoke it in the controller Multi rather than waiting for webhook projection. |
| Prefix isolation | Every new query and `Ecto.Multi.run` callback must carry `Mailglass.Repo.multi_opts()`; hostile-search-path tests are required. |

## Sources

- Repository inventory: `lib/mailglass/outbound.ex`, `outbound/worker.ex`, `outbound/delivery.ex`, `renderer.ex`, `tenancy.ex`, `compliance/unsubscribe_controller.ex`, `suppression/auto_suppress.ex`, Postgres migrations, and `reference/host_app/` (HIGH).
- [RFC 8058, One-Click Unsubscribe](https://www.rfc-editor.org/rfc/rfc8058.html) (HIGH; standards-track requirements).
- [Oban.Worker documentation](https://oban.hexdocs.pm/Oban.Worker.html) (MEDIUM; current official behavior; verify pinned version at implementation).
- [Ecto.Multi documentation](https://hexdocs.pm/ecto/Ecto.Multi.html) and [Swoosh.Email documentation](https://swoosh.hexdocs.pm/Swoosh.Email.html) (MEDIUM; current official API behavior; confirm pinned versions during phase planning).

---
*Architecture research for: Mailglass v2.4 Outbound First-Adopter Correctness*
*Researched: 2026-08-02*
