defmodule Mix.Tasks.Mailglass.Suppressions.ResyncTest do
  use Mailglass.DataCase, async: false

  import ExUnit.CaptureIO

  alias Mailglass.{Clock, TestRepo}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.Entry
  alias Mailglass.Suppression.Resync

  @tenant_id "resync-tenant"
  @other_tenant_id "other-tenant"

  defmodule CountingSuppressionStore do
    def check_many(keys, _opts) do
      send(Application.fetch_env!(:mailglass, :resync_bulk_check_pid), {:resync_bulk_check, keys})
      List.duplicate(:not_suppressed, length(keys))
    end

    def check(_key, _opts), do: :not_suppressed
  end

  describe "Mailglass.Suppression.Resync.run/1" do
    test "uses one tenant-scoped candidate path for dry-run and apply" do
      complaint = insert_delivery!(tenant_id: @tenant_id, recipient: "complaint@example.com")

      unsubscribed =
        insert_delivery!(tenant_id: @tenant_id, recipient: "unsub@example.com", stream: :bulk)

      hard_bounce = insert_delivery!(tenant_id: @tenant_id, recipient: "bounce@example.com")

      _other_delivery =
        insert_delivery!(tenant_id: @other_tenant_id, recipient: "other@example.com")

      insert_event!(complaint, :complained, "evt-complaint")
      insert_event!(unsubscribed, :unsubscribed, "evt-unsub")
      insert_event!(hard_bounce, :bounced, "evt-bounce", reject_reason: :bounced)

      insert_event!(complaint, :complained, "evt-old",
        occurred_at: DateTime.add(Clock.utc_now(), -91, :day)
      )

      insert_existing_suppression!(@tenant_id, "complaint@example.com", :address, nil, :complaint)

      insert_event!(
        %Delivery{
          id: Ecto.UUID.generate(),
          tenant_id: @other_tenant_id,
          recipient: "other@example.com",
          stream: :transactional
        },
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

      insert_event!(delivery, :complained, "evt-recent",
        occurred_at: DateTime.add(Clock.utc_now(), -89, :day)
      )

      insert_event!(delivery, :complained, "evt-stale",
        occurred_at: DateTime.add(Clock.utc_now(), -91, :day)
      )

      assert {:ok, result} = Resync.run(tenant_id: @tenant_id, dry_run: true)
      assert result.scanned == 1
      assert result.would_insert == 1
    end
  end

  describe "Mix.Tasks.Mailglass.Suppressions.Resync.run/1" do
    test "fails loudly without --tenant-id" do
      assert_raise Mix.Error, ~r/--tenant-id/, fn ->
        Mix.Tasks.Mailglass.Suppressions.Resync.run([])
      end
    end

    test "dry-run reports counts without writing rows" do
      delivery = insert_delivery!(tenant_id: @tenant_id, recipient: "task-dry-run@example.com")
      insert_event!(delivery, :complained, "evt-task-dry-run")

      output =
        capture_io(fn ->
          Mix.Tasks.Mailglass.Suppressions.Resync.run(["--tenant-id", @tenant_id, "--dry-run"])
        end)

      assert output =~ "tenant=#{@tenant_id}"
      assert output =~ "scanned=1"
      assert output =~ "would_insert=1"
      assert output =~ "inserted=0"
      assert output =~ "existing=0"
      assert TestRepo.aggregate(Entry, :count) == 0
    end

    test "repeated apply stays idempotent on the second run" do
      delivery = insert_delivery!(tenant_id: @tenant_id, recipient: "task-apply@example.com")
      insert_event!(delivery, :complained, "evt-task-apply")

      first_output =
        capture_io(fn ->
          Mix.Tasks.Mailglass.Suppressions.Resync.run(["--tenant-id", @tenant_id])
        end)

      second_output =
        capture_io(fn ->
          Mix.Tasks.Mailglass.Suppressions.Resync.run(["--tenant-id", @tenant_id])
        end)

      assert first_output =~ "inserted=1"
      assert second_output =~ "would_insert=0"
      assert second_output =~ "inserted=0"
      assert second_output =~ "existing=1"
      assert TestRepo.aggregate(Entry, :count) == 1
    end

    test "uses bounded configured pages without changing CLI flags" do
      prior_store = Application.get_env(:mailglass, :suppression_store)
      prior_page_size = Application.get_env(:mailglass, :suppression_resync_page_size)

      Application.put_env(:mailglass, :suppression_store, CountingSuppressionStore)
      Application.put_env(:mailglass, :suppression_resync_page_size, 2)
      Application.put_env(:mailglass, :resync_bulk_check_pid, self())

      on_exit(fn ->
        restore_env(:suppression_store, prior_store)
        restore_env(:suppression_resync_page_size, prior_page_size)
        Application.delete_env(:mailglass, :resync_bulk_check_pid)
      end)

      for index <- 1..5 do
        delivery =
          insert_delivery!(tenant_id: @tenant_id, recipient: "task-page-#{index}@example.com")

        insert_event!(delivery, :complained, "evt-task-page-#{index}")
      end

      output =
        capture_io(fn ->
          Mix.Tasks.Mailglass.Suppressions.Resync.run(["--tenant-id", @tenant_id, "--dry-run"])
        end)

      assert output =~ "dry-run tenant=#{@tenant_id} scanned=5"
      assert_receive {:resync_bulk_check, [_first, _second]}
      assert_receive {:resync_bulk_check, [_third, _fourth]}
      assert_receive {:resync_bulk_check, [_last]}
      refute_receive {:resync_bulk_check, _keys}
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

  defp restore_env(key, nil), do: Application.delete_env(:mailglass, key)
  defp restore_env(key, value), do: Application.put_env(:mailglass, key, value)
end
