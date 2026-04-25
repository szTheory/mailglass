defmodule Mailglass.Tracking.Guard do
  @moduledoc """
  Runtime auth-stream tracking guard (D-38).

  **Dual enforcement with Phase 6 `TRACK-02 NoTrackingOnAuthStream`**:

  - Compile-time: Phase 6 Credo catches most cases via AST inspection of
    `@mailglass_opts` + mailable function names.
  - Runtime: THIS MODULE catches the dynamic-function-name bypass
    (metaprogrammed mailables, `def unquote(name)(...)` patterns).

  Invoked from `Mailglass.Outbound.send/2` (Plan 05) as a precondition
  similar to `Mailglass.Tenancy.assert_stamped!/0` — not a preflight STAGE
  (no `{:error, _}` return path), but a FAIL-LOUD raise.

  ## Regex (D-38)

  `^(magic_link|password_reset|verify_email|confirm_account)` — matches the
  four canonical auth-carrying function-name prefixes. Variant function names
  starting with these prefixes (e.g. `magic_link_verify`, `password_reset_confirm`)
  ALSO match — Outlook SafeLinks pre-fetch could pre-trigger a tracked pixel on
  an auth email, which would be visible in scroll-tracking logs and represent a
  privacy regression.

  ## Adopters CANNOT turn this off

  Deliberate choice (D-38). The "acknowledged" escape hatch is not provided.
  Adopters who hit the regex falsely should rename their function or split their
  mailable module.

  ## nil mailable_function (T-3-04-01)

  When `mailable_function` is `nil`, the guard returns `:ok` — it cannot perform
  the heuristic without a function name. Phase 6 Credo `TRACK-02` is the primary
  enforcement for this case via compile-time AST inspection.
  """

  @auth_fn_regex ~r/^(magic_link|password_reset|verify_email|confirm_account)/

  alias Mailglass.{ConfigError, Message, Tracking}

  @doc """
  Raises `%Mailglass.ConfigError{type: :tracking_on_auth_stream}` when the
  mailable's compile-time tracking opts would enable opens or clicks AND the
  calling function name matches the auth-stream regex.

  Returns `:ok` otherwise.

  ## Examples

      iex> msg = %Mailglass.Message{mailable: MyApp.UserMailer, mailable_function: :welcome}
      iex> Mailglass.Tracking.Guard.assert_safe!(msg)
      :ok

  """
  @doc since: "0.1.0"
  @spec assert_safe!(Message.t()) :: :ok
  def assert_safe!(%Message{mailable: nil}), do: :ok

  def assert_safe!(%Message{mailable_function: nil}), do: :ok

  def assert_safe!(%Message{mailable: mod, mailable_function: fun_name})
      when is_atom(mod) and is_atom(fun_name) do
    flags = Tracking.enabled?(mailable: mod)

    if (flags.opens or flags.clicks) and auth_function?(fun_name) do
      raise ConfigError.new(:tracking_on_auth_stream,
              context: %{mailable: mod, function: fun_name}
            )
    end

    :ok
  end

  defp auth_function?(fun_name) when is_atom(fun_name) do
    Regex.match?(@auth_fn_regex, Atom.to_string(fun_name))
  end
end
