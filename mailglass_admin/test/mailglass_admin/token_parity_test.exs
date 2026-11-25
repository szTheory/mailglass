defmodule MailglassAdmin.TokenParityTest do
  @moduledoc """
  Fail-closed parity between the brand token oracle, the compiled bundle and the
  pinned brand book (TOKEN-04, BRTOK-01, BRTOK-05).

  ## What is checked

  1. **Three compiled blocks x every role.** `brandbook/tokens.json` is the oracle.
     Each of its roles (39 `--mg-color-*` plus the 2 logo roles `--mg-logo-glass`
     and `--mg-logo-overlap`, per theme tier) is compared with the hex inlined in
     `priv/static/app.css`, in all three blocks that carry them: the light
     `:root,[data-theme=light],[data-theme=mailglass-light]` block, the
     `[data-theme=dark],[data-theme=mailglass-dark]` block, and the
     `@media (prefers-color-scheme:dark)` system block. Each block is selected by
     its exact compiled selector and there must be exactly one of each kind. A
     block that declares a token the oracle does not know is red too. The system
     block matters: Phase 180 D-10 relies on it for the OS-dark default and
     nothing else reads it.
  2. **Palette provenance.** Every `palette` entry in `tokens.json` is either a
     brand-book colour (`$extensions.mailglass.book`, a path into
     `brandbook/v2/brand.json` with list items matched by `name`/`word`, whose
     hex must equal the palette hex) or a designed composite
     (`$extensions.mailglass.designed`, `over` + `color` + `alpha`, recomputed with
     `MailglassAdmin.TestSupport.Contrast.composite/3` to the stored hex). An entry
     with neither is red: no hue outside the book exists. No `{palette.x}` alias
     may dangle.
  3. **Slot map.** Every daisyUI `--color-*` slot in both themes references the
     expected `var(--mg-*)` role and no theme selector carries a raw hex (TOKEN-01).

  ## Why the old "36 slots" wording is gone

  The original requirement said "36 slots". That was never a number in the code:
  each theme tier declares 39 `--mg-color-*` roles plus 2 logo roles, those feed
  20 daisyUI `--color-*` slots, and the 20 slots consume 15 of the 39 roles. The
  requirement, the roadmap and PROJECT.md now say that (Phase 181 D-01). Do not
  restore "36".

  ## Teeth

  Every comparison is a pure function over `(css, tokens, brand)`. The "detectors
  have teeth" tests mutate one value in each block, remove a declaration, plant an
  extra one, duplicate or remove a block, plant an off-book palette hex, a
  provenance-free entry, an unreproducible composite and a dangling alias, and
  expect red, so a pass is not vacuous.

  If a parity test fails with a value mismatch, either `brandbook/tokens.json` /
  `tokens.css` changed without a rebuild, or `app.css` was hand-edited. Run
  `cd mailglass_admin && mix mailglass_admin.assets.build` and commit
  `priv/static/`. Never hand-edit `priv/static/app.css`.
  """

  use ExUnit.Case, async: true

  alias MailglassAdmin.TestSupport.Contrast

  @css_path Path.join([
              Application.app_dir(:mailglass_admin, "priv"),
              "static",
              "app.css"
            ])

  @css_source_path Path.expand("../../assets/css/app.css", __DIR__)
  @design_system_path Path.expand("../../docs/design-system.md", __DIR__)
  @gallery_path Path.expand("../../lib/mailglass_admin/gallery_live.ex", __DIR__)
  @storybook_path Path.expand(
                    "../../../reference/demo_app/dev/mailglass_demo_web/storybook.ex",
                    __DIR__
                  )
  @demo_router_path Path.expand(
                      "../../../reference/demo_app/lib/mailglass_demo_web/router.ex",
                      __DIR__
                    )
  @root_layout_path Path.expand("../../lib/mailglass_admin/layouts/root.html.heex", __DIR__)

  @shared_spacing_template_paths Enum.map(
                                   [
                                     "../../lib/mailglass_admin/operator/shell.ex",
                                     "../../lib/mailglass_admin/components.ex",
                                     "../../lib/mailglass_admin/operator/quick_view.ex",
                                     "../../lib/mailglass_admin/inbound/quick_view.ex",
                                     "../../lib/mailglass_admin/inbound/evidence_card.ex",
                                     "../../lib/mailglass_admin/preview_live.ex",
                                     "../../lib/mailglass_admin/preview/sidebar.ex"
                                   ],
                                   &Path.expand(&1, __DIR__)
                                 )

  # Three levels up from test/mailglass_admin/ → test/ → mailglass_admin/ → monorepo root → brandbook/
  @tokens_path Path.expand(Path.join([__DIR__, "..", "..", "..", "brandbook", "tokens.json"]))
  @brand_path Path.expand(Path.join([__DIR__, "..", "..", "..", "brandbook", "v2", "brand.json"]))

  # The three compiled blocks that carry the --mg-* roles, selected by their exact
  # compiled selector (pinned Tailwind 4.1.12 output). daisyUI also emits
  # `:root:not([data-theme]){...}` inside a media rule; it carries no --mg-* hex and
  # is excluded because the selector must match exactly.
  # {label, tokens.json tier, exact selector}
  @blocks [
    {"light block", "light", ":root,[data-theme=light],[data-theme=mailglass-light]"},
    {"dark block", "dark", "[data-theme=dark],[data-theme=mailglass-dark]"},
    {"system block", "dark", ":root:not([data-theme=light]):not([data-theme=mailglass-light])"}
  ]

  # Role inventory contract per theme tier (D-01): 39 colour roles + 2 logo roles.
  @color_role_count 39
  @logo_role_count 2

  # Full slot-to-role contract for both themes. This map IS the contract;
  # a token rename forces a deliberate edit here.
  # Each entry: {theme_name, daisyui_slot} => {mg_token_name, :light | :dark}
  # The second element indicates which tier of tokens.json to use as oracle.
  @mapping %{
    # mailglass-light theme uses color.light tier
    {"mailglass-light", "--color-base-100"} => {"--mg-color-background", :light},
    {"mailglass-light", "--color-base-200"} => {"--mg-color-surface-raised", :light},
    {"mailglass-light", "--color-base-300"} => {"--mg-color-border", :light},
    {"mailglass-light", "--color-base-content"} => {"--mg-color-text", :light},
    {"mailglass-light", "--color-primary"} => {"--mg-color-accent", :light},
    {"mailglass-light", "--color-primary-content"} => {"--mg-color-background", :light},
    {"mailglass-light", "--color-secondary"} => {"--mg-color-text-muted", :light},
    {"mailglass-light", "--color-secondary-content"} => {"--mg-color-background", :light},
    {"mailglass-light", "--color-accent"} => {"--mg-color-accent", :light},
    {"mailglass-light", "--color-accent-content"} => {"--mg-color-text-inverse", :light},
    {"mailglass-light", "--color-neutral"} => {"--mg-color-text-muted", :light},
    {"mailglass-light", "--color-neutral-content"} => {"--mg-color-background", :light},
    {"mailglass-light", "--color-info"} => {"--mg-color-info-solid", :light},
    {"mailglass-light", "--color-info-content"} => {"--mg-color-text-inverse", :light},
    {"mailglass-light", "--color-success"} => {"--mg-color-success-solid", :light},
    {"mailglass-light", "--color-success-content"} => {"--mg-color-success-on-solid", :light},
    {"mailglass-light", "--color-warning"} => {"--mg-color-warning-solid", :light},
    {"mailglass-light", "--color-warning-content"} => {"--mg-color-warning-on-solid", :light},
    {"mailglass-light", "--color-error"} => {"--mg-color-error-solid", :light},
    {"mailglass-light", "--color-error-content"} => {"--mg-color-error-on-solid", :light},

    # mailglass-dark theme uses color.dark tier
    {"mailglass-dark", "--color-base-100"} => {"--mg-color-background", :dark},
    {"mailglass-dark", "--color-base-200"} => {"--mg-color-surface-raised", :dark},
    {"mailglass-dark", "--color-base-300"} => {"--mg-color-border", :dark},
    {"mailglass-dark", "--color-base-content"} => {"--mg-color-text", :dark},
    {"mailglass-dark", "--color-primary"} => {"--mg-color-accent", :dark},
    {"mailglass-dark", "--color-primary-content"} => {"--mg-color-text-inverse", :dark},
    {"mailglass-dark", "--color-secondary"} => {"--mg-color-text-muted", :dark},
    {"mailglass-dark", "--color-secondary-content"} => {"--mg-color-text-inverse", :dark},
    {"mailglass-dark", "--color-accent"} => {"--mg-color-accent", :dark},
    {"mailglass-dark", "--color-accent-content"} => {"--mg-color-text-inverse", :dark},
    {"mailglass-dark", "--color-neutral"} => {"--mg-color-text-muted", :dark},
    {"mailglass-dark", "--color-neutral-content"} => {"--mg-color-text-inverse", :dark},
    {"mailglass-dark", "--color-info"} => {"--mg-color-info-solid", :dark},
    {"mailglass-dark", "--color-info-content"} => {"--mg-color-info-on-solid", :dark},
    {"mailglass-dark", "--color-success"} => {"--mg-color-success-solid", :dark},
    {"mailglass-dark", "--color-success-content"} => {"--mg-color-success-on-solid", :dark},
    {"mailglass-dark", "--color-warning"} => {"--mg-color-warning-solid", :dark},
    {"mailglass-dark", "--color-warning-content"} => {"--mg-color-warning-on-solid", :dark},
    {"mailglass-dark", "--color-error"} => {"--mg-color-error-solid", :dark},
    {"mailglass-dark", "--color-error-content"} => {"--mg-color-error-on-solid", :dark}
  }

  setup_all do
    assert File.exists?(@tokens_path),
           "tokens.json not found at #{@tokens_path} — run from mailglass_admin/"

    {:ok,
     tokens: Jason.decode!(File.read!(@tokens_path)),
     brand: Jason.decode!(File.read!(@brand_path))}
  end

  setup do
    css = File.read!(@css_path)
    {:ok, css: css}
  end

  test "shared workspace templates stay on the 4px spacing grid" do
    half_step_spacing =
      ~r/(?:^|[\s"'`])(?:[^\s"'`]*:)*(-?(?:m(?:t|r|b|l|x|y|s|e)?|p(?:t|r|b|l|x|y|s|e)?|gap(?:-[xy])?|space-[xy])-0\.5)(?=$|[\s"'`])/

    unsupported_2xs_spacing =
      ~r/(?:^|[\s"'`])(?:[^\s"'`]*:)*(-?(?:m(?:t|r|b|l|x|y|s|e)?|p(?:t|r|b|l|x|y|s|e)?|gap(?:-[xy])?|space-[xy])-2xs)(?=$|[\s"'`])/

    assert Regex.match?(half_step_spacing, " hover:-mt-0.5 "),
           "Spacing guard must detect variant-prefixed negative half-step margins"

    assert Regex.match?(unsupported_2xs_spacing, " sm:-mt-2xs "),
           "Spacing guard must detect variant-prefixed negative 2xs margins"

    assert Regex.match?(half_step_spacing, " supports-[display:grid]:-mt-0.5 "),
           "Spacing guard must detect negative half-step margins after arbitrary variants"

    assert Regex.match?(unsupported_2xs_spacing, " [&:hover]:sm:-mt-2xs "),
           "Spacing guard must detect negative 2xs margins after bracketed variants"

    assert Regex.match?(half_step_spacing, " [&:has([data-state=open])]:-mt-0.5 "),
           "Spacing guard must detect negative half-step margins after nested arbitrary variants"

    assert Regex.match?(half_step_spacing, " group-hover/item:-mt-0.5 "),
           "Spacing guard must detect negative half-step margins after slash-qualified variants"

    violations =
      Enum.flat_map(@shared_spacing_template_paths, fn path ->
        source = File.read!(path)

        [half_step_spacing, unsupported_2xs_spacing]
        |> Enum.flat_map(fn pattern ->
          Regex.scan(pattern, source, capture: :all_but_first)
          |> Enum.map(fn [class] -> "#{path}: #{class}" end)
        end)
      end)

    assert violations == [],
           "Unsupported Tailwind spacing classes are outside the approved 4px grid:\n" <>
             Enum.join(violations, "\n")

    source_css = File.read!(@css_source_path)
    bundle = File.read!(@css_path)

    assert source_css =~ ~r/--spacing-xs:\s*4px;/,
           "Source CSS must define xs spacing as 4px"

    assert bundle =~ ~r/--spacing-xs:\s*4px/,
           "Generated CSS must define xs spacing as 4px"

    assert bundle =~ ~r/\.mt-xs\s*\{\s*margin-top:\s*var\(--spacing-xs\)\s*\}/,
           "Generated CSS must resolve .mt-xs through --spacing-xs"

    assert bundle =~ ~r/\.gap-xs\s*\{\s*gap:\s*var\(--spacing-xs\)\s*\}/,
           "Generated CSS must resolve .gap-xs through --spacing-xs"
  end

  test "Quick view positioning is consolidated into source and served CSS" do
    source = File.read!(@css_source_path)
    layout = File.read!(@root_layout_path)
    bundle = File.read!(@css_path)

    for {label, stylesheet} <- [{"source", source}, {"bundle", bundle}] do
      assert stylesheet =~ ~r/\.mg-detail-panel\s*\{[^}]*position:\s*fixed/s,
             "Quick view panel positioning is missing from #{label} CSS"

      assert stylesheet =~
               ~r/\.mg-detail-panel\s*\{[^}]*max-height:\s*90vh[^}]*overflow-y:\s*auto/s,
             "Quick view mobile panel must keep a bounded scroll region in #{label} CSS"

      assert stylesheet =~
               ~r/@media\s*\(min-width:\s*768px\)[^{]*\{[^}]*\.mg-detail-panel\s*\{[^}]*max-width:\s*42rem/s,
             "Quick view desktop panel width is missing from #{label} CSS"
    end

    refute layout =~ ".mg-detail-panel",
           "Quick view positioning must not be duplicated in root.html.heex"
  end

  test "design-system guide matches current token ownership, scales, and review surfaces" do
    guide = @design_system_path |> File.read!() |> String.replace(~r/\s+/, " ")
    source_css = File.read!(@css_source_path)
    gallery = File.read!(@gallery_path)
    storybook = File.read!(@storybook_path)
    demo_router = File.read!(@demo_router_path)
    tokens = File.read!(Path.expand("../../../brandbook/tokens.css", __DIR__))

    assert guide =~ "brandbook/v2/brand.json and brandbook/tokens.json define identity and voice"
    assert guide =~ "brandbook/tokens.css mirrors the resolved token source"
    assert guide =~ "Funnel Display at 600 for headings"
    assert guide =~ "Atkinson Hyperlegible Next at 400 or 600 for body and interface text"
    assert guide =~ "brandbook/status-marks.json"
    assert guide =~ "assets/css/app.css maps those values"
    assert guide =~ "base-200 | White #FFFFFF | Roast Surface #2A211B"
    assert guide =~ "14/16/20/28px"
    assert guide =~ "/dev/mail/gallery"
    assert guide =~ "/dev/storybook"
    assert guide =~ "Host applications"
    assert guide =~ "Historical screenshots and visual scores"
    refute guide =~ "Ask for a per-pillar before/after score"

    assert source_css =~ "--color-base-200: var(--mg-color-surface-raised)"
    assert source_css =~ "--color-base-300: var(--mg-color-border)"
    assert source_css =~ ~r/--text-label:\s*0\.875rem;/
    assert source_css =~ ~r/--text-body:\s*1rem;/
    assert source_css =~ ~r/--text-heading:\s*1\.25rem;/
    assert source_css =~ ~r/--text-display:\s*1\.75rem;/
    assert source_css =~ ~r/--size-control-sm:\s*36px;/
    assert source_css =~ ~r/--size-control-md:\s*44px;/
    assert source_css =~ ~r/--size-control-lg:\s*52px;/
    assert tokens =~ "--mg-color-surface-raised: #FFFFFF;"
    assert gallery =~ "/dev/mail/gallery"
    assert demo_router =~ "live_storybook(\"/dev/storybook\""
    assert demo_router =~ "assets_path: \"/dev/storybook/assets\""

    assert storybook =~
             "css_path: \"/dev/mail/css-\" <> MailglassAdmin.Controllers.Assets.css_hash()"
  end

  @tag :token_parity
  test "no raw hex in any --color-* line inside daisyUI theme selectors (TOKEN-01)", %{css: css} do
    for theme <- ["mailglass-light", "mailglass-dark"],
        block <- theme_blocks_matching(css, ["[data-theme=#{theme}]"]) do
      refute block =~ ~r/--color-[a-z0-9-]+:\s*#[0-9a-fA-F]/,
             "TOKEN-01 violation: raw hex literal on a --color-* line inside #{theme}. " <>
               "All --color-* values must reference var(--mg-*). Run mix mailglass_admin.assets.build."
    end
  end

  @tag :token_parity
  test "every --color-* slot references its --mg-* role and resolves to the oracle value",
       %{css: css, tokens: tokens} do
    assert map_size(@mapping) == 40, "the slot map must hold 20 daisyUI slots per theme"

    oracle = Contrast.resolve_tokens(tokens)

    mismatches =
      Enum.flat_map(@mapping, fn {{theme, slot}, {mg_token, tier}} ->
        theme_block = theme_blocks_matching(css, ["[data-theme=#{theme}]"]) |> Enum.join(";")
        slot_pattern = ~r/(^|;)#{Regex.escape(slot)}:\s*var\(#{Regex.escape(mg_token)}\)/
        tier_name = Atom.to_string(tier)

        cond do
          not Regex.match?(slot_pattern, theme_block) ->
            [
              "#{theme} #{slot} must reference var(#{mg_token}); " <>
                "actual: #{extract_slot_value(theme_block, slot)}. " <>
                "Bundle is stale or app.css hand-edited — run mix mailglass_admin.assets.build"
            ]

          not Map.has_key?(oracle, {tier_name, mg_token}) ->
            [
              "#{theme} #{slot}: #{mg_token} has no token oracle in tokens.json " <>
                "(#{tier_name} tier). Update brandbook/tokens.json or the parity mapping."
            ]

          true ->
            []
        end
      end)

    assert mismatches == [],
           "Token parity failures (#{length(mismatches)} slot(s)):\n" <>
             Enum.join(mismatches, "\n")
  end

  describe "three-block parity of every role (D-04)" do
    test "the oracle declares 39 colour roles and 2 logo roles per theme tier", %{tokens: tokens} do
      oracle = Contrast.resolve_tokens(tokens)

      for tier <- ["light", "dark"] do
        vars = for {{^tier, var}, _hex} <- oracle, do: var

        assert length(Enum.filter(vars, &String.starts_with?(&1, "--mg-color-"))) ==
                 @color_role_count

        assert length(Enum.filter(vars, &String.starts_with?(&1, "--mg-logo-"))) ==
                 @logo_role_count
      end

      light = for {{"light", var}, _hex} <- oracle, do: var
      dark = for {{"dark", var}, _hex} <- oracle, do: var

      assert Enum.sort(light) == Enum.sort(dark),
             "light and dark tiers must declare the same role names"
    end

    @tag :token_parity
    test "light, dark and system blocks each carry every role at the oracle value",
         %{css: css, tokens: tokens} do
      failures = parity_failures(css, tokens)

      assert failures == [],
             "Token parity failures (#{length(failures)}):\n" <>
               Enum.join(failures, "\n") <>
               "\nRun mix mailglass_admin.assets.build after syncing brandbook/tokens.css."
    end

    test "detectors have teeth: one changed value in any block is red and names that block",
         %{css: css, tokens: tokens} do
      assert parity_failures(css, tokens) == []

      for {label, _tier, selector} <- @blocks,
          var <- ["--mg-color-text", "--mg-color-surface-selected", "--mg-logo-overlap"] do
        mutated = edit_block(css, selector, &replace_value(&1, var, "#010203"))
        refute mutated == css, "mutation of #{var} in the #{label} did not change the css"

        failures = parity_failures(mutated, tokens)

        assert failures != [], "a changed #{var} in the #{label} was not detected"

        assert Enum.all?(failures, &String.starts_with?(&1, label)),
               "a change in the #{label} must be reported against that block only: #{inspect(failures)}"

        assert Enum.any?(failures, &(&1 =~ var))
      end
    end

    test "detectors have teeth: a removed or extra declaration is red", %{
      css: css,
      tokens: tokens
    } do
      for {label, _tier, selector} <- @blocks do
        removed =
          edit_block(css, selector, &Regex.replace(~r/--mg-logo-glass\s*:\s*[^;]+;?/, &1, ""))

        assert Enum.any?(
                 parity_failures(removed, tokens),
                 &(&1 =~ "#{label}: --mg-logo-glass is not declared")
               )

        extra = edit_block(css, selector, &(&1 <> ";--mg-color-bogus:#123456"))

        assert Enum.any?(
                 parity_failures(extra, tokens),
                 &(&1 =~ "#{label}: --mg-color-bogus is declared")
               )
      end
    end

    test "detectors have teeth: a duplicated or missing block is red", %{css: css, tokens: tokens} do
      for {label, _tier, selector} <- @blocks do
        {raw_selector, body} = find_rule(css, selector)

        duplicated = css <> raw_selector <> "{" <> body <> "}"

        assert Enum.any?(
                 parity_failures(duplicated, tokens),
                 &(&1 =~ "#{label}: expected exactly one")
               )

        renamed =
          String.replace(css, raw_selector <> "{", raw_selector <> "-gone{", global: false)

        assert Enum.any?(
                 parity_failures(renamed, tokens),
                 &(&1 =~ "#{label}: expected exactly one")
               )
      end
    end

    test "a named-colour emission is red, not silently skipped", %{css: css, tokens: tokens} do
      mutated =
        edit_block(
          css,
          elem(Enum.at(@blocks, 0), 2),
          &replace_value(&1, "--mg-color-text", "white")
        )

      assert Enum.any?(parity_failures(mutated, tokens), &(&1 =~ "--mg-color-text is white"))
    end
  end

  describe "palette provenance (D-03, D-05)" do
    test "every palette hex is a brand-book hex found by name or a recomputed composite",
         %{tokens: tokens, brand: brand} do
      assert palette_failures(tokens, brand) == []

      palette = Map.drop(tokens["palette"], ["$type"])

      designed =
        for {_key, entry} <- palette,
            get_in(entry, ["$extensions", "mailglass", "designed"]),
            do: entry

      books =
        for {_key, entry} <- palette,
            get_in(entry, ["$extensions", "mailglass", "book"]),
            do: entry

      assert length(designed) == 11,
             "the designed set is link-hover, overlay, selected and eight tints"

      assert length(books) + length(designed) == map_size(palette)
    end

    test "detectors have teeth: an off-book hex, a bare entry, a bad composite and a dangling alias are red",
         %{tokens: tokens, brand: brand} do
      off_book = put_in(tokens, ["palette", "sand", "$value"], "#F6F1E9")
      assert Enum.any?(palette_failures(off_book, brand), &(&1 =~ "palette.sand"))

      bare = put_in(tokens, ["palette", "rogue"], %{"$value" => "#123456"})

      assert Enum.any?(
               palette_failures(bare, brand),
               &(&1 =~ "palette.rogue" and &1 =~ "provenance")
             )

      bad_composite = put_in(tokens, ["palette", "tint-info-light", "$value"], "#E7F0F4")
      assert Enum.any?(palette_failures(bad_composite, brand), &(&1 =~ "palette.tint-info-light"))

      bad_source =
        put_in(
          tokens,
          ["palette", "sand", "$extensions", "mailglass", "book"],
          "color.light[Nope].hex"
        )

      assert Enum.any?(
               palette_failures(bad_source, brand),
               &(&1 =~ "palette.sand" and &1 =~ "not found")
             )

      dangling = put_in(tokens, ["color", "light", "text", "$value"], "{palette.nope}")

      assert Enum.any?(
               palette_failures(dangling, brand),
               &(&1 =~ "dangling" and &1 =~ "palette.nope")
             )

      prose_miss =
        put_in(tokens, ["palette", "control-edge-dark", "$value"], "#8B7D73")

      assert Enum.any?(palette_failures(prose_miss, brand), &(&1 =~ "palette.control-edge-dark"))
    end
  end

  # ---------------------------------------------------------------------------------------
  # Pure comparison functions: (css, tokens, brand) -> [failure string]
  # ---------------------------------------------------------------------------------------

  defp parity_failures(css, tokens) do
    oracle = Contrast.resolve_tokens(tokens)
    rules = rules(css)

    Enum.flat_map(@blocks, fn {label, tier, selector} ->
      case Enum.filter(rules, fn {raw, _body} -> String.trim(raw) == selector end) do
        [{_raw, body}] ->
          block_failures(label, tier, body, oracle)

        found ->
          [
            "#{label}: expected exactly one rule with selector #{selector}, found #{length(found)}"
          ]
      end
    end)
  end

  defp block_failures(label, tier, body, oracle) do
    expected = for {{^tier, var}, hex} <- oracle, into: %{}, do: {var, hex}
    declared = declared_tokens(body)

    wrong_or_missing =
      for {var, want} <- Enum.sort(expected), declared[var] != want do
        case Map.fetch(declared, var) do
          {:ok, got} ->
            "#{label}: #{var} is #{got} but tokens.json (#{tier}) says #{want}"

          :error ->
            "#{label}: #{var} is not declared (tokens.json #{tier} says #{want})"
        end
      end

    extra =
      for var <- Enum.sort(Map.keys(declared) -- Map.keys(expected)) do
        "#{label}: #{var} is declared but tokens.json (#{tier}) has no such role"
      end

    wrong_or_missing ++ extra
  end

  defp palette_failures(tokens, brand) do
    palette = Map.drop(tokens["palette"], ["$type"])

    entry_failures =
      palette
      |> Enum.sort()
      |> Enum.flat_map(fn {key, entry} ->
        ext = get_in(entry, ["$extensions", "mailglass"]) || %{}

        case {Map.has_key?(ext, "book"), Map.has_key?(ext, "designed")} do
          {true, false} ->
            book_failures(key, entry, ext, brand)

          {false, true} ->
            designed_failures(key, entry, ext["designed"], palette)

          {false, false} ->
            ["palette.#{key}: no book or designed provenance (no hue outside the book)"]

          {true, true} ->
            ["palette.#{key}: carries both book and designed provenance"]
        end
      end)

    entry_failures ++ dangling_alias_failures(tokens, palette)
  end

  defp book_failures(key, entry, ext, brand) do
    want = entry["$value"]

    case lookup_book(brand, ext["book"]) do
      :error ->
        ["palette.#{key}: book path #{ext["book"]} not found in brandbook/v2/brand.json"]

      {:ok, found} when is_binary(found) ->
        ok? =
          if ext["prose"] do
            String.contains?(String.downcase(found), String.downcase(want))
          else
            Contrast.normalize_hex(found) == Contrast.normalize_hex(want)
          end

        if ok?,
          do: [],
          else: ["palette.#{key}: #{want} does not match brand.json #{ext["book"]} (#{found})"]

      {:ok, other} ->
        ["palette.#{key}: book path #{ext["book"]} is not a string (#{inspect(other)})"]
    end
  end

  defp designed_failures(
         key,
         entry,
         %{"over" => over, "color" => color, "alpha" => alpha},
         palette
       )
       when is_number(alpha) do
    with {:ok, over_hex} <- palette_hex(palette, over),
         {:ok, color_hex} <- palette_hex(palette, color) do
      recomputed = Contrast.composite(color_hex, over_hex, alpha)

      if recomputed == Contrast.normalize_hex(entry["$value"]),
        do: [],
        else: [
          "palette.#{key}: stored #{entry["$value"]} but #{alpha} of #{color} over #{over} " <>
            "recomputes to #{recomputed}"
        ]
    else
      :error -> ["palette.#{key}: designed source #{over} or #{color} is not a palette entry"]
    end
  end

  defp designed_failures(key, _entry, _designed, _palette),
    do: ["palette.#{key}: designed provenance needs over, color and a numeric alpha"]

  defp palette_hex(palette, key) do
    case get_in(palette, [key, "$value"]) do
      "#" <> _ = hex -> {:ok, hex}
      _ -> :error
    end
  end

  # Every "{palette.x}" alias anywhere in tokens.json must name a palette entry.
  defp dangling_alias_failures(tokens, palette) do
    tokens
    |> alias_refs()
    |> Enum.reject(&Map.has_key?(palette, &1))
    |> Enum.uniq()
    |> Enum.map(&"dangling alias {palette.#{&1}} in tokens.json")
  end

  defp alias_refs(%{} = map), do: map |> Map.values() |> Enum.flat_map(&alias_refs/1)
  defp alias_refs(list) when is_list(list), do: Enum.flat_map(list, &alias_refs/1)

  defp alias_refs(value) when is_binary(value) do
    case Regex.run(~r/^\{palette\.([^}]+)\}$/, value) do
      [_, key] -> [key]
      nil -> []
    end
  end

  defp alias_refs(_other), do: []

  # "color.light[Sand].hex" -> brand["color"]["light"] item with name "Sand" -> ["hex"].
  # List items are matched by "name", or by "word" for the status list.
  defp lookup_book(brand, path) do
    path
    |> String.split(".")
    |> Enum.reduce_while({:ok, brand}, fn segment, {:ok, current} ->
      [_, key, name] = Regex.run(~r/^([A-Za-z]+)(?:\[(.+)\])?$/, segment) |> pad_match()

      with %{} <- current,
           {:ok, value} <- Map.fetch(current, key),
           {:ok, value} <- select_item(value, name) do
        {:cont, {:ok, value}}
      else
        _ -> {:halt, :error}
      end
    end)
  end

  defp pad_match([whole, key]), do: [whole, key, ""]
  defp pad_match(match), do: match

  defp select_item(value, ""), do: {:ok, value}

  defp select_item(list, name) when is_list(list) do
    case Enum.find(list, &(is_map(&1) and (&1["name"] == name or &1["word"] == name))) do
      nil -> :error
      item -> {:ok, item}
    end
  end

  defp select_item(_other, _name), do: :error

  # ---------------------------------------------------------------------------------------
  # Compiled-css helpers
  # ---------------------------------------------------------------------------------------

  # Every innermost `selector{declarations}` rule, as {raw selector, body}. The regex
  # matches the rule inside an @media wrapper because [^{}]+ cannot cross a brace.
  defp rules(css) do
    ~r/([^{}]+)\{([^{}]+)\}/
    |> Regex.scan(css, capture: :all_but_first)
    |> Enum.map(fn [selector, body] -> {selector, body} end)
  end

  defp find_rule(css, selector) do
    Enum.find(rules(css), fn {raw, _body} -> String.trim(raw) == selector end)
  end

  # Applies `fun` to the declarations of the unique rule with `selector`.
  defp edit_block(css, selector, fun) do
    {raw, body} = find_rule(css, selector)
    String.replace(css, raw <> "{" <> body <> "}", raw <> "{" <> fun.(body) <> "}", global: false)
  end

  defp replace_value(body, var, value) do
    Regex.replace(~r/(#{Regex.escape(var)}\s*:\s*)[^;}]+/, body, "\\1" <> value, global: false)
  end

  # %{"--mg-color-x" => canonical value} for every --mg-color-* / --mg-logo-* declaration.
  defp declared_tokens(body) do
    ~r/(?:^|;)\s*(--mg-(?:color|logo)-[a-z0-9-]+)\s*:\s*([^;]+)/
    |> Regex.scan(body, capture: :all_but_first)
    |> Map.new(fn [var, value] -> {var, canonical_value(String.trim(value))} end)
  end

  defp canonical_value("#" <> _ = value) do
    if Regex.match?(~r/^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/, value),
      do: Contrast.normalize_hex(value),
      else: value
  end

  defp canonical_value(value), do: value

  defp theme_blocks_matching(css, selectors) do
    ~r/([^{}]+)\{([^{}]+)\}/
    |> Regex.scan(css, capture: :all_but_first)
    |> Enum.filter(fn [selector, _block] ->
      Enum.any?(selectors, &String.contains?(selector, &1))
    end)
    |> Enum.map(fn [_selector, block] -> block end)
  end

  # Extract the value of a slot from an already selected compiled CSS theme block.
  defp extract_slot_value(theme_block, slot) do
    pattern = ~r/(^|;)#{Regex.escape(slot)}:\s*([^;,}]+)/

    case Regex.run(pattern, theme_block, capture: :all_but_first) do
      [_prefix, value | _] -> String.trim(value)
      nil -> "(slot not found in theme block)"
    end
  end
end
