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
    assert job =~ "MAILGLASS_REFERENCE_HOST_PACKAGE_MODE: published_siblings"
    assert job =~ "run: mix verify.reference_host.journey --host-root reference/host_app"
    assert job =~ "run: bash scripts/check_trust_runner_checkpoint.sh"
    assert job =~ "name: trust-runner-clean-baseline-${{ github.run_id }}"
    assert job =~ "if-no-files-found: error"
    assert job =~ "retention-days: 90"
    assert job =~ "path: tmp/mailglass_trust_runner/checkpoint.json"
    refute job =~ "MAILGLASS_CORE_WORKSPACE_EBIN"
    refute job =~ "MAILGLASS_INBOUND_WORKSPACE_EBIN"

    # Phase 126 (M1 CI/CD efficiency, commit db8761527) intentionally gated EVERY
    # lane — including this one — on the `changes` job so docs-only PRs skip the
    # expensive trust journey. That is compatible with the publish gate: a real
    # release PR always carries a code change (version bumps), so `code == 'true'`
    # and the lane RUNS and gates. On a docs-only PR the lane is `skipped`, and
    # the publish gate's `blockingFailures` filter excludes `skipped` jobs —
    # so a skip never permits an unverified release. The load-bearing contract is
    # NOT "always run" but "publish-gate-only": this lane must NOT be a required
    # branch-protection check and must NOT be in ci_green.needs, so a red baseline
    # never masquerades as a required-green while still blocking publish when run.
    assert job =~ "needs: [changes]"
    assert job =~ "if: needs.changes.outputs.code == 'true'"

    # Publish-gate-only guarantee: not wired into the ci_green aggregate.
    refute ci_green_needs(workflow) =~ "trust_lane_clean_baseline"
  end

  test "clean-baseline guard rejects a sibling resolved via a non-Hex source" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "mailglass-clean-baseline-#{System.unique_integer([:positive])}")

    non_hex_lock_path = Path.join(tmp_dir, "mix.lock")

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    File.mkdir_p!(tmp_dir)

    # Flip the mailglass source atom :hex -> :git to simulate a non-published
    # (path/git) sibling sneaking into the baseline. Version-agnostic on purpose:
    # the guard enforces the Hex source, not a frozen version literal.
    non_hex_lock =
      @reference_lock_path
      |> File.read!()
      |> String.replace(
        ~s("mailglass": {:hex,),
        ~s("mailglass": {:git,),
        global: false
      )

    File.write!(non_hex_lock_path, non_hex_lock)

    {output, status} =
      System.cmd("bash", [@guard_script_path, non_hex_lock_path], stderr_to_stdout: true)

    assert status == 1
    assert output =~ "Hex-first violation: mailglass resolved via :git, expected :hex"
  end

  test "clean-baseline guard reports malformed sibling lock tuples" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "mailglass-clean-baseline-#{System.unique_integer([:positive])}")

    malformed_lock_path = Path.join(tmp_dir, "mix.lock")

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    File.mkdir_p!(tmp_dir)

    malformed_lock =
      @reference_lock_path
      |> File.read!()
      |> String.replace(
        ~r/"mailglass": \{:hex, :mailglass, "[^"]+".*/,
        ~s("mailglass": {:hex},),
        global: false
      )

    File.write!(malformed_lock_path, malformed_lock)

    {output, status} =
      System.cmd("bash", [@guard_script_path, malformed_lock_path], stderr_to_stdout: true)

    assert status == 1
    assert output =~ "Hex-first violation: mailglass lock tuple malformed"
  end

  test "clean-baseline guard parses lock literals without evaluating code" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "mailglass-clean-baseline-#{System.unique_integer([:positive])}")

    malicious_lock_path = Path.join(tmp_dir, "mix.lock")
    marker_path = Path.join(tmp_dir, "evaluated")

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    File.mkdir_p!(tmp_dir)

    malicious_lock = """
    %{
      "mailglass": (File.write!(#{inspect(marker_path)}, "executed"); {:hex, :mailglass, "1.4.5"}),
      "mailglass_admin": {:hex, :mailglass_admin, "1.4.5"},
      "mailglass_inbound": {:hex, :mailglass_inbound, "1.1.5"}
    }
    """

    File.write!(malicious_lock_path, malicious_lock)

    {output, status} =
      System.cmd("bash", [@guard_script_path, malicious_lock_path], stderr_to_stdout: true)

    assert status == 1
    refute File.exists?(marker_path)
    assert output =~ "Clean-baseline Hex-first check blocked: invalid"
    assert output =~ "unsupported lock literal"
  end

  test "clean-baseline guard reports non-tuple sibling lock entries" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "mailglass-clean-baseline-#{System.unique_integer([:positive])}")

    invalid_lock_path = Path.join(tmp_dir, "mix.lock")

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    File.mkdir_p!(tmp_dir)

    invalid_lock =
      @reference_lock_path
      |> File.read!()
      |> String.replace(
        ~r/"mailglass": \{:hex, :mailglass, "[^"]+".*/,
        ~s("mailglass": "bad",),
        global: false
      )

    File.write!(invalid_lock_path, invalid_lock)

    {output, status} =
      System.cmd("bash", [@guard_script_path, invalid_lock_path], stderr_to_stdout: true)

    assert status == 1
    assert output =~ ~s(Hex-first violation: mailglass lock entry has invalid type: "bad")
  end

  defp extract_job!(workflow, start_key, next_key) do
    [_before, rest] = String.split(workflow, "\n  #{start_key}:\n", parts: 2)
    [job | _after] = String.split(rest, "\n  #{next_key}:\n", parts: 2)
    job
  end

  # The ci_green aggregate job block — the load-bearing "publish-gate-only"
  # contract asserts trust_lane_clean_baseline is NOT a required leaf, so it must
  # not appear in ci_green.needs. ci_green is the final job in ci.yml, so the
  # block runs to end-of-file.
  defp ci_green_needs(workflow) do
    [_before, ci_green] = String.split(workflow, "\n  ci_green:\n", parts: 2)
    ci_green
  end
end
