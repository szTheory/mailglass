defmodule Mailglass.TestSupport.TimeoutEvidence do
  @moduledoc """
  Failure-only, non-PII SQLSTATE evidence for the deterministic CI lane.

  The recorder is disabled unless `MAILGLASS_TIMEOUT_EVIDENCE_PATH` is set.
  It records only stable operation labels and allowlisted PostgreSQL metadata,
  then re-raises the original exception with its original stacktrace.
  """

  @schema_version 1

  @spec initialize!() :: :ok
  def initialize! do
    case System.get_env("MAILGLASS_TIMEOUT_EVIDENCE_PATH") do
      nil ->
        :ok

      path ->
        manifest = %{
          schema_version: @schema_version,
          kind: "manifest",
          lane: "database",
          run_id: System.get_env("GITHUB_RUN_ID"),
          job: System.get_env("GITHUB_JOB"),
          head_sha: System.get_env("GITHUB_SHA"),
          event_name: System.get_env("GITHUB_EVENT_NAME"),
          command: System.get_env("MAILGLASS_TIMEOUT_EVIDENCE_COMMAND"),
          toolchain: %{
            elixir: System.version(),
            otp: System.otp_release()
          },
          captured_at: DateTime.utc_now() |> DateTime.to_iso8601()
        }

        File.mkdir_p!(Path.dirname(path))
        File.write!(path, Jason.encode!(manifest) <> "\n")
        :ok
    end
  end

  @spec capture(String.t(), (-> result)) :: result when result: var
  def capture(operation, fun) when is_binary(operation) and is_function(fun, 0) do
    validate_operation!(operation)
    fun.()
  rescue
    error in Postgrex.Error ->
      maybe_record(operation, error)
      reraise error, __STACKTRACE__
  end

  defp validate_operation!(operation) do
    unless Regex.match?(~r/\A[a-z0-9]+(?:[._-][a-z0-9]+)*\z/, operation) do
      raise ArgumentError,
            "timeout evidence operation must be a stable lowercase identifier, got: #{inspect(operation)}"
    end
  end

  defp maybe_record(operation, %Postgrex.Error{postgres: postgres}) when is_map(postgres) do
    if query_canceled?(postgres) do
      record = %{
        schema_version: @schema_version,
        kind: "postgres_error",
        lane: "database",
        operation: operation,
        sqlstate: "57014",
        code: "query_canceled",
        severity: stringify(postgres[:severity]),
        routine: stringify(postgres[:routine])
      }

      append(record)
    end
  end

  defp maybe_record(_operation, _error), do: :ok

  defp query_canceled?(postgres) do
    postgres[:code] in [:query_canceled, "query_canceled", "57014"] or
      postgres[:pg_code] == "57014"
  end

  defp stringify(nil), do: nil
  defp stringify(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify(value) when is_binary(value), do: value
  defp stringify(_value), do: nil

  defp append(record) do
    case System.get_env("MAILGLASS_TIMEOUT_EVIDENCE_PATH") do
      nil ->
        :ok

      path ->
        File.mkdir_p!(Path.dirname(path))

        :global.trans({__MODULE__, path}, fn ->
          File.write!(path, Jason.encode!(record) <> "\n", [:append])
        end)
    end
  end
end
