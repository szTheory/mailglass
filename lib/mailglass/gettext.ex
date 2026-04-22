defmodule Mailglass.Gettext do
  @moduledoc """
  Gettext backend for mailglass default strings.

  Adopters use their own Gettext backend inside HEEx slots (CONTEXT.md D-23):

      <.heading>
        <%= dgettext("emails", "Welcome, %{name}", name: @user.name) %>
      </.heading>

  The `"emails"` domain lives in `priv/gettext/`. Run `mix gettext.extract`
  to generate the POT file from mailglass source strings.
  """
  use Gettext.Backend, otp_app: :mailglass
end
