defmodule Mailglass.Suppression.ResyncTest do
  use Mailglass.DataCase, async: false

  alias Mailglass.{Clock, TestRepo}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.Entry
  alias Mailglass.Suppression.Resync

  @tenant_id "resync-paged-tenant"

  describe "run/1" do
    test "keyset-pages equal timestamps while preserving page-local duplicate treatment" do
      occurred_at = Clock.utc_now()

      duplicate = insert_delivery!("duplicate@example.com")
      first = insert_delivery!("first@example.com")
      second = insert_delivery!("second@example.com")

      insert_event!(duplicate, "00000000-0000-0000-0000-000000000001", occurred_at)
      insert_event!(duplicate, "00000000-0000-0000-0000-000000000002", occurred_at)
      insert_event!(duplicate, "00000000-0000-0000-0000-000000000003", occurred_at)
      insert_event!(first, "00000000-0000-0000-0000-000000000004", occurred_at)
      insert_event!(second, "00000000-0000-0000-0000-000000000005", occurred_at)

      insert_existing_suppression!("first@example.com")

      assert {:ok, dry_run} =
               Resync.run(
                 tenant_id: @tenant_id,
                 dry_run: true,
                 from: DateTime.add(occurred_at, -1, :second),
                 to: DateTime.add(occurred_at, 1, :second),
                 page_size: 2
               )

      # The first two duplicate events share one page-local candidate; the
      # third straddles a page boundary and remains a distinct candidate.
      assert dry_run.scanned == 4
      assert dry_run.would_insert == 3
      assert dry_run.existing == 1
      assert dry_run.inserted == 0

      assert Enum.sort(Enum.map(dry_run.candidates, & &1.address)) == [
               "duplicate@example.com",
               "duplicate@example.com",
               "first@example.com",
               "second@example.com"
             ]

      assert {:ok, applied} =
               Resync.run(
                 tenant_id: @tenant_id,
                 from: DateTime.add(occurred_at, -1, :second),
                 to: DateTime.add(occurred_at, 1, :second),
                 page_size: 2
               )

      assert applied.scanned == dry_run.scanned
      assert applied.would_insert == dry_run.would_insert
      assert applied.existing == dry_run.existing
      assert applied.inserted == 2
      assert TestRepo.aggregate(Entry, :count) == 3
    end

    test "halts on a bounded write failure after prior pages committed" do
      occurred_at = Clock.utc_now()
      first = insert_delivery!("first-write@example.com")
      second = insert_delivery!("second-write@example.com")

      insert_event!(first, "00000000-0000-0000-0000-000000000010", occurred_at)
      insert_event!(second, "00000000-0000-0000-0000-000000000011", occurred_at)

      counter = start_supervised!({Agent, fn -> 0 end})

      assert {:error, :injected_write_failure} =
               Resync.run(
                 tenant_id: @tenant_id,
                 from: DateTime.add(occurred_at, -1, :second),
                 to: DateTime.add(occurred_at, 1, :second),
                 page_size: 1,
                 upsert_fun: fn rows, insert ->
                   Agent.get_and_update(counter, fn
                     0 -> {insert.(rows), 1}
                     attempts -> {{:error, :injected_write_failure}, attempts + 1}
                   end)
                 end
               )

      assert TestRepo.aggregate(Entry, :count) == 1
    end
  end

  defp insert_delivery!(recipient) do
    %{
      tenant_id: @tenant_id,
      mailable: "MyApp.Mailers.WelcomeMailer.welcome/1",
      stream: :transactional,
      recipient: recipient,
      provider: "postmark",
      provider_message_id: "msg-#{System.unique_integer([:positive])}",
      last_event_type: :queued,
      last_event_at: Clock.utc_now(),
      status: :sent
    }
    |> Delivery.changeset()
    |> TestRepo.insert!()
  end

  defp insert_event!(delivery, id, occurred_at) do
    %{
      id: id,
      tenant_id: @tenant_id,
      delivery_id: delivery.id,
      type: :complained,
      occurred_at: occurred_at,
      metadata: %{"provider" => "postmark", "provider_event_id" => id}
    }
    |> Event.changeset()
    |> TestRepo.insert!()
  end

  defp insert_existing_suppression!(address) do
    %{
      tenant_id: @tenant_id,
      address: address,
      scope: :address,
      reason: :complaint,
      source: "manual:seed",
      metadata: %{}
    }
    |> Entry.changeset()
    |> TestRepo.insert!()
  end
end
