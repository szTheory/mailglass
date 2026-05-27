defmodule Mailglass.ReferenceHost.TrustRunnerFixtures do
  @moduledoc """
  Deterministic fixture catalog for the reference-host trust runner journey.
  """

  @stage_rows [
    %{fixture_id: "trust.install.001", stage: "install", order: 1},
    %{fixture_id: "trust.preview.001", stage: "preview", order: 2},
    %{fixture_id: "trust.send.001", stage: "send", order: 3},
    %{fixture_id: "trust.webhook_ingest.001", stage: "webhook_ingest", order: 4},
    %{fixture_id: "trust.operator_troubleshooting.001", stage: "operator_troubleshooting", order: 5}
  ]

  @spec stage_fixtures() :: [map()]
  def stage_fixtures do
    @stage_rows
    |> Enum.map(fn row ->
      %{
        "fixture_id" => row.fixture_id,
        "stage" => row.stage,
        "order" => row.order
      }
    end)
    |> Enum.sort_by(fn row -> {row["order"], row["stage"], row["fixture_id"]} end)
  end

  @spec stage_names() :: [String.t()]
  def stage_names do
    stage_fixtures()
    |> Enum.map(& &1["stage"])
  end

  @spec fixture_for_stage(String.t() | atom()) :: map() | nil
  def fixture_for_stage(stage) when is_atom(stage), do: fixture_for_stage(Atom.to_string(stage))

  def fixture_for_stage(stage) when is_binary(stage) do
    Enum.find(stage_fixtures(), &(&1["stage"] == stage))
  end
end
