defmodule Mailglass.Credo.NoOversizedUseInjection do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [max_lines: 20],
    explanations: [
      check: """
      `defmacro __using__/1` in Mailglass modules must keep injected code small.
      This check counts AST nodes in the returned `quote` body rather than
      macro-expanding the injection.
      """,
      params: [
        max_lines: "Maximum count of tracked AST forms allowed in `__using__/1`."
      ]
    ]

  @tracked_forms [:def, :defmacro, :import, :alias, :require, :use]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    max_lines = Params.get(params, :max_lines, __MODULE__)
    ast = SourceFile.ast(source_file)

    {_ast, state} =
      Macro.traverse(ast, %{issues: [], module_stack: []}, &prewalk(&1, &2, issue_meta, max_lines), &postwalk/2)

    Enum.reverse(state.issues)
  end

  defp prewalk({:defmodule, _, [module_ast, _]} = ast, state, _issue_meta, _max_lines) do
    {ast, %{state | module_stack: [module_name(module_ast) | state.module_stack]}}
  end

  defp prewalk({:defmacro, meta, [head, body_kw]} = ast, state, issue_meta, max_lines)
       when is_list(body_kw) do
    current_module = List.first(state.module_stack)

    if using_macro_head?(head) and mailglass_module?(current_module) do
      injected_lines = injected_line_count(body_kw[:do])

      if injected_lines > max_lines do
        issue =
          format_issue(
            issue_meta,
            message:
              "`__using__/1` injects #{injected_lines} tracked forms, exceeding max #{max_lines}. Keep macro injection <= #{max_lines}.",
            trigger: "__using__",
            line_no: meta[:line],
            column: meta[:column]
          )

        {ast, %{state | issues: [issue | state.issues]}}
      else
        {ast, state}
      end
    else
      {ast, state}
    end
  end

  defp prewalk(ast, state, _issue_meta, _max_lines), do: {ast, state}

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

  defp mailglass_module?(module) when is_atom(module) do
    module_string = Atom.to_string(module)
    module == Mailglass or String.starts_with?(module_string, "Elixir.Mailglass.")
  end

  defp mailglass_module?(_), do: false

  defp using_macro_head?({:when, _, [head | _guards]}), do: using_macro_head?(head)
  defp using_macro_head?({:__using__, _, _}), do: true
  defp using_macro_head?(_), do: false

  defp injected_line_count(nil), do: 0

  defp injected_line_count(body_ast) do
    body_ast
    |> resolve_return_expression()
    |> quote_bodies()
    |> Enum.reduce(0, fn quote_body, total -> total + count_tracked_forms(quote_body) end)
  end

  defp resolve_return_expression({:__block__, _, expressions}) when is_list(expressions) do
    case Enum.reverse(expressions) do
      [last | previous_rev] ->
        case resolve_return_variable(last, previous_rev) do
          {:ok, resolved} -> resolved
          :error -> last
        end

      [] ->
        nil
    end
  end

  defp resolve_return_expression(expression), do: expression

  defp resolve_return_variable({var_name, _, context}, previous_expressions)
       when is_atom(var_name) and (is_atom(context) or is_nil(context)) do
    Enum.find_value(previous_expressions, :error, fn
      {:=, _, [{^var_name, _, _}, rhs]} -> {:ok, rhs}
      _ -> false
    end)
  end

  defp resolve_return_variable(_other, _previous_expressions), do: :error

  defp quote_bodies(nil), do: []

  defp quote_bodies(ast) do
    ast
    |> Macro.prewalk([], fn
      {:quote, _, args} = node, acc ->
        case quote_do_block(args) do
          nil -> {node, acc}
          quote_body -> {node, [quote_body | acc]}
        end

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end

  defp quote_do_block(args) when is_list(args) do
    args
    |> Enum.find_value(fn
      [do: quote_body] -> quote_body
      keyword when is_list(keyword) -> Keyword.get(keyword, :do)
      _ -> nil
    end)
  end

  defp quote_do_block(_), do: nil

  defp count_tracked_forms(nil), do: 0

  defp count_tracked_forms(quote_body) do
    quote_body
    |> Macro.prewalk(0, fn node, count ->
      {node, count + tracked_form_weight(node)}
    end)
    |> elem(1)
  end

  defp tracked_form_weight({form, _, _}) when form in @tracked_forms, do: 1
  defp tracked_form_weight({:@, _, [{:behaviour, _, _}]}), do: 1
  defp tracked_form_weight(_), do: 0
end
