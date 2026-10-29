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
