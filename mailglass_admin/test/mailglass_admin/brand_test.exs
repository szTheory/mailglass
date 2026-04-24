defmodule MailglassAdmin.BrandTest do
  @moduledoc """
  RED-by-default coverage for PREV-05 / BRAND-01 palette mapping:
  compiled `priv/static/app.css` contains canonical brand hex values,
  daisyUI `mailglass-light` + `mailglass-dark` themes wire them to the
  documented tokens, and glassmorphism / depth / noise primitives are
  absent (per 05-UI-SPEC §Visual DON'Ts).

  Plan 05 lands `mailglass_admin/assets/css/app.css` + `mix mailglass_admin.assets.build`
  + `priv/static/app.css` (compiled artifact) and turns these RED tests green.
  """

  use ExUnit.Case, async: true

  @css_path Path.join([
              Application.app_dir(:mailglass_admin, "priv"),
              "static",
              "app.css"
            ])

  setup do
    css = File.read!(@css_path)
    {:ok, css: css}
  end

  describe "brand palette hex values" do
    test "compiled app.css defines all six canonical brand hex values", %{css: css} do
      # Case-insensitive — `#0D1B2A` or `#0d1b2a` both acceptable.
      lowered = String.downcase(css)

      assert lowered =~ "#0d1b2a", "Ink missing"
      assert lowered =~ "#277b96", "Glass missing"
      assert lowered =~ "#a6eaf2", "Ice missing"
      assert lowered =~ "#eaf6fb", "Mist missing"
      assert lowered =~ "#f8fbfd", "Paper missing"
      assert lowered =~ "#5c6b7a", "Slate missing"
    end
  end

  describe "mailglass-light theme" do
    test "defines canonical daisyUI tokens", %{css: css} do
      lowered = String.downcase(css)

      assert lowered =~ "--color-base-100: #f8fbfd" or lowered =~ "--color-base-100:#f8fbfd",
             "mailglass-light --color-base-100 must map to Paper"

      assert lowered =~ "--color-primary: #277b96" or lowered =~ "--color-primary:#277b96",
             "mailglass-light --color-primary must map to Glass"

      assert lowered =~ "--color-base-content: #0d1b2a" or
               lowered =~ "--color-base-content:#0d1b2a",
             "mailglass-light --color-base-content must map to Ink"
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
  end

  describe "visual DON'Ts (05-UI-SPEC §Visual DON'Ts)" do
    test "compiled CSS bans glassmorphism primitives", %{css: css} do
      refute css =~ "backdrop-filter",
             "compiled CSS must NOT contain `backdrop-filter` (no glassmorphism)"
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
