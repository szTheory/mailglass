defmodule Mailglass.Scripts.ConformanceAdvisoryTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @script_path Path.join(@repo_root, "mailglass_admin/scripts/check-conformance-advisory.sh")
  @ci_path Path.join(@repo_root, ".github/workflows/ci.yml")

  test "advisory conformance script fails closed on large type and arbitrary tracking" do
    tmp = Path.join(System.tmp_dir!(), "mailglass-advisory-#{System.unique_integer([:positive])}")
    script_dir = Path.join(tmp, "scripts")
    lib_dir = Path.join(tmp, "lib")
    on_exit(fn -> File.rm_rf!(tmp) end)

    File.mkdir_p!(script_dir)
    File.mkdir_p!(lib_dir)
    File.cp!(@script_path, Path.join(script_dir, "check-conformance-advisory.sh"))

    File.write!(Path.join(lib_dir, "violation.ex"), """
    defmodule Violation do
      def render, do: ~H\"\"\"
      <h2 class="text-xl tracking-[0.08em]">Bad</h2>
      \"\"\"
    end
    """)

    {output, status} =
      System.cmd("bash", [Path.join(script_dir, "check-conformance-advisory.sh")],
        stderr_to_stdout: true
      )

    assert status == 1
    assert output =~ "FAIL: TYPE-GATE"
    assert output =~ "FAIL: TRACK-GATE"
    assert output =~ "FAIL: advisory design-system conformance violations found (2 gate(s) failed)"
  end

  test "advisory conformance script exits clean with no violations" do
    tmp =
      Path.join(System.tmp_dir!(), "mailglass-advisory-clean-#{System.unique_integer([:positive])}")

    script_dir = Path.join(tmp, "scripts")
    lib_dir = Path.join(tmp, "lib")
    on_exit(fn -> File.rm_rf!(tmp) end)

    File.mkdir_p!(script_dir)
    File.mkdir_p!(lib_dir)
    File.cp!(@script_path, Path.join(script_dir, "check-conformance-advisory.sh"))

    File.write!(Path.join(lib_dir, "clean.ex"), """
    defmodule Clean do
      def render, do: ~H\"\"\"
      <h2 class="text-heading font-bold text-base-content tracking-tight">Good</h2>
      \"\"\"
    end
    """)

    {output, status} =
      System.cmd("bash", [Path.join(script_dir, "check-conformance-advisory.sh")],
        stderr_to_stdout: true
      )

    assert status == 0
    assert output =~ "OK: advisory design-system conformance clean."
  end

  test "CI advisory conformance step is halt-on-failure" do
    ci = File.read!(@ci_path)
    step = advisory_step_block(ci)

    assert step =~ "run: bash mailglass_admin/scripts/check-conformance-advisory.sh"
    refute step =~ "continue-on-error: true"
  end

  defp advisory_step_block(ci) do
    marker = "- name: Verify design-system conformance (advisory arms"
    [_before, rest] = String.split(ci, marker, parts: 2)
    [step | _] = String.split(rest, "\n      - name:", parts: 2)
    marker <> step
  end
end
