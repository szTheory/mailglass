defmodule Mailglass.Outbound.AsyncAdapter.Inline do
  @moduledoc false
  @behaviour Mailglass.Outbound.AsyncAdapter

  # Test-default async dispatch impl.
  # Runs the closure synchronously in the calling process so the Ecto
  # Sandbox connection is shared automatically — no cross-process ownership
  # transfer needed. The caller's closure is responsible for re-stamping
  # tenancy via Mailglass.Tenancy.with_tenant/2 (-15), which stamps
  # and then restores the prior tenant on return — same semantics as the
  # TaskSupervisor path.

  @impl true
  def dispatch(fun, _opts) when is_function(fun, 0) do
    fun.()
    :ok
  end
end
