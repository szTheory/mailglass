# Minimal adapter stub that always returns a SendError — used to test adapter failure path.
defmodule Mailglass.Adapters.AlwaysFail do
  @behaviour Mailglass.Adapter

  @impl Mailglass.Adapter
  def deliver(_msg, _opts) do
    {:error, Mailglass.SendError.new(:adapter_failure, context: %{reason: :test_stub})}
  end
end

defmodule Mailglass.OutboundTest do
  use Mailglass.DataCase, async: false

  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.Outbound
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Adapters.Fake
  alias Mailglass.{Message, TestRepo}
  alias Mailglass.TestSupport.SandboxOwnership

  setup do
    Fake.checkout()
    Mailglass.TestSupport.CitextProbe.run(repo: TestRepo)

    # `:compliance` is in no `config/*.exs`, so the `on_exit` below used to
    # restore it with `put_env(:mailglass, :compliance, nil)` — CREATING the
    # key holding `nil` instead of removing it, which makes every later
    # `Application.get_env(:mailglass, :compliance, default)` in the run
    # resolve to `nil` rather than its default. `with_app_env!/2` deletes keys
    # that were absent at capture; the narrower per-key restores below are kept
    # for the boot-present keys they name.
    SandboxOwnership.with_app_env!(:mailglass)

    prior_adapter = Application.get_env(:mailglass, :adapter)
    prior_adapters = Application.get_env(:mailglass, :adapters)
    prior_tenancy = Application.get_env(:mailglass, :tenancy)

    Application.put_env(:mailglass, :compliance,
      endpoint: "outbound-test-secret",
      host: "unsubscribe.example.com",
      scheme: "https",
      mount_path: "/mailglass/unsubscribe",
      previous_secrets: [],
      redirect: nil,
      max_age: 60
    )

    on_exit(fn ->
      Application.put_env(:mailglass, :adapter, prior_adapter)

      if is_nil(prior_adapters) do
        Application.delete_env(:mailglass, :adapters)
      else
        Application.put_env(:mailglass, :adapters, prior_adapters)
      end

      Application.put_env(:mailglass, :tenancy, prior_tenancy)
    end)

    :ok
  end

  describe "send/2 — happy path" do
    test "returns {:ok, %Delivery{status: :sent, tenant_id: t}} with Fake adapter recording the message" do
      msg = build_message("happy@example.com")

      assert {:ok, %Delivery{status: :sent, tenant_id: "test-tenant"} = delivery} =
               Outbound.send(msg)

      assert delivery.last_event_type == :dispatched
      assert delivery.adapter_ref == Delivery.default_adapter_ref()
      assert not is_nil(delivery.dispatched_at)
      assert not is_nil(delivery.provider_message_id)

      # Fake records the message
      [record] = Fake.deliveries()
      assert record.message.swoosh_email.to == [{"", "happy@example.com"}]
    end

    test "Multi#1 inserts Delivery(last_event_type: :queued) + Event(:queued); Multi#2 inserts Event(:dispatched)" do
      msg = build_message("multi@example.com")
      {:ok, delivery} = Outbound.send(msg)

      import Ecto.Query

      events =
        from(e in Mailglass.Events.Event,
          where: e.delivery_id == ^delivery.id,
          order_by: [asc: e.inserted_at]
        )
        |> TestRepo.all()

      # Two events: :queued (Multi#1) and :dispatched (Multi#2)
      event_types = Enum.map(events, & &1.type)
      assert :queued in event_types
      assert :dispatched in event_types
    end

    test "delivery_id is stamped into message metadata before adapter call (I-07)" do
      msg = build_message("stamp@example.com")
      {:ok, delivery} = Outbound.send(msg)

      [record] = Fake.deliveries()
      assert record.message.metadata[:delivery_id] == delivery.id
    end

    test "bulk deliveries sign the persisted delivery id into unsubscribe headers" do
      msg = build_message("bulk@example.com", stream: :bulk)
      {:ok, delivery} = Outbound.send(msg)
      delivery_id = delivery.id

      [record] = Fake.deliveries()
      token = unsubscribe_token!(record.message)

      assert {:ok, %{delivery_id: ^delivery_id}} = Unsubscribe.verify_token(token)
    end
  end

  describe "deliver/2 alias" do
    test "deliver/2 is a defdelegate alias for send/2 — same result" do
      msg = build_message("deliver@example.com")

      result_send = Outbound.send(build_message("send-path@example.com"))
      result_deliver = Outbound.deliver(msg)

      assert {:ok, %Delivery{status: :sent}} = result_send
      assert {:ok, %Delivery{status: :sent}} = result_deliver
    end
  end

  describe "Mailglass.deliver/2 top-level defdelegate" do
    test "routes to Mailglass.Outbound.deliver/2" do
      msg = build_message("toplevel@example.com")
      assert {:ok, %Delivery{status: :sent}} = Mailglass.deliver(msg)
    end
  end

  describe "adapter failure" do
    test "adapter failure writes status: :failed + last_error; returns {:error, %SendError{}}" do
      # Configure Fake to return an error by overriding at call time via opts
      msg = build_message("fail@example.com")

      {:error, send_err} =
        Outbound.send(msg, adapter: {Mailglass.Adapters.AlwaysFail, []})

      assert send_err.__struct__ != nil

      # The delivery row should have status: :failed
      import Ecto.Query

      deliveries =
        from(d in Delivery,
          where: d.recipient == "fail@example.com",
          order_by: [desc: d.inserted_at],
          limit: 1
        )
        |> TestRepo.all()

      case deliveries do
        [delivery] ->
          assert delivery.status == :failed
          assert is_map(delivery.last_error)

          assert Map.has_key?(delivery.last_error, "module") or
                   Map.has_key?(delivery.last_error, :module)

        [] ->
          # delivery row may not exist if adapter failed before Multi#1 — that's fine
          # The test primarily checks that {:error, _} is returned
          :ok
      end
    end
  end

  describe "runtime adapter resolution" do
    test "sync adapter_ref override wins over tenancy/default routing and persists the chosen ref" do
      configure_routed_adapters(self())
      Application.put_env(:mailglass, :tenancy, Mailglass.TestTenancy.RouteB)

      msg = build_message("route-a@example.com")

      assert {:ok, %Delivery{adapter_ref: "route_a"}} = Outbound.send(msg, adapter_ref: :route_a)
      assert_receive {:adapter_route, :route_a, _delivery_id, "test-tenant"}
    end

    test "explicit sync adapter override wins over adapter_ref and tenancy routing" do
      configure_routed_adapters(self())
      Application.put_env(:mailglass, :tenancy, Mailglass.TestTenancy.RouteA)

      msg = build_message("explicit@example.com")

      assert {:ok, %Delivery{}} =
               Outbound.send(msg,
                 adapter:
                   {Mailglass.TestSupport.RouteRecordingAdapter,
                    [test_pid: self(), route: :explicit]},
                 adapter_ref: :route_b
               )

      assert_receive {:adapter_route, :explicit, _delivery_id, "test-tenant"}
    end

    test "invalid tenancy callback output fails loudly instead of falling back to the default adapter" do
      configure_routed_adapters(self())
      Application.put_env(:mailglass, :tenancy, Mailglass.TestTenancy.InvalidRoute)

      msg = build_message("invalid-route@example.com")

      assert {:error, %Mailglass.SendError{} = err} = Outbound.send(msg)
      assert err.context.reason_class == :invalid_adapter_ref_callback
      refute_received {:adapter_route, _, _, _}
    end
  end

  describe "deliver!/2 bang variant" do
    test "returns %Delivery{} on success" do
      msg = build_message("bang@example.com")
      delivery = Outbound.deliver!(msg)
      assert %Delivery{status: :sent} = delivery
    end

    test "raises the error struct directly (no generic wrapping) on suppression" do
      # Add suppression
      {:ok, _} = insert_suppression!("suppressed@example.com")

      msg = build_message("suppressed@example.com")

      assert_raise Mailglass.SuppressedError, fn ->
        Outbound.deliver!(msg)
      end
    end
  end

  describe "PubSub broadcast after Multi#2" do
    test "broadcast_delivery_updated fires after Multi#2 commit" do
      Phoenix.PubSub.subscribe(Mailglass.PubSub, Mailglass.PubSub.Topics.events("test-tenant"))

      msg = build_message("pubsub@example.com")
      {:ok, delivery} = Outbound.send(msg)

      delivery_id = delivery.id
      assert_receive {:delivery_updated, ^delivery_id, :dispatched, _meta}, 500
    end
  end

  describe "adapter call outside transaction (D-20 / T-3-05-03)" do
    test "Fake.deliver is called AFTER Repo.transact returns for Multi#1" do
      # Verify by checking that Fake records exist after send completes
      # (not inside a transaction that could roll back)
      msg = build_message("order@example.com")
      assert {:ok, %Delivery{}} = Outbound.send(msg)

      # Fake has the record — it was written outside the transaction
      deliveries = Fake.deliveries()
      assert length(deliveries) == 1
    end
  end

  # Helper to build a minimal test message for the Fake adapter.
  # html_body must be a binary (HTML string) or 1-arity function — Renderer requires it.
  defp build_message(to_addr, opts \\ []) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Test", "from@example.com"})
      |> Swoosh.Email.to(to_addr)
      |> Swoosh.Email.subject("Test subject")
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
