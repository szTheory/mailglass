# Phase 150: Private Envelope and Atomic Durable Enqueue - Pattern Map

**Mapped:** 2026-08-02  
**Files analyzed:** 16 implementation/test/documentation targets  
**Analogs found:** 14 / 16 (the new envelope and payload have composed analogs rather than a single exact predecessor)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mailglass/outbound/envelope.ex` | service / codec | transform, file-I/O | `lib/mailglass/outbound.ex` | partial (new explicit protocol) |
| `lib/mailglass/outbound/payload.ex` | model | CRUD | `lib/mailglass/outbound/delivery.ex` | role-match |
| `lib/mailglass/outbound.ex` | service | request-response, CRUD | its current Oban single-send multi | exact extension |
| `lib/mailglass/outbound/worker.ex` | worker | event-driven, request-response | current worker | exact extension |
| `lib/mailglass/optional_deps/oban.ex` | optional-dependency gateway | request-response | current gateway | exact extension |
| `lib/mailglass/migrations/postgres/v06.ex` | migration | batch / DDL | `lib/mailglass/migrations/postgres/v05.ex` | exact |
| `lib/mailglass/migrations/postgres.ex` | config / migration runner | batch | current runner | exact extension |
| `test/mailglass/outbound/envelope_test.exs` | test | transform, file-I/O | `test/mailglass/outbound/deliver_later_test.exs` | partial |
| `test/mailglass/outbound/deliver_later_test.exs` | test | request-response, CRUD | current file | exact extension |
| `test/mailglass/outbound/deliver_many_test.exs` | test | batch, CRUD | current file | exact extension |
| `test/mailglass/outbound/worker_test.exs` | test | event-driven | current file | exact extension |
| `test/mailglass/migration_test.exs` | test | batch / DDL | current prefix migration describe | exact extension |
| `test/mailglass/schema_prefix_hardening_test.exs` | test | CRUD | current prefix-hardening harness | exact extension |
| `test/mailglass/docs_contract_test.exs` | test | config contract | current guide-content test | exact extension |
| `guides/production-go-live-checklist.md` | documentation / config | request-response | existing Oban queue section | exact correction |
| `guides/getting-started.md` | documentation | request-response | existing async-adapter guidance | role-match |

## Pattern Assignments

### `lib/mailglass/outbound/envelope.ex` (service/codec, transform and file-I/O)

**Analog:** composed from `lib/mailglass/outbound.ex` and the Swoosh message handling already exercised by `test/mailglass/outbound/deliver_later_test.exs`.

Put the codec after the existing preparation seam, not before render/compliance/tracking. `prepare_outbound_message/1` is the established immutable-boundary hook ([`outbound.ex:1257`](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:1257)):

```elixir
rendered
|> Message.put_metadata(:delivery_id, delivery_id)
|> Compliance.apply_outbound_headers()
|> Tracking.rewrite_if_enabled()
```

Use the existing sole-recipient discriminator when dumping/loading, preserving native `:to`, `:cc`, or `:bcc` rather than inferring it from the address ([`outbound.ex:1287`](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:1287)). Follow the `SendError` constructor and its safe public context boundary ([`send_error.ex:55`](/Users/jon/projects/mailglass/lib/mailglass/errors/send_error.ex:55)); unsupported values, malformed attachments, and unknown envelope versions return `SendError.new(:serialization_failed, context: %{reason_class: ...})` before a Multi is built.

There is no generic serializer analog: the phase must introduce a deliberately allowlisted JSON protocol (`version`, `dump/2`, `load/1`) and materialize attachment bytes. The closest behavioral proof is the existing sole-`cc`/`bcc` async fidelity test ([`deliver_later_test.exs:70`](/Users/jon/projects/mailglass/test/mailglass/outbound/deliver_later_test.exs:70)).

### `lib/mailglass/outbound/payload.ex` (model, CRUD)

**Analog:** [`lib/mailglass/outbound/delivery.ex`](/Users/jon/projects/mailglass/lib/mailglass/outbound/delivery.ex:86) (same schema macro, typed fields, changeset discipline), with private ownership instead of public projection semantics.

Copy imports/schema/changeset shape:

```elixir
use Mailglass.Schema
import Ecto.Changeset

schema "mailglass_deliveries" do
  field(:tenant_id, :string)
  field(:metadata, :map, default: %{})
  timestamps(type: :utc_datetime_usec)
end

def changeset(%__MODULE__{} = record, attrs) when is_map(attrs) do
  record
  |> cast(attrs, @cast)
  |> validate_required(@required)
end
```

For `Payload`, replace the public fields/table with one delivery-scoped private record: tenant id, delivery id, version, integrity facts, envelope map, and lifecycle timestamps. Add a tenant-scoped lookup helper using `Tenancy.scope/1` and the Repo facade; do not expose it as an admin/read model. Delivery's own module explicitly defines `metadata` as adopter-supplied non-PII extras ([`delivery.ex:17`](/Users/jon/projects/mailglass/lib/mailglass/outbound/delivery.ex:17)), so it is the boundary to preserve—not a storage location to reuse.

### `lib/mailglass/outbound.ex` (service, request-response/CRUD)

**Analog:** the current single-send Oban transaction, [`outbound.ex:380`](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:380).

Extend this ordered Multi; preserve its step-local prefixing and error conversion:

```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert(:delivery, Delivery.changeset(%Delivery{id: delivery_id}, attrs), Repo.multi_opts())
|> Events.append_multi(:event_queued, fn %{delivery: d} ->
  %{tenant_id: tenant_id, delivery_id: d.id, type: :queued,
    occurred_at: Clock.utc_now(), idempotency_key: ik, normalized_payload: %{}}
end)
|> Mailglass.OptionalDeps.Oban.insert(:job, fn %{delivery: d} ->
  Mailglass.Outbound.Worker.new(%{"delivery_id" => d.id, "mailglass_tenant_id" => tenant_id})
end)
|> Repo.multi()
```

Insert `:payload` between `:event_queued` and `:job`, using `Payload.changeset/2` plus `Repo.multi_opts()`. Dump/validate the envelope and check explicit Oban readiness before this builder so serialization/readiness failures create no records. Preserve `{:ok, %{delivery: d}} -> {:ok, %{d | status: :queued, last_event_type: :queued}}` and `{:error, _step, err, _} -> {:error, to_error(err)}` ([`outbound.ex:412`](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:412)).

`base_delivery_attrs/3` is the exact privacy-removal seam: it currently merges rendered bodies, subject, headers, and recipient field into metadata ([`outbound.ex:1231`](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:1231)). Change it to retain only adopter public metadata. Keep that legacy shape only in an isolated legacy reader used when no Payload exists.

Replace the `insert_batch/1` + post-commit `enqueue_batch_jobs/1` arrangement with per-eligible-message reuse of the same helper. The current post-commit `Oban.insert_all/1` at [`outbound.ex:633`](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:633) is explicitly not an acceptable template for new work.

### `lib/mailglass/outbound/worker.ex` (worker, event-driven)

**Analog:** [`worker.ex:33`](/Users/jon/projects/mailglass/lib/mailglass/outbound/worker.ex:33).

Do not change the worker arguments or queue options:

```elixir
use Oban.Worker,
  queue: :mailglass_outbound,
  max_attempts: 20,
  unique: [period: 3600, fields: [:args], keys: [:delivery_id]]

def perform(%Oban.Job{args: %{"delivery_id" => id}} = job) when is_binary(id) do
  Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
    # payload-first dispatch
  end)
end
```

The tenant wrapper is mandatory ([`worker.ex:39`](/Users/jon/projects/mailglass/lib/mailglass/outbound/worker.ex:39)). Have the dispatch path load Payload by delivery/tenant first, reconstruct through `Envelope.load/1`, and use metadata reconstruction only for rows with no Payload (legacy reader). Keep the existing result normalization to Oban `:ok` / `{:error, term}` ([`worker.ex:41`](/Users/jon/projects/mailglass/lib/mailglass/outbound/worker.ex:41)).

### `lib/mailglass/optional_deps/oban.ex` (gateway, request-response)

**Analog:** [`optional_deps/oban.ex:36`](/Users/jon/projects/mailglass/lib/mailglass/optional_deps/oban.ex:36).

Keep every Oban reference in this module under the existing warning suppression:

```elixir
@compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job, Oban.Migrations, Oban.Testing]}

def insert(multi, name, job_builder) when is_atom(name) and is_function(job_builder, 1) do
  if available?(), do: Oban.insert(multi, name, job_builder), else: multi
end
```

Extend the gateway with `ready?/0`/configuration-query helpers and a fail-closed insertion result used only by the explicit `:oban` branch. Do not copy the current “return multi unchanged” absence behavior for durable sends ([`optional_deps/oban.ex:48`](/Users/jon/projects/mailglass/lib/mailglass/optional_deps/oban.ex:48)); it is the precise behavior Phase 150 replaces. Keep Task.Supervisor only in the explicit branch of `enqueue_via_async_adapter/3`, where the current fallback is visible at [`outbound.ex:363`](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:363).

### `lib/mailglass/migrations/postgres/v06.ex` and `postgres.ex` (migration/config, batch DDL)

**Analog:** [`v05.ex:5`](/Users/jon/projects/mailglass/lib/mailglass/migrations/postgres/v05.ex:5) and [`postgres.ex:5`](/Users/jon/projects/mailglass/lib/mailglass/migrations/postgres.ex:5).

Copy the reversible version-module structure and thread the supplied prefix into every table/index operation:

```elixir
def up(opts \\ []) do
  prefix = opts[:prefix]
  # create table(..., prefix: prefix); create indexes with prefix: prefix
end

def down(opts \\ []) do
  prefix = opts[:prefix]
  # drop indexes/table in reverse order, each with prefix: prefix
end
```

Increment `@current_version` from `5` to `6`; the runner dynamically resolves `V#{pad_idx}` ([`postgres.ex:54`](/Users/jon/projects/mailglass/lib/mailglass/migrations/postgres.ex:54)), so no module registry change is needed. Do not backfill legacy metadata in this migration.

### Tests and documentation

**Durable enqueue integration:** extend [`deliver_later_test.exs`](/Users/jon/projects/mailglass/test/mailglass/outbound/deliver_later_test.exs:1), which already uses `DataCase, async: false`, shared sandbox ownership, application-env restoration, fixture builders, and direct `oban_jobs` counts ([`deliver_later_test.exs:376`](/Users/jon/projects/mailglass/test/mailglass/outbound/deliver_later_test.exs:376)). Add structural envelope round trips, metadata privacy assertions, all-four-record success, and injected Payload/job failure rollback assertions there or in the new `envelope_test.exs` unit file.

**Batch:** extend [`deliver_many_test.exs`](/Users/jon/projects/mailglass/test/mailglass/outbound/deliver_many_test.exs:1) with `async: false`, its env restoration pattern, and assertions retaining per-message public results. Test each eligible item has Delivery/Event/Payload/Job; do not assert whole-batch atomicity.

**Worker:** extend [`worker_test.exs:43`](/Users/jon/projects/mailglass/test/mailglass/outbound/worker_test.exs:43) for canonical queue and [`worker_test.exs:71`](/Users/jon/projects/mailglass/test/mailglass/outbound/worker_test.exs:71) for payload-first versus metadata-only legacy fixtures. Continue conditional skips and `Oban.Testing` manual mode.

**Migration/prefix:** extend the scratch-prefix migration harness in [`migration_test.exs:366`](/Users/jon/projects/mailglass/test/mailglass/migration_test.exs:366) to assert `mailglass_outbound_payloads` plus indexes on up/down. Use `schema_prefix_hardening_test.exs`'s scratch-schema and hostile search-path discipline ([`schema_prefix_hardening_test.exs:21`](/Users/jon/projects/mailglass/test/mailglass/schema_prefix_hardening_test.exs:21)); never touch the configured baseline schema.

**Docs:** correct the existing production queue example, which currently names `:mailglass` ([`production-go-live-checklist.md:53`](/Users/jon/projects/mailglass/guides/production-go-live-checklist.md:53)), to `:mailglass_outbound`; add the explicit `:task_supervisor` non-durable warning to this operational guidance and Getting Started. Extend [`docs_contract_test.exs:446`](/Users/jon/projects/mailglass/test/mailglass/docs_contract_test.exs:446) with positive canonical-queue and durable-boundary literals plus stale-queue refutation.

## Shared Patterns

### Schema prefix and tenancy

**Sources:** [`repo.ex:137`](/Users/jon/projects/mailglass/lib/mailglass/repo.ex:137), [`optional_deps/oban.ex:152`](/Users/jon/projects/mailglass/lib/mailglass/optional_deps/oban.ex:152)

Every Multi write must receive `Repo.multi_opts()` because executor options do not flow into steps. Every Payload read is tenant scoped; worker execution restores the stamped tenant before querying.

### Transaction/error boundary

**Sources:** [`outbound.ex:387`](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:387), [`send_error.ex:66`](/Users/jon/projects/mailglass/lib/mailglass/errors/send_error.ex:66)

Perform pure dumping/materialization and Oban readiness before `Repo.multi/1`; run only local Delivery/Event/Payload/Job durability inside it. Map all public failures to the closed `SendError` types and bounded non-PII `reason_class` context.

### Optional dependency boundary and canonical queue

**Sources:** [`optional_deps/oban.ex:36`](/Users/jon/projects/mailglass/lib/mailglass/optional_deps/oban.ex:36), [`worker.ex:33`](/Users/jon/projects/mailglass/lib/mailglass/outbound/worker.ex:33)

No bare `Oban.*` outside the gateway. `:mailglass_outbound` is the worker's compile-time source of truth; readiness checks and docs must use the same value.

### Privacy boundary

**Sources:** [`delivery.ex:17`](/Users/jon/projects/mailglass/lib/mailglass/outbound/delivery.ex:17), [`outbound.ex:1231`](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:1231)

Delivery metadata stays public adopter data. Envelope bytes, headers, recipients, provider options, and attachment bytes belong only in Payload; Oban args remain delivery/tenant IDs.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/mailglass/outbound/envelope.ex` | service / codec | transform, file-I/O | No existing durable allowlisted codec or attachment materializer; compose from outbound preparation and SendError patterns. |
| `lib/mailglass/outbound/payload.ex` | model | CRUD | No current Mailglass-private one-to-one transport-state schema; copy Delivery mechanics but not its public semantics. |

## Metadata

**Analog search scope:** `lib/mailglass/outbound*`, `lib/mailglass/optional_deps/oban.ex`, `lib/mailglass/migrations/postgres*`, outbound/migration/prefix/docs tests, and operational guides.  
**Files scanned:** 29  
**Pattern extraction date:** 2026-08-02
