defmodule Mailglass.BrandDocsCheck do
  @moduledoc false

  @repo_root Path.expand("..", __DIR__)
  @asset_commit "7781b4b1ceeca940e5f892530b1cf05430b54d7c"
  @packages %{
    "core" => {".", "doc"},
    "admin" => {"mailglass_admin", "mailglass_admin/doc"},
    "inbound" => {"mailglass_inbound", "mailglass_inbound/doc"}
  }
  @readme_images [
    {"brandbook/v2/mailglass-lockup-light.svg", "#gh-light-mode-only"},
    {"brandbook/v2/mailglass-lockup-dark.svg", "#gh-dark-mode-only"}
  ]
  @docs_assets [
    {"assets/logo.svg", "brandbook/v2/mailglass-mark-light.svg"},
    {"assets/mailglass-mark-dark.svg", "brandbook/v2/mailglass-mark-dark.svg"}
  ]

  @doc """
  Checks one generated ExDoc output directory against the repository's pinned media and
  renderer contracts. The output is local, so callers never need a running server or network.
  """
  def verify_output(doc_dir, package) when package in ["core", "admin", "inbound"] do
    doc_dir = Path.expand(doc_dir)
    {package_root, _output} = Map.fetch!(@packages, package)
    package_root = Path.expand(package_root, @repo_root)
    readme_path = Path.join(package_root, "README.md")

    issues =
      []
      |> add_issues(readme_source_issues(readme_path))
      |> add_issues(output_asset_issues(doc_dir))
      |> add_issues(output_html_issues(doc_dir))
      |> add_issues(output_css_issues(doc_dir))
      |> add_issues(output_script_issues(doc_dir))
      |> add_issues(public_claim_issues(doc_dir))

    case issues do
      [] -> {:ok, %{package: package, doc_dir: doc_dir}}
      issues -> {:error, Enum.uniq(issues)}
    end
  end

  def verify_output(_doc_dir, package), do: {:error, [{:unknown_package, package}]}

  @doc false
  def readme_source_issues(path) do
    case File.read(path) do
      {:ok, readme} -> readme_issues(readme) ++ pinned_commit_assets_issues()
      {:error, _reason} -> [{:unreadable_readme, Path.relative_to(path, @repo_root)}]
    end
  end

  @doc false
  def readme_issues(readme) when is_binary(readme) do
    header = readme |> String.split(~r/^## /m, parts: 2) |> hd()
    headings = Regex.scan(~r/^# .*$/m, header) |> List.flatten()
    image_tags = Regex.scan(~r/<img\b[^>]*>/i, header) |> List.flatten()
    image_urls = Enum.map(image_tags, &attribute(&1, "src"))
    image_alts = Enum.map(image_tags, &attribute(&1, "alt"))
    expected_urls = Enum.map(@readme_images, fn {path, fragment} -> raw_url(path) <> fragment end)

    []
    |> maybe_issue(headings != ["# mailglass"], :wrong_readme_heading)
    |> maybe_issue(length(image_tags) != 2, :wrong_image_count)
    |> maybe_issue(image_alts != ["mailglass", "mailglass"], :wrong_or_missing_alt)
    |> maybe_issue(image_urls != expected_urls, :wrong_or_misordered_theme_urls)
    |> maybe_issue(not Enum.all?(image_tags, &responsive_image?/1), :invalid_image_dimensions)
    |> maybe_issue(String.contains?(header, ["<picture", "<source"]), :unsupported_picture_markup)
    |> maybe_issue(
      not String.contains?(header, "See your email before it ships. Trace it after."),
      :tagline_missing
    )
    |> Enum.reverse()
  end

  @doc false
  def pinned_bytes_match?(source_path, bytes) when is_binary(source_path) and is_binary(bytes) do
    case pin_entry(source_path) do
      nil -> false
      entry -> byte_size(bytes) == entry["bytes"] and sha256(bytes) == entry["sha256"]
    end
  end

  @doc false
  def syntax_css_issues(css) when is_binary(css) do
    clean_css = Regex.replace(~r/\/\*.*?\*\//s, css, "")
    rules = Regex.scan(~r/([^{}]+)\{([^{}]*)\}/s, clean_css, capture: :all_but_first)

    rule_issues =
      Enum.flat_map(rules, fn [selector, declarations] ->
        selectors = String.split(selector, ",") |> Enum.map(&String.trim/1)

        properties =
          declarations
          |> String.split(";", trim: true)
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.map(fn declaration ->
            declaration |> String.split(":", parts: 2) |> hd() |> String.trim()
          end)

        []
        |> maybe_issue(
          not Enum.all?(selectors, &String.contains?(&1, ".makeup")),
          :non_syntax_selector
        )
        |> maybe_issue(
          not Enum.all?(properties, &(&1 in ["color", "background-color"])),
          :non_color_property
        )
      end)
      |> List.flatten()

    []
    |> maybe_issue(String.contains?(clean_css, "@"), :at_rule_forbidden)
    |> maybe_issue(rules == [], :no_syntax_rules)
    |> maybe_issue(not String.contains?(clean_css, "color:"), :no_token_color)
    |> Kernel.++(rule_issues)
    |> Enum.uniq()
  end

  @doc false
  def package_doc_dir(package) do
    case Map.fetch(@packages, package) do
      {:ok, {_package_root, output}} -> Path.expand(output, @repo_root)
      :error -> nil
    end
  end

  @doc false
  def cli(args) do
    {opts, extra, invalid} = OptionParser.parse(args, strict: [package: :string])

    case {opts[:package], extra, invalid} do
      {package, [], []} when package in ["core", "admin", "inbound"] ->
        case verify_output(package_doc_dir(package), package) do
          {:ok, _result} -> {0, "[brand_docs_check] #{package} generated docs pass"}
          {:error, issues} -> {1, "[brand_docs_check] #{package}: #{format_issues(issues)}"}
        end

      _ ->
        {2, "Usage: mix run --no-start scripts/brand_docs_check.exs --package core|admin|inbound"}
    end
  end

  defp output_asset_issues(doc_dir) do
    source_assets =
      Enum.map(@docs_assets, fn {output, source} -> {Path.join(doc_dir, output), source} end)

    source_assets =
      source_assets ++ [{Path.join(doc_dir, "assets/favicon.svg"), "brandbook/v2/favicon.svg"}]

    source_assets
    |> Enum.map(fn {generated_path, source_rel} ->
      expected_path = Path.join(@repo_root, source_rel)
      relative_output = Path.relative_to(generated_path, doc_dir)

      with {:ok, generated} <- File.read(generated_path),
           {:ok, expected} <- File.read(expected_path),
           true <- pinned_bytes_match?(source_rel, expected),
           true <- generated == expected do
        []
      else
        {:error, _reason} -> [{:missing_or_unreadable_asset, relative_output}]
        false -> [{:pinned_asset_mismatch, relative_output}]
      end
    end)
    |> List.flatten()
  end

  defp output_html_issues(doc_dir) do
    html_files = Path.wildcard(Path.join(doc_dir, "**/*.html"))
    readme_html = Path.join(doc_dir, "readme.html")

    issues =
      []
      |> maybe_issue(html_files == [], :no_generated_html)
      |> maybe_issue(not File.regular?(readme_html), :missing_generated_readme)

    case File.read(readme_html) do
      {:ok, html} ->
        issues
        |> maybe_issue(
          not Enum.all?(
            Enum.map(@readme_images, fn {path, fragment} -> raw_url(path) <> fragment end),
            &String.contains?(html, &1)
          ),
          :generated_readme_missing_pinned_images
        )
        |> maybe_issue(
          not String.contains?(html, ~s(rel="stylesheet" href="assets/code-colors.css")),
          :missing_color_stylesheet_hook
        )
        |> maybe_issue(
          not String.contains?(html, ~s(src="assets/theme-mark.js")),
          :missing_theme_script_hook
        )
        |> Enum.reverse()

      {:error, _reason} ->
        issues
    end
  end

  defp output_css_issues(doc_dir) do
    custom_css = Path.join(doc_dir, "assets/code-colors.css")
    native_css_files = Path.wildcard(Path.join(doc_dir, "dist/html-elixir-*.css"))

    case {File.read(custom_css), Enum.find_value(native_css_files, &File.read/1)} do
      {{:ok, custom}, {:ok, native}} ->
        syntax_css_issues(custom) ++
          if(
            String.contains?(native, "Lato") and String.contains?(native, "body.dark") and
              String.contains?(native, "#gh-light-mode-only") and
              String.contains?(native, "#gh-dark-mode-only"),
            do: [],
            else: [{:native_exdoc_theme_or_lato_missing, "dist/html-elixir-*.css"}]
          )

      {{:error, _}, _} ->
        [{:missing_or_unreadable_asset, "assets/code-colors.css"}]

      {_, nil} ->
        [{:missing_native_exdoc_css, "dist/html-elixir-*.css"}]

      {_, _} ->
        [{:missing_native_exdoc_css, "dist/html-elixir-*.css"}]
    end
  end

  defp output_script_issues(doc_dir) do
    script_path = Path.join(doc_dir, "assets/theme-mark.js")

    case File.read(script_path) do
      {:ok, script} ->
        []
        |> maybe_issue(
          not String.contains?(script, ".sidebar-projectImage img"),
          :sidebar_mark_target_missing
        )
        |> maybe_issue(
          not String.contains?(script, "classList.contains(\"dark\")"),
          :theme_class_missing
        )
        |> maybe_issue(
          not String.contains?(script, "MutationObserver"),
          :theme_change_observer_missing
        )
        |> maybe_issue(
          String.contains?(script, [
            "matchMedia",
            "prefers-color-scheme",
            "fetch(",
            "http:",
            "https:"
          ]),
          :os_or_network_dependency_forbidden
        )
        |> Enum.reverse()

      {:error, _reason} ->
        [{:missing_or_unreadable_asset, "assets/theme-mark.js"}]
    end
  end

  defp public_claim_issues(doc_dir) do
    Application.put_env(:mailglass, :script_library_mode, true)
    Code.require_file(Path.join(@repo_root, "scripts/brand_trademark_gate.exs"))

    case apply(Mailglass.BrandTrademarkGate, :scan_public_claims, [[doc_dir]]) do
      {:allow, {:no_claims, []}} -> []
      {:allow, _other} -> []
      {:deny, reason} -> [{:generated_public_claim_denied, inspect(reason)}]
      {:error, reason} -> [{:generated_public_text_unreadable, inspect(reason)}]
    end
  end

  defp pin_entry(source_path) do
    pin = Path.join(@repo_root, "brandbook/brand.pin.json") |> File.read!() |> Jason.decode!()
    Enum.find(pin["shipped"], &(&1["to"] == source_path))
  rescue
    _error -> nil
  end

  defp read_git_blob(path) do
    case System.cmd("git", ["show", "#{@asset_commit}:#{path}"],
           cd: @repo_root,
           stderr_to_stdout: true
         ) do
      {bytes, 0} -> {:ok, bytes}
      {_output, _exit_code} -> :error
    end
  end

  defp pinned_commit_assets_issues do
    Enum.flat_map(@readme_images, fn {path, _fragment} ->
      case {pin_entry(path), read_git_blob(path), File.read(Path.join(@repo_root, path))} do
        {nil, _blob, _source} ->
          [{:readme_asset_missing_from_pin, path}]

        {_entry, :error, _source} ->
          [{:readme_asset_commit_missing, path}]

        {entry, {:ok, blob}, {:ok, source}} ->
          if blob == source and pinned_bytes_match?(path, blob) and
               byte_size(blob) == entry["bytes"],
             do: [],
             else: [{:readme_asset_bytes_mismatch, path}]

        {_entry, _blob, _source} ->
          [{:readme_asset_unreadable, path}]
      end
    end)
  end

  defp raw_url(path),
    do: "https://raw.githubusercontent.com/szTheory/mailglass/#{@asset_commit}/#{path}"

  defp attribute(tag, name) do
    pattern = Regex.compile!("\\b" <> Regex.escape(name) <> "=[\"']([^\"']*)[\"']", "i")

    case Regex.run(pattern, tag, capture: :all_but_first) do
      [value] -> value
      _ -> nil
    end
  end

  defp responsive_image?(tag) do
    style = attribute(tag, "style") || ""
    width = attribute(tag, "width")

    width != nil and String.to_integer(width) >= 96 and
      String.contains?(style, "max-width:100%") and String.contains?(style, "height:auto") and
      not String.contains?(style, ["object-fit:cover", "transform:"])
  rescue
    _error -> false
  end

  defp maybe_issue(issues, true, issue), do: [issue | issues]
  defp maybe_issue(issues, false, _issue), do: issues
  defp add_issues(issues, next), do: issues ++ next
  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp format_issues(issues) do
    Enum.map_join(issues, ", ", fn
      {tag, path} -> "#{tag}: #{path}"
      tag -> to_string(tag)
    end)
  end
end

unless Application.get_env(:mailglass, :script_library_mode, false) do
  {exit_code, output} = Mailglass.BrandDocsCheck.cli(System.argv())
  IO.puts(output)
  if exit_code != 0, do: System.halt(exit_code)
end
