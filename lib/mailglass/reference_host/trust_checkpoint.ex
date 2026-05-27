defmodule Mailglass.ReferenceHost.TrustCheckpoint do
  @moduledoc """
  Deterministic trust-checkpoint encoder for reference-host journey evidence.
  """

  @schema_version "trust_runner.v1"

  @claim_boundary "reference-host trust-journey confidence only; signed-negative webhook and non-happy-path diagnosis are deferred to Phase 58"

  @stage_order %{
    "install" => 1,
    "preview" => 2,
    "send" => 3,
    "webhook_ingest" => 4,
    "operator_troubleshooting" => 5
  }

  @spec schema_version() :: String.t()
  def schema_version, do: @schema_version

  @spec claim_boundary() :: String.t()
  def claim_boundary, do: @claim_boundary

  @spec encode([map()]) :: map()
  def encode(checkpoints) when is_list(checkpoints) do
    normalized_rows =
      checkpoints
      |> Enum.map(&normalize_row/1)
      |> Enum.sort_by(&row_sort_key/1)

    %{
      "schema_version" => @schema_version,
      "claim_boundary" => @claim_boundary,
      "checkpoint_count" => Enum.count(normalized_rows),
      "checkpoint_sha256" => checkpoint_sha256(normalized_rows),
      "checkpoints" => normalized_rows
    }
  end

  defp normalize_row(row) when is_map(row) do
    stage = row["stage"] || row[:stage] || row["stage_key"] || row[:stage_key]
    status = row["status"] || row[:status] || "completed"
    fixture_id = row["fixture_id"] || row[:fixture_id] || "#{stage}.fixture"

    %{
      "stage" => to_string(stage),
      "status" => to_string(status),
      "fixture_id" => to_string(fixture_id)
    }
    |> maybe_put_evidence(row["evidence"] || row[:evidence])
  end

  defp maybe_put_evidence(row, nil), do: row

  defp maybe_put_evidence(row, evidence) when is_map(evidence),
    do: Map.put(row, "evidence", evidence)

  defp row_sort_key(row) do
    stage = row["stage"]
    stage_rank = Map.get(@stage_order, stage, 999)
    {stage_rank, stage, row["fixture_id"], row["status"]}
  end

  defp checkpoint_sha256(rows) do
    rows
    |> Enum.map(fn row -> "#{row["stage"]}|#{row["status"]}|#{row["fixture_id"]}" end)
    |> Enum.join("\n")
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
