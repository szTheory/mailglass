defmodule Mailglass.Outbound.WorkerTest do
  use Mailglass.DataCase, async: false

  import Ecto.Query

  # Only run these tests when Oban is available
  @moduletag :oban

  alias Mailglass.Outbound
  alias Mailglass.Outbound.{Delivery, Envelope, Payload}
  alias Mailglass.Message
  alias Mailglass.TestRepo
  alias Mailglass.Generators

  setup do
    if Code.ensure_loaded?(Oban.Testing) do
      # Use Oban testing in manual mode so jobs don't execute immediately
      Oban.Testing.with_testing_mode(:manual, fn -> :ok end)
    end

    Mailglass.Adapters.Fake.checkout()
    prior_adapter = Application.get_env(:mailglass, :adapter)
    prior_adapters = Application.get_env(:mailglass, :adapters)
    prior_tenancy = Application.get_env(:mailglass, :tenancy)
    prior_async_adapter = Application.get_env(:mailglass, :async_adapter)
    prior_route_control = Application.get_env(:mailglass, :phase_150_worker_route_control)

    on_exit(fn ->
      Application.put_env(:mailglass, :adapter, prior_adapter)

      if is_nil(prior_adapters) do
        Application.delete_env(:mailglass, :adapters)
      else
        Application.put_env(:mailglass, :adapters, prior_adapters)
      end

      Application.put_env(:mailglass, :tenancy, prior_tenancy)
      Application.put_env(:mailglass, :async_adapter, prior_async_adapter)

      if is_nil(prior_route_control) do
        Application.delete_env(:mailglass, :phase_150_worker_route_control)
      else
        Application.put_env(:mailglass, :phase_150_worker_route_control, prior_route_control)
      end
    end)

    :ok
  end

  describe "Worker module structure" do
    @tag phase_150_task: "t150_03_01"
    test "Worker exposes the canonical queue identity" do
      if Code.ensure_loaded?(Mailglass.Outbound.Worker) do
        assert Mailglass.Outbound.Worker.queue() == :mailglass_outbound
      end
    end

    test "Worker module exists when Oban is available" do
      if Code.ensure_loaded?(Oban.Worker) do
        assert Code.ensure_loaded?(Mailglass.Outbound.Worker)
      else
        :skip
      end
    end

    test "Worker uses queue: :mailglass_outbound" do
      if Code.ensure_loaded?(Mailglass.Outbound.Worker) do
        opts = Mailglass.Outbound.Worker.__opts__()
        assert Keyword.get(opts, :queue) == :mailglass_outbound
      end
    end

    test "Worker uses max_attempts: 20" do
      if Code.ensure_loaded?(Mailglass.Outbound.Worker) do
        opts = Mailglass.Outbound.Worker.__opts__()
        assert Keyword.get(opts, :max_attempts) == 20
      end
    end

    test "Worker unique config includes keys: [:delivery_id]" do
      if Code.ensure_loaded?(Mailglass.Outbound.Worker) do
        opts = Mailglass.Outbound.Worker.__opts__()
        unique = Keyword.get(opts, :unique, [])
        assert Keyword.get(unique, :keys) == [:delivery_id]
      end
    end
  end

  describe "Oban readiness" do
    @tag phase_150_task: "t150_03_02"
    test "missing configured Oban instance fails with a bounded reason" do
      assert {:error, :instance_unavailable} =
               Mailglass.OptionalDeps.Oban.ready?(Mailglass.Outbound.Worker.queue())
    end
  end

  describe "Worker.perform/1" do
    @tag phase_150_task: "t150_10_01"
    test "persists finite float metadata and provider options without losing payload integrity" do
      delivery = Generators.delivery_fixture(tenant_id: "test-tenant")

      metadata = %{
        "exponent" => 1.0e20,
        "trailing_zero" => 1.2300,
        "reserved_string" => "~mailglass:json-v1:float:not-a-marker"
      }

      provider_options = %{
        "exponent" => 6.02e23,
        "trailing_zero" => 42.500,
        "nested" => [0.0, -0.0]
      }

      email =
        Swoosh.Email.new()
        |> Swoosh.Email.from({"Payload", "from@example.com"})
        |> Swoosh.Email.to("payload-#{System.unique_integer([:positive])}@example.com")
        |> Swoosh.Email.subject("float persistence")
        |> then(&%{&1 | provider_options: provider_options})

      assert {:ok, envelope} =
               Envelope.dump(
                 Message.build(email,
                   tenant_id: "test-tenant",
                   stream: :transactional,
                   metadata: metadata
                 ),
                 adapter_ref: Delivery.default_adapter_ref()
               )

      assert {:ok, payload} =
               Payload.from_envelope("test-tenant", delivery.id, envelope) |> TestRepo.insert()

      assert {:ok, %Envelope.Decoded{message: restored}} =
               Payload.fetch_for_delivery("test-tenant", delivery.id)

      assert restored.metadata == metadata
      assert restored.swoosh_email.provider_options == provider_options

      TestRepo.update!(
        Ecto.Changeset.change(payload, envelope: Map.put(payload.envelope, "subject", "tampered"))
      )

      assert {:error, :integrity_failed} = Payload.fetch_for_delivery("test-tenant", delivery.id)
    end

    @tag phase_150_task: "t150_08_01"
    test "retries the real queued job with immutable rendered content and its persisted route" do
      if not Code.ensure_loaded?(Mailglass.Outbound.Worker) do
        :skip
      else
        control =
          start_supervised!(
            {Agent, fn -> %{body: "original", route: :route_a, renders: 0, routes: 0} end}
          )

        Application.put_env(:mailglass, :phase_150_worker_route_control, control)
        Application.put_env(:mailglass, :async_adapter, :oban)

        Application.put_env(
          :mailglass,
          :tenancy,
          Mailglass.Outbound.WorkerTest.StatefulRouteTenancy
        )

        Application.put_env(
          :mailglass,
          :adapter,
          {Mailglass.Outbound.WorkerTest.StatefulRouteAdapter, [test_pid: self(), route: :default]}
        )

        Application.put_env(:mailglass, :adapters,
          route_a:
            {Mailglass.Outbound.WorkerTest.StatefulRouteAdapter,
             [test_pid: self(), route: :route_a]},
          route_b:
            {Mailglass.Outbound.WorkerTest.StatefulRouteAdapter,
             [test_pid: self(), route: :route_b]}
        )

        start_supervised!(
          {Oban, testing: :disabled, repo: TestRepo, queues: [mailglass_outbound: 10]}
        )

        subject = "queued original subject #{System.unique_integer([:positive])}"
        attachment_marker = "attachment-original-#{System.unique_integer([:positive])}"

        attachment =
          Swoosh.Attachment.new({:data, attachment_marker},
            filename: "immutable-marker.txt",
            content_type: "text/plain"
          )

        message =
          Swoosh.Email.new()
          |> Swoosh.Email.from({"Worker", "from@example.com"})
          |> Swoosh.Email.to("worker-#{System.unique_integer([:positive])}@example.com")
          |> Swoosh.Email.subject(subject)
          |> Swoosh.Email.html_body(fn _assigns ->
            Agent.get_and_update(control, fn state ->
              {"<p>rendered #{state.body}</p>", %{state | renders: state.renders + 1}}
            end)
          end)
          |> Swoosh.Email.text_body("original text")
          |> then(&%{&1 | attachments: [attachment]})
          |> Message.build(tenant_id: "test-tenant", stream: :transactional)

        assert {:ok, %Delivery{status: :queued} = delivery} = Outbound.deliver_later(message)

        assert %Oban.Job{} =
                 job =
                 TestRepo.one!(
                   from(j in Oban.Job,
                     where:
                       j.queue == "mailglass_outbound" and j.args["delivery_id"] == ^delivery.id
                   )
                 )

        assert job.args == %{"delivery_id" => delivery.id, "mailglass_tenant_id" => "test-tenant"}
        assert %{renders: 1, routes: 1} = Agent.get(control, & &1)

        Agent.update(control, &%{&1 | body: "changed", route: :route_b})

        assert :ok = Mailglass.Outbound.Worker.perform(job)

        delivery_id = delivery.id
        assert_receive {:stateful_adapter_delivery, :route_a, ^delivery_id, sent}
        assert sent.swoosh_email.subject == subject
        assert sent.swoosh_email.html_body == "&lt;p&gt;rendered original&lt;/p&gt;"

        assert [%Swoosh.Attachment{data: ^attachment_marker, filename: "immutable-marker.txt"}] =
                 sent.swoosh_email.attachments

        refute_receive {:stateful_adapter_delivery, :route_b, _, _}
        assert %{renders: 1, routes: 1} = Agent.get(control, & &1)
      end
    end

    @tag phase_150_task: "t150_08_01"
    test "fails closed before adapter delivery when the public route projection disagrees with the envelope" do
      if not Code.ensure_loaded?(Mailglass.Outbound.Worker) do
        :skip
      else
        Application.put_env(:mailglass, :async_adapter, :oban)
        Application.put_env(:mailglass, :tenancy, Mailglass.TestTenancy.RouteA)

        Application.put_env(:mailglass, :adapters,
          route_a:
            {Mailglass.Outbound.WorkerTest.StatefulRouteAdapter,
             [test_pid: self(), route: :route_a]},
          route_b:
            {Mailglass.Outbound.WorkerTest.StatefulRouteAdapter,
             [test_pid: self(), route: :route_b]}
        )

        start_supervised!(
          {Oban, testing: :disabled, repo: TestRepo, queues: [mailglass_outbound: 10]}
        )

        assert {:ok, delivery} =
                 Outbound.deliver_later(
                   Swoosh.Email.new()
                   |> Swoosh.Email.from({"Worker", "from@example.com"})
                   |> Swoosh.Email.to("mismatch-#{System.unique_integer([:positive])}@example.com")
                   |> Swoosh.Email.subject("projection mismatch")
                   |> Swoosh.Email.text_body("stored private payload")
                   |> Message.build(tenant_id: "test-tenant", stream: :transactional)
                 )

        job =
          TestRepo.one!(
            from(j in Oban.Job,
              where: j.queue == "mailglass_outbound" and j.args["delivery_id"] == ^delivery.id
            )
          )

        TestRepo.update!(Ecto.Changeset.change(delivery, adapter_ref: "route_b"))

        assert {:error,
                %Mailglass.SendError{
                  type: :serialization_failed,
                  context: %{reason_class: :persisted_adapter_mismatch}
                }} = Mailglass.Outbound.Worker.perform(job)

        refute_receive {:stateful_adapter_delivery, _, _, _}
      end
    end

    @tag phase_150_task: "t150_03_01"
    test "dispatches immutable payload input before consulting legacy delivery metadata" do
      if not Code.ensure_loaded?(Mailglass.Outbound.Worker) do
        :skip
      else
        delivery =
          Generators.delivery_fixture(
            tenant_id: "test-tenant",
            metadata: %{"subject" => "legacy subject", "rendered_html" => "legacy body"}
          )

        email =
          Swoosh.Email.new()
          |> Swoosh.Email.from({"Payload", "from@example.com"})
          |> Swoosh.Email.to("payload-#{System.unique_integer([:positive])}@example.com")
          |> Swoosh.Email.subject("immutable payload subject")
          |> Swoosh.Email.html_body("<p>immutable payload body</p>")

        {:ok, envelope} =
          Envelope.dump(
            Message.build(email, tenant_id: "test-tenant", stream: :transactional),
            adapter_ref: Delivery.default_adapter_ref()
          )

        {:ok, _payload} =
          Payload.from_envelope("test-tenant", delivery.id, envelope) |> TestRepo.insert()

        assert {:ok, %Delivery{status: :sent}} = Outbound.dispatch_by_id(delivery.id)

        assert [%{message: %{swoosh_email: %{subject: "immutable payload subject"}}}] =
                 Mailglass.Adapters.Fake.deliveries()
      end
    end

    test "perform/1 dispatches delivery and returns :ok on success" do
      if not Code.ensure_loaded?(Mailglass.Outbound.Worker) do
        :skip
      else
        # Create a queued delivery fixture with rendered content in metadata
        delivery =
          Generators.delivery_fixture(
            tenant_id: "test-tenant",
            metadata: %{
              "rendered_html" => "<p>Hello</p>",
              "rendered_text" => "Hello",
              "subject" => "Test",
              "headers" => %{},
              "recipient_field" => "to"
            }
          )

        job = %Oban.Job{
          args: %{"delivery_id" => delivery.id, "mailglass_tenant_id" => "test-tenant"}
        }

        result =
          Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
            Outbound.dispatch_by_id(delivery.id)
          end)

        assert {:ok, %Delivery{}} = result
      end
    end

    test "Worker wraps via TenancyMiddleware — tenant is stamped during perform" do
      if not Code.ensure_loaded?(Mailglass.Outbound.Worker) do
        :skip
      else
        delivery =
          Generators.delivery_fixture(
            tenant_id: "middleware-tenant",
            metadata: %{
              "rendered_html" => "<p>Hello</p>",
              "rendered_text" => "Hello",
              "subject" => "Test",
              "headers" => %{},
              "recipient_field" => "to"
            }
          )

        job = %Oban.Job{
          args: %{"delivery_id" => delivery.id, "mailglass_tenant_id" => "middleware-tenant"}
        }

        captured_tenant = :ets.new(:captured_tenant, [:set, :public])

        Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
          :ets.insert(captured_tenant, {:tenant, Mailglass.Tenancy.current()})
          Outbound.dispatch_by_id(delivery.id)
        end)

        [{:tenant, tenant}] = :ets.lookup(captured_tenant, :tenant)
        assert tenant == "middleware-tenant"
        :ets.delete(captured_tenant)
      end
    end

    test "queued dispatch uses the persisted adapter_ref instead of rerunning tenancy routing" do
      if not Code.ensure_loaded?(Mailglass.Outbound.Worker) do
        :skip
      else
        Application.put_env(
          :mailglass,
          :adapter,
          {Mailglass.TestSupport.RouteRecordingAdapter, [test_pid: self(), route: :default]}
        )

        Application.put_env(:mailglass, :adapters,
          route_a:
            {Mailglass.TestSupport.RouteRecordingAdapter, [test_pid: self(), route: :route_a]},
          route_b:
            {Mailglass.TestSupport.RouteRecordingAdapter, [test_pid: self(), route: :route_b]}
        )

        delivery =
          Generators.delivery_fixture(
            tenant_id: "worker-tenant",
            adapter_ref: "route_a",
            metadata: %{
              "rendered_html" => "<p>Hello</p>",
              "rendered_text" => "Hello",
              "subject" => "Test",
              "headers" => %{},
              "recipient_field" => "to"
            }
          )

        delivery_id = delivery.id

        job = %Oban.Job{
          args: %{"delivery_id" => delivery.id, "mailglass_tenant_id" => "worker-tenant"}
        }

        assert :ok = Mailglass.Outbound.Worker.perform(job)
        assert_receive {:adapter_route, :route_a, ^delivery_id, "worker-tenant"}
      end
    end
  end

  describe "mix compile --no-optional-deps passes" do
    test "Worker module is elided when Oban absent (verified by no-optional-deps build)" do
      # This is verified by the CI lane; here we just confirm the module
      # loads (or doesn't) based on Oban availability
      oban_available = Code.ensure_loaded?(Oban.Worker)
      worker_available = Code.ensure_loaded?(Mailglass.Outbound.Worker)
      assert oban_available == worker_available
    end
  end
end

defmodule Mailglass.Outbound.WorkerTest.StatefulRouteTenancy do
  @moduledoc false
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, _context), do: query

  @impl Mailglass.Tenancy
  def resolve_outbound_adapter_ref(_context) do
    control = Application.fetch_env!(:mailglass, :phase_150_worker_route_control)

    Agent.get_and_update(control, fn state ->
      {{:ok, state.route}, %{state | routes: state.routes + 1}}
    end)
  end
end

defmodule Mailglass.Outbound.WorkerTest.StatefulRouteAdapter do
  @moduledoc false
  @behaviour Mailglass.Adapter

  @impl Mailglass.Adapter
  def deliver(%Mailglass.Message{} = message, opts) do
    route = Keyword.fetch!(opts, :route)
    test_pid = Keyword.fetch!(opts, :test_pid)

    send(test_pid, {:stateful_adapter_delivery, route, message.metadata[:delivery_id], message})

    {:ok, %{message_id: "stateful-#{route}", provider_response: %{adapter: route}}}
  end
end
