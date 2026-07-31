defmodule Mailglass.Scripts.ReleaseTriggerRecoveryTest do
  use ExUnit.Case, async: true

  @workflow_path Path.expand("../../.github/workflows/release-please.yml", __DIR__)

  test "release-please retains the complete recovery trigger set" do
    source = File.read!(@workflow_path)

    assert extract_trigger_block!(source, "push") =~ "branches:\n      - main"
    assert extract_trigger_block!(source, "workflow_dispatch") =~ "workflow_dispatch: {}"
    assert extract_trigger_block!(source, "schedule") =~ "cron: \"17 * * * *\""
  end
end
