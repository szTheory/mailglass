defmodule MailglassAdmin.Operator.Mount do
  @moduledoc """
  Internal `on_mount` authorization hook for the production operator
  surface.

  This hook consumes the operator session whitelist from
  `MailglassAdmin.Router.__operator_session__/2`, calls the adopter-owned
  `MailglassAdmin.Auth` implementation, and assigns normalized auth
  context for later operator actions.
  """

  import Phoenix.Component, only: [assign: 3]

  alias MailglassAdmin.Auth
  alias Phoenix.LiveView.Socket

  @spec on_mount(map(), map(), map(), Socket.t()) :: {:cont, Socket.t()} | {:halt, Socket.t()}
  def on_mount(opts, params, session, socket) when is_map(session) or is_list(opts) do
    auth_context = %{
      params: params,
      session: session,
      socket: socket,
      actor: Auth.session_actor(session)
    }

    case Auth.authorize(opts[:auth], :operator_access, auth_context) do
      {:ok, %{actor: actor, assigns: extra_assigns}} ->
        socket =
          socket
          |> assign(:operator_actor, actor)
          |> assign(:operator_auth, %{
            status: :authorized,
            adapter: opts[:auth],
            recent_auth?: not is_nil(actor[:recent_auth_at])
          })
          |> assign_extra(extra_assigns)

        {:cont, socket}

      {:error, reason, details} ->
        {:halt, deny(socket, reason, details, opts)}
    end
  end

  defp assign_extra(socket, extra_assigns) do
    Enum.reduce(extra_assigns, socket, fn {key, value}, acc -> assign(acc, key, value) end)
  end

  defp deny(socket, reason, details, opts) do
    to = Map.get(details, :to, opts[:unauthorized_path])
    message = Map.get(details, :message, default_message(reason))

    socket
    |> Phoenix.LiveView.put_flash(:error, message)
    |> Phoenix.LiveView.redirect(to: to)
  end

  defp default_message(:stale_auth), do: "Recent authentication is required."
  defp default_message(:unauthorized), do: "You are not authorized to access mailglass."
end
