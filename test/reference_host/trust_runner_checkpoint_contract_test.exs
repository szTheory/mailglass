defmodule Mailglass.ReferenceHost.TrustRunnerCheckpointContractTest do
  use ExUnit.Case, async: false

  alias Mailglass.ReferenceHost.TrustRunnerFixtures

  @project_root Path.expand("../..", __DIR__)

  test "two dry runs emit deterministic equivalent checkpoints with stable hash" do
    checkpoint_dir = Path.join(@project_root, "tmp/mailglass_trust_runner")
    checkpoint_1 = Path.join(checkpoint_dir, "checkpoint-1.json")
    checkpoint_2 = Path.join(checkpoint_dir, "checkpoint-2.json")

    File.rm_rf!(checkpoint_dir)
    File.mkdir_p!(checkpoint_dir)

    assert {_, 0} =
             System.cmd(
               "mix",
               ["verify.reference_host.journey", "--dry-run", "--checkpoint-out", checkpoint_1],
               cd: @project_root,
               stderr_to_stdout: true,
               env: [{"MIX_ENV", "test"}]
             )

    assert {_, 0} =
             System.cmd(
               "mix",
               ["verify.reference_host.journey", "--dry-run", "--checkpoint-out", checkpoint_2],
               cd: @project_root,
               stderr_to_stdout: true,
               env: [{"MIX_ENV", "test"}]
             )

    payload_1 = decode!(checkpoint_1)
    payload_2 = decode!(checkpoint_2)

    assert normalize(payload_1) == normalize(payload_2)
    assert payload_1["checkpoint_sha256"] == payload_2["checkpoint_sha256"]
    assert payload_1["schema_version"] == "trust_runner.v1"
    assert payload_1["claim_boundary"] =~ "deferred to Phase 58"
  end

  test "webhook ingest checkpoint includes route-level Postmark proof evidence" do
    checkpoint_dir = Path.join(@project_root, "tmp/mailglass_trust_runner")
    checkpoint = Path.join(checkpoint_dir, "phase58-plan01-webhook.json")

    File.rm_rf!(checkpoint_dir)
    File.mkdir_p!(checkpoint_dir)

    assert {_, 0} =
             System.cmd(
               "mix",
               ["verify.reference_host.journey", "--checkpoint-out", checkpoint],
               cd: @project_root,
               stderr_to_stdout: true,
               env: [{"MIX_ENV", "test"}]
             )

    payload = decode!(checkpoint)
    webhook = checkpoint_for_stage(payload, "webhook_ingest")

    assert webhook["status"] == "completed"
    assert webhook["fixture_id"] == "trust.webhook_ingest.001"

    assert webhook["evidence"] == TrustRunnerFixtures.webhook_ingest_evidence()
  end

  defp decode!(path), do: path |> File.read!() |> Jason.decode!()

  defp checkpoint_for_stage(payload, stage) do
    Enum.find(payload["checkpoints"], &(&1["stage"] == stage))
  end

  defp normalize(payload) do
    %{
      "schema_version" => payload["schema_version"],
      "claim_boundary" => payload["claim_boundary"],
      "checkpoint_count" => payload["checkpoint_count"],
      "checkpoint_sha256" => payload["checkpoint_sha256"],
      "checkpoints" => payload["checkpoints"]
    }
  end
end
