defmodule Mailglass.Suppression do
  @moduledoc """
  Public preflight facade for suppression checks (SEND-04).

  Thin wrapper over `Mailglass.SuppressionStore.check/2` configured via:

      config :mailglass, :suppression_store, Mailglass.SuppressionStore.Ecto  # default
      config :mailglass, :suppression_store, Mailglass.SuppressionStore.ETS   # test-speed

  ## Return shape

  - `:ok` when the recipient is not suppressed
  - `{:error, %Mailglass.SuppressedError{type: scope}}` on a suppression hit

  ## Telemetry

  Single-emit `[:mailglass, :outbound, :suppression, :stop]` with:
  - Measurements: `%{duration_us: integer()}`
  - Metadata: `%{hit: boolean(), tenant_id: String.t()}`

  **No PII** — neither address nor stream appears in metadata. Context
  on the `%SuppressedError{}` carries `tenant_id` + `stream` only
  (stream is enum-narrow, not recipient-identifying).
  """

  alias Mailglass.{Message, SuppressedError}

  @doc """
  Pre-send suppression check. Returns `:ok` when allowed, `{:error, %SuppressedError{}}` when blocked.

  Extracts the primary recipient from `msg.swoosh_email.to` and delegates to the
  configured `SuppressionStore` implementation.
  """
  @doc since: "0.1.0"
  @spec check_before_send(Message.t()) :: :ok | {:error, SuppressedError.t()}
  def check_before_send(%Message{} = msg) do
    start = System.monotonic_time(:microsecond)

    address = primary_recipient(msg)
    key = %{tenant_id: msg.tenant_id, address: address, stream: msg.stream}

    result = store().check(key, [])
    duration_us = System.monotonic_time(:microsecond) - start

    case result do
      :not_suppressed ->
        emit_telemetry(duration_us, false, msg.tenant_id)
        :ok

      {:suppressed, %{scope: scope}} ->
        emit_telemetry(duration_us, true, msg.tenant_id)

        {:error,
         SuppressedError.new(scope,
           context: %{
             tenant_id: msg.tenant_id,
             stream: msg.stream
           }
         )}

      {:error, err} ->
        emit_telemetry(duration_us, false, msg.tenant_id)
        {:error, err}
    end
  end

  defp store do
    Application.get_env(:mailglass, :suppression_store, Mailglass.SuppressionStore.Ecto)
  end

  defp primary_recipient(%Message{swoosh_email: %Swoosh.Email{to: [{_, addr} | _]}}),
    do: String.downcase(addr)

  defp primary_recipient(%Message{swoosh_email: %Swoosh.Email{to: [addr | _]}})
       when is_binary(addr),
       do: String.downcase(addr)

  defp primary_recipient(_), do: ""

  defp emit_telemetry(duration_us, hit, tenant_id) do
    :telemetry.execute(
      [:mailglass, :outbound, :suppression, :stop],
      %{duration_us: duration_us},
      %{hit: hit, tenant_id: tenant_id}
    )
  end
end
