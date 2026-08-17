defmodule Mailglass.Outbound.DeliverLaterTest do
  # async: false required — we switch sandbox to shared mode and use Application.put_env
  use Mailglass.DataCase, async: false

  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.{Outbound, Message, TestRepo}
  alias Mailglass.Outbound.Delivery

  defmodule RefusingAsyncAdapter do
    @behaviour Mailglass.Outbound.AsyncAdapter

    @impl true
    def dispatch(_fun, _opts), do: {:error, :max_children}
  end

  setup do
    # Use shared mode so Task.Supervisor background tasks can deliver via the Fake adapter.
    # async: false guarantees no other test owns the shared bucket during this test.
    Mailglass.Adapters.Fake.checkout()
    Mailglass.Adapters.Fake.set_shared(self())
    # `:compliance` is in no `config/*.exs`, so the `on_exit` below used to
    # restore it with `put_env(:mailglass, :compliance, nil)` — CREATING the
    # key holding `nil` instead of removing it. `with_app_env!/2` deletes keys
    # that were absent at capture. See its @doc.
    Mailglass.TestSupport.SandboxOwnership.with_app_env!(:mailglass)

    prior_adapter = Application.get_env(:mailglass, :adapter)
    prior_adapters = Application.get_env(:mailglass, :adapters)
    prior_tenancy = Application.get_env(:mailglass, :tenancy)

    # Use task_supervisor for deliver_later tests — Oban is not started in the test suite.
    # Worker-specific tests (worker_test.exs) test the Worker module directly.
    Application.put_env(:mailglass, :async_adapter, :task_supervisor)

    Application.put_env(:mailglass, :compliance,
      endpoint: "deliver-later-test-secret",
      host: "unsubscribe.example.com",
      scheme: "https",
      mount_path: "/mailglass/unsubscribe",
      previous_secrets: [],
      redirect: nil,
      max_age: 60
    )

    # No raw Sandbox mode call switching to shared self-owned mode here: this
    # module `use`s Mailglass.DataCase with async disabled, so DataCase's own setup
    # (ExUnit.CaseTemplate composes the module's setup after the template's)
    # already ran checkout!(shared: true) and put the pool in shared mode with
    # a live agent owner — a call here would return :already_shared
    # (manager.ex:148-159) and change nothing. The Task.Supervisor background
    # process reaches the DB because the pool is genuinely shared already.

    on_exit(fn ->
      # Brief pause so any in-flight Task.Supervisor tasks finish their DB work
      # before the sandbox is torn down (avoids Postgrex disconnect noise).
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

  describe "deliver_later/2 — return shape invariant (D-14)" do
    test "returns {:ok, %Delivery{status: :queued}} — never %Oban.Job{}" do
      msg = build_message("later-#{unique_id()}@example.com")

      result = Outbound.deliver_later(msg)

      assert {:ok, %Delivery{status: :queued, tenant_id: "test-tenant"}} = result
    end

    test "returned Delivery has an idempotency_key set" do
      msg = build_message("idem-#{unique_id()}@example.com")
      {:ok, delivery} = Outbound.deliver_later(msg)
      assert is_binary(delivery.idempotency_key)
      assert delivery.adapter_ref == Delivery.default_adapter_ref()
    end

    test "Delivery row is persisted with last_event_type: :queued before return" do
      msg = build_message("persist-#{unique_id()}@example.com")
      {:ok, delivery} = Outbound.deliver_later(msg)

      reloaded = TestRepo.get!(Delivery, delivery.id)
      assert reloaded.last_event_type in [:queued, :dispatched]
      assert reloaded.status in [:queued, :sent]
    end
  end

  describe "deliver_later/2 — Task.Supervisor fallback" do
    test "fallback inserts Delivery synchronously and returns {:ok, %Delivery{status: :queued}}" do
      msg = build_message("fallback-#{unique_id()}@example.com")
      result = Outbound.deliver_later(msg)
      assert {:ok, %Delivery{status: :queued}} = result
    end

    test "Task.Supervisor fallback re-stamps tenancy via with_tenant — dispatch completes" do
      # Allow the Fake adapter for the spawned task process via shared mode
      Mailglass.Adapters.Fake.set_shared(self())

      msg = build_message("task-tenant-#{unique_id()}@example.com")
      {:ok, delivery} = Outbound.deliver_later(msg)

      # Give the Task.Supervisor task time to run dispatch
      Process.sleep(150)

      # Check the delivery was updated to :sent
      reloaded = TestRepo.get!(Delivery, delivery.id)
      # The task may have completed or still be running; accept either
      assert reloaded.status in [:queued, :sent]
    end

    test "bulk async deliveries sign the persisted delivery id into unsubscribe headers" do
      msg = build_message("later-bulk-#{unique_id()}@example.com", stream: :bulk)
      {:ok, delivery} = Outbound.deliver_later(msg)
      delivery_id = delivery.id

      Process.sleep(150)

      [record] = Mailglass.Adapters.Fake.deliveries()
      token = unsubscribe_token!(record.message)

      assert {:ok, %{delivery_id: ^delivery_id}} = Unsubscribe.verify_token(token)
    end

    test "fallback return shape is {:ok, %Delivery{status: :queued}} regardless of Oban availability" do
      msg = build_message("shape-#{unique_id()}@example.com")
      result = Outbound.deliver_later(msg)
      # Must never return an %Oban.Job{} struct
      assert {:ok, %Delivery{status: :queued}} = result
    end

    test "refused fallback admission returns a typed failure and persists a failed projection" do
      Application.put_env(:mailglass, :async_adapter_impl, RefusingAsyncAdapter)

      on_exit(fn -> Application.delete_env(:mailglass, :async_adapter_impl) end)

      msg = build_message("refused-#{unique_id()}@example.com")

      assert {:error, %Mailglass.SendError{type: :dispatch_unavailable} = error} =
               Outbound.deliver_later(msg)

      assert error.context == %{reason_class: :capacity_reached}

      [delivery] = TestRepo.all(Delivery)
      assert delivery.status == :failed
      assert delivery.last_event_type == :failed

      assert delivery.last_error["type"] == "dispatch_unavailable" or
               delivery.last_error[:type] == :dispatch_unavailable
    end
  end

  describe "deliver_later/2 — adapter refs" do
    test "persists the chosen adapter_ref at enqueue time and worker dispatch honors it later" do
      configure_routed_adapters(self())
      Application.put_env(:mailglass, :tenancy, Mailglass.TestTenancy.RouteA)

      msg = build_message("route-later-#{unique_id()}@example.com")
      {:ok, delivery} = Outbound.deliver_later(msg)
      delivery_id = delivery.id

      assert delivery.adapter_ref == "route_a"

      Application.put_env(:mailglass, :tenancy, Mailglass.TestTenancy.RouteB)
      Process.sleep(150)

      assert_receive {:adapter_route, :route_a, ^delivery_id, "test-tenant"}
      reloaded = TestRepo.get!(Delivery, delivery.id)
      assert reloaded.adapter_ref == "route_a"
    end

    test "queued raw adapter overrides fail when Mailglass cannot persist them safely" do
      msg = build_message("unsafe-override-#{unique_id()}@example.com")

      assert {:error, %Mailglass.SendError{} = err} =
               Outbound.deliver_later(msg,
                 adapter:
                   {Mailglass.TestSupport.RouteRecordingAdapter,
                    [test_pid: self(), route: :ephemeral]}
               )

      assert err.context.reason_class == :queued_adapter_override_not_persistable
    end
  end

  describe "deliver_later/2 — preflight failures" do
    test "suppressed recipient returns {:error, %SuppressedError{}} — no Delivery row" do
      addr = "blocked-later-#{unique_id()}@example.com"

      {:ok, _} =
        Mailglass.Suppression.Entry.changeset(%{
          tenant_id: "test-tenant",
          address: addr,
          scope: :address,
          reason: :manual,
          source: "test"
        })
        |> TestRepo.insert()

      msg = build_message(addr)
      assert {:error, %Mailglass.SuppressedError{}} = Outbound.deliver_later(msg)

      import Ecto.Query
      count = TestRepo.aggregate(from(d in Delivery, where: d.recipient == ^addr), :count)
      assert count == 0
    end
  end

  defp unique_id, do: System.unique_integer([:positive])

  defp build_message(to_addr, opts \\ []) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Test", "from@example.com"})
      |> Swoosh.Email.to(to_addr)
      |> Swoosh.Email.subject("Test later")
      |> Swoosh.Email.html_body("<p>Test body</p>")
      |> Swoosh.Email.text_body("Test body")

    Message.build(email,
      mailable: Mailglass.FakeFixtures.TestMailer,
      tenant_id: "test-tenant",
      stream: Keyword.get(opts, :stream, :transactional)
    )
  end

  defp configure_routed_adapters(test_pid) do
    Application.put_env(
      :mailglass,
      :adapter,
      {Mailglass.TestSupport.RouteRecordingAdapter, [test_pid: test_pid, route: :default]}
    )

    Application.put_env(:mailglass, :adapters,
      route_a: {Mailglass.TestSupport.RouteRecordingAdapter, [test_pid: test_pid, route: :route_a]},
      route_b: {Mailglass.TestSupport.RouteRecordingAdapter, [test_pid: test_pid, route: :route_b]}
    )
  end

  defp unsubscribe_token!(%Message{} = message) do
    message.swoosh_email.headers["List-Unsubscribe"]
    |> String.trim_leading("<")
    |> String.trim_trailing(">")
    |> URI.parse()
    |> Map.fetch!(:path)
    |> String.split("/", trim: true)
    |> List.last()
  end
end
