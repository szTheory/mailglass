defmodule Mailglass.AdminCase do
  @moduledoc """
  Shared test case template for admin-oriented tests.

  The root `mailglass` app does not own the synthetic `mailglass_admin`
  endpoint or browser harness. Those stay under `mailglass_admin/test/support`
  so package-boundary checks remain quiet.

  This wrapper intentionally stays generic: it layers only the core
  `Mailglass.MailerCase` setup and leaves endpoint/browser concerns to
  the `mailglass_admin` package's own case templates.
  """

  use ExUnit.CaseTemplate

  using opts do
    quote do
      use Mailglass.MailerCase, unquote(opts)
    end
  end
end
