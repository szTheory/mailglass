defmodule Mailglass.Credo.NoOtherAppEnvReads do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      allowed_apps: [:mailglass],
      included_path_prefixes: ["lib/mailglass/"],
      watched_functions: [:get_env, :fetch_env, :fetch_env!]
    ],
    explanations: [
      check: """
      Mailglass library code must not read other applications' env via
      `Application.get_env*` / `fetch_env*`.
      """,
      params: [
        allowed_apps: "Application atoms allowed as the first argument.",
        included_path_prefixes: "Only files in these path prefixes are linted.",
        watched_functions: "Application env reader functions this check inspects."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      allowed_apps = params |> Params.get(:allowed_apps, __MODULE__) |> MapSet.new()
      watched_functions = params |> Params.get(:watched_functions, __MODULE__) |> MapSet.new()

      source_file
      |> SourceFile.ast()
      |> Macro.postwalk([], fn node, issues ->
        {node, maybe_collect_issue(node, issues, issue_meta, allowed_apps, watched_functions)}
      end)
      |> elem(1)
      |> Enum.reverse()
    else
      []
    end
  end

  defp maybe_collect_issue(
         {{:., _, [{:__aliases__, _, [:Application]}, function_name]}, meta, args},
         issues,
         issue_meta,
         allowed_apps,
         watched_functions
       )
       when is_atom(function_name) and is_list(args) do
    with true <- MapSet.member?(watched_functions, function_name),
         [app | _rest] <- args,
         app when is_atom(app) <- app,
         false <- MapSet.member?(allowed_apps, app) do
      issue =
        format_issue(
          issue_meta,
          message:
            "Application env reads in mailglass library code must use one of #{inspect(MapSet.to_list(allowed_apps))}, got `#{inspect(app)}`.",
          trigger: "Application.#{function_name}",
          line_no: meta[:line],
          column: meta[:column]
        )

      [issue | issues]
    else
      _ -> issues
    end
  end

  defp maybe_collect_issue(_node, issues, _issue_meta, _allowed_apps, _watched_functions),
    do: issues

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
