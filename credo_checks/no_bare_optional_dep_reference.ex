defmodule Mailglass.Credo.NoBareOptionalDepReference do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      gated_modules: %{
        Oban => Mailglass.OptionalDeps.Oban,
        OpenTelemetry => Mailglass.OptionalDeps.OpenTelemetry,
        Mjml => Mailglass.OptionalDeps.Mjml,
        GenSmtp => Mailglass.OptionalDeps.GenSmtp,
        Sigra => Mailglass.OptionalDeps.Sigra
      },
      included_path_prefixes: ["lib/mailglass/"]
    ],
    explanations: [
      check: """
      Optional dependencies must be reached through `Mailglass.OptionalDeps.*`
      gateway modules, never referenced directly from application code.
      """,
      params: [
        gated_modules: "Map of optional dependency root modules to their required gateway module.",
        included_path_prefixes: "Only files in these path prefixes are linted."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      gated_modules = Params.get(params, :gated_modules, __MODULE__)
      ast = SourceFile.ast(source_file)

      {_ast, state} =
        Macro.traverse(
          ast,
          %{issues: [], module_stack: []},
          &prewalk(&1, &2, issue_meta, gated_modules),
          &postwalk/2
        )

      Enum.reverse(state.issues)
    else
      []
    end
  end

  defp prewalk({:defmodule, _, [module_ast, _]} = ast, state, _issue_meta, _gated_modules) do
    {ast, %{state | module_stack: [module_name(module_ast) | state.module_stack]}}
  end

  defp prewalk(
         {{:., _, [module_ast, function_name]}, meta, _args} = ast,
         state,
         issue_meta,
         gated_modules
       )
       when is_atom(function_name) do
    issue =
      with {:ok, dependency_root} <- root_module(module_ast),
           {:ok, gateway_module} <- Map.fetch(gated_modules, dependency_root),
           current_module <- List.first(state.module_stack),
           false <- allowed_module?(current_module, gateway_module) do
        issue_for(
          issue_meta,
          meta[:line],
          meta[:column],
          dependency_root,
          function_name,
          gateway_module
        )
      else
        _ -> nil
      end

    case issue do
      nil -> {ast, state}
      _ -> {ast, %{state | issues: [issue | state.issues]}}
    end
  end

  defp prewalk(ast, state, _issue_meta, _gated_modules), do: {ast, state}

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

  defp root_module({:__aliases__, _, [root | _rest]}) when is_atom(root) do
    {:ok, Module.concat([root])}
  end

  defp root_module(root) when is_atom(root), do: {:ok, root}
  defp root_module(_ast), do: :error

  defp allowed_module?(nil, _gateway_module), do: false

  defp allowed_module?(module, gateway_module) do
    module == gateway_module
  end

  defp issue_for(issue_meta, line_no, column, dependency_root, function_name, gateway_module) do
    format_issue(
      issue_meta,
      message:
        "Optional dependency call `#{dependency_root}.#{function_name}` must go through `#{gateway_module}`.",
      trigger: "#{dependency_root}.#{function_name}",
      line_no: line_no,
      column: column
    )
  end

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
