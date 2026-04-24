defmodule Mailglass.Credo.NoRawSwooshSendInLib do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      allowed_modules: [Mailglass.Adapters.Swoosh],
      included_path_prefixes: ["lib/mailglass/"],
      forbidden_functions: [:deliver, :deliver!, :deliver_many]
    ],
    explanations: [
      check: """
      Mailglass library code must send through `Mailglass.Outbound.*`, not
      `Swoosh.Mailer.deliver*` directly.
      """,
      params: [
        allowed_modules: "Modules explicitly allowed to call `Swoosh.Mailer.deliver*`.",
        included_path_prefixes: "Only files in these path prefixes are linted.",
        forbidden_functions: "Swoosh.Mailer function names that are disallowed."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      allowed_modules = params |> Params.get(:allowed_modules, __MODULE__) |> MapSet.new()
      forbidden_functions = params |> Params.get(:forbidden_functions, __MODULE__) |> MapSet.new()
      ast = SourceFile.ast(source_file)
      swoosh_mailer_aliases = collect_swoosh_mailer_aliases(ast)

      {_ast, state} =
        Macro.traverse(
          ast,
          %{issues: [], module_stack: []},
          &prewalk(&1, &2, issue_meta, allowed_modules, forbidden_functions, swoosh_mailer_aliases),
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
         _forbidden_functions,
         _swoosh_mailer_aliases
       ) do
    {ast, %{state | module_stack: [module_name(module_ast) | state.module_stack]}}
  end

  defp prewalk(
         {{:., _, [module_ast, function_name]}, meta, _args} = ast,
         state,
         issue_meta,
         allowed_modules,
         forbidden_functions,
         swoosh_mailer_aliases
       )
       when is_atom(function_name) do
    current_module = List.first(state.module_stack)

    if swoosh_mailer_module_ast?(module_ast, swoosh_mailer_aliases) and
         MapSet.member?(forbidden_functions, function_name) and
         not MapSet.member?(allowed_modules, current_module) do
      issue =
        format_issue(
          issue_meta,
          message:
            "Use `Mailglass.Outbound.*` instead of `Swoosh.Mailer.#{function_name}` in library code.",
          trigger: "Swoosh.Mailer.#{function_name}",
          line_no: meta[:line],
          column: meta[:column]
        )

      {ast, %{state | issues: [issue | state.issues]}}
    else
      {ast, state}
    end
  end

  defp prewalk(ast, state, _issue_meta, _allowed_modules, _forbidden_functions, _swoosh_mailer_aliases),
    do: {ast, state}

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

  defp module_parts_from_ast({:__aliases__, _, parts}) when is_list(parts) do
    Enum.map(parts, &Atom.to_string/1)
  end

  defp module_parts_from_ast(_ast), do: []

  defp module_tail_from_ast({:__aliases__, _, [part]}) when is_atom(part), do: Atom.to_string(part)
  defp module_tail_from_ast(_ast), do: nil

  defp swoosh_mailer_module_ast?(module_ast, swoosh_mailer_aliases) do
    module_tail = module_tail_from_ast(module_ast)

    module_parts_from_ast(module_ast) == ["Swoosh", "Mailer"] or
      MapSet.member?(swoosh_mailer_aliases, module_tail) or
      module_tail == "Mailer"
  end

  defp collect_swoosh_mailer_aliases(ast) do
    {_ast, aliases} =
      Macro.prewalk(ast, MapSet.new(), fn
        {:alias, _, [module_ast]} = node, aliases ->
          {node, maybe_put_swoosh_mailer_alias(aliases, module_ast, [])}

        {:alias, _, [module_ast, opts]} = node, aliases when is_list(opts) ->
          {node, maybe_put_swoosh_mailer_alias(aliases, module_ast, opts)}

        node, aliases ->
          {node, aliases}
      end)

    aliases
  end

  defp maybe_put_swoosh_mailer_alias(aliases, module_ast, opts) do
    if module_parts_from_ast(module_ast) == ["Swoosh", "Mailer"] do
      MapSet.put(aliases, alias_name_from_opts(opts) || "Mailer")
    else
      aliases
    end
  end

  defp alias_name_from_opts(opts) when is_list(opts) do
    case Keyword.get(opts, :as) do
      {:__aliases__, _, parts} when is_list(parts) -> parts |> List.last() |> Atom.to_string()
      name when is_atom(name) -> Atom.to_string(name)
      _ -> nil
    end
  end

  defp alias_name_from_opts(_opts), do: nil

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
