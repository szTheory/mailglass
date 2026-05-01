defmodule Mailglass.Operator.DeliveriesTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Generators
  alias Mailglass.Operator.Deliveries

  describe "list_recent_deliveries/2" do
    test "excludes rows from other tenants" do
      recent = DateTime.add(DateTime.utc_now(), -60, :second)
      older = DateTime.add(DateTime.utc_now(), -120, :second)

      own_delivery =
        Generators.delivery_fixture(
          tenant_id: "tenant-a",
          recipient: "primary@example.com",
          provider: "postmark",
          status: :sent,
          last_event_type: :delivered,
          last_event_at: recent
        )

      _foreign_delivery =
        Generators.delivery_fixture(
          tenant_id: "tenant-b",
          recipient: "foreign@example.com",
          provider: "postmark",
          status: :sent,
          last_event_type: :delivered,
          last_event_at: older
        )

      rows = Deliveries.list_recent_deliveries(%{tenant_id: "tenant-a"}, [])

      assert [%{id: id, tenant_id: "tenant-a", recipient: "primary@example.com"} | _] = rows
      assert id == own_delivery.id
      refute Enum.any?(rows, &(&1.tenant_id == "tenant-b"))
    end

    test "filters by provider and status" do
      matching =
        Generators.delivery_fixture(
          tenant_id: "tenant-a",
          recipient: "match@example.com",
          provider: "postmark",
          status: :failed,
          last_event_type: :failed,
          last_event_at: DateTime.add(DateTime.utc_now(), -30, :second)
        )

      _wrong_provider =
        Generators.delivery_fixture(
          tenant_id: "tenant-a",
          recipient: "provider@example.com",
          provider: "sendgrid",
          status: :failed,
          last_event_type: :failed,
          last_event_at: DateTime.add(DateTime.utc_now(), -20, :second)
        )

      _wrong_status =
        Generators.delivery_fixture(
          tenant_id: "tenant-a",
          recipient: "status@example.com",
          provider: "postmark",
          status: :sent,
          last_event_type: :delivered,
          last_event_at: DateTime.add(DateTime.utc_now(), -10, :second)
        )

      rows =
        Deliveries.list_recent_deliveries(
          %{tenant_id: "tenant-a", provider: "postmark", status: :failed},
          []
        )

      assert [%{id: id, provider: "postmark", status: :failed, last_event_type: :failed}] = rows
      assert id == matching.id
    end

    test "orders rows by recency by default" do
      oldest =
        Generators.delivery_fixture(
          tenant_id: "tenant-a",
          recipient: "oldest@example.com",
          provider: "postmark",
          status: :sent,
          last_event_type: :sent,
          last_event_at: DateTime.add(DateTime.utc_now(), -300, :second)
        )

      middle =
        Generators.delivery_fixture(
          tenant_id: "tenant-a",
          recipient: "middle@example.com",
          provider: "postmark",
          status: :sent,
          last_event_type: :delivered,
          last_event_at: DateTime.add(DateTime.utc_now(), -200, :second)
        )

      newest =
        Generators.delivery_fixture(
          tenant_id: "tenant-a",
          recipient: "newest@example.com",
          provider: "postmark",
          status: :failed,
          last_event_type: :failed,
          last_event_at: DateTime.add(DateTime.utc_now(), -100, :second)
        )

      rows = Deliveries.list_recent_deliveries(%{tenant_id: "tenant-a"}, [])

      assert Enum.map(rows, & &1.id) == [newest.id, middle.id, oldest.id]
    end
  end
end
