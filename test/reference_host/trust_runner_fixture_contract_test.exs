defmodule Mailglass.ReferenceHost.TrustRunnerFixtureContractTest do
  use ExUnit.Case, async: true

  alias Mailglass.ReferenceHost.TrustRunnerFixtures

  test "fixture IDs and stage order remain deterministic" do
    expected_rows = [
      %{"fixture_id" => "trust.install.001", "order" => 1, "stage" => "install"},
      %{"fixture_id" => "trust.preview.001", "order" => 2, "stage" => "preview"},
      %{"fixture_id" => "trust.send.001", "order" => 3, "stage" => "send"},
      %{"fixture_id" => "trust.webhook_ingest.001", "order" => 4, "stage" => "webhook_ingest"},
      %{
        "fixture_id" => "trust.operator_troubleshooting.001",
        "order" => 5,
        "stage" => "operator_troubleshooting"
      }
    ]

    assert TrustRunnerFixtures.stage_fixtures() == expected_rows
    assert TrustRunnerFixtures.stage_fixtures() == expected_rows
    assert TrustRunnerFixtures.stage_names() == Enum.map(expected_rows, & &1["stage"])
  end
end
