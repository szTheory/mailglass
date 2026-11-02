defmodule MailglassDemoWeb.AdminAuth do
  @moduledoc """
  Demo policy for the mounted MailglassAdmin dashboard.

  This adapter grants every operator action to any logged-in demo operator so
  the demo can show each flow. It is not a recommended production policy. Real
  hosts decide each action themselves and deny by default, as the catch-all
  clause here does.

  Logged-out operators are sent to the demo login with a `return_to` of the page
  they asked for, so a Preview return to a non-default Account still lands on
  that Account after login.
  """

  @behaviour MailglassAdmin.Auth

  @impl true
  def authorize(:operator_access, %{actor: %{subject_id: subject_id}}) when is_binary(subject_id) do
    {:ok, %{subject_id: subject_id, role: :support_lead}}
  end

  def authorize(:operator_access, context) do
    {:error, :unauthorized,
     %{
       message: "demo operator login required",
       to: "/demo/login?return_to=" <> URI.encode_www_form(return_path(context))
     }}
  end

  def authorize(:destructive_action, %{actor: %{subject_id: subject_id}}) when is_binary(subject_id) do
    {:ok, %{subject_id: subject_id, role: :support_lead}}
  end

  def authorize(:replay_inbound, %{actor: %{subject_id: subject_id}}) when is_binary(subject_id) do
    {:ok, %{subject_id: subject_id, role: :support_lead}}
  end

  def authorize(:reveal_raw, %{actor: %{subject_id: subject_id}}) when is_binary(subject_id) do
    {:ok, %{subject_id: subject_id, role: :support_lead}}
  end

  def authorize(_action, _context),
    do: {:error, :unauthorized, %{message: "demo operator login required"}}

  # The login page's safe_return_to/1 stays the single validator of this value.
  @max_return_bytes 2048
  @max_param_bytes 255

  defp return_path(context) do
    case arrival_uri(context) do
      path when is_binary(path) and byte_size(path) <= @max_return_bytes -> path
      _other -> params_path(context[:params])
    end
  end

  defp arrival_uri(%{socket: %Phoenix.LiveView.Socket{} = socket}) do
    case Phoenix.LiveView.get_connect_info(socket, :uri) do
      %URI{path: path, query: query} when is_binary(path) ->
        if is_binary(query) and query != "", do: path <> "?" <> query, else: path

      _other ->
        nil
    end
  end

  defp arrival_uri(_context), do: nil

  defp params_path(params) when is_map(params) do
    pairs =
      for key <- ["tenant_id", "view"],
          value = Map.get(params, key),
          is_binary(value) and byte_size(value) in 1..@max_param_bytes//1,
          do: {key, value}

    case pairs do
      [] -> "/ops/mail"
      pairs -> "/ops/mail?" <> URI.encode_query(pairs)
    end
  end

  defp params_path(_params), do: "/ops/mail"
end
