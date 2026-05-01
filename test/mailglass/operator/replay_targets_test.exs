defmodule Mailglass.Operator.ReplayTargetsTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Events
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Operator.ReplayTargets
  alias Mailglass.Webhook.WebhookEvent
  alias Mailglass.Clock

  describe "list_delivery_targets/1" do
    test "returns one exact target for a delivery with one replayable webhook row" do
      delivery =
        insert_delivery!(
          tenant_id: "tenant-a",
          provider: "postmark",
          recipient: "exact@example.com",
          provider_message_id: "msg-exact"
        )

      webhook_event =
        insert_webhook_event!(
          tenant_id: "tenant-a",
          provider: "postmark",
          provider_event_id: "postmark-webhook-1",
          received_at: DateTime.add(Clock.utc_now(), -60, :second)
        )

      append_delivery_event!(
        tenant_id: "tenant-a",
        delivery_id: delivery.id,
        type: :delivered,
        metadata: %{
          "provider" => "postmark",
          "provider_event_id" => "child-postmark-event-1",
          "webhook_event_id" => webhook_event.id,
          "webhook_provider_event_id" => webhook_event.provider_event_id,
          "message_id" => "msg-exact"
        }
      )

      assert {:ok, %{status: :exact, candidate: candidate, candidates: [candidate]}} =
               ReplayTargets.list_delivery_targets(%{
                 tenant_id: "tenant-a",
                 delivery_id: delivery.id
               })

      assert candidate.webhook_event_id == webhook_event.id
      assert candidate.provider == "postmark"
      assert candidate.provider_event_id == "postmark-webhook-1"
      assert candidate.webhook_timestamp == webhook_event.received_at
      assert candidate.delivery_id == delivery.id
      assert candidate.delivery_provider_message_id == "msg-exact"
    end

    test "returns many targets when multiple replayable webhook rows are linked to one delivery" do
      delivery =
        insert_delivery!(
          tenant_id: "tenant-a",
          provider: "postmark",
          recipient: "many@example.com",
          provider_message_id: "msg-many"
        )

      older =
        insert_webhook_event!(
          tenant_id: "tenant-a",
          provider: "postmark",
          provider_event_id: "postmark-webhook-old",
          received_at: DateTime.add(Clock.utc_now(), -120, :second)
        )

      newer =
        insert_webhook_event!(
          tenant_id: "tenant-a",
          provider: "postmark",
          provider_event_id: "postmark-webhook-new",
          received_at: DateTime.add(Clock.utc_now(), -30, :second)
        )

      append_delivery_event!(
        tenant_id: "tenant-a",
        delivery_id: delivery.id,
        type: :delivered,
        metadata: linked_metadata("postmark", older, "child-postmark-old", "msg-many")
      )

      append_delivery_event!(
        tenant_id: "tenant-a",
        delivery_id: delivery.id,
        type: :opened,
        metadata: linked_metadata("postmark", newer, "child-postmark-new", "msg-many")
      )

      assert {:ok, %{status: :ambiguous, reason: :multiple_candidates, candidates: candidates}} =
               ReplayTargets.list_delivery_targets(%{
                 tenant_id: "tenant-a",
                 delivery_id: delivery.id
               })

      assert Enum.map(candidates, & &1.webhook_event_id) == [newer.id, older.id]
      assert Enum.all?(candidates, &(&1.delivery_id == delivery.id))
      assert Enum.all?(candidates, &(&1.delivery_provider_message_id == "msg-many"))
    end

    test "returns unavailable for historical rows without safe linkage" do
      delivery =
        insert_delivery!(
          tenant_id: "tenant-a",
          provider: "postmark",
          recipient: "historical@example.com",
          provider_message_id: "msg-historical"
        )

      append_delivery_event!(
        tenant_id: "tenant-a",
        delivery_id: delivery.id,
        type: :delivered,
        metadata: %{
          "provider" => "postmark",
          "provider_event_id" => "historical-child-only",
          "message_id" => "msg-historical"
        }
      )

      assert {:ok, %{status: :unavailable, reason: :missing_replay_linkage, candidates: []}} =
               ReplayTargets.list_delivery_targets(%{
                 tenant_id: "tenant-a",
                 delivery_id: delivery.id
               })
    end

    test "rejects tenant mismatches before replay-target lookup" do
      delivery =
        insert_delivery!(
          tenant_id: "tenant-b",
          provider: "postmark",
          recipient: "foreign@example.com",
          provider_message_id: "msg-foreign"
        )

      assert {:error, :delivery_not_found} =
               ReplayTargets.list_delivery_targets(%{
                 tenant_id: "tenant-a",
                 delivery_id: delivery.id
               })
    end

    test "returns unavailable for sendgrid child events that do not safely imply one raw webhook identity" do
      delivery =
        insert_delivery!(
          tenant_id: "tenant-a",
          provider: "sendgrid",
          recipient: "sendgrid@example.com",
          provider_message_id: "sg-msg-1"
        )

      _first_batch =
        insert_webhook_event!(
          tenant_id: "tenant-a",
          provider: "sendgrid",
          provider_event_id: "sg-batch-hash-1",
          received_at: DateTime.add(Clock.utc_now(), -90, :second)
        )

      _second_batch =
        insert_webhook_event!(
          tenant_id: "tenant-a",
          provider: "sendgrid",
          provider_event_id: "sg-batch-hash-2",
          received_at: DateTime.add(Clock.utc_now(), -45, :second)
        )

      append_delivery_event!(
        tenant_id: "tenant-a",
        delivery_id: delivery.id,
        type: :opened,
        metadata: %{
          "provider" => "sendgrid",
          "provider_event_id" => "sg-child-event-1",
          "sg_message_id" => "sg-msg-1"
        }
      )

      append_delivery_event!(
        tenant_id: "tenant-a",
        delivery_id: delivery.id,
        type: :clicked,
        metadata: %{
          "provider" => "sendgrid",
          "provider_event_id" => "sg-child-event-2",
          "sg_message_id" => "sg-msg-1"
        }
      )

      assert {:ok, %{status: :unavailable, reason: :historical_sendgrid_batch, candidates: []}} =
               ReplayTargets.list_delivery_targets(%{
                 tenant_id: "tenant-a",
                 delivery_id: delivery.id
               })
    end
  end

  defp append_delivery_event!(attrs) do
    defaults = %{
      occurred_at: Clock.utc_now()
    }

    merged =
      attrs
      |> Map.new()
      |> then(&Map.merge(defaults, &1))

    {:ok, event} =
      Events.append(%{
        tenant_id: merged.tenant_id,
        delivery_id: merged.delivery_id,
        type: merged.type,
        occurred_at: merged.occurred_at,
        metadata: merged.metadata
      })

    event
  end

  defp insert_delivery!(attrs) do
    defaults = %{
      tenant_id: "test-tenant",
      mailable: "Mailglass.ReplayTargetsTest.Mailer",
      stream: :transactional,
      recipient: "fixture@example.com",
      provider: "postmark",
      provider_message_id: "msg-#{System.unique_integer([:positive])}",
      last_event_type: :queued,
      last_event_at: Clock.utc_now(),
      status: :sent,
      metadata: %{}
    }

    attrs
    |> Enum.into(defaults)
    |> Delivery.changeset()
    |> TestRepo.insert!()
  end

  defp insert_webhook_event!(attrs) do
    defaults = %{
      tenant_id: "test-tenant",
      provider: "postmark",
      provider_event_id: "webhook-#{System.unique_integer([:positive])}",
      event_type_raw: "Delivery",
      event_type_normalized: "delivered",
      status: :succeeded,
      raw_payload: %{"ok" => true},
      received_at: Clock.utc_now(),
      processed_at: Clock.utc_now()
    }

    attrs
    |> Enum.into(defaults)
    |> WebhookEvent.changeset()
    |> TestRepo.insert!()
  end

  defp linked_metadata(provider, webhook_event, provider_event_id, message_id) do
    %{
      "provider" => provider,
      "provider_event_id" => provider_event_id,
      "webhook_event_id" => webhook_event.id,
      "webhook_provider_event_id" => webhook_event.provider_event_id,
      "message_id" => message_id
    }
  end
end
