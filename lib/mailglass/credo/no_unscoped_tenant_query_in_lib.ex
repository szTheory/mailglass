defmodule Mailglass.Credo.NoUnscopedTenantQueryInLib do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      tenanted_schemas: [
        Mailglass.Outbound.Delivery,
        Mailglass.Events.Event,
        Mailglass.Suppression.Entry,
        Mailglass.Webhook.WebhookEvent
      ],
      included_path_prefixes: ["lib/mailglass/"],
      repo_functions: [:all, :one, :get, :get!, :get_by, :get_by!, :insert, :update, :delete],
      scope_module: Mailglass.Tenancy
    ],
    explanations: [
      check: """
      Repo queries touching tenanted mailglass schemas must be scoped through
      `Mailglass.Tenancy.scope/2` unless explicitly marked with `scope: :unscoped`.
      """,
      params: [
        tenanted_schemas: "Schemas treated as tenant-scoped resources.",
        included_path_prefixes: "Only files in these path prefixes are linted.",
        repo_functions: "Repo functions treated as query entry points.",
        scope_module: "Module that provides `scope/2`."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      tenanted_schemas = Params.get(params, :tenanted_schemas, __MODULE__)
      repo_functions = params |> Params.get(:repo_functions, __MODULE__) |> MapSet.new()
      scope_module = Params.get(params, :scope_module, __MODULE__)
      schema_tail_names = schema_tail_names(tenanted_schemas)
      scope_module_tail = module_tail_name(scope_module)
      ast = SourceFile.ast(source_file)

      ast
      |> collect_issues(issue_meta, schema_tail_names, repo_functions, scope_module_tail)
      |> Enum.reverse()
    else
      []
    end
  end

  defp collect_issues(ast, issue_meta, schema_tail_names, repo_functions, scope_module_tail) do
    {_ast, issues} =
      Macro.prewalk(ast, [], fn
        {def_type, _meta, [_head, body_kw]} = node, issues when def_type in [:def, :defp] and is_list(body_kw) ->
          body = Keyword.get(body_kw, :do)
          function_issues = function_issues(body, issue_meta, schema_tail_names, repo_functions, scope_module_tail)
          {node, Enum.reverse(function_issues) ++ issues}

        node, issues ->
          {node, issues}
      end)

    issues
  end

  defp function_issues(nil, _issue_meta, _schema_tail_names, _repo_functions, _scope_module_tail), do: []

  defp function_issues(body, issue_meta, schema_tail_names, repo_functions, scope_module_tail) do
    body
    |> collect_repo_calls(schema_tail_names, repo_functions, scope_module_tail)
    |> Enum.reject(&(&1.unscoped_bypass? or &1.scoped_bypass?))
    |> Enum.map(fn call ->
      issue_for(issue_meta, call.line, call.column, call.function_name)
    end)
  end

  defp collect_repo_calls(body, schema_tail_names, repo_functions, scope_module_tail) do
    {_ast, calls} =
      Macro.prewalk(body, [], fn
        {:|>, meta, [lhs, {{:., _, [repo_module_ast, function_name]}, _, rhs_args}]} = node, calls ->
          args = [lhs | List.wrap(rhs_args)]

          {node,
           maybe_collect_call(
             calls,
             meta,
             repo_module_ast,
             function_name,
             args,
             schema_tail_names,
             repo_functions,
             scope_module_tail
           )}

        {{:., _, [repo_module_ast, function_name]}, meta, args} = node, calls ->
          {node,
           maybe_collect_call(
             calls,
             meta,
             repo_module_ast,
             function_name,
             args,
             schema_tail_names,
             repo_functions,
             scope_module_tail
           )}

        node, calls ->
          {node, calls}
      end)

    calls
  end

  defp maybe_collect_call(
         calls,
         meta,
         repo_module_ast,
         function_name,
         args,
         schema_tail_names,
         repo_functions,
         scope_module_tail
       )
       when is_atom(function_name) and is_list(args) do
    if repo_module_ast?(repo_module_ast) and MapSet.member?(repo_functions, function_name) and
         repo_call_targets_tenanted_schema?(args, schema_tail_names) do
      [
        %{
          function_name: function_name,
          line: meta[:line],
          column: meta[:column],
          unscoped_bypass?: explicit_unscoped_bypass?(args),
          scoped_bypass?: scoped_bypass?(args, scope_module_tail)
        }
        | calls
      ]
    else
      calls
    end
  end

  defp maybe_collect_call(
         calls,
         _meta,
         _repo_module_ast,
         _function_name,
         _args,
         _schema_tail_names,
         _repo_functions,
         _scope_module_tail
       ),
    do: calls

  defp scoped_bypass?([queryable | _rest], scope_module_tail) do
    ast_contains_scope_call?(queryable, scope_module_tail)
  end

  defp scoped_bypass?(_args, _scope_module_tail), do: false

  defp ast_contains_scope_call?(ast, scope_module_tail) do
    {_ast, found?} =
      Macro.prewalk(ast, false, fn
        {{:., _, [module_ast, :scope]}, _, args} = node, false when is_list(args) ->
          if module_tail_from_ast(module_ast) == scope_module_tail and args != [] do
            {node, true}
          else
            {node, false}
          end

        node, found? ->
          {node, found?}
      end)

    found?
  end

  defp repo_call_targets_tenanted_schema?([queryable | _rest], schema_tail_names) do
    ast_contains_tenanted_schema?(queryable, schema_tail_names)
  end

  defp repo_call_targets_tenanted_schema?(_args, _schema_tail_names), do: false

  defp ast_contains_tenanted_schema?(ast, schema_tail_names) do
    {_ast, found?} =
      Macro.prewalk(ast, false, fn
        {:__aliases__, _, parts} = node, false when is_list(parts) ->
          tail = parts |> List.last() |> Atom.to_string()

          if MapSet.member?(schema_tail_names, tail), do: {node, true}, else: {node, false}

        node, found? ->
          {node, found?}
      end)

    found?
  end

  defp explicit_unscoped_bypass?(args) when is_list(args) do
    Enum.any?(args, &scope_unscoped_literal?/1)
  end

  defp scope_unscoped_literal?(list) when is_list(list) do
    if Keyword.keyword?(list) do
      Keyword.get(list, :scope) == :unscoped
    else
      false
    end
  end

  defp scope_unscoped_literal?({:%{}, _, pairs}) when is_list(pairs) do
    Enum.any?(pairs, fn
      {:scope, :unscoped} -> true
      _ -> false
    end)
  end

  defp scope_unscoped_literal?(_), do: false

  defp issue_for(issue_meta, line_no, column, function_name) do
    format_issue(
      issue_meta,
      message:
        "Repo.#{function_name} on a tenanted schema must pass through `Mailglass.Tenancy.scope/2` or use `scope: :unscoped`.",
      trigger: "Repo.#{function_name}",
      line_no: line_no,
      column: column
    )
  end

  defp schema_tail_names(schemas) when is_list(schemas) do
    schemas
    |> Enum.map(&module_tail_name/1)
    |> MapSet.new()
  end

  defp module_tail_name(module) when is_atom(module) do
    module
    |> Atom.to_string()
    |> String.trim_leading("Elixir.")
    |> String.split(".")
    |> List.last()
  end

  defp module_tail_name(other) when is_binary(other), do: other
  defp module_tail_name(_other), do: nil

  defp module_tail_from_ast({:__aliases__, _, parts}) when is_list(parts) do
    parts |> List.last() |> Atom.to_string()
  end

  defp module_tail_from_ast(_), do: nil

  defp repo_module_ast?({:__aliases__, _, [:Repo]}), do: true
  defp repo_module_ast?({:__aliases__, _, [:Mailglass, :Repo]}), do: true
  defp repo_module_ast?(_), do: false

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
