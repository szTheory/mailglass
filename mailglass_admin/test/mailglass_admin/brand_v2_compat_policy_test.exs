defmodule MailglassAdmin.BrandV2CompatPolicyTest do
  @moduledoc """
  Reads the machine-readable table in `docs/brand-v2-compatibility.md` and
  proves every listed public name still exists in the code.

  The table is the only list: this test parses it and holds no second copy of
  the names. Removing a listed name from the code turns it red with a message
  that names the policy file. Adding names is always allowed.

  The test only reads files and loaded modules and writes nothing, so it runs
  `async: true` with no shared state.
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

  defp compat_rows! do
    case parse_table(policy_markdown!(), "compat-table") do
      {:ok, rows} ->
        rows

      {:error, reason} ->
        flunk(
          "#{@policy_rel} compat table could not be parsed (#{inspect(reason)}). " <>
            "Restore the compat-table:start and compat-table:end markers and a header row " <>
            "`| name | kind | package | proof |`."
        )
    end
  end

  # -- verifier ---------------------------------------------------------------

  defp verify_row(%{kind: "module", name: name} = row) do
    if Code.ensure_loaded?(Module.concat([name])),
      do: :ok,
      else: {:error, row, "module #{name} is not loaded"}
  end

  defp verify_row(row), do: {:error, row, "unknown kind #{inspect(row.kind)}"}

  defp failure_message(failures) do
    lines =
      for {:error, row, reason} <- failures do
        "  - #{row.name} (#{row.kind}): #{reason}"
      end

    "#{@policy_rel} lists public names that the code no longer provides:\n" <>
      Enum.join(lines, "\n") <>
      "\nRestore the name. Removing a row needs the deprecation process in " <>
      "guides/compatibility-and-deprecations.md and a major version."
  end

  describe "policy file" do
    test "lives at the repo-root docs directory" do
      assert Path.relative_to(@policy_path, @repo_root) == @policy_rel
      assert File.regular?(@policy_path)
    end

    test "states the gloss rule" do
      assert policy_markdown!() =~ "glossed, never renamed"
    end
  end

  describe "compat table" do
    test "parses to a non-empty list of rows" do
      assert [_ | _] = compat_rows!()
    end

    test "every row verifies against live code" do
      failures =
        compat_rows!()
        |> Enum.map(&verify_row/1)
        |> Enum.reject(&(&1 == :ok))

      assert failures == [], failure_message(failures)
    end
  end

  describe "parser" do
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

    test "a backticked cell and a bare cell parse to the same name" do
      table = fn cell ->
        """
        <!-- compat-table:start -->
        | name | kind | package | proof |
        |------|------|---------|-------|
        | #{cell} | module | mailglass | `Code.ensure_loaded?` |
        <!-- compat-table:end -->
        """
      end

      assert {:ok, [backticked]} =
               parse_table(table.("`Mailglass.Operator.Timeline`"), "compat-table")

      assert {:ok, [bare]} = parse_table(table.("Mailglass.Operator.Timeline"), "compat-table")
      assert backticked.name == "Mailglass.Operator.Timeline"
      assert backticked == bare
    end
  end

  describe "teeth" do
    test "a module row for a module that does not exist is reported" do
      row = %{
        name: "Mailglass.Operator.DoesNotExist",
        kind: "module",
        package: "mailglass",
        proof: "Code.ensure_loaded?"
      }

      assert {:error, ^row, reason} = verify_row(row)
      assert reason =~ "Mailglass.Operator.DoesNotExist"
      assert failure_message([{:error, row, reason}]) =~ "docs/brand-v2-compatibility.md"
    end
  end
end
