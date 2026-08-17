defmodule Mailglass.ArchitectureBoundaryTest do
  use ExUnit.Case, async: false

  @core_source_glob "lib/mailglass/**/*.ex"

  test "the core production tree has no reverse dependency on inbound" do
    core_sources =
      @core_source_glob
      |> Path.wildcard()
      |> Enum.map(fn path -> {path, File.read!(path)} end)

    assert remote_reference_violations(core_sources, :MailglassInbound, %{}) == []

    assert remote_reference_violations(
             [
               {"fixture.ex", "defmodule Fixture do\n  MailglassInbound.Router.call(conn, [])\nend"}
             ],
             :MailglassInbound,
             %{}
           ) == [{"fixture.ex", "MailglassInbound.Router"}]
  end

  test "the core safe broadcast capability has one owner" do
    pub_sub = File.read!("lib/mailglass/pub_sub.ex")
    projector = File.read!("lib/mailglass/outbound/projector.ex")

    assert pub_sub =~ "def safe_broadcast(topic, payload)"
    assert projector =~ "Mailglass.Ports.PubSub.safe_broadcast"
    refute projector =~ "defp safe_broadcast"
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

  test "a required core support lane executes the architecture contract without swallowing failure" do
    ci = File.read!(".github/workflows/ci.yml")

    assert_required_architecture_gate!(ci)

    without_gate =
      String.replace(
        ci,
        "mix test test/scripts/architecture_boundary_test.exs --warnings-as-errors",
        "true", global: false)

    assert_raise ExUnit.AssertionError, fn -> assert_required_architecture_gate!(without_gate) end
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

  defp remote_reference_violations(sources, root, allowed_references_by_path) do
    for {path, source} <- sources,
        reference <- remote_references(source, root),
        reference not in Map.get(allowed_references_by_path, path, MapSet.new()),
        do: {path, reference}
  end

  defp remote_references(source, root) do
    {:ok, ast} = Code.string_to_quoted(source)

    {_ast, references} =
      Macro.prewalk(ast, MapSet.new(), fn
        {:__aliases__, _, [head | rest]} = node, refs when head == root ->
          reference = Enum.join([Atom.to_string(root) | Enum.map(rest, &Atom.to_string/1)], ".")
          {node, MapSet.put(refs, reference)}

        node, refs ->
          {node, refs}
      end)

    Enum.sort(references)
  end

  defp cycle_free?(output) when is_binary(output) do
    Regex.match?(~r/^No cycles found\s*$/m, output) and
      not Regex.match?(~r/\b[1-9]\d* cycles found\b/, output)
  end

  defp cycle_free?(_), do: false

  defp assert_required_architecture_gate!(ci) do
    support_contract =
      case String.split(ci, "  support_contract_core:\n", parts: 2) do
        [_, rest] -> rest |> String.split(~r/\n  [a-z_][a-z_-]*:\n/, parts: 2) |> hd()
        _ -> flunk("support_contract_core job is missing")
      end

    assert support_contract =~ "name: Support Contract Core (Elixir 1.18 / OTP 27)"

    assert support_contract =~
             "mix test test/scripts/architecture_boundary_test.exs --warnings-as-errors"
  end
end
