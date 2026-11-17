defmodule MailglassAdmin.BrandV2CompatPolicyTest do
  @moduledoc """
  Reads the machine-readable table in `docs/brand-v2-compatibility.md` and
  proves every listed public name still exists in the code.

  The table is the only list: this test parses it and holds no second copy of
  the names. Removing a listed name from the code turns it red with a message
  that names the policy file. Adding names is always allowed.

  Checks, in order of what they protect:

    * subset: every listed name exists, verified by its kind (module, macro,
      function, enum, schema_field, topic or grep);
    * reverse: every `Mailglass.Operator.*` module has a module row, so a new
      Operator module forces a policy decision;
    * guards against a false green: the table must parse, must not be empty,
      must contain the required names and must not repeat a row;
    * the policy's own citations: every repo path it names must exist.

  The test only reads files and loaded modules and writes nothing, so it runs
  concurrently with the rest of the suite and shares no state.
  """

  use ExUnit.Case, async: true

  @policy_path Path.expand("../../../docs/brand-v2-compatibility.md", __DIR__)
  @repo_root Path.expand("../../..", __DIR__)
  @policy_rel "docs/brand-v2-compatibility.md"

  @tables %{
    "compat-table" => {["name", "kind", "package", "proof"], [:name, :kind, :package, :proof]},
    "gloss-table" =>
      {["public name", "on-screen word", "gloss"], [:public_name, :on_screen_word, :gloss]}
  }

  # Names the policy must always list. A row whose name equals or contains the
  # fragment satisfies it. Without this, an emptied or truncated table would
  # still verify "every row" and pass.
  @required_name_fragments [
    "Mailglass.Operator.",
    "mailglass_operator_routes",
    ":operator_access",
    "tenant_id",
    ":orphan_backlog",
    "[:mailglass, :webhook, :orphan, :stop]",
    "[:mailglass, :suppression, :pre_send_blocked, :stop]",
    "Mailglass.Outbound.Delivery.status"
  ]

  @tenant_id_proofs [
    "mailglass_admin/lib/mailglass_admin/router.ex",
    "mailglass_admin/lib/mailglass_admin/operator/mount.ex"
  ]

  @gloss_public_names ["Operator", "Tenant", "Deliveries", "orphan / unmatched"]

  # Repo paths the policy must keep citing, as inline code.
  @required_path_cites [
    "lib/mailglass/outbound/preflight.ex",
    "lib/mailglass/suppression.ex",
    "test/mailglass/outbound/suppressed_not_persisted_test.exs",
    "mailglass_admin/test/mailglass_admin/operator_trust_doc_test.exs",
    "test/mailglass/docs_contract_test.exs",
    "mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs",
    "mailglass_admin/test/mailglass_admin/stability_contract_test.exs"
  ]

  # Relative links to the stability inventories, resolved against docs/.
  @required_links [
    "api_stability.md",
    "../mailglass_admin/docs/api_stability.md",
    "../mailglass_inbound/docs/api_stability.md",
    "../guides/compatibility-and-deprecations.md"
  ]

  # -- parser -----------------------------------------------------------------

  # Cells are compared as exact binaries after trimming ASCII whitespace and one
  # pair of surrounding backticks. No case folding, no Unicode normalization.
  defp clean_cell(cell) do
    trimmed = String.replace(cell, ~r/\A[ \t\r\n]+|[ \t\r\n]+\z/, "")

    if byte_size(trimmed) >= 2 and String.starts_with?(trimmed, "`") and
         String.ends_with?(trimmed, "`") do
      binary_part(trimmed, 1, byte_size(trimmed) - 2)
    else
      trimmed
    end
  end

  defp split_cells(line) do
    line
    |> String.replace(~r/\A[ \t\r\n]+|[ \t\r\n]+\z/, "")
    |> String.replace_prefix("|", "")
    |> String.replace_suffix("|", "")
    |> String.split("|")
    |> Enum.map(&clean_cell/1)
  end

  defp region(lines, marker) do
    start_marker = "<!-- #{marker}:start -->"
    end_marker = "<!-- #{marker}:end -->"
    trimmed = Enum.map(lines, &String.trim/1)

    with start when is_integer(start) <- Enum.find_index(trimmed, &(&1 == start_marker)),
         rest = Enum.drop(trimmed, start + 1),
         stop when is_integer(stop) <- Enum.find_index(rest, &(&1 == end_marker)) do
      {:ok, Enum.take(rest, stop)}
    else
      nil -> {:error, :markers_missing}
    end
  end

  defp parse_table(markdown, marker) do
    {header, keys} = Map.fetch!(@tables, marker)

    with {:ok, region_lines} <- region(String.split(markdown, "\n"), marker),
         table_lines = Enum.reject(region_lines, &(&1 == "")),
         :ok <- reject_non_table_lines(table_lines),
         [header_line, separator_line | data_lines] when data_lines != [] <- table_lines,
         :ok <- check_header(split_cells(header_line), header),
         :ok <- check_separator(split_cells(separator_line)) do
      parse_rows(data_lines, keys)
    else
      lines when is_list(lines) -> {:error, :empty_table}
      {:error, _} = error -> error
    end
  end

  defp reject_non_table_lines(lines) do
    case Enum.find(lines, &(not String.starts_with?(&1, "|"))) do
      nil -> :ok
      line -> {:error, {:not_a_table_line, line}}
    end
  end

  defp check_header(cells, cells), do: :ok
  defp check_header(cells, _expected), do: {:error, {:header_mismatch, cells}}

  defp check_separator(cells) do
    if Enum.all?(cells, &Regex.match?(~r/\A:?-+:?\z/, &1)),
      do: :ok,
      else: {:error, {:separator_missing, cells}}
  end

  defp parse_rows(data_lines, keys) do
    Enum.reduce_while(data_lines, {:ok, []}, fn line, {:ok, acc} ->
      cells = split_cells(line)

      if length(cells) == length(keys) do
        {:cont, {:ok, [keys |> Enum.zip(cells) |> Map.new() | acc]}}
      else
        {:halt, {:error, {:malformed_row, line}}}
      end
    end)
    |> case do
      {:ok, rows} -> {:ok, Enum.reverse(rows)}
      error -> error
    end
  end

  defp policy_markdown!, do: File.read!(@policy_path)

  defp table_rows!(marker) do
    case parse_table(policy_markdown!(), marker) do
      {:ok, rows} ->
        rows

      {:error, reason} ->
        flunk(
          "#{@policy_rel} #{marker} could not be parsed (#{inspect(reason)}). " <>
            "Restore the #{marker}:start and #{marker}:end markers, the header row " <>
            "and at least one data row."
        )
    end
  end

  defp compat_rows!, do: table_rows!("compat-table")

  # -- verifier ---------------------------------------------------------------

  defp verify_row(%{kind: "module", name: name} = row) do
    if Code.ensure_loaded?(Module.concat([name])),
      do: :ok,
      else: {:error, row, "module #{name} is not loaded"}
  end

  defp verify_row(%{kind: kind, name: name} = row) when kind in ["macro", "function"] do
    with {:ok, mod, fun, arity} <- parse_mfa(name),
         true <- Code.ensure_loaded?(mod),
         {:ok, fun_atom} <- existing_atom(fun),
         true <- exported?(kind, mod, fun_atom, arity) do
      :ok
    else
      {:error, :bad_name} -> {:error, row, "#{kind} name must look like Module.name/arity"}
      _ -> {:error, row, "#{kind} #{name} is not exported"}
    end
  end

  defp verify_row(%{kind: "enum", name: name, proof: proof} = row) do
    with {:ok, live} <- enum_live_values(name, row),
         {:ok, listed} <- parse_atom_list(proof, row) do
      case listed -- live do
        [] ->
          :ok

        missing ->
          {:error, row,
           "#{inspect(missing)} are not live #{name} values (live values: #{inspect(live)})"}
      end
    end
  end

  defp verify_row(%{kind: "schema_field", name: name} = row) do
    case Regex.run(~r/\A(.+)\.([a-z_][A-Za-z0-9_]*)\z/, name) do
      [_, mod_name, field] ->
        mod = Module.concat([mod_name])

        fields =
          if Code.ensure_loaded?(mod) and function_exported?(mod, :__schema__, 1),
            do: Enum.map(mod.__schema__(:fields), &Atom.to_string/1),
            else: nil

        cond do
          is_nil(fields) -> {:error, row, "#{mod_name} is not an Ecto schema"}
          field in fields -> :ok
          true -> {:error, row, "#{field} is not a field of #{mod_name}"}
        end

      nil ->
        {:error, row, "schema_field name must look like Module.field"}
    end
  end

  defp verify_row(%{kind: "topic", name: name, proof: proof} = row) do
    with {:ok, mod, fun, 1} <- parse_mfa(proof),
         true <- Code.ensure_loaded?(mod),
         {:ok, fun_atom} <- existing_atom(fun),
         true <- function_exported?(mod, fun_atom, 1) do
      expected = String.replace(name, "\#{tenant_id}", "t1")
      actual = apply(mod, fun_atom, ["t1"])

      if actual == expected,
        do: :ok,
        else: {:error, row, "#{proof} returned #{inspect(actual)}, expected #{inspect(expected)}"}
    else
      _ -> {:error, row, "topic proof must name an exported Module.fun/1, got #{proof}"}
    end
  end

  defp verify_row(%{kind: "grep", name: name, proof: proof} = row) do
    with {:ok, rel} <- safe_relative(proof, row),
         {:ok, content} <- read_proof(rel, row) do
      if grep_proof_match?(rel, name, content),
        do: :ok,
        else: {:error, row, "#{name} not found in #{proof}"}
    end
  end

  defp verify_row(%{kind: kind} = row), do: {:error, row, "unknown kind #{inspect(kind)}"}

  defp parse_mfa(name) do
    case Regex.run(~r/\A(.+)\.([a-z_][A-Za-z0-9_]*[?!]?)\/(\d+)\z/, name) do
      [_, mod, fun, arity] -> {:ok, Module.concat([mod]), fun, String.to_integer(arity)}
      nil -> {:error, :bad_name}
    end
  end

  # A function that does not exist has no atom either, once its module is
  # loaded. Looking the atom up instead of creating it keeps a typo in the doc
  # from minting atoms, and the miss is reported as "not exported".
  defp existing_atom(string) do
    {:ok, String.to_existing_atom(string)}
  rescue
    ArgumentError -> {:error, :unknown_atom}
  end

  defp exported?("macro", mod, fun, arity), do: macro_exported?(mod, fun, arity)
  defp exported?("function", mod, fun, arity), do: function_exported?(mod, fun, arity)

  defp enum_live_values("Mailglass.Outbound.Delivery.status", _row),
    do: {:ok, Ecto.Enum.values(Mailglass.Outbound.Delivery, :status)}

  defp enum_live_values("Mailglass.Events.Event.type", _row),
    do: {:ok, Mailglass.Events.Event.__types__()}

  defp enum_live_values("Mailglass.Events.Event.reject_reason", _row),
    do: {:ok, Mailglass.Events.Event.__reject_reasons__()}

  defp enum_live_values(name, row),
    do: {:error, row, "no live-values source for enum #{name}"}

  defp parse_atom_list(proof, row) do
    case Code.string_to_quoted(proof) do
      {:ok, [_ | _] = list} ->
        if Enum.all?(list, &is_atom/1),
          do: {:ok, list},
          else: {:error, row, "enum proof must be a non-empty list of atoms"}

      _ ->
        {:error, row, "enum proof must be a non-empty list of atoms"}
    end
  end

  defp safe_relative(proof, row) do
    case Path.safe_relative(proof) do
      {:ok, rel} -> {:ok, rel}
      :error -> {:error, row, "proof path must be repo-relative, got #{proof}"}
    end
  end

  defp read_proof(rel, row) do
    case File.read(Path.join(@repo_root, rel)) do
      {:ok, content} -> {:ok, content}
      {:error, _} -> {:error, row, "proof file does not exist: #{rel}"}
    end
  end

  # An atom is accepted in either source form: `:atom` as a value or `atom:` as
  # a keyword key. Anything else is an exact substring.
  defp grep_patterns(":" <> atom = name), do: [name, atom <> ":"]
  defp grep_patterns(name), do: [name]

  defp grep_proof_match?(rel, name, content) do
    implementation =
      if Path.extname(rel) in [".ex", ".exs"] do
        Regex.replace(~r/@(?:moduledoc|doc)\s+""".*?"""/s, content, "")
      else
        content
      end

    Enum.any?(grep_patterns(name), &String.contains?(implementation, &1))
  end

  defp failures(rows) do
    rows
    |> Enum.map(&verify_row/1)
    |> Enum.reject(&(&1 == :ok))
    |> Enum.sort()
  end

  defp failure_message(failures) do
    lines =
      for {:error, row, reason} <- failures do
        "  - #{row.name} (#{row.kind}): #{reason}"
      end

    "#{@policy_rel} lists public names that the code no longer provides:\n" <>
      Enum.join(lines, "\n") <>
      "\nRestore the name for the branding change. Review row removal against the package's " <>
      "canonical stability inventory; stable adopter APIs need the deprecation process in " <>
      "guides/compatibility-and-deprecations.md and a major version."
  end

  # -- guards -----------------------------------------------------------------

  defp duplicates(rows) do
    rows
    |> Enum.frequencies_by(&{&1.name, &1.kind, &1.proof})
    |> Enum.filter(fn {_key, count} -> count > 1 end)
    |> Enum.map(&elem(&1, 0))
  end

  defp missing_required(rows) do
    Enum.reject(@required_name_fragments, fn fragment ->
      Enum.any?(rows, &String.contains?(&1.name, fragment))
    end)
  end

  defp operator_modules do
    (Application.spec(:mailglass, :modules) || [])
    |> Enum.map(&Atom.to_string/1)
    |> Enum.filter(&String.starts_with?(&1, "Elixir.Mailglass.Operator."))
    |> Enum.map(&String.replace_prefix(&1, "Elixir.", ""))
    |> Enum.sort()
  end

  defp unlisted_operator_modules(modules, rows) do
    listed = for %{kind: "module", name: name} <- rows, into: MapSet.new(), do: name
    Enum.reject(modules, &MapSet.member?(listed, &1))
  end

  # Repo paths the document cites: inline-code paths ending in .ex, .exs or .md
  # resolve against the repo root; relative markdown links resolve against docs/.
  defp cited_paths(markdown) do
    inline =
      ~r/`([^`\s]+\.(?:exs?|md))`/
      |> Regex.scan(markdown, capture: :all_but_first)
      |> List.flatten()
      |> Enum.map(&Path.expand(&1, @repo_root))

    linked =
      ~r/\]\(([^)\s#]+\.md)\)/
      |> Regex.scan(markdown, capture: :all_but_first)
      |> List.flatten()
      |> Enum.reject(&String.starts_with?(&1, "http"))
      |> Enum.map(&Path.expand(&1, Path.dirname(@policy_path)))

    Enum.uniq(inline ++ linked)
  end

  defp missing_cited_paths(markdown) do
    markdown
    |> cited_paths()
    |> Enum.reject(&File.regular?/1)
    |> Enum.map(&Path.relative_to(&1, @repo_root))
  end

  defp planted_row(kind, name, proof),
    do: %{name: name, kind: kind, package: "mailglass", proof: proof}

  defp bad_rows do
    [
      {planted_row("module", "Mailglass.Operator.DoesNotExist", "Code.ensure_loaded?"),
       "is not loaded"},
      {planted_row("macro", "MailglassAdmin.Router.no_such_macro/1", "macro_exported?"),
       "is not exported"},
      {planted_row(
         "macro",
         "MailglassAdmin.Router.mailglass_operator_routes/9",
         "macro_exported?"
       ), "is not exported"},
      {planted_row(
         "function",
         "Mailglass.Operator.SupportSummary.no_such_function/1",
         "function_exported?"
       ), "is not exported"},
      {planted_row("macro", "not a macro name", "macro_exported?"), "must look like"},
      {planted_row("enum", "Mailglass.Outbound.Delivery.status", "[:queued, :bogus]"),
       "are not live"},
      {planted_row("enum", "Mailglass.Outbound.Delivery.status", "queued"),
       "non-empty list of atoms"},
      {planted_row("enum", "Mailglass.Outbound.Delivery.not_an_enum", "[:queued]"),
       "no live-values source for enum"},
      {planted_row("schema_field", "Mailglass.Outbound.Delivery.no_such_field", "__schema__"),
       "is not a field of"},
      {planted_row("schema_field", "Mailglass.Operator.Timeline.tenant_id", "__schema__"),
       "is not an Ecto schema"},
      {planted_row(
         "topic",
         "mailglass:deliveries:\#{tenant_id}",
         "Mailglass.PubSub.Topics.no_such_topic/1"
       ), "topic proof must name an exported"},
      {planted_row(
         "topic",
         "mailglass:other:\#{tenant_id}",
         "Mailglass.PubSub.Topics.deliveries/1"
       ), "returned"},
      {planted_row("grep", ":operator_access", "lib/mailglass/suppression.ex"), "not found in"},
      {planted_row("grep", ":operator_access", "lib/does/not/exist.ex"),
       "proof file does not exist"},
      {planted_row("grep", ":operator_access", "../outside.ex"), "must be repo-relative"},
      {planted_row("bogus_kind", "anything", "anything"), "unknown kind"}
    ]
  end

  # -- the policy file --------------------------------------------------------

  describe "policy file" do
    test "lives at the repo-root docs directory" do
      assert Path.relative_to(@policy_path, @repo_root) == @policy_rel
      assert File.regular?(@policy_path)
    end

    test "states the gloss rule" do
      assert policy_markdown!() =~ "glossed, never renamed"
    end

    test "does not make compatibility-table membership an adopter stability promise" do
      markdown = policy_markdown!()

      assert markdown =~ "Table membership is a guard for this branding change"
      assert markdown =~ ~r/does not by itself\s+make a name part of the stable adopter API/
      assert markdown =~ "docs/api_stability.md"
    end

    test "keeps citing the Not sent proof, the pinned tests and the stability inventories" do
      markdown = policy_markdown!()

      for path <- @required_path_cites do
        assert markdown =~ "`#{path}`", "#{@policy_rel} no longer cites #{path}"
      end

      assert markdown =~ "Mailglass.Outbound.Persistence.build_failed_delivery/2"

      for link <- @required_links do
        assert markdown =~ "](#{link})", "#{@policy_rel} no longer links to #{link}"
      end
    end

    test "every repo path it cites exists" do
      markdown = policy_markdown!()

      assert length(cited_paths(markdown)) >= 15,
             "#{@policy_rel} cites too few paths; the citation scan may have stopped matching"

      assert missing_cited_paths(markdown) == [],
             "#{@policy_rel} cites paths that do not exist: " <>
               inspect(missing_cited_paths(markdown))
    end
  end

  describe "compat table" do
    test "parses to a non-empty list of rows" do
      assert [_ | _] = compat_rows!()
    end

    test "every row verifies against live code" do
      assert failures(compat_rows!()) == [], failure_message(failures(compat_rows!()))
    end

    test "Elixir grep proofs ignore documentation text and check implementation source" do
      rel = "mailglass_admin/lib/mailglass_admin/router.ex"
      docs_only = "@moduledoc \"\"\"\n  deliveries_path: []\n  \"\"\""
      implementation = "@navigation_opts_schema [deliveries_path: [type: :string]]"

      refute grep_proof_match?(rel, "deliveries_path", docs_only)
      assert grep_proof_match?(rel, "deliveries_path", implementation)
    end

    test "no row is repeated" do
      assert duplicates(compat_rows!()) == [],
             "#{@policy_rel} repeats rows with the same name, kind and proof: " <>
               inspect(duplicates(compat_rows!()))
    end

    test "contains every required name" do
      assert missing_required(compat_rows!()) == [],
             "#{@policy_rel} is missing required names: #{inspect(missing_required(compat_rows!()))}"
    end

    test "tenant_id is listed in every place it is public" do
      rows = compat_rows!()

      schema_fields =
        Enum.filter(
          rows,
          &(&1.kind == "schema_field" and String.ends_with?(&1.name, ".tenant_id"))
        )

      assert length(schema_fields) >= 3, "#{@policy_rel} must list tenant_id on each schema"

      for proof <- @tenant_id_proofs do
        assert Enum.any?(
                 rows,
                 &(&1.kind == "grep" and &1.name == "\"tenant_id\"" and &1.proof == proof)
               ),
               "#{@policy_rel} has no tenant_id grep row for #{proof}"
      end

      assert Enum.any?(rows, &(&1.kind == "topic")),
             "#{@policy_rel} must list the deliveries PubSub topic"
    end

    test "the same name with different proof files is two distinct rows" do
      rows = Enum.filter(compat_rows!(), &(&1.name == "\"tenant_id\""))

      assert length(rows) == 2
      assert length(Enum.uniq_by(rows, & &1.proof)) == 2
      assert duplicates(rows) == []
    end

    test "every Mailglass.Operator module has a module row" do
      modules = operator_modules()

      assert [_ | _] = modules,
             "no Mailglass.Operator modules found in Application.spec(:mailglass, :modules)"

      unlisted = unlisted_operator_modules(modules, compat_rows!())

      assert unlisted == [],
             "#{@policy_rel} has no module row for #{inspect(unlisted)}. " <>
               "A new Operator module needs a decision: add a row, which commits to keeping the name."
    end

    test "verification does not depend on row order" do
      bad = planted_row("module", "Mailglass.Operator.DoesNotExist", "Code.ensure_loaded?")
      rows = [bad | compat_rows!()]

      assert failures(rows) == failures(Enum.reverse(rows))
      assert Enum.any?(failures(rows), &match?({:error, ^bad, _reason}, &1))
    end
  end

  describe "gloss table" do
    test "lists the four glossed public names, each stating that the public name stays" do
      rows = table_rows!("gloss-table")
      names = Enum.map(rows, & &1.public_name)

      for name <- @gloss_public_names do
        assert name in names, "#{@policy_rel} gloss table is missing #{name}"
      end

      for row <- rows do
        assert row.gloss =~ "public name stays",
               "#{@policy_rel} gloss for #{row.public_name} must say the public name stays"

        assert row.on_screen_word != ""
      end
    end
  end

  describe "parser" do
    defp compat_table(first_cell) do
      """
      <!-- compat-table:start -->
      | name | kind | package | proof |
      |------|------|---------|-------|
      | #{first_cell} | module | mailglass | `Code.ensure_loaded?` |
      <!-- compat-table:end -->
      """
    end

    test "missing markers give :markers_missing" do
      assert parse_table("| name | kind | package | proof |\n", "compat-table") ==
               {:error, :markers_missing}

      assert parse_table("<!-- compat-table:start -->\n| a |\n", "compat-table") ==
               {:error, :markers_missing}
    end

    test "a header-only table gives :empty_table" do
      markdown = """
      <!-- compat-table:start -->
      | name | kind | package | proof |
      |------|------|---------|-------|
      <!-- compat-table:end -->
      """

      assert parse_table(markdown, "compat-table") == {:error, :empty_table}
    end

    test "a table with no rows at all gives :empty_table" do
      assert parse_table(
               "<!-- compat-table:start -->\n<!-- compat-table:end -->\n",
               "compat-table"
             ) == {:error, :empty_table}
    end

    test "a row with the wrong number of cells is reported, not skipped" do
      markdown = """
      <!-- compat-table:start -->
      | name | kind | package | proof |
      |------|------|---------|-------|
      | `Mailglass.Operator.Timeline` | module | mailglass |
      <!-- compat-table:end -->
      """

      assert {:error, {:malformed_row, _line}} = parse_table(markdown, "compat-table")
    end

    test "a changed header is reported" do
      markdown = """
      <!-- compat-table:start -->
      | name | type | package | proof |
      |------|------|---------|-------|
      | `Mailglass.Operator.Timeline` | module | mailglass | `Code.ensure_loaded?` |
      <!-- compat-table:end -->
      """

      assert {:error, {:header_mismatch, _cells}} = parse_table(markdown, "compat-table")
    end

    test "a backticked cell and a bare cell parse to the same name" do
      assert {:ok, [backticked]} =
               parse_table(compat_table("`Mailglass.Operator.Timeline`"), "compat-table")

      assert {:ok, [bare]} =
               parse_table(compat_table("Mailglass.Operator.Timeline"), "compat-table")

      assert backticked.name == "Mailglass.Operator.Timeline"
      assert backticked == bare
    end

    test "ASCII whitespace around a cell is trimmed" do
      assert {:ok, [row]} =
               parse_table(compat_table(" \t`Mailglass.Operator.Timeline`\t "), "compat-table")

      assert row.name == "Mailglass.Operator.Timeline"
    end

    test "names are compared as exact binaries: no case folding, no Unicode trimming" do
      assert {:ok, [lower]} =
               parse_table(compat_table("mailglass.operator.timeline"), "compat-table")

      assert lower.name == "mailglass.operator.timeline"
      assert {:error, _row, _reason} = verify_row(lower)

      nbsp = " "

      assert {:ok, [padded]} =
               parse_table(compat_table("#{nbsp}Mailglass.Operator.Timeline"), "compat-table")

      assert padded.name == nbsp <> "Mailglass.Operator.Timeline"
      assert {:error, _row, _reason} = verify_row(padded)
    end
  end

  describe "teeth" do
    test "every verifier kind rejects a planted bad row with a reason naming the cause" do
      for {row, fragment} <- bad_rows() do
        assert {:error, ^row, reason} = verify_row(row)
        assert reason =~ fragment, "expected #{inspect(fragment)} in #{inspect(reason)}"
      end
    end

    test "a planted failure message names the policy file and the row" do
      row = planted_row("module", "Mailglass.Operator.DoesNotExist", "Code.ensure_loaded?")
      message = failure_message(failures([row]))

      assert message =~ "docs/brand-v2-compatibility.md"
      assert message =~ "Mailglass.Operator.DoesNotExist"
    end

    test "the duplicate detector reports a planted duplicate" do
      [first | _] = rows = compat_rows!()

      assert {first.name, first.kind, first.proof} in duplicates(rows ++ [first])
    end

    test "the required-name guard reports a removed name" do
      rows = Enum.reject(compat_rows!(), &String.contains?(&1.name, ":operator_access"))

      assert ":operator_access" in missing_required(rows)
      assert missing_required([]) == @required_name_fragments
    end

    test "the reverse check reports a module with no row" do
      synthetic = "Mailglass.Operator.Synthetic"

      assert synthetic in unlisted_operator_modules(
               operator_modules() ++ [synthetic],
               compat_rows!()
             )
    end

    test "the reverse check reports a module whose row was deleted" do
      rows = Enum.reject(compat_rows!(), &(&1.name == "Mailglass.Operator.Tenants"))

      assert "Mailglass.Operator.Tenants" in unlisted_operator_modules(operator_modules(), rows)
    end

    test "the cited-path scan reports a path that does not exist" do
      markdown = "See `lib/does/not/exist.ex` and [x](../guides/no-such-guide.md)."

      assert missing_cited_paths(markdown) == [
               "lib/does/not/exist.ex",
               "guides/no-such-guide.md"
             ]
    end
  end
end
