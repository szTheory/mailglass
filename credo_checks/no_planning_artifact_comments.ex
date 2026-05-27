defmodule Mailglass.Credo.NoPlanningArtifactComments do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      banned_patterns: [
        ~r/\bD-\d{1,3}\b/,
        ~r/\bPhase\s+\d+(?:\.\d+)?\b/,
        ~r/\bPlan\s+\d+(?:\.\d+)?\b/,
        ~r/\[ASSUMED[^\]]*\]/,
        ~r/\bREQ-[A-Z0-9-]+\b/,
        ~r/\bGSD\b/
      ],
      included_path_prefixes: ["lib/mailglass/", "mailglass_admin/lib/", "mailglass_inbound/lib/"],
      allowed_literals: []
    ],
    explanations: [
      check: """
      Planning-artifact tokens are not allowed in source comments/docstrings.
      Use behavior-focused rationale instead of workflow/provenance markers.
      """,
      params: [
        banned_patterns: "Regex list of disallowed planning-artifact tokens.",
        included_path_prefixes: "Only files in these path prefixes are linted.",
        allowed_literals: "Exact literal matches that are intentionally allowed."
      ]
    ]

  @doc_attrs [:doc, :moduledoc, :typedoc, :shortdoc]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      banned_patterns = Params.get(params, :banned_patterns, __MODULE__)
      allowed_literals = params |> Params.get(:allowed_literals, __MODULE__) |> MapSet.new()

      comment_issues =
        source_file
        |> collect_comment_surfaces()
        |> Enum.flat_map(&issues_for_surface(&1, issue_meta, banned_patterns, allowed_literals, "comment"))

      docstring_issues =
        source_file
        |> collect_docstring_surfaces()
        |> Enum.flat_map(
          &issues_for_surface(&1, issue_meta, banned_patterns, allowed_literals, "docstring")
        )

      comment_issues ++ docstring_issues
    else
      []
    end
  end

  defp collect_comment_surfaces(%SourceFile{} = source_file) do
    source_file
    |> SourceFile.lines()
    |> Enum.reduce([], fn {line_no, line}, acc ->
      case String.trim_leading(line) do
        "#" <> comment -> [{line_no, comment} | acc]
        _other -> acc
      end
    end)
    |> Enum.reverse()
  end

  defp collect_docstring_surfaces(source_file) do
    source_file
    |> SourceFile.ast()
    |> Macro.prewalk([], fn
      {:@, meta, [{name, _, [value]}]} = ast, acc when name in @doc_attrs ->
        line_no = meta[:line] || 1

        case doc_string(value) do
          value when is_binary(value) -> {ast, [{line_no, value} | acc]}
          _other -> {ast, acc}
        end

      ast, acc ->
        {ast, acc}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp issues_for_surface({line_no, value}, issue_meta, banned_patterns, allowed_literals, surface_name) do
    banned_patterns
    |> Enum.flat_map(fn pattern ->
      pattern
      |> Regex.scan(value)
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.reject(&MapSet.member?(allowed_literals, &1))
      |> Enum.map(fn token ->
        format_issue(
          issue_meta,
          message:
            "Planning artifact token `#{token}` is not allowed in #{surface_name} text. Rewrite with behavior-focused rationale.",
          trigger: token,
          line_no: line_no
        )
      end)
    end)
  end

  defp doc_string(value) when is_binary(value), do: value

  defp doc_string({:<<>>, _meta, parts}) when is_list(parts) do
    if Enum.all?(parts, &is_binary/1), do: Enum.join(parts), else: nil
  end

  defp doc_string(_value), do: nil

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
