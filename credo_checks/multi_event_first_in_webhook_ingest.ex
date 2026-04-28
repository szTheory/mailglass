defmodule Mailglass.Credo.MultiEventFirstInWebhookIngest do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    explanations: [
      check: """
      Webhook ingest must keep suppression writes after the durable event append
      and projector path so replay-safe event rows always land first.
      """
    ]

  @target_module Mailglass.Webhook.Ingest
  @required_order [:event_append, :projector_categorize, :projector_apply, :auto_suppress]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    ast = SourceFile.ast(source_file)

    {_ast, state} =
      Macro.traverse(
        ast,
        %{issues: [], module_stack: [], steps: []},
        &prewalk(&1, &2),
        &postwalk(&1, &2, issue_meta)
      )

    Enum.reverse(state.issues)
  end

  defp prewalk({:defmodule, _, [module_ast, _]} = ast, state) do
    {ast, %{state | module_stack: [module_name(module_ast) | state.module_stack]}}
  end

  defp prewalk(ast, state) do
    state =
      if current_module(state) == @target_module do
        case ordering_step(ast) do
          nil -> state
          step -> %{state | steps: [step | state.steps]}
        end
      else
        state
      end

    {ast, state}
  end

  defp postwalk({:defmodule, _, _} = ast, state, issue_meta) do
    issues =
      case current_module(state) do
        @target_module ->
          case issue_for_steps(issue_meta, Enum.reverse(state.steps)) do
            nil -> state.issues
            issue -> [issue | state.issues]
          end

        _other ->
          state.issues
      end

    new_stack =
      case state.module_stack do
        [_ | rest] -> rest
        [] -> []
      end

    {ast, %{state | issues: issues, module_stack: new_stack, steps: []}}
  end

  defp postwalk(ast, state, _issue_meta), do: {ast, state}

  defp issue_for_steps(issue_meta, steps) do
    positions =
      Map.new(steps, fn {name, line_no, column} ->
        {name, %{line_no: line_no, column: column}}
      end)

    auto_step = Map.get(positions, :auto_suppress)

    cond do
      is_nil(auto_step) ->
        nil

      not ordered?(positions) ->
        format_issue(
          issue_meta,
          message:
            "MultiEventFirstInWebhookIngest: suppression writes must stay after the event append path in Mailglass.Webhook.Ingest.",
          trigger: "{:auto_suppress, idx}",
          line_no: auto_step.line_no,
          column: auto_step.column
        )

      true ->
        nil
    end
  end

  defp ordered?(positions) do
    case Enum.map(@required_order, &Map.get(positions, &1)) do
      [%{line_no: a}, %{line_no: b}, %{line_no: c}, %{line_no: d}] ->
        a <= b and b <= c and c <= d

      _missing ->
        false
    end
  end

  defp ordering_step({{:., meta, [{:__aliases__, _, [:Events]}, :append_multi]}, _, _args}) do
    {:event_append, meta[:line], meta[:column]}
  end

  defp ordering_step({:append_events_for_each, meta, _args}) do
    {:event_append, meta[:line], meta[:column]}
  end

  defp ordering_step({{:., meta, [{:__aliases__, _, [:Multi]}, :run]}, _, args}) when is_list(args) do
    step_ast =
      case args do
        [step_ast, _fun] -> step_ast
        [_, step_ast, _fun] -> step_ast
        _other -> nil
      end

    case step_name(step_ast) do
      name when name in [:projector_categorize, :projector_apply, :auto_suppress] ->
        {name, meta[:line], meta[:column]}

      _other ->
        nil
    end
  end

  defp ordering_step(_ast), do: nil

  defp step_name({name, _, _}) when name in [:projector_categorize, :projector_apply, :auto_suppress],
    do: name

  defp step_name({name, _idx})
       when name in [:projector_categorize, :projector_apply, :auto_suppress],
       do: name

  defp step_name({:{}, _, [name, _idx]})
       when name in [:projector_categorize, :projector_apply, :auto_suppress],
       do: name

  defp step_name(_ast), do: nil

  defp module_name({:__aliases__, _, parts}) when is_list(parts), do: Module.concat(parts)
  defp module_name(_ast), do: nil

  defp current_module(%{module_stack: [module | _rest]}), do: module
  defp current_module(_state), do: nil
end
