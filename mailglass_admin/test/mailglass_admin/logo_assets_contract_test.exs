defmodule MailglassAdmin.LogoAssetsContractTest do
  @moduledoc """
  BRTOK-04 logo half (D-15, D-16, D-18, T-181-11, T-181-12): the admin draws the
  pinned brand v2 typemark, follows the page theme through the logo roles, and
  ships the pinned files byte for byte.

  Required lane: `support_contract_admin` (`mix verify.support_contract.admin`,
  the whole admin test directory). No browser is involved; the browser checks in
  `e2e/` are advisory evidence only.

  What is proven, all against `brandbook/v2/*` (sha256-pinned by
  `brandbook/brand.pin.json`, verified by `scripts/brand_pin.exs verify`):

    * `priv/static/mailglass-logo.svg` is byte identical to the pinned light
      lockup, and `priv/static/favicon.svg` to the pinned favicon;
    * the four `d` values of `Components.logo/1` equal, in order, the pinned
      light and dark lockup path data (nobody re-traced the mark);
    * the pinned light fills equal the light `text`, `logo.glass` and
      `logo.overlap` token values and the pinned dark fills equal the dark ones,
      so the classes the component uses resolve to the drawing the book ships;
    * the component paints the lettering with `currentColor`, the panes with
      `.mg-logo-glass` and the overlap with `.mg-logo-overlap`, with no hex fill
      and no `prefers-color-scheme` (the page root theme block owns the theme,
      Phase 180 D-10), and the compiled bundle holds both rules;
    * neither the header nor the gallery draws the logo as an `<img>` of a
      fixed-colour file (the book forbids inverting the light file on dark);
    * the logo files carry no `<text>`, script, event handler, `<foreignObject>`,
      `<image>`, `href` or remote `url(` (T-181-11), and `h-6` renders the mark
      at least 96 px wide.

  The checks are pure `(input) -> [failure]` functions and the "detectors have
  teeth" block plants one violation per check, so a pass is never vacuous.
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias MailglassAdmin.Components
  alias MailglassAdmin.TestSupport.Contrast

  @admin_root Path.expand("../..", __DIR__)
  @repo_root Path.expand("..", @admin_root)
  @lib_dir Path.join(@admin_root, "lib/mailglass_admin")

  @book_light Path.join(@repo_root, "brandbook/v2/mailglass-lockup-light.svg")
  @book_dark Path.join(@repo_root, "brandbook/v2/mailglass-lockup-dark.svg")
  @book_favicon Path.join(@repo_root, "brandbook/v2/favicon.svg")
  @tokens_path Path.join(@repo_root, "brandbook/tokens.json")

  @static_logo Path.join(@admin_root, "priv/static/mailglass-logo.svg")
  @static_favicon Path.join(@admin_root, "priv/static/favicon.svg")
  @bundle Path.join(@admin_root, "priv/static/app.css")
  @admin_shell Path.join(@lib_dir, "admin_shell.ex")
  @gallery Path.join(@lib_dir, "gallery_live.ex")

  @view_box "34.0 -840.0 5323.8 1092.0"
  @min_logo_width_px 96

  # Token role behind each of the four pinned fills, in path order.
  @fill_roles ["--mg-color-text", "--mg-logo-glass", "--mg-logo-glass", "--mg-logo-overlap"]

  setup_all do
    %{
      rendered: render_component(&Components.logo/1, class: "h-6 w-auto shrink-0"),
      light: pinned_paths(File.read!(@book_light)),
      dark: pinned_paths(File.read!(@book_dark)),
      tokens: @tokens_path |> File.read!() |> Jason.decode!() |> Contrast.resolve_tokens()
    }
  end

  describe "the shipped logo and favicon are the pinned files byte for byte (D-16, D-18, T-181-12)" do
    test "priv/static/mailglass-logo.svg is the pinned light lockup" do
      assert byte_identity_failures(
               "priv/static/mailglass-logo.svg",
               File.read!(@static_logo),
               File.read!(@book_light)
             ) == []
    end

    test "priv/static/favicon.svg is the pinned favicon" do
      assert byte_identity_failures(
               "priv/static/favicon.svg",
               File.read!(@static_favicon),
               File.read!(@book_favicon)
             ) == []
    end

    test "the favicon is the one file that follows the OS scheme (tab chrome, D-16)" do
      favicon = File.read!(@static_favicon)

      assert favicon =~ ~s(viewBox="0 0 32 32")
      assert favicon =~ ~r/prefers-color-scheme:\s*dark/
    end
  end

  describe "the inline component draws the pinned typemark (D-15, D-18)" do
    test "viewBox, role and label are the pinned ones", %{rendered: rendered} do
      logo = parse_logo(rendered)

      assert logo.view_box == @view_box
      assert logo.role == "img"
      assert logo.label == "mailglass"
      assert length(logo.paths) == 4
    end

    test "path data equals the pinned light and dark lockups, in order", %{
      rendered: rendered,
      light: light,
      dark: dark
    } do
      assert path_identity_failures(parse_logo(rendered).paths, light, dark) == []
    end

    test "the pinned lockups carry four paths", %{light: light, dark: dark} do
      assert length(light) == 4
      assert length(dark) == 4
    end

    test "word is currentColor, panes are mg-logo-glass, overlap is mg-logo-overlap", %{
      rendered: rendered
    } do
      assert paint_failures(parse_logo(rendered).paths) == []
    end

    test "the pinned fills equal the text, logo.glass and logo.overlap token values", %{
      light: light,
      dark: dark,
      tokens: tokens
    } do
      assert fill_token_failures(light, dark, tokens) == []
    end

    test "the compiled bundle holds both logo rules" do
      assert css_rule_failures(File.read!(@bundle)) == []
    end
  end

  describe "the theme owns the logo (D-15, Phase 180 D-10)" do
    test "the rendered component and the shipped logo do not switch by prefers-color-scheme", %{
      rendered: rendered
    } do
      assert scheme_failures("Components.logo/1", rendered) == []
      assert scheme_failures("priv/static/mailglass-logo.svg", File.read!(@static_logo)) == []
    end

    test "no <img> of the logo file in the rendered component, the header or the gallery", %{
      rendered: rendered
    } do
      header = File.read!(@admin_shell)
      gallery = File.read!(@gallery)

      assert img_logo_failures(rendered) == []
      assert img_logo_failures(header) == []
      assert img_logo_failures(gallery) == []

      # Anti-vacuity: both call sites really draw the inline component.
      assert header =~ "<Components.logo"
      assert gallery =~ "<Components.logo"
    end
  end

  describe "size and safety (D-15, T-181-11)" do
    test "h-6 renders the logo at least 96 px wide and the header passes h-6", %{
      rendered: rendered
    } do
      assert size_failures(parse_logo(rendered).view_box, File.read!(@admin_shell)) == []
    end

    test "the pinned lockups, the shipped logo and the component are free of active content", %{
      rendered: rendered
    } do
      for {label, markup} <- [
            {"brandbook/v2/mailglass-lockup-light.svg", File.read!(@book_light)},
            {"brandbook/v2/mailglass-lockup-dark.svg", File.read!(@book_dark)},
            {"brandbook/v2/favicon.svg", File.read!(@book_favicon)},
            {"priv/static/mailglass-logo.svg", File.read!(@static_logo)},
            {"priv/static/favicon.svg", File.read!(@static_favicon)},
            {"Components.logo/1", rendered}
          ] do
        assert safety_failures(label, markup) == []
      end
    end

    test "the logo files are text-free outlines" do
      for path <- [@book_light, @book_dark, @static_logo] do
        svg = File.read!(path)
        refute svg =~ "<text", "#{path} must not carry live <text>"
        refute svg =~ "font-family", "#{path} must not name a font"
      end
    end
  end

  describe "detectors have teeth" do
    test "an appended byte breaks byte identity" do
      good = File.read!(@static_logo)

      assert [failure] =
               byte_identity_failures("logo copy", good <> "\n", File.read!(@book_light))

      assert failure =~ "logo copy"
      assert failure =~ "differ"
    end

    test "an appended byte on the favicon copy breaks byte identity" do
      assert [failure] =
               byte_identity_failures(
                 "favicon copy",
                 File.read!(@static_favicon) <> <<0>>,
                 File.read!(@book_favicon)
               )

      assert failure =~ "favicon copy"
      assert failure =~ "differ"
    end

    test "a favicon with a different viewBox or a redrawn path is not the pinned file" do
      pinned = File.read!(@book_favicon)

      redrawn = String.replace(pinned, ~s(viewBox="0 0 32 32"), ~s(viewBox="0 0 16 16"))
      assert [_] = byte_identity_failures("favicon copy", redrawn, pinned)

      moved = String.replace(pinned, "M9.98 11.88", "M9.98 11.89", global: false)
      assert [_] = byte_identity_failures("favicon copy", moved, pinned)
    end

    test "one altered path coordinate is named", %{rendered: rendered, light: light, dark: dark} do
      [{paint, d} | rest] = parse_logo(rendered).paths
      altered = [{paint, String.replace(d, "M2787.7", "M2787.8", global: false)} | rest]

      failures = path_identity_failures(altered, light, dark)
      assert Enum.any?(failures, &(&1 =~ "path 1"))
      assert Enum.any?(failures, &(&1 =~ "light"))
    end

    test "a missing path is named", %{rendered: rendered, light: light, dark: dark} do
      failures = path_identity_failures(Enum.drop(parse_logo(rendered).paths, 1), light, dark)

      assert Enum.any?(failures, &(&1 =~ "3 paths"))
    end

    test "a hex fill on a pane is named", %{rendered: rendered} do
      markup =
        String.replace(rendered, ~s(class="mg-logo-glass"), ~s(fill="#1895C2"), global: false)

      failures = paint_failures(parse_logo(markup).paths)
      assert Enum.any?(failures, &(&1 =~ "path 2" and &1 =~ "hex fill"))
    end

    test "a pane or overlap without its class is named", %{rendered: rendered} do
      markup = String.replace(rendered, ~s(class="mg-logo-overlap"), ~s(class="x"))

      assert Enum.any?(paint_failures(parse_logo(markup).paths), &(&1 =~ "path 4"))
    end

    test "a word path that is not currentColor is named", %{rendered: rendered} do
      markup = String.replace(rendered, ~s(fill="currentColor"), ~s(fill="red"))

      assert Enum.any?(paint_failures(parse_logo(markup).paths), &(&1 =~ "path 1"))
    end

    test "a prefers-color-scheme string is named", %{rendered: rendered} do
      markup =
        rendered <> "<style>@media (prefers-color-scheme: dark) { .x { fill: red } }</style>"

      assert Enum.any?(scheme_failures("planted", markup), &(&1 =~ "prefers-color-scheme"))
    end

    test "a fill that differs from the token value is named", %{
      light: light,
      dark: dark,
      tokens: tokens
    } do
      [{_fill, d} | rest] = light

      failures = fill_token_failures([{"#2A1D18", d} | rest], dark, tokens)
      assert Enum.any?(failures, &(&1 =~ "light path 1"))
    end

    test "a missing bundle rule is named" do
      css = ".mg-logo-glass{fill:var(--mg-logo-glass)}.other{color:red}"

      assert Enum.any?(css_rule_failures(css), &(&1 =~ ".mg-logo-overlap"))
      assert css_rule_failures(".mg-logo-glass{fill:red}") != []
    end

    test "a header that draws the logo as an <img> is named" do
      header = ~s(<header><img src="/dev/mail/logo.svg" alt="mailglass"></header>)
      variant = ~s(<img\n  alt="mailglass"\n  src={~p"/mailglass-logo.svg"}\n/>)

      assert [failure] = img_logo_failures(header)
      assert failure =~ "logo.svg"
      assert [_] = img_logo_failures(variant)
    end

    test "an <img> that does not reference the logo is not a logo failure" do
      assert img_logo_failures(~s(<img src="/dev/mail/fonts/ui-400.woff2" alt="x">)) == []
      assert img_logo_failures(~s(<Components.logo class="h-6" />)) == []
    end

    test "each kind of active content is named" do
      cases = [
        {"<script", ~s|<svg><script>alert(1)</script></svg>|},
        {"event handler", ~s|<svg><path onload="x()" d="M0"/></svg>|},
        {"<foreignObject", ~s|<svg><foreignObject></foreignObject></svg>|},
        {"<image", ~s|<svg><image width="1"/></svg>|},
        {"href", ~s|<svg><a href="https://example.com"></a></svg>|},
        {"xlink:href", ~s|<svg><use xlink:href="#a"/></svg>|},
        {"remote url(", ~s|<svg><path style="fill:url(https://example.com/x)"/></svg>|},
        {"<text", ~s|<svg><text>mailglass</text></svg>|},
        {"font-family", ~s|<svg><path style="font-family:serif"/></svg>|}
      ]

      for {name, markup} <- cases do
        failures = safety_failures("planted", markup)

        assert Enum.any?(failures, &(&1 =~ name)),
               "#{name} must be named, got #{inspect(failures)}"
      end
    end

    test "a logo too short for the width floor, or a header without h-6, is named" do
      too_square = size_failures("0 0 100 100", ~s(<Components.logo class="h-6" />))
      assert Enum.any?(too_square, &(&1 =~ "px wide"))

      small = size_failures(@view_box, ~s(<Components.logo class="h-4 w-auto" />))
      assert Enum.any?(small, &(&1 =~ "h-6"))
    end
  end

  # ---------------------------------------------------------------------------
  # Pure checks
  # ---------------------------------------------------------------------------

  # `[{fill, d}]` of a pinned lockup, in file order.
  defp pinned_paths(svg) do
    ~r/<path fill="([^"]*)" d="([^"]*)"\/>/
    |> Regex.scan(svg)
    |> Enum.map(fn [_all, fill, d] -> {fill, d} end)
  end

  # The rendered component: `%{view_box, role, label, paths: [{paint, d}]}` where
  # paint is `{:fill, value}`, `{:class, value}` or `{:none, nil}`. Floki lower-cases
  # attribute names, hence "viewbox".
  defp parse_logo(markup) do
    [svg] = markup |> Floki.parse_fragment!() |> Floki.find("svg")

    paths =
      svg
      |> Floki.find("path")
      |> Enum.map(fn path ->
        paint =
          case {Floki.attribute(path, "fill"), Floki.attribute(path, "class")} do
            {[fill], _} -> {:fill, fill}
            {[], [class]} -> {:class, class}
            {[], []} -> {:none, nil}
          end

        {paint, path |> Floki.attribute("d") |> List.first()}
      end)

    %{
      view_box: svg |> Floki.attribute("viewbox") |> List.first(),
      role: svg |> Floki.attribute("role") |> List.first(),
      label: svg |> Floki.attribute("aria-label") |> List.first(),
      paths: paths
    }
  end

  defp byte_identity_failures(label, actual, expected) do
    if actual == expected do
      []
    else
      [
        "#{label}: bytes differ from the pinned copy " <>
          "(#{byte_size(actual)} bytes vs #{byte_size(expected)} pinned)"
      ]
    end
  end

  defp path_identity_failures(rendered, light, dark) do
    rendered_d = Enum.map(rendered, fn {_paint, d} -> d end)
    light_d = Enum.map(light, fn {_fill, d} -> d end)
    dark_d = Enum.map(dark, fn {_fill, d} -> d end)

    count =
      if length(rendered_d) == length(light_d) do
        []
      else
        [
          "component has #{length(rendered_d)} paths, " <>
            "the pinned lockup has #{length(light_d)} paths"
        ]
      end

    drift =
      for {pinned, tier} <- [{light_d, "light"}, {dark_d, "dark"}],
          {{actual, expected}, index} <- Enum.with_index(Enum.zip(rendered_d, pinned), 1),
          actual != expected do
        "path #{index} data differs from the pinned #{tier} lockup " <>
          "(#{String.length(actual || "")} vs #{String.length(expected)} chars)"
      end

    light_vs_dark =
      if light_d == dark_d,
        do: [],
        else: ["the pinned light and dark lockups have different path data"]

    count ++ drift ++ light_vs_dark
  end

  defp paint_failures(paths) do
    expected = [
      {:fill, "currentColor"},
      {:class, "mg-logo-glass"},
      {:class, "mg-logo-glass"},
      {:class, "mg-logo-overlap"}
    ]

    count =
      if length(paths) == 4, do: [], else: ["#{length(paths)} paths rendered, expected 4"]

    hex =
      for {{{:fill, "#" <> _ = fill}, _d}, index} <- Enum.with_index(paths, 1) do
        "path #{index} carries hex fill #{fill}; the theme roles own the colour"
      end

    paint =
      for {{{actual, _d}, wanted}, index} <- Enum.with_index(Enum.zip(paths, expected), 1),
          actual != wanted do
        "path #{index} paints #{inspect(actual)}, expected #{inspect(wanted)}"
      end

    count ++ hex ++ paint
  end

  defp fill_token_failures(light, dark, tokens) do
    for {paths, tier} <- [{light, "light"}, {dark, "dark"}],
        {{{fill, _d}, var}, index} <- paths |> Enum.zip(@fill_roles) |> Enum.with_index(1),
        expected = Map.fetch!(tokens, {tier, var}),
        Contrast.normalize_hex(fill) != expected do
      "#{tier} path #{index} fill #{fill} is not the #{tier} #{var} token (#{expected})"
    end
  end

  defp css_rule_failures(css) do
    for {class, var} <- [
          {".mg-logo-glass", "--mg-logo-glass"},
          {".mg-logo-overlap", "--mg-logo-overlap"}
        ],
        not Regex.match?(
          ~r/#{Regex.escape(class)}\s*\{\s*fill:\s*var\(#{Regex.escape(var)}\)\s*;?\s*\}/,
          css
        ) do
      "compiled bundle has no `#{class}{fill:var(#{var})}` rule"
    end
  end

  defp scheme_failures(label, markup) do
    if String.contains?(markup, "prefers-color-scheme") do
      ["#{label} contains prefers-color-scheme; the page theme block owns the logo colours"]
    else
      []
    end
  end

  defp img_logo_failures(markup) do
    ~r/<img\b[^>]*(?:logo\.svg|mailglass-logo)[^>]*>/is
    |> Regex.scan(markup)
    |> Enum.map(fn [tag] ->
      shown = tag |> String.replace(~r/\s+/, " ") |> String.slice(0, 80)
      "an <img> references the logo file (#{shown}); draw it inline with Components.logo/1"
    end)
  end

  defp size_failures(view_box, header_source) do
    [_x, _y, width, height] =
      view_box |> String.split(" ") |> Enum.map(&(&1 |> Float.parse() |> elem(0)))

    width_at_h6 = 24 * width / height

    wide =
      if width_at_h6 >= @min_logo_width_px do
        []
      else
        [
          "the logo is #{Float.round(width_at_h6, 1)} px wide at h-6, " <>
            "below the #{@min_logo_width_px} px floor"
        ]
      end

    header =
      if Regex.match?(~r/<Components\.logo\s+class="[^"]*\bh-6\b/, header_source),
        do: [],
        else: ["the header does not pass h-6 to Components.logo"]

    wide ++ header
  end

  defp safety_failures(label, markup) do
    checks = [
      {"<script", ~r/<script/i},
      {"event handler", ~r/\son[a-z]+\s*=/i},
      {"<foreignObject", ~r/<foreignObject/i},
      {"<image", ~r/<image\b/i},
      {"href", ~r/\bhref\s*=/i},
      {"xlink:href", ~r/xlink:href/i},
      {"remote url(", ~r/url\(\s*["']?(?:https?:)?\/\//i},
      {"<text", ~r/<text\b/i},
      {"font-family", ~r/font-family/i}
    ]

    for {name, pattern} <- checks, Regex.match?(pattern, markup) do
      "#{label} contains #{name}"
    end
  end
end
