defmodule Mailglass.Operator.DeliveriesTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Generators
  alias Mailglass.Operator.Deliveries

  test "outcome groups cover filtered results across pages and exclude other tenants" do
    recent = DateTime.add(DateTime.utc_now(), -60, :second)

    for event <- [:delivered, :bounced, :queued] do
      Generators.delivery_fixture(
        tenant_id: "summary-tenant",
        recipient: "#{event}@example.com",
        provider: "postmark",
        status: :sent,
        last_event_type: event,
        last_event_at: recent
      )
    end

    for {tenant, provider} <- [{"other-tenant", "postmark"}, {"summary-tenant", "sendgrid"}] do
      Generators.delivery_fixture(
        tenant_id: tenant,
        recipient: "excluded@example.com",
        provider: provider,
        status: :sent,
        last_event_type: :delivered,
        last_event_at: recent
      )
    end

    page =
      Deliveries.list_recent_deliveries_page(
        %{tenant_id: "summary-tenant", provider: "postmark"},
        per_page: 1
      )

    assert length(page.entries) == 1
    assert page.total_count == 3
    assert Enum.sum(Enum.map(page.outcome_groups, & &1.count)) == 3

    assert MapSet.new(Enum.map(page.outcome_groups, & &1.last_event_type)) ==
             MapSet.new([:delivered, :bounced, :queued])
  end

  test "search matches visible subjects and recipients, escapes wildcards, and stays tenant scoped" do
    for {tenant, recipient, subject} <- [
          {"search-tenant", "billing@example.com", "Invoice 100% paid"},
          {"search-tenant", "other@example.com", "Invoice 1000 paid"},
          {"other-tenant", "billing@example.com", "Invoice 100% paid"}
        ] do
      Generators.delivery_fixture(
        tenant_id: tenant,
        recipient: recipient,
        metadata: %{"subject" => subject},
        provider: "postmark"
      )
    end

    page = Deliveries.list_recent_deliveries_page(%{tenant_id: "search-tenant", search: "100%"})
    assert [%{recipient: "billing@example.com", subject: "Invoice 100% paid"}] = page.entries
    assert page.total_count == 1
    assert Enum.sum(Enum.map(page.outcome_groups, & &1.count)) == 1

    assert [%{recipient: "billing@example.com"}] =
             Deliveries.list_recent_deliveries(%{tenant_id: "search-tenant", search: "BILLING@"})
  end

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

  describe "get_delivery/2" do
    test "resolves the exact tenant delivery independently of list filters and page boundaries" do
      target =
        Generators.delivery_fixture(
          tenant_id: "tenant-exact",
          recipient: "exact@example.com",
          provider: "postmark",
          status: :sent,
          last_event_type: :delivered,
          last_event_at: DateTime.add(DateTime.utc_now(), -240, :hour)
        )

      _recent =
        Generators.delivery_fixture(
          tenant_id: "tenant-exact",
          recipient: "recent@example.com",
          provider: "sendgrid",
          status: :failed,
          last_event_type: :failed,
          last_event_at: DateTime.add(DateTime.utc_now(), -1, :hour)
        )

      page =
        Deliveries.list_recent_deliveries_page(
          %{
            tenant_id: "tenant-exact",
            provider: "sendgrid",
            event: :failed,
            window_hours: 24,
            per_page: 1
          },
          []
        )

      assert Enum.map(page.entries, & &1.id) != [target.id]

      assert %{
               id: id,
               tenant_id: "tenant-exact",
               recipient: "exact@example.com",
               provider: "postmark",
               last_event_type: :delivered
             } = Deliveries.get_delivery(%{tenant_id: "tenant-exact", delivery_id: target.id}, [])

      assert id == target.id
    end

    test "returns no row for a malformed, missing, or foreign exact ID" do
      foreign = Generators.delivery_fixture(tenant_id: "tenant-foreign")

      assert is_nil(
               Deliveries.get_delivery(
                 %{tenant_id: "tenant-exact-lookup", delivery_id: "not-a-uuid"},
                 []
               )
             )

      assert is_nil(Deliveries.get_delivery(%{tenant_id: "tenant-exact-lookup"}, []))

      assert is_nil(
               Deliveries.get_delivery(
                 %{tenant_id: "tenant-exact-lookup", delivery_id: foreign.id},
                 []
               )
             )
    end
  end
end
