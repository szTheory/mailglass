defmodule MailglassInbound.RouterTest do
  use ExUnit.Case, async: true

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.Router.Matcher
  alias MailglassInbound.Router.Route

  defmodule SupportMailbox do
    @behaviour MailglassInbound.Mailbox

    @impl true
    def process(_message), do: :accept
  end

  defmodule BillingMailbox do
    @behaviour MailglassInbound.Mailbox

    @impl true
    def process(_message), do: {:reject, :manual_review}
  end

  defmodule FallbackMailbox do
    @behaviour MailglassInbound.Mailbox

    @impl true
    def process(_message), do: :ignore
  end

  defmodule ExampleRouter do
    use MailglassInbound.Router

    route SupportMailbox,
      recipient: "support@example.com",
      subject: ~r/help/i,
      headers: [{"x-ticket-kind", "support"}]

    route BillingMailbox,
      recipient: ~r/^billing\+/,
      headers: [{"x-account-tier", ~r/^gold$/i}]

    route FallbackMailbox, recipient: "support@example.com"
  end

  test "router DSL compiles to ordered pure route data" do
    assert [
             %Route{mailbox: SupportMailbox},
             %Route{mailbox: BillingMailbox},
             %Route{mailbox: FallbackMailbox}
           ] = ExampleRouter.__mailglass_inbound_routes__()
  end

  test "matcher supports exact and regex matching across recipient, subject, and headers" do
    message = %InboundMessage{
      envelope_recipient: "support@example.com",
      subject: "Need help with my account",
      headers: %{"x-ticket-kind" => ["support"], "x-account-tier" => ["silver"]}
    }

    assert {:ok, %Route{mailbox: SupportMailbox}} =
             Matcher.match(ExampleRouter.__mailglass_inbound_routes__(), message)

    billing_message = %InboundMessage{
      envelope_recipient: "billing+west@example.com",
      subject: "Invoice question",
      headers: %{"x-account-tier" => ["GOLD"]}
    }

    assert {:ok, %Route{mailbox: BillingMailbox}} =
             Matcher.match(ExampleRouter.__mailglass_inbound_routes__(), billing_message)
  end

  test "multiple clauses within one route are logical and, route order is top-to-bottom, and first match wins" do
    message = %InboundMessage{
      envelope_recipient: "support@example.com",
      subject: "help with billing",
      headers: %{"x-ticket-kind" => ["support"], "x-account-tier" => ["gold"]}
    }

    assert {:ok, %Route{mailbox: SupportMailbox}} =
             Matcher.match(ExampleRouter.__mailglass_inbound_routes__(), message)
  end

  test "route misses are explicit and non-exceptional" do
    message = %InboundMessage{
      envelope_recipient: "other@example.com",
      subject: "hello",
      headers: %{"x-ticket-kind" => ["general"]}
    }

    assert :no_match = Matcher.match(ExampleRouter.__mailglass_inbound_routes__(), message)
  end
end
