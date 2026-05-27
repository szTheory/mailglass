defmodule Mailglass.Operator.TimelineTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Events
  alias Mailglass.Generators
  alias Mailglass.Operator.{ReplayHistory, Timeline}

  describe "list_delivery_events/2" do
    test "reads only events for the selected delivery" do
      selected = Generators.delivery_fixture(tenant_id: "tenant-a", recipient: "one@example.com")
      other = Generators.delivery_fixture(tenant_id: "tenant-a", recipient: "two@example.com")

      {:ok, _queued} =
        Events.append(%{
          tenant_id: "tenant-a",
          delivery_id: selected.id,
          type: :queued,
          occurred_at: DateTime.add(DateTime.utc_now(), -120, :second),
          metadata: %{"provider" => "postmark"}
        })

      {:ok, _delivered} =
        Events.append(%{
          tenant_id: "tenant-a",
          delivery_id: selected.id,
          type: :delivered,
          occurred_at: DateTime.add(DateTime.utc_now(), -60, :second),
          metadata: %{"provider" => "postmark"}
        })

      {:ok, _foreign_delivery_event} =
        Events.append(%{
          tenant_id: "tenant-a",
          delivery_id: other.id,
          type: :failed,
          occurred_at: DateTime.add(DateTime.utc_now(), -30, :second),
          metadata: %{"provider" => "sendgrid"}
        })

      rows = Timeline.list_delivery_events(%{tenant_id: "tenant-a", delivery_id: selected.id}, [])

      assert Enum.map(rows, & &1.type) == [:queued, :delivered]
      assert Enum.all?(rows, &(&1.delivery_id == selected.id))
    end

    test "excludes mismatched-tenant rows" do
      delivery = Generators.delivery_fixture(tenant_id: "tenant-a", recipient: "tenant@example.com")

      {:ok, _tenant_a_event} =
        Events.append(%{
          tenant_id: "tenant-a",
          delivery_id: delivery.id,
          type: :queued,
          occurred_at: DateTime.add(DateTime.utc_now(), -60, :second),
          metadata: %{"provider" => "postmark"}
        })

      {:ok, _tenant_b_event} =
        Events.append(%{
          tenant_id: "tenant-b",
          delivery_id: delivery.id,
          type: :failed,
          occurred_at: DateTime.add(DateTime.utc_now(), -30, :second),
          metadata: %{"provider" => "sendgrid"}
        })

      rows = Timeline.list_delivery_events(%{tenant_id: "tenant-a", delivery_id: delivery.id}, [])

      assert [%{tenant_id: "tenant-a", type: :queued}] = rows
    end

    test "orders events chronologically with a stable tie-breaker" do
      delivery =
        Generators.delivery_fixture(tenant_id: "tenant-a", recipient: "ordered@example.com")

      occurred_at = DateTime.add(DateTime.utc_now(), -90, :second)

      {:ok, first} =
        Events.append(%{
          tenant_id: "tenant-a",
          delivery_id: delivery.id,
          type: :queued,
          occurred_at: occurred_at,
          metadata: %{"provider" => "postmark", "stage" => "first"}
        })

      {:ok, second} =
        Events.append(%{
          tenant_id: "tenant-a",
          delivery_id: delivery.id,
          type: :sent,
          occurred_at: occurred_at,
          metadata: %{"provider" => "postmark", "stage" => "second"}
        })

      {:ok, third} =
        Events.append(%{
          tenant_id: "tenant-a",
          delivery_id: delivery.id,
          type: :delivered,
          occurred_at: DateTime.add(occurred_at, 60, :second),
          metadata: %{"provider" => "postmark", "stage" => "third"}
        })

      rows = Timeline.list_delivery_events(%{tenant_id: "tenant-a", delivery_id: delivery.id}, [])

      expected =
        [first, second, third]
        |> Enum.sort_by(&event_order_key/1)
        |> Enum.map(& &1.id)

      assert Enum.map(rows, & &1.id) == expected
    end

    test "keeps replay audit rows distinct and preserves facts for requested and completed summaries" do
      delivery = Generators.delivery_fixture(tenant_id: "tenant-a", recipient: "replay@example.com")
      now = DateTime.utc_now()

      {:ok, _requested} =
        Events.append(%{
          tenant_id: "tenant-a",
          delivery_id: delivery.id,
          type: :webhook_replay_requested,
          occurred_at: DateTime.add(now, -120, :second),
          metadata: %{
            "actor_id" => "operator-1",
            "provider" => "postmark",
            "webhook_event_id" => "webhook-1"
          }
        })

      {:ok, _completed} =
        Events.append(%{
          tenant_id: "tenant-a",
          delivery_id: delivery.id,
          type: :webhook_replay_succeeded,
          occurred_at: DateTime.add(now, -60, :second),
          metadata: %{
            "actor_id" => "operator-1",
            "provider" => "postmark",
            "webhook_event_id" => "webhook-1",
            "outcome" => "noop"
          }
        })

      rows = Timeline.list_delivery_events(%{tenant_id: "tenant-a", delivery_id: delivery.id}, [])

      assert Enum.map(rows, & &1.type) == [:webhook_replay_requested, :webhook_replay_succeeded]
      assert Enum.map(rows, &replay_summary_for(&1)) == ["requested", "completed · no change"]
      assert Enum.all?(rows, &Map.has_key?(&1.metadata, "webhook_event_id"))
    end
  end

  describe "list_delivery_replay_history/1" do
    test "returns tenant-scoped replay audit rows in chronological order" do
      selected = Generators.delivery_fixture(tenant_id: "tenant-a", recipient: "one@example.com")
      other = Generators.delivery_fixture(tenant_id: "tenant-a", recipient: "two@example.com")

      {:ok, _requested} =
        Events.append(%{
          tenant_id: "tenant-a",
          delivery_id: selected.id,
          type: :webhook_replay_requested,
          occurred_at: DateTime.add(DateTime.utc_now(), -120, :second),
          metadata: %{
            "actor_id" => "operator-1",
            "provider" => "postmark",
            "webhook_event_id" => "webhook-1",
            "webhook_provider_event_id" => "provider-1"
          }
        })

      {:ok, _succeeded} =
        Events.append(%{
          tenant_id: "tenant-a",
          delivery_id: selected.id,
          type: :webhook_replay_succeeded,
          occurred_at: DateTime.add(DateTime.utc_now(), -60, :second),
          metadata: %{
            "actor_id" => "operator-1",
            "provider" => "postmark",
            "webhook_event_id" => "webhook-1",
            "webhook_provider_event_id" => "provider-1",
            "outcome" => "replayed"
          }
        })

      {:ok, _foreign_delivery_event} =
        Events.append(%{
          tenant_id: "tenant-a",
          delivery_id: other.id,
          type: :webhook_replay_failed,
          occurred_at: DateTime.add(DateTime.utc_now(), -30, :second),
          metadata: %{
            "actor_id" => "operator-2",
            "provider" => "sendgrid",
            "webhook_event_id" => "webhook-2",
            "failure_reason" => "replay_failed"
          }
        })

      {:ok, _foreign_tenant_event} =
        Events.append(%{
          tenant_id: "tenant-b",
          delivery_id: selected.id,
          type: :webhook_replay_failed,
          occurred_at: DateTime.add(DateTime.utc_now(), -15, :second),
          metadata: %{
            "actor_id" => "operator-3",
            "provider" => "sendgrid",
            "webhook_event_id" => "webhook-3",
            "failure_reason" => "replay_failed"
          }
        })

      rows =
        ReplayHistory.list_delivery_replay_history(%{
          tenant_id: "tenant-a",
          delivery_id: selected.id
        })

      assert Enum.map(rows, & &1.type) == [:webhook_replay_requested, :webhook_replay_succeeded]
      assert Enum.map(rows, & &1.actor_id) == ["operator-1", "operator-1"]
      assert Enum.map(rows, & &1.delivery_id) == [selected.id, selected.id]
      assert Enum.map(rows, & &1.webhook_event_id) == ["webhook-1", "webhook-1"]
      assert List.last(rows).outcome == "replayed"
    end
  end

  defp replay_summary_for(%{type: :webhook_replay_requested}), do: "requested"
  defp replay_summary_for(%{type: :webhook_replay_failed}), do: "failed"

  defp replay_summary_for(%{type: :webhook_replay_succeeded, metadata: %{"outcome" => "replayed"}}),
    do: "completed · new work"

  defp replay_summary_for(%{type: :webhook_replay_succeeded, metadata: %{"outcome" => "noop"}}),
    do: "completed · no change"

  defp event_order_key(event) do
    {
      DateTime.to_unix(event.occurred_at, :microsecond),
      DateTime.to_unix(event.inserted_at, :microsecond),
      event.id
    }
  end
end
