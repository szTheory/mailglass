# Multi-Tenancy

mailglass stores `tenant_id` on deliveries, events, and suppressions from day one. This guide shows the minimum setup and one custom resolver shape.

## Prerequisites

- `Mailglass.Config` points to your repo
- You choose a tenant resolution strategy (`SingleTenant` or custom)

## Single-tenant default

```elixir
config :mailglass, tenancy: Mailglass.Tenancy.SingleTenant
```

## Custom tenant behaviour

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
end
```

## Run tenant-scoped delivery

```elixir
Mailglass.Tenancy.with_tenant("acme", fn ->
  %{email: "ops@acme.example"}
  |> MyApp.UserMailer.welcome()
  |> Mailglass.deliver()
end)
```

## End-to-End Example

```elixir
Mailglass.Tenancy.with_tenant("acme", fn ->
  {:ok, delivery} =
    %{email: "owner@acme.example"}
    |> MyApp.UserMailer.welcome()
    |> Mailglass.deliver()

  delivery.tenant_id
end)
```
