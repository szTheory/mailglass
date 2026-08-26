defmodule MailglassAdmin.TestSupport.BrowserTimeoutEvidence do
  @moduledoc false

  @spec record(String.t(), non_neg_integer()) :: :ok
  def record(stage, elapsed_ms)
      when is_binary(stage) and is_integer(elapsed_ms) and elapsed_ms >= 0 do
    validate_stage!(stage)

    case System.get_env("MAILGLASS_BROWSER_SERVER_EVIDENCE_PATH") do
      nil ->
        :ok

      path ->
        event = %{
          schema_version: 1,
          kind: "stage",
          lane: "browser",
          stage: stage,
          elapsed_ms: elapsed_ms
        }

        File.mkdir_p!(Path.dirname(path))

        :global.trans({__MODULE__, path}, fn ->
          File.write!(path, Jason.encode!(event) <> "\n", [:append])
        end)

        :ok
    end
  end

  defp validate_stage!(stage) do
    unless Regex.match?(~r/\A[a-z0-9]+(?:[._-][a-z0-9]+)*\z/, stage) do
      raise ArgumentError,
            "browser evidence stage must be a stable lowercase identifier, got: #{inspect(stage)}"
    end
  end
end
