defmodule Mailglass.Outbound.PayloadLifecycle do
  @moduledoc false

  alias Mailglass.{Clock, Config}
  alias Mailglass.Outbound.Payload

  @terminal_states [:terminal, :discarded, :abandoned]

  @doc false
  @spec retention_days(Payload.lifecycle_state()) :: pos_integer() | nil
  def retention_days(state) when state in @terminal_states,
    do: Config.outbound_payload_retention()[:terminal_days]

  def retention_days(:uncertain), do: Config.outbound_payload_retention()[:uncertain_days]
  def retention_days(:legacy), do: Config.outbound_payload_retention()[:legacy_days]
  def retention_days(_state), do: nil

  @doc false
  @spec expires_at(Payload.lifecycle_state()) :: DateTime.t() | nil
  def expires_at(state) do
    case retention_days(state) do
      nil -> nil
      days -> DateTime.add(Clock.utc_now(), days * 86_400, :second)
    end
  end

  @doc false
  @spec recovery_eligibility(Payload.t()) ::
          :claimable | :expired | :uncertain | :legacy_unavailable | :unavailable
  def recovery_eligibility(%Payload{lifecycle_state: :recoverable, expires_at: nil}), do: :claimable

  def recovery_eligibility(%Payload{lifecycle_state: :recoverable, expires_at: expires_at}) do
    if DateTime.compare(expires_at, Clock.utc_now()) == :gt, do: :claimable, else: :expired
  end

  # A claimed payload may already have reached a provider. It is never a
  # retry-safe recovery candidate without explicit reconciliation evidence.
  def recovery_eligibility(%Payload{lifecycle_state: :dispatching}), do: :uncertain
  def recovery_eligibility(%Payload{lifecycle_state: :legacy}), do: :legacy_unavailable
  def recovery_eligibility(%Payload{}), do: :unavailable

  @doc false
  @spec prunable?(Payload.lifecycle_state()) :: boolean()
  def prunable?(state), do: is_integer(retention_days(state))
end
