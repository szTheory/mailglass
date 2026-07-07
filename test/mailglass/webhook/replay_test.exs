defmodule Mailglass.Webhook.ReplayTest do
  use Mailglass.DataCase, async: false

  alias Mailglass.Clock
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.TestRepo
  alias Mailglass.Webhook.{Ingest, Replay, WebhookEvent}
  alias Mailglass.Webhook.Providers.Postmark

  describe "execute/1" do
    test "successfully replays one stored webhook target and records requested and completed audit facts" do
      delivery = insert_delivery!(provider_message_id: "msg-replay-success")

      webhook_event =
        insert_webhook_event!(
          provider_event_id: "postmark-webhook-success",
          raw_payload: %{
            "RecordType" => "Delivery",
            "MessageID" => "msg-replay-success",
            "ID" => 101
          }
        )

      assert {:ok, result} =
               Replay.execute(%{
                 tenant_id: "test-tenant",
                 webhook_event_id: webhook_event.id,
                 delivery_id: delivery.id,
                 actor: %{subject_id: "operator-1"}
               })

      assert result.status == :replayed
      assert result.delivery_id == delivery.id
      assert result.replayed_event_count == 1
      assert result.new_event_count == 1
      assert result.orphan_event_count == 0

      delivered =
        TestRepo.one!(
          from(event in Event,
            where:
              event.type == :delivered and
                fragment("?->>'webhook_event_id' = ?", event.metadata, ^webhook_event.id),
            limit: 1
          )
        )

      assert delivered.delivery_id == delivery.id
      assert delivered.metadata["webhook_event_id"] == webhook_event.id

      [requested] = replay_events_for(webhook_event.id, :webhook_replay_requested)
      [succeeded] = replay_events_for(webhook_event.id, :webhook_replay_succeeded)

      assert requested.metadata["actor_id"] == "operator-1"
      assert requested.metadata["webhook_event_id"] == webhook_event.id
      assert requested.metadata["provider"] == "postmark"
      assert succeeded.metadata["actor_id"] == "operator-1"
      assert succeeded.metadata["outcome"] == "replayed"
      assert succeeded.metadata["requested_audit_event_id"] == requested.id
      refute succeeded.metadata["outcome"] == "noop"
    end

    test "normalizes known actor string keys without failing on unknown keys" do
      unknown_key = "unknown_actor_key_#{System.unique_integer([:positive])}"
      delivery = insert_delivery!(provider_message_id: "msg-replay-string-actor")

      webhook_event =
        insert_webhook_event!(
          provider_event_id: "postmark-webhook-string-actor",
          raw_payload: %{
            "RecordType" => "Delivery",
            "MessageID" => "msg-replay-string-actor",
            "ID" => 102
          }
        )

      assert {:ok, result} =
               Replay.execute(%{
                 tenant_id: "test-tenant",
                 webhook_event_id: webhook_event.id,
                 delivery_id: delivery.id,
                 actor: %{
                   "subject_id" => "operator-string-key",
                   "tenant_id" => "test-tenant",
                   unknown_key => "preserved"
                 }
               })

      assert result.status == :replayed

      [requested] = replay_events_for(webhook_event.id, :webhook_replay_requested)
      [succeeded] = replay_events_for(webhook_event.id, :webhook_replay_succeeded)

      assert requested.metadata["actor_id"] == "operator-string-key"
      assert requested.metadata["actor_tenant_id"] == "test-tenant"
      assert succeeded.metadata["actor_id"] == "operator-string-key"
    end

    test "rejects missing and malformed actor subject IDs before audit work begins" do
      webhook_event =
        insert_webhook_event!(
          provider_event_id: "postmark-webhook-invalid-actor",
          raw_payload: %{
            "RecordType" => "Delivery",
            "MessageID" => "msg-replay-invalid-actor",
            "ID" => 103
          }
        )

      invalid_actors = [
        %{},
        %{subject_id: nil},
        %{"subject_id" => ""},
        %{subject_id: %{}}
      ]

      for actor <- invalid_actors do
        assert {:error, :invalid_params} =
                 Replay.execute(%{
                   tenant_id: "test-tenant",
                   webhook_event_id: webhook_event.id,
                   actor: actor
                 })
      end

      assert replay_events_for(webhook_event.id, :webhook_replay_requested) == []
      assert replay_events_for(webhook_event.id, :webhook_replay_failed) == []
    end

    test "returns a noop outcome when replay converges on existing ledger rows" do
      delivery = insert_delivery!(provider_message_id: "msg-replay-noop")
      raw_body = ~s({"RecordType":"Delivery","MessageID":"msg-replay-noop","ID":202})

      assert {:ok, normalized_events} = {:ok, Postmark.normalize(raw_body, [])}
      assert {:ok, ingest_result} = Ingest.ingest_multi(:postmark, raw_body, normalized_events)

      assert {:ok, result} =
               Replay.execute(%{
                 tenant_id: "test-tenant",
                 webhook_event_id: ingest_result.webhook_event.id,
                 delivery_id: delivery.id,
                 actor: %{subject_id: "operator-2"}
               })

      assert result.status == :noop
      assert result.new_event_count == 0
      assert result.replayed_event_count == 1

      assert 1 ==
               TestRepo.aggregate(
                 from(webhook_event in WebhookEvent,
                   where:
                     webhook_event.provider == ^ingest_result.webhook_event.provider and
                       webhook_event.provider_event_id ==
                         ^ingest_result.webhook_event.provider_event_id
                 ),
                 :count
               )

      [delivered] = delivery_events_for(ingest_result.webhook_event.id, :delivered)
      [requested] = replay_events_for(ingest_result.webhook_event.id, :webhook_replay_requested)
      [succeeded] = replay_events_for(ingest_result.webhook_event.id, :webhook_replay_succeeded)

      assert delivered.delivery_id == delivery.id
      assert requested.metadata["actor_id"] == "operator-2"
      assert succeeded.metadata["actor_id"] == "operator-2"
      assert succeeded.metadata["outcome"] == "noop"
      refute succeeded.metadata["outcome"] == "replayed"
    end

    test "rejects tenant mismatches before replay work begins" do
      webhook_event =
        insert_webhook_event!(
          tenant_id: "tenant-b",
          provider_event_id: "tenant-b-webhook",
          raw_payload: %{"RecordType" => "Delivery", "MessageID" => "msg-tenant-b", "ID" => 303}
        )

      assert {:error, :webhook_event_not_found} =
               Replay.execute(%{
                 tenant_id: "test-tenant",
                 webhook_event_id: webhook_event.id,
                 actor: %{subject_id: "operator-3"}
               })

      assert replay_events_for(webhook_event.id, :webhook_replay_requested) == []
      assert replay_events_for(webhook_event.id, :webhook_replay_failed) == []
    end

    test "records a failed audit fact when replay cannot resolve a provider module" do
      webhook_event =
        insert_webhook_event!(
          provider: "mystery",
          provider_event_id: "mystery-webhook",
          raw_payload: %{"kind" => "mystery"}
        )

      assert {:error, :unknown_provider} =
               Replay.execute(%{
                 tenant_id: "test-tenant",
                 webhook_event_id: webhook_event.id,
                 actor: %{subject_id: "operator-4"}
               })

      [requested] = replay_events_for(webhook_event.id, :webhook_replay_requested)
      [failed] = replay_events_for(webhook_event.id, :webhook_replay_failed)

      assert requested.metadata["actor_id"] == "operator-4"
      assert failed.metadata["actor_id"] == "operator-4"
      assert failed.metadata["outcome"] == "failed"
      assert failed.metadata["failure_reason"] == "replay_failed"
      assert failed.metadata["requested_audit_event_id"] == requested.id
    end
  end

  defp insert_delivery!(attrs) do
    defaults = %{
      tenant_id: "test-tenant",
      mailable: "Mailglass.ReplayTest.Mailer",
      stream: :transactional,
      recipient: "replay@example.com",
      provider: "postmark",
      provider_message_id: "msg-#{System.unique_integer([:positive])}",
      last_event_type: :sent,
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
      raw_payload: %{"RecordType" => "Delivery"},
      received_at: Clock.utc_now(),
      processed_at: Clock.utc_now()
    }

    attrs
    |> Enum.into(defaults)
    |> WebhookEvent.changeset()
    |> TestRepo.insert!()
  end

  defp replay_events_for(webhook_event_id, type) do
    TestRepo.all(
      from(event in Event,
        where:
          event.type == ^type and
            fragment("?->>'webhook_event_id' = ?", event.metadata, ^webhook_event_id),
        order_by: [asc: event.occurred_at, asc: event.inserted_at, asc: event.id]
      )
    )
  end

  defp delivery_events_for(webhook_event_id, type) do
    TestRepo.all(
      from(event in Event,
        where:
          event.type == ^type and
            fragment("?->>'webhook_event_id' = ?", event.metadata, ^webhook_event_id),
        order_by: [asc: event.occurred_at, asc: event.inserted_at, asc: event.id]
      )
    )
  end
end
