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

  @spec feedback!(map()) :: map()
  def feedback!(proof) when is_map(proof) do
    required =
      ~w(valid_status valid_body_bytes forged_status forged_body_bytes webhook_event_count ledger_event_count forged_effects_zero)

    unless Enum.all?(required, &Map.has_key?(proof, &1)) and proof["valid_status"] == 200 and
             proof["valid_body_bytes"] == 0 and proof["forged_status"] == 401 and
             proof["forged_body_bytes"] == 0 and proof["webhook_event_count"] >= 1 and
             proof["ledger_event_count"] >= 1 and proof["forged_effects_zero"] do
      raise "generated-host feedback proof is incomplete"
    end

    Map.take(proof, required) |> Map.put("name", "feedback") |> Map.put("status", "passed")
  end

  @spec one_click!(map()) :: map()
  def one_click!(proof) when is_map(proof) do
    required =
      ~w(first_status first_body_bytes replay_status replay_body_bytes canonical_event_count canonical_suppression_count matching_send transactional_send unrelated_stream_send matching_capture_growth control_capture_growth)

    unless Enum.all?(required, &Map.has_key?(proof, &1)) and proof["first_status"] == 200 and
             proof["first_body_bytes"] == 0 and proof["replay_status"] == 200 and
             proof["replay_body_bytes"] == 0 and proof["canonical_event_count"] == 1 and
             proof["canonical_suppression_count"] == 1 and proof["matching_send"] == "suppressed" and
             proof["transactional_send"] == "sent" and proof["unrelated_stream_send"] == "sent" and
             proof["matching_capture_growth"] == 0 and proof["control_capture_growth"] == 2 do
      raise "generated-host one-click proof is incomplete"
    end

    Map.take(proof, required) |> Map.put("name", "one_click") |> Map.put("status", "passed")
  end

  defp stringify_keys(map) when is_map(map),
    do: Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)

  defp stringify_keys(value) when is_list(value), do: Enum.map(value, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp sha(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
end
