if Code.ensure_loaded?(Oban.Worker) do
  defmodule MailglassInbound.Execution.Worker do
    @moduledoc false

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
        execution_opts = [source: source_from_args(args)]

        with {:ok, persisted} <- loader.load(args),
             {:ok, result} <- execution.execute(persisted, execution_opts) do
          normalize_result(result)
        else
          {:error, reason} -> {:error, reason}
        end
      end)
    end

    defp normalize_result(%{outcome: :failed, failure: failure}) when is_map(failure),
      do: {:error, failure}

    defp normalize_result(_result), do: :ok

    defp wrap_perform(job, fun) do
      if Code.ensure_loaded?(Mailglass.Oban.TenancyMiddleware) do
        Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fun)
      else
        fun.()
      end
    end

    defp source_from_args(%{"source" => source}) when is_binary(source), do: String.to_atom(source)
    defp source_from_args(_args), do: :fresh
  end
end
