defmodule Mailglass.Credo.NoCompileEnvOutsideConfig do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      allowed_modules: [Mailglass.Config],
      included_path_prefixes: ["lib/mailglass/"],
      blocked_functions: [:compile_env, :compile_env!]
    ],
    explanations: [
      check: """
      `Application.compile_env*` calls are only allowed inside `Mailglass.Config`.
      """,
      params: [
        allowed_modules: "Modules allowed to call `Application.compile_env*`.",
        included_path_prefixes: "Only files in these path prefixes are linted.",
        blocked_functions: "Application functions treated as compile-time env reads."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      allowed_modules = Params.get(params, :allowed_modules, __MODULE__)
      blocked_functions = params |> Params.get(:blocked_functions, __MODULE__) |> MapSet.new()
      ast = SourceFile.ast(source_file)

      {_ast, state} =
        Macro.traverse(
          ast,
          %{issues: [], module_stack: []},
          &prewalk(&1, &2, issue_meta, allowed_modules, blocked_functions),
          &postwalk/2
        )

      Enum.reverse(state.issues)
    else
      []
    end
  end

  defp prewalk(
         {:defmodule, _, [module_ast, _]} = ast,
         state,
         _issue_meta,
         _allowed_modules,
         _blocked_functions
       ) do
    {ast, %{state | module_stack: [module_name(module_ast) | state.module_stack]}}
  end

  defp prewalk(
         {{:., _, [{:__aliases__, _, [:Application]}, function_name]}, meta, _args} = ast,
         state,
         issue_meta,
         allowed_modules,
         blocked_functions
       )
       when is_atom(function_name) do
    current_module = List.first(state.module_stack)

    if MapSet.member?(blocked_functions, function_name) and
         not allowed_module?(current_module, allowed_modules) do
      issue =
        format_issue(
          issue_meta,
          message: "Only `Mailglass.Config` may call `Application.#{function_name}`.",
          trigger: "Application.#{function_name}",
          line_no: meta[:line],
          column: meta[:column]
        )

      {ast, %{state | issues: [issue | state.issues]}}
    else
      {ast, state}
    end
  end

  defp prewalk(ast, state, _issue_meta, _allowed_modules, _blocked_functions), do: {ast, state}

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

  defp allowed_module?(nil, _allowed_modules), do: false

  defp allowed_module?(module, allowed_modules) do
    module_string = Atom.to_string(module)

    Enum.any?(allowed_modules, fn allowed ->
      allowed_string = Atom.to_string(allowed)
      module == allowed or String.starts_with?(module_string, "#{allowed_string}.")
    end)
  end

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
