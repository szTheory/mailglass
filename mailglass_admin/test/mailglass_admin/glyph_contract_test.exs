defmodule MailglassAdmin.GlyphContractTest do
  @moduledoc """
  Machine-checked glyph contract for rendered admin text (BRTOK-03 and BRTOK-04,
  Phase 181 D-13 and D-17). Required lane: `support_contract_admin`
  (`mix verify.support_contract.admin`, the whole admin test directory).

  The six brand v2 woff2 are subset to 170 code points, and they carry no arrow
  glyphs and no middle dot. A character outside the subset in rendered text falls
  back to another face, so this file owns three checks over every `.ex` and
  `.heex` source under `mailglass_admin/lib`, through the shared
  `MailglassAdmin.TestSupport.GlyphScan`:

    1. **Arrow scan, no allow-list.** No rendered string in `lib` contains a code
       point in U+2190-U+2193. The back link and both "Open full detail" links
       draw `hero-arrow-left` / `hero-arrow-right` icons instead.
    2. **Font subset.** No rendered string in `lib` contains a code point outside
       the 170-code-point subset, except the exact `{file, code point}` entries in
       the allow-list below, each with a reason (deliberate worst-case gallery
       fixtures). An allow-list entry the scan no longer finds is itself a failure,
       so the list cannot rot.
    3. **Every hero icon has a bundle rule.** Every `hero-<name>` token used in
       `lib` has a `.hero-<name>` rule in the compiled bundle. A missing vendored
       icon renders as an invisible empty span: no compile step and no other test
       notices, and only this test and the ICON-EXISTS-GATE conformance gate catch
       it.

  ## The subset is bound to the font bytes

  The subset literal below is bound to the six woff2 `sha256` values in
  `brandbook/brand.pin.json`, which are copied in full beside it. A font update
  through `brand_pin.exs update` or `extend` changes a pinned hash and fails here,
  which forces the subset to be derived again before the contract can pass. Never
  re-subset the fonts to add a character (BRTOK-03 prohibition); change the
  character instead.

  Derivation (all six files give the same set):

      python3 -c "from fontTools.ttLib import TTFont; \\
        print(sorted(TTFont('mailglass_admin/priv/static/fonts/ui-400.woff2').getBestCmap()))"

  The set is Basic Latin U+0020-U+007E, U+00A0, U+00B0, Latin-1 letters
  U+00C0-U+00FF, en and em dash, curly quotes, the bullet U+2022, the ellipsis
  U+2026 and the minus U+2212.

  ## Teeth

  Every detector is a pure function of source text (or CSS text, or hash maps),
  and the "detectors have teeth" block feeds each one a known violation: a
  leftwards arrow or a middle dot planted in a `~H` string is reported with its
  line, docs and HEEx comments are not scanned, a stale allow-list entry and a
  changed recorded font hash are reported, and a dropped `.hero-arrow-left` rule
  is reported. A pass is therefore not vacuous.
  """

  use ExUnit.Case, async: true

  alias MailglassAdmin.TestSupport.GlyphScan

  @lib_dir Path.expand("../../lib", __DIR__)
  @css_path Path.join(Application.app_dir(:mailglass_admin, "priv/static"), "app.css")

  @pin_path Path.expand("../../../brandbook/brand.pin.json", __DIR__)
  @fonts_dir Path.join(Application.app_dir(:mailglass_admin, "priv/static"), "fonts")

  @larr "←"
  @rarr "→"
  @middot "·"
  @cjk "山"

  # The 170 code points every pinned woff2 draws (derivation in the moduledoc).
  @subset Enum.to_list(0x0020..0x007E) ++
            [0x00A0, 0x00B0] ++
            Enum.to_list(0x00C0..0x00FF) ++
            [0x2013, 0x2014, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2026, 0x2212]

  # The six woff2 the subset was derived from, with the sha256 recorded in
  # brandbook/brand.pin.json. Copy the new values here only after deriving the
  # subset again from the new fonts.
  @font_hashes %{
    "a-display-600.woff2" => "3e756227e0281898d718b6e2f5724eda53dbda34ce4f814a117742fb98b28956",
    "a-mono-400.woff2" => "6c2b7d2dd9547f1438299d2e22ec21570df63abecc300e72b4908cd977126b47",
    "a-mono-600.woff2" => "27abbe6bde2ef17cda90ef700cecac73b6cd78c6f025cea5c4e1195027d7b666",
    "ui-400.woff2" => "c9ea743af769d03c62058e7d9047ec3c271b6c26b45ba908bab378f050b99cae",
    "ui-400i.woff2" => "e24ed9e06273f44bbee177022c25b3bc50f52841b6cffa35ea66b3a492e44b4b",
    "ui-600.woff2" => "f3fc5d883120a0582211d948d1bb832bf01cc299101f165478dffc8a54a2bd84"
  }

  # Deliberate worst-case gallery fixtures: non-Latin text that renders through
  # the fallback face on purpose. {relative path under lib, code point, reason}.
  @tenant_reason "non-ASCII tenant specimen (STATE-LD-07, \"Muenchen-Tokyo-...\"): a deliberate worst case for the tenant chip"
  @name_reason "non-ASCII display-name specimen (fjordline-non-ascii-names): a deliberate worst case for sender-name truncation"
  @mime_reason "raw MIME specimen (evidence_card revealed): CRLF is the message wire format, kept so the specimen is a real worst case"
  @allow_list [
    {"mailglass_admin/gallery_live.ex", 0x30C6, @tenant_reason},
    {"mailglass_admin/gallery_live.ex", 0x30CA, @tenant_reason},
    {"mailglass_admin/gallery_live.ex", 0x30F3, @tenant_reason},
    {"mailglass_admin/gallery_live.ex", 0x30C8, @tenant_reason},
    {"mailglass_admin/gallery_live.ex", 0x5C71, @name_reason},
    {"mailglass_admin/gallery_live.ex", 0x7530, @name_reason},
    {"mailglass_admin/gallery_live.ex", 0x592A, @name_reason},
    {"mailglass_admin/gallery_live.ex", 0x90CE, @name_reason},
    {"mailglass_admin/gallery_live.ex", 0x000D, @mime_reason}
  ]

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

  @subset_set MapSet.new(@subset)

  defp in_subset?(codepoint), do: MapSet.member?(@subset_set, codepoint)

  defp hex(codepoint),
    do: "U+" <> (codepoint |> Integer.to_string(16) |> String.pad_leading(4, "0"))

  # One failure string per code point outside the subset that is not allow-listed,
  # and one per allow-list entry the scan no longer finds.
  defp subset_failures(sources, allow_list) do
    findings = scan(sources, &in_subset?/1)
    allowed = MapSet.new(allow_list, fn {path, codepoint, _reason} -> {path, codepoint} end)

    unexpected =
      for {path, line, codepoint} <- findings,
          not MapSet.member?(allowed, {path, codepoint}),
          do: "#{path}:#{line} #{hex(codepoint)} is outside the font subset"

    found = MapSet.new(findings, fn {path, _line, codepoint} -> {path, codepoint} end)

    stale =
      for {path, codepoint, _reason} <- allow_list,
          not MapSet.member?(found, {path, codepoint}),
          do: "stale allow-list entry #{path} #{hex(codepoint)}: the scan no longer finds it"

    unexpected ++ stale
  end

  # Recorded font hashes against the woff2 entries of the fonts dir in the pin.
  defp hash_failures(recorded, pin) do
    pinned =
      for %{"to" => "mailglass_admin/priv/static/fonts/" <> name, "sha256" => sha256} <-
            pin["shipped"],
          String.ends_with?(name, ".woff2"),
          into: %{},
          do: {name, sha256}

    changed =
      for {name, sha256} <- recorded, Map.get(pinned, name) != sha256 do
        "#{name}: recorded #{sha256}, brand.pin.json has #{inspect(Map.get(pinned, name))}"
      end

    unrecorded =
      for {name, _sha256} <- pinned, not Map.has_key?(recorded, name) do
        "#{name}: pinned in brand.pin.json but not recorded in the glyph contract"
      end

    Enum.sort(changed ++ unrecorded)
  end

  defp sha256(binary), do: :sha256 |> :crypto.hash(binary) |> Base.encode16(case: :lower)

  describe "font subset over admin lib (D-13, BRTOK-03)" do
    test "the subset literal is exactly 170 distinct code points" do
      assert length(@subset) == 170
      assert MapSet.size(@subset_set) == 170
    end

    test "no rendered lib text falls outside the subset, except reasoned worst-case fixtures" do
      failures = subset_failures(lib_sources(), @allow_list)

      assert failures == [],
             "rendered admin text outside the 170-code-point font subset " <>
               "(replace the character, never re-subset the fonts):\n  " <>
               Enum.join(failures, "\n  ")
    end

    test "every allow-list entry names a lib file and carries a reason" do
      paths = lib_sources() |> Enum.map(&elem(&1, 0)) |> MapSet.new()

      for {path, codepoint, reason} <- @allow_list do
        assert MapSet.member?(paths, path), "#{path} (#{hex(codepoint)}) is not a lib source"
        assert is_binary(reason) and String.length(reason) > 20
        refute in_subset?(codepoint), "#{hex(codepoint)} is in the subset; drop the entry"
      end
    end
  end

  describe "the subset is bound to the pinned font bytes (BRTOK-03)" do
    test "the six recorded sha256 values equal the woff2 entries in brand.pin.json" do
      pin = @pin_path |> File.read!() |> Jason.decode!()

      assert map_size(@font_hashes) == 6
      assert hash_failures(@font_hashes, pin) == []
    end

    test "the recorded sha256 values equal the shipped woff2 bytes" do
      for {name, recorded} <- @font_hashes do
        assert sha256(File.read!(Path.join(@fonts_dir, name))) == recorded,
               "#{name} on disk differs from the font the subset was derived from"
      end
    end
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

    test "a middle dot planted in a ~H string is reported on its line" do
      planted = [
        {"mailglass_admin/planted.ex", :ex,
         ~s|defmodule Planted do\n  def render(assigns), do: ~H"<p>a #{@middot} b</p>"\nend\n|}
      ]

      assert subset_failures(planted, []) == [
               "mailglass_admin/planted.ex:2 U+00B7 is outside the font subset"
             ]
    end

    test "a middle dot planted in a plain string and in a .heex template is reported" do
      planted = [
        {"a.ex", :ex, ~s|defmodule A do\n  def r, do: "x #{@middot} y"\nend\n|},
        {"b.html.heex", :heex, "<p>fine</p>\n<span>#{@middot}</span>\n"}
      ]

      assert subset_failures(planted, []) == [
               "a.ex:2 U+00B7 is outside the font subset",
               "b.html.heex:2 U+00B7 is outside the font subset"
             ]
    end

    test "an allow-list entry covers exactly its file and code point" do
      source = ~s|defmodule A do\n  def r, do: "#{@cjk}"\nend\n|

      assert subset_failures([{"a.ex", :ex, source}], [{"a.ex", 0x5C71, "worst-case fixture"}]) ==
               []

      # the same code point in another file is not covered
      assert subset_failures([{"b.ex", :ex, source}], [{"a.ex", 0x5C71, "worst-case fixture"}]) ==
               [
                 "b.ex:2 U+5C71 is outside the font subset",
                 "stale allow-list entry a.ex U+5C71: the scan no longer finds it"
               ]

      # a different code point in the same file is not covered
      assert subset_failures([{"a.ex", :ex, source}], [{"a.ex", 0x7530, "worst-case fixture"}]) ==
               [
                 "a.ex:2 U+5C71 is outside the font subset",
                 "stale allow-list entry a.ex U+7530: the scan no longer finds it"
               ]
    end

    test "a stale allow-list entry is reported" do
      clean = [{"a.ex", :ex, "defmodule A do\n  def r, do: \"plain\"\nend\n"}]

      assert subset_failures(clean, [{"a.ex", 0x5C71, "worst-case fixture"}]) ==
               ["stale allow-list entry a.ex U+5C71: the scan no longer finds it"]
    end

    test "a bullet and the other subset characters are not reported" do
      allowed =
        "x \u2022 y \u2013 \u2014 \u2018\u2019 \u201C\u201D \u2026 \u2212 \u00A0 \u00B0 \u00C5\u00FF"

      assert subset_failures(
               [{"a.ex", :ex, "defmodule A do\n  def r, do: \"#{allowed}\"\nend\n"}],
               []
             ) ==
               []
    end

    test "a changed recorded font hash is reported, and so is an unrecorded pinned font" do
      pin = %{
        "shipped" => [
          %{"to" => "mailglass_admin/priv/static/fonts/ui-400.woff2", "sha256" => "aa"},
          %{"to" => "mailglass_admin/priv/static/fonts/ui-600.woff2", "sha256" => "bb"},
          %{"to" => "brandbook/v2/brand.json", "sha256" => "cc"}
        ]
      }

      assert hash_failures(%{"ui-400.woff2" => "aa", "ui-600.woff2" => "bb"}, pin) == []

      assert hash_failures(%{"ui-400.woff2" => "aa", "ui-600.woff2" => "XX"}, pin) ==
               [~s|ui-600.woff2: recorded XX, brand.pin.json has "bb"|]

      assert hash_failures(%{"ui-400.woff2" => "aa"}, pin) ==
               ["ui-600.woff2: pinned in brand.pin.json but not recorded in the glyph contract"]

      assert hash_failures(
               %{"ui-400.woff2" => "aa", "ui-600.woff2" => "bb", "x.woff2" => "dd"},
               pin
             ) ==
               [~s|x.woff2: recorded dd, brand.pin.json has nil|]
    end

    test "hero_names/1 reads every token and no trailing hyphen" do
      source = ~s(name="hero-arrow-left" class="hero-check h-4" <> "hero-")

      assert GlyphScan.hero_names(source) == MapSet.new(["arrow-left", "check"])
    end
  end
end
