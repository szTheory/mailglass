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

  @spec async_parity!(map()) :: map()
  def async_parity!(proof) when is_map(proof) do
    required =
      ~w(job_inserted job_terminal delivery_sent payload_scrubbed event_count capture_count transition_order sync_input_sha256 async_input_sha256)

    unless Enum.all?(required, &Map.has_key?(proof, &1)) do
      raise "generated-host async parity proof is incomplete"
    end

    unless proof["job_inserted"] and proof["job_terminal"] and proof["delivery_sent"] and
             proof["payload_scrubbed"] and proof["event_count"] >= 2 and proof["capture_count"] >= 2 and
             proof["sync_input_sha256"] == proof["async_input_sha256"] do
      raise "generated-host async parity proof did not settle successfully"
    end

    %{
      "name" => "async_parity",
      "status" => "passed",
      "job_inserted" => true,
      "job_terminal" => true,
      "delivery_sent" => true,
      "payload_scrubbed" => true,
      "event_count" => proof["event_count"],
      "capture_count" => proof["capture_count"],
      "transition_order_sha256" => sha(Jason.encode!(proof["transition_order"])),
      "parity_sha256" => proof["sync_input_sha256"]
    }
  end

  @spec negative_controls!([map()]) :: map()
  def negative_controls!(controls) when is_list(controls) and controls != [] do
    normalized = Enum.map(controls, &stringify_keys/1)

    Enum.each(normalized, fn control ->
      required = ~w(name reason_class result before after)

      unless Enum.all?(required, &Map.has_key?(control, &1)),
        do: raise("generated-host negative control is incomplete")

      unless control["result"] == "rejected",
        do: raise("generated-host negative control did not reject")

      unless control["before"] == control["after"],
        do: raise("generated-host negative control has a nonzero effect delta")

      unless Enum.all?(control["before"], fn {_key, value} -> is_integer(value) and value >= 0 end),
        do: raise("generated-host negative control has invalid effects")
    end)

    %{"name" => "negative_controls", "status" => "passed", "controls" => normalized}
  end

  defp stringify_keys(map) when is_map(map),
    do: Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)

  defp stringify_keys(value) when is_list(value), do: Enum.map(value, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp sha(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
end
