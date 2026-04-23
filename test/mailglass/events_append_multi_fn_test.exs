defmodule Mailglass.EventsAppendMultiFnTest do
  use Mailglass.DataCase, async: false

  @moduletag :phase_03_uat

  setup do
    Mailglass.Tenancy.put_current("test-tenant")
    :ok
  end

  test "append_multi/3 still accepts a map (backward compat)" do
    attrs = %{
      type: :queued,
      delivery_id: Ecto.UUID.generate(),
      tenant_id: "test-tenant",
      occurred_at: DateTime.utc_now()
    }

    multi = Mailglass.Events.append_multi(Ecto.Multi.new(), :ev, attrs)
    assert {:ok, %{ev: _}} = Mailglass.Repo.multi(multi)
  end

  test "append_multi/3 accepts a function closing over prior Multi changes" do
    # Insert a Delivery first, then have the event attrs closure read its id.
    delivery_changeset =
      Mailglass.Outbound.Delivery.changeset(%{
        tenant_id: "test-tenant",
        mailable: "TestMailer",
        stream: :transactional,
        recipient: "a@b.com",
        last_event_type: :queued,
        last_event_at: DateTime.utc_now()
      })

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:delivery, delivery_changeset)
      |> Mailglass.Events.append_multi(:ev, fn %{delivery: d} ->
        %{
          type: :queued,
          delivery_id: d.id,
          tenant_id: "test-tenant",
          occurred_at: DateTime.utc_now()
        }
      end)

    assert {:ok, %{delivery: delivery, ev: event}} = Mailglass.Repo.multi(multi)
    assert event.delivery_id == delivery.id
  end
end
