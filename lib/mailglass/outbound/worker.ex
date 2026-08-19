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

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"delivery_id" => id}} = job) when is_binary(id) do
      Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
        case Mailglass.Outbound.dispatch_by_id(id) do
          {:ok, %Mailglass.Outbound.Delivery{status: :sent}} ->
            :ok

          {:ok, %Mailglass.Outbound.Delivery{status: :failed, last_error: err}} ->
            worker_outcome(err)

          {:error, %Mailglass.SendError{} = err} ->
            worker_outcome(err)

          {:error, _other} ->
            permanent_discard()
        end
      end)
    end

    defp worker_outcome(%Mailglass.SendError{} = err) do
      if Mailglass.SendError.retryable?(err), do: {:error, err}, else: permanent_discard()
    end

    defp worker_outcome(_persisted_or_malformed_error), do: permanent_discard()

    # Oban 2.23.1 documents `{:cancel, reason}` as the non-retrying return.
    # Keep the reason finite so provider or message data cannot reach Oban logs.
    defp permanent_discard, do: {:cancel, :permanent_failure}
  end
end
