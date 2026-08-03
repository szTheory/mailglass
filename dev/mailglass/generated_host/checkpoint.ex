defmodule Mailglass.GeneratedHost.Checkpoint do
  @moduledoc false

  @schema_version "generated_host_proof.v1"

  @spec encode(map()) :: map()
  def encode(input) when is_map(input) do
    stages = Map.get(input, :stages, [])

    payload = %{
      "schema_version" => @schema_version,
      "dependency_mode" => Map.fetch!(input, :dependency_mode),
      "source_sha256" => sha(Map.fetch!(input, :source_sha)),
      "packages" => Map.get(input, :packages, []),
      "stages" => stages,
      "overall_status" =>
        if(Enum.all?(stages, &(&1["status"] == "passed")), do: "passed", else: "failed")
    }

    Map.put(payload, "checkpoint_sha256", sha(Jason.encode!(payload)))
  end

  defp sha(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
end
