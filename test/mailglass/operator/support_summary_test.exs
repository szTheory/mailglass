defmodule Mailglass.Operator.SupportSummaryTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Events
  alias Mailglass.Generators
  alias Mailglass.Operator.SupportSummary
  alias Mailglass.TestRepo
  alias Mailglass.Webhook.WebhookEvent

  describe "summarize_tenant/1" do
    test "returns four explicit support buckets" do
      %{failed: failed, orphan: orphan, replay: replay, reconciled: reconciled} =
        seed_support_facts()

      summary = SupportSummary.summarize_tenant(%{tenant_id: "tenant-a", window_hours: 24})

      assert Map.keys(summary) == [
               :failed_ingest,
               :orphan_backlog,
               :replay_outcomes,
               :reconcile_facts
             ]

      assert summary.failed_ingest.count == 2
      assert summary.failed_ingest.latest.webhook_event_id == failed.dead.id

      assert summary.orphan_backlog.count == 1
      assert summary.orphan_backlog.oldest.event_id == orphan.unresolved.id

      assert summary.replay_outcomes.counts == %{failed: 1, noop: 1, replayed: 1}
      assert summary.replay_outcomes.latest.event_id == replay.replayed.id

      assert summary.reconcile_facts.reconciled_count == 1
      assert summary.reconcile_facts.still_unmatched_count == 1
      assert summary.reconcile_facts.latest_reconciled.event_id == reconciled.event.id
    end

    test "returns counts plus exemplar identifiers or durable timestamps for each bucket" do
      %{failed: failed, orphan: orphan, replay: replay, reconciled: reconciled} =
        seed_support_facts()

      summary = SupportSummary.summarize_tenant(%{tenant_id: "tenant-a", window_hours: 24})

      assert summary.failed_ingest.latest == %{
               webhook_event_id: failed.dead.id,
               provider: "postmark",
               provider_event_id: "failed-dead",
               received_at: failed.dead.received_at,
               status: :dead
             }

      assert summary.orphan_backlog.oldest == %{
               event_id: orphan.unresolved.id,
               occurred_at: orphan.unresolved.occurred_at,
               provider: "postmark",
               provider_event_id: "orphan-open",
               webhook_event_id: nil
             }

      assert summary.replay_outcomes.latest == %{
               delivery_id: replay.delivery.id,
               event_id: replay.replayed.id,
               occurred_at: replay.replayed.occurred_at,
               outcome: "replayed",
               provider: "postmark",
               webhook_event_id: "replay-webhook-replayed"
             }

      assert summary.reconcile_facts.latest_reconciled == %{
               delivery_id: reconciled.delivery.id,
               event_id: reconciled.event.id,
               occurred_at: reconciled.event.occurred_at,
               provider: "postmark",
               reconciled_from_event_id: reconciled.orphan.id,
               reconciled_provider_event_id: "orphan-linked"
             }

      assert summary.reconcile_facts.oldest_unmatched.event_id == orphan.unresolved.id
      assert summary.reconcile_facts.oldest_unmatched.occurred_at == orphan.unresolved.occurred_at
    end

    test "stays tenant scoped and window bounded" do
      seed_support_facts()

      summary = SupportSummary.summarize_tenant(%{tenant_id: "tenant-a", window_hours: 24})

      assert summary.failed_ingest.count == 2
      assert summary.orphan_backlog.count == 1
      assert summary.replay_outcomes.counts == %{failed: 1, noop: 1, replayed: 1}
      assert summary.reconcile_facts.reconciled_count == 1
      assert summary.reconcile_facts.still_unmatched_count == 1
    end

    test "counts failed and dead webhook rows and exposes the latest failed-ingest exemplar" do
      %{failed: failed} = seed_support_facts()

      summary = SupportSummary.summarize_tenant(%{tenant_id: "tenant-a", window_hours: 24})

      assert summary.failed_ingest.count == 2
      assert summary.failed_ingest.latest.status == :dead
      assert summary.failed_ingest.latest.webhook_event_id == failed.dead.id
      assert summary.failed_ingest.latest.received_at == failed.dead.received_at
      refute summary.failed_ingest.latest.webhook_event_id == failed.failed.id
    end

    test "reports only unresolved orphan backlog facts and keeps the oldest unresolved exemplar" do
      %{orphan: orphan} = seed_support_facts()

      summary = SupportSummary.summarize_tenant(%{tenant_id: "tenant-a", window_hours: 24})

      assert summary.orphan_backlog.count == 1
      assert is_integer(summary.orphan_backlog.oldest_age_seconds)
      assert summary.orphan_backlog.oldest_age_seconds >= 17_000
      assert summary.orphan_backlog.oldest.event_id == orphan.unresolved.id
      assert summary.reconcile_facts.oldest_unmatched.event_id == orphan.unresolved.id
      refute summary.orphan_backlog.oldest.event_id == orphan.linked.id
    end

    test "keeps replay outcomes distinct from reconcile facts" do
      %{replay: replay, reconciled: reconciled} = seed_support_facts()

      summary = SupportSummary.summarize_tenant(%{tenant_id: "tenant-a", window_hours: 24})

      assert summary.replay_outcomes.counts == %{failed: 1, noop: 1, replayed: 1}
      assert summary.replay_outcomes.latest.event_id == replay.replayed.id
      assert summary.replay_outcomes.latest.outcome == "replayed"

      assert summary.reconcile_facts.reconciled_count == 1
      assert summary.reconcile_facts.latest_reconciled.event_id == reconciled.event.id
      assert summary.reconcile_facts.latest_reconciled.reconciled_from_event_id ==
               reconciled.orphan.id

      refute summary.reconcile_facts.latest_reconciled.event_id == replay.replayed.id
    end
  end

  defp seed_support_facts do
    now = DateTime.utc_now()
    old = DateTime.add(now, -48, :hour)

    replay_delivery =
      Generators.delivery_fixture(
        tenant_id: "tenant-a",
        provider: "postmark",
        recipient: "replay@example.com",
        status: :sent
      )

    reconciled_delivery =
      Generators.delivery_fixture(
        tenant_id: "tenant-a",
        provider: "postmark",
        recipient: "reconciled@example.com",
        status: :sent
      )

    failed =
      insert_webhook_event!(
        tenant_id: "tenant-a",
        provider_event_id: "failed-ingest",
        status: :failed,
        received_at: DateTime.add(now, -4, :hour)
      )

    dead =
      insert_webhook_event!(
        tenant_id: "tenant-a",
        provider_event_id: "failed-dead",
        status: :dead,
        received_at: DateTime.add(now, -2, :hour)
      )

    _ignored_old_failed =
      insert_webhook_event!(
        tenant_id: "tenant-a",
        provider_event_id: "failed-old",
        status: :failed,
        received_at: old
      )

    _ignored_foreign_failed =
      insert_webhook_event!(
        tenant_id: "tenant-b",
        provider_event_id: "failed-foreign",
        status: :failed,
        received_at: DateTime.add(now, -1, :hour)
      )

    {:ok, unresolved_orphan} =
      Events.append(%{
        tenant_id: "tenant-a",
        type: :delivered,
        delivery_id: nil,
        occurred_at: DateTime.add(now, -5, :hour),
        needs_reconciliation: true,
        metadata: %{
          "provider" => "postmark",
          "provider_event_id" => "orphan-open",
          "provider_message_id" => "msg-open"
        }
      })

    {:ok, linked_orphan} =
      Events.append(%{
        tenant_id: "tenant-a",
        type: :delivered,
        delivery_id: nil,
        occurred_at: DateTime.add(now, -6, :hour),
        needs_reconciliation: true,
        metadata: %{
          "provider" => "postmark",
          "provider_event_id" => "orphan-linked",
          "provider_message_id" => "msg-linked"
        }
      })

    {:ok, _ignored_old_orphan} =
      Events.append(%{
        tenant_id: "tenant-a",
        type: :delivered,
        delivery_id: nil,
        occurred_at: old,
        needs_reconciliation: true,
        metadata: %{
          "provider" => "postmark",
          "provider_event_id" => "orphan-old",
          "provider_message_id" => "msg-old"
        }
      })

    {:ok, _ignored_foreign_orphan} =
      Events.append(%{
        tenant_id: "tenant-b",
        type: :delivered,
        delivery_id: nil,
        occurred_at: DateTime.add(now, -3, :hour),
        needs_reconciliation: true,
        metadata: %{
          "provider" => "postmark",
          "provider_event_id" => "orphan-foreign",
          "provider_message_id" => "msg-foreign"
        }
      })

    {:ok, replay_failed} =
      Events.append(%{
        tenant_id: "tenant-a",
        delivery_id: replay_delivery.id,
        type: :webhook_replay_failed,
        occurred_at: DateTime.add(now, -90, :minute),
        metadata: %{
          "provider" => "postmark",
          "webhook_event_id" => "replay-webhook-failed",
          "outcome" => "failed"
        }
      })

    {:ok, replay_noop} =
      Events.append(%{
        tenant_id: "tenant-a",
        delivery_id: replay_delivery.id,
        type: :webhook_replay_succeeded,
        occurred_at: DateTime.add(now, -70, :minute),
        metadata: %{
          "provider" => "postmark",
          "webhook_event_id" => "replay-webhook-noop",
          "outcome" => "noop"
        }
      })

    {:ok, replay_replayed} =
      Events.append(%{
        tenant_id: "tenant-a",
        delivery_id: replay_delivery.id,
        type: :webhook_replay_succeeded,
        occurred_at: DateTime.add(now, -50, :minute),
        metadata: %{
          "provider" => "postmark",
          "webhook_event_id" => "replay-webhook-replayed",
          "outcome" => "replayed"
        }
      })

    {:ok, _ignored_old_replay} =
      Events.append(%{
        tenant_id: "tenant-a",
        delivery_id: replay_delivery.id,
        type: :webhook_replay_succeeded,
        occurred_at: old,
        metadata: %{
          "provider" => "postmark",
          "webhook_event_id" => "replay-webhook-old",
          "outcome" => "replayed"
        }
      })

    {:ok, _ignored_foreign_replay} =
      Events.append(%{
        tenant_id: "tenant-b",
        delivery_id: replay_delivery.id,
        type: :webhook_replay_failed,
        occurred_at: DateTime.add(now, -40, :minute),
        metadata: %{
          "provider" => "postmark",
          "webhook_event_id" => "replay-webhook-foreign",
          "outcome" => "failed"
        }
      })

    {:ok, reconciled_event} =
      Events.append(%{
        tenant_id: "tenant-a",
        delivery_id: reconciled_delivery.id,
        type: :reconciled,
        occurred_at: DateTime.add(now, -30, :minute),
        metadata: %{
          "reconciled_from_event_id" => linked_orphan.id,
          "reconciled_provider" => "postmark",
          "reconciled_provider_event_id" => "orphan-linked"
        }
      })

    {:ok, _ignored_old_reconciled} =
      Events.append(%{
        tenant_id: "tenant-a",
        delivery_id: reconciled_delivery.id,
        type: :reconciled,
        occurred_at: old,
        metadata: %{
          "reconciled_from_event_id" => Ecto.UUID.generate(),
          "reconciled_provider" => "postmark",
          "reconciled_provider_event_id" => "orphan-linked-old"
        }
      })

    {:ok, _ignored_foreign_reconciled} =
      Events.append(%{
        tenant_id: "tenant-b",
        delivery_id: reconciled_delivery.id,
        type: :reconciled,
        occurred_at: DateTime.add(now, -20, :minute),
        metadata: %{
          "reconciled_from_event_id" => Ecto.UUID.generate(),
          "reconciled_provider" => "postmark",
          "reconciled_provider_event_id" => "orphan-linked-foreign"
        }
      })

    %{
      failed: %{failed: failed, dead: dead},
      orphan: %{unresolved: unresolved_orphan, linked: linked_orphan},
      replay: %{delivery: replay_delivery, failed: replay_failed, noop: replay_noop, replayed: replay_replayed},
      reconciled: %{delivery: reconciled_delivery, orphan: linked_orphan, event: reconciled_event}
    }
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
      received_at: DateTime.utc_now(),
      processed_at: DateTime.utc_now()
    }

    attrs
    |> Enum.into(defaults)
    |> WebhookEvent.changeset()
    |> TestRepo.insert!()
  end
end
