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
    # No raw Sandbox mode call switching to shared self-owned mode here: this
    # module `use`s Mailglass.DataCase with async disabled, so DataCase's own setup
    # (ExUnit.CaseTemplate composes the module's setup after the template's)
    # already ran checkout!(shared: true) and put the pool in shared mode with
    # a live agent owner — a call here would return :already_shared
    # (manager.ex:148-159) and change nothing. Task.Supervisor background
    # tasks reach the DB because the pool is genuinely shared already.
    Mailglass.TestSupport.CitextProbe.run(repo: TestRepo)
    prior_adapter = Application.get_env(:mailglass, :adapter)
    prior_adapters = Application.get_env(:mailglass, :adapters)
    prior_tenancy = Application.get_env(:mailglass, :tenancy)

    on_exit(fn ->
      Process.sleep(50)
      Application.put_env(:mailglass, :async_adapter, :oban)
      Application.put_env(:mailglass, :adapter, prior_adapter)

      if is_nil(prior_adapters) do
        Application.delete_env(:mailglass, :adapters)
      else
        Application.put_env(:mailglass, :adapters, prior_adapters)
      end

      Application.put_env(:mailglass, :tenancy, prior_tenancy)

      # Healing call, not a leak site: reverts the shared mode DataCase's own
      # checkout put the pool in. Its reverse on_exit placement runs before
      # DataCase's own release, so it cannot strand the owner. Migrated to
      # the sanctioned door per plan 143-08's Mailglass.Credo.NoRawSandboxOwnership
      # (see Mailglass.TestSupport.SandboxOwnership.mode_manual!/1's moduledoc
      # for why this exact caller shape is one of its two legitimate uses).
      Mailglass.TestSupport.SandboxOwnership.mode_manual!(TestRepo, caller: __MODULE__)
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

    test "renders a blank HTML function once and dispatches its explicit plaintext" do
      address = "blank-html-batch-#{unique_id()}@example.com"

      message =
        build_message(address)
        |> put_in([Access.key(:swoosh_email), Access.key(:html_body)], fn _assigns -> "" end)
        |> put_in([Access.key(:swoosh_email), Access.key(:text_body)], "explicit plaintext")

      assert {:ok, [%Delivery{recipient: ^address}]} = Outbound.deliver_many([message], [])

      assert %Message{swoosh_email: %{html_body: nil, text_body: "explicit plaintext"}} =
               Mailglass.TestAssertions.wait_for_mail(500)
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

      {:ok, _} = insert_suppression!(blocked_addr)

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

      {:ok, _} = insert_suppression!(blocked_addr)

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
        {:ok, _} = insert_suppression!(addr)
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
        assert reloaded.adapter_ref == Delivery.default_adapter_ref()
        # The background task may complete before or after this assertion;
        # accept :queued (still pending) or :sent (dispatch completed).
        assert reloaded.status in [:queued, :sent]
      end
    end
  end

  describe "deliver_many/2 — tenant-aware routing" do
    test "persists adapter refs per message before queue handoff" do
      configure_routed_adapters(self())
      Application.put_env(:mailglass, :tenancy, Mailglass.TestTenancy.RouteA)

      uid = unique_id()

      msgs = [
        build_message("route-batch-1-#{uid}@example.com"),
        build_message("route-batch-2-#{uid}@example.com")
      ]

      {:ok, deliveries} = Outbound.deliver_many(msgs, [])

      assert Enum.all?(deliveries, &(&1.adapter_ref == "route_a"))
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

    Message.build(email,
      mailable: Mailglass.FakeFixtures.TestMailer,
      tenant_id: "test-tenant",
      stream: :transactional
    )
  end

  defp configure_routed_adapters(test_pid) do
    Application.put_env(
      :mailglass,
      :adapter,
      {Mailglass.TestSupport.RouteRecordingAdapter, [test_pid: test_pid, route: :default]}
    )

    Application.put_env(:mailglass, :adapters,
      route_a: {Mailglass.TestSupport.RouteRecordingAdapter, [test_pid: test_pid, route: :route_a]}
    )
  end

  defp insert_suppression!(address) do
    attrs = %{
      tenant_id: "test-tenant",
      address: address,
      scope: :address,
      reason: :manual,
      source: "test"
    }

    insert_suppression!(attrs, 4)
  end

  defp insert_suppression!(attrs, attempts_left) when attempts_left > 0 do
    try do
      attrs
      |> Mailglass.Suppression.Entry.changeset()
      |> TestRepo.insert()
    rescue
      Postgrex.Error ->
        Mailglass.TestSupport.CitextProbe.run(repo: TestRepo)

        if attempts_left > 1 do
          insert_suppression!(attrs, attempts_left - 1)
        else
          attrs
          |> Mailglass.Suppression.Entry.changeset()
          |> TestRepo.insert()
        end
    end
  end
end
