# Phase 151: Unified Dispatch, Honest Outcomes, and Payload Lifecycle - Pattern Map

**Mapped:** 2026-08-02  
**Files analyzed:** 18 proposed modified/new files  
**Analogs found:** 17 / 18

## File Classification

| New/Modified File | Role | Data flow | Closest analog | Match quality |
|---|---|---|---|---|
| `lib/mailglass/outbound.ex` | service/facade | request-response + async dispatch | itself: `dispatch_by_id/1`, `prepare_outbound_message/1` | exact seam |
| `lib/mailglass/outbound/dispatch_outcome.ex` (new) | model/utility | transform | `Mailglass.Adapters.Swoosh` reason translation | partial (new closed type) |
| `lib/mailglass/outbound/worker.ex` | worker | event-driven | itself: `perform/1` | exact |
| `lib/mailglass/adapters/swoosh.ex` | adapter/service | request-response | itself: `raw_deliver/2` | exact |
| `lib/mailglass/outbound/payload.ex` | model/service | CRUD + lifecycle | itself: `fetch_for_delivery/2` | exact |
| `lib/mailglass/outbound/delivery.ex` | model | CRUD/state transition | itself plus `Outbound.Projector` | role-match |
| `lib/mailglass/outbound/projector.ex` | service | event-driven transition | itself: monotonic update + optimistic lock | exact |
| `lib/mailglass/events/event.ex` | model | append-only event | existing event atom contract | role-match |
| `lib/mailglass/outbound/payload_pruner.ex` (new) | service | batch / CRUD | `Mailglass.Webhook.Pruner` | exact data-flow |
| `lib/mailglass/outbound/payload_pruner_worker.ex` (new, if scheduled) | worker | batch / event-driven | `Mailglass.Webhook.Pruner` | exact |
| `lib/mix/tasks/mailglass.outbound.payloads.prune.ex` (new) | maintenance task | batch | `Mix.Tasks.Mailglass.Webhooks.Prune` | exact |
| `lib/mailglass/migrations/postgres/v07.ex` (only if new DB enum/index is required) | migration | schema | `Migrations.Postgres.V06` | exact |
| `test/mailglass/outbound/dispatch_outcome_test.exs` (new) | test | transform | `test/mailglass/adapters/swoosh_test.exs` | role-match |
| `test/mailglass/outbound/worker_test.exs` | integration test | event-driven | itself | exact |
| `test/mailglass/outbound/deliver_later_test.exs` | integration/contract test | CRUD + async | itself | exact |
| `test/mailglass/outbound/payload_pruner_test.exs` (new) | integration test | batch | `test/mailglass/webhook/pruner_test.exs` | exact |
| `test/mailglass/v07_migration_test.exs` (only if V07) | migration test | schema/prefix | `test/mailglass/v06_migration_test.exs` | exact |
| `guides/jobs.md`, `guides/production-go-live-checklist.md`, `docs/api_stability.md`, and a new focused docs contract test | docs + contract test | documentation | `test/mailglass/compatibility_contract_test.exs` | exact |

## Pattern Assignments

### `lib/mailglass/outbound.ex` — shared preparation, dispatch, and persistence

**Analog:** this module at [lines 258-285](../../../lib/mailglass/outbound.ex#L258), [292-349](../../../lib/mailglass/outbound.ex#L292), [646-729](../../../lib/mailglass/outbound.ex#L646), and [839-870](../../../lib/mailglass/outbound.ex#L839).

**Copy the shared-input seam, do not add a second authoring path.** Both sync and async already obtain a fully prepared `%Message{}` through `prepare_outbound_message/1`:

```elixir
# lib/mailglass/outbound.ex:1240-1247
defp prepare_outbound_message(%Message{} = rendered) do
  delivery_id = existing_delivery_id(rendered) || Ecto.UUID.generate()

  rendered
  |> Message.put_metadata(:delivery_id, delivery_id)
  |> Compliance.apply_outbound_headers()
  |> Tracking.rewrite_if_enabled()
end
```

The planner should make this preparation result the input to one internal dispatch function. `dispatch_by_id/1` should continue to load the immutable envelope; sync should pass its just-prepared message into the same function. Do not persist a sync payload merely to use the async reader.

**Keep provider I/O outside transactions** ([lines 646-656](../../../lib/mailglass/outbound.ex#L646)):

```elixir
defp call_adapter(%Message{} = rendered, {adapter_mod, adapter_opts}) do
  Telemetry.dispatch_span(%{tenant_id: rendered.tenant_id,
    mailable: rendered.mailable, provider: adapter_mod}, fn ->
    adapter_mod.deliver(rendered, adapter_opts)
  end)
end
```

**Success persistence must extend—not replace—the existing Multi** ([lines 683-728](../../../lib/mailglass/outbound.ex#L683)). Add the payload scrubbing update to this same `Repo.multi/1` after the projection update and event append, all with `Repo.multi_opts()`. Broadcast remains strictly after a successful commit.

**Risk boundary:** `base_delivery_attrs/3` deliberately drops `delivery_id` from public metadata at [lines 1222-1237](../../../lib/mailglass/outbound.ex#L1222); lifecycle work must never reintroduce envelope fields into `Delivery.metadata`. Existing `serialize_error/1` stores raw exception messages ([779-786](../../../lib/mailglass/outbound.ex#L779)); new structural outcome persistence needs a separate bounded projection rather than extending this raw shape.

### `lib/mailglass/outbound/dispatch_outcome.ex` (new) — closed structural outcome

**Analog:** [Swoosh adapter mapping](../../../lib/mailglass/adapters/swoosh.ex#L65) and the stable adapter callback in [api stability documentation](../../../docs/api_stability.md#L733).

Preserve the public adapter callback:

```elixir
# docs/api_stability.md:739-754
@callback deliver(Mailglass.Message.t(), keyword()) ::
          {:ok, %{message_id: String.t(), provider_response: term()}} |
            {:error, Mailglass.Error.t()}
```

Translate adapter results/errors internally, after the callback, into a closed struct or tagged tuple such as `%DispatchOutcome{class: :retryable | :terminal | :uncertain, reason_class: ...}`. The worker must match only this class, never `Exception.message/1`, `inspect/1`, or provider body text.

**Reusable evidence fields:** `Swoosh.raw_deliver/2` already emits bounded `reason_class` values from HTTP status and transport shape ([72-92](../../../lib/mailglass/adapters/swoosh.ex#L72)); use those structured values as input. However, `body_preview` and arbitrary `cause` are unsuitable for the new public/event/log projection.

### `lib/mailglass/adapters/swoosh.ex` — provider evidence only

**Analog:** [lines 65-93](../../../lib/mailglass/adapters/swoosh.ex#L65) and [127-141](../../../lib/mailglass/adapters/swoosh.ex#L127).

```elixir
{:error, {:api_error, status, body}} ->
  {:error, Mailglass.SendError.new(:adapter_failure,
    context: %{provider_status: status, provider_module: mod,
      body_preview: body_preview(body), reason_class: classify_status(status)},
    cause: build_delivery_error({:api_error, status, body}))}
```

Keep this module pure and callback-compatible. If it gains an internal certainty hint, it must be opt-in metadata that the outcome classifier consumes; do not change the callback return contract or expose response bodies. `:client_error` can support terminal classification, `:server_error` supports retryable classification; transport ambiguity must remain conservative/uncertain unless the provider supplies stronger evidence.

### `lib/mailglass/outbound/worker.ex` — Oban result mapping

**Analog:** [lines 42-66](../../../lib/mailglass/outbound/worker.ex#L42).

```elixir
case Mailglass.Outbound.dispatch_by_id(id) do
  {:ok, %Mailglass.Outbound.Delivery{status: :sent}} -> :ok
  {:error, %{__exception__: true} = err} ->
    if terminal_payload_error?(err), do: {:cancel, err}, else: {:error, err}
end
```

Replace `terminal_payload_error?/1`'s one-off payload special case with exhaustive structural outcome matching: `:retryable -> {:error, bounded_reason}`, `:terminal -> {:cancel, bounded_reason}`, `:uncertain -> {:cancel, bounded_reason}`. The tenant wrapper at [44-58](../../../lib/mailglass/outbound/worker.ex#L44), ID-only args, queue identity, and optional compile guard are locked and must remain unchanged.

### `lib/mailglass/outbound/payload.ex` — payload state machine and prefix-safe query base

**Analog:** [lines 8-16](../../../lib/mailglass/outbound/payload.ex#L8) and [50-75](../../../lib/mailglass/outbound/payload.ex#L50).

```elixir
query = from(p in __MODULE__, where: p.tenant_id == ^tenant_id and p.delivery_id == ^delivery_id)

case Repo.one(Tenancy.scope(query, tenant_id)) do
  nil -> {:error, :not_found}
  %__MODULE__{} = payload ->
    case Envelope.digest(payload.envelope) do
      digest when is_binary(digest) and digest == payload.envelope_digest -> Envelope.load(payload.envelope)
      _ when payload.envelope_version == 1 -> {:error, :legacy_integrity_unverifiable}
      _ -> {:error, :integrity_failed}
    end
end
```

Extend this owner with named lifecycle operations (`scrub`, `expire`, `terminalize`, `prune_batch`) and distinct errors for missing, corrupt, unsupported, expired, and scrubbed. Every query must retain both tenant predicate and `Tenancy.scope/2`; writes inside a Multi receive `Repo.multi_opts()`. Scrub must remove all recoverable envelope bytes while retaining lifecycle/version/digest/timestamps in the tombstone. Do not use the legacy metadata reconstruction as a normal fallback.

### `lib/mailglass/outbound/delivery.ex`, `projector.ex`, and `events/event.ex` — atomic operator state

**Analogs:** [Delivery lock contract](../../../lib/mailglass/outbound/delivery.ex#L25), [Projector update](../../../lib/mailglass/outbound/projector.ex#L58), and [Events.append_multi/3](../../../lib/mailglass/events.ex#L131).

```elixir
# lib/mailglass/outbound/projector.ex:64-70
delivery
|> Ecto.Changeset.change()
|> maybe_advance_last_event(event)
|> maybe_set_once_timestamp(event)
|> maybe_flip_terminal(event)
|> Ecto.Changeset.optimistic_lock(:lock_version)
```

Use this projection owner for new terminal/uncertain event types or add a small dedicated lifecycle transition builder that still chains `optimistic_lock/1`. Do not mutate projection fields through `Payload` or raw `Repo.update_all`. Append lifecycle/success events through `Events.append_multi/3` in the same Multi; it supplies schema prefix and event-writer ownership.

**Risk:** current Delivery enum sets ([35-57](../../../lib/mailglass/outbound/delivery.ex#L35)) and the event schema's closed type set may require a migration/contract update before adding any stored atoms. Treat this as a compatibility decision, not an incidental new atom.

### `lib/mailglass/outbound/payload_pruner.ex`, optional worker, and Mix task

**Analog:** [Webhook Pruner](../../../lib/mailglass/webhook/pruner.ex#L1) plus [Mix task](../../../lib/mix/tasks/mailglass.webhooks.prune.ex#L34).

```elixir
# lib/mailglass/webhook/pruner.ex:91-104
defp prune_status(_status, :infinity), do: {:ok, 0}
defp prune_status(status, days) when is_atom(status) and is_integer(days) and days > 0 do
  cutoff = DateTime.add(Clock.utc_now(), -days * 86_400, :second)
  {count, _} = Repo.delete_all(from(w in WebhookEvent, where: w.status == ^status and w.inserted_at < ^cutoff))
  {:ok, count}
end
```

Reuse the public `prune/0` + optional Oban wrapper + same-code-path Mix task shape, but **not** its unbounded single `delete_all`: outbound pruning needs tenant/prefix safety, bounded batches, and tombstone preservation. A suitable batch query must use `Tenancy.scope`, explicit deterministic ordering/limit, and transition rows to a non-content tombstone rather than delete the payload record. Follow the `available?/0` stub and `@compile {:no_warn_undefined, ...}` convention from [lines 117-129](../../../lib/mailglass/webhook/pruner.ex#L117) and [36-55](../../../lib/mix/tasks/mailglass.webhooks.prune.ex#L36).

### Migration (only if schema/index changes are actually needed)

**Analog:** [V06](../../../lib/mailglass/migrations/postgres/v06.ex#L5).

```elixir
def up(opts \\ []) do
  prefix = opts[:prefix]
  create_if_not_exists index(:mailglass_outbound_payloads, [:expires_at],
    name: :mailglass_outbound_payloads_expires_at_idx,
    where: "expires_at IS NOT NULL", prefix: prefix)
end
```

V06 already owns `scrubbed_at`, `expires_at`, digest, and the expiry index. Avoid a migration merely to encode lifecycle in content; add V07 only for genuinely missing persisted lifecycle/reason/index needs. All DDL must accept `opts`, thread `prefix`, and have an exact down path.

### Tests — wire equivalence, failures, lifecycle, and docs

**Analogs:** [durable private-surface test](../../../test/mailglass/outbound/deliver_later_test.exs#L169), [worker structural tests](../../../test/mailglass/outbound/worker_test.exs#L50), [Swoosh mapping tests](../../../test/mailglass/adapters/swoosh_test.exs#L28), [pruner tests](../../../test/mailglass/webhook/pruner_test.exs#L43), and [compatibility docs test](../../../test/mailglass/compatibility_contract_test.exs#L50).

Copy the current Fake-capture approach: run the same fully-featured message sync and through a durable job, then compare the captured `Mailglass.Message`/Swoosh input field-for-field (recipient native field, ordered headers, attachments, metadata/tags, JSON-safe options), allowing only provider-generated values. Use dedicated small test adapters for `retryable`, `terminal`, and `uncertain`, rather than exception-message fixtures.

For lifecycle tests, use `DataCase, async: false` when touching application retention config, snapshot public surfaces with unique private marker values, and prove scrub/prune does not leak markers. The v06 migration test's hostile-search-path setup ([79-137](../../../test/mailglass/v06_migration_test.exs#L79)) is mandatory if V07 is introduced. Docs tests should use `File.read!/1` assertions, as in the compatibility contract test, to lock at-least-once language and forbidden exactly-once claims.

## Shared Patterns

### Tenant and prefix safety

**Sources:** [Payload fetch](../../../lib/mailglass/outbound/payload.ex#L50), [Events insert options](../../../lib/mailglass/events.ex#L174), and [V06 migration](../../../lib/mailglass/migrations/postgres/v06.ex#L5).

- Read/query operations: tenant predicate plus `Tenancy.scope(query, tenant_id)`.
- Multi writes: `Repo.multi_opts()`.
- Event writes: `Events.append_multi/3`; it supplies `prefix: Mailglass.Config.schema()`.
- New migration: explicit `prefix = opts[:prefix]` on every table/index/reference.
- Lifecycle/prune tests: hostile search path with a decoy schema, never only the default prefix.

### Persistence ownership and concurrency

**Sources:** [Outbound success Multi](../../../lib/mailglass/outbound.ex#L683), [Projector lock](../../../lib/mailglass/outbound/projector.ex#L64), [post-commit broadcast](../../../lib/mailglass/outbound/projector.ex#L136).

Provider calls stay outside DB transactions. After provider acceptance, one `Repo.multi` must update Delivery, append Event, and scrub Payload. Concurrency uses the existing Delivery optimistic lock (or an explicit locked/CAS payload transition) so a worker retry cannot dispatch once another transition has already scrubbed/terminalized the payload. Broadcast/feedback is post-commit only.

### Public/private data boundary

**Sources:** [base delivery attrs](../../../lib/mailglass/outbound.ex#L1222), [adapter PII policy](../../../lib/mailglass/adapters/swoosh.ex#L24), and [durable enqueue privacy test](../../../test/mailglass/outbound/deliver_later_test.exs#L169).

Public Delivery/event/job/log/telemetry projections may include stable reason classes, correlation IDs, and counts only. They must exclude subject, body, headers, recipient/sender, attachments, tokens, provider options, raw provider payloads, and arbitrary exception strings. The envelope remains the only recoverable async message representation.

### Optional runtime maintenance

**Sources:** [conditional Pruner module](../../../lib/mailglass/webhook/pruner.ex#L1) and [manual task fallback](../../../lib/mix/tasks/mailglass.webhooks.prune.ex#L41).

An optional scheduled worker is conditionally compiled. Its library API/Mix task must still offer an honest manual/system-cron path when Oban is unavailable; selecting scheduled behavior must not silently downgrade or make pruning unavailable without a clear operator result.

## No Analog Found

| File/Concern | Role | Data flow | Reason |
|---|---|---|---|
| `Mailglass.Outbound.DispatchOutcome` closed type | model | transform | No existing three-class certainty model; Swoosh has only reason classes. |
| bounded, tombstone-preserving outbound prune query | service | batch | Webhook pruning deletes rows and is not tenant-batched/tombstone-preserving. |
| sync/Oban wire-equivalence contract test | integration test | request-response + async | Fake capture exists, but no current comparison oracle spanning both paths. |

## Metadata

**Analog search scope:** `lib/mailglass/outbound*`, `lib/mailglass/adapters`, `lib/mailglass/events*`, `lib/mailglass/webhook`, `lib/mix/tasks`, migrations, outbound/webhook/migration tests, guides, and API contracts.  
**Files scanned:** 31  
**Pattern extraction date:** 2026-08-02
