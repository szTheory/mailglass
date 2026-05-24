defmodule MailglassAdmin.Inbound.DestructiveAction do
  @moduledoc """
  Action-time authorization helper for destructive inbound work (replay).

  Sibling of `MailglassAdmin.Operator.DestructiveAction` (D-48-10 / D-48-13). Rides
  the existing `MailglassAdmin.Auth.authorize/3` `atom()` action type — NO new auth
  surface — with action `:replay_inbound`, and passes the record under the
  `:inbound_record` context key, NEVER `:delivery`. An adopter `Auth` implementation
  may pattern-match `%Mailglass.Outbound.Delivery{}` on the `:delivery` key, so an
  inbound record under that key would silently misclassify.
  """

  import Phoenix.Component, only: [assign: 3]

  alias MailglassAdmin.Auth
  alias Phoenix.LiveView.Socket

  @default_denial "Replay blocked: this action is not authorized for the current operator."

  @spec authorize(Socket.t(), module() | nil, map()) ::
          {:ok, Socket.t()} | {:error, {:auth, String.t()}}
  def authorize(%Socket{} = socket, adapter, inbound_record) when is_atom(adapter) do
    case Auth.authorize(adapter, :replay_inbound, %{
           actor: socket.assigns.operator_actor,
           inbound_record: inbound_record
         }) do
      {:ok, %{actor: actor, assigns: extra_assigns}} ->
        {:ok, assign_extra_assigns(assign(socket, :operator_actor, actor), extra_assigns)}

      {:ok, %{actor: actor}} ->
        {:ok, assign(socket, :operator_actor, actor)}

      {:error, _reason, details} ->
        {:error, {:auth, Map.get(details, :message, @default_denial)}}
    end
  end

  def authorize(%Socket{}, _adapter, _inbound_record),
    do: {:error, {:auth, @default_denial}}

  defp assign_extra_assigns(socket, extra_assigns) when map_size(extra_assigns) == 0, do: socket

  defp assign_extra_assigns(socket, extra_assigns) do
    Enum.reduce(extra_assigns, socket, fn {key, value}, acc -> assign(acc, key, value) end)
  end
end
