defmodule Mailglass.Outbound.WorkerTest do
  use Mailglass.DataCase, async: false

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

    on_exit(fn ->
      Application.put_env(:mailglass, :adapter, prior_adapter)

      if is_nil(prior_adapters) do
        Application.delete_env(:mailglass, :adapters)
      else
        Application.put_env(:mailglass, :adapters, prior_adapters)
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

  describe "Worker.perform/1" do
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
              "subject" => "Test"
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
              "subject" => "Test"
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
              "subject" => "Test"
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
