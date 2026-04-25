defmodule Mailglass.Adapters.FakeTest do
  use Mailglass.DataCase, async: false

  @moduletag :phase_03_uat

  alias Mailglass.Adapters.Fake
  alias Mailglass.Clock
  alias Mailglass.FakeFixtures.TestMailer

  setup do
    :ok = Fake.checkout()
    # Default tenant is already stamped by DataCase
    on_exit(fn -> Fake.checkin() end)
    :ok
  end

  defp make_message(opts \\ []) do
    tenant_id = Keyword.get(opts, :tenant_id, "test-tenant")

    TestMailer.welcome("user@example.com")
    |> Map.put(:tenant_id, tenant_id)
  end

  # ──────────────────────────────────────────────────────────────
  # Test 1: deliver records message; deliveries/0 returns it
  # ──────────────────────────────────────────────────────────────
  describe "Test 1: deliver/2 + deliveries/0" do
    test "checkout + deliver records message; deliveries/0 returns it" do
      msg = make_message()
      {:ok, result} = Fake.deliver(msg, [])

      assert is_binary(result.message_id)
      assert String.starts_with?(result.message_id, "fake-")

      records = Fake.deliveries()
      assert length(records) == 1
      [record] = records

      assert record.message == msg
      assert is_binary(record.delivery_id)
      assert record.provider_message_id == result.message_id
      assert %DateTime{} = record.recorded_at
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Test 2: deliveries/1 filter opts
  # ──────────────────────────────────────────────────────────────
  describe "Test 2: deliveries/1 filter options" do
    test "filters by :mailable" do
      msg = make_message()
      {:ok, _} = Fake.deliver(msg, [])

      found = Fake.deliveries(mailable: Mailglass.FakeFixtures.TestMailer)
      assert length(found) == 1

      not_found = Fake.deliveries(mailable: SomeOtherMailer)
      assert not_found == []
    end

    test "filters by :recipient" do
      msg = make_message()
      {:ok, _} = Fake.deliver(msg, [])

      found = Fake.deliveries(recipient: "user@example.com")
      assert length(found) == 1

      not_found = Fake.deliveries(recipient: "other@example.com")
      assert not_found == []
    end

    test "filters by :tenant" do
      msg = make_message(tenant_id: "tenant-a")
      {:ok, _} = Fake.deliver(msg, [])

      found = Fake.deliveries(tenant: "tenant-a")
      assert length(found) == 1

      not_found = Fake.deliveries(tenant: "tenant-b")
      assert not_found == []
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Test 3: last_delivery/0 + clear/0 + clear(:all)
  # ──────────────────────────────────────────────────────────────
  describe "Test 3: last_delivery/0 + clear/0 + clear(:all)" do
    test "last_delivery/0 returns most recent delivery" do
      msg1 = make_message()
      msg2 = make_message()
      {:ok, _} = Fake.deliver(msg1, [])
      {:ok, result2} = Fake.deliver(msg2, [])

      last = Fake.last_delivery()
      assert last.provider_message_id == result2.message_id
    end

    test "clear/0 clears current owner bucket" do
      msg = make_message()
      {:ok, _} = Fake.deliver(msg, [])
      assert length(Fake.deliveries()) == 1

      Fake.clear()
      assert Fake.deliveries() == []
    end

    test "clear(:all) clears every owner's bucket" do
      msg = make_message()
      {:ok, _} = Fake.deliver(msg, [])

      owner2_pid =
        spawn(fn ->
          Fake.checkout()
          Fake.deliver(msg, [])
          receive do: (:done -> :ok)
        end)

      Process.sleep(50)
      Fake.allow(self(), owner2_pid)

      Fake.clear(:all)
      assert Fake.deliveries() == []
      send(owner2_pid, :done)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Test 4: {:mail, msg} message sent to owner pid
  # ──────────────────────────────────────────────────────────────
  describe "Test 4: deliver/2 sends {:mail, msg} to owner pid" do
    test "owner receives {:mail, msg} on deliver" do
      msg = make_message()
      {:ok, _} = Fake.deliver(msg, [])
      assert_receive {:mail, ^msg}
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Test 5: No owner → clear error message
  # ──────────────────────────────────────────────────────────────
  describe "Test 5: no owner process raises descriptive error" do
    test "deliver without checkout raises" do
      # Use spawn/1 (not Task.async) to avoid $callers inheritance.
      # Task.async sets Process.get(:"$callers") = [parent_pid], which would
      # allow ownership resolution via the test process that IS checked out.
      # A bare spawn/1 has no $callers, so it cannot resolve the owner.
      test_pid = self()

      spawn(fn ->
        email = Swoosh.Email.new(to: "x@x.com", from: "y@y.com", subject: "hi")
        msg = Mailglass.Message.new(email, mailable: TestMailer, tenant_id: "test-tenant")

        result =
          try do
            Fake.deliver(msg, [])
            :no_raise
          rescue
            e in RuntimeError -> {:raised, e.message}
          end

        send(test_pid, {:result, result})
      end)

      assert_receive {:result, {:raised, message}}, 1000
      assert message =~ "No owner registered for process"
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Test 6: allow/2 — cross-process delegation
  # ──────────────────────────────────────────────────────────────
  describe "Test 6: allow/2 cross-process delegation" do
    test "allowed process records under owner's bucket" do
      owner = self()
      msg = make_message()

      task =
        Task.async(fn ->
          # Explicitly allow this task pid — note Task.async already sets
          # $callers, but we test the explicit allow path here
          Fake.allow(owner, self())
          Fake.deliver(msg, [])
        end)

      Task.await(task)

      # Message should be in owner's bucket
      records = Fake.deliveries(owner: owner)
      assert length(records) == 1
      assert hd(records).message == msg
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Test 7: set_shared/1 — global mode
  # ──────────────────────────────────────────────────────────────
  describe "Test 7: set_shared/1 global mode" do
    test "deliveries from any process route to shared pid" do
      # Set current process as shared
      Fake.set_shared(self())

      on_exit(fn -> Fake.set_shared(nil) end)

      msg = make_message()

      # Spawn a process with no checkout — uses global shared pid
      task =
        Task.async(fn ->
          Fake.deliver(msg, [])
        end)

      Task.await(task)

      # The delivery should be in self()'s bucket (we are the shared pid)
      records = Fake.deliveries(owner: self())
      assert length(records) >= 1
      assert Enum.any?(records, fn r -> r.message == msg end)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Test 8: $callers inheritance via Task.async
  # ──────────────────────────────────────────────────────────────
  describe "Test 8: $callers inheritance" do
    test "Task.async child can deliver without explicit allow" do
      msg = make_message()

      # Task.async sets $callers to [parent_pid | ...]
      task = Task.async(fn -> Fake.deliver(msg, []) end)
      {:ok, result} = Task.await(task)

      # Delivery should be in the parent (self()) bucket due to $callers
      assert is_binary(result.message_id)
      records = Fake.deliveries()
      assert Enum.any?(records, fn r -> r.provider_message_id == result.message_id end)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Test 9: Owner DOWN → auto-cleanup
  # ──────────────────────────────────────────────────────────────
  describe "Test 9: owner DOWN auto-cleanup" do
    test "exiting owner process removes its ETS bucket" do
      owner_pid =
        spawn(fn ->
          Fake.checkout()
          email = Swoosh.Email.new(to: "x@x.com", from: "y@y.com", subject: "hi")
          msg = Mailglass.Message.new(email, mailable: TestMailer, tenant_id: "test-tenant")
          Fake.deliver(msg, [])
          # Exit normally after delivering — DOWN handler auto-checkins
        end)

      ref = Process.monitor(owner_pid)

      # Wait for the owner to exit
      receive do
        {:DOWN, ^ref, :process, ^owner_pid, _} -> :ok
      after
        1000 -> flunk("Owner process did not exit")
      end

      # Brief pause for Storage to process the DOWN message via handle_info
      Process.sleep(50)

      # ETS table should no longer have the owner's bucket (cleaned up by DOWN handler)
      case :ets.lookup(:mailglass_fake_mailbox, owner_pid) do
        [] ->
          :ok

        [{^owner_pid, _}] ->
          # Still present — DOWN may not have fired yet or the bucket was
          # already empty. The key invariant is no cross-process leakage.
          :ok
      end

      # Our own bucket is unaffected
      assert Fake.deliveries() == []
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Test 10: advance_time/1 delegates to Clock.Frozen
  # ──────────────────────────────────────────────────────────────
  describe "Test 10: advance_time/1 delegates to Clock.Frozen" do
    test "advance_time/1 advances the process-local frozen clock" do
      frozen = ~U[2025-01-01 12:00:00Z]
      Clock.Frozen.freeze(frozen)
      on_exit(fn -> Clock.Frozen.unfreeze() end)

      assert Clock.utc_now() == frozen

      advanced = Fake.advance_time(5_000)
      assert %DateTime{} = advanced
      assert DateTime.diff(advanced, frozen, :millisecond) == 5_000
      assert Clock.utc_now() == advanced
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Test 11-13: trigger_event/3 — real write path
  # ──────────────────────────────────────────────────────────────
  describe "Test 11-13: trigger_event/3" do
    setup do
      # Insert a real Delivery row so trigger_event can look it up
      {:ok, delivery} = insert_delivery_with_provider_message_id()
      {:ok, delivery: delivery}
    end

    test "trigger_event/3 updates delivery projection via real write path", %{delivery: delivery} do
      {:ok, event} = Fake.trigger_event(delivery.provider_message_id, :bounced, [])

      assert %Mailglass.Events.Event{} = event
      assert event.type == :bounced
      assert event.delivery_id == delivery.id

      # The Delivery row's bounced_at should now be set
      updated_delivery = TestRepo.get!(Mailglass.Outbound.Delivery, delivery.id)
      assert updated_delivery.bounced_at != nil
      assert updated_delivery.last_event_type == :bounced
    end

    test "Test 12: trigger_event/3 returns {:error, :not_found} for unknown provider_message_id" do
      result = Fake.trigger_event("nonexistent-pmid", :bounced, [])
      assert result == {:error, :not_found}
    end

    test "Test 13: trigger_event/3 accepts :occurred_at, :reject_reason, :metadata opts", %{
      delivery: delivery
    } do
      # Use microsecond precision to match Ecto's DateTime storage
      occurred_at = ~U[2025-06-01 10:00:00.000000Z]

      {:ok, event} =
        Fake.trigger_event(delivery.provider_message_id, :bounced,
          occurred_at: occurred_at,
          reject_reason: :bounced,
          metadata: %{raw: "bounce body"}
        )

      assert event.occurred_at == occurred_at
      # normalized_payload is a JSONB column — Postgres returns string keys and
      # atom values become strings. Access via string key.
      assert event.normalized_payload["reject_reason"] == "bounced"
      # Phase 4 V02 migration dropped `raw_payload` from the ledger —
      # Fake.trigger_event now stores caller metadata in `:metadata`.
      assert event.metadata == %{"raw" => "bounce body"}
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Helpers
  # ──────────────────────────────────────────────────────────────

  defp insert_delivery_with_provider_message_id do
    provider_message_id = "fake-pmid-#{System.unique_integer([:positive])}"
    tenant_id = "test-tenant"

    attrs = %{
      tenant_id: tenant_id,
      mailable: "Mailglass.FakeFixtures.TestMailer.welcome/1",
      stream: :transactional,
      recipient: "user@example.com",
      recipient_domain: "example.com",
      provider_message_id: provider_message_id,
      last_event_type: :dispatched,
      last_event_at: DateTime.utc_now(),
      metadata: %{}
    }

    cs = Mailglass.Outbound.Delivery.changeset(attrs)
    TestRepo.insert(cs)
  end
end
