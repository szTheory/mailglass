defmodule Mailglass.Credo.NoDefaultModuleNameSingleton do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      watched_modules: [GenServer, Agent, Registry],
      included_path_prefixes: ["lib/mailglass/"]
    ],
    explanations: [
      check: """
      Library processes must not register as `name: __MODULE__` by default.
      """,
      params: [
        watched_modules: "Modules whose `start_link` calls are inspected.",
        included_path_prefixes: "Only files in these path prefixes are linted."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      watched_modules = params |> Params.get(:watched_modules, __MODULE__) |> MapSet.new()

      source_file
      |> SourceFile.ast()
      |> Macro.postwalk([], fn node, issues ->
        {node, maybe_collect_issue(node, issues, issue_meta, watched_modules)}
      end)
      |> elem(1)
      |> Enum.reverse()
    else
      []
    end
  end

  defp maybe_collect_issue(
         {{:., _, [module_ast, :start_link]}, meta, args},
         issues,
         issue_meta,
         watched_modules
       )
       when is_list(args) do
    with {:ok, module_name} <- module_name(module_ast),
         true <- MapSet.member?(watched_modules, module_name),
         true <- has_default_module_name?(args) do
      issue =
        format_issue(
          issue_meta,
          message:
            "Avoid `name: __MODULE__` in #{inspect(module_name)}.start_link; accept `:name` via options instead.",
          trigger: "name: __MODULE__",
          line_no: meta[:line],
          column: meta[:column]
        )

      [issue | issues]
    else
      _ -> issues
    end
  end

  defp maybe_collect_issue(_node, issues, _issue_meta, _watched_modules), do: issues

  defp module_name({:__aliases__, _, parts}) when is_list(parts), do: {:ok, Module.concat(parts)}
  defp module_name(module) when is_atom(module), do: {:ok, module}
  defp module_name(_ast), do: :error

  defp has_default_module_name?(args) do
    Enum.any?(args, &keyword_with_default_name?/1)
  end

  defp keyword_with_default_name?(maybe_keyword) when is_list(maybe_keyword) do
    if Keyword.keyword?(maybe_keyword) do
      case Keyword.get(maybe_keyword, :name) do
        {:__MODULE__, _, _} -> true
        _ -> false
      end
    else
      false
    end
  end

  defp keyword_with_default_name?(_), do: false

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
