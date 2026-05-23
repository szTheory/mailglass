defmodule Mailglass.Credo.TelemetryEventConvention do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [required_root: :mailglass, min_segments: 4],
    explanations: [
      check: """
      Telemetry event names must follow mailglass's 4-level convention and
      start with `:mailglass` (or `:mailglass_inbound` for the inbound package).

      The convention validates LITERAL atom-list event names at three call-site
      forms:

        * direct `:telemetry.execute/3` call sites — the full event name;
        * direct `:telemetry.span/3` call sites — the event PREFIX; and
        * the package's own `span/3` wrapper call sites (a call to a function
          named `span`, e.g. the inbound private wrapper and the outbound
          `Mailglass.Telemetry.span/3`) — the literal event PREFIX, which is
          where the inbound event names actually live.

      The inbound package wraps every emission in a private `span/3` that
      forwards a VARIABLE prefix to `:telemetry.span/3`; the literal full
      prefix lives at the `span([...], ...)` wrapper call sites inside the
      `*_span/2` helpers. Validating the `span/3` wrapper call site is what
      gives REAL inbound coverage — a literal-only `:telemetry.span/3` clause
      would never fire on inbound code, because the inbound `:telemetry.span`
      call carries a variable.

      A `:telemetry.span/3` prefix and a `span/3` wrapper prefix are both
      validated against `min_segments - 1` because the runtime appends
      `:start`/`:stop`/`:exception` to the prefix, so the emitted event name
      reaches the full segment count.

      A NON-LITERAL (variable) prefix is intentionally NOT validated at any
      call-site form — including the private `span/3` wrapper itself, whose
      `:telemetry.span(event_prefix, ...)` forwards a variable. That is not a
      gap: the literal lives one level up at the `span([...], ...)` wrapper
      call site, which IS covered. Validating the variable forward would only
      produce false positives.
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

  # `span/3` wrapper call sites — the package's own named span wrapper. This is
  # where the LITERAL inbound event names actually live: the inbound `*_span/2`
  # public helpers forward to a private `span([literal_prefix], metadata, fun)`,
  # and the outbound core calls `Mailglass.Telemetry.span([literal_prefix], ...)`.
  # A literal-only `:telemetry.span/3` clause never fires on inbound code because
  # the inbound `:telemetry.span` call carries a VARIABLE prefix — so validating
  # the `span/3` wrapper call site is what delivers real inbound coverage.
  #
  # The wrapper forwards its first arg to `:telemetry.span/3`, so the literal
  # prefix is one segment short of the emitted event (runtime appends
  # `:start`/`:stop`/`:exception`) — validated against `min_segments - 1`, the
  # same off-by-one as the `:telemetry.span` clause. A variable first arg (the
  # private wrapper's own `event_prefix` forward) yields `:error` from
  # `literal_atom_list/1` and produces no issue (false-positive avoidance).
  #
  # Two heads cover the bare-atom local call `span([...], ...)` and the qualified
  # remote call `Mod.span([...], ...)`. Matching the function name `span` (not a
  # `*_span` suffix) is deliberate: the inbound/outbound `*_span/2,/3` helpers do
  # NOT carry a full literal prefix at their public call site — outbound
  # `persist_span([:delivery, :update_projections], ...)` passes a partial SUFFIX
  # that the wrapper prepends `[:mailglass, :persist]` onto, so flagging it by
  # `*_span` suffix would be a false positive. The full literal prefix is always
  # at the `span([...], ...)` wrapper call site.
  defp walk(
         {:span, meta, [event_ast | _rest] = args} = ast,
         ctx,
         issue_meta,
         required_roots,
         min_segments
       )
       when length(args) >= 2 do
    validate(ast, ctx, issue_meta, required_roots, min_segments, event_ast, meta,
      threshold: min_segments - 1,
      trigger: "span"
    )
  end

  defp walk(
         {{:., _, [_module, :span]}, meta, [event_ast | _rest] = args} = ast,
         ctx,
         issue_meta,
         required_roots,
         min_segments
       )
       when length(args) >= 2 do
    validate(ast, ctx, issue_meta, required_roots, min_segments, event_ast, meta,
      threshold: min_segments - 1,
      trigger: "span"
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
