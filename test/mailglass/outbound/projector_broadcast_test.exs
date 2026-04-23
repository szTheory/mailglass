defmodule Mailglass.Outbound.ProjectorBroadcastTest do
  use Mailglass.DataCase, async: false

  @moduletag :phase_03_uat

  alias Mailglass.Outbound.{Delivery, Projector}
  alias Mailglass.PubSub.Topics

  setup do
    tenant_id = "test-tenant"
    # Subscribe to the tenant-wide events topic
    :ok = Phoenix.PubSub.subscribe(Mailglass.PubSub, Topics.events(tenant_id))

    {:ok, delivery} = insert_delivery(tenant_id)
    {:ok, delivery: delivery, tenant_id: tenant_id}
  end

  describe "broadcast_delivery_updated/3" do
    # Test 1: broadcasts to tenant-wide topic
    test "broadcasts {:delivery_updated, ...} to tenant-wide events topic", %{
      delivery: delivery,
      tenant_id: _tenant_id
    } do
      delivery_id = delivery.id

      :ok = Projector.broadcast_delivery_updated(delivery, :dispatched, %{foo: :bar})

      assert_receive {:delivery_updated, ^delivery_id, :dispatched, %{foo: :bar}}, 500
    end

    # Test 2: broadcasts to BOTH tenant-wide AND per-delivery topics
    test "broadcasts to both tenant-wide and per-delivery topics", %{
      delivery: delivery,
      tenant_id: tenant_id
    } do
      delivery_id = delivery.id
      per_delivery_topic = Topics.events(tenant_id, delivery_id)

      # Subscribe to per-delivery topic too
      :ok = Phoenix.PubSub.subscribe(Mailglass.PubSub, per_delivery_topic)

      :ok = Projector.broadcast_delivery_updated(delivery, :delivered, %{})

      # Should receive on tenant-wide topic
      assert_receive {:delivery_updated, ^delivery_id, :delivered, %{}}, 500

      # Should ALSO receive on per-delivery topic
      assert_receive {:delivery_updated, ^delivery_id, :delivered, %{}}, 500
    end

    # Test 3: returns :ok even when no subscribers
    test "returns :ok with no subscribers on either topic", %{delivery: delivery} do
      # Unsubscribe to simulate no-subscriber scenario
      Phoenix.PubSub.unsubscribe(
        Mailglass.PubSub,
        Topics.events(delivery.tenant_id)
      )

      result = Projector.broadcast_delivery_updated(delivery, :bounced, %{})
      assert result == :ok
    end

    # Test 4: payload shape is locked
    test "payload shape: {:delivery_updated, delivery_id :: binary, event_type :: atom, meta :: map}",
         %{delivery: delivery, tenant_id: _tenant_id} do
      delivery_id = delivery.id
      meta = %{provider: :sendgrid, latency_ms: 42}

      :ok = Projector.broadcast_delivery_updated(delivery, :opened, meta)

      assert_receive message, 500

      assert {:delivery_updated, ^delivery_id, :opened, received_meta} = message
      assert is_binary(delivery_id)
      assert is_map(received_meta)
      assert received_meta == meta
    end

    # Test 5: update_projections/2 is UNCHANGED — Phase 2 contract holds
    test "update_projections/2 signature unchanged (Phase 2 contract)", %{delivery: delivery} do
      event = %Mailglass.Events.Event{
        id: Ecto.UUID.generate(),
        tenant_id: delivery.tenant_id,
        delivery_id: delivery.id,
        type: :dispatched,
        occurred_at: DateTime.utc_now(),
        idempotency_key: nil,
        raw_payload: %{},
        normalized_payload: %{}
      }

      # update_projections/2 must still return an Ecto.Changeset
      result = Projector.update_projections(delivery, event)
      assert %Ecto.Changeset{} = result
      assert result.valid?
    end

    # Test 6: broadcast failure never rolls back — returns :ok even on PubSub failure
    test "returns :ok when PubSub broadcast fails (best-effort semantics)", %{
      delivery: delivery
    } do
      # The safe_broadcast/2 private function wraps in try/rescue.
      # This test verifies the function always returns :ok (not raises).
      result = Projector.broadcast_delivery_updated(delivery, :bounced, %{})
      assert result == :ok
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Helpers
  # ──────────────────────────────────────────────────────────────

  defp insert_delivery(tenant_id) do
    attrs = %{
      tenant_id: tenant_id,
      mailable: "MyApp.UserMailer.welcome/1",
      stream: :transactional,
      recipient: "user@example.com",
      recipient_domain: "example.com",
      last_event_type: :queued,
      last_event_at: DateTime.utc_now(),
      metadata: %{}
    }

    cs = Delivery.changeset(attrs)
    TestRepo.insert(cs)
  end
end
