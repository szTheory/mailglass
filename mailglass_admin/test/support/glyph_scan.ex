defmodule MailglassAdmin.TestSupport.GlyphScan do
  @moduledoc """
  Pure text scan for the admin glyph contract (test environment only; Phase 181
  D-13 and D-17).

  The module is compiled from `test/support` (`elixirc_paths(:test)`), so it
  never ships in the Hex tarball and adds no dependency.

  `rendered_strings/2` extracts the text a source file can put on a screen and
  `offending/2` reports every code point in that text a predicate rejects. The
  scan reads source text through the Elixir parser, not through a file list, so
  a string added to any admin `lib` file later is covered without editing a
  list.

    * `:ex` sources are parsed with `Code.string_to_quoted!/2` and a
      `literal_encoder`, so every literal carries its line. Binary literals,
      interpolated binary fragments and `~H` sigil content are collected. The
      bodies of `@doc`, `@moduledoc` and `@typedoc` are skipped, and comments are
      not part of the AST. A `<%!-- ... --%>` HEEx comment inside a `~H` sigil is
      removed because the HEEx engine never renders it.
    * `:heex` sources are scanned as a whole with `<%!-- ... --%>` comments
      removed.

  Both kinds return one `{line, text}` pair per non-empty source line, so a
  finding names the exact line. The line is exact except after a multi-line
  interpolation inside an interpolated heredoc, where it is the line the
  fragment started on plus the newlines seen so far.

  The scan treats every remaining binary as rendered text (conservative): a log
  or error message with an undrawable character is reported too, and the fix is
  to change the character or to allow-list the deliberate case with a reason in
  the calling test.
  """

  @doc_attributes [:doc, :moduledoc, :typedoc]
  @heex_sigils [:sigil_H, :sigil_L]

  @typedoc "A source line and the rendered text on it."
  @type line_text :: {pos_integer(), String.t()}

  @doc """
  Returns the rendered text of `source` as `{line, text}` pairs.

  `kind` is `:ex` for Elixir source and `:heex` for a `.heex` template.
  """
  @spec rendered_strings(String.t(), :ex | :heex) :: [line_text()]
  def rendered_strings(source, :ex) when is_binary(source) do
    source
    |> Code.string_to_quoted!(
      literal_encoder: &{:ok, {:__block__, &2, [&1]}},
      token_metadata: true
    )
    |> collect([])
    |> Enum.reverse()
  end

  def rendered_strings(source, :heex) when is_binary(source) do
    source
    |> strip_heex_comments()
    |> add_lines(1, [])
    |> Enum.reverse()
  end

  @doc """
  Returns `{line, codepoint}` for every code point in `strings` that `allowed?`
  rejects, in source order.
  """
  @spec offending([line_text()], (non_neg_integer() -> boolean())) ::
          [{pos_integer(), non_neg_integer()}]
  def offending(strings, allowed?) when is_function(allowed?, 1) do
    for {line, text} <- strings,
        codepoint <- String.to_charlist(text),
        not allowed?.(codepoint),
        do: {line, codepoint}
  end

  @doc """
  Returns every icon name used as `hero-<name>` in `source`, without the
  `hero-` prefix.

  Docs and comments count: a name mentioned there but absent from the bundle is
  a stale reference worth failing on.
  """
  @spec hero_names(String.t()) :: MapSet.t(String.t())
  def hero_names(source) when is_binary(source) do
    ~r/hero-([a-z0-9]+(?:-[a-z0-9]+)*)/
    |> Regex.scan(source, capture: :all_but_first)
    |> List.flatten()
    |> MapSet.new()
  end

  # ---- AST collection -------------------------------------------------------

  defp collect({:@, _meta, [{attribute, _, _}]}, acc) when attribute in @doc_attributes, do: acc

  defp collect({:__block__, meta, [binary]}, acc) when is_binary(binary) do
    emit_parts([binary], meta[:line], meta[:delimiter], false, acc)
  end

  # Literal-encoder wrapper around a list, a two-tuple, an atom or a number, and
  # a one-expression block: look inside.
  defp collect({:__block__, _meta, [inner]}, acc), do: collect(inner, acc)

  defp collect({:<<>>, meta, parts}, acc) when is_list(parts) do
    emit_parts(parts, meta[:line], meta[:delimiter], false, acc)
  end

  defp collect({sigil, meta, [{:<<>>, _, parts}, modifiers] = args}, acc)
       when is_atom(sigil) and is_list(parts) and is_list(modifiers) do
    if sigil_name?(sigil) do
      emit_parts(parts, meta[:line], meta[:delimiter], sigil in @heex_sigils, acc)
    else
      collect_call(sigil, args, acc)
    end
  end

  defp collect({form, _meta, args}, acc) when is_list(args), do: collect_call(form, args, acc)

  defp collect({left, right}, acc), do: collect(right, collect(left, acc))

  defp collect(list, acc) when is_list(list), do: Enum.reduce(list, acc, &collect/2)

  defp collect(_other, acc), do: acc

  defp collect_call(form, args, acc) do
    acc = if is_tuple(form), do: collect(form, acc), else: acc
    Enum.reduce(args, acc, &collect/2)
  end

  defp sigil_name?(atom), do: atom |> Atom.to_string() |> String.starts_with?("sigil_")

  # Heredoc content starts on the line after the opening delimiter.
  defp emit_parts(parts, line, delimiter, strip?, acc) when is_integer(line) do
    base = if delimiter in [~s("""), "'''"], do: line + 1, else: line

    {acc, _newlines} =
      Enum.reduce(parts, {acc, 0}, fn
        part, {acc, newlines} when is_binary(part) ->
          text = if strip?, do: strip_heex_comments(part), else: part
          {add_lines(text, base + newlines, acc), newlines + count_newlines(part)}

        part, {acc, newlines} ->
          {collect(part, acc), newlines}
      end)

    acc
  end

  defp emit_parts(parts, nil, delimiter, strip?, acc) do
    emit_parts(parts, 1, delimiter, strip?, acc)
  end

  defp add_lines(text, first_line, acc) do
    text
    |> String.split("\n")
    |> Enum.with_index(first_line)
    |> Enum.reduce(acc, fn
      {"", _line}, acc -> acc
      {text, line}, acc -> [{line, text} | acc]
    end)
  end

  defp count_newlines(text), do: text |> :binary.matches("\n") |> length()

  # Replace each HEEx comment with its newlines so later lines keep their numbers.
  defp strip_heex_comments(text) do
    Regex.replace(~r/<%!--.*?--%>/s, text, fn comment ->
      String.duplicate("\n", count_newlines(comment))
    end)
  end
end
