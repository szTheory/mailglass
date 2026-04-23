defmodule Mailglass.Webhook.RouterTest do
  # Pure compile-time macro expansion + `Phoenix.Router.__routes__/0`
  # reflection — no shared state, safe for async.
  use ExUnit.Case, async: true

  describe "mailglass_webhook_routes/2 default opts" do
    defmodule DefaultRouter do
      use Phoenix.Router
      import Mailglass.Webhook.Router

      scope "/" do
        mailglass_webhook_routes("/webhooks")
      end
    end

    test "generates exactly 2 POST routes (postmark + sendgrid)" do
      routes = DefaultRouter.__routes__()
      assert length(routes) == 2

      postmark_route = Enum.find(routes, &(&1.path == "/webhooks/postmark"))
      assert postmark_route != nil
      assert postmark_route.verb == :post
      assert postmark_route.plug == Mailglass.Webhook.Plug
      assert postmark_route.plug_opts[:provider] == :postmark

      sendgrid_route = Enum.find(routes, &(&1.path == "/webhooks/sendgrid"))
      assert sendgrid_route != nil
      assert sendgrid_route.verb == :post
      assert sendgrid_route.plug == Mailglass.Webhook.Plug
      assert sendgrid_route.plug_opts[:provider] == :sendgrid
    end

    test "default :as prefix is :mailglass_webhook (CONTEXT D-08)" do
      routes = DefaultRouter.__routes__()
      helpers = Enum.map(routes, & &1.helper)
      assert "mailglass_webhook_postmark" in helpers
      assert "mailglass_webhook_sendgrid" in helpers
    end
  end

  describe "mailglass_webhook_routes/2 custom opts" do
    defmodule PostmarkOnlyRouter do
      use Phoenix.Router
      import Mailglass.Webhook.Router

      scope "/api" do
        mailglass_webhook_routes("/hooks", providers: [:postmark], as: :hooks)
      end
    end

    test "respects custom :providers list (single provider)" do
      routes = PostmarkOnlyRouter.__routes__()
      assert length(routes) == 1
      [route] = routes
      assert route.path == "/api/hooks/postmark"
      assert route.verb == :post
      assert route.plug == Mailglass.Webhook.Plug
      assert route.plug_opts[:provider] == :postmark
    end

    test "respects custom :as prefix" do
      routes = PostmarkOnlyRouter.__routes__()
      [route] = routes
      assert route.helper == "hooks_postmark"
    end

    defmodule SendgridOnlyRouter do
      use Phoenix.Router
      import Mailglass.Webhook.Router

      scope "/" do
        mailglass_webhook_routes("/webhooks", providers: [:sendgrid])
      end
    end

    test "respects custom :providers list containing only :sendgrid" do
      routes = SendgridOnlyRouter.__routes__()
      assert length(routes) == 1
      [route] = routes
      assert route.path == "/webhooks/sendgrid"
      assert route.plug_opts[:provider] == :sendgrid
      # default :as prefix still applies
      assert route.helper == "mailglass_webhook_sendgrid"
    end
  end

  describe "mailglass_webhook_routes/2 compile-time validation (D-07)" do
    test "raises ArgumentError on unknown provider atom" do
      # Macro-time validation fires during Code.compile_string/1 — the
      # ArgumentError bubbles up unwrapped because it's raised BEFORE the
      # router module's compile finishes. Any exception class is acceptable
      # as long as the message matches.
      err =
        assert_raise ArgumentError, ~r/unknown provider/, fn ->
          Code.compile_string("""
          defmodule Mailglass.Webhook.RouterTest.UnknownProviderRouter do
            use Phoenix.Router
            import Mailglass.Webhook.Router

            scope "/" do
              mailglass_webhook_routes "/webhooks", providers: [:mailgun]
            end
          end
          """)
        end

      assert err.message =~ ":mailgun"
      assert err.message =~ "v0.1"
    end
  end
end
