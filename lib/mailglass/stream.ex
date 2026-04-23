defmodule Mailglass.Stream do
  @moduledoc """
  Stream policy seam (SEND-01 stage 3, D-25).

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
  pipeline (Plan 05) is stable across versions. Adding stream_policy
  later would be a breaking change to the pipeline order; shipping a
  no-op now locks the contract.
  """

  alias Mailglass.Message

  @doc """
  Checks stream policy for the given message. Returns `:ok` at v0.1 for all streams.

  Pattern-matches on `%Mailglass.Message{}` only — passing a raw map raises `FunctionClauseError`.
  Emits `[:mailglass, :outbound, :stream_policy, :stop]` telemetry on every call.

  v0.5 DELIV-02 will swap this implementation; callers do not change.
  """
  @doc since: "0.1.0"
  @spec policy_check(Message.t()) :: :ok
  def policy_check(%Message{} = msg) do
    start = System.monotonic_time(:microsecond)
    duration_us = System.monotonic_time(:microsecond) - start

    :telemetry.execute(
      [:mailglass, :outbound, :stream_policy, :stop],
      %{duration_us: duration_us},
      %{tenant_id: msg.tenant_id, stream: msg.stream}
    )

    :ok
  end
end
