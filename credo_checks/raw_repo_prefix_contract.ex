defmodule Mailglass.Credo.RawRepoPrefixContract do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      included_path_prefixes: ["lib/mailglass/", "mailglass_inbound/lib/"],
      schema_modules: [
        Mailglass.Outbound.Delivery,
        Mailglass.Events.Event,
        Mailglass.Suppression.Entry,
        Mailglass.Webhook.WebhookEvent,
        MailglassInbound.InboundRecords.InboundRecord,
        MailglassInbound.InboundRecords.InboundEvidence,
        MailglassInbound.InboundRecords.ExecutionRun
      ],
      repo_functions: [
        :one,
        :one!,
        :get,
        :get!,
        :get_by,
        :get_by!,
        :all,
        :aggregate,
        :exists?,
        :insert,
        :insert!,
        :insert_all,
        :update,
        :update!,
        :update_all,
        :delete,
        :delete!,
        :delete_all
      ],
      multi_functions: [:insert, :insert_all, :update, :update_all, :delete, :delete_all],
      projection_steps: [:delivery, :projection],
      prefix_helper_functions: [:schema_opts, :insert_opts]
    ],
    explanations: [
      check: """
      Raw callback repos and Ecto.Multi projection updates that touch mailglass
      tables must carry explicit schema prefix opts. Use `Repo.multi_opts()`,
      local `schema_opts()`, or a literal `prefix:` option.
      """,
      params: [
        included_path_prefixes: "Only production files under these prefixes are linted.",
        schema_modules: "Mailglass schemas treated as schema-prefix-sensitive.",
        repo_functions: "Lowercase raw repo functions treated as table access.",
        multi_functions: "Ecto.Multi functions that can update projections.",
        projection_steps: "Multi step names known to update mailglass projections.",
        prefix_helper_functions: "Local helper functions that return explicit prefix opts."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      schema_tail_names = params |> Params.get(:schema_modules, __MODULE__) |> schema_tail_names()
      repo_functions = params |> Params.get(:repo_functions, __MODULE__) |> MapSet.new()
      multi_functions = params |> Params.get(:multi_functions, __MODULE__) |> MapSet.new()
      projection_steps = params |> Params.get(:projection_steps, __MODULE__) |> MapSet.new()

      prefix_helper_functions =
        params |> Params.get(:prefix_helper_functions, __MODULE__) |> MapSet.new()

      source_file
      |> SourceFile.ast()
      |> collect_issues(
        issue_meta,
        schema_tail_names,
        repo_functions,
        multi_functions,
        projection_steps,
        prefix_helper_functions
      )
      |> Enum.reverse()
    else
      []
    end
  end

  defp collect_issues(
         ast,
         issue_meta,
         schema_tail_names,
         repo_functions,
         multi_functions,
         projection_steps,
         prefix_helper_functions
       ) do
    verified_prefix_helpers = collect_verified_prefix_helpers(ast, prefix_helper_functions)
    mailglass_repo_aliases = collect_mailglass_repo_aliases(ast)
    mailglass_config_aliases = collect_mailglass_config_aliases(ast)

    {_ast, issues} =
      Macro.prewalk(ast, [], fn
        {def_type, _meta, [head, body_kw]} = node, issues
        when def_type in [:def, :defp] and is_list(body_kw) ->
          body = Keyword.get(body_kw, :do)

          function_issues =
            function_issues(
              head,
              body,
              issue_meta,
              schema_tail_names,
              repo_functions,
              multi_functions,
              projection_steps,
              verified_prefix_helpers,
              mailglass_repo_aliases,
              mailglass_config_aliases
            )

          {node, Enum.reverse(function_issues) ++ issues}

        node, issues ->
          {node, issues}
      end)

    issues
  end

  defp function_issues(
         _head,
         nil,
         _issue_meta,
         _schema_tail_names,
         _repo_functions,
         _multi_functions,
         _projection_steps,
         _verified_prefix_helpers,
         _mailglass_repo_aliases,
         _mailglass_config_aliases
       ),
       do: []

  defp function_issues(
         head,
         body,
         issue_meta,
         schema_tail_names,
         repo_functions,
         multi_functions,
         projection_steps,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         mailglass_config_aliases
       ) do
    tainted_vars =
      head
      |> collect_schema_pattern_vars(schema_tail_names)
      |> then(&collect_tainted_vars(body, schema_tail_names, &1))

    prefix_contract_vars =
      collect_prefix_contract_vars(
        body,
        verified_prefix_helpers,
        mailglass_repo_aliases,
        mailglass_config_aliases
      )

    {_ast, issues} =
      Macro.prewalk(body, [], fn
        {:|>, _pipe_meta, [lhs, {{:., _, [module_ast, function_name]}, meta, rhs_args}]} = node,
        issues ->
          args = [lhs | List.wrap(rhs_args)]

          {node,
           maybe_collect_call(
             issues,
             meta,
             module_ast,
             function_name,
             args,
             issue_meta,
             schema_tail_names,
             repo_functions,
             multi_functions,
             projection_steps,
             tainted_vars,
             prefix_contract_vars,
             verified_prefix_helpers,
             mailglass_repo_aliases,
             mailglass_config_aliases
           )}

        {{:., _, [module_ast, function_name]}, meta, args} = node, issues ->
          {node,
           maybe_collect_call(
             issues,
             meta,
             module_ast,
             function_name,
             List.wrap(args),
             issue_meta,
             schema_tail_names,
             repo_functions,
             multi_functions,
             projection_steps,
             tainted_vars,
             prefix_contract_vars,
             verified_prefix_helpers,
             mailglass_repo_aliases,
             mailglass_config_aliases
           )}

        node, issues ->
          {node, issues}
      end)

    issues
  end

  defp maybe_collect_call(
         issues,
         meta,
         module_ast,
         function_name,
         args,
         issue_meta,
         schema_tail_names,
         repo_functions,
         multi_functions,
         projection_steps,
         tainted_vars,
         prefix_contract_vars,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         mailglass_config_aliases
       )
       when is_atom(function_name) and is_list(args) do
    cond do
      raw_repo_ast?(module_ast) and MapSet.member?(repo_functions, function_name) ->
        maybe_collect_raw_repo_call(
          issues,
          meta,
          module_ast,
          function_name,
          args,
          issue_meta,
          schema_tail_names,
          tainted_vars,
          prefix_contract_vars,
          verified_prefix_helpers,
          mailglass_repo_aliases,
          mailglass_config_aliases
        )

      multi_ast?(module_ast) and MapSet.member?(multi_functions, function_name) ->
        maybe_collect_multi_call(
          issues,
          meta,
          module_ast,
          function_name,
          args,
          issue_meta,
          schema_tail_names,
          projection_steps,
          tainted_vars,
          prefix_contract_vars,
          verified_prefix_helpers,
          mailglass_repo_aliases,
          mailglass_config_aliases
        )

      true ->
        issues
    end
  end

  defp maybe_collect_call(
         issues,
         _meta,
         _module_ast,
         _function_name,
         _args,
         _issue_meta,
         _schema_tail_names,
         _repo_functions,
         _multi_functions,
         _projection_steps,
         _tainted_vars,
         _prefix_contract_vars,
         _verified_prefix_helpers,
         _mailglass_repo_aliases,
         _mailglass_config_aliases
       ),
       do: issues

  defp maybe_collect_raw_repo_call(
         issues,
         meta,
         module_ast,
         function_name,
         args,
         issue_meta,
         schema_tail_names,
         tainted_vars,
         prefix_contract_vars,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         mailglass_config_aliases
       ) do
    if raw_repo_call_targets_schema?(function_name, args, schema_tail_names, tainted_vars) and
         not call_has_prefix_contract?(
           function_name,
           args,
           prefix_contract_vars,
           verified_prefix_helpers,
           mailglass_repo_aliases,
           mailglass_config_aliases
         ) do
      [
        issue_for(
          issue_meta,
          meta[:line],
          meta[:column],
          raw_repo_trigger(module_ast, function_name)
        )
        | issues
      ]
    else
      issues
    end
  end

  defp maybe_collect_multi_call(
         issues,
         meta,
         module_ast,
         function_name,
         args,
         issue_meta,
         schema_tail_names,
         projection_steps,
         tainted_vars,
         prefix_contract_vars,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         mailglass_config_aliases
       ) do
    if multi_call_targets_projection?(
         function_name,
         args,
         schema_tail_names,
         projection_steps,
         tainted_vars
       ) and
         not multi_call_has_prefix_contract?(
           function_name,
           args,
           prefix_contract_vars,
           verified_prefix_helpers,
           mailglass_repo_aliases,
           mailglass_config_aliases
         ) do
      [
        issue_for(
          issue_meta,
          meta[:line],
          meta[:column],
          "#{multi_trigger(module_ast)}.#{function_name}"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp collect_schema_pattern_vars(head, schema_tail_names) do
    {_ast, vars} =
      Macro.prewalk(head, MapSet.new(), fn
        {:=, _meta, [left, right]} = node, vars ->
          vars =
            cond do
              ast_touches_mailglass_schema?(left, schema_tail_names) ->
                add_pattern_variable(vars, right)

              ast_touches_mailglass_schema?(right, schema_tail_names) ->
                add_pattern_variable(vars, left)

              true ->
                vars
            end

          {node, vars}

        node, vars ->
          {node, vars}
      end)

    vars
  end

  defp collect_tainted_vars(body, schema_tail_names, initial_vars) do
    {_ast, vars} =
      Macro.prewalk(body, initial_vars, fn
        {:=, _meta, [var_ast, rhs]} = node, vars ->
          case variable_name(var_ast) do
            nil ->
              {node, vars}

            name ->
              if ast_touches_mailglass_schema?(rhs, schema_tail_names) or
                   tainted_variable?(rhs, vars) do
                {node, MapSet.put(vars, name)}
              else
                {node, vars}
              end
          end

        node, vars ->
          {node, vars}
      end)

    vars
  end

  defp collect_prefix_contract_vars(
         body,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         mailglass_config_aliases
       ) do
    {_ast, vars} =
      Macro.prewalk(body, MapSet.new(), fn
        {:=, _meta, [var_ast, rhs]} = node, vars ->
          case variable_name(var_ast) do
            nil ->
              {node, vars}

            name ->
              if prefix_contract_opts?(
                   rhs,
                   MapSet.new(),
                   verified_prefix_helpers,
                   mailglass_repo_aliases,
                   mailglass_config_aliases
                 ) do
                {node, MapSet.put(vars, name)}
              else
                {node, vars}
              end
          end

        node, vars ->
          {node, vars}
      end)

    vars
  end

  defp raw_repo_call_targets_schema?(function_name, args, schema_tail_names, tainted_vars) do
    args
    |> Enum.take(raw_repo_min_args(function_name))
    |> Enum.any?(
      &(ast_touches_mailglass_schema?(&1, schema_tail_names) or tainted_variable?(&1, tainted_vars))
    )
  end

  defp multi_call_targets_projection?(
         :update_all,
         args,
         schema_tail_names,
         projection_steps,
         tainted_vars
       ) do
    step_name = Enum.at(args, 1)
    query = Enum.at(args, 2)
    updates = Enum.at(args, 3)

    projection_step?(step_name, projection_steps) or
      schema_ast_or_var?(query, schema_tail_names, tainted_vars) or
      schema_ast_or_var?(updates, schema_tail_names, tainted_vars)
  end

  defp multi_call_targets_projection?(
         function_name,
         args,
         schema_tail_names,
         projection_steps,
         tainted_vars
       )
       when function_name in [:insert, :update, :delete] do
    step_name = Enum.at(args, 1)
    target = Enum.at(args, 2)

    projection_step?(step_name, projection_steps) or
      schema_ast_or_var?(target, schema_tail_names, tainted_vars)
  end

  defp multi_call_targets_projection?(
         :insert_all,
         args,
         schema_tail_names,
         projection_steps,
         tainted_vars
       ) do
    step_name = Enum.at(args, 1)
    schema_or_source = Enum.at(args, 2)
    entries = Enum.at(args, 3)

    projection_step?(step_name, projection_steps) or
      schema_ast_or_var?(schema_or_source, schema_tail_names, tainted_vars) or
      schema_ast_or_var?(entries, schema_tail_names, tainted_vars)
  end

  defp multi_call_targets_projection?(
         :delete_all,
         args,
         schema_tail_names,
         projection_steps,
         tainted_vars
       ) do
    step_name = Enum.at(args, 1)
    query = Enum.at(args, 2)

    projection_step?(step_name, projection_steps) or
      schema_ast_or_var?(query, schema_tail_names, tainted_vars)
  end

  defp multi_call_targets_projection?(
         _function_name,
         _args,
         _schema_tail_names,
         _projection_steps,
         _tainted_vars
       ),
       do: false

  defp call_has_prefix_contract?(
         function_name,
         args,
         prefix_contract_vars,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         mailglass_config_aliases
       ) do
    case final_opts_arg(args, raw_repo_min_args(function_name)) do
      nil ->
        false

      opts ->
        prefix_contract_opts?(
          opts,
          prefix_contract_vars,
          verified_prefix_helpers,
          mailglass_repo_aliases,
          mailglass_config_aliases
        )
    end
  end

  defp multi_call_has_prefix_contract?(
         function_name,
         args,
         prefix_contract_vars,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         mailglass_config_aliases
       )
       when function_name in [:insert, :insert_all, :update, :update_all, :delete, :delete_all] do
    case final_opts_arg(args, multi_min_args(function_name)) do
      nil ->
        false

      opts ->
        prefix_contract_opts?(
          opts,
          prefix_contract_vars,
          verified_prefix_helpers,
          mailglass_repo_aliases,
          mailglass_config_aliases
        )
    end
  end

  defp multi_call_has_prefix_contract?(
         _function_name,
         _args,
         _prefix_contract_vars,
         _verified_prefix_helpers,
         _mailglass_repo_aliases,
         _mailglass_config_aliases
       ),
       do: false

  defp final_opts_arg(args, minimum_non_opts_args) when length(args) > minimum_non_opts_args do
    List.last(args)
  end

  defp final_opts_arg(_args, _minimum_non_opts_args), do: nil

  defp prefix_contract_opts?(
         opts,
         _prefix_contract_vars,
         _verified_prefix_helpers,
         _mailglass_repo_aliases,
         mailglass_config_aliases
       )
       when is_list(opts) do
    returned_expression_has_configured_prefix?(opts, mailglass_config_aliases)
  end

  defp prefix_contract_opts?(
         {helper_name, _meta, args},
         _prefix_contract_vars,
         verified_prefix_helpers,
         _mailglass_repo_aliases,
         _mailglass_config_aliases
       )
       when is_atom(helper_name) and is_list(args) do
    MapSet.member?(verified_prefix_helpers, {helper_name, length(args)})
  end

  defp prefix_contract_opts?(
         {{:., _, [module_ast, :multi_opts]}, _meta, args},
         _prefix_contract_vars,
         _verified_prefix_helpers,
         mailglass_repo_aliases,
         _mailglass_config_aliases
       )
       when is_list(args) do
    mailglass_repo_ast?(module_ast, mailglass_repo_aliases)
  end

  defp prefix_contract_opts?(
         opts,
         prefix_contract_vars,
         _verified_prefix_helpers,
         _mailglass_repo_aliases,
         _mailglass_config_aliases
       ) do
    tainted_variable?(opts, prefix_contract_vars)
  end

  defp schema_ast_or_var?(ast, schema_tail_names, tainted_vars) do
    ast_touches_mailglass_schema?(ast, schema_tail_names) or tainted_variable?(ast, tainted_vars)
  end

  defp add_pattern_variable(vars, ast) do
    case variable_name(ast) do
      nil -> vars
      name -> MapSet.put(vars, name)
    end
  end

  defp ast_touches_mailglass_schema?(ast, schema_tail_names) do
    {_ast, found?} =
      Macro.prewalk(ast, false, fn
        {:__aliases__, _, parts} = node, false when is_list(parts) ->
          tail = parts |> List.last() |> Atom.to_string()

          if MapSet.member?(schema_tail_names, tail), do: {node, true}, else: {node, false}

        {{:., _, [module_ast, :update_projections]}, _, args} = node, false when is_list(args) ->
          if module_tail_from_ast(module_ast) == "Projector", do: {node, true}, else: {node, false}

        node, found? ->
          {node, found?}
      end)

    found?
  end

  defp projection_step?(step_name, projection_steps) when is_atom(step_name) do
    MapSet.member?(projection_steps, step_name)
  end

  defp projection_step?(_step_name, _projection_steps), do: false

  defp raw_repo_min_args(function_name) when function_name in [:get, :get!], do: 2
  defp raw_repo_min_args(function_name) when function_name in [:get_by, :get_by!], do: 2
  defp raw_repo_min_args(:aggregate), do: 2
  defp raw_repo_min_args(function_name) when function_name in [:insert_all, :update_all], do: 2
  defp raw_repo_min_args(_function_name), do: 1

  defp multi_min_args(function_name) when function_name in [:insert, :update, :delete], do: 3
  defp multi_min_args(function_name) when function_name in [:insert_all, :update_all], do: 4
  defp multi_min_args(:delete_all), do: 3

  defp tainted_variable?(ast, tainted_vars) do
    case variable_name(ast) do
      nil -> false
      name -> MapSet.member?(tainted_vars, name)
    end
  end

  defp variable_name({name, _meta, context})
       when is_atom(name) and (is_atom(context) or is_nil(context)),
       do: name

  defp variable_name(_ast), do: nil

  defp raw_repo_ast?({name, _meta, context})
       when is_atom(name) and (is_atom(context) or is_nil(context)) do
    not (name |> Atom.to_string() |> String.starts_with?("_"))
  end

  defp raw_repo_ast?(_module_ast), do: false

  defp multi_ast?({:__aliases__, _, [:Multi]}), do: true
  defp multi_ast?({:__aliases__, _, [:Ecto, :Multi]}), do: true
  defp multi_ast?(_module_ast), do: false

  defp raw_repo_trigger({name, _meta, _context}, function_name), do: "#{name}.#{function_name}"
  defp raw_repo_trigger(_module_ast, function_name), do: "repo.#{function_name}"

  defp multi_trigger({:__aliases__, _, parts}), do: Enum.join(parts, ".")
  defp multi_trigger(_module_ast), do: "Multi"

  defp collect_verified_prefix_helpers(ast, prefix_helper_functions) do
    {_ast, helper_counts} =
      Macro.prewalk(ast, %{}, fn
        {def_type, _meta, [head, body_kw]} = node, helper_counts
        when def_type in [:def, :defp] and is_list(body_kw) ->
          helper_key = function_key_from_head(head)
          body = Keyword.get(body_kw, :do)

          if helper_key && MapSet.member?(prefix_helper_functions, elem(helper_key, 0)) do
            {total, prefixed} = Map.get(helper_counts, helper_key, {0, 0})

            prefixed =
              if returned_expression_has_configured_prefix?(
                   body,
                   collect_mailglass_config_aliases(ast)
                 ),
                 do: prefixed + 1,
                 else: prefixed

            {node, Map.put(helper_counts, helper_key, {total + 1, prefixed})}
          else
            {node, helper_counts}
          end

        node, helper_counts ->
          {node, helper_counts}
      end)

    helper_counts
    |> Enum.reduce(MapSet.new(), fn
      {helper_key, {total, prefixed}}, verified when total > 0 and total == prefixed ->
        MapSet.put(verified, helper_key)

      _entry, verified ->
        verified
    end)
  end

  defp function_key_from_head({:when, _meta, [head | _guards]}),
    do: function_key_from_head(head)

  defp function_key_from_head({name, _meta, args}) when is_atom(name) and is_list(args),
    do: {name, length(args)}

  defp function_key_from_head({name, _meta, context})
       when is_atom(name) and (is_atom(context) or is_nil(context)),
       do: {name, 0}

  defp function_key_from_head(_head), do: nil

  defp returned_expression({:__block__, _meta, expressions}) when is_list(expressions) do
    expressions
    |> List.last()
    |> returned_expression()
  end

  defp returned_expression(expression), do: expression

  defp returned_expression_has_configured_prefix?(ast, mailglass_config_aliases) do
    ast
    |> returned_expression()
    |> do_returned_expression_has_configured_prefix?(mailglass_config_aliases)
  end

  defp do_returned_expression_has_configured_prefix?(opts, mailglass_config_aliases)
       when is_list(opts) do
    Keyword.keyword?(opts) and
      configured_prefix_ast?(Keyword.get(opts, :prefix), mailglass_config_aliases)
  end

  defp do_returned_expression_has_configured_prefix?(
         {{:., _, [{:__aliases__, _, [:Keyword]}, function_name]}, _meta,
          [_opts, :prefix, prefix_ast]},
         mailglass_config_aliases
       )
       when function_name in [:put, :put_new] do
    configured_prefix_ast?(prefix_ast, mailglass_config_aliases)
  end

  defp do_returned_expression_has_configured_prefix?(
         {:|>, _meta,
          [
            _opts,
            {{:., _, [{:__aliases__, _, [:Keyword]}, function_name]}, _call_meta,
             [:prefix, prefix_ast]}
          ]},
         mailglass_config_aliases
       )
       when function_name in [:put, :put_new] do
    configured_prefix_ast?(prefix_ast, mailglass_config_aliases)
  end

  defp do_returned_expression_has_configured_prefix?(_expression, _mailglass_config_aliases),
    do: false

  defp configured_prefix_ast?(
         {{:., _, [{:__aliases__, _, [:Mailglass, :Config]}, :schema]}, _meta, args},
         _mailglass_config_aliases
       )
       when is_list(args),
       do: args == []

  defp configured_prefix_ast?(
         {{:., _, [{:__aliases__, _, [:MailglassInbound, :Config]}, :schema]}, _meta, args},
         _mailglass_config_aliases
       )
       when is_list(args),
       do: args == []

  defp configured_prefix_ast?(
         {{:., _, [{:__aliases__, _, parts}, :schema]}, _meta, args},
         mailglass_config_aliases
       )
       when is_list(parts) and is_list(args) do
    args == [] and MapSet.member?(mailglass_config_aliases, Enum.join(parts, "."))
  end

  defp configured_prefix_ast?(_ast, _mailglass_config_aliases), do: false

  defp collect_mailglass_repo_aliases(ast) do
    {_ast, aliases} =
      Macro.prewalk(ast, MapSet.new(), fn
        {:alias, _meta, args} = node, aliases ->
          {node, collect_mailglass_repo_alias(args, aliases)}

        node, aliases ->
          {node, aliases}
      end)

    aliases
  end

  defp collect_mailglass_repo_alias([alias_ast], aliases) do
    alias_string = Macro.to_string(alias_ast)

    cond do
      alias_string == "Mailglass.Repo" ->
        MapSet.put(aliases, "Repo")

      String.starts_with?(alias_string, "Mailglass.{") and
          Regex.match?(~r/(^|[{\s,])Repo([}\s,]|$)/, alias_string) ->
        MapSet.put(aliases, "Repo")

      true ->
        aliases
    end
  end

  defp collect_mailglass_repo_alias([alias_ast, opts], aliases) when is_list(opts) do
    alias_string = Macro.to_string(alias_ast)

    case Keyword.get(opts, :as) do
      as_name when alias_string == "Mailglass.Repo" and is_atom(as_name) ->
        MapSet.put(aliases, Atom.to_string(as_name))

      _other ->
        collect_mailglass_repo_alias([alias_ast], aliases)
    end
  end

  defp collect_mailglass_repo_alias(_args, aliases), do: aliases

  defp collect_mailglass_config_aliases(ast) do
    {_ast, aliases} =
      Macro.prewalk(ast, MapSet.new(), fn
        {:alias, _meta, args} = node, aliases ->
          {node, collect_mailglass_config_alias(args, aliases)}

        node, aliases ->
          {node, aliases}
      end)

    aliases
  end

  defp collect_mailglass_config_alias([alias_ast], aliases) do
    alias_string = Macro.to_string(alias_ast)

    cond do
      alias_string == "Mailglass.Config" or alias_string == "MailglassInbound.Config" ->
        MapSet.put(aliases, "Config")

      String.starts_with?(alias_string, "Mailglass.{") and
          Regex.match?(~r/(^|[{\s,])Config([}\s,]|$)/, alias_string) ->
        MapSet.put(aliases, "Config")

      String.starts_with?(alias_string, "MailglassInbound.{") and
          Regex.match?(~r/(^|[{\s,])Config([}\s,]|$)/, alias_string) ->
        MapSet.put(aliases, "Config")

      true ->
        aliases
    end
  end

  defp collect_mailglass_config_alias([alias_ast, opts], aliases) when is_list(opts) do
    alias_string = Macro.to_string(alias_ast)

    case Keyword.get(opts, :as) do
      as_name
      when alias_string in ["Mailglass.Config", "MailglassInbound.Config"] and is_atom(as_name) ->
        MapSet.put(aliases, Atom.to_string(as_name))

      _other ->
        collect_mailglass_config_alias([alias_ast], aliases)
    end
  end

  defp collect_mailglass_config_alias(_args, aliases), do: aliases

  defp mailglass_repo_ast?({:__aliases__, _, [:Mailglass, :Repo]}, _mailglass_repo_aliases),
    do: true

  defp mailglass_repo_ast?({:__aliases__, _, parts}, mailglass_repo_aliases) when is_list(parts) do
    parts
    |> Enum.join(".")
    |> then(&MapSet.member?(mailglass_repo_aliases, &1))
  end

  defp mailglass_repo_ast?(_module_ast, _mailglass_repo_aliases), do: false

  defp issue_for(issue_meta, line_no, column, trigger) do
    format_issue(
      issue_meta,
      message:
        "Raw repo/Multi call touching mailglass tables must pass explicit schema prefix opts via `Repo.multi_opts()`, `schema_opts()`, or `prefix:`.",
      trigger: trigger,
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

  defp module_tail_from_ast(_module_ast), do: nil

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
