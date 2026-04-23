defmodule Mailglass.Outbound.ProjectorTest do
  use Mailglass.DataCase, async: true

  @moduletag :phase_02_uat

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Outbound.Projector
  alias Mailglass.TestRepo

  describe "update_projections/2 — monotonic timestamps (D-15)" do
    test "sets dispatched_at on first :dispatched event" do
      {:ok, delivery} = insert_delivery()
      event = build_event(:dispatched)

      {:ok, updated} =
        delivery |> Projector.update_projections(event) |> TestRepo.update()

      assert updated.dispatched_at == event.occurred_at
      assert updated.last_event_type == :dispatched
      assert updated.last_event_at == event.occurred_at
    end

    test "does NOT overwrite dispatched_at on a second :dispatched event (monotonic once)" do
      {:ok, delivery} = insert_delivery()
      first_event = build_event(:dispatched)

      {:ok, after_first} =
        delivery |> Projector.update_projections(first_event) |> TestRepo.update()

      second_event =
        build_event(:dispatched, DateTime.add(first_event.occurred_at, 300, :second))

      {:ok, after_second} =
        after_first |> Projector.update_projections(second_event) |> TestRepo.update()

      # monotonic: dispatched_at unchanged.
      assert after_second.dispatched_at == first_event.occurred_at
      # last_event_at DOES advance — it's a monotonic max, not a set-once.
      assert after_second.last_event_at == second_event.occurred_at
    end

    test "sets delivered_at on :delivered event and flips terminal to true" do
      {:ok, delivery} = insert_delivery()
      event = build_event(:delivered)

      {:ok, updated} =
        delivery |> Projector.update_projections(event) |> TestRepo.update()

      assert updated.delivered_at == event.occurred_at
      assert updated.terminal == true
      assert updated.last_event_type == :delivered
    end

    test "late :opened AFTER :delivered updates last_event_at but preserves delivered_at + terminal" do
      {:ok, delivery} = insert_delivery()
      delivered_at = DateTime.utc_now()
      delivered_event = build_event(:delivered, delivered_at)

      {:ok, after_delivered} =
        delivery |> Projector.update_projections(delivered_event) |> TestRepo.update()

      assert after_delivered.terminal == true
      assert after_delivered.delivered_at == delivered_at

      # Late :opened arrives 30s later — user reads email in inbox.
      opened_at = DateTime.add(delivered_at, 30, :second)
      opened_event = build_event(:opened, opened_at)

      {:ok, after_opened} =
        after_delivered |> Projector.update_projections(opened_event) |> TestRepo.update()

      # Projections INTACT:
      assert after_opened.delivered_at == delivered_at
      assert after_opened.terminal == true
      # Last-event pointers MOVED:
      assert after_opened.last_event_type == :opened
      assert after_opened.last_event_at == opened_at
    end

    test "non-monotonic ordering: :opened BEFORE :delivered still sets delivered_at once :delivered arrives" do
      {:ok, delivery} = insert_delivery()
      opened_first = DateTime.utc_now()

      {:ok, after_opened} =
        delivery
        |> Projector.update_projections(build_event(:opened, opened_first))
        |> TestRepo.update()

      assert after_opened.last_event_at == opened_first
      assert after_opened.terminal == false

      # Then :delivered arrives LATER (provider reordered webhooks).
      delivered_later = DateTime.add(opened_first, 60, :second)

      {:ok, after_delivered} =
        after_opened
        |> Projector.update_projections(build_event(:delivered, delivered_later))
        |> TestRepo.update()

      assert after_delivered.delivered_at == delivered_later
      assert after_delivered.terminal == true
      assert after_delivered.last_event_at == delivered_later
    end

    test "terminal never flips back: :opened after :bounced leaves terminal=true" do
      {:ok, delivery} = insert_delivery()

      {:ok, bounced} =
        delivery |> Projector.update_projections(build_event(:bounced)) |> TestRepo.update()

      assert bounced.terminal == true
      assert bounced.bounced_at != nil

      late_opened = build_event(:opened, DateTime.add(bounced.bounced_at, 30, :second))

      {:ok, after_opened} =
        bounced |> Projector.update_projections(late_opened) |> TestRepo.update()

      # terminal DOES NOT flip back
      assert after_opened.terminal == true
      assert after_opened.bounced_at == bounced.bounced_at
      assert after_opened.last_event_type == :opened
    end

    test "earlier occurred_at does NOT move last_event_at OR last_event_type backwards" do
      {:ok, delivery} = insert_delivery()
      now = DateTime.utc_now()

      {:ok, after_now} =
        delivery |> Projector.update_projections(build_event(:opened, now)) |> TestRepo.update()

      # Arriving out-of-order: an event with an earlier timestamp.
      earlier = DateTime.add(now, -60, :second)

      {:ok, after_earlier} =
        after_now
        |> Projector.update_projections(build_event(:clicked, earlier))
        |> TestRepo.update()

      # last_event_at stays at `now` — monotonic max.
      assert after_earlier.last_event_at == now
      # last_event_type also stays — the two fields advance TOGETHER so the
      # denormalized summary never disagrees with the event ledger about
      # which event is "latest" (WR-02).
      assert after_earlier.last_event_type == :opened
    end
  end

  describe "update_projections/2 — optimistic locking (D-18, Landmine §L5)" do
    test "bumps lock_version on successful update" do
      {:ok, delivery} = insert_delivery()
      assert delivery.lock_version == 1

      {:ok, updated} =
        delivery |> Projector.update_projections(build_event(:delivered)) |> TestRepo.update()

      assert updated.lock_version == 2
    end

    test "concurrent update on stale delivery raises Ecto.StaleEntryError" do
      {:ok, delivery} = insert_delivery()

      # Two dispatchers hold the same pre-update copy.
      copy_a = delivery
      copy_b = delivery

      {:ok, _a_won} =
        copy_a |> Projector.update_projections(build_event(:dispatched)) |> TestRepo.update()

      assert_raise Ecto.StaleEntryError, fn ->
        copy_b
        |> Projector.update_projections(build_event(:delivered))
        |> TestRepo.update()
      end
    end
  end

  describe "update_projections/2 — telemetry" do
    test "emits [:mailglass, :persist, :delivery, :update_projections, :stop] span" do
      handler = self()
      ref = make_ref()

      :telemetry.attach(
        "projector-test-#{inspect(ref)}",
        [:mailglass, :persist, :delivery, :update_projections, :stop],
        fn _event, _measurements, meta, _config -> send(handler, {ref, meta}) end,
        nil
      )

      {:ok, delivery} = insert_delivery()

      _ =
        delivery
        |> Projector.update_projections(build_event(:delivered))
        |> TestRepo.update()

      assert_receive {^ref, %{tenant_id: "test-tenant", delivery_id: delivery_id}}, 500
      assert is_binary(delivery_id)

      :telemetry.detach("projector-test-#{inspect(ref)}")
    end

    test "metadata whitelist — no PII keys leak into :stop metadata" do
      handler = self()
      ref = make_ref()

      :telemetry.attach(
        "projector-pii-test-#{inspect(ref)}",
        [:mailglass, :persist, :delivery, :update_projections, :stop],
        fn _event, _measurements, meta, _config -> send(handler, {ref, meta}) end,
        nil
      )

      {:ok, delivery} = insert_delivery()

      _ =
        delivery
        |> Projector.update_projections(build_event(:delivered))
        |> TestRepo.update()

      assert_receive {^ref, meta}, 500

      forbidden = [:to, :from, :body, :html_body, :subject, :headers, :recipient, :email]

      for key <- forbidden do
        refute Map.has_key?(meta, key),
               "telemetry metadata leaked PII key #{inspect(key)}: #{inspect(meta)}"
      end

      :telemetry.detach("projector-pii-test-#{inspect(ref)}")
    end
  end

  defp insert_delivery(overrides \\ %{}) do
    attrs =
      Map.merge(
        %{
          tenant_id: "test-tenant",
          mailable: "MyApp.UserMailer.welcome/1",
          stream: :transactional,
          recipient: "user@example.com",
          last_event_type: :queued,
          last_event_at: DateTime.utc_now()
        },
        overrides
      )

    attrs |> Delivery.changeset() |> TestRepo.insert()
  end

  defp build_event(type, occurred_at \\ nil) do
    %Event{
      id: Ecto.UUID.generate(),
      tenant_id: "test-tenant",
      type: type,
      occurred_at: occurred_at || DateTime.utc_now(),
      normalized_payload: %{},
      metadata: %{}
    }
  end
end
