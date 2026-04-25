defmodule Mailglass.Credo.NoFullResponseInLogs do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      levels: [:info, :warning, :error],
      included_path_prefixes: ["lib/mailglass/"],
      suspicious_fragments: ["response", "resp", "body", "payload"]
    ],
    explanations: [
      check: """
      Avoid logging full provider responses at info/warning/error levels.
      """,
      params: [
        levels: "Logger levels to inspect.",
        included_path_prefixes: "Only files in these path prefixes are linted.",
        suspicious_fragments: "Variable-name fragments treated as response payload hints."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      levels = params |> Params.get(:levels, __MODULE__) |> MapSet.new()
      suspicious_fragments = Params.get(params, :suspicious_fragments, __MODULE__)

      source_file
      |> SourceFile.ast()
      |> Macro.postwalk([], fn node, issues ->
        {node, maybe_collect_issue(node, issues, issue_meta, levels, suspicious_fragments)}
      end)
      |> elem(1)
      |> Enum.reverse()
    else
      []
    end
  end

  defp maybe_collect_issue(
         {{:., _, [{:__aliases__, _, [:Logger]}, level]}, meta, args},
         issues,
         issue_meta,
         levels,
         suspicious_fragments
       )
       when is_atom(level) and is_list(args) do
    if MapSet.member?(levels, level) and dangerous_log_payload?(args, suspicious_fragments) do
      issue =
        format_issue(
          issue_meta,
          message:
            "Do not log full response-like payloads via `Logger.#{level}`. Log summarized fields instead.",
          trigger: "Logger.#{level}",
          line_no: meta[:line],
          column: meta[:column]
        )

      [issue | issues]
    else
      issues
    end
  end

  defp maybe_collect_issue(_node, issues, _issue_meta, _levels, _suspicious_fragments), do: issues

  defp dangerous_log_payload?(args, suspicious_fragments) do
    Enum.any?(args, fn arg ->
      contains_inspect_of_response_var?(arg, suspicious_fragments) or
        contains_interpolation_of_response_var?(arg, suspicious_fragments)
    end)
  end

  defp contains_inspect_of_response_var?(ast, suspicious_fragments) do
    ast
    |> Macro.prewalk(false, fn
      {:inspect, _, [expr | _rest]} = node, acc ->
        {node, acc or contains_response_like_variable?(expr, suspicious_fragments)}

      {{:., _, [{:__aliases__, _, [:Kernel]}, :inspect]}, _, [expr | _rest]} = node, acc ->
        {node, acc or contains_response_like_variable?(expr, suspicious_fragments)}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end

  defp contains_interpolation_of_response_var?(ast, suspicious_fragments) do
    ast
    |> Macro.prewalk(false, fn
      {:<<>>, _, parts} = node, acc when is_list(parts) ->
        flagged =
          Enum.any?(parts, fn
            part when is_binary(part) -> false
            part -> contains_response_like_variable?(part, suspicious_fragments)
          end)

        {node, acc or flagged}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end

  defp contains_response_like_variable?(ast, suspicious_fragments) do
    ast
    |> Macro.prewalk(false, fn
      {name, _, context} = node, acc when is_atom(name) and (is_atom(context) or is_nil(context)) ->
        var_name = Atom.to_string(name) |> String.downcase()

        flagged =
          Enum.any?(suspicious_fragments, fn fragment ->
            String.contains?(var_name, String.downcase(fragment))
          end)

        {node, acc or flagged}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
