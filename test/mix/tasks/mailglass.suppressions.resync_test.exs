defmodule Mix.Tasks.Mailglass.Suppressions.ResyncTest do
  use Mailglass.DataCase, async: false

  alias Mailglass.{Clock, TestRepo}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.Entry
  alias Mailglass.Suppression.Resync

  @tenant_id "resync-tenant"
  @other_tenant_id "other-tenant"

  describe "Mailglass.Suppression.Resync.run/1" do
    test "uses one tenant-scoped candidate path for dry-run and apply" do
      complaint = insert_delivery!(tenant_id: @tenant_id, recipient: "complaint@example.com")
      unsubscribed = insert_delivery!(tenant_id: @tenant_id, recipient: "unsub@example.com", stream: :bulk)
      hard_bounce = insert_delivery!(tenant_id: @tenant_id, recipient: "bounce@example.com")

      _other_delivery = insert_delivery!(tenant_id: @other_tenant_id, recipient: "other@example.com")

      insert_event!(complaint, :complained, "evt-complaint")
      insert_event!(unsubscribed, :unsubscribed, "evt-unsub")
      insert_event!(hard_bounce, :bounced, "evt-bounce", reject_reason: :bounced)
      insert_event!(complaint, :complained, "evt-old", occurred_at: DateTime.add(Clock.utc_now(), -91, :day))
      insert_existing_suppression!(@tenant_id, "complaint@example.com", :address, nil, :complaint)

      insert_event!(
        %Delivery{id: Ecto.UUID.generate(), tenant_id: @other_tenant_id, recipient: "other@example.com", stream: :transactional},
        :complained,
        "evt-other"
      )

      assert {:ok, dry_run} = Resync.run(tenant_id: @tenant_id, dry_run: true)
      assert dry_run.scanned == 3
      assert dry_run.would_insert == 2
      assert dry_run.existing == 1
      assert dry_run.inserted == 0
      assert TestRepo.aggregate(Entry, :count) == 1

      assert {:ok, applied} = Resync.run(tenant_id: @tenant_id)
      assert applied.scanned == dry_run.scanned
      assert applied.would_insert == dry_run.would_insert
      assert applied.existing == dry_run.existing
      assert applied.inserted == 2
      assert TestRepo.aggregate(Entry, :count) == 3

      assert {:ok, repeated} = Resync.run(tenant_id: @tenant_id)
      assert repeated.scanned == 3
      assert repeated.would_insert == 0
      assert repeated.existing == 3
      assert repeated.inserted == 0
      assert TestRepo.aggregate(Entry, :count) == 3
    end

    test "defaults to the last 90 days when no window overrides are given" do
      delivery = insert_delivery!(tenant_id: @tenant_id, recipient: "window@example.com")

      insert_event!(delivery, :complained, "evt-recent", occurred_at: DateTime.add(Clock.utc_now(), -89, :day))
      insert_event!(delivery, :complained, "evt-stale", occurred_at: DateTime.add(Clock.utc_now(), -91, :day))

      assert {:ok, result} = Resync.run(tenant_id: @tenant_id, dry_run: true)
      assert result.scanned == 1
      assert result.would_insert == 1
    end
  end

  defp insert_delivery!(attrs) do
    attrs
    |> Enum.into(%{
      tenant_id: @tenant_id,
      mailable: "MyApp.Mailers.WelcomeMailer.welcome/1",
      stream: :transactional,
      recipient: "to@example.com",
      provider: "postmark",
      provider_message_id: "msg-#{System.unique_integer([:positive])}",
      last_event_type: :queued,
      last_event_at: Clock.utc_now(),
      status: :sent
    })
    |> Delivery.changeset()
    |> TestRepo.insert!()
  end

  defp insert_event!(%Delivery{} = delivery, type, provider_event_id, overrides \\ []) do
    overrides =
      Enum.into(overrides, %{
        tenant_id: delivery.tenant_id,
        delivery_id: delivery.id,
        type: type,
        occurred_at: Clock.utc_now(),
        reject_reason: reject_reason_for(type),
        metadata: %{
          "provider" => "postmark",
          "provider_event_id" => provider_event_id,
          "message_id" => delivery.provider_message_id
        }
      })

    overrides
    |> Event.changeset()
    |> TestRepo.insert!()
  end

  defp insert_existing_suppression!(tenant_id, address, scope, stream, reason) do
    %{
      tenant_id: tenant_id,
      address: address,
      scope: scope,
      stream: stream,
      reason: reason,
      source: "manual:seed",
      metadata: %{}
    }
    |> Entry.changeset()
    |> TestRepo.insert!()
  end

  defp reject_reason_for(:bounced), do: :bounced
  defp reject_reason_for(_type), do: nil
end
