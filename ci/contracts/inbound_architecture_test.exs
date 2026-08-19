defmodule Mailglass.InboundArchitectureCheck do
  @moduledoc """
  Opt-in cross-package architecture proof.

  This file lives outside the default `test/` load path, so ordinary core and
  CI-meta suites do not require the sibling package's dependencies. The
  required Support Contract Core lane provisions those locked dependencies
  and executes this check explicitly.
  """

  use ExUnit.Case, async: false

  @moduletag timeout: 180_000

  test "the inbound compile-connected graph is cycle-free" do
    project_root = Path.join(File.cwd!(), "mailglass_inbound")

    {output, status} =
      System.cmd("mix", ["xref", "graph", "--format", "cycles", "--label", "compile-connected"],
        cd: project_root,
        stderr_to_stdout: true
      )

    assert status == 0,
           "xref cycle command failed in #{project_root}:\n#{output}"

    assert cycle_free?(output),
           "xref reported a compile-connected cycle or unparseable output in #{project_root}:\n#{output}"
  end

  defp cycle_free?(output) do
    Regex.match?(~r/^No cycles found\s*$/m, output) and
      not Regex.match?(~r/\b[1-9]\d* cycles found\b/, output)
  end
end
