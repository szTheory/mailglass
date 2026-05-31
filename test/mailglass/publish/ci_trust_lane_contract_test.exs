defmodule Mailglass.Publish.CITrustLaneContractTest do
  use ExUnit.Case, async: true

  @workflow_path Path.expand("../../../.github/workflows/ci.yml", __DIR__)
  @guard_script_path Path.expand("../../../scripts/check_clean_baseline_hex_only.sh", __DIR__)
  @reference_lock_path Path.expand("../../../reference/host_app/mix.lock", __DIR__)

  test "clean-baseline trust lane remains publish-gate-only and verifies Hex-sourced host" do
    workflow = File.read!(@workflow_path)
    job = extract_job!(workflow, "trust_lane_clean_baseline", "branch_protection_advisory")

    assert job =~ "name: Trust Lane Clean Baseline (Elixir 1.18 / OTP 27)"
    assert job =~ "working-directory: reference/host_app"
    assert job =~ "run: bash ../../scripts/check_clean_baseline_hex_only.sh"
    assert job =~ "run: mix verify.reference_host.journey --host-root reference/host_app"
    assert job =~ "run: bash scripts/check_trust_runner_checkpoint.sh"
    assert job =~ "name: trust-runner-clean-baseline-${{ github.run_id }}"
    assert job =~ "if-no-files-found: error"
    assert job =~ "retention-days: 90"
    assert job =~ "path: tmp/mailglass_trust_runner/checkpoint.json"

    refute job =~ ~r/^    if:/m
    refute job =~ ~r/^    needs:/m
  end

  test "clean-baseline guard rejects stale Hex-sourced sibling versions" do
    tmp_dir = Path.join(System.tmp_dir!(), "mailglass-clean-baseline-#{System.unique_integer([:positive])}")
    stale_lock_path = Path.join(tmp_dir, "mix.lock")

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    File.mkdir_p!(tmp_dir)

    stale_lock =
      @reference_lock_path
      |> File.read!()
      |> String.replace(
        ~s("mailglass": {:hex, :mailglass, "1.3.0"),
        ~s("mailglass": {:hex, :mailglass, "1.2.0"),
        global: false
      )

    File.write!(stale_lock_path, stale_lock)

    {output, status} = System.cmd("bash", [@guard_script_path, stale_lock_path], stderr_to_stdout: true)

    assert status == 1
    assert output =~ "Hex-first violation: mailglass expected 1.3.0, got 1.2.0"
  end

  defp extract_job!(workflow, start_key, next_key) do
    [_before, rest] = String.split(workflow, "\n  #{start_key}:\n", parts: 2)
    [job | _after] = String.split(rest, "\n  #{next_key}:\n", parts: 2)
    job
  end
end
