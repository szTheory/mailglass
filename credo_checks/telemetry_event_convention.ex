defmodule Mailglass.Credo.TelemetryEventConvention do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [required_root: :mailglass, min_segments: 4],
    explanations: [
      check: """
      Telemetry event names must follow mailglass's 4-level convention and
      start with `:mailglass` (or `:mailglass_inbound` for the inbound package).

      The convention is enforced for BOTH `:telemetry.execute/3` and
      `:telemetry.span/3`. A `:telemetry.span/3` prefix is validated against
      `min_segments - 1` because the runtime appends `:start`/`:stop`/`:exception`
      to the prefix, so the emitted event name reaches the full segment count.
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
    validate(ast, ctx, issue_meta, required_roots, min_segments, event_ast, meta,
      threshold: min_segments,
      trigger: ":telemetry.execute"
    )
  end

  # `:telemetry.span/3` is arity 3 — `[event_prefix, start_metadata, fun]`. The
  # prefix is one segment shorter than the emitted event because the runtime
  # appends `:start`/`:stop`/`:exception`, so it is validated against
  # `min_segments - 1`.
  defp walk(
         {{:., _, [:telemetry, :span]}, meta, [event_ast, _metadata, _fun]} = ast,
         ctx,
         issue_meta,
         required_roots,
         min_segments
       ) do
    validate(ast, ctx, issue_meta, required_roots, min_segments, event_ast, meta,
      threshold: min_segments - 1,
      trigger: ":telemetry.span"
    )
  end

  defp walk(ast, ctx, _issue_meta, _required_roots, _min_segments), do: {ast, ctx}

  # Shared root/length validation for both `:telemetry.execute` and
  # `:telemetry.span` clauses. `threshold` is the minimum prefix length for the
  # specific call form (execute uses `min_segments`; span uses `min_segments - 1`).
  # The reported message always references `min_segments` because operators reason
  # in final event-name terms, not prefix length. A non-literal prefix (a var)
  # yields `:error` and produces no issue (false-positive avoidance).
  defp validate(ast, ctx, issue_meta, required_roots, min_segments, event_ast, meta,
         threshold: threshold,
         trigger: trigger
       ) do
    case literal_atom_list(event_ast) do
      {:ok, [root | _] = event}
      when length(event) >= threshold ->
        if root in required_roots do
          {ast, ctx}
        else
          {ast, put_issue(ctx, root_issue(issue_meta, required_roots, min_segments, meta, trigger))}
        end

      {:ok, _event} ->
        {ast, put_issue(ctx, root_issue(issue_meta, required_roots, min_segments, meta, trigger))}

      :error ->
        {ast, ctx}
    end
  end

  defp root_issue(issue_meta, required_roots, min_segments, meta, trigger) do
    roots = required_roots |> Enum.map(&inspect/1) |> Enum.join(" or ")

    format_issue(
      issue_meta,
      message:
        "Telemetry event must start with #{roots} and contain at least #{min_segments} segments.",
      trigger: trigger,
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
