defmodule Mailglass.Tenancy.SingleTenant do
  @moduledoc """
  Default `Mailglass.Tenancy` resolver: `scope/2` is a no-op.

  Single-tenant adopters need zero configuration — this is the
  `Mailglass.Config`-resolved default when `:tenancy` is `nil`.
  `Mailglass.Tenancy.current/0` returns the literal string `"default"`
  when this resolver is active and no explicit `put_current/1` has
  run.

  Adopters who want real tenant isolation implement their own module
  with `@behaviour Mailglass.Tenancy` and wire it via:

      config :mailglass, tenancy: MyApp.Tenancy
  """
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, _context), do: query
end
