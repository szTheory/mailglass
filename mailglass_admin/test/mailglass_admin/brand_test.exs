defmodule MailglassAdmin.BrandTest do
  @moduledoc """
  Compiled `priv/static/app.css` carries the brand v2.0 palette (BRTOK-01,
  BRTOK-05), the daisyUI `mailglass-light` and `mailglass-dark` themes wire it to
  the documented roles, no v1 palette value survives, and glassmorphism, depth
  and noise primitives stay absent (05-UI-SPEC section Visual DON'Ts).

  Full per-role value parity against `brandbook/tokens.json` lives in
  `token_parity_test.exs`; the contrast contract lives in
  `contrast_contract_test.exs`. This file is the coarse tripwire: six v2 anchors
  must be inlined and the retired v1 values must be gone.
  """

  use ExUnit.Case, async: true

  @css_path Path.join([
              Application.app_dir(:mailglass_admin, "priv"),
              "static",
              "app.css"
            ])

  # Sand, Espresso, Deep Glass, Sand Line, Roast, Bright Glass.
  @v2_anchors ~w(#f6f1e8 #2a1d17 #0a6488 #ddd3c4 #1d1713 #6cc6f0)

  # The v1 navy/teal palette (Ink, Glass, Ice, Mist, Paper, Slate and the derived
  # steps) retired by brand v2.0.
  @retired_v1_hexes ~w(#0d1b2a #277b96 #a6eaf2 #eaf6fb #f8fbfd #5c6b7a #152538 #c7dce5 #315069)

  setup do
    css = File.read!(@css_path)
    {:ok, css: css}
  end

  describe "brand palette hex values" do
    test "compiled app.css inlines the six v2 anchor colours", %{css: css} do
      # Case-insensitive; the minifier lower-cases hex.
      lowered = String.downcase(css)

      for hex <- @v2_anchors do
        assert lowered =~ hex, "v2 anchor #{hex} missing from the compiled bundle"
      end
    end

    test "no retired v1 palette value survives in the bundle", %{css: css} do
      lowered = String.downcase(css)

      for hex <- @retired_v1_hexes do
        refute lowered =~ hex, "retired v1 colour #{hex} is still in the compiled bundle"
      end

      refute lowered =~ "rgb(13 27 42",
             "the retired navy shadow tint rgb(13 27 42 / a) is still in the compiled bundle"
    end
  end

  describe "mailglass-light theme" do
    test "defines canonical daisyUI tokens", %{css: css} do
      lowered = String.downcase(css)

      # Slot-to-role wiring (var references in the theme block).
      assert css =~ "--color-base-100: var(--mg-color-background)" or
               css =~ "--color-base-100:var(--mg-color-background)",
             "mailglass-light --color-base-100 must reference --mg-color-background"

      assert css =~ "--color-primary: var(--mg-color-accent)" or
               css =~ "--color-primary:var(--mg-color-accent)",
             "mailglass-light --color-primary must reference --mg-color-accent"

      assert css =~ "--color-base-content: var(--mg-color-text)" or
               css =~ "--color-base-content:var(--mg-color-text)",
             "mailglass-light --color-base-content must reference --mg-color-text"

      # Role values inlined from brandbook/tokens.css (v2).
      assert lowered =~ "--mg-color-background: #f6f1e8" or
               lowered =~ "--mg-color-background:#f6f1e8",
             "--mg-color-background token (#F6F1E8 Sand) must be inlined in compiled CSS"

      assert lowered =~ "--mg-color-accent: #0a6488" or
               lowered =~ "--mg-color-accent:#0a6488",
             "--mg-color-accent token (#0A6488 Deep Glass) must be inlined in compiled CSS"

      assert lowered =~ "--mg-color-text: #2a1d17" or
               lowered =~ "--mg-color-text:#2a1d17",
             "--mg-color-text token (#2A1D17 Espresso) must be inlined in compiled CSS"
    end
  end

  describe "mailglass-dark theme" do
    # The daisyUI 5 plugin transforms the source-level `name: "mailglass-dark"`
    # directive into CSS selectors like `[data-theme=mailglass-dark]` +
    # `input.theme-controller[value=mailglass-dark]` — the literal
    # `name: "mailglass-dark"` string does NOT survive into the compiled
    # output. Assert on the compiled-form selectors instead.
    test "exists as a compiled daisyUI theme selector", %{css: css} do
      assert css =~ "[data-theme=mailglass-dark]",
             ~s|compiled CSS must define a [data-theme=mailglass-dark] selector (daisyUI 5's compiled form of `name: "mailglass-dark"`)|
    end

    test "defines the v2 dark roles", %{css: css} do
      lowered = String.downcase(css)

      assert lowered =~ "--mg-color-background:#1d1713",
             "--mg-color-background token (#1D1713 Roast) must be inlined in compiled CSS"

      assert lowered =~ "--mg-color-accent:#6cc6f0",
             "--mg-color-accent token (#6CC6F0 Bright Glass) must be inlined in compiled CSS"
    end
  end

  describe "visual DON'Ts (05-UI-SPEC §Visual DON'Ts)" do
    test "compiled CSS bans glassmorphism primitives", %{css: css} do
      # Check for actual glassmorphism USE, not Tailwind @layer properties registration.
      # Tailwind v4 registers backdrop-filter in a comma-separated property list inside
      # @layer properties (e.g. `filter,-webkit-backdrop-filter,backdrop-filter,display`).
      # That is NOT glassmorphism; it is Tailwind's CSS property initialization. The real
      # signal is backdrop-filter used as a CSS property: `backdrop-filter:` or
      # `backdrop-filter: ` followed by a value such as `blur(...)`.
      refute css =~ ~r/backdrop-filter\s*:/,
             "compiled CSS must NOT use `backdrop-filter:` as a property (no glassmorphism)"

      refute css =~ "box-shadow: inset",
             "compiled CSS must NOT contain `box-shadow: inset` (no bevels)"
    end

    test "depth and noise are disabled in both themes", %{css: css} do
      assert css =~ "--depth: 0" or css =~ "--depth:0",
             "both themes must set --depth: 0"

      assert css =~ "--noise: 0" or css =~ "--noise:0",
             "both themes must set --noise: 0"
    end
  end
end
