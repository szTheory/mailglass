defmodule Mailglass.Credo.NoSchemaPrefixAttribute do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      included_path_prefixes: ["lib/mailglass/"]
    ],
    explanations: [
      check: """
      Modules under `lib/mailglass/` must not declare a `@schema` `@prefix`
      module attribute (the Ecto read-side schema-prefix attribute).

      mailglass resolves the Postgres schema at RUNTIME through the facade
      (`Mailglass.Config.schema/0`), which injects the prefix into every
      Repo call and migration. A compile-time attribute pins the read side to a
      single baked-in schema and inverts the read-vs-write prefix precedence
      that the runtime facade guarantees (decision 6): reads would resolve
      against the attribute value while writes/migrations resolve against
      `Mailglass.Config.schema/0`. Delete the attribute and let the facade inject the
      prefix.
      """,
      params: [
        included_path_prefixes: "Only files in these path prefixes are linted."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      ast = SourceFile.ast(source_file)

      {_ast, issues} =
        Macro.prewalk(ast, [], fn node, acc ->
          {node, maybe_collect_issue(node, acc, issue_meta)}
        end)

      Enum.reverse(issues)
    else
      []
    end
  end

  # Matches an `@schema` + `@prefix`-style module-attribute DEFINITION node:
  # the AST for `@<name> <value>` is `{:@, meta, [{<name>, _, [value]}]}` where
  # the inner tuple's third element is a non-nil arg list (an assignment). A bare
  # reference `@<name>` has `nil` there, so this only fires on declarations.
  defp maybe_collect_issue(
         {:@, meta, [{attr_name, _, args}]},
         issues,
         issue_meta
       )
       when attr_name == :schema_prefix and is_list(args) do
    issue =
      format_issue(
        issue_meta,
        message:
          "`@#{attr_name}` is forbidden: mailglass injects the schema prefix at " <>
            "runtime via `Mailglass.Config.schema/0`; a compile-time attribute inverts " <>
            "read-vs-write prefix precedence (decision 6). Delete it.",
        trigger: "@#{attr_name}",
        line_no: meta[:line],
        column: meta[:column]
      )

    [issue | issues]
  end

  defp maybe_collect_issue(_node, issues, _issue_meta), do: issues

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
