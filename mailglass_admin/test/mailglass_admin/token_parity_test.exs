defmodule MailglassAdmin.TokenParityTest do
  @moduledoc """
  Fail-closed compiled-bundle parity test (TOKEN-04).

  Reads the compiled `priv/static/app.css` and asserts:
  1. No raw `#hex` appears on any `--color-*` line inside a daisyUI theme selector
     (the TOKEN-01 no-raw-hex structural rule).
  2. Every daisyUI `--color-*` slot in both themes resolves via `var(--mg-*)` to
     the oracle value from `brandbook/tokens.json`.

  If this test fails with "expected var(--mg-*) but got something else", the bundle
  is stale. Run `cd mailglass_admin && mix mailglass_admin.assets.build &&
  git add priv/static/` and commit.

  If it fails with a value mismatch, either `brandbook/tokens.json` was updated
  without re-syncing `app.css`, or `app.css` was hand-edited. Never hand-edit
  `priv/static/app.css`. `actual` is what currently SHIPS.
  """

  use ExUnit.Case, async: true

  @css_path Path.join([
              Application.app_dir(:mailglass_admin, "priv"),
              "static",
              "app.css"
            ])

  # Three levels up from test/mailglass_admin/ → test/ → mailglass_admin/ → monorepo root → brandbook/
  @tokens_path Path.expand(Path.join([__DIR__, "..", "..", "..", "brandbook", "tokens.json"]))

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

    {:ok, tokens: Jason.decode!(File.read!(@tokens_path))}
  end

  setup do
    css = File.read!(@css_path)
    {:ok, css: css}
  end

  @tag :token_parity
  test "no raw hex in any --color-* line inside daisyUI theme selectors (TOKEN-01)", %{css: css} do
    # Extract each [data-theme=mailglass-*] { ... } block then scan for raw hex.
    # A line matching `--color-[a-z-]+: #[0-9a-fA-F]` is a TOKEN-01 violation.
    refute css =~ ~r/\[data-theme=mailglass-[^\]]+\]\{[^}]*--color-[a-z-]+:\s*#[0-9a-fA-F]/s,
           "TOKEN-01 violation: raw hex literal on a --color-* line inside a daisyUI theme block. " <>
             "All --color-* values must reference var(--mg-*). Run mix mailglass_admin.assets.build."
  end

  @tag :token_parity
  test "every --color-* slot references var(--mg-*) and oracle value matches tokens.json",
       %{css: css, tokens: tokens} do
    mismatches =
      Enum.reduce(@mapping, [], fn {{theme, slot}, {mg_token, tier}}, acc ->
        # Check that the slot references var(--mg-*)
        slot_pattern = slot <> ": var(" <> mg_token <> ")"
        slot_pattern_nospace = slot <> ":var(" <> mg_token <> ")"

        unless css =~ slot_pattern or css =~ slot_pattern_nospace do
          actual = extract_slot_value(css, theme, slot)

          [
            "#{theme} #{slot} must reference var(#{mg_token}); " <>
              "actual: #{actual}. Bundle is stale or app.css hand-edited — run mix mailglass_admin.assets.build"
            | acc
          ]
        else
          # Check oracle value: resolve mg_token from the tokens.json oracle for this tier
          token_key = String.replace_prefix(mg_token, "--mg-color-", "")
          oracle_hex = resolve_oracle(tokens, token_key, tier)

          # Extract the actual inlined value from the compiled CSS for this tier
          actual_inlined = extract_mg_token_value(css, mg_token, tier)

          if oracle_hex != nil and actual_inlined != nil and
               not hex_equal?(oracle_hex, actual_inlined) do
            [
              "#{theme} #{slot}: #{mg_token} inlined as #{actual_inlined} " <>
                "but oracle (tokens.json #{tier}) says #{oracle_hex}. " <>
                "Run mix mailglass_admin.assets.build after syncing brandbook/tokens.json."
              | acc
            ]
          else
            if oracle_hex != nil and actual_inlined == nil do
              [
                "#{theme} #{slot}: #{mg_token} not found as inlined declaration in compiled CSS. " <>
                  "Run mix mailglass_admin.assets.build."
                | acc
              ]
            else
              acc
            end
          end
        end
      end)

    assert mismatches == [],
           "Token parity failures (#{length(mismatches)} slot(s)):\n" <>
             Enum.join(mismatches, "\n")
  end

  # Resolve a semantic token key to its hex value via the W3C token alias chain.
  # tier is :light or :dark.
  defp resolve_oracle(tokens, token_key, tier) do
    tier_str = Atom.to_string(tier)
    raw = get_in(tokens, ["color", tier_str, token_key, "$value"])

    case raw do
      nil ->
        nil

      "{palette." <> rest ->
        palette_key = String.replace_suffix(rest, "}", "")
        get_in(tokens, ["palette", palette_key, "$value"])

      hex ->
        hex
    end
  end

  # Extract the CSS value of an inlined --mg-* custom property from compiled CSS.
  # For light tier: uses the first occurrence (from :root/[data-theme=light] block).
  # For dark tier: uses the occurrence inside [data-theme=dark]{...} block.
  # Returns the hex string (e.g. "#fff" or "#f8fbfd") or nil.
  defp extract_mg_token_value(css, mg_token, tier) do
    pattern = ~r/#{Regex.escape(mg_token)}:\s*(#[0-9a-fA-F]+)/

    case tier do
      :light ->
        # First occurrence is in :root/[data-theme=light] block
        case Regex.run(pattern, css, capture: :all_but_first) do
          [value | _] -> String.downcase(value)
          nil -> nil
        end

      :dark ->
        # Find [data-theme=dark]{...} block, then extract from it
        dark_block_pattern = ~r/\[data-theme=dark\]\{([^}]+)\}/

        case Regex.run(dark_block_pattern, css, capture: :all_but_first) do
          [block | _] ->
            case Regex.run(pattern, block, capture: :all_but_first) do
              [value | _] -> String.downcase(value)
              nil -> nil
            end

          nil ->
            nil
        end
    end
  end

  # Compare two hex color values for equality, normalizing shorthand (#fff → #ffffff).
  defp hex_equal?(oracle_hex, actual_hex) do
    normalize_hex(String.downcase(oracle_hex)) == normalize_hex(String.downcase(actual_hex))
  end

  # Expand 3-digit hex shorthand to 6-digit form.
  defp normalize_hex("#" <> hex) when byte_size(hex) == 3 do
    <<r::binary-1, g::binary-1, b::binary-1>> = hex
    "#" <> r <> r <> g <> g <> b <> b
  end

  defp normalize_hex(hex), do: hex

  # Extract the value of a slot from the compiled CSS theme block.
  defp extract_slot_value(css, theme, slot) do
    pattern = ~r/\[data-theme=#{Regex.escape(theme)}\]\{[^}]*#{Regex.escape(slot)}:\s*([^;,}]+)/s

    case Regex.run(pattern, css, capture: :all_but_first) do
      [value | _] -> String.trim(value)
      nil -> "(slot not found in theme block)"
    end
  end
end
