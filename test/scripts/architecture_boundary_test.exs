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

    for mutation <- [
          {"removed command", "true"},
          {"shell-swallowed command",
           "mix test test/scripts/architecture_boundary_test.exs --warnings-as-errors || true"},
          {"step continue-on-error",
           "continue-on-error: true\n        run: mix test test/scripts/architecture_boundary_test.exs --warnings-as-errors"}
        ] do
      {_label, replacement} = mutation

      mutated =
        String.replace(
          ci,
          "run: mix test test/scripts/architecture_boundary_test.exs --warnings-as-errors",
          replacement,
          global: false
        )

      assert_raise ExUnit.AssertionError, fn -> assert_required_architecture_gate!(mutated) end
    end

    support_contract = job!(ci, "support_contract_core")

    skipped_job =
      String.replace(support_contract, "if: needs.changes.outputs.code == 'true'", "if: false")

    skipped_ci = String.replace(ci, support_contract, skipped_job)

    assert_raise ExUnit.AssertionError, fn -> assert_required_architecture_gate!(skipped_ci) end
  end

  test "the Phase 158 commit manifest excludes forbidden scope categories" do
    changes = phase_changes!()

    assert changes != []
    assert scope_violations(changes) == []

    assert scope_violations([
             {:added, "mailglass_admin/lib/mailglass_admin/operator/live.ex"},
             {:added, "priv/repo/migrations/20260817000000_expand_provider.exs"},
             {:added, "lib/mailglass/webhook/providers/new_provider.ex"},
             {:modified, "mailglass_admin/mix.exs"}
           ]) == [
             {:added, "mailglass_admin/lib/mailglass_admin/operator/live.ex",
              :admin_or_operator_ui},
             {:added, "priv/repo/migrations/20260817000000_expand_provider.exs", :migration},
             {:added, "lib/mailglass/webhook/providers/new_provider.ex", :provider_expansion},
             {:modified, "mailglass_admin/mix.exs", :package_collapse}
           ]
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
    support_contract = job!(ci, "support_contract_core")

    assert support_contract =~ "name: Support Contract Core (Elixir 1.18 / OTP 27)"
    assert support_contract =~ "if: needs.changes.outputs.code == 'true'"

    step = step!(support_contract, "Run architecture boundary contract")

    assert step =~ "run: mix test test/scripts/architecture_boundary_test.exs --warnings-as-errors"
    refute step =~ "continue-on-error:"
    refute step =~ "if:"
    refute step =~ ~r/\|\|\s*(true|:)\b/
    refute step =~ ~r/;\s*true\b/
  end

  defp job!(ci, name) do
    case String.split(ci, "  #{name}:\n", parts: 2) do
      [_, rest] -> rest |> String.split(~r/\n  [a-z_][a-z_-]*:\n/, parts: 2) |> hd()
      _ -> flunk("#{name} job is missing")
    end
  end

  defp step!(job, name) do
    case Regex.run(
           ~r/^      - name: #{Regex.escape(name)}\n(?<body>.*?)(?=^      - name:|\z)/ms,
           job
         ) do
      [_, body] -> body
      _ -> flunk("#{name} step is missing")
    end
  end

  defp phase_changes! do
    phase_commits = git!("log", ["--all", "--format=%H", "--fixed-strings", "--grep=(158"])

    phase_commits
    |> String.split("\n", trim: true)
    |> Enum.flat_map(fn commit ->
      git!("show", [commit, "--format=", "--name-status", "--find-renames"])
      |> String.split("\n", trim: true)
      |> Enum.map(&parse_change!/1)
    end)
  end

  defp parse_change!(line) do
    case String.split(line, "\t") do
      [status, path] -> {status_kind(status), path}
      [status, _from, path] -> {status_kind(status), path}
      _ -> flunk("unparseable git name-status line: #{inspect(line)}")
    end
  end

  defp status_kind("A" <> _rest), do: :added
  defp status_kind("M" <> _rest), do: :modified
  defp status_kind("R" <> _rest), do: :renamed
  defp status_kind(other), do: String.to_atom(other)

  defp scope_violations(changes) do
    for {status, path} <- changes,
        reason <- scope_reason(status, path),
        do: {status, path, reason}
  end

  defp scope_reason(status, path) do
    cond do
      path == "mailglass_admin/mix.exs" -> [:package_collapse]
      String.starts_with?(path, "mailglass_admin/") -> [:admin_or_operator_ui]
      Regex.match?(~r{(?:^|/)migrations/.+\.exs$}, path) -> [:migration]
      status == :added and Regex.match?(~r{(?:^|/)providers/}, path) -> [:provider_expansion]
      true -> []
    end
  end

  defp git!(command, args) do
    {output, status} = System.cmd("git", [command | args], stderr_to_stdout: true)
    assert status == 0, "git #{command} failed:\n#{output}"
    output
  end
end
