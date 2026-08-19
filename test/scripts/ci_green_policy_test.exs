defmodule Mailglass.Scripts.CIGreenPolicyTest do
  use ExUnit.Case, async: true

  @policy_path Path.expand("../../scripts/ci_green_policy.sh", __DIR__)
  @ci_yml_path Path.expand("../../.github/workflows/ci.yml", __DIR__)

  test "detector failure blocks CI Green regardless of required leaf results" do
    assert {output, 1} = run_policy(["failure", "false", "hex_audit=skipped"])

    assert output =~ "CI Green blocked: change detector result must be success (got failure)"
  end

  test "code changes require every required leaf to succeed exactly" do
    assert {"", 0} = run_policy(policy_arguments(active_results()))

    assert {output, 1} = run_policy(policy_arguments(active_results(%{"hex_audit" => "skipped"})))

    assert output =~ "CI Green blocked: unacceptable required lane result(s): hex_audit=skipped"
  end

  test "missing, unknown, failed, and cancelled code-lane results block CI Green" do
    assert {output, 1} =
             run_policy(
               policy_arguments(
                 active_results(%{
                   "hex_audit" => "",
                   "deps_audit_advisory" => "unknown",
                   "compile_no_optional_deps" => "failure",
                   "installer_host_smoke" => "cancelled"
                 })
               )
             )

    assert output =~ "hex_audit=(missing)"
    assert output =~ "deps_audit_advisory=unknown"
    assert output =~ "compile_no_optional_deps=failure"
    assert output =~ "installer_host_smoke=cancelled"
  end

  test "missing, empty, and non-boolean code classifications block CI Green" do
    for code <- ["", "false ", "unknown"] do
      assert {output, 1} = run_policy(["success", code | active_results()])
      assert output =~ "CI Green blocked: change detector code output must be exactly true or false"
    end
  end

  test "only a successful docs-only classification permits skipped required leaves" do
    assert {"", 0} = run_policy(["success", "false" | active_results(%{"hex_audit" => "skipped"})])

    assert {output, 1} =
             run_policy(["success", "false" | active_results(%{"hex_audit" => "failure"})])

    assert output =~ "CI Green blocked: unacceptable required lane result(s): hex_audit=failure"
  end

  test "push change detection fails closed when git diff cannot establish the changed files" do
    source = File.read!(@ci_yml_path)

    assert_push_diff_failure_blocks!(source)

    assert_raise ExUnit.AssertionError, fn ->
      assert_push_diff_failure_blocks!(
        String.replace(
          source,
          "git diff --name-only \"${BEFORE}\" \"${AFTER}\"",
          "false",
          global: false
        )
      )
    end
  end

  test "malformed, duplicate, and empty required leaf inputs block CI Green" do
    assert {malformed_output, 1} = run_policy(["success", "true", "not-a-pair"])
    assert malformed_output =~ "CI Green blocked: malformed required lane input: not-a-pair"

    assert {duplicate_output, 1} =
             run_policy(["success", "true", "hex_audit=success", "hex_audit=success"])

    assert duplicate_output =~ "CI Green blocked: duplicate required lane input: hex_audit"

    assert {empty_output, 1} = run_policy(["success", "true"])
    assert empty_output =~ "CI Green blocked: no required lane results were supplied"
  end

  test "unknown and advisory lane identities cannot be supplied as required evidence" do
    assert {unknown_output, 1} =
             run_policy(["success", "true", "unknown_lane=success"])

    assert unknown_output =~ "CI Green blocked: unknown required lane input: unknown_lane"

    assert {advisory_output, 1} =
             run_policy(["success", "true", "operator_browser_gate=success"])

    assert advisory_output =~
             "CI Green blocked: advisory lane cannot be supplied as required evidence: operator_browser_gate"
  end

  defp run_policy(arguments) do
    System.cmd("bash", [@policy_path | arguments], stderr_to_stdout: true)
  end

  defp active_results(overrides \\ %{}) do
    active_lanes =
      Mailglass.CIPolicy.load!()
      |> Mailglass.CIPolicy.active_required_ids()
      |> MapSet.to_list()

    Enum.map(active_lanes, fn lane -> "#{lane}=#{Map.get(overrides, lane, "success")}" end)
  end

  defp policy_arguments(results), do: ["success", "true" | results]

  defp assert_push_diff_failure_blocks!(source) do
    [_before_push, push_branch] =
      String.split(source, "# push event: compare against the before SHA", parts: 2)

    assert push_branch =~
             "if ! CHANGED=$(git diff --name-only \"${BEFORE}\" \"${AFTER}\" 2>/dev/null); then"

    assert push_branch =~ "Unable to determine changed files for push"
    assert push_branch =~ "exit 1"
    refute push_branch =~ "git diff --name-only \"${BEFORE}\" \"${AFTER}\" 2>/dev/null || true"
  end
end
