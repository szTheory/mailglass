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

  describe "ingest_multi/3 auto suppression" do
    test "inserts address suppression for hard bounce" do
      delivery =
        insert_delivery!(
          provider: "postmark",
          provider_message_id: "msg_bounce_001",
          recipient: "bounce@example.com"
        )

      event =
        build_event(:bounced,
          reject_reason: :bounced,
          metadata: %{
            "provider" => "postmark",
            "provider_event_id" => "Bounce:1:2026-04-28T12:00:00Z",
            "record_type" => "Bounce",
            "message_id" => "msg_bounce_001"
          }
        )

      assert {:ok, _result} = Mailglass.Webhook.Ingest.ingest_multi(:postmark, ~s({"x":1}), [event])

      [entry] = TestRepo.all(Entry)
      assert entry.tenant_id == delivery.tenant_id
      assert entry.address == "bounce@example.com"
      assert entry.scope == :address
      assert entry.reason == :hard_bounce
    end

    test "inserts address suppression for complaint" do
      insert_delivery!(
        provider: "postmark",
        provider_message_id: "msg_complaint_001",
        recipient: "complaint@example.com"
      )

      event =
        build_event(:complained,
          metadata: %{
            "provider" => "postmark",
            "provider_event_id" => "SpamComplaint:1:2026-04-28T12:00:00Z",
            "record_type" => "SpamComplaint",
            "message_id" => "msg_complaint_001"
          }
        )

      assert {:ok, _result} = Mailglass.Webhook.Ingest.ingest_multi(:postmark, ~s({"x":1}), [event])

      [entry] = TestRepo.all(Entry)
      assert entry.address == "complaint@example.com"
      assert entry.scope == :address
      assert entry.reason == :complaint
    end

    test "inserts address_stream suppression for unsubscribe" do
      insert_delivery!(
        provider: "postmark",
        provider_message_id: "msg_unsub_001",
        recipient: "unsubscribe@example.com",
        stream: :bulk
      )

      event =
        build_event(:unsubscribed,
          metadata: %{
            "provider" => "postmark",
            "provider_event_id" => "SubscriptionChange:1:2026-04-28T12:00:00Z",
            "record_type" => "SubscriptionChange",
            "message_id" => "msg_unsub_001"
          }
        )

      assert {:ok, _result} = Mailglass.Webhook.Ingest.ingest_multi(:postmark, ~s({"x":1}), [event])

      [entry] = TestRepo.all(Entry)
      assert entry.address == "unsubscribe@example.com"
      assert entry.scope == :address_stream
      assert entry.stream == :bulk
      assert entry.reason == :unsubscribe
    end

    test "skips orphan events with no matching delivery" do
      event =
        build_event(:complained,
          metadata: %{
            "provider" => "postmark",
            "provider_event_id" => "SpamComplaint:orphan:2026-04-28T12:00:00Z",
            "record_type" => "SpamComplaint",
            "message_id" => "msg_orphan_001"
          }
        )

      assert {:ok, _result} = Mailglass.Webhook.Ingest.ingest_multi(:postmark, ~s({"x":1}), [event])
      assert TestRepo.aggregate(Entry, :count) == 0
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

  defp insert_delivery!(attrs) do
    attrs
    |> Enum.into(%{
      tenant_id: "test-tenant",
      mailable: "MyApp.Mailers.WelcomeMailer.welcome/1",
      stream: :transactional,
      recipient: "to@example.com",
      last_event_type: :queued,
      last_event_at: Clock.utc_now(),
      status: :sent
    })
    |> Delivery.changeset()
    |> TestRepo.insert!()
  end
end
