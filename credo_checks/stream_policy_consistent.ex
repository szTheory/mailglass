defmodule Mailglass.Credo.StreamPolicyConsistent do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      mailable_module: Mailglass.Mailable,
      included_path_prefixes: ["lib/mailglass/", "mailglass_inbound/lib/"]
    ],
    explanations: [
      check: """
      Mailable tracking requires an explicit `:bulk` or `:operational` stream.
      """,
      params: [
        mailable_module: "Module used to identify mailable modules (`use Mailglass.Mailable`).",
        included_path_prefixes:
          "Only files in these path prefixes are linted. Scoped to production mailables; " <>
            "test fixtures deliberately declare tracking on `:transactional` to exercise the " <>
            "runtime auth-stream guard, so linting them would be a false positive."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      mailable_tail = params |> Params.get(:mailable_module, __MODULE__) |> module_tail_name()

      ast = SourceFile.ast(source_file)

      {_ast, issues} =
        Macro.traverse(
          ast,
          [],
          &prewalk(&1, &2, issue_meta, mailable_tail),
          fn ast, state -> {ast, state} end
        )

      Enum.reverse(issues)
    else
      []
    end
  end

  defp prewalk({:use, meta, [module_ast, opts]} = ast, issues, issue_meta, mailable_tail)
       when is_list(opts) do
    if module_tail_from_ast(module_ast) == mailable_tail do
      if node_enables_tracking?(opts) do
        stream_val = Keyword.get(opts, :stream)

        if is_nil(stream_val) or stream_val == :transactional do
          issue =
            format_issue(
              issue_meta,
              message: "Mailable tracking requires an explicit `:bulk` or `:operational` stream.",
              line_no: meta[:line],
              column: meta[:column]
            )

          {ast, [issue | issues]}
        else
          {ast, issues}
        end
      else
        {ast, issues}
      end
    else
      {ast, issues}
    end
  end

  defp prewalk(ast, state, _issue_meta, _mailable_tail), do: {ast, state}

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

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
