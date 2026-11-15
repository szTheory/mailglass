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

  # Keys the operator read model carried before Phase 182. Maps may gain keys in a
  # minor release, so the guard is "these are still present", never the exact set.
  @legacy_keys ~w[id tenant_id mailable stream recipient subject provider
                  provider_message_id status last_event_type delivery_confirmed
                  last_event_at inserted_at]a

  # {label, event history, last_event_type, bounced?, delivered?}
  # Each history leaves the evidence a consumer needs to read the row as a failed
  # delivery. `rejected` has no timestamp column, so only the `terminal` latch
  # carries it; a bounce also leaves `bounced_at`.
  @failure_histories [
    {"bounce then open", [:sent, :bounced, :opened], :opened, true, false},
    {"bounce then click", [:sent, :bounced, :clicked], :clicked, true, false},
    {"rejected then open", [:sent, :rejected, :opened], :opened, false, false},
    {"delivered then bounce", [:sent, :delivered, :bounced], :bounced, true, true}
  ]

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

  describe "histories that contain a failure" do
    for {label, types, last, bounced?, delivered?} <- @failure_histories do
      test "#{label} keeps the failure evidence on the row" do
        tenant = tenant("history")
        delivery = delivery_with_history(tenant, unquote(types))

        detail = Deliveries.get_delivery(%{tenant_id: tenant, delivery_id: delivery.id}, [])
        %{entries: [entry]} = Deliveries.list_recent_deliveries_page(%{tenant_id: tenant})

        for row <- [detail, entry] do
          assert row.last_event_type == unquote(last)
          assert row.terminal == true
          assert row.bounced_at != nil == unquote(bounced?)
          assert row.delivered_at != nil == unquote(delivered?)
          assert row.complained_at == nil
          assert row.suppressed_at == nil

          # The evidence a consumer needs to call this row failed: a recorded bounce,
          # or a terminal latch with no delivery, complaint or suppression behind it.
          assert row.bounced_at != nil or
                   (row.terminal == true and row.delivered_at == nil and
                      row.complained_at == nil and row.suppressed_at == nil)
        end
      end
    end

    test "a complaint with no delivery is not mistaken for a failure signal" do
      tenant = tenant("complaint")
      delivery = delivery_with_history(tenant, [:sent, :complained])

      row = Deliveries.get_delivery(%{tenant_id: tenant, delivery_id: delivery.id}, [])

      # `terminal` latches on a complaint too, which is why the row also carries the
      # fields that tell a complaint from a failure.
      assert row.terminal == true
      assert %DateTime{} = row.complained_at
      assert row.bounced_at == nil
      assert row.delivered_at == nil
    end

    test "a suppression carries suppressed_at and the terminal latch" do
      tenant = tenant("suppression")
      delivery = delivery_with_history(tenant, [:suppressed])

      row = Deliveries.get_delivery(%{tenant_id: tenant, delivery_id: delivery.id}, [])

      assert row.terminal == true
      assert %DateTime{} = row.suppressed_at
      assert row.bounced_at == nil
    end
  end

  describe "additive-only read model" do
    test "every pre-existing key is still present on both read functions" do
      tenant = tenant("legacy")
      delivery = delivery_with_history(tenant, [:sent, :delivered])

      %{entries: [entry]} = Deliveries.list_recent_deliveries_page(%{tenant_id: tenant})
      detail = Deliveries.get_delivery(%{tenant_id: tenant, delivery_id: delivery.id}, [])

      for row <- [entry, detail], key <- @legacy_keys do
        assert Map.has_key?(row, key),
               "pre-existing key #{inspect(key)} is gone from #{inspect(row)}"
      end

      assert entry.delivery_confirmed == true
      assert %DateTime{} = entry.delivered_at
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
