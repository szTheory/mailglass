defmodule MailglassAdmin.Operator.MailerName do
  @moduledoc false

  # The plain name of a delivery's mailer, derived only from the text stored in
  # `Delivery.mailable` (D-13, C-9, BRADM-05).
  #
  # Production persistence writes the module alone (`inspect(rendered.mailable)`), so the
  # stored value is usually `MyApp.AccountMailer` and the plain name is its humanized
  # leaf, "Account mailer". Seeded data carries `Module.function`, so the plain name is the
  # humanized function, "Password reset". No name is invented: a nil, blank or unreadable
  # value has no name, the text "nil" (what core stores for a message with no mailable) has
  # none, and a value with no letter or digit in it has none either.
  #
  # Pure and total: it only reads the value it is given, never creates an atom (it works
  # on binaries with `String.split/2` and `Macro.underscore/1`), and emits no diagnostics.
  # `Delivery.mailable` is database text, so an atom made from it would be unbounded.

  alias MailglassAdmin.Preview.ScenarioLabel

  @doc """
  The humanized name, or nil when the stored value has none.

  A trailing `/N` arity, a leading `Elixir.` and trailing dots are ignored. When the last
  segment starts with a lower-case letter and a module path precedes it, it is the
  function; otherwise the last segment is the module leaf, split at its capitals.
  """
  @spec plain_name(String.t() | nil) :: String.t() | nil
  def plain_name(value) do
    with value when is_binary(value) <- identity(value),
         segments when segments != [] <- segments(value),
         name when is_binary(name) <- humanize(segments),
         true <- String.match?(name, ~r/[\p{L}\p{N}]/u) do
      name
    else
      _ -> nil
    end
  end

  # `Mailglass.Outbound.Persistence` stores `inspect(rendered.mailable)`, and a message
  # built without a mailable stores `inspect(nil)`. That text is the absence of a mailer,
  # not a mailer named "Nil". A module really called `Nil` inspects as "Nil", so only the
  # exact lower-case text is treated as missing.
  @missing_mailable inspect(nil)

  @doc """
  The stored value, trimmed, to show in full; nil for nil, blank or unreadable text, and
  for the text core stores when a message has no mailable.
  """
  @spec identity(String.t() | nil) :: String.t() | nil
  def identity(value) when is_binary(value) do
    trimmed = String.trim(value)

    if trimmed not in ["", @missing_mailable] and String.valid?(trimmed), do: trimmed
  end

  def identity(_value), do: nil

  # `Elixir.MyApp.AccountMailer.password_reset/1` -> ["MyApp", "AccountMailer", "password_reset"]
  defp segments(value) do
    value
    |> String.replace(~r{/\d+\z}, "")
    |> String.split(".")
    |> Enum.reject(&(&1 == ""))
    |> drop_elixir_prefix()
  end

  defp drop_elixir_prefix(["Elixir", _ | _] = segments), do: tl(segments)
  defp drop_elixir_prefix(segments), do: segments

  defp humanize([leaf]), do: leaf |> Macro.underscore() |> ScenarioLabel.humanize()

  defp humanize(segments) do
    last = List.last(segments)

    if lower_case_start?(last),
      do: ScenarioLabel.humanize(last),
      else: last |> Macro.underscore() |> ScenarioLabel.humanize()
  end

  defp lower_case_start?(segment) do
    first = String.first(segment)
    first == String.downcase(first) and first != String.upcase(first)
  end
end
