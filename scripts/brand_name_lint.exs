defmodule Mailglass.BrandNameLint do
  @moduledoc false

  @proper_name ~r/(?<![\p{L}\p{N}_])mailglass(?![\p{L}\p{N}_]|-Mailable|\.[A-Za-z_{])/iu
  @split_name ~r/(?<![\p{L}\p{N}_])[Mm]ail\s+[Gg]lass(?![\p{L}\p{N}_])/u
  @platform_claim ~r/\bthe\s+mailglass\s+platform\b/iu
  @wire_header ~r/\b(?:Mailglass-Mailable|X-Mailglass-[A-Za-z0-9-]+)\b/iu
  @module_name ~r/\bMailglass(?:Admin|Inbound)?(?:\.[A-Z][A-Za-z0-9_]*)+(?:\/\d+)?\b/iu
  @module_alias ~r/\bMailglass\.\{[^}]+\}/iu
  @fenced ~r/(?ms)^ {0,3}(?:`{3,}|~{3,})[^\n]*\n.*?^ {0,3}(?:`{3,}|~{3,})[ \t]*$/
  @inline_code ~r/(`+)[^`]*\1/u
  @html_code ~r/(?is)<(code|pre)\b[^>]*>.*?<\/\1\s*>/u
  @html_comment ~r/(?s)<!--.*?-->/u
  @link_destinations ~r/\]\([^)]*\)/u
  @reference_destinations ~r/(?m)^\s*\[[^\]]+\]:\s*\S+.*$/u
  @url ~r/\b(?:https?|ftp):\/\/[^\s)>]+/iu
  @indented_code ~r/(?m)^(?: {4,}|\t).*(?:\n|$)/u
  @iex_lines ~r/(?m)^\s*(?:iex>|\.\.\.)[^\n]*(?:\n|$)/u
  @source_code_line ~r/(?m)^\s*(?:alias|import|require|defmodule|use)\s+Mailglass\b[^\n]*(?:\n|$)/u
  @accessible_attribute ~r/\b(?:aria-label|aria-description|title|alt|placeholder)\s*=\s*["']([^"']*)["']/isu
  @gettext_field ~r/^\s*(?:msgid_plural|msgid|msgstr(?:\[[^]]+\])?)\s+"((?:\\.|[^"\\])*)"\s*$/u
  @gettext_quoted_continuation ~r/^\s*"((?:\\.|[^"\\])*)"\s*$/u

  # These path-specific exceptions preserve historical release text and the pending
  # owner-approved product definition. Each exception is required to match at least one
  # current finding, so it cannot silently outlive its reason.
  @exceptions [
    %{path: "PRODUCT.md", reason: "Canonical product brief awaits owner sign-off (BRDOC-03)."},
    %{path: "CHANGELOG.md", reason: "Release history is immutable and release-please-owned."},
    %{path: "mailglass_admin/CHANGELOG.md", reason: "Release history is immutable and release-please-owned."}
  ]

  # Pinned/retired brand-book sources, test fixtures, reference baselines, .planning and
  # generated evidence are intentionally outside this adopter-facing scan corpus.
  @excluded_surfaces [
    {"test/**", "Test assertions and fixtures are updated in lockstep with adopter copy."},
    {"reference/**", "Reference baselines are frozen evidence."},
    {"brandbook/v2/**", "Pinned brand authority text must remain source-exact."},
    {"brandbook/index.html", "Retired book export is preserved as historical source."},
    {".planning/**", "Planning and generated evidence are workflow records, not adopter prose."}
  ]

  @inventory_floor %{
    root_docs: 8,
    guides: 10,
    admin_docs: 1,
    inbound_docs: 5,
    core_lib: 50,
    admin_lib: 25,
    inbound_lib: 30,
    mix: 3
  }

  @doc "Returns findings for prose in a markdown, source string, HEEx, or gettext input."
  def scan_text(path, text, format) when is_binary(path) and is_binary(text) do
    fragments =
      case format do
        :source -> source_fragments(text)
        :gettext -> gettext_fragments(text)
        _ -> [{1, text}]
      end

    Enum.flat_map(fragments, fn {base_line, fragment} ->
      fragment
      |> prose_view(format)
      |> findings(path, base_line)
    end)
  end

  @doc "Scans the explicit adopter-facing inventory and rejects a vacuous or incomplete corpus."
  def scan_repo(root \\ Path.expand("..", __DIR__)) do
    files = inventory(root)
    counts = inventory_counts(files)

    with :ok <- validate_inventory(counts),
         {:ok, exceptions_used} <- validate_exceptions(root) do
      findings =
        files
        |> Enum.flat_map(fn {path, format, _surface} ->
          text = File.read!(Path.join(root, path))
          scan_text(path, text, format)
        end)
        |> Enum.reject(&covered_by_exception?(root, &1))
        |> Enum.sort_by(&{&1.path, &1.line, &1.match})

      {:ok, findings, %{counts: counts, exceptions_used: exceptions_used}}
    end
  end

  @doc "Returns the deterministic relative-path inventory."
  def inventory(root \\ Path.expand("..", __DIR__)) do
    markdown =
      [
        {"README.md", :markdown, :root_docs},
        {"CONTRIBUTING.md", :markdown, :root_docs},
        {"MAINTAINING.md", :markdown, :root_docs},
        {"SECURITY.md", :markdown, :root_docs},
        {"CODE_OF_CONDUCT.md", :markdown, :root_docs},
        {"CLAUDE.md", :markdown, :root_docs},
        {"AGENTS.md", :markdown, :root_docs},
        {"PRODUCT.md", :markdown, :root_docs}
      ] ++
        glob(root, "docs/**/*.md", :markdown, :root_docs) ++
        glob(root, "guides/**/*.md", :markdown, :guides) ++
        [{"mailglass_admin/README.md", :markdown, :admin_docs}] ++
        glob(root, "mailglass_admin/docs/**/*.md", :markdown, :admin_docs) ++
        [{"mailglass_inbound/README.md", :markdown, :inbound_docs}] ++
        glob(root, "mailglass_inbound/docs/**/*.md", :markdown, :inbound_docs)

    source =
      glob(root, "lib/**/*.{ex,exs}", :source, :core_lib) ++
        glob(root, "mailglass_admin/lib/**/*.{ex,exs}", :source, :admin_lib) ++
        glob(root, "mailglass_inbound/lib/**/*.{ex,exs}", :source, :inbound_lib) ++
        glob(root, "lib/**/*.heex", :heex, :core_lib) ++
        glob(root, "mailglass_admin/lib/**/*.heex", :heex, :admin_lib) ++
        glob(root, "mailglass_inbound/lib/**/*.heex", :heex, :inbound_lib) ++
        Enum.map(["mix.exs", "mailglass_admin/mix.exs", "mailglass_inbound/mix.exs"], &{&1, :source, :mix}) ++
        glob(root, "priv/gettext/**/*.{po,pot}", :gettext, :core_lib) ++
        glob(root, "mailglass_admin/priv/gettext/**/*.{po,pot}", :gettext, :admin_lib) ++
        glob(root, "mailglass_inbound/priv/gettext/**/*.{po,pot}", :gettext, :inbound_lib)

    (markdown ++ source)
    |> Enum.uniq_by(&elem(&1, 0))
    |> Enum.filter(fn {path, _format, _surface} -> File.regular?(Path.join(root, path)) end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  @doc "Exposes the scanner's path-specific exceptions for contract and rot checks."
  def exceptions, do: @exceptions
  def excluded_surfaces, do: @excluded_surfaces

  @doc "Checks whether every exception currently protects matching source text."
  def validate_exceptions(root \\ Path.expand("..", __DIR__)) do
    results =
      Enum.map(@exceptions, fn exception ->
        path = Path.join(root, exception.path)

        hits =
          if File.regular?(path) do
            scan_text(exception.path, File.read!(path), :markdown)
          else
            []
          end

        {exception.path, length(hits)}
      end)

    case Enum.filter(results, fn {_path, count} -> count == 0 end) do
      [] -> {:ok, results}
      unused -> {:error, {:unused_exceptions, unused}}
    end
  end

  @doc "Lowercases only non-structural name occurrences on scanner-confirmed source lines."
  def lowercase_lines(text, line_numbers, format) when is_binary(text) and is_list(line_numbers) do
    protected = [@url, @module_alias, @module_name, @wire_header, @inline_code, @html_code]
    protected = if format == :markdown, do: [@html_comment, @fenced | protected], else: protected
    {text, protected_inline} = protect_multiline_inline_code(text)
    lines = String.split(text, "\n", trim: false)
    targets = MapSet.new(line_numbers)

    lines
    |> Enum.with_index(1)
    |> Enum.map(fn {line, number} ->
      source_comment? = format == :source and Regex.match?(~r/^\s*#/u, line)

      if MapSet.member?(targets, number) and not source_comment? do
        lowercase_line(line, protected)
      else
        line
      end
    end)
    |> Enum.join("\n")
    |> then(fn rewritten ->
      Enum.reduce(protected_inline, rewritten, fn {marker, original}, current ->
        String.replace(current, marker, original)
      end)
    end)
  end

  defp glob(root, pattern, format, surface) do
    root
    |> Path.join(pattern)
    |> Path.wildcard(match_dot: true)
    |> Enum.map(fn absolute -> {Path.relative_to(absolute, root), format, surface} end)
  end

  defp inventory_counts(files) do
    files
    |> Enum.group_by(&elem(&1, 2))
    |> Map.new(fn {surface, entries} -> {surface, length(entries)} end)
  end

  defp validate_inventory(counts) do
    missing =
      Enum.reject(@inventory_floor, fn {surface, minimum} ->
        Map.get(counts, surface, 0) >= minimum
      end)

    if missing == [], do: :ok, else: {:error, {:inventory_below_floor, missing, counts}}
  end

  defp covered_by_exception?(root, finding) do
    Enum.any?(@exceptions, fn exception ->
      exception.path == finding.path and File.regular?(Path.join(root, exception.path))
    end)
  end

  defp source_fragments(source) do
    case Code.string_to_quoted(source, columns: true) do
      {:ok, ast} ->
        ast
        |> ast_fragments(1, [])
        |> Enum.reverse()
        |> locate_fragment_lines(source)

      {:error, {location, error, token}} ->
        raise ArgumentError,
              "cannot parse source at line #{inspect(location)}: #{inspect(error)} #{inspect(token)}"
    end
  end

  defp locate_fragment_lines(fragments, source) do
    source_lines = String.split(source, "\n", trim: false)

    {located, _cursor_line} =
      Enum.map_reduce(fragments, 1, fn {parent_line, fragment}, cursor_line ->
        nonempty = Enum.find(String.split(fragment, "\n"), &(String.trim(&1) != ""))
        needle = if is_binary(nonempty), do: String.trim(nonempty), else: ""
        preferred_line = Enum.at(source_lines, parent_line - 1, "")

        fragment_line =
          cond do
            fragment == "" -> parent_line
            needle != "" and String.contains?(preferred_line, needle) ->
              parent_line

            needle != "" ->
              source_lines
              |> Enum.with_index(1)
              |> Enum.find_value(parent_line, fn {line, number} ->
                if number >= max(cursor_line, parent_line) and String.contains?(line, needle),
                  do: number
              end)

            true -> parent_line
          end

        next_line = max(fragment_line, cursor_line)
        {{fragment_line, fragment}, next_line}
      end)

    located
  end

  defp ast_fragments(node, line, acc) when is_binary(node), do: [{line, node} | acc]
  defp ast_fragments(node, _line, acc) when is_atom(node) or is_number(node), do: acc

  defp ast_fragments({left, metadata, right}, line, acc) when is_list(metadata) do
    line = Keyword.get(metadata, :line, line)
    acc = ast_fragments(left, line, acc)
    ast_fragments(right, line, acc)
  end

  defp ast_fragments({left, right}, line, acc) do
    acc = ast_fragments(left, line, acc)
    ast_fragments(right, line, acc)
  end

  defp ast_fragments(list, line, acc) when is_list(list),
    do: Enum.reduce(list, acc, &ast_fragments(&1, line, &2))

  defp ast_fragments(_other, _line, acc), do: acc

  defp gettext_fragments(text) do
    {fragments, current} =
      text
      |> String.split("\n", trim: false)
      |> Enum.with_index(1)
      |> Enum.reduce({[], nil}, fn {line, number}, {fragments, current} ->
        case Regex.run(@gettext_field, line, capture: :all_but_first) do
          [value] ->
            {flush_gettext_fragment(fragments, current), {number, value}}

          _ ->
            case Regex.run(@gettext_quoted_continuation, line, capture: :all_but_first) do
              [continued] when not is_nil(current) ->
                {base_line, value} = current
                {fragments, {base_line, value <> continued}}

              _ ->
                {flush_gettext_fragment(fragments, current), nil}
            end
        end
      end)

    flush_gettext_fragment(fragments, current) |> Enum.reverse()
  end

  defp flush_gettext_fragment(fragments, nil), do: fragments
  defp flush_gettext_fragment(fragments, fragment), do: [fragment | fragments]

  defp prose_view(text, :plain), do: text

  defp prose_view(text, :heex) do
    body =
      text
      |> mask(~r/\{#.*?#\}/su)
      |> mask(@html_comment)
      |> mask(@html_code)
      |> preserve_accessible_attributes()
      |> mask(~r/<[^>]+>/u)

    prose_view(body, :plain)
  end

  defp prose_view(text, :markdown) do
    text
    |> mask(@fenced)
    |> mask(@html_comment)
    |> mask(@html_code)
    |> mask(@indented_code)
    |> mask(@iex_lines)
    |> mask(@inline_code)
    |> mask(@reference_destinations)
    |> mask(@link_destinations)
    |> mask(@url)
    |> mask(@module_alias)
    |> mask(@module_name)
    |> mask(@wire_header)
    |> preserve_accessible_attributes()
    |> mask(~r/<[^>]+>/u)
  end

  defp prose_view(text, :source) do
    text
    |> prose_view(:markdown)
    |> mask(@source_code_line)
  end

  defp prose_view(text, _format) do
    text
    |> mask(@module_alias)
    |> mask(@module_name)
    |> mask(@wire_header)
    |> preserve_accessible_attributes()
    |> mask(~r/<[^>]+>/u)
  end

  defp preserve_accessible_attributes(text) do
    Regex.replace(~r/<[^>]+>/us, text, fn tag ->
      @accessible_attribute
      |> Regex.scan(tag, capture: :all_but_first)
      |> Enum.map_join(" ", fn [value] -> value end)
    end)
  end

  defp mask(text, regex) do
    Regex.replace(regex, text, fn matched -> String.replace(matched, ~r/[^\n]/u, " ") end)
  end

  defp protect_multiline_inline_code(text) do
    text
    |> then(&Regex.scan(@inline_code, &1, capture: :first))
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.filter(&String.contains?(&1, "\n"))
    |> Enum.with_index()
    |> Enum.reduce({text, []}, fn {matched, span_index}, {current, protected} ->
      parts = String.split(matched, "\n", trim: false)

      {markers, replacements} =
        parts
        |> Enum.with_index()
        |> Enum.map_reduce([], fn {part, line_index}, replacements ->
          marker = "__LINT_PROTECTED_CODE_#{span_index}_#{line_index}__"
          {marker, [{marker, part} | replacements]}
        end)

      replacement = Enum.join(markers, "\n")
      {String.replace(current, matched, replacement), replacements ++ protected}
    end)
  end

  defp lowercase_line(line, protected_patterns) do
    {masked, protected} =
      Enum.reduce(protected_patterns, {line, []}, fn regex, {text, saved} ->
        regex
        |> then(&Regex.scan(&1, text, capture: :first))
        |> List.flatten()
        |> Enum.uniq()
        |> Enum.reduce({text, saved}, fn matched, {current, entries} ->
          index = length(entries)
          marker = "\u0000keep#{index}\u0000"
          {String.replace(current, matched, marker), [{marker, matched} | entries]}
        end)
      end)

    lowered =
      masked
      |> then(&Regex.replace(@platform_claim, &1, "the mailglass library"))
      |> then(&Regex.replace(@proper_name, &1, "mailglass"))
      |> then(&Regex.replace(@split_name, &1, "mailglass"))

    Enum.reduce(protected, lowered, fn {marker, original}, text ->
      String.replace(text, marker, original)
    end)
  end

  defp findings(text, path, base_line) do
    for {regex, label} <- [
          {@proper_name, "capitalized product name"},
          {@split_name, "split product name"},
          {@platform_claim, "unsupported platform claim"}
        ],
        [match] <- Regex.scan(regex, text, return: :index),
        {offset, match_length} = match,
        matched_text = binary_part(text, offset, match_length),
        matched_text != "mailglass" do
      prefix = binary_part(text, 0, offset)
      line = base_line + length(String.split(prefix, "\n")) - 1
      %{path: path, line: line, match: matched_text, rule: label}
    end
  end
end

if not Application.get_env(:mailglass, :script_library_mode, false) do
  if System.argv() == ["check"] do
  case Mailglass.BrandNameLint.scan_repo() do
    {:ok, [], inventory} ->
      IO.puts("brand-name lint passed: #{inspect(inventory.counts)}")
      IO.puts("active exceptions: #{inspect(inventory.exceptions_used)}")

    {:ok, findings, inventory} ->
      Enum.each(findings, fn finding ->
        IO.puts("#{finding.path}:#{finding.line}: #{finding.rule}: #{finding.match}")
      end)

      IO.puts("inventory: #{inspect(inventory.counts)}")
      System.halt(1)

    {:error, reason} ->
      IO.puts("brand-name lint failed: #{inspect(reason)}")
      System.halt(1)
  end
  else
    IO.puts("Usage: mix run --no-start scripts/brand_name_lint.exs check")
    System.halt(2)
  end
end
