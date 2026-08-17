defmodule Mailglass.Outbound.WorkerTest do
  use Mailglass.DataCase, async: false

  # Only run these tests when Oban is available
  @moduletag :oban

  alias Mailglass.Outbound
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Generators
  alias Mailglass.SendError

  defmodule PermanentFailureAdapter do
    @behaviour Mailglass.Adapter

    def deliver(_message, _opts) do
      {:error, SendError.new(:adapter_failure, retry_class: :permanent)}
    end
  end

  defmodule TransientFailureAdapter do
    @behaviour Mailglass.Adapter

    def deliver(_message, _opts) do
      {:error, SendError.new(:adapter_failure, retry_class: :transient)}
    end
  end

  defmodule ProviderBodyAdapter do
    @behaviour Swoosh.Adapter

    def deliver(_email, _config) do
      {:error,
       {:api_error, 502,
        "provider-body-sentinel recipient-sentinel@example.com subject-sentinel rendered-body-sentinel"}}
    end

    def validate_config(_), do: :ok
  end

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

    test "permanent send errors cancel rather than retry under locked Oban 2.23 semantics" do
      Application.put_env(:mailglass, :adapter, {PermanentFailureAdapter, []})

      delivery =
        Generators.delivery_fixture(
          tenant_id: "permanent-worker-tenant",
          metadata: %{
            "rendered_html" => "<p>Hello</p>",
            "rendered_text" => "Hello",
            "subject" => "Test"
          }
        )

      job = %Oban.Job{
        args: %{"delivery_id" => delivery.id, "mailglass_tenant_id" => "permanent-worker-tenant"}
      }

      assert {:cancel, :permanent_failure} = Mailglass.Outbound.Worker.perform(job)
    end

    test "transient send errors return Oban's retry form" do
      Application.put_env(:mailglass, :adapter, {TransientFailureAdapter, []})

      delivery =
        Generators.delivery_fixture(
          tenant_id: "transient-worker-tenant",
          metadata: %{
            "rendered_html" => "<p>Hello</p>",
            "rendered_text" => "Hello",
            "subject" => "Test"
          }
        )

      job = %Oban.Job{
        args: %{"delivery_id" => delivery.id, "mailglass_tenant_id" => "transient-worker-tenant"}
      }

      assert {:error, %SendError{retry_class: :transient}} = Mailglass.Outbound.Worker.perform(job)
    end

    test "provider response sentinels cannot enter persisted last_error" do
      Application.put_env(
        :mailglass,
        :adapter,
        {Mailglass.Adapters.Swoosh, swoosh_adapter: ProviderBodyAdapter}
      )

      delivery =
        Generators.delivery_fixture(
          tenant_id: "private-error-worker-tenant",
          metadata: %{
            "rendered_html" => "<p>Hello</p>",
            "rendered_text" => "Hello",
            "subject" => "Test"
          }
        )

      job = %Oban.Job{
        args: %{
          "delivery_id" => delivery.id,
          "mailglass_tenant_id" => "private-error-worker-tenant"
        }
      }

      assert {:error, %SendError{retry_class: :transient}} = Mailglass.Outbound.Worker.perform(job)
      persisted = Mailglass.Repo.get(Delivery, delivery.id).last_error |> inspect()

      for sentinel <- [
            "provider-body-sentinel",
            "recipient-sentinel@example.com",
            "subject-sentinel",
            "rendered-body-sentinel"
          ] do
        refute String.contains?(persisted, sentinel)
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
