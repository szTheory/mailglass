defmodule Mailglass.ReferenceHost.TrustRunnerCheckpointContractTest do
  use ExUnit.Case, async: false

  # Requires the full repo workspace (reference-host trust runner + sibling
  # MailglassInbound), unavailable in the isolated-core Core Full Suite
  # lane. Excluded there via `--exclude requires_workspace`; covered in CI by the
  # dedicated Trust Lane lanes.
  @moduletag :requires_workspace

  alias Mailglass.ReferenceHost.TrustCheckpoint
  alias Mailglass.ReferenceHost.TrustRunnerFixtures

  @project_root Path.expand("../..", __DIR__)
  @claim_boundary "reference-host trust-journey confidence only; signed Postmark webhook verification and no-match operator diagnosis proven by deterministic runner evidence"
  @row_hash_contract "stage|status|fixture_id"
  @stage_order ["install", "preview", "send", "webhook_ingest", "operator_troubleshooting"]
  @generated_host_script_path Path.expand("../../scripts/generated_ecto_host_proof.sh", __DIR__)
  @workspace_core_ebin Path.expand("../../_build/test/lib/mailglass/ebin", __DIR__)
  @workspace_inbound_root Path.expand("../../mailglass_inbound", __DIR__)
  @workspace_inbound_ebin Path.join(
                            @workspace_inbound_root,
                            "_build/test/lib/mailglass_inbound/ebin"
                          )

  setup_all do
    {output, exit_code} =
      System.cmd("mix", ["compile", "--warnings-as-errors"],
        cd: @workspace_inbound_root,
        stderr_to_stdout: true,
        env: [
          {"MIX_ENV", "test"},
          {"MIX_BUILD_PATH", nil},
          {"MIX_DEPS_PATH", nil}
        ]
      )

    assert exit_code == 0, "workspace inbound compile failed:\n#{output}"
    assert File.dir?(@workspace_core_ebin)
    assert File.dir?(@workspace_inbound_ebin)
    :ok
  end

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
               env: workspace_runner_env()
             )

    assert {_, 0} =
             System.cmd(
               "mix",
               ["verify.reference_host.journey", "--dry-run", "--checkpoint-out", checkpoint_2],
               cd: @project_root,
               stderr_to_stdout: true,
               env: workspace_runner_env()
             )

    payload_1 = decode!(checkpoint_1)
    payload_2 = decode!(checkpoint_2)

    assert normalize(payload_1) == normalize(payload_2)
    assert payload_1["checkpoint_sha256"] == payload_2["checkpoint_sha256"]
    assert payload_1["schema_version"] == "trust_runner.v1"
    assert payload_1["claim_boundary"] == @claim_boundary
    assert Enum.map(payload_1["checkpoints"], & &1["stage"]) == @stage_order

    assert {_, 0} =
             System.cmd(
               "bash",
               ["scripts/check_trust_runner_checkpoint.sh", "--checkpoint", checkpoint_1],
               cd: @project_root,
               stderr_to_stdout: true
             )
  end

  test "checkpoint hash is based only on ordered stage status fixture_id rows" do
    assert @row_hash_contract == "stage|status|fixture_id"

    rows = [
      %{
        "stage_key" => "webhook_ingest",
        "status" => "completed",
        "fixture_id" => "trust.webhook_ingest.001",
        "evidence" => %{"b" => 2, "a" => 1}
      },
      %{
        "stage_key" => "operator_troubleshooting",
        "status" => "completed",
        "fixture_id" => "trust.operator_troubleshooting.001",
        "evidence" => %{"a" => 1, "b" => 2}
      }
    ]

    reordered_evidence_rows = [
      put_in(Enum.at(rows, 0), ["evidence"], %{"a" => 1, "b" => 2}),
      put_in(Enum.at(rows, 1), ["evidence"], %{"b" => 2, "a" => 1})
    ]

    payload = TrustCheckpoint.encode(rows)
    reordered_payload = TrustCheckpoint.encode(reordered_evidence_rows)

    assert payload["checkpoint_sha256"] == reordered_payload["checkpoint_sha256"]
    assert payload["checkpoint_sha256"] == expected_row_hash(payload["checkpoints"])
  end

  test "non-dry-run checkpoint includes completed Phase 58 evidence" do
    checkpoint_dir = Path.join(@project_root, "tmp/mailglass_trust_runner")
    checkpoint = Path.join(checkpoint_dir, "phase58-plan02-evidence.json")

    File.rm_rf!(checkpoint_dir)
    File.mkdir_p!(checkpoint_dir)

    assert {_, 0} =
             System.cmd(
               "mix",
               ["verify.reference_host.journey", "--checkpoint-out", checkpoint],
               cd: @project_root,
               stderr_to_stdout: true,
               env: workspace_runner_env()
             )

    payload = decode!(checkpoint)
    webhook = checkpoint_for_stage(payload, "webhook_ingest")
    operator = checkpoint_for_stage(payload, "operator_troubleshooting")

    assert webhook["status"] == "completed"
    assert webhook["fixture_id"] == "trust.webhook_ingest.001"
    assert webhook["evidence"] == TrustRunnerFixtures.webhook_ingest_evidence()

    assert webhook["evidence"]["negative_reason"] == "bad_credentials"
    assert webhook["evidence"]["verified_before_tenant"] == true
    assert operator["evidence"]["scenario"] == "no_match"
    assert operator["evidence"]["raw_payload_included"] == false
  end

  test "checkpoint validator rejects malformed Phase 58 evidence" do
    checkpoint_dir = Path.join(@project_root, "tmp/mailglass_trust_runner")
    valid_checkpoint = Path.join(checkpoint_dir, "phase58-plan02-validator-valid.json")
    invalid_checkpoint = Path.join(checkpoint_dir, "phase58-plan02-validator-invalid.json")

    File.rm_rf!(checkpoint_dir)
    File.mkdir_p!(checkpoint_dir)

    assert {_, 0} =
             System.cmd(
               "mix",
               ["verify.reference_host.journey", "--checkpoint-out", valid_checkpoint],
               cd: @project_root,
               stderr_to_stdout: true,
               env: workspace_runner_env()
             )

    payload =
      valid_checkpoint
      |> decode!()
      |> update_in(["checkpoints"], fn rows ->
        Enum.map(rows, fn
          %{"stage" => "operator_troubleshooting"} = row ->
            put_in(row, ["evidence", "raw_payload"], "must be rejected")

          row ->
            row
        end)
      end)

    File.write!(invalid_checkpoint, Jason.encode_to_iodata!(payload, pretty: true))

    assert {_, 0} =
             System.cmd(
               "bash",
               ["scripts/check_trust_runner_checkpoint.sh", "--checkpoint", valid_checkpoint],
               cd: @project_root,
               stderr_to_stdout: true
             )

    assert {output, exit_code} =
             System.cmd(
               "bash",
               ["scripts/check_trust_runner_checkpoint.sh", "--checkpoint", invalid_checkpoint],
               cd: @project_root,
               stderr_to_stdout: true
             )

    assert exit_code != 0
    assert output =~ "forbidden evidence key"
  end

  test "REL-01 generated-host evidence closes every package boundary in exact order" do
    source = File.read!(@generated_host_script_path)

    expected = [
      "fresh_install",
      "sync_send",
      "atomic_enqueue",
      "worker_run",
      "persisted_outcome",
      "custom_modules",
      "multi_repo_prefixes",
      "upgrade",
      "rollback",
      "idempotent_rerun"
    ]

    Enum.each(expected, fn stage ->
      assert source =~ stage, "generated-host proof is missing ordered stage #{stage}"
    end)

    assert source =~ "validate_checkpoint_file"
    assert source =~ "core_first inbound_first"
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

  defp expected_row_hash(rows) do
    rows
    |> Enum.map(fn row -> "#{row["stage"]}|#{row["status"]}|#{row["fixture_id"]}" end)
    |> Enum.join("\n")
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp workspace_runner_env do
    [
      {"MIX_ENV", "test"},
      {"MAILGLASS_REFERENCE_HOST_PACKAGE_MODE", "workspace"},
      {"MAILGLASS_CORE_WORKSPACE_EBIN", @workspace_core_ebin},
      {"MAILGLASS_INBOUND_WORKSPACE_EBIN", @workspace_inbound_ebin}
    ]
  end
end
