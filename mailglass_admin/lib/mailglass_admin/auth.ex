defmodule MailglassAdmin.Auth do
  @moduledoc since: "0.1.0"
  @moduledoc """
  Stack-agnostic authorization seam for production operator access and
  future destructive actions.

  This behaviour is the stable adopter-owned auth seam for `mailglass_admin`.
  If your app integrates with the operator surface, this is the module contract
  to depend on.

  Adopters implement this behaviour and pass the module to
  `mailglass_operator_routes/2`. MailglassAdmin normalizes the return
  shape so later operator actions can rely on one server-side contract.

  Sensitive operator actions stay adopter-owned. For example, an adopter
  may choose to require a recent reauthentication check before allowing
  `:destructive_action`:

      def authorize(:destructive_action, %{actor: %{recent_auth_at: recent_auth_at}})
          when is_struct(recent_auth_at, DateTime) do
        if DateTime.diff(DateTime.utc_now(), recent_auth_at, :second) <= 900 do
          {:ok, %{subject_id: "operator-1", recent_auth_at: recent_auth_at}}
        else
          {:error, :stale_auth, %{message: "Recent authentication is required."}}
        end
      end

  The 900-second window above is an adopter example, not a library-owned
  constant or policy.
  """

  @typedoc since: "0.1.0"
  @type action :: :operator_access | :destructive_action | atom()
  @typedoc since: "0.1.0"
  @type actor :: %{
          required(:subject_id) => term(),
          optional(:tenant_id) => term() | nil,
          optional(:auth_method) => String.t() | atom() | nil,
          optional(:recent_auth_at) => DateTime.t() | nil
        }
  @typedoc since: "0.1.0"
  @type success :: {:ok, actor()} | {:ok, %{required(:actor) => actor(), optional(:assigns) => map()}}
  @typedoc since: "0.1.0"
  @type failure_reason :: :unauthorized | :stale_auth
  @typedoc since: "0.1.0"
  @type failure :: {:error, failure_reason(), map()}
  @typedoc since: "0.1.0"
  @type result :: success() | failure()

  @doc since: "0.1.0"
  @callback authorize(action(), context :: map()) :: result()

  @doc since: "0.1.0"
  @spec authorize(module(), action(), map()) :: {:ok, %{actor: actor(), assigns: map()}} | failure()
  def authorize(module, action, context) when is_atom(module) do
    unless Code.ensure_loaded?(module) and function_exported?(module, :authorize, 2) do
      raise ArgumentError,
            "operator auth module #{inspect(module)} must implement authorize/2"
    end

    module
    |> apply(:authorize, [action, context])
    |> normalize_result()
  end

  @doc since: "0.1.0"
  @spec session_actor(map()) :: actor()
  def session_actor(session) when is_map(session) do
    %{
      subject_id: Map.get(session, "subject_id"),
      tenant_id: Map.get(session, "tenant_id"),
      auth_method: Map.get(session, "auth_method"),
      recent_auth_at: normalize_recent_auth_at(Map.get(session, "recent_auth_at"))
    }
  end

  defp normalize_result({:ok, %{actor: actor} = result}) when is_map(actor) do
    {:ok, %{actor: normalize_actor(actor), assigns: Map.get(result, :assigns, %{})}}
  end

  defp normalize_result({:ok, actor}) when is_map(actor) do
    {:ok, %{actor: normalize_actor(actor), assigns: %{}}}
  end

  defp normalize_result({:error, reason, details}) when reason in [:unauthorized, :stale_auth] and is_map(details) do
    {:error, reason, details}
  end

  defp normalize_result(other) do
    raise ArgumentError,
          "operator auth returned an invalid result: #{inspect(other)}"
  end

  defp normalize_actor(actor) do
    actor
    |> Map.new(fn
      {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
      pair -> pair
    end)
    |> Map.update(:recent_auth_at, nil, &normalize_recent_auth_at/1)
  rescue
    ArgumentError ->
      Map.update(actor, :recent_auth_at, nil, &normalize_recent_auth_at/1)
  end

  defp normalize_recent_auth_at(nil), do: nil
  defp normalize_recent_auth_at(%DateTime{} = value), do: value
  defp normalize_recent_auth_at(%NaiveDateTime{} = value), do: DateTime.from_naive!(value, "Etc/UTC")

  defp normalize_recent_auth_at(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, parsed, _offset} -> parsed
      _ -> raise ArgumentError, "recent_auth_at must be a DateTime, NaiveDateTime, ISO8601 string, or nil"
    end
  end

  defp normalize_recent_auth_at(value) do
    raise ArgumentError,
          "recent_auth_at must be a DateTime, NaiveDateTime, ISO8601 string, or nil, got: #{inspect(value)}"
  end
end
