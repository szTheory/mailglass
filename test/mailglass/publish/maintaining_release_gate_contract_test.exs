defmodule Mailglass.Publish.MaintainingReleaseGateContractTest do
  use ExUnit.Case, async: true

  @maintaining_path Path.expand("../../../MAINTAINING.md", __DIR__)

  test "release runbook requires trust evidence and does not mention stale approval gates" do
    maintaining = File.read!(@maintaining_path)

    assert maintaining =~ "Trust Lane Repo Head (Elixir 1.18 / OTP 27)"
    assert maintaining =~ ~r/trust-runner-(repo-head|clean-baseline|published)/

    refute maintaining =~ "requires manual approval in the GitHub Actions UI"
    refute maintaining =~ ~r/Approve the `hex-publish` deployment/
    refute maintaining =~ "single required reviewer"
  end
end
