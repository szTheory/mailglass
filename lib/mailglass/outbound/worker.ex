if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Outbound.Worker do
    @moduledoc """
    Oban worker that dispatches a queued Delivery (SEN). Conditionally
    compiled — entire module elided when `:oban` is not loaded.

    ## Args schema (api_stability.md §Outbound.Worker)

        %{
          "delivery_id" => binary(),          # UUIDv7 string
          "mailglass_tenant_id" => binary()   # matches Mailglass.Oban.TenancyMiddleware contract
        }

    **Never** serialize `%Message{}` into args — adopter types may not
    be JSON-safe (functions, PIDs, structs with private fields).

    ## Options locked (api_stability.md §Outbound.Worker)

    - `queue: :mailglass_outbound`
    - `max_attempts: 20` — transactional SLAs are tight; exponential
      backoff reaches ~hours by attempt 20
    - `unique: [period: 3600, fields: [:args], keys: [:delivery_id]]` —
      prevents double-enqueue on retry storms

    ## perform/1 flow

    1. `TenancyMiddleware.wrap_perform/2` restores `Mailglass.Tenancy.current/0`
       from args
    2. `Mailglass.Outbound.dispatch_by_id/1` hydrates the Delivery by id,
       calls the adapter OUTSIDE the job's transaction, writes Multi#2
    """

    use Oban.Worker,
      queue: :mailglass_outbound,
      max_attempts: 20,
      unique: [period: 3600, fields: [:args], keys: [:delivery_id]]

    @doc false
    @spec queue() :: :mailglass_outbound
    def queue, do: :mailglass_outbound

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"delivery_id" => id}} = job) when is_binary(id) do
      Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
        case Mailglass.Outbound.dispatch_by_id(id) do
          {:ok, %Mailglass.Outbound.Delivery{status: :sent}} ->
            :ok

          {:ok, %Mailglass.Outbound.Delivery{status: :failed, last_error: err}} ->
            {:error, err}

          {:error, %{__exception__: true} = err} ->
            worker_error_result(err)

          {:error, %Mailglass.Outbound.DispatchOutcome{class: :retryable} = outcome} ->
            {:error, outcome.reason_class}

          {:error, %Mailglass.Outbound.DispatchOutcome{class: class} = outcome}
          when class in [:terminal, :uncertain] ->
            {:cancel, outcome.reason_class}

          {:error, other} ->
            {:error, inspect(other)}
        end
      end)
    end

    defp worker_result(%Mailglass.Outbound.DispatchOutcome{class: :retryable} = outcome),
      do: {:error, outcome.reason_class}

    defp worker_result(%Mailglass.Outbound.DispatchOutcome{class: class} = outcome)
         when class in [:terminal, :uncertain],
         do: {:cancel, outcome.reason_class}

    # Preserve the established callback-visible errors for legacy rows while
    # making lifecycle-originated payload facts terminal/cancelled.
    defp worker_error_result(
           %Mailglass.SendError{
             context: %{reason_class: :legacy_payload_integrity_unverifiable}
           } = err
         ),
         do: {:cancel, err}

    # A claim can observe a terminal payload fact written by an earlier
    # attempt. Preserve that terminal classification rather than handing the
    # typed lifecycle error back to Oban as retryable work.
    defp worker_error_result(%Mailglass.SendError{context: %{outcome_class: :terminal}} = err),
      do: worker_result(Mailglass.Outbound.DispatchOutcome.classify({:error, err}))

    defp worker_error_result(%Mailglass.SendError{context: %{reason_class: reason}} = err)
         when reason in [
                :legacy_payload_unavailable,
                :payload_missing,
                :payload_corrupt,
                :payload_unsupported_version,
                :payload_expired,
                :payload_scrubbed,
                :payload_dispatching,
                :persisted_adapter_mismatch
              ],
         do: worker_result(Mailglass.Outbound.DispatchOutcome.classify({:error, err}))

    defp worker_error_result(err), do: {:error, err}
  end
end
