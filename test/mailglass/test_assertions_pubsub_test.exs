defmodule Mailglass.TestAssertionsPubSubTest do
  @moduledoc """
  Tests for PubSub-backed assertions: assert_mail_delivered/2 and
  assert_mail_bounced/2 (Tests 11-13 from the plan spec).

  Uses Mailglass.DataCase (async: false — Repo). Sets up PubSub subscription
  and fires broadcasts directly via Projector.broadcast_delivery_updated/3.
  """
  use Mailglass.DataCase, async: false

  import Mailglass.TestAssertions

  alias Mailglass.Outbound.Delivery

  setup do
    tenant_id = "test-tenant"
    delivery_id = Ecto.UUID.generate()

    # Subscribe to the tenant-wide topic — MailerCase does this automatically,
    # but DataCase doesn't. Subscribe explicitly for these tests.
    :ok = Phoenix.PubSub.subscribe(Mailglass.PubSub, Mailglass.PubSub.Topics.events(tenant_id))
    :ok = Phoenix.PubSub.subscribe(Mailglass.PubSub, Mailglass.PubSub.Topics.events(tenant_id, delivery_id))

    {:ok, tenant_id: tenant_id, delivery_id: delivery_id}
  end

  # Test 11: assert_mail_delivered/2 consumes :delivered broadcast
  test "assert_mail_delivered/2 passes when :delivered broadcast arrives", %{
    tenant_id: tenant_id,
    delivery_id: delivery_id
  } do
    # Fire the broadcast (this is what Projector.broadcast_delivery_updated does)
    Phoenix.PubSub.broadcast(
      Mailglass.PubSub,
      Mailglass.PubSub.Topics.events(tenant_id, delivery_id),
      {:delivery_updated, delivery_id, :delivered, %{tenant_id: tenant_id}}
    )

    assert_mail_delivered(delivery_id, 100)
  end

  # Test 12: assert_mail_bounced/2 consumes :bounced broadcast
  test "assert_mail_bounced/2 passes when :bounced broadcast arrives", %{
    tenant_id: tenant_id,
    delivery_id: delivery_id
  } do
    Phoenix.PubSub.broadcast(
      Mailglass.PubSub,
      Mailglass.PubSub.Topics.events(tenant_id, delivery_id),
      {:delivery_updated, delivery_id, :bounced, %{tenant_id: tenant_id}}
    )

    assert_mail_bounced(delivery_id, 100)
  end

  # Test 13: assert_mail_delivered accepts Delivery struct (extracts .id)
  test "assert_mail_delivered/2 accepts a %Delivery{} struct (extracts .id)", %{
    tenant_id: tenant_id,
    delivery_id: delivery_id
  } do
    delivery = %Delivery{id: delivery_id, tenant_id: tenant_id}

    Phoenix.PubSub.broadcast(
      Mailglass.PubSub,
      Mailglass.PubSub.Topics.events(tenant_id, delivery_id),
      {:delivery_updated, delivery_id, :delivered, %{tenant_id: tenant_id}}
    )

    # Pass the struct directly (not just the ID)
    assert_mail_delivered(delivery, 100)
  end

  # Timeout behavior
  test "assert_mail_delivered/2 flunks on timeout", %{delivery_id: delivery_id} do
    assert_raise ExUnit.AssertionError, ~r/assert_mail_delivered timed out/, fn ->
      assert_mail_delivered(delivery_id, 10)
    end
  end

  test "assert_mail_bounced/2 flunks on timeout", %{delivery_id: delivery_id} do
    assert_raise ExUnit.AssertionError, ~r/assert_mail_bounced timed out/, fn ->
      assert_mail_bounced(delivery_id, 10)
    end
  end
end
