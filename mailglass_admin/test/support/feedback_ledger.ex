defmodule MailglassAdmin.TestSupport.FeedbackLedger do
  @moduledoc false
  # Pure, total detectors for the owner-feedback ledger in
  # `reference/persona_spec/quick_view_scenarios.json` (UIQ-04, D-07/D-08).
  #
  # The rule is phase-independent: a row is judged by its own status, scenario
  # links and evidence pointer, never by which phase owns it. Rows still
  # `pending` are skipped by the rule and listed by `open_rows/1` so an open row
  # stays visible instead of hiding.
  #
  # Every function returns data (violation tuples or a resolved path); none
  # raises on bad input, so the teeth tests can assert on exact reasons.

  @boundary "connected-real-route-only"
  @archive_glob ".planning/milestones/v*-phases"
  @live_prefix ".planning/phases/"

  @type row_id :: String.t()
  @type violation :: {row_id(), term()}

  @doc "The repository root, resolved from this support file's directory."
  @spec repo_root() :: String.t()
  def repo_root, do: Path.expand("../../..", __DIR__)

  @doc """
  GitHub-style heading slug: lowercase, every character except letters, digits,
  spaces, `-` and `_` dropped (Unicode letters kept), spaces to `-`.
  """
  @spec slug(String.t()) :: String.t()
  def slug(heading) when is_binary(heading) do
    heading
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^\p{L}\p{N} \-_]/u, "")
    |> String.replace(" ", "-")
  end

  @doc """
  Resolves an `evidence_pointer` of the form `path` or `path#anchor`.

  A `.planning/phases/<dir>/...` path resolves in exactly one of the live
  location or any `.planning/milestones/v*-phases/<dir>/...` archive. With an
  anchor, the file must contain a markdown heading whose `slug/1` equals it.
  """
  @spec resolve_pointer(term(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def resolve_pointer(pointer, repo_root)

  def resolve_pointer(pointer, _repo_root) when not is_binary(pointer) or pointer == "",
    do: {:error, :empty_pointer}

  def resolve_pointer(pointer, repo_root) do
    with :ok <- reject_prose(pointer),
         {path, anchor} <- split_anchor(pointer),
         :ok <- reject_unsafe_path(path),
         {:ok, file} <- locate(path, repo_root) do
      check_anchor(file, anchor)
    end
  end

  @doc """
  D-08 rule over the non-pending rows. Returns `[{row_id, reason}]`.

  A non-pending row needs scenario ids that exist, or the connected-only
  `proof_boundary`, and an `evidence_pointer` that resolves.
  """
  @spec rule_violations([map()], [map()], String.t()) :: [violation()]
  def rule_violations(rows, scenarios, repo_root) do
    known = MapSet.new(scenarios, & &1["id"])

    rows
    |> Enum.reject(&(&1["status"] == "pending"))
    |> Enum.flat_map(fn row ->
      scenario_ids = row["scenario_ids"] || []

      scenario_check =
        if scenario_ids == [] and row["proof_boundary"] != @boundary do
          [{row["id"], :no_scenarios_and_no_boundary}]
        else
          for sid <- scenario_ids, not MapSet.member?(known, sid) do
            {row["id"], {:unknown_scenario, sid}}
          end
        end

      pointer_check =
        case resolve_pointer(row["evidence_pointer"], repo_root) do
          {:ok, _path} -> []
          {:error, reason} -> [{row["id"], {:pointer, reason}}]
        end

      scenario_check ++ pointer_check
    end)
  end

  @doc "Rows still open, in manifest order: `%{pending: [id], partial: [id]}`."
  @spec open_rows([map()]) :: %{pending: [row_id()], partial: [row_id()]}
  def open_rows(rows) do
    %{
      pending: for(row <- rows, row["status"] == "pending", do: row["id"]),
      partial: for(row <- rows, row["status"] == "partial", do: row["id"])
    }
  end

  @doc """
  Row-to-scenario back-link: every scenario a row lists must exist and list the
  row id in its own `feedback_ids`.
  """
  @spec link_violations([map()], [map()]) :: [violation()]
  def link_violations(rows, scenarios) do
    by_id = Map.new(scenarios, &{&1["id"], &1})

    for row <- rows,
        sid <- row["scenario_ids"] || [],
        reason = link_problem(row["id"], by_id[sid], sid),
        reason != nil do
      {row["id"], reason}
    end
  end

  @doc "Row ids that appear more than once, each listed once."
  @spec duplicate_ids([map()]) :: [row_id()]
  def duplicate_ids(rows) do
    rows
    |> Enum.frequencies_by(& &1["id"])
    |> Enum.filter(fn {_id, count} -> count > 1 end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
  end

  @accounting_heading "## Retained stories (STORY-07)"
  @linked_heading "### Linked scenarios without a story render (STORY-07)"
  @linked_count_pattern ~r/^Linked scenarios without a story render: (\d+)$/m
  @accounting_columns [
    "Feedback",
    "Requirement(s)",
    "Story-backed scenarios",
    "Linked without story render",
    "Boundary"
  ]
  @linked_columns ["Scenario", "Feedback", "Rendered", "Story path", "Boundary"]

  @doc """
  Per-row story accounting, in row order.

  A scenario is story-backed when it is rendered and has a story path. A row
  links a scenario when the row lists it or the scenario lists the row. Each
  entry is `%{id, stories, unrendered_linked, boundary}`: the count of
  story-backed linked scenarios, the count of linked scenarios that are not
  story-backed, and the row's own `proof_boundary` or else the sorted distinct
  boundaries of its linked scenarios (`"none"` when it links nothing).
  """
  @spec story_accounting([map()], [map()]) :: [map()]
  def story_accounting(rows, scenarios) do
    Enum.map(rows, fn row ->
      linked = linked_scenarios(row, scenarios)
      {backed, unbacked} = Enum.split_with(linked, &story_backed?/1)

      %{
        id: row["id"],
        stories: length(backed),
        unrendered_linked: length(unbacked),
        boundary: boundary_label(row, linked)
      }
    end)
  end

  @doc """
  Rows with no story-backed scenario and no connected-only boundary, so a
  missing, failed or zero-story case is counted and visible.
  """
  @spec story_accounting_violations([map()]) :: [violation()]
  def story_accounting_violations(accounting) do
    for %{id: id, stories: 0, boundary: boundary} <- accounting,
        not String.contains?(boundary, @boundary),
        do: {id, :no_story_and_no_boundary}
  end

  @doc """
  Every scenario that a feedback row links and that is not story-rendered,
  sorted by scenario id. A scenario is linked when some row lists it or its own
  `feedback_ids` is non-empty; `feedback_ids` is the sorted union of both.
  """
  @spec unrendered_linked_scenarios([map()], [map()]) :: [map()]
  def unrendered_linked_scenarios(rows, scenarios) do
    listed = rows |> Enum.flat_map(&(&1["scenario_ids"] || [])) |> MapSet.new()

    scenarios
    |> Enum.filter(fn scenario ->
      (MapSet.member?(listed, scenario["id"]) or (scenario["feedback_ids"] || []) != []) and
        not story_backed?(scenario)
    end)
    |> Enum.map(fn scenario ->
      listing_rows = for row <- rows, scenario["id"] in (row["scenario_ids"] || []), do: row["id"]

      %{
        scenario_id: scenario["id"],
        feedback_ids: Enum.sort(Enum.uniq((scenario["feedback_ids"] || []) ++ listing_rows)),
        rendered: scenario["rendered"],
        story_path: scenario["story_path"],
        proof_boundary: scenario["proof_boundary"]
      }
    end)
    |> Enum.sort_by(& &1.scenario_id)
  end

  @doc "Entries whose `proof_boundary` is missing or empty, so none is silently unaccounted."
  @spec boundary_violations([map()]) :: [violation()]
  def boundary_violations(entries) do
    for %{scenario_id: id, proof_boundary: boundary} <- entries,
        boundary in [nil, ""],
        do: {id, :empty_boundary}
  end

  @doc "The expected cells of the `## Retained stories (STORY-07)` table, one list per row."
  @spec accounting_table_rows([map()], [map()]) :: [[String.t()]]
  def accounting_table_rows(rows, scenarios) do
    rows
    |> Enum.zip(story_accounting(rows, scenarios))
    |> Enum.map(fn {row, entry} ->
      [
        row["id"],
        Enum.join(row["owner_requirements"] || [], ", "),
        Integer.to_string(entry.stories),
        Integer.to_string(entry.unrendered_linked),
        entry.boundary
      ]
    end)
  end

  @doc "The expected cells of the `### Linked scenarios without a story render (STORY-07)` table."
  @spec linked_table_rows([map()], [map()]) :: [[String.t()]]
  def linked_table_rows(rows, scenarios) do
    for entry <- unrendered_linked_scenarios(rows, scenarios) do
      [
        entry.scenario_id,
        Enum.join(entry.feedback_ids, ", "),
        cell(entry.rendered),
        cell(entry.story_path),
        entry.proof_boundary || ""
      ]
    end
  end

  @doc """
  Compares both STORY-07 tables and the count line in the markdown record with
  the computed accounting. Returns `[]` when the record is true.
  """
  @spec accounting_doc_violations(String.t(), [map()], [map()]) :: [term()]
  def accounting_doc_violations(markdown, rows, scenarios) do
    accounting_violations(markdown, rows, scenarios) ++
      linked_violations(markdown, rows, scenarios)
  end

  @doc """
  The first markdown table under `heading` (an exact heading line), as
  `{:ok, header_cells, body_rows}`. A heading that is not found or has no table
  before the next heading is an error.
  """
  @spec table_after(String.t(), String.t()) ::
          {:ok, [String.t()], [[String.t()]]} | {:error, :heading_not_found | :table_not_found}
  def table_after(markdown, heading) do
    lines = String.split(markdown, "\n")

    case Enum.drop_while(lines, &(String.trim_trailing(&1) != heading)) do
      [] ->
        {:error, :heading_not_found}

      [_heading | rest] ->
        table =
          rest
          |> Enum.take_while(&(not heading_line?(&1)))
          |> Enum.drop_while(&(not table_line?(&1)))
          |> Enum.take_while(&table_line?/1)
          |> Enum.map(&split_cells/1)

        case table do
          [header, _separator | body] -> {:ok, header, body}
          _ -> {:error, :table_not_found}
        end
    end
  end

  defp accounting_violations(markdown, rows, scenarios) do
    case table_after(markdown, @accounting_heading) do
      {:ok, header, body} ->
        header_check(:accounting_header, header, @accounting_columns) ++
          row_diff(:accounting, body, accounting_table_rows(rows, scenarios))

      {:error, reason} ->
        [{:accounting_table, reason}]
    end
  end

  defp linked_violations(markdown, rows, scenarios) do
    expected = linked_table_rows(rows, scenarios)

    table =
      case table_after(markdown, @linked_heading) do
        {:ok, header, body} ->
          header_check(:linked_header, header, @linked_columns) ++
            row_diff(:linked, body, expected)

        {:error, reason} ->
          [{:linked_table, reason}]
      end

    table ++ count_check(markdown, length(expected))
  end

  defp count_check(markdown, expected) do
    case Regex.run(@linked_count_pattern, markdown) do
      [_line, count] ->
        if String.to_integer(count) == expected,
          do: [],
          else: [{:linked_count, String.to_integer(count)}]

      nil ->
        [{:linked_count, :missing}]
    end
  end

  defp header_check(_tag, header, header), do: []
  defp header_check(tag, header, _expected), do: [{tag, header}]

  defp row_diff(_tag, body, body), do: []

  defp row_diff(tag, body, expected) do
    missing = for row <- expected -- body, do: {:"#{tag}_missing_row", row}
    extra = for row <- body -- expected, do: {:"#{tag}_extra_row", row}

    case missing ++ extra do
      [] -> [{:"#{tag}_row_order", body}]
      found -> found
    end
  end

  defp linked_scenarios(row, scenarios) do
    listed = row["scenario_ids"] || []

    Enum.filter(scenarios, fn scenario ->
      scenario["id"] in listed or row["id"] in (scenario["feedback_ids"] || [])
    end)
  end

  defp story_backed?(scenario),
    do: scenario["rendered"] == true and scenario["story_path"] not in [nil, ""]

  defp boundary_label(%{"proof_boundary" => boundary}, _linked) when is_binary(boundary),
    do: boundary

  defp boundary_label(_row, []), do: "none"

  defp boundary_label(_row, linked) do
    linked
    |> Enum.map(&(&1["proof_boundary"] || "none"))
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.join(", ")
  end

  defp cell(nil), do: "null"
  defp cell(""), do: "null"
  defp cell(value) when is_binary(value), do: value
  defp cell(value), do: to_string(value)

  defp heading_line?(line), do: String.starts_with?(line, "#")
  defp table_line?(line), do: String.starts_with?(String.trim_leading(line), "|")

  defp split_cells(line) do
    line
    |> String.trim()
    |> String.trim_leading("|")
    |> String.trim_trailing("|")
    |> String.split("|")
    |> Enum.map(&String.trim/1)
  end

  # --- link helpers ---------------------------------------------------------

  defp link_problem(_row_id, nil, sid), do: {:unknown_scenario, sid}

  defp link_problem(row_id, scenario, sid) do
    if row_id in (scenario["feedback_ids"] || []), do: nil, else: {:missing_backlink, sid}
  end

  # --- pointer helpers ------------------------------------------------------

  defp reject_prose(pointer) do
    if String.match?(pointer, ~r/\s/), do: {:error, :prose_pointer}, else: :ok
  end

  defp split_anchor(pointer) do
    case String.split(pointer, "#", parts: 2) do
      [path] -> {path, nil}
      [path, ""] -> {path, ""}
      [path, anchor] -> {path, anchor}
    end
  end

  defp reject_unsafe_path(""), do: {:error, :empty_path}

  defp reject_unsafe_path(path) do
    segments = Path.split(path)

    cond do
      Path.type(path) == :absolute -> {:error, :outside_repo}
      ".." in segments -> {:error, :outside_repo}
      String.match?(path, ~r/[*?\[\]{}\\]/) -> {:error, :invalid_path}
      true -> :ok
    end
  end

  defp locate(path, repo_root) do
    candidates =
      case path do
        @live_prefix <> rest ->
          live = Path.join(repo_root, path)
          archived = Path.wildcard(Path.join([repo_root, @archive_glob, rest]))
          [live | archived]

        _ ->
          [Path.join(repo_root, path)]
      end

    case Enum.filter(candidates, &File.regular?/1) do
      [file] -> {:ok, file}
      [] -> {:error, :missing}
      _many -> {:error, :ambiguous}
    end
  end

  defp check_anchor(file, nil), do: {:ok, file}
  defp check_anchor(_file, ""), do: {:error, :empty_anchor}

  defp check_anchor(file, anchor) do
    if anchor in heading_slugs(file), do: {:ok, file}, else: {:error, {:anchor_not_found, anchor}}
  end

  # Slugs of every ATX heading outside fenced code, with GitHub's `-1`, `-2`
  # suffixes for repeated headings.
  defp heading_slugs(file) do
    {slugs, _fence, _seen} =
      file
      |> File.read!()
      |> String.split(~r/\R/)
      |> Enum.reduce({[], false, %{}}, fn line, {slugs, in_fence, seen} ->
        cond do
          String.match?(line, ~r/^\s{0,3}(```|~~~)/) ->
            {slugs, not in_fence, seen}

          in_fence ->
            {slugs, in_fence, seen}

          match = Regex.run(~r/^\#{1,6}[ \t]+(.+?)[ \t]*#*[ \t]*$/, line) ->
            base = slug(Enum.at(match, 1))
            count = Map.get(seen, base, 0)
            unique = if count == 0, do: base, else: "#{base}-#{count}"
            {[unique | slugs], in_fence, Map.put(seen, base, count + 1)}

          true ->
            {slugs, in_fence, seen}
        end
      end)

    slugs
  end
end
