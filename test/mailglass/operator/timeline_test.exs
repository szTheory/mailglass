defmodule Mailglass.Operator.TimelineTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Events
  alias Mailglass.Generators
  alias Mailglass.Operator.Timeline

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
      delivery = Generators.delivery_fixture(tenant_id: "tenant-a", recipient: "ordered@example.com")
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

      assert Enum.map(rows, & &1.id) == [first.id, second.id, third.id]
    end
  end
end
