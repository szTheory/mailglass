defmodule Mailglass.Components.Theme do
  @moduledoc """
  Theme-token resolver backed by `:persistent_term`.

  Reads the brand theme cached by `Mailglass.Config.validate_at_boot!/0`
  (D-19). The theme map shape:

      [
        colors: %{ink: "#0D1B2A", glass: "#277B96", ...},
        fonts:  %{body: "...", display: "...", mono: "..."}
      ]

  All reads are O(1). Unknown tokens fall back to sensible defaults rather
  than raising — components render even if boot-time validation has not yet
  populated the cache (e.g. in minimal test setups).
  """

  @default_color "#277B96"
  @default_font "sans-serif"

  @doc "Returns the cached theme keyword list. Empty list when uncached."
  @doc since: "0.1.0"
  @spec get() :: keyword()
  def get, do: Mailglass.Config.get_theme()

  @doc """
  Returns the hex color for a brand token.

  Accepts `:ink`, `:glass`, `:ice`, `:mist`, `:paper`, `:slate` by default.
  Falls back to `#{@default_color}` (Glass) for unknown tokens.

  ## Examples

      iex> Mailglass.Components.Theme.color(:unknown_token)
      "#277B96"
  """
  @doc since: "0.1.0"
  @spec color(atom()) :: String.t()
  def color(token) when is_atom(token) do
    colors = Keyword.get(get(), :colors, %{})
    Map.get(colors, token, @default_color)
  end

  @doc """
  Returns the font-stack string for a font role.

  Accepts `:body`, `:display`, `:mono` by default. Falls back to
  `#{@default_font}` for unknown roles.
  """
  @doc since: "0.1.0"
  @spec font(atom()) :: String.t()
  def font(role) when is_atom(role) do
    fonts = Keyword.get(get(), :fonts, %{})
    Map.get(fonts, role, @default_font)
  end
end
