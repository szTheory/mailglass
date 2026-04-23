defmodule Mailglass.WebhookCase do
  @moduledoc """
  Test case template for webhook ingest tests (TEST-02).

  Phase 3 ships this skeleton. Phase 4 (HOOK-01..07) extends with:
  - `Plug.Test` helpers for HTTP request building
  - HMAC signature fixtures (Postmark Basic Auth + SendGrid ECDSA)
  - Body-preservation setup for `CachingBodyReader`
  - Provider-specific assertion helpers

  Inherits the full `Mailglass.MailerCase` setup:
  - Ecto sandbox + Fake adapter + Tenancy stamp + PubSub subscribe + Clock freeze.
  - All `Mailglass.MailerCase` tags work (`@tag tenant:`, `@tag frozen_at:`, etc.)

  ## Usage (Phase 4+)

      defmodule MyApp.PostmarkWebhookTest do
        use Mailglass.WebhookCase, async: false

        test "delivered event updates delivery status" do
          # Phase 4: use Plug.Test + HMAC fixture helpers here
        end
      end
  """
  use ExUnit.CaseTemplate

  using opts do
    quote do
      use Mailglass.MailerCase, unquote(opts)
      # Phase 4 will add:
      #   import Plug.Test
      #   import Mailglass.WebhookCase.Helpers
      #   (HMAC signature fixtures, body-preservation setup, etc.)
    end
  end
end
