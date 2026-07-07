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
      table_sources: [
        core: [
          "mailglass_deliveries",
          "mailglass_events",
          "mailglass_suppressions",
          "mailglass_webhook_events"
        ],
        inbound: [
          "mailglass_inbound_records",
          "mailglass_inbound_evidence",
          "mailglass_inbound_replay_runs"
        ]
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
        table_sources: "String table sources treated as schema-prefix-sensitive.",
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
      schema_owners = params |> Params.get(:schema_modules, __MODULE__) |> schema_owners()

      table_source_owners =
        params |> Params.get(:table_sources, __MODULE__) |> table_source_owners()

      repo_functions = params |> Params.get(:repo_functions, __MODULE__) |> MapSet.new()
      multi_functions = params |> Params.get(:multi_functions, __MODULE__) |> MapSet.new()
      projection_steps = params |> Params.get(:projection_steps, __MODULE__) |> MapSet.new()

      prefix_helper_functions =
        params |> Params.get(:prefix_helper_functions, __MODULE__) |> MapSet.new()

      source_file
      |> SourceFile.ast()
      |> collect_issues(
        issue_meta,
        schema_owners,
        table_source_owners,
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
         schema_owners,
         table_source_owners,
         repo_functions,
         multi_functions,
         projection_steps,
         prefix_helper_functions
       ) do
    mailglass_repo_aliases = collect_mailglass_repo_aliases(ast)
    facade_repo_aliases = collect_facade_repo_aliases(ast)
    raw_repo_aliases = collect_raw_repo_aliases(ast)
    multi_aliases = collect_multi_aliases(ast)
    mailglass_config_alias_owners = collect_mailglass_config_alias_owners(ast)

    schema_owners =
      schema_owners
      |> merge_owner_maps(collect_schema_alias_owners(ast, schema_owners))

    schema_owners =
      schema_owners
      |> merge_owner_maps(collect_schema_attribute_owners(ast, schema_owners, table_source_owners))

    schema_owners =
      schema_owners
      |> merge_owner_maps(
        collect_local_query_helper_owners(ast, schema_owners, table_source_owners)
      )

    verified_prefix_helpers =
      collect_verified_prefix_helpers(
        ast,
        prefix_helper_functions,
        mailglass_repo_aliases,
        mailglass_config_alias_owners
      )

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
              schema_owners,
              table_source_owners,
              repo_functions,
              multi_functions,
              projection_steps,
              verified_prefix_helpers,
              mailglass_repo_aliases,
              facade_repo_aliases,
              raw_repo_aliases,
              multi_aliases,
              mailglass_config_alias_owners
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
         _schema_owners,
         _table_source_owners,
         _repo_functions,
         _multi_functions,
         _projection_steps,
         _verified_prefix_helpers,
         _mailglass_repo_aliases,
         _facade_repo_aliases,
         _raw_repo_aliases,
         _multi_aliases,
         _mailglass_config_aliases
       ),
       do: []

  defp function_issues(
         head,
         body,
         issue_meta,
         schema_owners,
         table_source_owners,
         repo_functions,
         multi_functions,
         projection_steps,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         facade_repo_aliases,
         raw_repo_aliases,
         multi_aliases,
         mailglass_config_alias_owners
       ) do
    initial_state = %{
      tainted_var_owners:
        collect_schema_pattern_var_owners(head, schema_owners, table_source_owners),
      prefix_contract_var_owners: %{},
      issues: [],
      scope_stack: []
    }

    {_ast, state} =
      Macro.traverse(
        body,
        initial_state,
        fn
          {:|>, _pipe_meta, [lhs, {{:., _, [module_ast, function_name]}, meta, rhs_args}]} = node,
          state ->
            args = [lhs | List.wrap(rhs_args)]
            state = push_scope_if_needed(state, node)

            {node,
             maybe_collect_call(
               update_state_for_match(
                 state,
                 node,
                 schema_owners,
                 table_source_owners,
                 verified_prefix_helpers,
                 mailglass_repo_aliases,
                 mailglass_config_alias_owners
               ),
               meta,
               module_ast,
               function_name,
               args,
               issue_meta,
               schema_owners,
               table_source_owners,
               repo_functions,
               multi_functions,
               projection_steps,
               verified_prefix_helpers,
               mailglass_repo_aliases,
               facade_repo_aliases,
               raw_repo_aliases,
               multi_aliases,
               mailglass_config_alias_owners
             )}

          {{:., _, [module_ast, function_name]}, meta, args} = node, state ->
            state = push_scope_if_needed(state, node)

            {node,
             maybe_collect_call(
               update_state_for_match(
                 state,
                 node,
                 schema_owners,
                 table_source_owners,
                 verified_prefix_helpers,
                 mailglass_repo_aliases,
                 mailglass_config_alias_owners
               ),
               meta,
               module_ast,
               function_name,
               List.wrap(args),
               issue_meta,
               schema_owners,
               table_source_owners,
               repo_functions,
               multi_functions,
               projection_steps,
               verified_prefix_helpers,
               mailglass_repo_aliases,
               facade_repo_aliases,
               raw_repo_aliases,
               multi_aliases,
               mailglass_config_alias_owners
             )}

          node, state ->
            state = push_scope_if_needed(state, node)

            {node,
             update_state_for_match(
               state,
               node,
               schema_owners,
               table_source_owners,
               verified_prefix_helpers,
               mailglass_repo_aliases,
               mailglass_config_alias_owners
             )}
        end,
        fn node, state ->
          {node, pop_scope_if_needed(state, node)}
        end
      )

    Enum.uniq_by(state.issues, fn issue -> {issue.line_no, issue.column, issue.trigger} end)
  end

  defp maybe_collect_call(
         state,
         meta,
         module_ast,
         function_name,
         args,
         issue_meta,
         schema_owners,
         table_source_owners,
         repo_functions,
         multi_functions,
         projection_steps,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         facade_repo_aliases,
         raw_repo_aliases,
         multi_aliases,
         mailglass_config_alias_owners
       )
       when is_atom(function_name) and is_list(args) do
    cond do
      multi_ast?(module_ast, multi_aliases) and MapSet.member?(multi_functions, function_name) ->
        maybe_collect_multi_call(
          state,
          meta,
          module_ast,
          function_name,
          args,
          issue_meta,
          schema_owners,
          table_source_owners,
          projection_steps,
          verified_prefix_helpers,
          mailglass_repo_aliases,
          mailglass_config_alias_owners
        )

      raw_repo_ast?(module_ast, facade_repo_aliases, raw_repo_aliases) and
          MapSet.member?(repo_functions, function_name) ->
        maybe_collect_raw_repo_call(
          state,
          meta,
          module_ast,
          function_name,
          args,
          issue_meta,
          schema_owners,
          table_source_owners,
          verified_prefix_helpers,
          mailglass_repo_aliases,
          mailglass_config_alias_owners
        )

      true ->
        state
    end
  end

  defp maybe_collect_call(
         state,
         _meta,
         _module_ast,
         _function_name,
         _args,
         _issue_meta,
         _schema_owners,
         _table_source_owners,
         _repo_functions,
         _multi_functions,
         _projection_steps,
         _verified_prefix_helpers,
         _mailglass_repo_aliases,
         _facade_repo_aliases,
         _raw_repo_aliases,
         _multi_aliases,
         _mailglass_config_alias_owners
       ),
       do: state

  defp maybe_collect_raw_repo_call(
         state,
         meta,
         module_ast,
         function_name,
         args,
         issue_meta,
         schema_owners,
         table_source_owners,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         mailglass_config_alias_owners
       ) do
    target_owners =
      raw_repo_call_target_owners(
        function_name,
        args,
        schema_owners,
        table_source_owners,
        state.tainted_var_owners
      )

    if not MapSet.equal?(target_owners, MapSet.new()) and
         not call_has_prefix_contract?(
           function_name,
           args,
           target_owners,
           state.prefix_contract_var_owners,
           verified_prefix_helpers,
           mailglass_repo_aliases,
           mailglass_config_alias_owners
         ) do
      prepend_issue(
        state,
        issue_meta,
        meta,
        raw_repo_trigger(module_ast, function_name)
      )
    else
      state
    end
  end

  defp maybe_collect_multi_call(
         state,
         meta,
         module_ast,
         function_name,
         args,
         issue_meta,
         schema_owners,
         table_source_owners,
         projection_steps,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         mailglass_config_alias_owners
       ) do
    target_owners =
      multi_call_target_owners(
        function_name,
        args,
        schema_owners,
        table_source_owners,
        projection_steps,
        state.tainted_var_owners
      )

    if not MapSet.equal?(target_owners, MapSet.new()) and
         not multi_call_has_prefix_contract?(
           function_name,
           args,
           target_owners,
           state.prefix_contract_var_owners,
           verified_prefix_helpers,
           mailglass_repo_aliases,
           mailglass_config_alias_owners
         ) do
      prepend_issue(
        state,
        issue_meta,
        meta,
        "#{multi_trigger(module_ast)}.#{function_name}"
      )
    else
      state
    end
  end

  defp collect_schema_pattern_var_owners(head, schema_owners, table_source_owners) do
    {_ast, var_owners} =
      Macro.prewalk(head, %{}, fn
        {:=, _meta, [left, right]} = node, vars ->
          vars =
            vars
            |> add_schema_pattern_var_owners(left, right, schema_owners, table_source_owners)
            |> add_schema_pattern_var_owners(right, left, schema_owners, table_source_owners)

          {node, vars}

        node, vars ->
          {node, vars}
      end)

    var_owners
  end

  defp update_state_for_match(
         state,
         {op, _meta, [left, right]},
         schema_owners,
         table_source_owners,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         mailglass_config_alias_owners
       )
       when op in [:=, :<-] do
    state
    |> update_tainted_var_owners(left, right, schema_owners, table_source_owners)
    |> update_prefix_contract_var_owners(
      left,
      right,
      verified_prefix_helpers,
      mailglass_repo_aliases,
      mailglass_config_alias_owners
    )
  end

  defp update_state_for_match(
         state,
         _node,
         _schema_owners,
         _table_source_owners,
         _verified_prefix_helpers,
         _mailglass_repo_aliases,
         _mailglass_config_alias_owners
       ),
       do: state

  defp push_scope_if_needed(state, node) do
    if scoped_node?(node) do
      snapshot = %{
        tainted_var_owners: state.tainted_var_owners,
        prefix_contract_var_owners: state.prefix_contract_var_owners
      }

      %{state | scope_stack: [snapshot | state.scope_stack]}
    else
      state
    end
  end

  defp pop_scope_if_needed(state, node) do
    if scoped_node?(node) do
      [snapshot | scope_stack] = state.scope_stack

      %{
        state
        | tainted_var_owners: snapshot.tainted_var_owners,
          prefix_contract_var_owners: snapshot.prefix_contract_var_owners,
          scope_stack: scope_stack
      }
    else
      state
    end
  end

  defp scoped_node?({:fn, _meta, _clauses}), do: true
  defp scoped_node?({:->, _meta, _args}), do: true
  defp scoped_node?({:case, _meta, _args}), do: true
  defp scoped_node?({:cond, _meta, _args}), do: true
  defp scoped_node?({:if, _meta, _args}), do: true
  defp scoped_node?({:unless, _meta, _args}), do: true
  defp scoped_node?({:with, _meta, _args}), do: true
  defp scoped_node?({:for, _meta, _args}), do: true
  defp scoped_node?({:try, _meta, _args}), do: true
  defp scoped_node?({:receive, _meta, _args}), do: true
  defp scoped_node?(_node), do: false

  defp update_tainted_var_owners(state, left, right, schema_owners, table_source_owners) do
    tainted_var_owners =
      state.tainted_var_owners
      |> add_schema_pattern_var_owners(left, right, schema_owners, table_source_owners)
      |> add_schema_pattern_var_owners(right, left, schema_owners, table_source_owners)
      |> update_tainted_assignment_owners(left, right, schema_owners, table_source_owners)

    %{state | tainted_var_owners: tainted_var_owners}
  end

  defp update_prefix_contract_var_owners(
         state,
         left,
         right,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         mailglass_config_alias_owners
       ) do
    case variable_name(left) do
      nil ->
        state

      name ->
        owners =
          prefix_contract_owners(
            right,
            state.prefix_contract_var_owners,
            verified_prefix_helpers,
            mailglass_repo_aliases,
            mailglass_config_alias_owners
          )

        prefix_contract_var_owners =
          if MapSet.equal?(owners, MapSet.new()) do
            Map.delete(state.prefix_contract_var_owners, name)
          else
            Map.put(state.prefix_contract_var_owners, name, owners)
          end

        %{state | prefix_contract_var_owners: prefix_contract_var_owners}
    end
  end

  defp raw_repo_call_target_owners(
         function_name,
         args,
         schema_owners,
         table_source_owners,
         tainted_var_owners
       ) do
    args
    |> Enum.take(raw_repo_min_args(function_name))
    |> Enum.reduce(MapSet.new(), fn ast, owners ->
      MapSet.union(
        owners,
        owners_for_ast(ast, schema_owners, table_source_owners, tainted_var_owners)
      )
    end)
  end

  defp prepend_issue(state, issue_meta, meta, trigger) do
    issue =
      issue_for(
        issue_meta,
        meta[:line],
        meta[:column],
        trigger
      )

    %{state | issues: [issue | state.issues]}
  end

  defp prefix_contract_covers?(contract_owners, target_owners) do
    MapSet.subset?(target_owners, contract_owners)
  end

  defp empty_owners?(owners), do: MapSet.equal?(owners, MapSet.new())

  defp merge_owners(left, right), do: MapSet.union(left, right)

  defp merge_owner_maps(left, right) do
    Enum.reduce(right, left, fn {key, owners}, merged ->
      Map.update(merged, key, owners, &merge_owners(&1, owners))
    end)
  end

  defp put_registry_owners(registry, key, owners) do
    if empty_owners?(owners) do
      registry
    else
      Map.update(registry, key, owners, &merge_owners(&1, owners))
    end
  end

  defp union_owners(asts, schema_owners, table_source_owners, tainted_var_owners) do
    Enum.reduce(asts, MapSet.new(), fn ast, owners ->
      merge_owners(
        owners,
        owners_for_ast(ast, schema_owners, table_source_owners, tainted_var_owners)
      )
    end)
  end

  defp owner_set(owner), do: MapSet.new([owner])

  defp put_var_owners(var_owners, names, owners) do
    Enum.reduce(names, var_owners, fn name, acc ->
      Map.update(acc, name, owners, &merge_owners(&1, owners))
    end)
  end

  defp add_schema_pattern_var_owners(
         var_owners,
         schema_pattern,
         bound_ast,
         schema_owners,
         table_source_owners
       ) do
    owners = owners_for_ast(schema_pattern, schema_owners, table_source_owners, var_owners)

    if empty_owners?(owners) do
      var_owners
    else
      names =
        schema_pattern
        |> variable_names()
        |> MapSet.union(variable_names(bound_ast))

      put_var_owners(var_owners, names, owners)
    end
  end

  defp update_tainted_assignment_owners(
         var_owners,
         left,
         right,
         schema_owners,
         table_source_owners
       ) do
    case variable_name(left) do
      nil ->
        var_owners

      name ->
        owners = owners_for_ast(right, schema_owners, table_source_owners, var_owners)

        if empty_owners?(owners) do
          Map.delete(var_owners, name)
        else
          Map.put(var_owners, name, owners)
        end
    end
  end

  defp owners_for_ast(nil, _schema_owners, _table_source_owners, _tainted_var_owners),
    do: MapSet.new()

  defp owners_for_ast(ast, schema_owners, table_source_owners, tainted_var_owners) do
    {_ast, owners} =
      Macro.prewalk(ast, MapSet.new(), fn
        {:@, _, [{attr_name, _, _args}]} = node, owners when is_atom(attr_name) ->
          attr_owners =
            Map.get(schema_owners, module_attribute_owner_key(attr_name), MapSet.new())

          {node, merge_owners(owners, attr_owners)}

        {:__aliases__, _, parts} = node, owners when is_list(parts) ->
          alias_string = Enum.join(parts, ".")
          tail = parts |> List.last() |> Atom.to_string()

          owners =
            owners
            |> merge_owners(Map.get(schema_owners, alias_string, MapSet.new()))
            |> merge_owners(Map.get(schema_owners, tail, MapSet.new()))

          {node, owners}

        table, owners when is_binary(table) ->
          {table, merge_owners(owners, Map.get(table_source_owners, table, MapSet.new()))}

        {function_name, _meta, args} = node, owners when is_atom(function_name) and is_list(args) ->
          helper_owners =
            Map.get(
              schema_owners,
              local_helper_owner_key(function_name, length(args)),
              MapSet.new()
            )

          {node, merge_owners(owners, helper_owners)}

        {{:., _, [module_ast, :update_projections]}, _, args} = node, owners when is_list(args) ->
          owners =
            if module_tail_from_ast(module_ast) == "Projector" do
              MapSet.put(owners, :core)
            else
              owners
            end

          {node, owners}

        node, owners ->
          case variable_name(node) do
            nil ->
              {node, owners}

            name ->
              {node, merge_owners(owners, Map.get(tainted_var_owners, name, MapSet.new()))}
          end
      end)

    owners
  end

  defp multi_call_target_owners(
         :update_all,
         args,
         schema_owners,
         table_source_owners,
         projection_steps,
         tainted_var_owners
       ) do
    offset = multi_step_offset(args)
    step_name = Enum.at(args, offset)
    query = Enum.at(args, offset + 1)
    updates = Enum.at(args, offset + 2)

    step_name
    |> projection_step_owners(projection_steps)
    |> merge_owners(
      union_owners([query, updates], schema_owners, table_source_owners, tainted_var_owners)
    )
  end

  defp multi_call_target_owners(
         function_name,
         args,
         schema_owners,
         table_source_owners,
         projection_steps,
         tainted_var_owners
       )
       when function_name in [:insert, :update, :delete] do
    offset = multi_step_offset(args)
    step_name = Enum.at(args, offset)
    target = Enum.at(args, offset + 1)

    step_name
    |> projection_step_owners(projection_steps)
    |> merge_owners(union_owners([target], schema_owners, table_source_owners, tainted_var_owners))
  end

  defp multi_call_target_owners(
         :insert_all,
         args,
         schema_owners,
         table_source_owners,
         projection_steps,
         tainted_var_owners
       ) do
    offset = multi_step_offset(args)
    step_name = Enum.at(args, offset)
    schema_or_source = Enum.at(args, offset + 1)
    entries = Enum.at(args, offset + 2)

    step_name
    |> projection_step_owners(projection_steps)
    |> merge_owners(
      union_owners(
        [schema_or_source, entries],
        schema_owners,
        table_source_owners,
        tainted_var_owners
      )
    )
  end

  defp multi_call_target_owners(
         :delete_all,
         args,
         schema_owners,
         table_source_owners,
         projection_steps,
         tainted_var_owners
       ) do
    offset = multi_step_offset(args)
    step_name = Enum.at(args, offset)
    query = Enum.at(args, offset + 1)

    step_name
    |> projection_step_owners(projection_steps)
    |> merge_owners(union_owners([query], schema_owners, table_source_owners, tainted_var_owners))
  end

  defp multi_call_target_owners(
         _function_name,
         _args,
         _schema_owners,
         _table_source_owners,
         _projection_steps,
         _tainted_var_owners
       ),
       do: MapSet.new()

  defp call_has_prefix_contract?(
         function_name,
         args,
         target_owners,
         prefix_contract_var_owners,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         mailglass_config_alias_owners
       ) do
    case final_opts_arg(args, raw_repo_min_args(function_name)) do
      nil ->
        false

      opts ->
        opts
        |> prefix_contract_owners(
          prefix_contract_var_owners,
          verified_prefix_helpers,
          mailglass_repo_aliases,
          mailglass_config_alias_owners
        )
        |> prefix_contract_covers?(target_owners)
    end
  end

  defp multi_call_has_prefix_contract?(
         function_name,
         args,
         target_owners,
         prefix_contract_var_owners,
         verified_prefix_helpers,
         mailglass_repo_aliases,
         mailglass_config_alias_owners
       )
       when function_name in [:insert, :insert_all, :update, :update_all, :delete, :delete_all] do
    case final_opts_arg(args, multi_min_args(function_name, args)) do
      nil ->
        false

      opts ->
        opts
        |> prefix_contract_owners(
          prefix_contract_var_owners,
          verified_prefix_helpers,
          mailglass_repo_aliases,
          mailglass_config_alias_owners
        )
        |> prefix_contract_covers?(target_owners)
    end
  end

  defp multi_call_has_prefix_contract?(
         _function_name,
         _args,
         _target_owners,
         _prefix_contract_var_owners,
         _verified_prefix_helpers,
         _mailglass_repo_aliases,
         _mailglass_config_alias_owners
       ),
       do: false

  defp final_opts_arg(args, minimum_non_opts_args) when length(args) > minimum_non_opts_args do
    List.last(args)
  end

  defp final_opts_arg(_args, _minimum_non_opts_args), do: nil

  defp prefix_contract_owners(
         opts,
         _prefix_contract_var_owners,
         _verified_prefix_helpers,
         _mailglass_repo_aliases,
         mailglass_config_alias_owners
       )
       when is_list(opts) do
    returned_expression_prefix_owners(opts, mailglass_config_alias_owners)
  end

  defp prefix_contract_owners(
         {helper_name, _meta, args},
         _prefix_contract_var_owners,
         verified_prefix_helpers,
         _mailglass_repo_aliases,
         _mailglass_config_alias_owners
       )
       when is_atom(helper_name) and is_list(args) do
    Map.get(verified_prefix_helpers, {helper_name, length(args)}, MapSet.new())
  end

  defp prefix_contract_owners(
         {{:., _, [module_ast, :multi_opts]}, _meta, args},
         _prefix_contract_var_owners,
         _verified_prefix_helpers,
         mailglass_repo_aliases,
         mailglass_config_alias_owners
       )
       when is_list(args) do
    if mailglass_repo_ast?(module_ast, mailglass_repo_aliases) do
      multi_opts_owners(args, mailglass_config_alias_owners)
    else
      MapSet.new()
    end
  end

  defp prefix_contract_owners(
         opts,
         prefix_contract_var_owners,
         _verified_prefix_helpers,
         _mailglass_repo_aliases,
         _mailglass_config_alias_owners
       ) do
    case variable_name(opts) do
      nil -> MapSet.new()
      name -> Map.get(prefix_contract_var_owners, name, MapSet.new())
    end
  end

  defp multi_opts_owners([], _mailglass_config_alias_owners), do: owner_set(:core)

  defp multi_opts_owners([opts | _rest], mailglass_config_alias_owners) do
    case explicit_prefix_override_owners(opts, mailglass_config_alias_owners) do
      :absent -> owner_set(:core)
      {:present, owners} -> owners
    end
  end

  defp explicit_prefix_override_owners(opts, mailglass_config_alias_owners)
       when is_list(opts) do
    if Keyword.keyword?(opts) and Keyword.has_key?(opts, :prefix) do
      {:present,
       configured_prefix_owners(Keyword.get(opts, :prefix), mailglass_config_alias_owners)}
    else
      :absent
    end
  end

  defp explicit_prefix_override_owners(
         {{:., _, [{:__aliases__, _, [:Keyword]}, function_name]}, _meta,
          [_opts, :prefix, prefix_ast]},
         mailglass_config_alias_owners
       )
       when function_name in [:put, :put_new] do
    {:present, configured_prefix_owners(prefix_ast, mailglass_config_alias_owners)}
  end

  defp explicit_prefix_override_owners(
         {:|>, _meta,
          [
            _opts,
            {{:., _, [{:__aliases__, _, [:Keyword]}, function_name]}, _call_meta,
             [:prefix, prefix_ast]}
          ]},
         mailglass_config_alias_owners
       )
       when function_name in [:put, :put_new] do
    {:present, configured_prefix_owners(prefix_ast, mailglass_config_alias_owners)}
  end

  defp explicit_prefix_override_owners(_opts, _mailglass_config_alias_owners) do
    {:present, MapSet.new()}
  end

  defp projection_step_owners(step_name, projection_steps) do
    if projection_step?(step_name, projection_steps), do: owner_set(:core), else: MapSet.new()
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

  defp multi_min_args(function_name, args) when function_name in [:insert, :update, :delete],
    do: multi_step_offset(args) + 2

  defp multi_min_args(function_name, args) when function_name in [:insert_all, :update_all],
    do: multi_step_offset(args) + 3

  defp multi_min_args(:delete_all, args), do: multi_step_offset(args) + 2

  defp multi_step_offset([step_name | _args]) when is_atom(step_name), do: 0
  defp multi_step_offset(_args), do: 1

  defp variable_name({name, _meta, context})
       when is_atom(name) and (is_atom(context) or is_nil(context)),
       do: name

  defp variable_name(_ast), do: nil

  defp raw_repo_ast?({name, _meta, context}, _facade_repo_aliases, _raw_repo_aliases)
       when is_atom(name) and (is_atom(context) or is_nil(context)) do
    not (name |> Atom.to_string() |> String.starts_with?("_"))
  end

  defp raw_repo_ast?({:__aliases__, _, parts} = module_ast, facade_repo_aliases, raw_repo_aliases)
       when is_list(parts) do
    repo_receiver? =
      List.last(parts) == :Repo or
        parts |> Enum.join(".") |> then(&MapSet.member?(raw_repo_aliases, &1))

    repo_receiver? and not facade_repo_ast?(module_ast, facade_repo_aliases)
  end

  defp raw_repo_ast?(_module_ast, _facade_repo_aliases, _raw_repo_aliases), do: false

  defp multi_ast?({:__aliases__, _, [:Ecto, :Multi]}, _multi_aliases), do: true

  defp multi_ast?({:__aliases__, _, parts}, multi_aliases) when is_list(parts) do
    parts
    |> Enum.join(".")
    |> then(&MapSet.member?(multi_aliases, &1))
  end

  defp multi_ast?(_module_ast, _multi_aliases), do: false

  defp raw_repo_trigger({:__aliases__, _, parts}, function_name),
    do: "#{Enum.join(parts, ".")}.#{function_name}"

  defp raw_repo_trigger({name, _meta, context}, function_name)
       when is_atom(name) and (is_atom(context) or is_nil(context)),
       do: "#{name}.#{function_name}"

  defp raw_repo_trigger(_module_ast, function_name), do: "repo.#{function_name}"

  defp multi_trigger({:__aliases__, _, parts}), do: Enum.join(parts, ".")
  defp multi_trigger(_module_ast), do: "Multi"

  defp collect_verified_prefix_helpers(
         ast,
         prefix_helper_functions,
         mailglass_repo_aliases,
         mailglass_config_alias_owners
       ) do
    {_ast, helper_counts} =
      Macro.prewalk(ast, %{}, fn
        {def_type, _meta, [head, body_kw]} = node, helper_counts
        when def_type in [:def, :defp] and is_list(body_kw) ->
          helper_key = function_key_from_head(head)
          body = Keyword.get(body_kw, :do)

          if helper_key && MapSet.member?(prefix_helper_functions, elem(helper_key, 0)) do
            {total, prefixed, owners} =
              Map.get(helper_counts, helper_key, {0, 0, MapSet.new()})

            helper_owners =
              prefix_contract_owners(
                returned_expression(body),
                %{},
                %{},
                mailglass_repo_aliases,
                mailglass_config_alias_owners
              )

            prefixed =
              if empty_owners?(helper_owners), do: prefixed, else: prefixed + 1

            {node,
             Map.put(
               helper_counts,
               helper_key,
               {total + 1, prefixed, merge_owners(owners, helper_owners)}
             )}
          else
            {node, helper_counts}
          end

        node, helper_counts ->
          {node, helper_counts}
      end)

    helper_counts
    |> Enum.reduce(%{}, fn
      {helper_key, {total, prefixed, owners}}, verified when total > 0 and total == prefixed ->
        Map.put(verified, helper_key, owners)

      _entry, verified ->
        verified
    end)
  end

  defp collect_schema_alias_owners(ast, schema_owners) do
    {_ast, alias_owners} =
      Macro.prewalk(ast, %{}, fn
        {:alias, _meta, args} = node, alias_owners ->
          {node, collect_schema_alias_owner(args, alias_owners, schema_owners)}

        node, alias_owners ->
          {node, alias_owners}
      end)

    alias_owners
  end

  defp collect_schema_alias_owner([alias_ast, opts], alias_owners, schema_owners)
       when is_list(opts) do
    as_name = alias_as_name(Keyword.get(opts, :as))
    owners = owners_for_ast(alias_ast, schema_owners, %{}, %{})

    if is_binary(as_name) do
      put_registry_owners(alias_owners, as_name, owners)
    else
      alias_owners
    end
  end

  defp collect_schema_alias_owner(_args, alias_owners, _schema_owners), do: alias_owners

  defp collect_schema_attribute_owners(ast, schema_owners, table_source_owners) do
    {_ast, attribute_owners} =
      Macro.prewalk(ast, %{}, fn
        {:@, _meta, [{attr_name, _attr_meta, [value_ast]}]} = node, attribute_owners
        when is_atom(attr_name) ->
          owners = owners_for_ast(value_ast, schema_owners, table_source_owners, %{})

          {node,
           put_registry_owners(attribute_owners, module_attribute_owner_key(attr_name), owners)}

        node, attribute_owners ->
          {node, attribute_owners}
      end)

    attribute_owners
  end

  defp collect_local_query_helper_owners(ast, schema_owners, table_source_owners) do
    helper_returns = collect_local_helper_returns(ast)
    max_iterations = map_size(helper_returns) + 1

    expand_local_query_helper_owners(
      helper_returns,
      schema_owners,
      table_source_owners,
      %{},
      max_iterations
    )
  end

  defp collect_local_helper_returns(ast) do
    {_ast, helper_returns} =
      Macro.prewalk(ast, %{}, fn
        {def_type, _meta, [head, body_kw]} = node, helper_returns
        when def_type in [:def, :defp] and is_list(body_kw) ->
          case function_key_from_head(head) do
            nil ->
              {node, helper_returns}

            helper_key ->
              body = Keyword.get(body_kw, :do)
              expression = returned_expression(body)

              {node,
               Map.update(helper_returns, helper_key, [expression], fn expressions ->
                 [expression | expressions]
               end)}
          end

        node, helper_returns ->
          {node, helper_returns}
      end)

    helper_returns
  end

  defp expand_local_query_helper_owners(
         _helper_returns,
         _schema_owners,
         _table_source_owners,
         helper_owners,
         0
       ),
       do: helper_owners

  defp expand_local_query_helper_owners(
         helper_returns,
         schema_owners,
         table_source_owners,
         helper_owners,
         iterations_remaining
       ) do
    owner_registry = merge_owner_maps(schema_owners, helper_owners)

    next_helper_owners =
      Enum.reduce(helper_returns, %{}, fn {{function_name, arity}, expressions}, collected ->
        owners = union_owners(expressions, owner_registry, table_source_owners, %{})

        put_registry_owners(collected, local_helper_owner_key(function_name, arity), owners)
      end)

    if next_helper_owners == helper_owners do
      helper_owners
    else
      expand_local_query_helper_owners(
        helper_returns,
        schema_owners,
        table_source_owners,
        next_helper_owners,
        iterations_remaining - 1
      )
    end
  end

  defp function_key_from_head({:when, _meta, [head | _guards]}),
    do: function_key_from_head(head)

  defp function_key_from_head({name, _meta, args}) when is_atom(name) and is_list(args),
    do: {name, length(args)}

  defp function_key_from_head({name, _meta, context})
       when is_atom(name) and (is_atom(context) or is_nil(context)),
       do: {name, 0}

  defp function_key_from_head(_head), do: nil

  defp local_helper_owner_key(function_name, arity), do: {:local_helper, function_name, arity}

  defp module_attribute_owner_key(attribute_name), do: {:module_attribute, attribute_name}

  defp variable_names(ast) do
    {_ast, names} =
      Macro.prewalk(ast, MapSet.new(), fn node, names ->
        case variable_name(node) do
          nil ->
            {node, names}

          name ->
            name_string = Atom.to_string(name)

            if String.starts_with?(name_string, "_") do
              {node, names}
            else
              {node, MapSet.put(names, name)}
            end
        end
      end)

    names
  end

  defp returned_expression({:__block__, _meta, expressions}) when is_list(expressions) do
    expressions
    |> List.last()
    |> returned_expression()
  end

  defp returned_expression(expression), do: expression

  defp returned_expression_prefix_owners(ast, mailglass_config_alias_owners) do
    ast
    |> returned_expression()
    |> do_returned_expression_prefix_owners(mailglass_config_alias_owners)
  end

  defp do_returned_expression_prefix_owners(opts, mailglass_config_alias_owners)
       when is_list(opts) do
    if Keyword.keyword?(opts) do
      configured_prefix_owners(Keyword.get(opts, :prefix), mailglass_config_alias_owners)
    else
      MapSet.new()
    end
  end

  defp do_returned_expression_prefix_owners(
         {{:., _, [{:__aliases__, _, [:Keyword]}, function_name]}, _meta,
          [_opts, :prefix, prefix_ast]},
         mailglass_config_alias_owners
       )
       when function_name in [:put, :put_new] do
    configured_prefix_owners(prefix_ast, mailglass_config_alias_owners)
  end

  defp do_returned_expression_prefix_owners(
         {:|>, _meta,
          [
            _opts,
            {{:., _, [{:__aliases__, _, [:Keyword]}, function_name]}, _call_meta,
             [:prefix, prefix_ast]}
          ]},
         mailglass_config_alias_owners
       )
       when function_name in [:put, :put_new] do
    configured_prefix_owners(prefix_ast, mailglass_config_alias_owners)
  end

  defp do_returned_expression_prefix_owners(_expression, _mailglass_config_alias_owners),
    do: MapSet.new()

  defp configured_prefix_owners(
         {{:., _, [{:__aliases__, _, [:Mailglass, :Config]}, :schema]}, _meta, args},
         _mailglass_config_alias_owners
       )
       when is_list(args),
       do: if(args == [], do: owner_set(:core), else: MapSet.new())

  defp configured_prefix_owners(
         {{:., _, [{:__aliases__, _, [:MailglassInbound, :Config]}, :schema]}, _meta, args},
         _mailglass_config_alias_owners
       )
       when is_list(args),
       do: if(args == [], do: owner_set(:inbound), else: MapSet.new())

  defp configured_prefix_owners(
         {{:., _, [{:__aliases__, _, parts}, :schema]}, _meta, args},
         mailglass_config_alias_owners
       )
       when is_list(parts) and is_list(args) do
    if args == [] do
      Map.get(mailglass_config_alias_owners, Enum.join(parts, "."), MapSet.new())
    else
      MapSet.new()
    end
  end

  defp configured_prefix_owners(_ast, _mailglass_config_alias_owners), do: MapSet.new()

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

    case alias_as_name(Keyword.get(opts, :as)) do
      as_name when alias_string == "Mailglass.Repo" and is_binary(as_name) ->
        MapSet.put(aliases, as_name)

      _other ->
        collect_mailglass_repo_alias([alias_ast], aliases)
    end
  end

  defp collect_mailglass_repo_alias(_args, aliases), do: aliases

  defp collect_facade_repo_aliases(ast) do
    {_ast, aliases} =
      Macro.prewalk(ast, MapSet.new(), fn
        {:alias, _meta, args} = node, aliases ->
          {node, collect_facade_repo_alias(args, aliases)}

        node, aliases ->
          {node, aliases}
      end)

    aliases
  end

  defp collect_facade_repo_alias([alias_ast], aliases) do
    alias_string = Macro.to_string(alias_ast)

    cond do
      alias_string in ["Mailglass.Repo", "MailglassInbound.Repo"] ->
        MapSet.put(aliases, "Repo")

      String.starts_with?(alias_string, "Mailglass.{") and
          Regex.match?(~r/(^|[{\s,])Repo([}\s,]|$)/, alias_string) ->
        MapSet.put(aliases, "Repo")

      String.starts_with?(alias_string, "MailglassInbound.{") and
          Regex.match?(~r/(^|[{\s,])Repo([}\s,]|$)/, alias_string) ->
        MapSet.put(aliases, "Repo")

      true ->
        aliases
    end
  end

  defp collect_facade_repo_alias([alias_ast, opts], aliases) when is_list(opts) do
    alias_string = Macro.to_string(alias_ast)

    case alias_as_name(Keyword.get(opts, :as)) do
      as_name
      when alias_string in ["Mailglass.Repo", "MailglassInbound.Repo"] and is_binary(as_name) ->
        MapSet.put(aliases, as_name)

      _other ->
        collect_facade_repo_alias([alias_ast], aliases)
    end
  end

  defp collect_facade_repo_alias(_args, aliases), do: aliases

  defp collect_raw_repo_aliases(ast) do
    {_ast, aliases} =
      Macro.prewalk(ast, MapSet.new(), fn
        {:alias, _meta, args} = node, aliases ->
          {node, collect_raw_repo_alias(args, aliases)}

        node, aliases ->
          {node, aliases}
      end)

    aliases
  end

  defp collect_raw_repo_alias([alias_ast], aliases) do
    alias_string = Macro.to_string(alias_ast)

    cond do
      alias_string in ["Mailglass.Repo", "MailglassInbound.Repo"] ->
        aliases

      Regex.match?(~r/(^|[.\s{,])Repo([}\s,]|$)/, alias_string) ->
        MapSet.put(aliases, "Repo")

      true ->
        aliases
    end
  end

  defp collect_raw_repo_alias([alias_ast, opts], aliases) when is_list(opts) do
    alias_string = Macro.to_string(alias_ast)

    case alias_as_name(Keyword.get(opts, :as)) do
      as_name
      when alias_string not in ["Mailglass.Repo", "MailglassInbound.Repo"] and
             is_binary(as_name) ->
        if String.ends_with?(alias_string, ".Repo") do
          MapSet.put(aliases, as_name)
        else
          collect_raw_repo_alias([alias_ast], aliases)
        end

      _other ->
        collect_raw_repo_alias([alias_ast], aliases)
    end
  end

  defp collect_raw_repo_alias(_args, aliases), do: aliases

  defp collect_multi_aliases(ast) do
    {_ast, aliases} =
      Macro.prewalk(ast, MapSet.new(["Multi"]), fn
        {:alias, _meta, args} = node, aliases ->
          {node, collect_multi_alias(args, aliases)}

        node, aliases ->
          {node, aliases}
      end)

    aliases
  end

  defp collect_multi_alias([alias_ast], aliases) do
    alias_string = Macro.to_string(alias_ast)

    if alias_string == "Ecto.Multi" do
      MapSet.put(aliases, "Multi")
    else
      aliases
    end
  end

  defp collect_multi_alias([alias_ast, opts], aliases) when is_list(opts) do
    alias_string = Macro.to_string(alias_ast)

    case alias_as_name(Keyword.get(opts, :as)) do
      as_name when alias_string == "Ecto.Multi" and is_binary(as_name) ->
        MapSet.put(aliases, as_name)

      _other ->
        collect_multi_alias([alias_ast], aliases)
    end
  end

  defp collect_multi_alias(_args, aliases), do: aliases

  defp collect_mailglass_config_alias_owners(ast) do
    {_ast, alias_owners} =
      Macro.prewalk(ast, %{}, fn
        {:alias, _meta, args} = node, alias_owners ->
          {node, collect_mailglass_config_alias_owner(args, alias_owners)}

        node, alias_owners ->
          {node, alias_owners}
      end)

    alias_owners
  end

  defp collect_mailglass_config_alias_owner([alias_ast], alias_owners) do
    alias_string = Macro.to_string(alias_ast)

    cond do
      alias_string == "Mailglass.Config" ->
        put_config_alias_owner(alias_owners, "Config", :core)

      alias_string == "MailglassInbound.Config" ->
        put_config_alias_owner(alias_owners, "Config", :inbound)

      String.starts_with?(alias_string, "Mailglass.{") and
          Regex.match?(~r/(^|[{\s,])Config([}\s,]|$)/, alias_string) ->
        put_config_alias_owner(alias_owners, "Config", :core)

      String.starts_with?(alias_string, "MailglassInbound.{") and
          Regex.match?(~r/(^|[{\s,])Config([}\s,]|$)/, alias_string) ->
        put_config_alias_owner(alias_owners, "Config", :inbound)

      true ->
        alias_owners
    end
  end

  defp collect_mailglass_config_alias_owner([alias_ast, opts], alias_owners) when is_list(opts) do
    alias_string = Macro.to_string(alias_ast)

    case alias_as_name(Keyword.get(opts, :as)) do
      as_name when alias_string == "Mailglass.Config" and is_binary(as_name) ->
        put_config_alias_owner(alias_owners, as_name, :core)

      as_name when alias_string == "MailglassInbound.Config" and is_binary(as_name) ->
        put_config_alias_owner(alias_owners, as_name, :inbound)

      _other ->
        collect_mailglass_config_alias_owner([alias_ast], alias_owners)
    end
  end

  defp collect_mailglass_config_alias_owner(_args, alias_owners), do: alias_owners

  defp put_config_alias_owner(alias_owners, alias_name, owner) do
    Map.update(alias_owners, alias_name, owner_set(owner), &MapSet.put(&1, owner))
  end

  defp alias_as_name({:__aliases__, _, parts}) when is_list(parts),
    do: Enum.join(parts, ".")

  defp alias_as_name(name) when is_atom(name), do: Atom.to_string(name)
  defp alias_as_name(_name), do: nil

  defp facade_repo_ast?(
         {:__aliases__, _, [:Mailglass, :Repo]},
         _facade_repo_aliases
       ),
       do: true

  defp facade_repo_ast?(
         {:__aliases__, _, [:MailglassInbound, :Repo]},
         _facade_repo_aliases
       ),
       do: true

  defp facade_repo_ast?({:__aliases__, _, parts}, facade_repo_aliases) when is_list(parts) do
    parts
    |> Enum.join(".")
    |> then(&MapSet.member?(facade_repo_aliases, &1))
  end

  defp facade_repo_ast?(_module_ast, _facade_repo_aliases), do: false

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

  defp schema_owners(schemas) when is_list(schemas) do
    Enum.reduce(schemas, %{}, fn schema, owners ->
      case module_name(schema) do
        nil ->
          owners

        module_name ->
          owner = schema_owner(schema)

          owners
          |> put_registry_owners(module_name, owner_set(owner))
          |> put_registry_owners(module_tail_name(module_name), owner_set(owner))
      end
    end)
  end

  defp table_source_owners(table_sources) when is_list(table_sources) do
    Enum.reduce(table_sources, %{}, fn
      {owner, tables}, owners when owner in [:core, :inbound] and is_list(tables) ->
        Enum.reduce(tables, owners, fn table, acc ->
          Map.update(acc, table, owner_set(owner), &MapSet.put(&1, owner))
        end)

      _entry, owners ->
        owners
    end)
  end

  defp module_name(module) when is_atom(module) do
    module
    |> Atom.to_string()
    |> String.trim_leading("Elixir.")
  end

  defp module_name(other) when is_binary(other), do: other
  defp module_name(_other), do: nil

  defp module_tail_name(module) when is_atom(module) do
    module
    |> module_name()
    |> module_tail_name()
  end

  defp module_tail_name(module) when is_binary(module) do
    module
    |> String.split(".")
    |> List.last()
  end

  defp module_tail_name(_other), do: nil

  defp schema_owner(schema) when is_atom(schema) do
    schema
    |> Atom.to_string()
    |> String.trim_leading("Elixir.")
    |> schema_owner()
  end

  defp schema_owner("MailglassInbound." <> _rest), do: :inbound
  defp schema_owner(_schema), do: :core

  defp module_tail_from_ast({:__aliases__, _, parts}) when is_list(parts) do
    parts |> List.last() |> Atom.to_string()
  end

  defp module_tail_from_ast(_module_ast), do: nil

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
