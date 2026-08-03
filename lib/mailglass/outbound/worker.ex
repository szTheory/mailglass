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
            if terminal_payload_error?(err), do: {:cancel, err}, else: {:error, err}

          {:error, other} ->
            {:error, inspect(other)}
        end
      end)
    end

    defp terminal_payload_error?(%Mailglass.SendError{
           context: %{reason_class: :legacy_payload_integrity_unverifiable}
         }),
         do: true

    defp terminal_payload_error?(_), do: false
  end
end
