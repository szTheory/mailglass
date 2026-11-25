defmodule MailglassAdmin.AccessibilityTest do
  @moduledoc """
  WCAG contrast anchors for the brand v2.0 tokens (PREV-05, BRTOK-02, BRTOK-05).

  Role hexes are read from `brandbook/tokens.json` through
  `MailglassAdmin.TestSupport.Contrast` (WCAG 2.2, sRGB threshold 0.04045), so
  there is no hex literal for a role in this file. The full pair inventory,
  coverage guards and `never` rules live in `contrast_contract_test.exs`; this
  file keeps the headline pairs and pins the values that are intentionally
  below 3:1 (decorative dividers) so nobody "fixes" them upward.
  """

  use ExUnit.Case, async: true

  alias MailglassAdmin.TestSupport.Contrast

  @tokens_path Path.expand("../../../brandbook/tokens.json", __DIR__)

  setup_all do
    {:ok, resolved: @tokens_path |> File.read!() |> Jason.decode!() |> Contrast.resolve_tokens()}
  end

  describe "canonical contrast pairs" do
    test "text on the page background passes AAA in both themes", ctx do
      for tier <- ["light", "dark"] do
        assert ratio(ctx, tier, "text", "background") >= 7.0
      end
    end

    test "text on a card surface passes AAA in both themes", ctx do
      for tier <- ["light", "dark"] do
        assert ratio(ctx, tier, "text", "surface") >= 7.0
        assert ratio(ctx, tier, "text", "surface-raised") >= 7.0
      end
    end

    test "secondary text passes AA on the page and on a card in both themes", ctx do
      for tier <- ["light", "dark"], ground <- ["background", "surface", "surface-raised"] do
        assert ratio(ctx, tier, "text-muted", ground) >= 4.5,
               "text-muted on #{ground} (#{tier}) must clear AA"
      end
    end

    test "link and accent text pass AA on the page and on a card in both themes", ctx do
      for tier <- ["light", "dark"],
          fg <- ["link", "accent-text"],
          ground <- ["background", "surface"] do
        assert ratio(ctx, tier, fg, ground) >= 4.5, "#{fg} on #{ground} (#{tier}) must clear AA"
      end
    end

    test "the primary button label passes AA in both themes", ctx do
      # --color-primary-content is the page background in light and text-inverse in dark.
      assert ratio(ctx, "light", "background", "accent") >= 4.5
      assert ratio(ctx, "dark", "text-inverse", "accent") >= 4.5
    end

    test "every solid status fill carries a label that passes AA", ctx do
      for tier <- ["light", "dark"], status <- ~w(success warning error info) do
        assert ratio(ctx, tier, "#{status}-on-solid", "#{status}-solid") >= 4.5,
               "#{status}-on-solid on #{status}-solid (#{tier}) must clear AA"
      end
    end
  end

  describe "logo glass is artwork only" do
    test "glass clears 3:1 on the light page but never 4.5:1, so it is never text", ctx do
      light = ratio(ctx, "light", "logo-glass", "background")

      assert light >= 3.0, "logo glass on the light page is #{light}; artwork needs 3:1"

      assert light < 4.5,
             "logo glass on the light page is #{light}; if it reached 4.5 the book's never-for-text rule would need revisiting"
    end

    test "glass on the dark page clears 3:1", ctx do
      assert ratio(ctx, "dark", "logo-glass", "background") >= 3.0
    end
  end

  describe "dark-mode text (TOKEN-03)" do
    test "muted and status text pass AA on the dark surface and on a raised surface", ctx do
      for fg <- ~w(text-muted success-text warning-text error-text info-text),
          ground <- ["surface", "surface-raised"] do
        assert ratio(ctx, "dark", fg, ground) >= 4.5, "dark #{fg} on #{ground} must clear AA"
      end
    end

    test "dark status text passes AA on the page background", ctx do
      for fg <- ~w(success-text warning-text error-text info-text) do
        assert ratio(ctx, "dark", fg, "background") >= 4.5
      end
    end
  end

  describe "border role is intentionally sub-3:1 (WCAG 1.4.11 decorative exemption)" do
    # The brand classifies base-300 (the `border` role, Sand Line / Roast Line) as a
    # decorative divider. WCAG 1.4.11 (Non-text Contrast) only requires 3:1 for CONTROL
    # BOUNDARIES, and those use border-input, which contrast_contract_test holds at
    # 3:1. These assertions are intentionally below 3.0 — do NOT raise the value to "fix"
    # them.
    test "light border on the page background is sub-3:1 (decorative hairline)", ctx do
      # Do NOT raise this value — WCAG 1.4.11 exempts decorative dividers.
      assert ratio(ctx, "light", "border", "background") < 3.0
    end

    test "dark border on the page background is sub-3:1 (decorative hairline)", ctx do
      # Do NOT raise this value — WCAG 1.4.11 exempts decorative dividers.
      assert ratio(ctx, "dark", "border", "background") < 3.0
    end

    test "the control border is not the divider: border-input stays at or above 3:1", ctx do
      for tier <- ["light", "dark"] do
        assert ratio(ctx, tier, "border-input", "background") >= 3.0
      end
    end
  end

  defp ratio(%{resolved: resolved}, tier, fg_role, bg_role) do
    Contrast.ratio(role_hex(resolved, tier, fg_role), role_hex(resolved, tier, bg_role))
  end

  defp role_hex(resolved, tier, "logo-" <> rest),
    do: Map.fetch!(resolved, {tier, "--mg-logo-" <> rest})

  defp role_hex(resolved, tier, role), do: Map.fetch!(resolved, {tier, "--mg-color-" <> role})
end
