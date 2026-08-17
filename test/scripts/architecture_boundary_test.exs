defmodule Mailglass.ArchitectureBoundaryTest do
  use ExUnit.Case, async: false

  @core_source_glob "lib/mailglass/**/*.ex"

  test "the core production tree has no reverse dependency on inbound" do
    core_sources =
      @core_source_glob
      |> Path.wildcard()
      |> Enum.map(fn path -> {path, File.read!(path)} end)

    assert forbidden_package_references(:core, core_sources) == []

    assert forbidden_package_references(:core, [
             {"fixture.ex", "defmodule Fixture do\n  use MailglassInbound.Router\nend"}
           ]) == ["fixture.ex"]

    assert forbidden_package_references(:inbound, [
             {"fixture.ex", "defmodule Fixture do\n  Mailglass.Config.schema()\nend"}
           ]) == []
  end

  test "the compile-cycle parser fails closed and rejects a synthetic SCC" do
    assert cycle_free?("No cycles found\n")
    refute cycle_free?("1 cycles found:\nlib/a.ex\nlib/b.ex\n")
    refute cycle_free?("unexpected xref output")
  end

  test "core and inbound compile-connected graphs are cycle-free" do
    assert_cycle_free!(File.cwd!())
    assert_cycle_free!(Path.join(File.cwd!(), "mailglass_inbound"))
  end

  defp assert_cycle_free!(project_root) do
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

  defp forbidden_package_references(:core, sources) do
    for {path, source} <- sources,
        source =~ ~r/\b(?:alias|import|require|use)\s+MailglassInbound\b/ or
          source =~ ~r/\bMailglassInbound\.[A-Z]\w*\s*\(/,
        do: path
  end

  defp forbidden_package_references(:inbound, _sources), do: []

  defp cycle_free?(output) when is_binary(output) do
    Regex.match?(~r/^No cycles found\s*$/m, output) and
      not Regex.match?(~r/\b[1-9]\d* cycles found\b/, output)
  end

  defp cycle_free?(_), do: false
end
