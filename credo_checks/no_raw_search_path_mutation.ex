defmodule Mailglass.Credo.NoRawSearchPathMutation do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      allowed_modules: [
        Mailglass.TestSupport.SandboxOwnership,
        Mailglass.TestSupport.SandboxOwnershipTest,
        Mailglass.Credo.NoRawSearchPathMutationTest
      ],
      included_path_prefixes: ["test/", "mailglass_inbound/test/"],
      match_target_functions: [:=~, :contains?]
    ],
    explanations: [
      check: """
      Test code MUST NOT issue a raw `search_path` mutation as SQL. Route it
      through `Mailglass.TestSupport.SandboxOwnership.with_search_path!/3`,
      which pins ONE pooled connection for the whole block, restores the prior
      value on that same connection, and then RE-READS it to verify the restore
      actually landed.

      ## The failure mode, by name

      `SET search_path TO public` without `LOCAL` is a SESSION-level write: it
      persists on the physical Postgres connection for that connection's entire
      lifetime. Under Sandbox `:auto` mode every `Repo.query` checks a
      connection out of the 10-slot pool and returns it, so the poisoned
      connection goes straight back into the pool. `config/test.exs` +
      `test/test_helper.exs` give pool connections a startup `search_path` of
      `"<schema>, public"`, and the whole rest of the suite relies on it to
      resolve unqualified relation names.

      The result is **pool poisoning**: some later, wholly unrelated test draws
      the poisoned connection and raises
      `(Postgrex.Error) ERROR 42P01 (undefined_table) relation
      "mailglass_deliveries" does not exist` — a failure attributed to an
      innocent module hundreds of tests away from the one that broke it. This is
      not hypothetical: it is the confirmed root cause of the D-31 Class A
      cascade on the `MAILGLASS_SCHEMA=mailglass` axis (seven victim modules,
      two full misdiagnosis cycles). A throwaway probe confirmed it directly —
      after ONE unscoped `SET search_path TO public`, all 40 subsequent pool
      checkouts observed `"public"`.

      A trailing `RESET search_path` from `on_exit` does NOT undo it: that is a
      SEPARATE pool checkout that lands on whichever connection it lands on,
      which need not be the poisoned one.

      ## What is banned, and why each form

      Every form below is banned in SQL-statement position under `test/`:

        * `SET search_path ...` — session-scoped. The defect above.
        * `SET SESSION search_path ...` — an explicit spelling of the same
          session-scoped write.
        * `SET LOCAL search_path ...` — transaction-scoped, and therefore
          *looks* safe. It is not safe inside a migration: `SET LOCAL` persists
          for the remainder of the transaction, and `Ecto.Migrator` inserts its
          `schema_migrations` version row INSIDE that same transaction, AFTER
          the migration body. The pin redirects Ecto's own bookkeeping INSERT to
          a `search_path` holding no `schema_migrations` table, raising
          `42P01 ... relation "schema_migrations" does not exist`. Observed
          live: `MAILGLASS_SCHEMA=mailglass mix test
          test/mailglass/shipped_migration_divergence_test.exs` failed 4 tests /
          4 failures on exactly this.
        * `RESET search_path` — cannot poison (it restores the startup-packet
          value), but from `:auto` mode it is its own checkout on an arbitrary
          pooled connection, so it heals nothing observable while reading as a
          fix. A guard that reads as a guarantee without being one is the exact
          credibility failure this milestone exists to repair.
        * `set_config('search_path', ...)` — the function-call spelling of a
          session-level `SET`, banned for the same reason as the first form.

      ## What is permitted

        * `SHOW search_path` — read-only.
        * `search_path` in the Postgrex `:parameters` connection option
          (`test/test_helper.exs`) — that is the connection's STARTUP value, set
          once at pool-connect time on every connection, which is precisely the
          invariant the bans above protect.
        * `SET search_path = ''` as a `CREATE FUNCTION` attribute clause — a
          different construct entirely (it hardens a function body against
          search-path injection, and is not a session write). It is never in
          statement-initial position inside a `CREATE FUNCTION` statement, so it
          does not match.
        * The same literals as ASSERTION MATCH TARGETS (`body =~ "SET
          search_path = ''"`, `String.contains?/2`). A match target is compared,
          never executed, so it cannot poison anything. See
          `:match_target_functions`.
        * Anything inside `Mailglass.TestSupport.SandboxOwnership` — the one
          sanctioned seam, which owns the same-connection, verified restore —
          its own mechanism test, and this check's own fixture corpus. Those
          three modules are the whole allowlist; see `.credo.exs` for the
          per-entry justification.

      ## Two-layer guard

      This is the PREVENTION half. The detection half is
      `Mailglass.TestSupport.SandboxOwnership.with_search_path!/3`'s post-restore
      re-read, which raises `SearchPathError` naming the offending module. The
      D-31 Class A cascade recurred precisely because detection shipped without
      prevention.
      """,
      params: [
        allowed_modules:
          "Modules explicitly allowed to issue raw `search_path` mutations (the sanctioned seam and its own test).",
        included_path_prefixes: "Only files in these path prefixes are linted.",
        match_target_functions:
          "Function/operator names whose arguments are assertion MATCH TARGETS rather than executed SQL."
      ]
    ]

  # A `search_path` mutation only counts when it opens a SQL statement — the
  # start of the literal, or immediately after a `;`. This is what keeps the
  # `CREATE FUNCTION ... SET search_path = ''` attribute clause (a different
  # construct, see the moduledoc) out of scope without an allowlist entry.
  @statement_initial_patterns [
    {~r/\ASET\s+(?:LOCAL\s+|SESSION\s+)?search_path\b/i, "SET search_path"},
    {~r/\ARESET\s+search_path\b/i, "RESET search_path"},
    # `set_config('search_path', ...)` is a session-level write wearing a
    # function call. It is never statement-initial itself, so it is anchored to
    # the statement that invokes it — which keeps a bare mention of the function
    # name in prose or a keyword list out of scope.
    {~r/\A(?:SELECT|PERFORM)\b[^;]*\bset_config\s*\(\s*['"]search_path['"]/i,
     "set_config('search_path', ...)"}
  ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      run_included(source_file, params)
    else
      []
    end
  end

  # FAIL-CLOSED (D-31): a file this check is responsible for but cannot parse
  # is NOT a pass. Credo sets `status: :invalid` and hands `run/2` an empty AST
  # when `Code.string_to_quoted/2` fails — traversing that empty AST would find
  # nothing and report green for a file whose contents were never observed.
  # Report the non-observation as an issue instead.
  defp run_included(%SourceFile{status: status} = source_file, params) when status != :valid do
    [
      format_issue(
        IssueMeta.for(source_file, params),
        message:
          "Delivery blocked: Mailglass.Credo.NoRawSearchPathMutation could not parse this " <>
            "file (status #{inspect(status)}), so it could not observe whether the file " <>
            "issues a raw `search_path` mutation. A check that cannot observe its subject " <>
            "must never report success.",
        trigger: "unparsable-source",
        line_no: 1
      )
    ]
  end

  defp run_included(%SourceFile{} = source_file, params) do
    ctx = %{
      issue_meta: IssueMeta.for(source_file, params),
      allowed_modules: params |> Params.get(:allowed_modules, __MODULE__) |> MapSet.new(),
      match_target_functions:
        params |> Params.get(:match_target_functions, __MODULE__) |> MapSet.new()
    }

    {_ast, state} =
      Macro.traverse(
        SourceFile.ast(source_file),
        %{issues: [], module_stack: [], line: 1},
        &prewalk(&1, &2, ctx),
        &postwalk/2
      )

    Enum.reverse(state.issues)
  end

  defp prewalk(ast, state, ctx), do: do_prewalk(ast, track_line(ast, state), ctx)

  defp do_prewalk({:defmodule, _meta, [module_ast, _body]} = ast, state, _ctx) do
    {ast, %{state | module_stack: [module_name(module_ast) | state.module_stack]}}
  end

  # An assertion match target is compared, never executed. Scrub the literal
  # arguments so the clauses below never see them — this is the ONLY carve-out,
  # and it is positional rather than an allowlist of files.
  defp do_prewalk({fun_ast, meta, args} = ast, state, ctx) when is_list(args) do
    if match_target_call?(fun_ast, ctx.match_target_functions) do
      {{fun_ast, meta, Enum.map(args, &scrub_literal/1)}, state}
    else
      maybe_flag_interpolated(ast, state, ctx)
    end
  end

  defp do_prewalk(ast, state, ctx) when is_binary(ast) do
    {ast, flag_matches(ast, state, ctx)}
  end

  defp do_prewalk(ast, state, _ctx), do: {ast, state}

  # `"SET search_path TO #{prior}"` and `~s|...|` both compile to a `<<>>` node
  # whose literal segments carry the SQL. Check the joined literal segments,
  # then scrub them so the bare-binary clause cannot double-report the same
  # statement. Interpolation is the MOST likely re-typing of this defect
  # (`SET search_path TO #{schema}`), so missing it would gut the check.
  defp maybe_flag_interpolated({:<<>>, meta, parts}, state, ctx) when is_list(parts) do
    state = flag_matches(literal_segments(parts), state, ctx)
    {{:<<>>, meta, Enum.map(parts, &scrub_literal/1)}, state}
  end

  defp maybe_flag_interpolated(ast, state, _ctx), do: {ast, state}

  defp literal_segments(parts) do
    parts
    |> Enum.filter(&is_binary/1)
    |> Enum.join(" ")
  end

  defp flag_matches(literal, state, ctx) when is_binary(literal) do
    if MapSet.member?(ctx.allowed_modules, List.first(state.module_stack)) do
      state
    else
      literal
      |> forbidden_triggers()
      |> Enum.reduce(state, fn trigger, acc ->
        %{acc | issues: [issue(trigger, acc.line, ctx.issue_meta) | acc.issues]}
      end)
    end
  end

  defp forbidden_triggers(literal) do
    literal
    |> String.split(";")
    |> Enum.map(&String.trim_leading/1)
    |> Enum.flat_map(fn statement ->
      for {regex, trigger} <- @statement_initial_patterns,
          Regex.match?(regex, statement),
          do: trigger
    end)
    |> Enum.uniq()
  end

  defp issue(trigger, line_no, issue_meta) do
    format_issue(
      issue_meta,
      message:
        "Delivery blocked: raw `#{trigger}` in test code. A session-level `search_path` " <>
          "write persists on the pooled Postgres connection for its whole lifetime, so the " <>
          "connection returns to the pool poisoned and some later, unrelated test fails " <>
          "with `42P01 (undefined_table)` — the innocent-victim misattribution D-31 Class A " <>
          "cost two diagnosis cycles. `SET LOCAL` is not the escape hatch either: it " <>
          "survives to the end of the transaction and breaks Ecto's own " <>
          "`schema_migrations` bookkeeping INSERT. Use " <>
          "`Mailglass.TestSupport.SandboxOwnership.with_search_path!/3`, which pins one " <>
          "connection, restores it, and verifies the restore landed.",
      trigger: trigger,
      line_no: line_no
    )
  end

  defp match_target_call?({:., _meta, [_module_ast, name]}, names) when is_atom(name),
    do: MapSet.member?(names, name)

  defp match_target_call?(name, names) when is_atom(name), do: MapSet.member?(names, name)
  defp match_target_call?(_fun_ast, _names), do: false

  defp scrub_literal(literal) when is_binary(literal), do: :__match_target__
  defp scrub_literal({:<<>>, meta, _parts}), do: {:<<>>, meta, []}
  defp scrub_literal(ast), do: ast

  # Bare string literals carry no metadata of their own, so an issue reported
  # against one has no line number to name. Carry the nearest enclosing node's
  # line forward through the depth-first pre-order walk instead — that is the
  # line of the call the literal is an argument to, which is exactly the line a
  # reader needs.
  defp track_line({_fun, meta, _args}, state) when is_list(meta) do
    case Keyword.get(meta, :line) do
      line when is_integer(line) -> %{state | line: line}
      _ -> state
    end
  end

  defp track_line(_ast, state), do: state

  defp postwalk({:defmodule, _meta, _args} = ast, state) do
    new_stack =
      case state.module_stack do
        [_ | rest] -> rest
        [] -> []
      end

    {ast, %{state | module_stack: new_stack}}
  end

  defp postwalk(ast, state), do: {ast, state}

  defp module_name({:__aliases__, _meta, parts}) when is_list(parts), do: Module.concat(parts)
  defp module_name(_ast), do: nil

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
