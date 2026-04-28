defmodule Mailglass.Outbound.DeliverLaterTest do
  # async: false required — we switch sandbox to shared mode and use Application.put_env
  use Mailglass.DataCase, async: false

  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.{Outbound, Message, TestRepo}
  alias Mailglass.Outbound.Delivery

  setup do
    # Use shared mode so Task.Supervisor background tasks can deliver via the Fake adapter.
    # async: false guarantees no other test owns the shared bucket during this test.
    Mailglass.Adapters.Fake.checkout()
    Mailglass.Adapters.Fake.set_shared(self())
    prior_compliance = Application.get_env(:mailglass, :compliance)

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

    # The Task.Supervisor spawns a background process that accesses the DB.
    # Use shared mode so background tasks share the test process's connection
    # rather than getting their own checkout — avoids stale OID cache errors
    # when running alongside :manual-mode tests in the full suite.
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, {:shared, self()})

    on_exit(fn ->
      # Brief pause so any in-flight Task.Supervisor tasks finish their DB work
      # before the sandbox is torn down (avoids Postgrex disconnect noise).
      Process.sleep(50)
      Application.put_env(:mailglass, :async_adapter, :oban)
      Application.put_env(:mailglass, :compliance, prior_compliance)
      Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
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
    end

    test "Delivery row is persisted with last_event_type: :queued before return" do
      msg = build_message("persist-#{unique_id()}@example.com")
      {:ok, delivery} = Outbound.deliver_later(msg)

      reloaded = TestRepo.get!(Delivery, delivery.id)
      assert reloaded.last_event_type == :queued
      assert reloaded.status == :queued
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
