defmodule Mailglass.Scripts.BranchProtectionTruthTest do
  use ExUnit.Case, async: true

  @ci_path Path.expand("../../.github/workflows/ci.yml", __DIR__)

  test "Branch Protection Advisory reports a closed, fail-loud verification outcome" do
    source = File.read!(@ci_path)
    job = extract_job_block(source, "branch_protection_advisory")
    verify = extract_step_block(job, "Verify branch protection")
    report = extract_step_block(job, "Report branch protection outcome")

    assert job != "", "branch_protection_advisory job parser returned an empty block"
    assert verify != "", "Verify branch protection step parser returned an empty block"
    assert report != "", "Report branch protection outcome step parser returned an empty block"

    assert verify =~ "./scripts/verify-branch-protection.sh main"
    assert verify =~ "continue-on-error: true"
    assert verify =~ "classification=clean"
    assert verify =~ "classification=drift"
    assert verify =~ "classification=cannot_check"
    assert report =~ "if: always()"
    assert report =~ "clean"
    assert report =~ "drift"
    assert report =~ "cannot_check"
    assert report =~ "exit 1"
    assert report =~ "exit 0"
  end

  test "Branch Protection Advisory remains publish-gating and outside CI Green" do
    ci_source = File.read!(@ci_path)
    job = extract_job_block(ci_source, "ci_green")

    assert job != "", "ci_green job parser returned an empty block"
    refute job =~ "branch_protection_advisory"
    assert "Branch Protection Advisory" in Mailglass.CILanes.publish_gating_lanes()
  end

  defp extract_job_block(source, job_key) do
    marker = "  #{job_key}:\n"

    case String.split(source, marker, parts: 2) do
      [_, rest] ->
        rest
        |> String.split(~r/\n  [a-z_][a-z_-]*:\n/, parts: 2)
        |> hd()
        |> then(&(marker <> &1))

      _ ->
        ""
    end
  end

  defp extract_step_block(job_block, step_name) do
    marker = "      - name: #{step_name}\n"

    case String.split(job_block, marker, parts: 2) do
      [_, rest] ->
        rest
        |> String.split("\n      - name:", parts: 2)
        |> hd()
        |> then(&(marker <> &1))

      _ ->
        ""
    end
  end

end
