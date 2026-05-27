defmodule Mailglass.Stream do
  @moduledoc """
  Stream policy seam (SEN stage 3, ).

  At v0.1 this is a no-op that returns `:ok` for every valid stream
  (valid streams are enforced at schema level via `Ecto.Enum` on
  `Mailglass.Outbound.Delivery.stream`). Emits a single telemetry
  event for observability.

  v0.5 DELIV-02 swaps this implementation in place; callers do not
  change. The v0.5 impl will enforce:

  - `:transactional` stream: no tracking injection allowed
  - `:bulk` stream: RFC 8058 List-Unsubscribe header auto-injected
  - Per-stream provider routing via per-tenant adapter resolver (DELIV-07)

  Why a no-op seam at v0.1 rather than "omit the stage": the preflight
  pipeline () is stable across versions. Adding stream_policy
  later would be a breaking change to the pipeline order; shipping a
  no-op now locks the contract.
  """

  alias Mailglass.Message

  @streams [:transactional, :operational, :bulk]

  @doc """
  Guard that checks if a value is a valid stream atom.
  """
  defguard is_stream(stream) when stream in @streams

  @doc """
  Checks if a given atom is a valid stream.

  Valid streams are `:transactional`, `:operational`, and `:bulk`.
  """
  @doc since: "0.2.0"
  @spec valid?(atom() | any()) :: boolean()
  def valid?(stream) when is_stream(stream), do: true
  def valid?(_), do: false

  @doc """
  Checks stream policy for the given message. Returns `:ok` at v0.1 for all streams.

  Pattern-matches on `%Mailglass.Message{}` only — passing a raw map raises `FunctionClauseError`.
  Emits `[:mailglass, :outbound, :stream_policy, :stop]` telemetry on every call.

  v0.5 DELIV-02 will swap this implementation; callers do not change.
  """
  @doc since: "0.1.0"
  @spec policy_check(Message.t()) :: :ok | {:error, Mailglass.StreamPolicyError.t()}
  def policy_check(%{__struct__: Mailglass.Message} = msg) do
    start = System.monotonic_time(:microsecond)

    result =
      case msg do
        %{stream: :bulk, mailable: nil} ->
          {:error,
           Mailglass.StreamPolicyError.new(:stream_policy_violated,
             detail: %{
               rule: :bulk_requires_mailable,
               suggestion: "A mailable module is required when sending via the :bulk stream."
             }
           )}

        _ ->
          :ok
      end

    duration_us = System.monotonic_time(:microsecond) - start

    :telemetry.execute(
      [:mailglass, :outbound, :stream_policy, :stop],
      %{duration_us: duration_us},
      %{tenant_id: msg.tenant_id, stream: msg.stream}
    )

    result
  end
end
