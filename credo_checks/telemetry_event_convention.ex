defmodule Mailglass.Credo.TelemetryEventConvention do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [required_root: :mailglass, min_segments: 4],
    explanations: [
      check: """
      Telemetry event names must follow mailglass's 4-level convention and
      start with `:mailglass` (or `:mailglass_inbound` for the inbound package).
      """,
      params: [
        required_root:
          "Allowed first segment(s) in telemetry event lists. A single atom or a list of atoms.",
        min_segments: "Minimum number of literal atom segments required."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__)
    required_roots = params |> Params.get(:required_root, __MODULE__) |> List.wrap()
    min_segments = Params.get(params, :min_segments, __MODULE__)

    result =
      Credo.Code.prewalk(source_file, &walk(&1, &2, ctx, required_roots, min_segments), ctx)

    result.issues
  end

  defp walk(
         {{:., _, [:telemetry, :execute]}, meta, [event_ast, _measurements, _metadata]} = ast,
         ctx,
         issue_meta,
         required_roots,
         min_segments
       ) do
    case literal_atom_list(event_ast) do
      {:ok, [root | _] = event}
      when length(event) >= min_segments ->
        if root in required_roots do
          {ast, ctx}
        else
          {ast, put_issue(ctx, root_issue(issue_meta, required_roots, min_segments, meta))}
        end

      {:ok, _event} ->
        {ast, put_issue(ctx, root_issue(issue_meta, required_roots, min_segments, meta))}

      :error ->
        {ast, ctx}
    end
  end

  defp walk(ast, ctx, _issue_meta, _required_roots, _min_segments), do: {ast, ctx}

  defp root_issue(issue_meta, required_roots, min_segments, meta) do
    roots = required_roots |> Enum.map(&inspect/1) |> Enum.join(" or ")

    format_issue(
      issue_meta,
      message:
        "Telemetry event must start with #{roots} and contain at least #{min_segments} segments.",
      trigger: ":telemetry.execute",
      line_no: meta[:line],
      column: meta[:column]
    )
  end

  defp literal_atom_list(list) when is_list(list) do
    if Enum.all?(list, &is_atom/1) do
      {:ok, list}
    else
      :error
    end
  end

  defp literal_atom_list(_ast), do: :error
end
