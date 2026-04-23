defmodule Mailglass.Tenancy.SingleTenant do
  @moduledoc """
  Default `Mailglass.Tenancy` resolver: `scope/2` is a no-op;
  `resolve_webhook_tenant/1` returns `{:ok, "default"}`.

  Single-tenant adopters need zero configuration — this is the
  `Mailglass.Config`-resolved default when `:tenancy` is `nil`.
  `Mailglass.Tenancy.current/0` returns the literal string `"default"`
  when this resolver is active and no explicit `put_current/1` has
  run, and webhook ingest (Phase 4) stamps the same `"default"` value
  on every verified request.

  Adopters who want real tenant isolation implement their own module
  with `@behaviour Mailglass.Tenancy` and wire it via:

      config :mailglass, tenancy: MyApp.Tenancy

  Multi-tenant adopters override `resolve_webhook_tenant/1` to map
  verified webhook contexts (headers / path_params / conn / raw_body)
  to tenant_ids. See the `Mailglass.Tenancy` moduledoc for the
  callback's 6-key context map shape and examples.
  """
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, _context), do: query

  @impl Mailglass.Tenancy
  def resolve_webhook_tenant(_context), do: {:ok, "default"}
end
