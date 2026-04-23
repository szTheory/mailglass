defmodule Mailglass.Outbound.DeliverManyTest do
  # async: false required — DB writes + Application.put_env
  use Mailglass.DataCase, async: false

  alias Mailglass.{Outbound, Message, TestRepo}
  alias Mailglass.Outbound.Delivery

  setup do
    Mailglass.Adapters.Fake.checkout()
    Mailglass.Adapters.Fake.set_shared(self())

    # Use task_supervisor so Oban is not required
    Application.put_env(:mailglass, :async_adapter, :task_supervisor)
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :auto)

    on_exit(fn ->
      Process.sleep(50)
      Application.put_env(:mailglass, :async_adapter, :oban)
      Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
    end)

    :ok
  end

  describe "deliver_many/2 — basic batch (Test 1)" do
    test "returns {:ok, [%Delivery{}]} with one row per input message" do
      uid = unique_id()
      msgs = [
        build_message("batch1-#{uid}@example.com"),
        build_message("batch2-#{uid}@example.com"),
        build_message("batch3-#{uid}@example.com")
      ]

      result = Outbound.deliver_many(msgs, [])

      assert {:ok, deliveries} = result
      assert length(deliveries) == 3
      assert Enum.all?(deliveries, fn d -> %Delivery{} = d end)
    end
  end

  describe "deliver_many/2 — idempotency keys (Test 2)" do
    test "each Delivery has a unique idempotency_key computed from message content" do
      uid = unique_id()
      msgs = [
        build_message("idem1-#{uid}@example.com"),
        build_message("idem2-#{uid}@example.com"),
        build_message("idem3-#{uid}@example.com")
      ]

      {:ok, deliveries} = Outbound.deliver_many(msgs, [])

      keys = Enum.map(deliveries, & &1.idempotency_key)
      assert length(Enum.uniq(keys)) == 3
      assert Enum.all?(keys, &is_binary/1)
    end
  end

  describe "deliver_many/2 — idempotency replay (Test 3)" do
    test "re-running same batch re-fetches existing rows (ON CONFLICT DO NOTHING replay)" do
      uid = unique_id()
      msgs = [
        build_message("replay1-#{uid}@example.com"),
        build_message("replay2-#{uid}@example.com")
      ]

      {:ok, first_deliveries} = Outbound.deliver_many(msgs, [])
      first_ids = Enum.map(first_deliveries, & &1.id) |> Enum.sort()

      {:ok, second_deliveries} = Outbound.deliver_many(msgs, [])
      second_ids = Enum.map(second_deliveries, & &1.id) |> Enum.sort()

      # Same rows re-fetched — idempotency_key collisions are no-ops
      assert first_ids == second_ids
    end
  end

  describe "deliver_many/2 — mixed-batch replay (Test 4)" do
    test "first 2 msgs re-fetched, new 3rd msg gets a fresh Delivery" do
      uid = unique_id()
      msg1 = build_message("mixed1-#{uid}@example.com")
      msg2 = build_message("mixed2-#{uid}@example.com")
      msg3 = build_message("mixed3-#{uid}@example.com")

      {:ok, first_deliveries} = Outbound.deliver_many([msg1, msg2], [])
      first_ids = Enum.map(first_deliveries, & &1.id) |> MapSet.new()

      {:ok, second_deliveries} = Outbound.deliver_many([msg1, msg2, msg3], [])
      assert length(second_deliveries) == 3

      second_ids = Enum.map(second_deliveries, & &1.id) |> MapSet.new()

      # The two original rows are in both sets
      overlap = MapSet.intersection(first_ids, second_ids)
      assert MapSet.size(overlap) == 2

      # The 3rd row is new
      new_ids = MapSet.difference(second_ids, first_ids)
      assert MapSet.size(new_ids) == 1
    end
  end

  describe "deliver_many/2 — preflight failure (Test 5)" do
    test "suppressed message becomes a :failed Delivery in result list; others succeed" do
      uid = unique_id()
      blocked_addr = "suppressed-batch-#{uid}@example.com"

      {:ok, _} =
        Mailglass.Suppression.Entry.changeset(%{
          tenant_id: "test-tenant",
          address: blocked_addr,
          scope: :address,
          reason: :manual,
          source: "test"
        })
        |> TestRepo.insert()

      msgs = [
        build_message("ok1-#{uid}@example.com"),
        build_message(blocked_addr),
        build_message("ok2-#{uid}@example.com")
      ]

      {:ok, deliveries} = Outbound.deliver_many(msgs, [])

      assert length(deliveries) == 3

      failed = Enum.filter(deliveries, &(&1.status == :failed))
      succeeded = Enum.filter(deliveries, &(&1.status == :queued))

      assert length(failed) == 1
      assert length(succeeded) == 2

      assert hd(failed).recipient == blocked_addr
      assert hd(failed).last_error != nil
    end
  end

  describe "deliver_many/2 — empty batch (Test 6)" do
    test "returns {:ok, []} for empty input" do
      result = Outbound.deliver_many([], [])
      assert {:ok, []} = result
    end
  end

  describe "deliver_many!/2 — all success (Test 7)" do
    test "returns [%Delivery{}] list when all succeed (no raise)" do
      uid = unique_id()
      msgs = [
        build_message("bang1-#{uid}@example.com"),
        build_message("bang2-#{uid}@example.com")
      ]

      result = Outbound.deliver_many!(msgs, [])

      assert is_list(result)
      assert length(result) == 2
      assert Enum.all?(result, fn d -> %Delivery{} = d end)
    end
  end

  describe "deliver_many!/2 — partial failure (Test 8)" do
    test "raises %BatchFailed{type: :partial_failure} when at least one fails" do
      uid = unique_id()
      blocked_addr = "bang-blocked-#{uid}@example.com"

      {:ok, _} =
        Mailglass.Suppression.Entry.changeset(%{
          tenant_id: "test-tenant",
          address: blocked_addr,
          scope: :address,
          reason: :manual,
          source: "test"
        })
        |> TestRepo.insert()

      msgs = [
        build_message("bang-ok-#{uid}@example.com"),
        build_message(blocked_addr)
      ]

      assert_raise Mailglass.Error.BatchFailed, fn ->
        Outbound.deliver_many!(msgs, [])
      end

      # Also check the type is :partial_failure
      try do
        Outbound.deliver_many!(msgs, [])
      rescue
        err in Mailglass.Error.BatchFailed ->
          assert err.type == :partial_failure
          assert length(err.failures) == 1
      end
    end
  end

  describe "deliver_many!/2 — all failures (Test 9)" do
    test "raises %BatchFailed{type: :all_failed} when every message fails" do
      uid = unique_id()
      addr1 = "all-fail-1-#{uid}@example.com"
      addr2 = "all-fail-2-#{uid}@example.com"

      for addr <- [addr1, addr2] do
        {:ok, _} =
          Mailglass.Suppression.Entry.changeset(%{
            tenant_id: "test-tenant",
            address: addr,
            scope: :address,
            reason: :manual,
            source: "test"
          })
          |> TestRepo.insert()
      end

      msgs = [build_message(addr1), build_message(addr2)]

      try do
        Outbound.deliver_many!(msgs, [])
      rescue
        err in Mailglass.Error.BatchFailed ->
          assert err.type == :all_failed
          assert length(err.failures) == 2
      end
    end
  end

  describe "deliver_many/2 — DB persistence (Test 10)" do
    test "Delivery rows are persisted in the database" do
      uid = unique_id()
      msgs = [
        build_message("persist1-#{uid}@example.com"),
        build_message("persist2-#{uid}@example.com")
      ]

      {:ok, deliveries} = Outbound.deliver_many(msgs, [])

      for d <- deliveries do
        reloaded = TestRepo.get!(Delivery, d.id)
        assert reloaded.id == d.id
        # Status is :queued right after batch insert (jobs enqueued asynchronously)
        assert reloaded.status == :queued
      end
    end
  end

  defp unique_id, do: System.unique_integer([:positive])

  defp build_message(to_addr) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Test", "from@example.com"})
      |> Swoosh.Email.to(to_addr)
      |> Swoosh.Email.subject("Test batch")
      |> Swoosh.Email.html_body("<p>Test body</p>")
      |> Swoosh.Email.text_body("Test body")

    Message.new(email,
      mailable: Mailglass.FakeFixtures.TestMailer,
      tenant_id: "test-tenant",
      stream: :transactional
    )
  end
end
