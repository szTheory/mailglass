if Code.ensure_loaded?(Oban.Worker) do
  defmodule MailglassInbound.Execution.Worker do
    @moduledoc false

    require Logger

    use Oban.Worker,
      queue: :mailglass_inbound,
      max_attempts: 20,
      unique: [period: 3600, fields: [:args], keys: [:inbound_record_id, :source]]

    alias MailglassInbound.Execution

    @impl Oban.Worker
    def perform(job), do: perform(job, [])

    def perform(%Oban.Job{args: args} = job, opts) when is_list(opts) do
      wrap_perform(job, fn ->
        loader = Keyword.get(opts, :loader, Execution)
        execution = Keyword.get(opts, :execution, Execution)

        with {:ok, source} <- source_from_args(args),
             {:ok, persisted} <- loader.load(args),
             {:ok, _route} <- Execution.validate_job_route(args, persisted.inbound_evidence, []),
             {:ok, result} <- execution.execute(persisted, source: source) do
          normalize_result(result)
        else
          {:error, :invalid_job_args} -> {:cancel, :permanent_failure}
          {:error, :legacy_route_binding_missing} -> legacy_route_binding_missing()
          {:error, :route_authority_unavailable} -> {:error, :route_authority_unavailable}
          {:error, reason} -> {:error, reason}
        end
      end)
    end

    defp normalize_result(%{outcome: :failed, failure: failure}) when is_map(failure),
      do: {:error, failure}

    defp normalize_result(_result), do: :ok

    defp legacy_route_binding_missing do
      Logger.warning(
        "[mailglass_inbound] inbound execution cancelled: durable route binding is missing; replay the tenant-scoped message after the route-binding migration"
      )

      {:cancel, :permanent_failure}
    end

    defp wrap_perform(job, fun) do
      if Code.ensure_loaded?(Mailglass.Oban.TenancyMiddleware) do
        Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fun)
      else
        fun.()
      end
    end

    defp source_from_args(%{"source" => "fresh"}), do: {:ok, :fresh}
    defp source_from_args(%{"source" => "replay"}), do: {:ok, :replay}
    defp source_from_args(%{"source" => _source}), do: {:error, :invalid_job_args}
    defp source_from_args(args) when is_map(args), do: {:ok, :fresh}
    defp source_from_args(_args), do: {:error, :invalid_job_args}
  end
end
