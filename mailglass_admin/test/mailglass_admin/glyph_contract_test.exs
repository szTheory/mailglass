defmodule MailglassAdmin.GlyphContractTest do
  @moduledoc """
  Machine-checked glyph contract for rendered admin text (BRTOK-04, Phase 181
  D-17). Required lane: `support_contract_admin` (`mix verify.support_contract.admin`,
  the whole admin test directory).

  The brand v2 fonts carry no arrow glyphs, so an arrow in rendered text would
  fall back to another face (ROADMAP criterion 4). This file owns two checks, both
  over every `.ex` and `.heex` source under `mailglass_admin/lib` through the
  shared `MailglassAdmin.TestSupport.GlyphScan`:

    1. **Arrow scan, no allow-list.** No rendered string in `lib` contains a code
       point in U+2190-U+2193. The back link and both "Open full detail" links
       draw `hero-arrow-left` / `hero-arrow-right` icons instead.
    2. **Every hero icon has a bundle rule.** Every `hero-<name>` token used in
       `lib` has a `.hero-<name>` rule in the compiled bundle. A missing vendored
       icon renders as an invisible empty span: no compile step and no other test
       notices, and only this test and the ICON-EXISTS-GATE conformance gate catch
       it.

  ## Teeth

  Every detector is a pure function of source text (or CSS text), and the
  "detectors have teeth" block feeds each one a known violation: a leftwards
  arrow planted in a `~H` string and in a `.heex` template is reported with its
  line, docs and HEEx comments are not scanned, and a dropped
  `.hero-arrow-left` rule is reported. A pass is therefore not vacuous.
  """

  use ExUnit.Case, async: true

  alias MailglassAdmin.TestSupport.GlyphScan

  @lib_dir Path.expand("../../lib", __DIR__)
  @css_path Path.join(Application.app_dir(:mailglass_admin, "priv/static"), "app.css")

  @larr "←"
  @rarr "→"

  defp arrow?(codepoint), do: codepoint in 0x2190..0x2193

  # {relative path, kind, source} for every admin lib source.
  defp lib_sources do
    @lib_dir
    |> Path.join("**/*.{ex,heex}")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(fn path ->
      kind = if String.ends_with?(path, ".heex"), do: :heex, else: :ex
      {Path.relative_to(path, @lib_dir), kind, File.read!(path)}
    end)
  end

  defp scan(sources, allowed?) do
    for {path, kind, source} <- sources,
        {line, codepoint} <-
          source |> GlyphScan.rendered_strings(kind) |> GlyphScan.offending(allowed?),
        do: {path, line, codepoint}
  end

  defp format_findings(findings) do
    Enum.map_join(findings, "\n", fn {path, line, codepoint} ->
      "  #{path}:#{line} U+#{codepoint |> Integer.to_string(16) |> String.pad_leading(4, "0")}"
    end)
  end

  # Names used in `lib` that have no `.hero-<name>` selector in `css`.
  defp missing_hero_rules(sources, css) do
    available =
      ~r/\.hero-([a-z0-9]+(?:-[a-z0-9]+)*)/
      |> Regex.scan(css, capture: :all_but_first)
      |> List.flatten()
      |> MapSet.new()

    sources
    |> Enum.reduce(MapSet.new(), fn {_path, _kind, source}, acc ->
      MapSet.union(acc, GlyphScan.hero_names(source))
    end)
    |> MapSet.difference(available)
    |> Enum.sort()
  end

  describe "arrow scan over admin lib (D-17, BRTOK-04)" do
    test "the scan reads the whole lib tree, not a short list" do
      paths = lib_sources() |> Enum.map(&elem(&1, 0))

      assert length(paths) > 50
      assert "mailglass_admin/operator_live.ex" in paths
      assert "mailglass_admin/layouts/root.html.heex" in paths
    end

    test "no rendered lib text contains a code point in U+2190-U+2193" do
      findings = scan(lib_sources(), &(not arrow?(&1)))

      assert findings == [],
             "arrow glyphs in rendered admin text (the brand fonts cannot draw them; " <>
               "use a hero-arrow-* icon):\n" <> format_findings(findings)
    end

    test "the three replaced arrows are drawn as icons" do
      sources = Map.new(lib_sources(), fn {path, _kind, source} -> {path, source} end)

      assert sources["mailglass_admin/operator_live.ex"] =~ ~s(name="hero-arrow-left")
      assert sources["mailglass_admin/operator/quick_view.ex"] =~ ~s(name="hero-arrow-right")
      assert sources["mailglass_admin/inbound/quick_view.ex"] =~ ~s(name="hero-arrow-right")
    end
  end

  describe "every hero icon used in lib has a rule in the compiled bundle" do
    test "no used hero-<name> lacks a .hero-<name> selector in priv/static/app.css" do
      sources = lib_sources()
      missing = missing_hero_rules(sources, File.read!(@css_path))

      assert missing == [],
             "hero icons used in lib with no bundle rule (they render invisibly; embed the SVG " <>
               "in assets/vendor/heroicons-inline.js and rebuild): #{inspect(missing)}"
    end

    test "the check sees the icons it is meant to guard" do
      used =
        lib_sources()
        |> Enum.reduce(MapSet.new(), fn {_path, _kind, source}, acc ->
          MapSet.union(acc, GlyphScan.hero_names(source))
        end)

      assert MapSet.size(used) >= 31
      assert MapSet.member?(used, "arrow-left")
      assert MapSet.member?(used, "arrow-right")
      assert MapSet.member?(used, "chevron-down")
    end
  end

  describe "detectors have teeth (fail-first proof)" do
    test "docs are not scanned, a ~H string is" do
      source = """
      defmodule Sample do
        @moduledoc "doc #{@rarr} text"
        @doc "function doc #{@rarr}"
        @typedoc "type doc #{@rarr}"
        def render(assigns), do: ~H"<p>back #{@larr}</p>"
      end
      """

      strings = GlyphScan.rendered_strings(source, :ex)

      assert Enum.map(strings, &elem(&1, 1)) == ["<p>back #{@larr}</p>"]
      assert GlyphScan.offending(strings, &(not arrow?(&1))) == [{5, 0x2190}]
    end

    test "a leftwards arrow planted in a multi-line ~H heredoc is reported on its line" do
      source = """
      defmodule Sample do
        def render(assigns) do
          ~H\"\"\"
          <p>
            back #{@larr}
          </p>
          \"\"\"
        end
      end
      """

      assert source
             |> GlyphScan.rendered_strings(:ex)
             |> GlyphScan.offending(&(not arrow?(&1))) == [{5, 0x2190}]
    end

    test "an arrow in a plain string, an interpolated string and a heredoc is reported" do
      source = """
      defmodule Sample do
        def a, do: "go #{@rarr}"
        def b(x), do: "from \#{x} #{@larr} to"
        def c do
          \"\"\"
          first
          second #{@larr}
          \"\"\"
        end
      end
      """

      assert source
             |> GlyphScan.rendered_strings(:ex)
             |> GlyphScan.offending(&(not arrow?(&1))) == [{2, 0x2192}, {3, 0x2190}, {7, 0x2190}]
    end

    test "comments and HEEx comments are not scanned" do
      source = """
      defmodule Sample do
        # a comment with #{@rarr}
        def render(assigns) do
          ~H\"\"\"
          <%!-- HEEx comment with #{@larr}
                spanning two lines --%>
          <p>ok</p> #{@rarr}
          \"\"\"
        end
      end
      """

      assert source
             |> GlyphScan.rendered_strings(:ex)
             |> GlyphScan.offending(&(not arrow?(&1))) == [{7, 0x2192}]
    end

    test ".heex sources are scanned whole with their comments removed" do
      template = "<%!-- #{@larr} --%>\n<p>fine</p>\n<a>#{@rarr} open</a>\n"

      assert template
             |> GlyphScan.rendered_strings(:heex)
             |> GlyphScan.offending(&(not arrow?(&1))) == [{3, 0x2192}]
    end

    test "a planted leftwards arrow in a lib source is reported by the lib scan" do
      planted = [
        {"mailglass_admin/planted.ex", :ex,
         ~s|defmodule Planted do\n  def render(assigns), do: ~H"<p>#{@larr} Back</p>"\nend\n|}
      ]

      assert scan(planted, &(not arrow?(&1))) == [{"mailglass_admin/planted.ex", 2, 0x2190}]
    end

    test "a hero icon with no rule in the bundle is reported" do
      sources = [{"x.ex", :ex, ~s(<Components.icon name="hero-arrow-left" />)}]
      css = ".hero-arrow-left{display:inline-block}.hero-check{display:inline-block}"

      assert missing_hero_rules(sources, css) == []

      dropped = String.replace(css, ".hero-arrow-left", ".hero-arrow-left-gone")
      assert missing_hero_rules(sources, dropped) == ["arrow-left"]
    end

    test "hero_names/1 reads every token and no trailing hyphen" do
      source = ~s(name="hero-arrow-left" class="hero-check h-4" <> "hero-")

      assert GlyphScan.hero_names(source) == MapSet.new(["arrow-left", "check"])
    end
  end
end
