defmodule Mailglass.Outbound.DeliverLaterTest do
  # async: false required — we switch sandbox to shared mode and use Application.put_env
  use Mailglass.DataCase, async: false

  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.{Outbound, Message, TestRepo}
  alias Mailglass.Outbound.{Delivery, Payload}

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
    test "async delivery preserves a sole cc or bcc recipient, tenant, and persisted address" do
      for field <- [:cc, :bcc] do
        address = "async-#{field}-#{unique_id()}@example.com"
        message = build_message_with_recipient_field(field, address)

        assert {:ok, %Delivery{tenant_id: "test-tenant", recipient: ^address} = delivery} =
                 Outbound.deliver_later(message)

        assert %Delivery{tenant_id: "test-tenant", recipient: ^address} =
                 TestRepo.get!(Delivery, delivery.id)

        assert_async_fake_delivery("test-tenant")
        %{message: dispatched} = fake_delivery_in_field!(field, address)
        assert Map.fetch!(dispatched.swoosh_email, field) == [{"", address}]
        assert dispatched.swoosh_email.to == []
        Mailglass.Adapters.Fake.checkout()
      end
    end

    test "async delivery sends explicit plaintext when an HTML function renders blank" do
      message =
        build_message("blank-html-later-#{unique_id()}@example.com")
        |> put_in([Access.key(:swoosh_email), Access.key(:html_body)], fn _assigns -> "" end)
        |> put_in([Access.key(:swoosh_email), Access.key(:text_body)], "explicit plaintext")

      assert {:ok, %Delivery{}} = Outbound.deliver_later(message)
      assert_async_fake_delivery("test-tenant")

      assert [%{message: %{swoosh_email: %{html_body: nil, text_body: "explicit plaintext"}}}] =
               Mailglass.Adapters.Fake.deliveries()
    end

    test "async preparation retains renderer plaintext semantics before monitored dispatch" do
      Application.put_env(:mailglass, :renderer, plaintext: false, css_inliner: :none)

      html_address = "renderer-later-html-#{unique_id()}@example.com"

      html_only =
        build_message(html_address)
        |> put_in([Access.key(:swoosh_email), Access.key(:text_body)], nil)

      assert {:ok, %Delivery{}} = Outbound.deliver_later(html_only)
      assert_async_fake_delivery("test-tenant")
      %{message: html_rendered} = fake_delivery_to!(html_address)
      assert is_nil(html_rendered.swoosh_email.text_body)

      Mailglass.Adapters.Fake.checkout()

      explicit_address = "renderer-later-explicit-#{unique_id()}@example.com"

      explicit_text =
        build_message(explicit_address)
        |> put_in([Access.key(:swoosh_email), Access.key(:text_body)], "Async authored Unicode 🚀")

      assert {:ok, %Delivery{}} = Outbound.deliver_later(explicit_text)
      assert_async_fake_delivery("test-tenant")
      %{message: explicit_rendered} = fake_delivery_to!(explicit_address)
      assert explicit_rendered.swoosh_email.text_body == "Async authored Unicode 🚀"
    end

    @tag tenant: :unset
    test "SingleTenant queues an unstamped message as the default tenant" do
      msg = build_message("default-later-#{unique_id()}@example.com", tenant_id: nil)

      assert {:ok, %Delivery{tenant_id: "default"} = delivery} = Outbound.deliver_later(msg)
      assert %Delivery{tenant_id: "default"} = TestRepo.get!(Delivery, delivery.id)
      assert_async_fake_delivery("default")
      assert [%{message: %{tenant_id: "default"}}] = Mailglass.Adapters.Fake.deliveries()
    end

    test "returns {:ok, %Delivery{status: :queued}} — never %Oban.Job{}" do
      msg = build_message("later-#{unique_id()}@example.com")

      result = Outbound.deliver_later(msg)

      assert {:ok, %Delivery{status: :queued, tenant_id: "test-tenant"}} = result
      assert_async_fake_delivery("test-tenant")
    end

    test "returned Delivery has an idempotency_key set" do
      msg = build_message("idem-#{unique_id()}@example.com")
      {:ok, delivery} = Outbound.deliver_later(msg)
      assert is_binary(delivery.idempotency_key)
      assert delivery.adapter_ref == Delivery.default_adapter_ref()
      assert_async_fake_delivery("test-tenant")
    end

    test "Delivery row is persisted with last_event_type: :queued before return" do
      msg = build_message("persist-#{unique_id()}@example.com")
      {:ok, delivery} = Outbound.deliver_later(msg)

      reloaded = TestRepo.get!(Delivery, delivery.id)
      assert reloaded.last_event_type in [:queued, :dispatched]
      assert reloaded.status in [:queued, :sent]
      assert_async_fake_delivery("test-tenant")
    end
  end

  describe "deliver_later/2 — atomic private durable enqueue (Phase 150)" do
    @tag phase_150_task: "t150_02_01"
    test "Oban enqueue persists only public delivery metadata and all four durable facts" do
      if not Code.ensure_loaded?(Oban) do
        :skip
      else
        Application.put_env(:mailglass, :async_adapter, :oban)
        start_supervised!({Oban, testing: :manual, repo: TestRepo, queues: [mailglass_outbound: 10]})

        private_subject = "private subject #{unique_id()}"
        private_body = "private rendered body #{unique_id()}"

        message =
          build_message("atomic-#{unique_id()}@example.com")
          |> put_in([Access.key(:swoosh_email), Access.key(:subject)], private_subject)
          |> put_in([Access.key(:swoosh_email), Access.key(:html_body)], "<p>#{private_body}</p>")
          |> Message.put_metadata(:public_marker, "adopter-visible")

        assert {:ok, %Delivery{status: :queued} = delivery} = Outbound.deliver_later(message)
        assert %Payload{delivery_id: delivery_id, tenant_id: "test-tenant"} =
                 TestRepo.get_by!(Payload, delivery_id: delivery.id)

        assert delivery_id == delivery.id
        assert delivery.metadata == %{public_marker: "adopter-visible"}
        assert %{rows: [[1]]} =
                 TestRepo.query!(
                   "SELECT COUNT(*) FROM oban_jobs WHERE queue = 'mailglass_outbound' AND args->>'delivery_id' = $1",
                   [delivery.id]
                 )
      end
    end
  end

  describe "deliver_later/2 — Task.Supervisor fallback" do
    test "fallback inserts Delivery synchronously and returns {:ok, %Delivery{status: :queued}}" do
      msg = build_message("fallback-#{unique_id()}@example.com")
      result = Outbound.deliver_later(msg)
      assert {:ok, %Delivery{status: :queued}} = result
      assert_async_fake_delivery("test-tenant")
    end

    test "Task.Supervisor fallback re-stamps tenancy via with_tenant — dispatch completes" do
      # Allow the Fake adapter for the spawned task process via shared mode
      Mailglass.Adapters.Fake.set_shared(self())

      msg = build_message("task-tenant-#{unique_id()}@example.com")
      {:ok, delivery} = Outbound.deliver_later(msg)

      assert_async_fake_delivery("test-tenant")

      reloaded = TestRepo.get!(Delivery, delivery.id)
      assert reloaded.status == :sent
    end

    test "bulk async deliveries sign the persisted delivery id into unsubscribe headers" do
      msg = build_message("later-bulk-#{unique_id()}@example.com", stream: :bulk)
      {:ok, delivery} = Outbound.deliver_later(msg)
      delivery_id = delivery.id

      assert_async_fake_delivery("test-tenant")

      [record] = Mailglass.Adapters.Fake.deliveries()
      token = unsubscribe_token!(record.message)

      assert {:ok, %{delivery_id: ^delivery_id}} = Unsubscribe.verify_token(token)
    end

    test "fallback return shape is {:ok, %Delivery{status: :queued}} regardless of Oban availability" do
      msg = build_message("shape-#{unique_id()}@example.com")
      result = Outbound.deliver_later(msg)
      # Must never return an %Oban.Job{} struct
      assert {:ok, %Delivery{status: :queued}} = result
      assert_async_fake_delivery("test-tenant")
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

      assert_receive {:adapter_route, :route_a, ^delivery_id, "test-tenant"}
      await_task_supervisor_children()
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
    test "recipient and body rejection insert no delivery, event, Oban job, task, or Fake delivery" do
      Mailglass.TestSupport.SandboxOwnership.with_app_env!(:mailglass)
      Application.put_env(:mailglass, :async_adapter, :oban)

      deliveries_before = TestRepo.aggregate(Delivery, :count)
      oban_jobs_before = oban_job_count()

      for message <- [
            build_message_with_recipients(["one@example.com", "two@example.com"]),
            build_message_with_bodies(nil, "\u00A0\u2003"),
            build_message_with_bodies(fn _assigns -> "" end, nil)
          ] do
        assert {:error, %Mailglass.SendError{type: :preflight_rejected}} =
                 Outbound.deliver_later(message)
      end

      assert TestRepo.aggregate(Delivery, :count) == deliveries_before
      assert oban_job_count() == oban_jobs_before
      assert DynamicSupervisor.which_children(Mailglass.TaskSupervisor) == []
      assert Mailglass.Adapters.Fake.deliveries() == []
    end

    test "valid HTML does not mask unsupported explicit plaintext before async effects" do
      Mailglass.TestSupport.SandboxOwnership.with_app_env!(:mailglass)
      Application.put_env(:mailglass, :async_adapter, :oban)

      deliveries_before = TestRepo.aggregate(Delivery, :count)
      oban_jobs_before = oban_job_count()

      for text <- [:not_text, <<255>>] do
        assert {:error,
                %Mailglass.SendError{
                  type: :preflight_rejected,
                  context: %{reason_class: :body_invalid, body_state: :unsupported}
                }} = Outbound.deliver_later(build_message_with_bodies("<p>valid HTML</p>", text))
      end

      assert TestRepo.aggregate(Delivery, :count) == deliveries_before
      assert oban_job_count() == oban_jobs_before
      assert DynamicSupervisor.which_children(Mailglass.TaskSupervisor) == []
      assert Mailglass.Adapters.Fake.deliveries() == []
    end

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
      tenant_id: Keyword.get(opts, :tenant_id, "test-tenant"),
      stream: Keyword.get(opts, :stream, :transactional)
    )
  end

  defp build_message_with_recipients(recipients) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Test", "from@example.com"})
      |> Swoosh.Email.to(recipients)
      |> Swoosh.Email.subject("Rejected later")
      |> Swoosh.Email.text_body("Body")

    Message.build(email,
      mailable: Mailglass.FakeFixtures.TestMailer,
      tenant_id: "test-tenant",
      stream: :transactional
    )
  end

  defp build_message_with_recipient_field(field, address) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Test", "from@example.com"})
      |> Swoosh.Email.subject("Recipient field")
      |> Swoosh.Email.text_body("Body")
      |> Map.merge(%{to: [], cc: [], bcc: []})
      |> Map.put(field, [{"", address}])

    Message.build(email,
      mailable: Mailglass.FakeFixtures.TestMailer,
      tenant_id: "test-tenant",
      stream: :transactional
    )
  end

  defp build_message_with_bodies(html, text) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Test", "from@example.com"})
      |> Swoosh.Email.to("one@example.com")
      |> Swoosh.Email.subject("Rejected later")
      |> Map.put(:html_body, html)
      |> Map.put(:text_body, text)

    Message.build(email,
      mailable: Mailglass.FakeFixtures.TestMailer,
      tenant_id: "test-tenant",
      stream: :transactional
    )
  end

  defp oban_job_count do
    %{rows: [[count]]} = TestRepo.query!("SELECT COUNT(*) FROM oban_jobs")
    count
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

  defp assert_async_fake_delivery(tenant_id) do
    assert %Message{tenant_id: ^tenant_id} = Mailglass.TestAssertions.wait_for_mail(500)
    await_task_supervisor_children()
  end

  defp fake_delivery_to!(address) do
    Enum.find(Mailglass.Adapters.Fake.deliveries(), fn %{message: message} ->
      Enum.any?(message.swoosh_email.to, fn {_name, recipient} -> recipient == address end)
    end) || flunk("no Fake delivery found for #{address}")
  end

  defp fake_delivery_in_field!(field, address) do
    Enum.find(Mailglass.Adapters.Fake.deliveries(), fn %{message: message} ->
      Enum.any?(Map.fetch!(message.swoosh_email, field), fn {_name, recipient} ->
        recipient == address
      end)
    end) || flunk("no Fake delivery found for #{address} in #{field}")
  end

  defp await_task_supervisor_children do
    Mailglass.TaskSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.each(fn {_id, pid, _type, _modules} -> await_task_exit(pid) end)
  end

  defp await_task_exit(pid) do
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, ^pid, reason} when reason in [:normal, :noproc] ->
        :ok

      {:DOWN, ^ref, :process, ^pid, reason} ->
        flunk("Task.Supervisor child exited: #{inspect(reason)}")
    after
      500 -> flunk("Task.Supervisor child did not finish dispatch within 500ms")
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
