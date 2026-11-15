defmodule MailglassAdmin.Operator.OrphanCount do
  @moduledoc false

  # The sentence for a count of provider reports that match no email (D-12, BRADM-05).
  #
  # The data key stays `:orphan_backlog`; only the words on screen change. The brand book's
  # example is "3 provider reports match no email", and the singular follows English:
  # "1 provider report matches no email". Zero takes the plural form, which is exact and
  # claims nothing the count does not support.
  #
  # The phrase is a plain literal here, outside `copy.ex`, on purpose: the vocabulary
  # binding in `copy_contract_test.exs` requires every wired `on_screen` word to appear in a
  # screen-side string literal, and it excludes `copy.ex` (its owner).
  #
  # Pure and total over non-negative integers. A negative or non-integer count is a caller
  # bug, so it raises `FunctionClauseError` rather than render a made-up sentence.

  @spec label(non_neg_integer()) :: String.t()
  def label(1), do: "1 provider report matches no email"

  def label(count) when is_integer(count) and count >= 0,
    do: Integer.to_string(count) <> " provider reports match no email"
end
