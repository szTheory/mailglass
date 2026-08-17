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
  def dispatch(fun, opts) when is_function(fun, 0) do
    supervisor = Keyword.get(opts, :task_supervisor_name, Mailglass.TaskSupervisor)

    try do
      case Task.Supervisor.start_child(supervisor, fun) do
        {:ok, pid} when is_pid(pid) -> {:ok, pid}
        :ok -> :ok
        {:error, reason} -> {:error, normalize_reason(reason)}
        other -> {:error, normalize_reason(other)}
      end
    rescue
      _error -> {:error, :supervisor_unavailable}
    catch
      :exit, _reason -> {:error, :supervisor_unavailable}
    end
  end

  defp normalize_reason(:max_children), do: :max_children
  defp normalize_reason(:noproc), do: :supervisor_unavailable
  defp normalize_reason(_reason), do: :start_child_failed
end
