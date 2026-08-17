defmodule Mailglass.Adapters.Swoosh do
  @moduledoc """
  Adapter bridging to any `Swoosh.Adapter`.

  Adopters configure their Swoosh adapter once and mailglass wraps it —
  they keep existing Postmark/SendGrid/Mailgun/SES/Resend/SMTP config.
  mailglass adds error normalization into `%Mailglass.SendError{}`. The
  authoritative dispatch span belongs to the outbound facade's `call_adapter/2`,
  so a provider call emits one span rather than a nested duplicate.

  Pure: no DB, no PubSub, no `Process.put`. Caller's process owns the
  HTTP request via Swoosh's `:api_client` (adopter-supplied, typically
  Finch).

  ## Configuration

      config :mailglass,
        adapter: {Mailglass.Adapters.Swoosh,
                  swoosh_adapter: {Swoosh.Adapters.Postmark,
                                   api_key: System.fetch_env!("POSTMARK_API_KEY")}}

  The `:swoosh_adapter` opt carries either a module (for Swoosh adapters
  with no config) or a `{module, opts}` tuple.

  ## Error mapping (v0.1)

  | Swoosh shape | Mapped SendError `:type` | Context fields |
  |--------------|--------------------------|----------------|
  | `{:api_error, 429, _}` or `500..599` | `:adapter_failure` / transient | `provider_status`, `reason_class`, `provider_module` |
  | `{:api_error, 400..499, _}` | `:adapter_failure` / permanent | `provider_status`, `reason_class`, `provider_module` |
  | Known transport/timeouts | `:adapter_failure` / transient | `reason_class: :transport`, `provider_module` |
  | Unknown or malformed outcomes | `:adapter_failure` / permanent | `reason_class: :unknown`, `provider_module` |

  **PII policy:** Provider response bodies and reason text never enter error
  context, exception messages, JSON, or persisted delivery errors. The 8 forbidden keys
  (`:to, :from, :body, :html_body, :subject, :headers, :recipient, :email`)
  NEVER appear in error context.  `NoPiiInTelemetryMeta`
  enforces.

  ## What this module does NOT do

  - Does not call `Swoosh.Mailer.deliver/1` — forbidden in library code.
    Calls `Swoosh.Adapter.deliver/2` (the behaviour callback) directly.
  - Is not a GenServer — pure function, stateless.
  - Does not touch `mailglass_events`, `mailglass_deliveries`, or
    `Phoenix.PubSub`. Side-effect-free by design.
  """

  @behaviour Mailglass.Adapter

  @impl Mailglass.Adapter
  def deliver(%Mailglass.Message{swoosh_email: %Swoosh.Email{} = email} = msg, opts) do
    swoosh_adapter = resolve_swoosh_adapter(opts)
    _ = msg

    raw_deliver(swoosh_adapter, email)
  end

  defp raw_deliver(swoosh_adapter, email) do
    {mod, config} = normalize_swoosh_adapter(swoosh_adapter)

    case mod.deliver(email, config) do
      {:ok, %{id: message_id} = response} when is_binary(message_id) ->
        {:ok, %{message_id: message_id, provider_response: response}}

      {:ok, response} when is_map(response) ->
        {:ok, %{message_id: synthetic_id(), provider_response: response}}

      {:error, {:api_error, status, _body}} ->
        {:error,
         Mailglass.SendError.new(:adapter_failure,
           context: %{
             provider_status: status,
             provider_module: mod,
             reason_class: classify_status(status)
           },
           retry_class: retry_class_for_status(status)
         )}

      {:error, reason} ->
        {:error,
         Mailglass.SendError.new(:adapter_failure,
           context: %{
             provider_module: mod,
             reason_class: classify_reason(reason)
           },
           retry_class: retry_class_for_reason(reason)
         )}
    end
  end

  defp resolve_swoosh_adapter(opts) do
    case Keyword.fetch(opts, :swoosh_adapter) do
      {:ok, {_mod, _kw} = tuple} ->
        tuple

      {:ok, mod} when is_atom(mod) ->
        mod

      :error ->
        case Application.get_env(:mailglass, :adapter) do
          {Mailglass.Adapters.Swoosh, kw} -> Keyword.fetch!(kw, :swoosh_adapter)
          _ -> raise Mailglass.ConfigError.new(:missing, context: %{key: :swoosh_adapter})
        end
    end
  end

  defp normalize_swoosh_adapter({mod, opts}) when is_atom(mod) and is_list(opts), do: {mod, opts}
  defp normalize_swoosh_adapter(mod) when is_atom(mod), do: {mod, []}

  defp synthetic_id do
    "mailglass-synthetic-" <> (:crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false))
  end

  defp classify_status(429), do: :rate_limited
  defp classify_status(status) when is_integer(status) and status in 500..599, do: :server_error
  defp classify_status(status) when is_integer(status) and status in 400..499, do: :client_error
  defp classify_status(_), do: :unknown

  defp retry_class_for_status(429), do: :transient
  defp retry_class_for_status(status) when is_integer(status) and status in 500..599, do: :transient
  defp retry_class_for_status(status) when is_integer(status) and status in 400..499, do: :permanent
  defp retry_class_for_status(_), do: :permanent

  defp classify_reason(reason)
       when reason in [:timeout, :closed, :econnrefused, :enetunreach, :ehostunreach, :nxdomain],
       do: :transport

  defp classify_reason({:tls_alert, _}), do: :transport
  defp classify_reason({:failed_connect, _}), do: :transport
  defp classify_reason(_), do: :unknown

  defp retry_class_for_reason(reason)
       when reason in [:timeout, :closed, :econnrefused, :enetunreach, :ehostunreach, :nxdomain],
       do: :transient

  defp retry_class_for_reason({:tls_alert, _}), do: :transient
  defp retry_class_for_reason({:failed_connect, _}), do: :transient
  defp retry_class_for_reason(_), do: :permanent
end
