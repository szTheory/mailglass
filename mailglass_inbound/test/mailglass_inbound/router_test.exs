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

    route(SupportMailbox,
      recipient: "support@example.com",
      subject: ~r/help/i,
      headers: [{"x-ticket-kind", "support"}]
    )

    route(BillingMailbox,
      recipient: ~r/^billing\+/,
      headers: [{"x-account-tier", ~r/^gold$/i}]
    )

    route(FallbackMailbox, recipient: "support@example.com")
  end

  test "router DSL compiles to ordered pure route data" do
    assert [
             %Route{mailbox: SupportMailbox},
             %Route{mailbox: BillingMailbox},
             %Route{mailbox: FallbackMailbox}
           ] = ExampleRouter.__mailglass_inbound_routes__()

    assert Enum.all?(ExampleRouter.__mailglass_inbound_routes__(), fn route ->
             match?(
               {file, line} when is_binary(file) and is_integer(line) and line > 0,
               route.source
             )
           end)
  end

  test "route options reject executable AST without running it" do
    sentinel = String.to_atom("router_side_effect_#{System.unique_integer([:positive])}")
    Process.register(self(), sentinel)

    module = unique_module("SideEffectRouter")

    source = """
    defmodule #{inspect(module)} do
      use MailglassInbound.Router

      route MailglassInbound.RouterTest.SupportMailbox,
        subject: (send(Process.whereis(#{inspect(sentinel)}), :route_side_effect); "help")
    end
    """

    assert_raise ArgumentError, ~r/route\/2 accepts only literal options/, fn ->
      Code.compile_string(source)
    end

    refute_received :route_side_effect
  end

  test "mailbox declarations reject macros without expanding them" do
    sentinel = String.to_atom("router_mailbox_side_effect_#{System.unique_integer([:positive])}")
    Process.register(self(), sentinel)
    module = unique_module("MailboxSideEffectRouter")

    source = """
    defmodule #{inspect(module)} do
      use MailglassInbound.Router

      defmacro executable_mailbox do
        send(Process.whereis(#{inspect(sentinel)}), :mailbox_side_effect)
        quote(do: MailglassInbound.RouterTest.SupportMailbox)
      end

      route executable_mailbox(), []
    end
    """

    assert_raise ArgumentError, ~r/literal mailbox module alias/, fn ->
      Code.compile_string(source)
    end

    refute_received :mailbox_side_effect
  end

  test "route options reject variables, calls, interpolation, and captures" do
    expressions = [
      "value",
      "String.upcase(\"help\")",
      "\"help-\#{value}\"",
      "&String.upcase/1"
    ]

    Enum.each(expressions, fn expression ->
      module = unique_module("NonLiteralRouter")

      source = """
      defmodule #{inspect(module)} do
        use MailglassInbound.Router
        value = "help"
        _ = value
        route MailglassInbound.RouterTest.SupportMailbox, subject: #{expression}
      end
      """

      assert_raise ArgumentError, ~r/route\/2 accepts only literal options/, fn ->
        Code.compile_string(source)
      end
    end)
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

  defp unique_module(prefix) do
    Module.concat(__MODULE__, "#{prefix}#{System.unique_integer([:positive])}")
  end
end
