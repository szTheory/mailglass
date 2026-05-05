defmodule MailglassAdmin.Operator.DestructiveAction do
  @moduledoc """
  Shared action-time authorization helper for destructive operator work.

  Replay and any future manual repair action should resolve the exact
  tenant-scoped target first, then authorize via the adopter-owned
  `:destructive_action` seam immediately before execution.
  """

  import Phoenix.Component, only: [assign: 3]

  alias MailglassAdmin.Auth
  alias Phoenix.LiveView.Socket

  @spec authorize(Socket.t(), module() | nil, map(), map()) ::
          {:ok, Socket.t()} | {:error, {:auth, String.t()}}
  def authorize(%Socket{} = socket, adapter, delivery, target) when is_atom(adapter) do
    case Auth.authorize(adapter, :destructive_action, %{
           actor: socket.assigns.operator_actor,
           delivery: delivery,
           replay_target: target
         }) do
      {:ok, %{actor: actor, assigns: extra_assigns}} ->
        {:ok, assign_extra_assigns(assign(socket, :operator_actor, actor), extra_assigns)}

      {:error, _reason, details} ->
        {:error, {:auth, Map.get(details, :message, "Replay is not authorized.")}}
    end
  end

  def authorize(%Socket{}, _adapter, _delivery, _target), do: {:error, {:auth, "Replay is not authorized."}}

  defp assign_extra_assigns(socket, extra_assigns) when map_size(extra_assigns) == 0, do: socket

  defp assign_extra_assigns(socket, extra_assigns) do
    Enum.reduce(extra_assigns, socket, fn {key, value}, acc -> assign(acc, key, value) end)
  end
end
