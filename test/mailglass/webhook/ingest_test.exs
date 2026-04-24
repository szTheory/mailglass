defmodule Mailglass.Webhook.IngestTest do
  @moduledoc """
  Integration tests for `Mailglass.Webhook.Ingest.ingest_multi/3` — the
  heart of HOOK-06.

  Covers the five acceptance gates from Plan 04-06:

    1. Happy path with matched Delivery — 1 webhook_event + 1 event +
       1 projection update + status flip.
    2. Orphan path (no matching Delivery) — event inserts with
       `delivery_id: nil + needs_reconciliation: true`; projector
       step SKIPPED (Pitfall 4).
    3. Duplicate replay (UNIQUE(provider, provider_event_id) collision)
       — second call returns `duplicate: true` without re-inserting.
    4. SendGrid batch (5 events, mixed matched/orphan) — `events_with_deliveries`
       3-tuple shape verified.
    5. `SET LOCAL statement_timeout` primitive fires on pg_sleep stress.

  All tests use `Mailglass.WebhookCase, async: false` — DB writes cannot
  be async, and the tenant-stamping side effects in setup need isolation.
  """

  use Mailglass.WebhookCase, async: false

  alias Mailglass.{Repo, Tenancy, TestRepo}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Webhook.{Ingest, WebhookEvent}

  setup do
    # MailerCase (which WebhookCase inherits) already stamps "test-tenant".
    # Per revision W7: use Mailglass.Tenancy.clear/0 in on_exit (NOT raw
    # Process.delete) so the internal atom can be refactored without
    # breaking test code.
    on_exit(fn -> Tenancy.clear() end)
    :ok
  end

  describe "ingest_multi/3 happy path (matched delivery)" do
    test "inserts 1 webhook_event + 1 event + 1 projection update + flips status" do
      # Ingest's resolve_delivery_id/2 queries mailglass_deliveries.provider_message_id
      # matching event.metadata["message_id"] for Postmark. Seed one that matches.
      delivery = insert_delivery!(provider: "postmark", provider_message_id: "msg_001")

      events = [
        %Event{
          type: :delivered,
          metadata: %{
            "provider" => "postmark",
            "provider_event_id" => "Delivery:1:2026-04-23T12:00:00Z",
            "record_type" => "Delivery",
            "message_id" => "msg_001"
          },
          reject_reason: nil
        }
      ]

      assert {:ok, result} =
               Ingest.ingest_multi(
                 :postmark,
                 ~s({"RecordType":"Delivery","MessageID":"msg_001"}),
                 events
               )

      assert result.duplicate == false
      assert length(result.events_with_deliveries) == 1
      assert result.orphan_event_count == 0

      # Assert webhook_event row exists with status :succeeded
      [webhook_event] = Repo.all(WebhookEvent)
      assert webhook_event.status == :succeeded
      assert webhook_event.processed_at != nil
      assert webhook_event.provider == "postmark"
      assert webhook_event.event_type_normalized == "delivered"

      # Assert event row inserted with delivery_id linked to the seeded Delivery.
      [event_row] = Repo.all(Event)
      assert event_row.delivery_id == delivery.id
      assert event_row.needs_reconciliation == false
      assert event_row.type == :delivered

      # Assert the events_with_deliveries 3-tuple shape carries the matched delivery.
      assert [{_event, delivery_tuple, false}] = result.events_with_deliveries
      assert delivery_tuple.id == delivery.id
    end
  end

  describe "ingest_multi/3 orphan path (no matching delivery)" do
    test "inserts event with delivery_id: nil + needs_reconciliation: true; SKIPS projector" do
      events = [
        %Event{
          type: :delivered,
          metadata: %{
            "provider" => "postmark",
            "provider_event_id" => "Delivery:1:2026-04-23T12:00:00Z",
            "record_type" => "Delivery",
            # Orphan: no matching Delivery row in DB.
            "message_id" => "msg_orphan_001"
          },
          reject_reason: nil
        }
      ]

      assert {:ok, result} =
               Ingest.ingest_multi(
                 :postmark,
                 ~s({"RecordType":"Delivery","MessageID":"msg_orphan_001"}),
                 events
               )

      assert result.duplicate == false
      # Orphans flow through events_with_deliveries with orphan?: true + delivery: nil
      # per revision B7 — Plan 04-04's Plug skips these in broadcast_post_commit/1.
      assert [{_event, nil, true}] = result.events_with_deliveries
      assert result.orphan_event_count == 1

      # Assert event row inserted with delivery_id: nil + needs_reconciliation: true
      [event_row] = Repo.all(Event)
      assert event_row.delivery_id == nil
      assert event_row.needs_reconciliation == true

      # Assert webhook_event row still flipped to :succeeded (orphan-skip is
      # normal flow, not failure — Plan 04-07 Reconciler sweeps orphans later).
      [webhook_event] = Repo.all(WebhookEvent)
      assert webhook_event.status == :succeeded
    end
  end

  describe "ingest_multi/3 duplicate replay (UNIQUE collision)" do
    test "second call returns duplicate: true; no second webhook_event row inserted" do
      events = [
        %Event{
          type: :delivered,
          metadata: %{
            "provider" => "postmark",
            "provider_event_id" => "Delivery:1:2026-04-23T12:00:00Z",
            "record_type" => "Delivery",
            "message_id" => "msg_dup_001"
          },
          reject_reason: nil
        }
      ]

      # First call
      assert {:ok, first} = Ingest.ingest_multi(:postmark, ~s({"x":1}), events)
      assert first.duplicate == false
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
      # The orphan path still inserts one mailglass_events row (delivery_id: nil).
      assert TestRepo.aggregate(Event, :count) == 1

      # Second call — UNIQUE collision — should be a structural no-op.
      assert {:ok, second} = Ingest.ingest_multi(:postmark, ~s({"x":1}), events)
      assert second.duplicate == true

      # Assert no NEW webhook_event row inserted.
      assert TestRepo.aggregate(WebhookEvent, :count) == 1

      # Assert no NEW event row inserted (the idempotency_key partial UNIQUE
      # on mailglass_events also catches this via `for_webhook_event/3` with
      # the same index → same key → ON CONFLICT DO NOTHING).
      assert TestRepo.aggregate(Event, :count) == 1
    end
  end

  describe "ingest_multi/3 batch (SendGrid 5 events, mixed matched/orphan)" do
    test "inserts 1 webhook_event + 5 event rows; events_with_deliveries 3-tuple shape" do
      # Seed matched deliveries for msg_a (x2 events) and msg_b (x1 event).
      # msg_c and msg_d are orphans.
      insert_delivery!(provider: "sendgrid", provider_message_id: "msg_a")
      insert_delivery!(provider: "sendgrid", provider_message_id: "msg_b")

      events = [
        build_sg_event(:queued, "evt_20", "msg_a"),
        build_sg_event(:delivered, "evt_21", "msg_a"),
        build_sg_event(:bounced, "evt_22", "msg_b", :bounced),
        build_sg_event(:opened, "evt_23", "msg_c"),
        build_sg_event(:clicked, "evt_24", "msg_d")
      ]

      assert {:ok, result} =
               Ingest.ingest_multi(:sendgrid, ~s([{"event":"processed"}]), events)

      assert result.duplicate == false
      # All 5 events surface in events_with_deliveries regardless of matched/orphan.
      assert length(result.events_with_deliveries) == 5

      # 3 matched (msg_a x2 + msg_b x1); 2 orphan (msg_c, msg_d).
      matched_count =
        Enum.count(result.events_with_deliveries, fn {_e, _d, orphan?} -> orphan? == false end)

      assert matched_count == 3
      assert result.orphan_event_count == 2

      # One webhook_event row; 5 mailglass_events rows.
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
      assert TestRepo.aggregate(Event, :count) == 5

      # Matched events carry their delivery struct; orphans carry nil.
      for {_event, delivery_or_nil, orphan?} <- result.events_with_deliveries do
        if orphan? do
          assert is_nil(delivery_or_nil)
        else
          assert %Delivery{} = delivery_or_nil
        end
      end
    end
  end

  describe "ingest_multi/3 statement_timeout (CONTEXT D-29)" do
    @tag :slow
    test "SET LOCAL statement_timeout fires on a slow query inside the transact" do
      # Exercise the primitive directly — the Ingest module uses a 2s timeout,
      # which would make this test slow if exercised end-to-end. Prove the
      # SET LOCAL pattern works by invoking it in a minimal transact closure
      # with a tightened 500ms cap.
      #
      # SQLSTATE 57014 = "canceling statement due to statement timeout".
      assert_raise Postgrex.Error, ~r/canceling statement due to statement timeout|57014/, fn ->
        Repo.transact(fn ->
          _ = Repo.query!("SET LOCAL statement_timeout = '500ms'", [])
          _ = Repo.query!("SELECT pg_sleep(2.0)", [])
          {:ok, :should_not_reach}
        end)
      end
    end
  end

  describe "ingest_multi/3 missing tenant (assert_stamped!/0 analog)" do
    test "raises %TenancyError{type: :unstamped} when no tenant in process scope" do
      # Clear the tenant set in the MailerCase setup. Per revision W7, use the
      # public Tenancy.clear/0 API so the internal process-dict atom stays
      # encapsulated.
      Tenancy.clear()

      assert_raise Mailglass.TenancyError, ~r/not stamped/, fn ->
        Ingest.ingest_multi(:postmark, "{}", [])
      end
    end
  end

  # ---- Test helpers --------------------------------------------------

  defp insert_delivery!(attrs) do
    defaults = %{
      tenant_id: "test-tenant",
      mailable: "MyApp.Mailers.WelcomeMailer.welcome/1",
      stream: :transactional,
      recipient: "to@example.com",
      last_event_type: :queued,
      last_event_at: Mailglass.Clock.utc_now(),
      status: :sent
    }

    attrs_map = Enum.into(attrs, defaults)

    attrs_map
    |> Delivery.changeset()
    |> TestRepo.insert!()
  end

  defp build_sg_event(type, provider_event_id, sg_message_id, reject_reason \\ nil) do
    %Event{
      type: type,
      reject_reason: reject_reason,
      metadata: %{
        "provider" => "sendgrid",
        "provider_event_id" => provider_event_id,
        "event" => Atom.to_string(type),
        "sg_message_id" => sg_message_id
      }
    }
  end
end
