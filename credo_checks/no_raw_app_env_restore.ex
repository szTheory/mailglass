defmodule Mailglass.Credo.NoRawAppEnvRestore do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      allowed_modules: [
        Mailglass.TestSupport.SandboxOwnership,
        Mailglass.TestSupport.SandboxOwnershipTest
      ],
      included_path_prefixes: ["test/", "mailglass_inbound/test/"]
    ],
    explanations: [
      check: """
      Test code restores Application env through
      `Mailglass.TestSupport.SandboxOwnership.with_app_env!/2`, never through
      `Application.put_all_env/1`.

      `Application.put_all_env/1` MERGES. It writes every key in the list it is
      given and touches nothing else, so it is structurally incapable of
      removing a key the test ADDED — a key absent from the captured snapshot
      is absent from the write set, and the test's value survives into every
      later module in the run. The idiom reads like a restore and is one only
      for keys that already existed.

      That is not a hypothetical. Seven `test/` modules used it as their
      restore, and all seven set `config :mailglass, :compliance`, which is in
      no `config/*.exs` — so all seven leaked it on every run. Two also install
      a `@behaviour Mailglass.Tenancy` resolver whose `scope/2` applies
      `as: :scoped`, and Mailglass.Operator.SupportSummary's private
      orphan_backlog_summary/2 (not backticked: ExDoc auto-links a `Mod.fun/arity`
      reference and `--warnings-as-errors` then fails on the private target)
      builds a query already aliased `as: :orphan`, so a leaked resolver turns
      every later caller into `** (Ecto.Query.CompileError) can't apply alias
      :scoped, binding in from is already aliased to :orphan`. Observed in CI
      run 30571989203 on a DOCS-ONLY commit, and green two commits later with
      `lib/` byte-identical.

      `with_app_env!/2` re-puts every captured key AND deletes every key that
      appeared since the capture, then verifies the result — the step
      `put_all_env/1` cannot express.

      ## What this check deliberately does NOT catch

      The same bug also wears a second syntax: `prior = Application.get_env(app,
      key)` followed by `Application.put_env(app, key, prior)`, which CREATES
      the key holding `nil` when it was absent, rather than removing it. That
      is not statically decidable — whether `prior` can be `nil` depends on
      runtime config — so this check does not guess at it. The narrow, always-
      wrong idiom is caught here; the general case is a review concern, and
      `with_app_env!/2` is the answer to both.
      """,
      params: [
        allowed_modules:
          "Modules explicitly allowed to reference Application.put_all_env/1 directly.",
        included_path_prefixes: "Only files in these path prefixes are linted."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      allowed_modules = params |> Params.get(:allowed_modules, __MODULE__) |> MapSet.new()

      {_ast, state} =
        Macro.traverse(
          SourceFile.ast(source_file),
          %{issues: [], module_stack: []},
          &prewalk(&1, &2, issue_meta, allowed_modules),
          &postwalk/2
        )

      Enum.reverse(state.issues)
    else
      []
    end
  end

  defp prewalk({:defmodule, _, [module_ast, _]} = ast, state, _issue_meta, _allowed) do
    {ast, %{state | module_stack: [module_name(module_ast) | state.module_stack]}}
  end

  # Matches `Application.put_all_env(...)` written either fully qualified or
  # through an `alias Application` (which nothing in this repo does, but the
  # tail check costs nothing and closes the obvious bypass). Resolution is
  # strictly by module tail `Application` — there is no bare-function fallback,
  # deliberately: a locally defined `put_all_env/1` helper in some future test
  # module is not this bug, and flagging it would teach maintainers to distrust
  # the check. See `Mailglass.Credo.NoRawSandboxOwnership`'s own note for the
  # same reasoning applied to `Sandbox`.
  defp prewalk(
         {{:., _, [module_ast, :put_all_env]}, meta, _args} = ast,
         state,
         issue_meta,
         allowed_modules
       ) do
    current_module = List.first(state.module_stack)

    if application_module_ast?(module_ast) and
         not MapSet.member?(allowed_modules, current_module) do
      issue =
        format_issue(
          issue_meta,
          message:
            "Delivery blocked: `Application.put_all_env/1` used in test code. That function " <>
              "MERGES — it can never remove a key the test added, so it is not a restore. " <>
              "Use `Mailglass.TestSupport.SandboxOwnership.with_app_env!/2`, which re-puts " <>
              "every captured key, deletes every key added since capture, and verifies the " <>
              "result.",
          trigger: "Application.put_all_env",
          line_no: meta[:line],
          column: meta[:column]
        )

      {ast, %{state | issues: [issue | state.issues]}}
    else
      {ast, state}
    end
  end

  defp prewalk(ast, state, _issue_meta, _allowed), do: {ast, state}

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

  defp application_module_ast?({:__aliases__, _, parts}) when is_list(parts) do
    List.last(parts) == :Application
  end

  defp application_module_ast?(_ast), do: false

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
