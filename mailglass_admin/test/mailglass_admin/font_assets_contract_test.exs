defmodule MailglassAdmin.FontAssetsContractTest do
  @moduledoc """
  Static proof that the admin's fonts are local, listed, pinned and correctly
  mapped (BRTOK-03, Phase 181 D-12).

  This file is the REQUIRED proof. It runs in `support_contract_admin` and needs
  no browser. The browser network check in `e2e/admin-assets.spec.js` ("every
  font request has the host's origin") is advisory evidence only and is never
  cited as the proof (Phase 180 D-04 / D-13).

  ## What is checked

  1. **One font set, three views.** The woff2 files in `priv/static/fonts`, the
     compile-time allow-list `Controllers.Assets.allowed_fonts/0` and the
     `@font-face` URLs in the compiled bundle are the same set of six names.
  2. **Face table.** The bundle declares exactly the six faces
     {family, style, weight, file} the book ships: Funnel Display 600, Atkinson
     Hyperlegible Next 400 / 600 / 400 italic, Atkinson Hyperlegible Mono 400 /
     600, every one with `font-display: swap`. A 600 face pointing at the 400
     file, a missing face and an unlisted extra file are each a named failure.
  3. **Local only.** The bundle has no `url(http`, no protocol-relative
     `url(//` and no remote `@import`.
  4. **Bytes and licenses.** Every woff2 starts with `wOF2`, and the three OFL
     texts sit beside them and name the SIL Open Font License.
  5. **Faces by role (D-10).** The `:root` and `--mg-font-*` stacks equal the book
     stacks in `brandbook/tokens.json`; `h1, h2, h3` (and the `.mg-admin-root`
     mirror) use Funnel Display, body uses Atkinson Hyperlegible Next, code uses
     Atkinson Hyperlegible Mono with ligatures off.
  6. **Tabular numerals in dense text (D-10).** The bundle declares
     `font-variant-numeric: tabular-nums` for `time` and `td` (every desktop
     email list row), and the mobile email list containers in
     `operator/deliveries_list.ex` and `inbound/records_list.ex` carry the
     `tabular-nums` utility so card rows inherit it.

  ## Teeth

  Every check is a pure function over `(css, file names, tokens)`. The "detectors
  have teeth" block feeds each one a known violation and expects a named failure,
  so a pass is not vacuous.

  `font-bold` resolves to the 600 face through `--font-weight-bold` (D-09); the
  retired v1 faces are 404s (`assets_test.exs`), not spelled out here.
  """

  use ExUnit.Case, async: true

  alias MailglassAdmin.Controllers.Assets

  @static_dir Path.join(Application.app_dir(:mailglass_admin, "priv"), "static")
  @css_path Path.join(@static_dir, "app.css")
  @fonts_dir Path.join(@static_dir, "fonts")
  @tokens_path Path.expand("../../../brandbook/tokens.json", __DIR__)

  @list_sources [
    {"operator-deliveries-list",
     Path.expand("../../lib/mailglass_admin/operator/deliveries_list.ex", __DIR__)},
    {"inbound-records-list",
     Path.expand("../../lib/mailglass_admin/inbound/records_list.ex", __DIR__)}
  ]

  # {family, style, weight, file}: the six faces the book ships (RESEARCH, D-02).
  @expected_faces [
    {"Atkinson Hyperlegible Mono", "normal", 400, "a-mono-400.woff2"},
    {"Atkinson Hyperlegible Mono", "normal", 600, "a-mono-600.woff2"},
    {"Atkinson Hyperlegible Next", "italic", 400, "ui-400i.woff2"},
    {"Atkinson Hyperlegible Next", "normal", 400, "ui-400.woff2"},
    {"Atkinson Hyperlegible Next", "normal", 600, "ui-600.woff2"},
    {"Funnel Display", "normal", 600, "a-display-600.woff2"}
  ]

  @ofl_files ~w(
    OFL-AtkinsonHyperlegibleMono.txt
    OFL-AtkinsonHyperlegibleNext.txt
    OFL-FunnelDisplay.txt
  )

  @heading_selectors ["h1,h2,h3", ".mg-admin-root h1,.mg-admin-root h2,.mg-admin-root h3"]
  @mono_selectors [
    "code,pre,.mono",
    ".mg-admin-root code,.mg-admin-root pre,.mg-admin-root .mono"
  ]

  # ---------------------------------------------------------------------------
  # Inputs

  defp css, do: File.read!(@css_path)

  defp woff2_names do
    @fonts_dir |> File.ls!() |> Enum.filter(&String.ends_with?(&1, ".woff2")) |> Enum.sort()
  end

  defp tokens, do: @tokens_path |> File.read!() |> Jason.decode!()

  defp list_sources do
    for {testid, path} <- @list_sources, do: {testid, File.read!(path)}
  end

  # ---------------------------------------------------------------------------
  # Parsing the compiled (minified) bundle. Tolerant on purpose: the family is
  # unquoted, `url()` is unquoted and there is no space before `format` in the
  # pinned Tailwind's output, but a quoted form must parse the same.

  defp face_blocks(css) do
    ~r/@font-face\s*\{([^}]*)\}/ |> Regex.scan(css) |> Enum.map(&List.last/1)
  end

  defp declaration(block, property) do
    case Regex.run(~r/(?:^|[;{\s])#{Regex.escape(property)}\s*:\s*([^;}]+)/, block) do
      [_all, value] -> String.trim(value)
      nil -> nil
    end
  end

  defp strip_quotes(nil), do: nil
  defp strip_quotes(value), do: String.replace(value, ["\"", "'"], "")

  defp face_file(block) do
    case Regex.run(~r/url\(\s*["']?\.\/fonts\/([^"')\s]+)/, block) do
      [_all, file] -> file
      nil -> nil
    end
  end

  # Document-order list of %{family, style, weight, file, display}.
  defp faces(css) do
    for block <- face_blocks(css) do
      %{
        family: block |> declaration("font-family") |> strip_quotes(),
        style: declaration(block, "font-style"),
        weight: block |> declaration("font-weight") |> to_integer(),
        file: face_file(block),
        display: declaration(block, "font-display")
      }
    end
  end

  defp to_integer(nil), do: nil

  defp to_integer(value) do
    case Integer.parse(value) do
      {int, _rest} -> int
      :error -> nil
    end
  end

  defp css_font_files(css) do
    ~r/url\(\s*["']?\.\/fonts\/([^"')\s]+)/
    |> Regex.scan(css)
    |> Enum.map(&List.last/1)
    |> Enum.sort()
  end

  # Quote- and whitespace-insensitive form of a font stack.
  defp normalize_stack(stack) do
    stack
    |> strip_quotes()
    |> String.replace(~r/\s*,\s*/, ",")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  # The bodies of every rule whose selector list is exactly `selector` (compiled form).
  defp rule_bodies(css, selector) do
    ~r/(?:^|\})#{Regex.escape(selector)}\{([^{}]*)\}/
    |> Regex.scan(css)
    |> Enum.map(&List.last/1)
  end

  # ---------------------------------------------------------------------------
  # Checks. Each returns a list of failure strings; [] means the check holds.

  defp set_failures(css, woff2, allowed) do
    urls = css_font_files(css)
    allowed = Enum.sort(allowed)

    disk_vs_list =
      if woff2 == allowed,
        do: [],
        else: [
          "woff2 files on disk #{inspect(woff2)} differ from allowed_fonts #{inspect(allowed)}"
        ]

    css_vs_disk =
      if urls == woff2,
        do: [],
        else: [
          "@font-face URL files #{inspect(urls)} differ from woff2 files on disk #{inspect(woff2)}"
        ]

    disk_vs_list ++ css_vs_disk
  end

  defp face_failures(css) do
    actual = faces(css)

    expected_keys =
      for {family, style, weight, _file} <- @expected_faces, do: {family, style, weight}

    wrong_file =
      for {family, style, weight, file} <- @expected_faces,
          match =
            Enum.find(
              actual,
              &(&1.family == family and &1.style == style and &1.weight == weight)
            ),
          match.file != file,
          do:
            "face #{family} #{style} #{weight} points at #{inspect(match.file)}, expected #{file}"

    absent =
      for {family, style, weight, _file} <- @expected_faces,
          not Enum.any?(
            actual,
            &(&1.family == family and &1.style == style and &1.weight == weight)
          ),
          do: "face missing: #{family} #{style} #{weight}"

    extra =
      for face <- actual,
          {face.family, face.style, face.weight} not in expected_keys,
          do: "unexpected face: #{inspect(face.family)} #{face.style} #{inspect(face.weight)}"

    swap =
      for face <- actual,
          face.display != "swap",
          do: "face #{face.family} #{face.style} #{face.weight} lacks font-display: swap"

    funnel_weights = Enum.sort(for f <- actual, f.family == "Funnel Display", do: f.weight)

    funnel =
      if funnel_weights == [600],
        do: [],
        else: ["Funnel Display must ship at 600 only, got #{inspect(funnel_weights)}"]

    wrong_file ++ absent ++ extra ++ swap ++ funnel
  end

  defp local_only_failures(css) do
    remote_url = ~r/url\(\s*["']?(?:https?:)?\/\/[^)]*\)?/
    remote_import = ~r/@import\s+(?:url\()?\s*["']?(?:https?:)?\/\/[^;]*/

    for {pattern, label} <- [
          {remote_url, "remote or protocol-relative url()"},
          {remote_import, "remote @import"}
        ],
        match <- Regex.run(pattern, css) |> List.wrap(),
        do: "#{label} in the bundle: #{String.slice(match, 0, 80)}"
  end

  defp stack_failures(css, tokens) do
    root =
      case Regex.scan(~r/\{([^{}]*--font-ui:[^{}]*)\}/, css) do
        [] -> ""
        blocks -> blocks |> List.last() |> List.last()
      end

    for role <- ~w(display ui mono),
        stack = normalize_stack(get_in(tokens, ["font", role, "$value"])),
        {label, source} <- [{"--font-#{role}", root}, {"--mg-font-#{role}", css}],
        failure <- stack_failure(label, role, stack, declaration(source, label)),
        do: failure
  end

  defp stack_failure(label, _role, _stack, nil), do: ["#{label} is not declared in the bundle"]

  defp stack_failure(label, role, stack, found) do
    if normalize_stack(found) == stack,
      do: [],
      else: [
        "#{label} is #{inspect(normalize_stack(found))}, tokens.json font.#{role} says #{inspect(stack)}"
      ]
  end

  defp role_failures(css) do
    heading =
      for selector <- @heading_selectors,
          bodies = rule_bodies(css, selector),
          not Enum.any?(bodies, &(strip_quotes(&1) =~ ~r/font-family:\s*Funnel Display\b/)),
          do: "heading rule `#{selector}` does not use Funnel Display"

    mono =
      for selector <- @mono_selectors,
          bodies = rule_bodies(css, selector),
          not Enum.any?(bodies, fn body ->
            strip_quotes(body) =~ ~r/font-family:\s*Atkinson Hyperlegible Mono\b/ and
              body =~ ~r/font-variant-ligatures:\s*none/
          end),
          do: "code rule `#{selector}` lacks Atkinson Hyperlegible Mono with ligatures off"

    body =
      if Enum.any?(
           rule_bodies(css, "body"),
           &(strip_quotes(&1) =~ ~r/font-family:\s*Atkinson Hyperlegible Next\b/)
         ),
         do: [],
         else: ["body rule does not use Atkinson Hyperlegible Next"]

    heading ++ mono ++ body
  end

  defp font_failures(css, woff2, allowed, tokens) do
    set_failures(css, woff2, allowed) ++
      face_failures(css) ++
      local_only_failures(css) ++
      stack_failures(css, tokens) ++
      role_failures(css)
  end

  defp tabular_failures(css, list_sources) do
    rule? =
      ~r/([^{}]+)\{([^{}]*)\}/
      |> Regex.scan(css)
      |> Enum.any?(fn [_all, selector, body] ->
        selectors = selector |> String.split(",") |> Enum.map(&String.trim/1)

        "time" in selectors and "td" in selectors and
          body =~ ~r/font-variant-numeric:\s*tabular-nums/
      end)

    css_failures =
      if rule?,
        do: [],
        else: ["no rule declares font-variant-numeric: tabular-nums for `time, td`"]

    list_failures =
      for {testid, source} <- list_sources,
          not list_tag_has_utility?(source, testid),
          do: "the <ul> with data-testid=\"#{testid}\" does not carry the tabular-nums utility"

    css_failures ++ list_failures
  end

  # The opening <ul ...> tag that carries the test id, and whether its class has the utility.
  defp list_tag_has_utility?(source, testid) do
    tag =
      ~r/<ul\b[^>]*data-testid="#{Regex.escape(testid)}"[^>]*>/
      |> Regex.run(source)
      |> List.wrap()
      |> List.first()

    case tag do
      nil -> false
      tag -> tag =~ ~r/class="(?:[^"]*\s)?tabular-nums(?:\s[^"]*)?"/
    end
  end

  defp magic_failures(files) do
    for {name, bytes} <- files,
        not match?(<<"wOF2", _::binary>>, bytes),
        do: "#{name} does not start with the wOF2 signature"
  end

  defp ofl_failures(names, read) do
    missing = for name <- @ofl_files, name not in names, do: "missing OFL text #{name}"

    unlicensed =
      for name <- @ofl_files,
          name in names,
          not (read.(name) =~ "SIL Open Font License"),
          do: "#{name} does not name the SIL Open Font License"

    missing ++ unlicensed
  end

  # ---------------------------------------------------------------------------
  # The real bundle, tree and sources

  describe "the admin fonts are local, listed and pinned" do
    test "disk, allow-list and @font-face URLs are the same six names" do
      assert woff2_names() == Assets.allowed_fonts()
      assert css_font_files(css()) == woff2_names()
      assert length(woff2_names()) == 6
    end

    test "the compiled bundle carries the face table, local URLs, role stacks and ligature rule" do
      assert font_failures(css(), woff2_names(), Assets.allowed_fonts(), tokens()) == []
    end

    test "the face table is exactly the six brand faces" do
      table =
        css() |> faces() |> Enum.map(&{&1.family, &1.style, &1.weight, &1.file}) |> Enum.sort()

      assert table == Enum.sort(@expected_faces)
    end

    test "every woff2 starts with wOF2" do
      files = Map.new(woff2_names(), &{&1, File.read!(Path.join(@fonts_dir, &1))})

      assert magic_failures(files) == []
    end

    test "the three OFL texts sit beside the fonts and name the license" do
      names = File.ls!(@fonts_dir)

      assert ofl_failures(names, &File.read!(Path.join(@fonts_dir, &1))) == []
      assert Enum.sort(Enum.filter(names, &String.starts_with?(&1, "OFL-"))) == @ofl_files
    end

    test "the bundle never mentions a remote font or stylesheet" do
      assert local_only_failures(css()) == []
    end

    test "email list rows use tabular numerals (desktop td, mobile list containers)" do
      assert tabular_failures(css(), list_sources()) == []
    end

    test "bold maps to the 600 face and no 700 weight is declared" do
      css = css()

      assert css =~ "--font-weight-bold:600"
      refute css =~ "font-weight:700"
    end
  end

  describe "detectors have teeth (fail-first proof)" do
    setup do
      %{css: css(), woff2: woff2_names(), allowed: Assets.allowed_fonts(), tokens: tokens()}
    end

    defp named(failures, fragment) do
      assert Enum.any?(failures, &(&1 =~ fragment)),
             "expected a failure naming #{inspect(fragment)}, got #{inspect(failures)}"
    end

    test "a face pointing at the wrong file is named", ctx do
      mutated = String.replace(ctx.css, "url(./fonts/ui-600.woff2)", "url(./fonts/ui-400.woff2)")

      failures = font_failures(mutated, ctx.woff2, ctx.allowed, ctx.tokens)

      named(failures, "Atkinson Hyperlegible Next normal 600 points at \"ui-400.woff2\"")
    end

    test "a missing face is named", ctx do
      mutated = Regex.replace(~r/@font-face\{font-family:Funnel Display[^}]*\}/, ctx.css, "")

      failures = font_failures(mutated, ctx.woff2, ctx.allowed, ctx.tokens)

      assert mutated != ctx.css
      named(failures, "face missing: Funnel Display normal 600")
    end

    test "an extra font file on disk or in the allow-list is named", ctx do
      failures = font_failures(ctx.css, ctx.woff2 ++ ["extra-700.woff2"], ctx.allowed, ctx.tokens)
      named(failures, "differ from allowed_fonts")

      failures = font_failures(ctx.css, ctx.woff2, ctx.allowed ++ ["extra-700.woff2"], ctx.tokens)
      named(failures, "differ from allowed_fonts")
    end

    test "a face the allow-list does not list is named", ctx do
      allowed = List.delete(ctx.allowed, "ui-600.woff2")

      named(font_failures(ctx.css, ctx.woff2, allowed, ctx.tokens), "differ from allowed_fonts")
    end

    test "a face without font-display swap is named", ctx do
      mutated = String.replace(ctx.css, "font-display:swap", "font-display:block", global: false)

      named(
        font_failures(mutated, ctx.woff2, ctx.allowed, ctx.tokens),
        "lacks font-display: swap"
      )
    end

    test "a remote url is named", ctx do
      mutated = ctx.css <> ".x{background:url(https://cdn.example.com/a.woff2)}"

      named(
        font_failures(mutated, ctx.woff2, ctx.allowed, ctx.tokens),
        "remote or protocol-relative url()"
      )
    end

    test "a protocol-relative url is named", ctx do
      mutated = ctx.css <> ".x{background:url(//cdn.example.com/a.woff2)}"

      named(
        font_failures(mutated, ctx.woff2, ctx.allowed, ctx.tokens),
        "remote or protocol-relative url()"
      )
    end

    test "a remote @import is named, quoted or in url() form", ctx do
      for import <- [
            "@import url(\"https://fonts.example.com/css?family=X\");",
            "@import \"//fonts.example.com/x.css\";"
          ] do
        mutated = import <> ctx.css

        named(font_failures(mutated, ctx.woff2, ctx.allowed, ctx.tokens), "remote @import")
      end
    end

    test "a stack that drifts from tokens.json is named", ctx do
      tokens = put_in(ctx.tokens, ["font", "ui", "$value"], "'Some Other Face', sans-serif")

      named(font_failures(ctx.css, ctx.woff2, ctx.allowed, tokens), "tokens.json font.ui says")
    end

    test "a heading rule that does not use Funnel Display is named", ctx do
      mutated =
        String.replace(
          ctx.css,
          "h1,h2,h3{letter-spacing:-.02em;font-family:Funnel Display,",
          "h1,h2,h3{letter-spacing:-.02em;font-family:Arial,"
        )

      assert mutated != ctx.css
      named(font_failures(mutated, ctx.woff2, ctx.allowed, ctx.tokens), "heading rule `h1,h2,h3`")
    end

    test "a code rule without ligatures off is named", ctx do
      mutated =
        String.replace(ctx.css, "code,pre,.mono{font-variant-ligatures:none;", "code,pre,.mono{")

      assert mutated != ctx.css

      named(
        font_failures(mutated, ctx.woff2, ctx.allowed, ctx.tokens),
        "code rule `code,pre,.mono`"
      )
    end

    test "a file that is not woff2 is named" do
      named(
        magic_failures(%{"ui-400.woff2" => "<html>"}),
        "ui-400.woff2 does not start with the wOF2"
      )
    end

    test "a missing or unlicensed OFL text is named" do
      names = ["OFL-FunnelDisplay.txt", "OFL-AtkinsonHyperlegibleNext.txt"]

      named(
        ofl_failures(names, fn _ -> "SIL Open Font License" end),
        "missing OFL text OFL-AtkinsonHyperlegibleMono.txt"
      )

      named(
        ofl_failures(names, fn _ -> "all rights reserved" end),
        "does not name the SIL Open Font License"
      )
    end

    test "removing the time, td tabular-nums rule from the CSS is named", ctx do
      mutated = String.replace(ctx.css, "time,td{font-variant-numeric:tabular-nums}", "")

      assert mutated != ctx.css
      named(tabular_failures(mutated, list_sources()), "for `time, td`")
    end

    test "stripping tabular-nums from either list container is named", ctx do
      for {testid, _source} <- list_sources() do
        stripped =
          for {id, source} <- list_sources() do
            if id == testid, do: {id, strip_utility(source, id)}, else: {id, source}
          end

        failures = tabular_failures(ctx.css, stripped)

        assert Enum.any?(failures, &(&1 =~ testid)),
               "stripping the utility from #{testid} must be named, got #{inspect(failures)}"
      end
    end

    test "a list container that is absent is named", ctx do
      named(
        tabular_failures(ctx.css, [{"operator-deliveries-list", "<ul class=\"x\"></ul>"}]),
        "operator-deliveries-list"
      )
    end
  end

  # Removes the tabular-nums class from the opening <ul> that carries `testid`.
  defp strip_utility(source, testid) do
    Regex.replace(
      ~r/(<ul\b[^>]*data-testid="#{Regex.escape(testid)}"[^>]*>)/,
      source,
      fn tag, _ -> String.replace(tag, " tabular-nums", "") end
    )
  end
end
