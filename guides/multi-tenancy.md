# Multi-Tenancy

Mailglass stores `tenant_id` on deliveries, events, suppressions, and durable
outbound payloads. The 2.x public contract keeps the zero-config single-tenant
path while allowing runtime per-tenant adapter resolution.

## Single-tenant default

If you only have one transport, keep the default path boring:

```elixir
config :mailglass,
  adapter:
    {Mailglass.Adapters.Swoosh,
     swoosh_adapter:
       {Swoosh.Adapters.Postmark, api_key: System.fetch_env!("POSTMARK_API_KEY")}}
```

You do not need `config :mailglass, adapters:` or a custom tenancy callback for this case. An unstamped outbound caller using `Mailglass.Tenancy.SingleTenant` is normalized to the string `"default"` before rendering, persistence, job insertion, or provider work.

This is deliberately not a general fallback. When you configure a custom
`Mailglass.Tenancy` resolver, every send needs a valid, nonblank tenant context
that can be restored for its execution context. Missing, invalid, or unavailable
custom context fails closed as `%Mailglass.TenancyError{type: :unstamped}`; it is
never rewritten to `"default"`.

## Named adapter refs

Add `config :mailglass, adapters:` only when you need reusable runtime route targets:

```elixir
config :mailglass,
  adapter:
    {Mailglass.Adapters.Swoosh,
     swoosh_adapter:
       {Swoosh.Adapters.Postmark, api_key: System.fetch_env!("POSTMARK_DEFAULT_API_KEY")}},
  adapters: [
    postmark_acme:
      {Mailglass.Adapters.Swoosh,
       swoosh_adapter:
         {Swoosh.Adapters.Postmark, api_key: System.fetch_env!("POSTMARK_ACME_API_KEY")}},
    sendgrid_globex:
      {Mailglass.Adapters.Swoosh,
       swoosh_adapter:
         {Swoosh.Adapters.Sendgrid, api_key: System.fetch_env!("SENDGRID_GLOBEX_API_KEY")}},
    ses_ops:
      {Mailglass.Adapters.Swoosh,
       swoosh_adapter:
         {Swoosh.Adapters.AmazonSES, region: "us-east-1", access_key: System.fetch_env!("SES_ACCESS_KEY"), secret: System.fetch_env!("SES_SECRET")}}
  ]
```

Each registry entry is just the same adapter shape Mailglass already understands: `AdapterModule` or `{AdapterModule, opts}`.

## Tenancy callback

Put routing policy on your existing `Mailglass.Tenancy` module with `resolve_outbound_adapter_ref/1`:

```elixir
defmodule MyApp.Tenancy do
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, %{tenant_id: tenant_id}) do
    Mailglass.Tenancy.scope(query, %{tenant_id: tenant_id})
  end

  @impl Mailglass.Tenancy
  def resolve_webhook_tenant(%{path_params: %{"tenant_id" => tenant_id}}), do: {:ok, tenant_id}
  def resolve_webhook_tenant(_ctx), do: {:error, :missing_tenant_id}

  @impl Mailglass.Tenancy
  def resolve_outbound_adapter_ref(%{tenant_id: tenant_id, message: message, mode: mode}) do
    case {tenant_id, message.stream, mode} do
      {"acme", :transactional, _mode} -> {:ok, :postmark_acme}
      {"globex", :transactional, _mode} -> {:ok, :sendgrid_globex}
      {"initech", :operational, :async} -> {:ok, :ses_ops}
      _ -> :default
    end
  end
end
```

The callback contract stays narrow on purpose:

- `{:ok, adapter_ref}` selects a named route from `config :mailglass, adapters:`
- `:default` keeps the global `config :mailglass, adapter` path
- missing callbacks behave the same as `:default`

Broken callback output or unknown refs fail loudly. Mailglass does not silently fall back to the default adapter when tenant-specific routing is misconfigured.

## Common routing patterns

### Different ESP per tenant

Route one tenant through Postmark and another through SendGrid by returning different named refs from `resolve_outbound_adapter_ref/1`.

### Same ESP family, different credentials

Point multiple refs at the same adapter module with different API keys or subaccount options:

```elixir
config :mailglass, adapters: [
  acme_postmark:
    {Mailglass.Adapters.Swoosh,
     swoosh_adapter:
       {Swoosh.Adapters.Postmark, api_key: System.fetch_env!("POSTMARK_ACME_API_KEY")}},
  globex_postmark:
    {Mailglass.Adapters.Swoosh,
     swoosh_adapter:
       {Swoosh.Adapters.Postmark, api_key: System.fetch_env!("POSTMARK_GLOBEX_API_KEY")}}
]
```

### Same provider family, different stream or domain routes

Use route refs to separate transactional and operational traffic even when the provider family is the same:

```elixir
config :mailglass, adapters: [
  ses_transactional:
    {Mailglass.Adapters.Swoosh,
     swoosh_adapter:
       {Swoosh.Adapters.AmazonSES, region: "us-east-1", configuration_set_name: "transactional"}},
  ses_bulk:
    {Mailglass.Adapters.Swoosh,
     swoosh_adapter:
       {Swoosh.Adapters.AmazonSES, region: "us-east-1", configuration_set_name: "bulk"}}
]
```

## Sync vs async semantics

- `Mailglass.deliver/2` resolves the effective adapter at send time.
- `Mailglass.deliver_later/2` applies the same resolver-aware preflight before it
  selects its configured async path.

`deliver_later/2` persists private transport input first, then enqueues one job
on `:mailglass_outbound`; successful payload content is scrubbed and retention
is explicit. This is the current 2.x behavior, not a future-phase promise.
