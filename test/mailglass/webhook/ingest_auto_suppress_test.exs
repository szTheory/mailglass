defmodule Mailglass.Webhook.IngestAutoSuppressTest do
  use Mailglass.WebhookCase, async: false

  alias Mailglass.{Clock, TestRepo}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.AutoSuppress
  alias Mailglass.Suppression.Entry

  describe "build_attrs/2" do
    test "maps complained to complaint address suppression" do
      delivery = build_delivery(stream: :transactional)
      event = build_event(:complained)

      assert {:ok, attrs} = AutoSuppress.build_attrs(event, delivery)
      assert attrs.address == delivery.recipient
      assert attrs.scope == :address
      assert attrs.reason == :complaint
      assert attrs.source == "webhook:auto_suppress"
    end

    test "maps unsubscribed to address_stream suppression using delivery stream" do
      delivery = build_delivery(stream: :bulk)
      event = build_event(:unsubscribed)

      assert {:ok, attrs} = AutoSuppress.build_attrs(event, delivery)
      assert attrs.scope == :address_stream
      assert attrs.stream == :bulk
      assert attrs.reason == :unsubscribe
    end

    test "skips deferred events" do
      assert {:ok, :skip} = AutoSuppress.build_attrs(build_event(:deferred), build_delivery())
    end
  end

  describe "insert/3" do
    test "uses conflict-ignore semantics for duplicate suppression candidates" do
      delivery = build_delivery(stream: :transactional, recipient: "DupE@example.com")
      event = build_event(:complained)

      assert {:ok, attrs} = AutoSuppress.build_attrs(event, delivery)
      assert {:ok, %Entry{}} = AutoSuppress.insert(TestRepo, attrs)
      assert {:ok, %Entry{}} = AutoSuppress.insert(TestRepo, attrs)
      assert TestRepo.aggregate(Entry, :count) == 1
    end
  end

  defp build_delivery(overrides \\ []) do
    attrs =
      overrides
      |> Enum.into(%{
        tenant_id: "test-tenant",
        mailable: "MyApp.Mailers.WelcomeMailer.welcome/1",
        stream: :transactional,
        recipient: "to@example.com",
        last_event_type: :queued,
        last_event_at: Clock.utc_now(),
        status: :sent
      })

    struct!(Delivery, attrs)
  end

  defp build_event(type, overrides \\ []) do
    attrs =
      overrides
      |> Enum.into(%{
        tenant_id: "test-tenant",
        type: type,
        occurred_at: Clock.utc_now(),
        metadata: %{
          "provider" => "postmark",
          "provider_event_id" => "evt_123",
          "message_id" => "msg_123"
        }
      })

    struct!(Event, attrs)
  end
end
