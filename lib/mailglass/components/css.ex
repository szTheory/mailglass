defmodule Mailglass.Components.CSS do
  @moduledoc """
  CSS style-string utilities for email component rendering.

  Internal to `Mailglass.Components`. Components build a base inline `style="..."`
  string (the email-client invariant part) and merge an optional adopter-supplied
  class/style override via `merge_style/2`. No external class-composition library
  is used (D-20).
  """

  @doc """
  Merges a base inline style string with an optional override.

  Override may be `nil`, a binary, or a list of binaries/nils (nils filtered).

  ## Examples

      iex> Mailglass.Components.CSS.merge_style("color:red;", nil)
      "color:red;"

      iex> Mailglass.Components.CSS.merge_style("color:red;", "font-size:16px;")
      "color:red; font-size:16px;"

      iex> Mailglass.Components.CSS.merge_style("color:red;", [nil, "font-size:16px;", nil])
      "color:red; font-size:16px;"
  """
  @doc since: "0.1.0"
  @spec merge_style(String.t(), nil | String.t() | [String.t() | nil]) :: String.t()
  def merge_style(base, nil) when is_binary(base), do: base
  def merge_style(base, "") when is_binary(base), do: base

  def merge_style(base, extra) when is_binary(base) and is_binary(extra) do
    "#{base} #{extra}"
  end

  def merge_style(base, list) when is_binary(base) and is_list(list) do
    filtered =
      list
      |> Enum.filter(&(is_binary(&1) and &1 != ""))
      |> Enum.join(" ")

    merge_style(base, filtered)
  end
end
