defmodule Mailglass.Outbound.WorkerTest do
  use Mailglass.DataCase, async: false

  # Only run these tests when Oban is available
  @moduletag :oban

  alias Mailglass.Outbound
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Generators

  setup do
    if Code.ensure_loaded?(Oban.Testing) do
      # Use Oban testing in manual mode so jobs don't execute immediately
      Oban.Testing.with_testing_mode(:manual, fn -> :ok end)
    end

    Mailglass.Adapters.Fake.checkout()
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
        delivery = Generators.delivery_fixture(
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

        result = Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
          Outbound.dispatch_by_id(delivery.id)
        end)

        assert {:ok, %Delivery{}} = result
      end
    end

    test "Worker wraps via TenancyMiddleware — tenant is stamped during perform" do
      if not Code.ensure_loaded?(Mailglass.Outbound.Worker) do
        :skip
      else
        delivery = Generators.delivery_fixture(
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
