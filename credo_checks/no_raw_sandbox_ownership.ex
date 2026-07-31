defmodule Mailglass.Credo.NoRawSandboxOwnership do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      allowed_modules: [
        Mailglass.TestSupport.SandboxOwnership,
        Mailglass.TestSupport.SandboxOwnershipTest
      ],
      included_path_prefixes: ["test/"],
      forbidden_functions: [:mode, :start_owner!, :stop_owner, :checkout, :checkin]
    ],
    explanations: [
      check: """
      Test code acquires and releases Ecto Sandbox pool ownership through
      `Mailglass.TestSupport.SandboxOwnership`, not through
      `Ecto.Adapters.SQL.Sandbox` directly.

      Both confirmed HARNESS-01 leak sites (`test/support/mailer_case.ex` and
      `test/mailglass/properties/webhook_idempotency_convergence_test.exs`)
      shared one shape: acquire, then work that can raise, then register the
      release — with the release registered last, so a raise in the middle
      loses it entirely. `SandboxOwnership.checkout!/1` makes that ordering
      structurally impossible to re-type by registering the release on the
      statement immediately following acquisition. A raw `Sandbox.start_owner!`/
      `Sandbox.mode`/`Sandbox.checkout` call outside the sanctioned door can
      reintroduce the exact ordering bug this check exists to prevent.
      """,
      params: [
        allowed_modules:
          "Modules explicitly allowed to call Ecto.Adapters.SQL.Sandbox's ownership functions directly.",
        included_path_prefixes: "Only files in these path prefixes are linted.",
        forbidden_functions:
          "Ecto.Adapters.SQL.Sandbox function names that are disallowed outside the door."
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
      sandbox_aliases = collect_sandbox_aliases(ast)

      {_ast, state} =
        Macro.traverse(
          ast,
          %{issues: [], module_stack: []},
          &prewalk(&1, &2, issue_meta, allowed_modules, forbidden_functions, sandbox_aliases),
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
         _sandbox_aliases
       ) do
    {ast, %{state | module_stack: [module_name(module_ast) | state.module_stack]}}
  end

  defp prewalk(
         {{:., _, [module_ast, function_name]}, meta, _args} = ast,
         state,
         issue_meta,
         allowed_modules,
         forbidden_functions,
         sandbox_aliases
       )
       when is_atom(function_name) do
    current_module = List.first(state.module_stack)

    if sandbox_module_ast?(module_ast, sandbox_aliases) and
         MapSet.member?(forbidden_functions, function_name) and
         not MapSet.member?(allowed_modules, current_module) do
      issue =
        format_issue(
          issue_meta,
          message:
            "Delivery blocked: raw `Ecto.Adapters.SQL.Sandbox.#{function_name}` call outside " <>
              "the sanctioned door. Acquire/release ownership through " <>
              "`Mailglass.TestSupport.SandboxOwnership` instead (`checkout!/1`, " <>
              "`unsandboxed_module/1`, or `unsandboxed/2`).",
          trigger: "Sandbox.#{function_name}",
          line_no: meta[:line],
          column: meta[:column]
        )

      {ast, %{state | issues: [issue | state.issues]}}
    else
      {ast, state}
    end
  end

  defp prewalk(
         ast,
         state,
         _issue_meta,
         _allowed_modules,
         _forbidden_functions,
         _sandbox_aliases
       ),
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

  @sandbox_parts ["Ecto", "Adapters", "SQL", "Sandbox"]

  # Deliberate non-copy of `Mailglass.Credo.NoRawSwooshSendInLib`'s bare-tail
  # fallback: that check also matches ANY module whose tail is "Mailer", even
  # without a resolving alias. This check does NOT fall back that way. `test/`
  # today has no other module whose tail is `Sandbox`, but a bare-tail
  # fallback would flag a future, unrelated `Sandbox` module and teach
  # maintainers to distrust the check — the exact credibility loss this
  # milestone is repairing. Resolution here is strictly through an explicit
  # `alias Ecto.Adapters.SQL.Sandbox` (bare or `as:`-renamed) or a
  # fully-qualified `Ecto.Adapters.SQL.Sandbox.<fn>` call.
  defp sandbox_module_ast?(module_ast, sandbox_aliases) do
    module_parts_from_ast(module_ast) == @sandbox_parts or
      MapSet.member?(sandbox_aliases, module_tail_from_ast(module_ast))
  end

  defp collect_sandbox_aliases(ast) do
    {_ast, aliases} =
      Macro.prewalk(ast, MapSet.new(), fn
        {:alias, _, [module_ast]} = node, aliases ->
          {node, maybe_put_sandbox_alias(aliases, module_ast, [])}

        {:alias, _, [module_ast, opts]} = node, aliases when is_list(opts) ->
          {node, maybe_put_sandbox_alias(aliases, module_ast, opts)}

        node, aliases ->
          {node, aliases}
      end)

    aliases
  end

  defp maybe_put_sandbox_alias(aliases, module_ast, opts) do
    if module_parts_from_ast(module_ast) == @sandbox_parts do
      MapSet.put(aliases, alias_name_from_opts(opts) || "Sandbox")
    else
      aliases
    end
  end

  # NOTE: `Keyword.get(opts, :as)` returns `nil` both when `:as` is absent
  # (the bare `alias Ecto.Adapters.SQL.Sandbox` form) AND would, if matched by
  # a bare `name when is_atom(name)` clause, satisfy that guard — `nil` is
  # itself an atom. Excluding it explicitly is load-bearing here: this check
  # (unlike its Swoosh analog) has no bare-tail fallback to mask the bug, so
  # the caller's `|| "Sandbox"` must actually see `nil`, not the string
  # `"nil"`, to fall through to the bare-tail default.
  defp alias_name_from_opts(opts) when is_list(opts) do
    case Keyword.get(opts, :as) do
      {:__aliases__, _, parts} when is_list(parts) -> parts |> List.last() |> Atom.to_string()
      name when is_atom(name) and not is_nil(name) -> Atom.to_string(name)
      _ -> nil
    end
  end

  defp alias_name_from_opts(_opts), do: nil

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
