defmodule MailglassAdmin.TestSupport.Contrast do
  @moduledoc """
  Pure colour helpers for the admin token tests (test environment only).

  No dependency is involved: `mix.lock` stays unchanged. The module is compiled
  from `test/support` (`elixirc_paths(:test)`), so it never ships in the Hex
  tarball.

    * `normalize_hex/1` lower-cases a hex colour and expands the three-digit
      form (`"#FFF"` and `"#FFFFFF"` both become `"#ffffff"`). The compiled
      bundle is minified by Lightning CSS, which shortens `#ffffff` to `#fff`.
    * `luminance/1` is the WCAG 2.2 relative luminance of an sRGB hex colour.
      The sRGB expansion threshold is **0.04045**. The older WCAG 2.0 constant
      is retired: the WCAG 2.1 errata and the current W3C techniques correct it
      as an editorial slip. The two give the same answer for every 8-bit
      colour, but the helper uses the current constant so nobody has to
      re-derive that.
    * `ratio/2` is the contrast ratio `(L1 + 0.05) / (L2 + 0.05)` of two hex
      colours, with the lighter luminance as `L1`, so it does not depend on
      argument order.
    * `composite/3` is the single rounding rule for every designed token value
      (alpha over a ground): per channel `round(alpha * fg + (1 - alpha) * bg)`
      with Elixir `round/1` (half away from zero). `brandbook/tokens.json`
      stores exactly this function's output and the parity test recomputes it,
      so a value that does not reproduce is a red test, never a judgment call.
    * `resolve_tokens/1` flattens the `brandbook/tokens.json` oracle into
      `%{{tier, css_var} => hex}` with every `{palette.x}` alias resolved.
  """

  @tiers ["light", "dark"]

  @doc "Lower-cases a hex colour and expands the three-digit form."
  @spec normalize_hex(String.t()) :: String.t()
  def normalize_hex("#" <> hex) do
    hex = String.downcase(hex)

    case byte_size(hex) do
      3 ->
        <<r::binary-1, g::binary-1, b::binary-1>> = hex
        "#" <> r <> r <> g <> g <> b <> b

      6 ->
        "#" <> hex

      _ ->
        raise ArgumentError, "not a 3 or 6 digit hex colour: #{inspect("#" <> hex)}"
    end
  end

  def normalize_hex(other) do
    raise ArgumentError, "not a hex colour: #{inspect(other)}"
  end

  @doc """
  WCAG 2.2 relative luminance of a hex colour, `0.0` (black) to `1.0` (white).
  """
  @spec luminance(String.t()) :: float()
  def luminance(hex) do
    {r, g, b} = channels(hex)
    0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
  end

  @doc """
  Contrast ratio of two hex colours, `1.0` to `21.0`, independent of argument order.
  """
  @spec ratio(String.t(), String.t()) :: float()
  def ratio(fg_hex, bg_hex) do
    l1 = luminance(fg_hex)
    l2 = luminance(bg_hex)
    (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
  end

  @doc """
  Composites `fg_hex` at `alpha` over `bg_hex`, per channel
  `round(alpha * fg + (1 - alpha) * bg)`, and returns a lower-case `"#rrggbb"`.
  """
  @spec composite(String.t(), String.t(), number()) :: String.t()
  def composite(fg_hex, bg_hex, alpha) when is_number(alpha) and alpha >= 0 and alpha <= 1 do
    {fr, fg, fb} = channels(fg_hex)
    {br, bg, bb} = channels(bg_hex)

    "#" <>
      Enum.map_join([{fr, br}, {fg, bg}, {fb, bb}], fn {f, b} ->
        value = round(alpha * f + (1 - alpha) * b)

        value
        |> Integer.to_string(16)
        |> String.downcase()
        |> String.pad_leading(2, "0")
      end)
  end

  @doc """
  Flattens a decoded `brandbook/tokens.json` into `%{{tier, css_var} => hex}`.

  `tier` is `"light"` or `"dark"`. `css_var` is `"--mg-color-<role>"` for each
  `color.<tier>.<role>` and `"--mg-logo-<role>"` for each `logo.<tier>.<role>`.
  Aliases of the form `{palette.x}` are resolved; a dangling alias raises.
  """
  @spec resolve_tokens(map()) :: %{{String.t(), String.t()} => String.t()}
  def resolve_tokens(tokens) when is_map(tokens) do
    for {group, prefix} <- [{"color", "--mg-color-"}, {"logo", "--mg-logo-"}],
        tier <- @tiers,
        {role, %{"$value" => value}} <- Map.get(tokens, group, %{}) |> Map.get(tier, %{}),
        into: %{} do
      {{tier, prefix <> role}, resolve_value(tokens, value)}
    end
  end

  defp resolve_value(tokens, "{palette." <> rest) do
    key = String.replace_suffix(rest, "}", "")

    case get_in(tokens, ["palette", key, "$value"]) do
      nil -> raise ArgumentError, "dangling alias {palette.#{key}}"
      hex -> normalize_hex(hex)
    end
  end

  defp resolve_value(_tokens, "#" <> _ = hex), do: normalize_hex(hex)

  # sRGB channel (0..255) to linear light, using the WCAG 2.2 threshold 0.04045.
  defp linearize(channel) do
    c = channel / 255

    if c <= 0.04045, do: c / 12.92, else: :math.pow((c + 0.055) / 1.055, 2.4)
  end

  defp channels(hex) do
    "#" <> <<r::binary-2, g::binary-2, b::binary-2>> = normalize_hex(hex)
    {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}
  end
end
