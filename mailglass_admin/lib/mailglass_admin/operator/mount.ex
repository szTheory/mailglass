defmodule MailglassAdmin.Operator.Mount do
  @moduledoc """
  Internal `on_mount` authorization hook for the production operator
  surface.

  This hook consumes the operator session whitelist from
  the router's operator session callback, calls the adopter-owned
  `MailglassAdmin.Auth` implementation, and assigns normalized auth context
  for later operator actions.

  This module remains internal even though Phoenix wiring requires it to stay
  reachable from the router macro expansion.
  """

  import Phoenix.Component, only: [assign: 3]

  alias MailglassAdmin.Auth
  alias Phoenix.LiveView.Socket

  @spec on_mount(map(), map(), map(), Socket.t()) :: {:cont, Socket.t()} | {:halt, Socket.t()}
  def on_mount(opts, params, session, socket) when is_map(session) or is_list(opts) do
    case authorize_access(opts, params, session, socket) do
      {:ok, socket} ->
        socket =
          socket
          |> remember_authorized_tenant(params)
          |> Phoenix.LiveView.attach_hook(
            :mailglass_admin_account_authorization,
            :handle_params,
            fn incoming_params, _uri, current_socket ->
              authorize_account_change(opts, session, incoming_params, current_socket)
            end
          )

        {:cont, socket}

      {:error, reason, details} ->
        {:halt, deny(socket, reason, details, opts)}
    end
  end

  defp authorize_access(opts, params, session, socket) do
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

        {:ok, socket}

      {:error, reason, details} ->
        {:error, reason, details}
    end
  end

  defp authorize_account_change(opts, session, params, socket) do
    if tenant_param_key(params) == socket.private[:mailglass_admin_authorized_tenant] do
      {:cont, socket}
    else
      case authorize_access(opts, params, session, socket) do
        {:ok, authorized_socket} ->
          {:cont, remember_authorized_tenant(authorized_socket, params)}

        {:error, reason, details} ->
          {:halt, deny(socket, reason, details, opts)}
      end
    end
  end

  defp tenant_param_key(params) do
    case Map.fetch(params, "tenant_id") do
      {:ok, value} -> {:present, value}
      :error -> :absent
    end
  end

  defp remember_authorized_tenant(socket, params) do
    Phoenix.LiveView.put_private(
      socket,
      :mailglass_admin_authorized_tenant,
      tenant_param_key(params)
    )
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
