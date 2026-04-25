defmodule Mailglass.Credo.NoTrackingOnAuthStream do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      auth_name_heuristics: [
        "magic_link",
        "password_reset",
        "verify_email",
        "confirm_account",
        "reset_token",
        "verification_token",
        "confirm_email",
        "two_factor",
        "2fa"
      ],
      mailable_module: Mailglass.Mailable
    ],
    explanations: [
      check: """
      Auth-context mailable functions must not enable open/click tracking.
      """,
      params: [
        auth_name_heuristics: "Function-name fragments treated as auth-context mailables.",
        mailable_module: "Module used to identify mailable modules (`use Mailglass.Mailable`)."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    heuristics =
      params |> Params.get(:auth_name_heuristics, __MODULE__) |> Enum.map(&String.downcase/1)

    mailable_tail = params |> Params.get(:mailable_module, __MODULE__) |> module_tail_name()
    ast = SourceFile.ast(source_file)

    {_ast, state} =
      Macro.traverse(
        ast,
        %{issues: [], module_stack: []},
        &prewalk(&1, &2, issue_meta, heuristics, mailable_tail),
        &postwalk/2
      )

    Enum.reverse(state.issues)
  end

  defp prewalk(
         {:defmodule, _, [module_ast, body_kw]} = ast,
         state,
         _issue_meta,
         _heuristics,
         mailable_tail
       )
       when is_list(body_kw) do
    body = Keyword.get(body_kw, :do)
    mailable? = module_uses_mailable?(body, mailable_tail)
    module_name = module_name(module_ast)

    {ast,
     %{state | module_stack: [%{name: module_name, mailable?: mailable?} | state.module_stack]}}
  end

  defp prewalk({:def, meta, [head, body_kw]} = ast, state, issue_meta, heuristics, _mailable_tail)
       when is_list(body_kw) do
    body = Keyword.get(body_kw, :do)
    current_module = List.first(state.module_stack)

    should_flag? =
      is_map(current_module) and current_module.mailable? and
        auth_context_function?(head, heuristics) and
        function_enables_tracking?(body)

    if should_flag? do
      function_name = function_name(head) |> Atom.to_string()

      issue =
        format_issue(
          issue_meta,
          message:
            "Auth-context mailable function `#{function_name}` must not enable tracking (`tracking:`).",
          trigger: function_name,
          line_no: meta[:line],
          column: meta[:column]
        )

      {ast, %{state | issues: [issue | state.issues]}}
    else
      {ast, state}
    end
  end

  defp prewalk(ast, state, _issue_meta, _heuristics, _mailable_tail), do: {ast, state}

  defp postwalk({:defmodule, _, _} = ast, state) do
    new_stack =
      case state.module_stack do
        [_ | rest] -> rest
        [] -> []
      end

    {ast, %{state | module_stack: new_stack}}
  end

  defp postwalk(ast, state), do: {ast, state}

  defp module_uses_mailable?(nil, _mailable_tail), do: false

  defp module_uses_mailable?(body, mailable_tail) do
    {_ast, found?} =
      Macro.prewalk(body, false, fn
        {:use, _, [module_ast | _]} = node, false ->
          if module_tail_from_ast(module_ast) == mailable_tail,
            do: {node, true},
            else: {node, false}

        node, found? ->
          {node, found?}
      end)

    found?
  end

  defp auth_context_function?(head, heuristics) do
    case function_name(head) do
      name when is_atom(name) ->
        function_string = name |> Atom.to_string() |> String.downcase()
        Enum.any?(heuristics, &String.contains?(function_string, &1))

      _ ->
        false
    end
  end

  defp function_name({:when, _, [head | _guards]}), do: function_name(head)
  defp function_name({name, _, _args}) when is_atom(name), do: name
  defp function_name(_), do: nil

  defp function_enables_tracking?(nil), do: false

  defp function_enables_tracking?(body) do
    {_ast, enabled?} =
      Macro.prewalk(body, false, fn node, enabled? ->
        if enabled? do
          {node, true}
        else
          {node, node_enables_tracking?(node)}
        end
      end)

    enabled?
  end

  defp node_enables_tracking?(list) when is_list(list) do
    if Keyword.keyword?(list) do
      case Keyword.fetch(list, :tracking) do
        {:ok, value} -> tracking_enabled_value?(value)
        :error -> false
      end
    else
      false
    end
  end

  defp node_enables_tracking?({:%{}, _, pairs}) when is_list(pairs) do
    case Enum.find_value(pairs, :missing, fn
           {:tracking, value} -> {:ok, value}
           _ -> false
         end) do
      {:ok, value} -> tracking_enabled_value?(value)
      _ -> false
    end
  end

  defp node_enables_tracking?(_), do: false

  defp tracking_enabled_value?(false), do: false
  defp tracking_enabled_value?(nil), do: false
  defp tracking_enabled_value?([]), do: false

  defp tracking_enabled_value?(list) when is_list(list) do
    if Keyword.keyword?(list) do
      Enum.any?(list, fn {_key, value} -> tracking_enabled_value?(value) end)
    else
      true
    end
  end

  defp tracking_enabled_value?({:%{}, _, pairs}) when is_list(pairs) do
    Enum.any?(pairs, fn
      {_key, value} -> tracking_enabled_value?(value)
      _ -> false
    end)
  end

  defp tracking_enabled_value?(_), do: true

  defp module_name({:__aliases__, _, parts}) when is_list(parts), do: Module.concat(parts)
  defp module_name(_ast), do: nil

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
end
