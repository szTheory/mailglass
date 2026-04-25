defmodule Mailglass.Credo.NoPiiInTelemetryMeta do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      blocked_keys: ~w(to from cc bcc body html_body text_body subject headers recipient email)a
    ],
    explanations: [
      check: """
      Telemetry metadata in mailglass must not include PII-shaped keys.

      This check only analyzes literal metadata maps passed directly to
      `:telemetry.execute/3` and `:telemetry.span/3`.
      """,
      params: [
        blocked_keys: "Literal metadata keys that are considered PII."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    {blocked_atom_keys, blocked_string_keys} =
      params
      |> Params.get(:blocked_keys, __MODULE__)
      |> blocked_key_sets()

    source_file
    |> SourceFile.ast()
    |> Macro.postwalk([], fn node, issues ->
      {node, maybe_collect_issue(node, issues, issue_meta, blocked_atom_keys, blocked_string_keys)}
    end)
    |> elem(1)
  end

  defp maybe_collect_issue(node, issues, issue_meta, blocked_atom_keys, blocked_string_keys) do
    case telemetry_metadata(node) do
      {:ok, meta_ast, line_no, column} ->
        new_issues =
          meta_ast
          |> blocked_literal_keys(blocked_atom_keys, blocked_string_keys)
          |> Enum.map(&issue_for(issue_meta, line_no, column, &1))

        issues ++ new_issues

      :error ->
        issues
    end
  end

  defp telemetry_metadata(
         {{:., _, [:telemetry, :execute]}, meta, [_event, _measurements, metadata]}
       ) do
    {:ok, metadata, meta[:line], meta[:column]}
  end

  defp telemetry_metadata({{:., _, [:telemetry, :span]}, meta, [_event, metadata, _fun]}) do
    {:ok, metadata, meta[:line], meta[:column]}
  end

  defp telemetry_metadata(_ast), do: :error

  defp blocked_literal_keys({:%{}, _, pairs}, blocked_atom_keys, blocked_string_keys)
       when is_list(pairs) do
    pairs
    |> Enum.reduce(MapSet.new(), fn
      {key, _value}, acc when is_atom(key) ->
        if MapSet.member?(blocked_atom_keys, key), do: MapSet.put(acc, {:atom, key}), else: acc

      {key, _value}, acc when is_binary(key) ->
        if MapSet.member?(blocked_string_keys, key), do: MapSet.put(acc, {:string, key}), else: acc

      _pair, acc ->
        acc
    end)
    |> MapSet.to_list()
    |> Enum.sort_by(&blocked_key_label/1)
  end

  defp blocked_literal_keys(_ast, _blocked_atom_keys, _blocked_string_keys), do: []

  defp blocked_key_sets(blocked_keys) when is_list(blocked_keys) do
    Enum.reduce(blocked_keys, {MapSet.new(), MapSet.new()}, fn
      key, {atom_keys, string_keys} when is_atom(key) ->
        {MapSet.put(atom_keys, key), MapSet.put(string_keys, Atom.to_string(key))}

      key, {atom_keys, string_keys} when is_binary(key) ->
        {atom_keys, MapSet.put(string_keys, key)}

      _key, sets ->
        sets
    end)
  end

  defp blocked_key_sets(_blocked_keys), do: {MapSet.new(), MapSet.new()}

  defp blocked_key_label({:atom, key}), do: ":#{key}"
  defp blocked_key_label({:string, key}), do: "\"#{key}\""

  defp issue_for(issue_meta, line_no, column, blocked_key) do
    label = blocked_key_label(blocked_key)

    format_issue(
      issue_meta,
      message: "Telemetry metadata must not include blocked key `#{label}`.",
      trigger: label,
      line_no: line_no,
      column: column
    )
  end
end
