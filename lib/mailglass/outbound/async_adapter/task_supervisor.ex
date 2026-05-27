defmodule Mailglass.Outbound.AsyncAdapter.TaskSupervisor do
  @moduledoc false
  @behaviour Mailglass.Outbound.AsyncAdapter

  # Prod-default async dispatch impl.
  # Spawns a non-linked task under the top-level Mailglass.TaskSupervisor,
  # which is started in Mailglass.Application. The caller's closure is
  # responsible for re-stamping tenancy via Mailglass.Tenancy.with_tenant/2
  # (-15) since the task runs in a fresh process that does not inherit
  # the parent process-dict.

  @impl true
  def dispatch(fun, _opts) when is_function(fun, 0) do
    Task.Supervisor.start_child(Mailglass.TaskSupervisor, fun)
  end
end
