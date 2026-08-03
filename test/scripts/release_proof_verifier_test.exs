defmodule Mailglass.Scripts.ReleaseProofVerifierTest do
  use ExUnit.Case, async: true

  @script Path.expand("../../scripts/verify_release_proof.exs", __DIR__)
  @checksum String.duplicate("b", 64)

  test "accepts only a ledger-bound protected publish run with exact artifact evidence" do
    with_fixture(%{}, fn ledger, fixture ->
      {output, status} = verify(ledger, fixture)
      assert status == 0, output
      assert output =~ "release proof verified"
    end)
  end

  test "fails closed on unapproved environment, tag SHA, package, version, or checksum drift" do
    for {field, value} <- [
          {"environment_approved", false},
          {"tag_sha", "deadbeef"},
          {"published_packages", [%{"name" => "mailglass", "version" => "9.9.9", "checksum" => @checksum}]},
          {"archive_checksum", "bad-checksum"}
        ] do
      with_fixture(%{field => value}, fn ledger, fixture ->
        {output, status} = verify(ledger, fixture)
        assert status != 0
        assert output =~ "release proof verification failed"
      end)
    end
  end

  defp verify(ledger, fixture) do
    System.cmd("mix", ["run", @script, "--", "--ledger", ledger, "--fixture", fixture, "--stage", "prepublication"],
      stderr_to_stdout: true
    )
  end

  defp with_fixture(overrides, fun) do
    root = Path.join(System.tmp_dir!(), "mailglass-release-proof-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    ledger = Path.join(root, "ledger.json")
    fixture = Path.join(root, "fixture.json")
    candidate = String.duplicate("a", 40)

    File.write!(ledger, Jason.encode!(ledger(candidate)))
    File.write!(fixture, Jason.encode!(Map.merge(fixture(candidate), overrides)))

    try do
      fun.(ledger, fixture)
    after
      File.rm_rf(root)
    end
  end

  defp ledger(candidate), do: %{
    "candidate" => %{"sha" => candidate, "tag" => "mailglass-v2.4.0"},
    "publication" => %{"workflow_path" => ".github/workflows/publish-hex.yml", "workflow_name" => "publish-hex", "environment" => "hex-publish", "run_id" => 123, "run_url" => "https://github.example/runs/123"},
    "release_packages" => ["mailglass", "mailglass_admin", "mailglass_inbound"],
    "target_versions" => %{"mailglass" => "2.4.0", "mailglass_admin" => "2.4.0", "mailglass_inbound" => "2.1.1"},
    "archive_checksums" => %{"mailglass" => @checksum, "mailglass_admin" => @checksum, "mailglass_inbound" => @checksum}
  }

  defp fixture(candidate), do: %{
    "workflow_path" => ".github/workflows/publish-hex.yml", "workflow_name" => "publish-hex", "run_id" => 123, "run_url" => "https://github.example/runs/123", "head_sha" => candidate, "tag_sha" => candidate, "environment" => "hex-publish", "environment_approved" => true,
    "publish_jobs" => ["publish-core", "publish-admin", "publish-inbound"],
    "published_packages" => Enum.map([{"mailglass", "2.4.0"}, {"mailglass_admin", "2.4.0"}, {"mailglass_inbound", "2.1.1"}], fn {name, version} -> %{"name" => name, "version" => version, "checksum" => @checksum} end),
    "archive_checksum" => @checksum
  }
end
