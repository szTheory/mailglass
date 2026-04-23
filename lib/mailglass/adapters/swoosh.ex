defmodule Mailglass.Adapters.Swoosh do
  @moduledoc """
  Adapter bridging to any `Swoosh.Adapter` (TRANS-03).

  Adopters configure their Swoosh adapter once and mailglass wraps it —
  they keep existing Postmark/SendGrid/Mailgun/SES/Resend/SMTP config.
  mailglass adds error normalization into `%Mailglass.SendError{}` and
  telemetry instrumentation via `Mailglass.Telemetry.dispatch_span/2`.

  Pure: no DB, no PubSub, no `Process.put`. Caller's process owns the
  HTTP request via Swoosh's `:api_client` (adopter-supplied, typically
  Finch). LIB-06 satisfied.

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
  | `{:api_error, status, body}` | `:adapter_failure` | `provider_status`, `body_preview` (200 bytes), `provider_module` |
  | Other `{:error, reason}` atoms | `:adapter_failure` | `reason_class`, `provider_module` |
  | Malformed responses | `:adapter_failure` | `reason_class: :malformed` |

  **PII policy:** `body_preview` is a 200-byte head of the provider's
  response body — may contain provider-emitted error strings (never
  user-supplied content). The 8 forbidden keys
  (`:to, :from, :body, :html_body, :subject, :headers, :recipient, :email`)
  NEVER appear in error context. Phase 6 `LINT-02 NoPiiInTelemetryMeta`
  enforces.

  ## What this module does NOT do

  - Does not call `Swoosh.Mailer.deliver/1` — forbidden by LINT-01.
    Calls `Swoosh.Adapter.deliver/2` (the behaviour callback) directly.
  - Is not a GenServer — pure function, stateless.
  - Does not touch `mailglass_events`, `mailglass_deliveries`, or
    `Phoenix.PubSub`. Side-effect-free by design (LIB-06).
  """

  @behaviour Mailglass.Adapter

  @impl Mailglass.Adapter
  def deliver(%Mailglass.Message{swoosh_email: %Swoosh.Email{} = email} = msg, opts) do
    swoosh_adapter = resolve_swoosh_adapter(opts)

    Mailglass.Telemetry.dispatch_span(
      %{tenant_id: msg.tenant_id, mailable: msg.mailable, provider: module_atom(swoosh_adapter)},
      fn ->
        raw_deliver(swoosh_adapter, email)
      end
    )
  end

  defp raw_deliver(swoosh_adapter, email) do
    {mod, config} = normalize_swoosh_adapter(swoosh_adapter)

    case mod.deliver(email, config) do
      {:ok, %{id: message_id} = response} when is_binary(message_id) ->
        {:ok, %{message_id: message_id, provider_response: response}}

      {:ok, response} when is_map(response) ->
        {:ok, %{message_id: synthetic_id(), provider_response: response}}

      {:error, {:api_error, status, body}} ->
        {:error,
         Mailglass.SendError.new(:adapter_failure,
           context: %{
             provider_status: status,
             provider_module: mod,
             body_preview: body_preview(body),
             reason_class: classify_status(status)
           },
           cause: build_delivery_error({:api_error, status, body})
         )}

      {:error, reason} ->
        {:error,
         Mailglass.SendError.new(:adapter_failure,
           context: %{
             provider_module: mod,
             reason_class: classify_reason(reason)
           },
           cause: reason_as_exception(reason)
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

  defp body_preview(body) when is_binary(body),
    do: binary_part(body, 0, min(200, byte_size(body)))

  defp body_preview(body), do: inspect(body, limit: 50, printable_limit: 200)

  defp module_atom({mod, _opts}), do: mod
  defp module_atom(mod) when is_atom(mod), do: mod

  defp classify_status(status) when status >= 500, do: :server_error
  defp classify_status(status) when status >= 400, do: :client_error
  defp classify_status(_), do: :unknown

  defp classify_reason(:timeout), do: :transport
  defp classify_reason({:tls_alert, _}), do: :transport
  defp classify_reason(_other), do: :other

  defp reason_as_exception(%_{} = ex), do: ex
  defp reason_as_exception(other), do: %RuntimeError{message: inspect(other, limit: 50)}

  defp build_delivery_error({:api_error, status, body}) do
    # Construct a descriptive exception without coupling to Swoosh.DeliveryError struct
    # (Swoosh may change the shape). Use RuntimeError with a non-PII summary.
    %RuntimeError{message: "Provider returned HTTP #{status}: #{body_preview(body)}"}
  end
end
