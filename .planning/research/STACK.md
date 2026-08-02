# Stack Research

**Domain:** Mailglass v2.4 outbound first-adopter correctness (Phoenix/Postgres transactional email)
**Researched:** 2026-08-02
**Confidence:** MEDIUM

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir / Phoenix | Elixir `~> 1.18`; Phoenix `~> 1.8` (lock: 1.8.9) | Host integration and existing unsubscribe endpoint | Keep the existing Phoenix controller/router mechanism. It already supplies the POST endpoint required by RFC 8058; this milestone is about transaction and idempotency correctness, not another web stack. |
| Ecto SQL / PostgreSQL | Ecto + Ecto SQL `~> 3.13` (lock: 3.14.0); Postgrex `~> 0.22` (lock: 0.22.3); PostgreSQL 14+ | Durable deliveries, event ledger, suppressions, and queued payload records | Use the existing `Repo.multi/1` + `Ecto.Multi` boundary. Ecto documents `Multi` as the mechanism for one database transaction, which fits delivery+job insertion and event+suppression convergence. |
| Oban | Optional `~> 2.21` (lock: 2.23.0) | Durable async execution through the adopter's host Repo | Make Oban the required production mode for `deliver_later/2`; retain it as an optional library dependency for package compatibility. Oban worker `new/2` generates an insertable job changeset and supports insertion in the same transaction as Mailglass persistence. |
| Swoosh | `~> 1.25` (lock: 1.26.3) | Canonical email/envelope representation and provider dispatch | Preserve Swoosh as the single message representation. Its email contract carries `from`, `to`, `cc`, `bcc`, `reply_to`, headers, bodies, attachments, and provider options; the async payload must explicitly serialize the supported one-recipient subset rather than reconstruct only a partial email. |
| Premailex + Floki | Premailex `~> 1.0` (lock: 1.0.0); Floki `~> 0.38` (lock: 0.38.4) | Existing HTML inlining and plaintext extraction | Retain the pure renderer pipeline. Fix configuration semantics in `Mailglass.Renderer` so explicit text-only, explicit plaintext, and the documented `renderer.plaintext` option are honored; do not substitute a rendering system. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Mailglass.OptionalDeps.Oban` | Repo-native gateway | Optional-dependency-safe `Oban.insert` / `insert_all` calls | Keep all Oban calls behind this gateway so the `--no-optional-deps` compile lane remains valid. Extend it only as needed to make the delivery row and job insert atomic. |
| `Mailglass.Tenancy.SingleTenant` | Repo-native default | Zero-config default tenant and no-op query scoping | Use it whenever `config :mailglass, tenancy: nil`. Change the outbound precondition to accept `Tenancy.current() == "default"` in that mode, while preserving `assert_stamped!/0` for custom tenancy. |
| `Mailglass.SuppressionStore.Ecto` | Repo-native default | Stream-scoped suppression persistence and pre-send lookup | Use an `Ecto.Multi`-compatible insertion path for the unsubscribe POST, not a post-commit lifecycle callback. The existing store has the needed unique conflict target and lookup predicates. |
| `Phoenix.Token` / existing `Mailglass.Compliance.Unsubscribe` | Phoenix 1.8 / repo-native | Opaque signed unsubscribe identifier | Keep the signed delivery token. RFC 8058 calls for an opaque, hard-to-forge component and an HTTPS POST without cookies; no session, CSRF, or new token package is required for this endpoint. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Oban testing (`:manual` and `:inline`) | Prove worker queue, transaction, retry result, and payload scrub behavior | Continue the existing `async: false` test isolation. Add a production-shaped host test with a real `oban_jobs` migration and configure `queues: [mailglass_outbound: concurrency]`; the current docs incorrectly say `:mailglass`. |
| Clean Phoenix/Postgres reference host | Adopter proof | Generate/configure a host that owns `Repo`, `Oban`, migrations, endpoint signing config, and Mailglass. It must use the published package surface rather than test helpers or the core repo's fake application wiring. |

## Required Integration Changes

1. **Oban becomes the documented durable path.** Keep the existing optional `{:oban, "~> 2.21", optional: true}` dependency, but production documentation and the clean-host proof must install/configure it with the host Repo and `queues: [mailglass_outbound: 10]` (or host-selected concurrency). This exactly matches `Mailglass.Outbound.Worker`'s compile-time queue. Do not claim that a missing-Oban `Task.Supervisor` fallback is durable or retryable; either retain it only as explicit best-effort compatibility mode or fail closed when `async_adapter: :oban` is selected but unavailable.

2. **Use one Ecto transaction for delivery + Oban job.** `enqueue_oban/3` already forms an `Ecto.Multi` containing delivery, queued event, and job. Preserve that shape, verify the host Oban configuration uses the same Repo/schema setup, and make batch enqueue use the same atomic pattern rather than committing deliveries then calling `insert_all/1` separately. This gives enqueue durability, not exactly-once provider delivery.

3. **Define a bounded internal async-envelope payload.** Add a Mailglass-owned, non-adopter metadata storage field/table for queued wire content. It needs enough JSON-safe data to rebuild exactly one supported envelope recipient: sender, one `to`, the explicitly supported `cc`/`bcc` policy, reply-to, subject, HTML/text bodies, headers (including compliance headers), provider options if supported, and attachment policy. Current `Delivery.metadata` is documented for adopter non-PII metadata yet currently stores rendered bodies there, while rehydration restores only `to`, subject, bodies, and headers. Separate transient private content from adopter metadata and scrub it in the same successful-dispatch transaction; add a bounded retention/pruner path for abandoned/retry-exhausted jobs.

4. **Keep Swoosh as the fidelity contract, but narrow the v2.4 promise.** The milestone requires exactly one envelope recipient. Reject or split unsupported multi-recipient shapes before enqueue, and persist/rebuild every supported field rather than silently dropping Swoosh fields. Attachments should be explicitly rejected for durable async unless the project persists bytes or a stable external reference; filesystem paths are not a durable cross-node payload contract.

5. **Repair semantics instead of adding a retry library.** Oban retries any error return with exponential backoff and jitter up to `max_attempts`; a worker can be re-run after a provider call whose outcome was not durably recorded. Document async as at-least-once execution and provider delivery as potentially duplicate unless the selected adapter/provider supports an idempotency key. Classify deterministic payload/configuration failures as cancellation/non-retryable once the worker can identify them; leave transient adapter/database failures retryable.

6. **Make unsubscribe convergence a single existing-Repo transaction.** The controller already validates an opaque token and appends an idempotency-keyed event. Add the stream-scoped `Suppression.Entry` write to the same `Ecto.Multi`; make duplicate POSTs converge through the existing unique conflict target. This makes the subsequent existing `Suppression.check_before_send/1` enforce the result. Respond 200 for valid replay/expired/invalid one-click POSTs as the current privacy-safe behavior intends, but return 500 only for a real transaction failure.

7. **Honor renderer configuration without new dependencies.** The configuration schema advertises `renderer.plaintext: true`, but `Renderer.render/2` currently always generates plaintext and overwrites any supplied text. Route the option through the existing pure renderer: preserve explicit `text_body`, allow text-only email without forcing an empty HTML pipeline, and generate plaintext only when enabled and absent. Keep CSS inlining independent of plaintext generation.

## Installation

No new Mailglass dependency is recommended. The production host needs its already-supported durable adapter enabled:

```elixir
# mix.exs in the Phoenix host
{:oban, "~> 2.21"}

# config/runtime.exs in the Phoenix host
config :my_app, Oban,
  repo: MyApp.Repo,
  queues: [mailglass_outbound: 10]

config :mailglass, async_adapter: :oban
```

Run the host's Oban migrations alongside Mailglass migrations. Do not add `Oban` to the Mailglass supervision tree: Oban belongs to, and must use, the adopter application and its Repo.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Existing Oban integration | `Task.Supervisor` fallback | Only explicit development/test or best-effort compatibility work where loss and no automatic retry are acceptable. It does not satisfy the v2.4 durable async contract. |
| Existing Ecto JSONB persistence + `Ecto.Multi` | Redis queue / external broker / new outbox product | Do not use for this milestone. The required data and transaction boundary already live in Postgres with Oban. |
| Swoosh email struct + explicit internal serializer | Serializing `%Mailglass.Message{}` directly into Oban args | Never: mailables can hold functions, PIDs, structs, and other non-JSON-safe data. |
| Existing Phoenix controller + signed token | Browser/session unsubscribe flow | Do not use for RFC 8058 machine POST. The standard requires no cookies or request context; the current token route is the correct shape. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| A second queue, job system, or retry package | It creates competing durability and observability contracts without fixing the existing queue-name/config drift. | Host-configured Oban and the current Ecto transaction boundary. |
| `:mailglass` Oban queue configuration | The actual worker declares `queue: :mailglass_outbound`; jobs will not execute when only `:mailglass` workers are running. | `queues: [mailglass_outbound: concurrency]`. |
| `Task.Supervisor` advertised as durable fallback | It has no durable job record or automatic retry after process/node failure. | Oban for documented async; label fallback best-effort or fail closed. |
| Persisting rendered payload in `Delivery.metadata` | It violates the field's non-PII adopter-metadata contract and leaves message content after delivery. | Separate Mailglass-internal queued payload with post-success scrub and bounded retention. |
| Direct `String.to_atom/1` or dynamic module recovery from DB data | It risks atom-table exhaustion and does not restore envelope fidelity. | JSON-safe explicit envelope serialization with existing atoms/modules resolved from trusted config. |
| Exactly-once delivery claim | Database enqueue can be atomic, but a worker can retry after an uncertain provider call. | At-least-once execution, idempotent persistence, and provider idempotency where available. |

## Stack Patterns by Variant

**If the adopter has no custom tenancy:**

- Use `Mailglass.Tenancy.SingleTenant` and its literal `"default"` fallback.
- Because this is the advertised zero-config mode; only custom tenancy should require an explicit process stamp.

**If the adopter configures custom tenancy:**

- Continue requiring `Tenancy.assert_stamped!/0` before outbound work and propagate a JSON-safe tenant id through Oban args.
- Because silent fallback would write/query cross-tenant records under `"default"`.

**If async delivery is requested in production:**

- Use host-owned Oban with `mailglass_outbound` configured and host migrations applied.
- Because it is the only repo-native path with persisted jobs and automatic retry.

**If the queued job completes successfully:**

- Atomically record dispatch truth and scrub internal payload bytes; retain only delivery projection/audit metadata.
- Because the payload is transient operational content, not a sent-message archive.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| `mailglass` 2.4.0 | Elixir `~> 1.18`, Phoenix `~> 1.8` | Existing project floor; no change needed. |
| Oban `~> 2.21` (lock 2.23.0) | Ecto SQL `~> 3.10`; project lock Ecto SQL 3.14.0 / Postgrex 0.22.3 | Compatible in the current lock. Host must run Oban migrations and configure the actual worker queue. |
| Swoosh `~> 1.25` (lock 1.26.3) | Existing Phoenix/Plug stack | Treat its documented email fields as the async-envelope compatibility surface; do not rehydrate a partial struct. |
| Ecto/Ecto SQL `~> 3.13` (lock 3.14.0) | PostgreSQL 14+ | Current `Ecto.Multi` API is sufficient for all v2.4 atomicity requirements. |

## Sources

- [Oban Worker documentation](https://oban.hexdocs.pm/Oban.Worker.html) — worker queue/options, job creation, transaction insertion, and return semantics (MEDIUM; official primary docs, current v2.23).
- [Oban error handling documentation](https://oban.hexdocs.pm/error_handling.html) — retry limits and exponential backoff with jitter (MEDIUM; official primary docs, current v2.23).
- [Swoosh.Email documentation](https://swoosh.hexdocs.pm/Swoosh.Email.html) — supported email fields and setters (MEDIUM; official primary docs, current v1.27; repository lock is 1.26.3).
- [Ecto.Multi documentation](https://hexdocs.pm/ecto/Ecto.Multi.html) — single-transaction grouping semantics (MEDIUM; official primary docs, current v3.14).
- [RFC 8058](https://www.rfc-editor.org/rfc/rfc8058.html) — one-click HTTPS POST, opaque identifier, and no-cookie requirements (MEDIUM; standards-track primary source).

---
*Stack research for: Mailglass v2.4 outbound first-adopter correctness*
*Researched: 2026-08-02*
