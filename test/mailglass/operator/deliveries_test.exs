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

  describe "list_providers/2" do
    test "returns distinct providers for one tenant and time window" do
      now = DateTime.utc_now()

      Generators.delivery_fixture(
        tenant_id: "tenant-providers",
        recipient: "postmark-a@example.com",
        provider: "postmark",
        last_event_at: DateTime.add(now, -1, :hour)
      )

      Generators.delivery_fixture(
        tenant_id: "tenant-providers",
        recipient: "postmark-b@example.com",
        provider: "postmark",
        last_event_at: DateTime.add(now, -2, :hour)
      )

      Generators.delivery_fixture(
        tenant_id: "tenant-providers",
        recipient: "sendgrid@example.com",
        provider: "sendgrid",
        last_event_at: DateTime.add(now, -3, :hour)
      )

      Generators.delivery_fixture(
        tenant_id: "tenant-providers",
        recipient: "old@example.com",
        provider: "resend",
        last_event_at: DateTime.add(now, -48, :hour)
      )

      Generators.delivery_fixture(
        tenant_id: "foreign-providers",
        recipient: "foreign@example.com",
        provider: "mailgun",
        last_event_at: DateTime.add(now, -1, :hour)
      )

      assert Deliveries.list_providers(
               %{tenant_id: "tenant-providers", window_hours: 24},
               []
             ) == ["postmark", "sendgrid"]
    end
  end

  describe "list_recent_deliveries_page/2" do
    test "returns honest total and first-page boundaries from a tenant-scoped count" do
      recent = DateTime.add(DateTime.utc_now(), -10, :second)

      matching =
        for offset <- 1..3 do
          Generators.delivery_fixture(
            tenant_id: "tenant-page",
            recipient: "page-#{offset}@example.com",
            provider: "postmark",
            status: :sent,
            last_event_type: :delivered,
            last_event_at: DateTime.add(recent, -offset, :second)
          )
        end

      _foreign =
        Generators.delivery_fixture(
          tenant_id: "tenant-other",
          recipient: "foreign@example.com",
          provider: "postmark",
          status: :sent,
          last_event_type: :delivered,
          last_event_at: recent
        )

      _filtered_out =
        Generators.delivery_fixture(
          tenant_id: "tenant-page",
          recipient: "filtered@example.com",
          provider: "sendgrid",
          status: :sent,
          last_event_type: :delivered,
          last_event_at: recent
        )

      page =
        Deliveries.list_recent_deliveries_page(
          %{tenant_id: "tenant-page", provider: "postmark", page: 1, per_page: 2},
          []
        )

      assert %{
               entries: entries,
               total_count: 3,
               page: 1,
               per_page: 2,
               total_pages: 2,
               has_previous?: false,
               has_next?: true
             } = page

      assert Enum.map(entries, & &1.id) == matching |> Enum.take(2) |> Enum.map(& &1.id)
      assert Enum.count(entries) == 2
    end

    test "returns last-page entries with boundary metadata" do
      recent = DateTime.add(DateTime.utc_now(), -10, :second)

      deliveries =
        for offset <- 1..3 do
          Generators.delivery_fixture(
            tenant_id: "tenant-last",
            recipient: "last-#{offset}@example.com",
            provider: "postmark",
            status: :sent,
            last_event_type: :delivered,
            last_event_at: DateTime.add(recent, -offset, :second)
          )
        end

      page =
        Deliveries.list_recent_deliveries_page(
          %{tenant_id: "tenant-last", page: 2, per_page: 2},
          []
        )

      assert %{
               entries: [%{id: id}],
               total_count: 3,
               page: 2,
               per_page: 2,
               total_pages: 2,
               has_previous?: true,
               has_next?: false
             } = page

      assert id == deliveries |> List.last() |> Map.fetch!(:id)
    end
  end
end
