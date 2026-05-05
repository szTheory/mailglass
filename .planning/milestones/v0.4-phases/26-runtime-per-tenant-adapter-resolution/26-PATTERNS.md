# Phase 26: runtime-per-tenant-adapter-resolution - Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mailglass/outbound.ex` | service | request-response | `lib/mailglass/outbound.ex` | exact |
| `lib/mailglass/outbound/delivery.ex` | model | CRUD | `lib/mailglass/outbound/delivery.ex` | exact |
| `lib/mailglass/outbound/worker.ex` | worker | event-driven | `lib/mailglass/outbound/worker.ex` | exact |
| `lib/mailglass/tenancy.ex` | service | request-response | `lib/mailglass/tenancy.ex` | exact |
| `lib/mailglass/tenancy/single_tenant.ex` | service | request-response | `lib/mailglass/tenancy/single_tenant.ex` | exact |
| `lib/mailglass/adapter.ex` | config | request-response | `lib/mailglass/adapter.ex` | exact |
| `lib/mailglass/adapters/swoosh.ex` | service | request-response | `lib/mailglass/adapters/swoosh.ex` | exact |
| `config/config.exs` / `config/runtime.exs` | config | request-response | same files | exact |
| `guides/multi-tenancy.md` + tests | doc / test | request-response | `guides/multi-tenancy.md`, `test/mailglass/docs_contract_test.exs`, `test/mailglass/tenancy_test.exs` | role-match |

## Pattern Assignments

### `lib/mailglass/outbound.ex`

**Resolution seam and precedence**

Source: [lib/mailglass/outbound.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:954)

```elixir
defp resolve_adapter(opts) do
  case Keyword.fetch(opts, :adapter) do
    {:ok, {mod, kw}} -> {mod, kw}
    {:ok, mod} when is_atom(mod) -> {mod, []}
    :error ->
      case Application.get_env(:mailglass, :adapter, {Mailglass.Adapters.Fake, []}) do
        {mod, kw} -> {mod, kw}
        mod when is_atom(mod) -> {mod, []}
      end
  end
end
```

Planning implication: keep this explicit precedence style. Phase 26 should extend it, not replace it. Existing top-priority escape hatch is per-call override.

**Queue-time persistence + dispatch-time rehydration**

Source: [lib/mailglass/outbound.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:1002)

```elixir
defp base_delivery_attrs(%Message{} = rendered, ik) do
  %{
    tenant_id: rendered.tenant_id,
    mailable: inspect(rendered.mailable),
    stream: rendered.stream,
    recipient: primary_recipient(rendered),
    recipient_domain: recipient_domain(rendered),
    status: :queued,
    last_event_type: :queued,
    last_event_at: Clock.utc_now(),
    metadata:
      Map.merge(rendered.metadata || %{}, %{
        rendered_html: rendered.swoosh_email.html_body,
        rendered_text: rendered.swoosh_email.text_body,
        subject: rendered.swoosh_email.subject,
        headers: rendered.swoosh_email.headers || %{}
      }),
    idempotency_key: ik
  }
end
```

Source: [lib/mailglass/outbound.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:861)

```elixir
defp rehydrate_message(%Delivery{} = delivery) do
  ...
  {:ok, build_rehydrated_message(delivery, mod_atom)}
end
```

Planning implication: async path already snapshots durable intent on the delivery row and rehydrates later. Route identity should follow this same pattern; do not move adapter config into job args.

**Worker/job args stay minimal**

Source: [lib/mailglass/outbound.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:393)

```elixir
Mailglass.Outbound.Worker.new(%{
  "delivery_id" => d.id,
  "mailglass_tenant_id" => tenant_id
})
```

Planning implication: preserve small args; prefer persisted route ref on `Delivery`.

**Persistence ordering**

Source: [lib/mailglass/outbound.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:665)

```elixir
|> Ecto.Multi.insert(:delivery, Delivery.changeset(%Delivery{id: delivery_id}, %{...}))
|> Events.append_multi(:event_queued, fn %{delivery: d} -> %{delivery_id: d.id, ...} end)
```

Source: [lib/mailglass/outbound.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:722)

```elixir
|> Ecto.Multi.update(:delivery, ...)
|> Events.append_multi(:event_dispatched, event_attrs)
```

Planning implication: if Phase 26 persists route intent, it belongs in Multi#1 attributes so retries and later dispatch see the same route choice.

### `lib/mailglass/tenancy.ex`

**Optional callback dispatcher convention**

Source: [lib/mailglass/tenancy.ex](/Users/jon/projects/mailglass/lib/mailglass/tenancy.ex:42)

```elixir
@optional_callbacks tracking_host: 1, compliance_host: 1, resolve_webhook_tenant: 1
```

Source: [lib/mailglass/tenancy.ex](/Users/jon/projects/mailglass/lib/mailglass/tenancy.ex:303)

```elixir
def resolve_webhook_tenant(context) when is_map(context) do
  module = resolver()

  if function_exported?(module, :resolve_webhook_tenant, 1) do
    module.resolve_webhook_tenant(context)
  else
    {:ok, "default"}
  end
end
```

Source: [lib/mailglass/tenancy.ex](/Users/jon/projects/mailglass/lib/mailglass/tenancy.ex:323)

```elixir
def compliance_host(context) do
  module = resolver()

  if function_exported?(module, :compliance_host, 1) do
    module.compliance_host(context)
  else
    :default
  end
end
```

Planning implication: Phase 26 should copy this exact seam shape.

- Optional callback on `Mailglass.Tenancy`
- Runtime dispatch through `resolver/0`
- `function_exported?/3` fallback
- Explicit sentinel fallback outcome, not silent nils

Best fit for new callback outcome: mirror existing `:default` pattern used by `tracking_host/1` and `compliance_host/1`, not webhook’s forced `{:ok, "default"}` shape.

**Resolver default**

Source: [lib/mailglass/tenancy.ex](/Users/jon/projects/mailglass/lib/mailglass/tenancy.ex:333)

```elixir
defp resolver do
  case Application.get_env(:mailglass, :tenancy) do
    nil -> Mailglass.Tenancy.SingleTenant
    mod when is_atom(mod) -> mod
  end
end
```

Planning implication: single-tenant default is first-class and config-free. Preserve this behavior.

### `lib/mailglass/tenancy/single_tenant.ex`

**Zero-config fallback semantics**

Source: [lib/mailglass/tenancy/single_tenant.ex](/Users/jon/projects/mailglass/lib/mailglass/tenancy/single_tenant.ex:1)

```elixir
@impl Mailglass.Tenancy
def scope(query, _context), do: query

@impl Mailglass.Tenancy
def resolve_webhook_tenant(_context), do: {:ok, "default"}
```

Planning implication: if Phase 26 adds an adapter callback, `SingleTenant` should provide the boring default path explicitly or remain compatible with an explicit fallback dispatcher. Either way, no config should be required for existing adopters.

### `lib/mailglass/outbound/delivery.ex`

**Delivery persistence surface**

Source: [lib/mailglass/outbound/delivery.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound/delivery.ex:84)

```elixir
schema "mailglass_deliveries" do
  field(:tenant_id, :string)
  field(:mailable, :string)
  field(:stream, Ecto.Enum, values: @streams)
  field(:recipient, :string)
  field(:recipient_domain, :string)
  field(:provider, :string)
  field(:provider_message_id, :string)
  ...
  field(:metadata, :map, default: %{})
  field(:idempotency_key, :string)
  field(:status, Ecto.Enum, values: @status_values, default: :queued)
  field(:last_error, :map)
end
```

Planning implication:

- `provider` is already durable and queryable, but today it behaves like provider provenance, not a route-ref contract.
- `metadata` is available for internal details, but Phase 26 context explicitly prefers a reserved namespace or explicit field over ambiguous free-form keys.
- If a new field is added, keep field ordering convention: identity, foreign keys, state, metadata/flags, timestamps.

**Changeset extension pattern**

Source: [lib/mailglass/outbound/delivery.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound/delivery.ex:124)

```elixir
@required ~w[tenant_id mailable stream recipient last_event_type last_event_at]a
@cast @required ++
        ~w[recipient_domain provider provider_message_id terminal
           dispatched_at delivered_at bounced_at complained_at
           suppressed_at metadata idempotency_key status last_error]a
```

Planning implication: new persisted route field belongs in `@cast`, likely not in `@required` if default fallback remains valid.

### Migrations

**Existing delivery column/index conventions**

Source: [lib/mailglass/migrations/postgres/v01.ex](/Users/jon/projects/mailglass/lib/mailglass/migrations/postgres/v01.ex:13)

```elixir
create table(:mailglass_deliveries, primary_key: false, prefix: prefix) do
  add(:id, :uuid, primary_key: true)
  add(:tenant_id, :text, null: false)
  ...
  add(:provider, :text)
  add(:provider_message_id, :text)
  ...
  add(:metadata, :map, null: false, default: %{})
  add(:lock_version, :integer, null: false, default: 1)
  timestamps(type: :utc_datetime_usec)
end
```

Source: [priv/repo/migrations/00000000000002_add_idempotency_key_to_deliveries.exs](/Users/jon/projects/mailglass/priv/repo/migrations/00000000000002_add_idempotency_key_to_deliveries.exs:4)

```elixir
alter table(:mailglass_deliveries) do
  add :idempotency_key, :text
  add :status, :string, null: false, default: "queued"
  add :last_error, :map
end
```

Planning implication:

- Delivery schema changes land as additive columns with wrapper migration files under `priv/repo/migrations/`.
- Existing repo also has versioned core migrations under `lib/mailglass/migrations/postgres/`; Phase 26 likely needs both the library migration and test wrapper update path.
- If adding route-ref persistence, treat it like `idempotency_key`/`status`/`last_error`: additive, nullable when global default applies, and explicitly tested at DB level.

### `lib/mailglass/outbound/worker.ex`

**Canonical queued dispatch path**

Source: [lib/mailglass/outbound/worker.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound/worker.ex:7)

```elixir
%{
  "delivery_id" => binary(),
  "mailglass_tenant_id" => binary()
}
```

Source: [lib/mailglass/outbound/worker.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound/worker.ex:39)

```elixir
def perform(%Oban.Job{args: %{"delivery_id" => id}} = job) when is_binary(id) do
  Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
    case Mailglass.Outbound.dispatch_by_id(id) do
      {:ok, %Mailglass.Outbound.Delivery{status: :sent}} -> :ok
      {:ok, %Mailglass.Outbound.Delivery{status: :failed, last_error: err}} -> {:error, err}
      {:error, %{__exception__: true} = err} -> {:error, err}
      {:error, other} -> {:error, inspect(other)}
    end
  end)
end
```

Planning implication: queued routing must be honored inside `dispatch_by_id/1`; do not add a second worker-specific routing path.

### `lib/mailglass/adapter.ex` and `lib/mailglass/adapters/swoosh.ex`

**Adapter contract**

Source: [lib/mailglass/adapter.ex](/Users/jon/projects/mailglass/lib/mailglass/adapter.ex:10)

```elixir
@callback deliver(Mailglass.Message.t(), keyword()) ::
            {:ok, %{required(:message_id) => String.t(), required(:provider_response) => term()}}
            | {:error, Mailglass.Error.t()}
```

**Runtime tuple normalization**

Source: [lib/mailglass/adapters/swoosh.ex](/Users/jon/projects/mailglass/lib/mailglass/adapters/swoosh.ex:96)

```elixir
defp resolve_swoosh_adapter(opts) do
  case Keyword.fetch(opts, :swoosh_adapter) do
    {:ok, {_mod, _kw} = tuple} -> tuple
    {:ok, mod} when is_atom(mod) -> mod
    :error ->
      case Application.get_env(:mailglass, :adapter) do
        {Mailglass.Adapters.Swoosh, kw} -> Keyword.fetch!(kw, :swoosh_adapter)
        _ -> raise Mailglass.ConfigError.new(:missing, context: %{key: :swoosh_adapter})
      end
  end
end
```

Planning implication: adapter registry entries should resolve to the same module-or-`{module, opts}` runtime shape already used here. Broken route refs should fail loudly with typed config errors, not silently fall back.

## Shared Patterns

### Precedence

Copy from [lib/mailglass/outbound.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:954): explicit per-call override is always first, global config fallback second. Phase 26 should insert tenant callback and adapter-ref lookup between those, while keeping `opts[:adapter]` highest priority.

### Optional callback fallback

Copy from [lib/mailglass/tenancy.ex](/Users/jon/projects/mailglass/lib/mailglass/tenancy.ex:303): `function_exported?/3` dispatcher plus explicit fallback sentinel.

### Runtime config, not compile-time expansion

Copy from [config/config.exs](/Users/jon/projects/mailglass/config/config.exs:3) and [config/runtime.exs](/Users/jon/projects/mailglass/config/runtime.exs:3):

```elixir
# Mailglass config is read at runtime via Application.get_env/2.
config :mailglass,
  adapter: {Mailglass.Adapters.Fake, []},
  async_adapter: :oban,
  suppression_store: Mailglass.SuppressionStore.Ecto
```

```elixir
# Adopter-provided runtime configuration example
# config :mailglass,
#   adapter:
#     {Mailglass.Adapters.Swoosh,
#      swoosh_adapter:
#        {Swoosh.Adapters.Postmark, api_key: System.fetch_env!("POSTMARK_API_KEY")}}
```

Planning implication: preserve the split between a minimal default in `config/config.exs` and real secret-bearing examples in `config/runtime.exs`.

### Documentation posture

Copy from [guides/multi-tenancy.md](/Users/jon/projects/mailglass/guides/multi-tenancy.md:10): docs show a zero-config default first, then one custom tenancy module, then end-to-end usage with `Mailglass.Tenancy.with_tenant/2`. Phase 26 docs should preserve that sequence.

## Test Analogs

| Area | Closest Test | What to copy |
|---|---|---|
| sync adapter precedence and persistence | [test/mailglass/outbound_test.exs](/Users/jon/projects/mailglass/test/mailglass/outbound_test.exs:117) | per-call override via `adapter:` opts; assert persisted `Delivery` state after send |
| async queue semantics | [test/mailglass/outbound/deliver_later_test.exs](/Users/jon/projects/mailglass/test/mailglass/outbound/deliver_later_test.exs:48) | assert returned `%Delivery{status: :queued}`, small args, persisted row before background dispatch |
| worker rehydration contract | [test/mailglass/outbound/worker_test.exs](/Users/jon/projects/mailglass/test/mailglass/outbound/worker_test.exs:53) | fixture delivery with persisted metadata, `delivery_id` + `mailglass_tenant_id` args, `dispatch_by_id/1` path |
| tenancy fallback conventions | [test/mailglass/tenancy_test.exs](/Users/jon/projects/mailglass/test/mailglass/tenancy_test.exs:35) | default `"default"` behavior, fail-loud stamped access, optional-callback fallback style |
| adapter tuple/config resolution | [test/mailglass/adapters/swoosh_test.exs](/Users/jon/projects/mailglass/test/mailglass/adapters/swoosh_test.exs:70) | runtime tuple normalization and typed error mapping |
| schema + migration additions | [test/mailglass/outbound/delivery_test.exs](/Users/jon/projects/mailglass/test/mailglass/outbound/delivery_test.exs:48) and [test/mailglass/outbound/delivery_idempotency_key_test.exs](/Users/jon/projects/mailglass/test/mailglass/outbound/delivery_idempotency_key_test.exs:10) | DB column existence, changeset casts, unique/index assertions |
| docs contract | [test/mailglass/docs_contract_test.exs](/Users/jon/projects/mailglass/test/mailglass/docs_contract_test.exs:48) | config examples remain valid and compile as docs code blocks |

## Planning Notes

- Best insertion point for Phase 26 is `Outbound.resolve_adapter/1` plus the enqueue path that builds `base_delivery_attrs/2`.
- Best fallback contract precedent is tenancy’s optional callback style, especially `compliance_host/1` returning `:default`.
- Best place to honor persisted route intent for async retries is `dispatch_by_id/1`, not the worker args.
- If `provider` is reused for route identity, audit webhook/event joins that currently treat it as provider name. If that is too ambiguous, add an explicit route-ref field instead.
- Preserve config/docs ergonomics: single-tenant defaults stay boring, runtime registry examples live in `runtime.exs`, guide examples start simple and then show custom multi-tenant routing.

## Metadata

**Primary context:** `.planning/phases/26-runtime-per-tenant-adapter-resolution/26-CONTEXT.md`
**Analog search scope:** `lib/mailglass`, `config`, `guides`, `test/mailglass`, `priv/repo/migrations`
**Pattern extraction date:** 2026-05-01
