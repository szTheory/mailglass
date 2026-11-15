defmodule Mailglass.Operator.DeliveriesProjectionTest do
  @moduledoc """
  DB-backed contract for the lifecycle fields the operator read model exposes
  (Phase 182 D-05).

  Histories are driven through the real `Mailglass.Outbound.Projector`, so
  `bounced_at` and the `terminal` latch hold what production writes, not what a
  fixture author guessed. The read model returns raw column values on rows and
  `true | nil` flags on `outcome_groups`. A `false` flag would read as "present"
  to a consumer that treats any non-nil value as a recorded fact, so the producer
  must never emit one.
  """

  use Mailglass.DataCase, async: true

  alias Mailglass.Events.Event
  alias Mailglass.Operator.Deliveries
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Outbound.Projector
  alias Mailglass.TestRepo

  @flag_keys [:bounced_at, :terminal, :complained_at, :suppressed_at]

  describe "bounce then open" do
    test "both read functions return the stored lifecycle fields" do
      tenant = tenant("bounce-open")
      delivery = delivery_with_history(tenant, [:sent, :bounced, :opened])

      %{entries: [entry]} = Deliveries.list_recent_deliveries_page(%{tenant_id: tenant})
      detail = Deliveries.get_delivery(%{tenant_id: tenant, delivery_id: delivery.id}, [])

      for row <- [entry, detail] do
        assert %DateTime{} = row.bounced_at
        assert row.terminal == true
        assert row.last_event_type == :opened
        assert row.delivered_at == nil
        assert row.complained_at == nil
        assert row.suppressed_at == nil
      end

      assert entry.bounced_at == delivery_reload(delivery).bounced_at
    end

    test "outcome groups keep a bounced then opened row apart from an ordinary opened row" do
      tenant = tenant("groups")
      delivery_with_history(tenant, [:sent, :bounced, :opened], recipient: "bounced@example.com")
      plain = insert_delivery(tenant, %{recipient: "plain@example.com", last_event_type: :opened})

      %{outcome_groups: groups} = Deliveries.list_recent_deliveries_page(%{tenant_id: tenant})

      opened = Enum.filter(groups, &(&1.last_event_type == :opened))
      assert length(opened) == 2, "expected two opened groups, got: #{inspect(opened)}"

      assert %{count: 1, terminal: true} = Enum.find(opened, &(&1.bounced_at == true))
      assert %{count: 1, terminal: nil} = Enum.find(opened, &(&1.bounced_at == nil))
      assert plain.terminal == false
    end
  end

  describe "outcome group flags" do
    test "are true or nil, never false, for every flag and every history" do
      tenant = tenant("no-false")

      # A non-terminal row first: a bare `terminal` column would surface `false` here.
      insert_delivery(tenant, %{recipient: "queued@example.com", last_event_type: :queued})
      delivery_with_history(tenant, [:sent], recipient: "sent@example.com")
      delivery_with_history(tenant, [:sent, :delivered], recipient: "delivered@example.com")
      delivery_with_history(tenant, [:sent, :bounced, :opened], recipient: "bounced@example.com")
      delivery_with_history(tenant, [:sent, :complained], recipient: "complained@example.com")
      delivery_with_history(tenant, [:suppressed], recipient: "suppressed@example.com")

      %{outcome_groups: groups} = Deliveries.list_recent_deliveries_page(%{tenant_id: tenant})

      assert length(groups) >= 5

      for group <- groups, key <- @flag_keys do
        assert Map.has_key?(group, key), "group is missing #{inspect(key)}: #{inspect(group)}"

        assert Map.fetch!(group, key) in [true, nil],
               "#{inspect(key)} must be true or nil, got #{inspect(Map.fetch!(group, key))} in #{inspect(group)}"
      end
    end
  end

  # -- helpers ---------------------------------------------------------------

  defp tenant(label), do: "projection-#{label}-#{System.unique_integer([:positive])}"

  defp insert_delivery(tenant, overrides) do
    attrs =
      Map.merge(
        %{
          tenant_id: tenant,
          mailable: "MyApp.UserMailer",
          stream: :transactional,
          recipient: "user@example.com",
          provider: "postmark",
          status: :sent,
          last_event_type: :sent,
          last_event_at: seconds_ago(600)
        },
        Map.new(overrides)
      )

    {:ok, delivery} = attrs |> Delivery.changeset() |> TestRepo.insert()
    delivery
  end

  # Inserts a delivery, then applies each event type through the real projector,
  # one second apart and oldest first, so `last_event_type`, `bounced_at` and the
  # `terminal` latch are exactly what a webhook replay would leave behind.
  defp delivery_with_history(tenant, types, overrides \\ []) do
    delivery = insert_delivery(tenant, Map.new(overrides))
    start = seconds_ago(300)

    types
    |> Enum.with_index()
    |> Enum.reduce(delivery, fn {type, index}, current ->
      event = build_event(tenant, type, DateTime.add(start, index, :second))
      {:ok, updated} = current |> Projector.update_projections(event) |> TestRepo.update()
      updated
    end)
  end

  defp delivery_reload(delivery), do: TestRepo.get!(Delivery, delivery.id)

  defp build_event(tenant, type, occurred_at) do
    %Event{
      id: Ecto.UUID.generate(),
      tenant_id: tenant,
      type: type,
      occurred_at: occurred_at,
      normalized_payload: %{},
      metadata: %{}
    }
  end

  defp seconds_ago(seconds), do: DateTime.add(DateTime.utc_now(), -seconds, :second)
end
