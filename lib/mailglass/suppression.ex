defmodule Mailglass.Suppression do
  @moduledoc """
  Public preflight facade for suppression checks (SEN).

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

  import Ecto.Query

  alias Mailglass.{Message, SendError, SuppressedError}
  alias Mailglass.Repo
  alias Mailglass.Suppression.Entry
  alias Mailglass.Tenancy

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
        emit_pre_send_blocked(duration_us, result, msg)

        {:error,
         SuppressedError.new(scope,
           context: error_context(msg, result)
         )}

      {:error, err} ->
        emit_telemetry(duration_us, false, msg.tenant_id)
        {:error, err}
    end
  end

  @doc """
  Removes a suppression entry unless the reason is permanently non-removable.

  Complaint and unsubscribe rows remain durable compliance controls and return
  a structured rejection error instead of deleting the row.
  """
  @doc since: "0.2.0"
  @spec remove(Ecto.UUID.t(), keyword()) ::
          {:ok, Entry.t()}
          | {:error, SendError.t() | Ecto.Changeset.t() | :invalid_id | :not_found}
  def remove(id, opts \\ [])

  def remove(id, opts) when is_binary(id) and is_list(opts) do
    tenant_id = Keyword.get(opts, :tenant_id, Tenancy.current())

    Mailglass.Telemetry.persist_span(
      [:suppression, :remove],
      %{tenant_id: tenant_id},
      fn ->
        case fetch_entry(id, tenant_id) do
          nil ->
            {:error, :not_found}

          %Entry{reason: reason} = entry when reason in [:complaint, :unsubscribe] ->
            {:error, permanent_reason_error(entry)}

          %Entry{} = entry ->
            Repo.delete(entry)
        end
      end
    )
  end

  def remove(_id, _opts), do: {:error, :invalid_id}

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

  defp emit_pre_send_blocked(duration_us, {:suppressed, %Entry{} = entry}, %Message{} = msg) do
    :telemetry.execute(
      [:mailglass, :suppression, :pre_send_blocked, :stop],
      %{duration_us: duration_us},
      %{
        tenant_id: msg.tenant_id,
        scope: entry.scope,
        reason: entry.reason,
        source: entry.source,
        expires_at?: not is_nil(entry.expires_at)
      }
    )
  end

  defp error_context(%Message{} = msg, {:suppressed, %Entry{} = entry}) do
    %{
      tenant_id: msg.tenant_id,
      stream: msg.stream,
      reason: entry.reason,
      source: entry.source,
      expires_at: entry.expires_at
    }
  end

  defp fetch_entry(id, tenant_id) when is_binary(tenant_id) do
    Entry
    |> where([entry], entry.id == ^id and entry.tenant_id == ^tenant_id)
    |> Tenancy.scope(tenant_id)
    |> Repo.one()
  end

  defp fetch_entry(_id, _tenant_id), do: nil

  defp permanent_reason_error(%Entry{} = entry) do
    SendError.new(:preflight_rejected,
      context: %{
        tenant_id: entry.tenant_id,
        reason: entry.reason,
        scope: entry.scope,
        stream: entry.stream,
        removable: false
      }
    )
  end
end
