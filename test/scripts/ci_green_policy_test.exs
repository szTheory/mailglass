defmodule Mailglass.Scripts.CIGreenPolicyTest do
  use ExUnit.Case, async: true

  @policy_path Path.expand("../../scripts/ci_green_policy.sh", __DIR__)

  test "detector failure blocks CI Green regardless of required leaf results" do
    assert {output, 1} = run_policy(["failure", "false", "hex_audit=skipped"])

    assert output =~ "CI Green blocked: change detector result must be success (got failure)"
  end

  test "code changes require every required leaf to succeed exactly" do
    assert {"", 0} = run_policy(["success", "true", "hex_audit=success", "deps_audit=success"])

    assert {output, 1} = run_policy(["success", "true", "hex_audit=skipped"])

    assert output =~ "CI Green blocked: unacceptable required lane result(s): hex_audit=skipped"
  end

  test "missing, unknown, failed, and cancelled code-lane results block CI Green" do
    assert {output, 1} =
             run_policy([
               "success",
               "true",
               "hex_audit=",
               "deps_audit=unknown",
               "compile=failure",
               "install=cancelled"
             ])

    assert output =~ "hex_audit=(missing)"
    assert output =~ "deps_audit=unknown"
    assert output =~ "compile=failure"
    assert output =~ "install=cancelled"
  end

  test "missing, empty, and non-boolean code classifications block CI Green" do
    for code <- ["", "false ", "unknown"] do
      assert {output, 1} = run_policy(["success", code, "hex_audit=success"])
      assert output =~ "CI Green blocked: change detector code output must be exactly true or false"
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

  defp run_policy(arguments) do
    System.cmd("bash", [@policy_path | arguments], stderr_to_stdout: true)
  end
end
