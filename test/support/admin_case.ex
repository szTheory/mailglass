defmodule Mailglass.AdminCase do
  @moduledoc """
  Test case template for admin LiveView tests (TEST-02).

  Phase 3 ships this skeleton. Phase 5 (PREV-01..06) extends with:
  - `Phoenix.LiveViewTest` helpers for LiveView mounting + interaction
  - `mailglass_admin` endpoint stub + session cookie fixtures
  - Device width / dark mode toggle assertion helpers
  - Mailable auto-discovery test utilities

  Inherits the full `Mailglass.MailerCase` setup:
  - Ecto sandbox + Fake adapter + Tenancy stamp + PubSub subscribe + Clock freeze.
  - All `Mailglass.MailerCase` tags work (`@tag tenant:`, `@tag frozen_at:`, etc.)

  ## Usage (Phase 5+)

      defmodule MailglassAdmin.MailableSidebarLiveTest do
        use Mailglass.AdminCase, async: false

        test "sidebar lists all mailables with preview_props/0" do
          # Phase 5: use Phoenix.LiveViewTest helpers here
        end
      end
  """
  use ExUnit.CaseTemplate

  using opts do
    quote do
      use Mailglass.MailerCase, unquote(opts)
      # Phase 5 will add:
      #   import Phoenix.LiveViewTest
      #   import Mailglass.AdminCase.Helpers
      #   (endpoint stub, session cookie fixtures, device toggle helpers, etc.)
    end
  end
end
