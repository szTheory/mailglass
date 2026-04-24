defmodule Mailglass.Credo.NoDirectDateTimeNow do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [allowed_modules: [Mailglass.Clock, Mailglass.Clock.System]],
    explanations: [
      check: """
      `DateTime.utc_now/0` calls must be routed through `Mailglass.Clock` so
      time-dependent code remains deterministic under test.
      """,
      params: [
        allowed_modules: "Modules allowed to call `DateTime.utc_now/0` directly."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    allowed_modules = Params.get(params, :allowed_modules, __MODULE__)
    ast = SourceFile.ast(source_file)

    {_ast, state} =
      Macro.traverse(
        ast,
        %{issues: [], module_stack: []},
        &prewalk(&1, &2, issue_meta, allowed_modules),
        &postwalk/2
      )

    Enum.reverse(state.issues)
  end

  defp prewalk({:defmodule, _, [module_ast, _]} = ast, state, _issue_meta, _allowed_modules) do
    {ast, %{state | module_stack: [module_name(module_ast) | state.module_stack]}}
  end

  defp prewalk(
         {{:., _, [{:__aliases__, _, [:DateTime]}, :utc_now]}, meta, []} = ast,
         state,
         issue_meta,
         allowed_modules
       ) do
    if allowed_clock_module?(List.first(state.module_stack), allowed_modules) do
      {ast, state}
    else
      issue = issue_for(issue_meta, meta[:line], meta[:column])
      {ast, %{state | issues: [issue | state.issues]}}
    end
  end

  defp prewalk(
         {:&, meta, [{:/, _, [{{:., _, [{:__aliases__, _, [:DateTime]}, :utc_now]}, _, []}, 0]}]} =
           ast,
         state,
         issue_meta,
         allowed_modules
       ) do
    if allowed_clock_module?(List.first(state.module_stack), allowed_modules) do
      {ast, state}
    else
      issue = issue_for(issue_meta, meta[:line], meta[:column])
      {ast, %{state | issues: [issue | state.issues]}}
    end
  end

  defp prewalk(ast, state, _issue_meta, _allowed_modules), do: {ast, state}

  defp postwalk({:defmodule, _, _} = ast, state) do
    new_stack =
      case state.module_stack do
        [_ | rest] -> rest
        [] -> []
      end

    {ast, %{state | module_stack: new_stack}}
  end

  defp postwalk(ast, state), do: {ast, state}

  defp module_name({:__aliases__, _, parts}) when is_list(parts), do: Module.concat(parts)
  defp module_name(_ast), do: nil

  defp allowed_clock_module?(nil, _allowed_modules), do: false

  defp allowed_clock_module?(module, allowed_modules) do
    module_string = Atom.to_string(module)

    Enum.any?(allowed_modules, fn allowed ->
      allowed_string = Atom.to_string(allowed)
      module == allowed or String.starts_with?(module_string, "#{allowed_string}.")
    end)
  end

  defp issue_for(issue_meta, line_no, column) do
    format_issue(
      issue_meta,
      message: "Use `Mailglass.Clock.utc_now/0` instead of `DateTime.utc_now/0`.",
      trigger: "DateTime.utc_now",
      line_no: line_no,
      column: column
    )
  end
end
