defmodule Mailglass.Credo.RequireAtomicUnsubscribeHeaders do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    explanations: [
      check: """
      RFC 8058 unsubscribe headers must be written atomically through
      `Mailglass.Compliance.inject_unsubscribe_headers/2`.
      """
    ]

  @injector_module Mailglass.Compliance
  @injector_function :inject_unsubscribe_headers
  @unsubscribe_headers MapSet.new(["List-Unsubscribe", "List-Unsubscribe-Post"])
  @local_writer_functions [:put_header_if_absent, :put_header]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    ast = SourceFile.ast(source_file)

    {_ast, state} =
      Macro.traverse(
        ast,
        %{issues: [], module_stack: [], function_stack: []},
        &prewalk(&1, &2, issue_meta),
        &postwalk(&1, &2, issue_meta)
      )

    Enum.reverse(state.issues)
  end

  defp prewalk({:defmodule, _, [module_ast, body_kw]} = ast, state, _issue_meta) when is_list(body_kw) do
    module_name = module_name(module_ast)
    {ast, %{state | module_stack: [module_name | state.module_stack]}}
  end

  defp prewalk({:def, meta, [head, body_kw]} = ast, state, _issue_meta) when is_list(body_kw) do
    function_name = function_name(head)
    current_module = List.first(state.module_stack)

    function_state = %{
      module: current_module,
      name: function_name,
      line: meta[:line],
      allowed?: current_module == @injector_module and function_name == @injector_function,
      header_writes: MapSet.new()
    }

    {ast, %{state | function_stack: [function_state | state.function_stack]}}
  end

  defp prewalk(ast, %{function_stack: []} = state, _issue_meta), do: {ast, state}

  defp prewalk(ast, state, issue_meta) do
    case unsubscribe_header_write(ast) do
      nil ->
        {ast, state}

      header_name ->
        [current_function | rest] = state.function_stack
        updated_function = %{current_function | header_writes: MapSet.put(current_function.header_writes, header_name)}

        updated_state = %{state | function_stack: [updated_function | rest]}

        if current_function.allowed? do
          {ast, updated_state}
        else
          issue =
            format_issue(
              issue_meta,
              message:
                "Unsubscribe headers must be written via Mailglass.Compliance.inject_unsubscribe_headers/2, not #{format_function_ref(current_function)}.",
              trigger: header_name,
              line_no: line_number(ast, current_function.line)
            )

          {ast, %{updated_state | issues: [issue | updated_state.issues]}}
        end
    end
  end

  defp postwalk({:defmodule, _, _} = ast, state, _issue_meta) do
    {ast, %{state | module_stack: tl_or_empty(state.module_stack)}}
  end

  defp postwalk({:def, _meta, [_head, _body_kw]} = ast, state, issue_meta) do
    [current_function | rest] = state.function_stack

    issues =
      if current_function.allowed? and current_function.header_writes != @unsubscribe_headers do
        issue =
          format_issue(
            issue_meta,
            message:
              "Mailglass.Compliance.inject_unsubscribe_headers/2 must write List-Unsubscribe and List-Unsubscribe-Post together.",
            trigger: Atom.to_string(@injector_function),
            line_no: current_function.line
          )

        [issue | state.issues]
      else
        state.issues
      end

    {ast, %{state | function_stack: rest, issues: issues}}
  end

  defp postwalk(ast, state, _issue_meta), do: {ast, state}

  defp unsubscribe_header_write({name, _meta, args})
       when name in @local_writer_functions and is_list(args) do
    Enum.find_value(args, &header_name_from_ast/1)
  end

  defp unsubscribe_header_write({{:., _, [module_ast, function_name]}, _meta, args})
       when function_name in [:header, :put] and is_list(args) do
    if module_tail_from_ast(module_ast) in ["Email", "Map"] do
      Enum.find_value(args, &header_name_from_ast/1)
    else
      nil
    end
  end

  defp unsubscribe_header_write(_ast), do: nil

  defp header_name_from_ast(header_name) when header_name in ["List-Unsubscribe", "List-Unsubscribe-Post"],
    do: header_name

  defp header_name_from_ast(_), do: nil

  defp module_name({:__aliases__, _, parts}) when is_list(parts), do: Module.concat(parts)
  defp module_name(_ast), do: nil

  defp function_name({:when, _, [head | _guards]}), do: function_name(head)
  defp function_name({name, _, _args}) when is_atom(name), do: name
  defp function_name(_), do: nil

  defp module_tail_from_ast({:__aliases__, _, parts}) when is_list(parts) do
    parts |> List.last() |> Atom.to_string()
  end

  defp module_tail_from_ast(_), do: nil

  defp format_function_ref(%{module: nil, name: name}) when is_atom(name), do: "#{name}/?"
  defp format_function_ref(%{module: module, name: name}) when is_atom(module) and is_atom(name), do: "#{inspect(module)}.#{name}/?"
  defp format_function_ref(_), do: "this function"

  defp line_number({_call, meta, _args}, fallback) when is_list(meta), do: meta[:line] || fallback
  defp line_number(_ast, fallback), do: fallback

  defp tl_or_empty([_ | rest]), do: rest
  defp tl_or_empty([]), do: []
end
