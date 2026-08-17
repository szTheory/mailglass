defmodule MailglassInbound.RateLimiterTest do
  # async: false — the limiter shares one node-local ETS table
  # (:mailglass_inbound_rate_limit) and reads process-global
  # :mailglass_inbound rate_limit config. Reset the table + snapshot config
  # in setup so tests are deterministic and order-independent.
  use ExUnit.Case, async: false

  alias Mailglass.RateLimitError
  alias MailglassInbound.RateLimiter

  @table :mailglass_inbound_rate_limit

  setup do
    prior_rate_limit = Application.get_env(:mailglass_inbound, :rate_limit)
    prior_clock = Application.get_env(:mailglass_inbound, :rate_limit_clock)
    prior_owner = Application.get_env(:mailglass_inbound, :rate_limit_table_owner)

    on_exit(fn ->
      if is_nil(prior_rate_limit) do
        Application.delete_env(:mailglass_inbound, :rate_limit)
      else
        Application.put_env(:mailglass_inbound, :rate_limit, prior_rate_limit)
      end

      restore_env(:rate_limit_clock, prior_clock)
      restore_env(:rate_limit_table_owner, prior_owner)
    end)

    # The TableOwner (supervised by MailglassInbound.Application) creates the
    # table at boot; clear it between tests.
    :ets.delete_all_objects(@table)
    :ok
  end

  defp restore_env(key, nil), do: Application.delete_env(:mailglass_inbound, key)
  defp restore_env(key, value), do: Application.put_env(:mailglass_inbound, key, value)

  describe "shared atomic bucket" do
    test "active-key overflow denies until idle expiry reclaims capacity" do
      Application.put_env(:mailglass_inbound, :rate_limit_table_owner,
        max_keys: 1,
        idle_expiry_ms: 10,
        sweep_interval_ms: 60_000
      )

      first_key = {:tenant, "bounded-first"}
      second_key = {:tenant, "bounded-second"}
      initial = fn key, now_us -> {key, 1_000_000, now_us, 0, now_us} end

      assert :ok =
               GenServer.call(
                 MailglassInbound.RateLimiter.TableOwner,
                 {:admit, first_key, initial.(first_key, 100_000), 100_000}
               )

      assert {:error, :denied} =
               GenServer.call(
                 MailglassInbound.RateLimiter.TableOwner,
                 {:admit, second_key, initial.(second_key, 100_000), 100_000}
               )

      assert :ets.info(@table, :size) == 1
      assert :ets.member(@table, first_key)

      true = :ets.insert(@table, {first_key, 1_000_000, 0, 0, 0})

      assert :ok =
               GenServer.call(
                 MailglassInbound.RateLimiter.TableOwner,
                 {:admit, second_key, initial.(second_key, 20_000), 20_000}
               )

      assert :ets.info(@table, :size) == 1
      refute :ets.member(@table, first_key)
      assert :ets.member(@table, second_key)
    end

    test "fast path preserves a depleted bucket across clock regression" do
      now = :atomics.new(1, [])
      :atomics.put(now, 1, 99)
      Application.put_env(:mailglass_inbound, :rate_limit_clock, fn -> :atomics.get(now, 1) end)

      Application.put_env(:mailglass_inbound, :rate_limit,
        tenant: [capacity: 1, per_minute: 60_000_000],
        recipient: [capacity: 1_000, per_minute: 0],
        sender_domain: [capacity: 1_000, per_minute: 0]
      )

      key = {:tenant, "clock-regression"}
      true = :ets.insert(@table, {key, 0, 100, 17, 100})

      assert {:error, %RateLimitError{}} =
               RateLimiter.check("clock-regression", "user@inbound.test", "sender.test")

      assert [{^key, 0, 100, 17, 100}] = :ets.lookup(@table, key)

      :atomics.put(now, 1, 100)

      assert {:error, %RateLimitError{}} =
               RateLimiter.check("clock-regression", "user@inbound.test", "sender.test")

      assert [{^key, 0, 100, 17, 100}] = :ets.lookup(@table, key)
    end

    test "recreates its ETS table instead of raising when admission sees it absent" do
      # Deleting a named ETS table immediately before admission exercises the
      # owner-side recovery path. It must recreate the canonical table before
      # looking up or inserting the new bucket.
      :ets.delete(@table)

      assert :ok = RateLimiter.check("restart-window", "user@restart.test", "sender.test")
      refute :undefined == :ets.whereis(@table)
    end

    test "concurrent inbound callers receive only the deterministic refilled capacity" do
      now = :atomics.new(1, [])
      :atomics.put(now, 1, 0)
      Application.put_env(:mailglass_inbound, :rate_limit_clock, fn -> :atomics.get(now, 1) end)

      Application.put_env(:mailglass_inbound, :rate_limit,
        tenant: [capacity: 10, per_minute: 10],
        recipient: [capacity: 1_000, per_minute: 1_000],
        sender_domain: [capacity: 1_000, per_minute: 1_000]
      )

      for _ <- 1..10,
          do: assert(:ok = RateLimiter.check("atomic", "user@inbound.test", "sender.test"))

      :atomics.put(now, 1, 60_000_000)
      parent = self()

      tasks =
        for _ <- 1..40 do
          Task.async(fn ->
            send(parent, :ready)

            receive do
              :go -> RateLimiter.check("atomic", "user@inbound.test", "sender.test")
            end
          end)
        end

      for _ <- tasks, do: assert_receive(:ready)
      Enum.each(tasks, &send(&1.pid, :go))
      assert Enum.count(Enum.map(tasks, &Task.await(&1, 5_000)), &(&1 == :ok)) == 10
    end

    test "a restarted owner admits exactly tenant capacity under barrier contention" do
      capacity = 50

      Application.put_env(:mailglass_inbound, :rate_limit,
        tenant: [capacity: capacity, per_minute: 0],
        recipient: [capacity: 100_000, per_minute: 0],
        sender_domain: [capacity: 100_000, per_minute: 0]
      )

      old_owner = Process.whereis(MailglassInbound.RateLimiter.TableOwner)
      owner_down = Process.monitor(old_owner)
      Process.exit(old_owner, :kill)
      assert_receive {:DOWN, ^owner_down, :process, ^old_owner, :killed}

      children = Elixir.Supervisor.which_children(MailglassInbound.Supervisor)

      {MailglassInbound.RateLimiter.TableOwner, new_owner, :worker, _} =
        Enum.find(children, fn {id, _pid, _type, _modules} ->
          id == MailglassInbound.RateLimiter.TableOwner
        end)

      assert is_pid(new_owner)
      refute new_owner == old_owner
      refute :undefined == :ets.whereis(@table)

      parent = self()

      tasks =
        for _ <- 1..100 do
          Task.async(fn ->
            send(parent, :inbound_rate_limit_ready)

            receive do
              :inbound_rate_limit_go ->
                RateLimiter.check("restart-contention", "user@restart.test", "sender.test")
            end
          end)
        end

      for _ <- tasks, do: assert_receive(:inbound_rate_limit_ready)
      Enum.each(tasks, &send(&1.pid, :inbound_rate_limit_go))

      results = Enum.map(tasks, &Task.await(&1, 5_000))
      assert Enum.count(results, &(&1 == :ok)) == capacity
      assert Enum.count(results, &match?({:error, %RateLimitError{}}, &1)) == 100 - capacity
    end
  end

  describe "check/3 fresh bucket allows up to capacity then errors" do
    test "tenant bucket: capacity successes, then {:error, %RateLimitError{}}" do
      Application.put_env(:mailglass_inbound, :rate_limit,
        tenant: [capacity: 5, per_minute: 60],
        recipient: [capacity: 1000, per_minute: 60],
        sender_domain: [capacity: 1000, per_minute: 60]
      )

      :ets.delete_all_objects(@table)

      results =
        for _i <- 1..6 do
          RateLimiter.check("tenant-a", "user@recipient.example", "sender.example")
        end

      ok_count = Enum.count(results, &(&1 == :ok))
      err_count = Enum.count(results, &match?({:error, %RateLimitError{}}, &1))

      assert ok_count == 5, "Expected 5 :ok, got #{ok_count}"
      assert err_count == 1, "Expected 1 error, got #{err_count}"
    end
  end

  describe "check/3 fail-fast bucket order tenant -> recipient -> sender_domain" do
    test "the tenant bucket trips first and the error carries a non-zero retry_after_ms" do
      # Tenant capacity is the smallest, so it trips first.
      Application.put_env(:mailglass_inbound, :rate_limit,
        tenant: [capacity: 1, per_minute: 60],
        recipient: [capacity: 1000, per_minute: 60],
        sender_domain: [capacity: 1000, per_minute: 60]
      )

      :ets.delete_all_objects(@table)

      assert :ok = RateLimiter.check("tenant-order", "user@recipient.example", "sender.example")

      assert {:error, %RateLimitError{} = err} =
               RateLimiter.check("tenant-order", "user@recipient.example", "sender.example")

      # The tenant bucket maps to :per_tenant.
      assert err.type == :per_tenant
      assert err.retry_after_ms >= 1
    end

    test "the recipient bucket trips when tenant is generous (its own retry_after, :per_domain)" do
      Application.put_env(:mailglass_inbound, :rate_limit,
        tenant: [capacity: 1000, per_minute: 60],
        recipient: [capacity: 1, per_minute: 60],
        sender_domain: [capacity: 1000, per_minute: 60]
      )

      :ets.delete_all_objects(@table)

      assert :ok = RateLimiter.check("tenant-r", "victim@recipient.example", "sender.example")

      assert {:error, %RateLimitError{} = err} =
               RateLimiter.check("tenant-r", "victim@recipient.example", "sender.example")

      # Recipient + sender_domain buckets map to :per_domain.
      assert err.type == :per_domain
      assert err.retry_after_ms >= 1
    end

    test "the sender_domain bucket trips when tenant + recipient are generous" do
      Application.put_env(:mailglass_inbound, :rate_limit,
        tenant: [capacity: 1000, per_minute: 60],
        recipient: [capacity: 1000, per_minute: 60],
        sender_domain: [capacity: 1, per_minute: 60]
      )

      :ets.delete_all_objects(@table)

      assert :ok = RateLimiter.check("tenant-s", "user@recipient.example", "sender.example")

      assert {:error, %RateLimitError{} = err} =
               RateLimiter.check("tenant-s", "anotheruser@other.example", "sender.example")

      assert err.type == :per_domain
      assert err.retry_after_ms >= 1
    end
  end

  describe "check/3 PII discipline (D-49-16)" do
    test "the error context carries no recipient/sender/to/email value keys" do
      Application.put_env(:mailglass_inbound, :rate_limit,
        tenant: [capacity: 0, per_minute: 60],
        recipient: [capacity: 1000, per_minute: 60],
        sender_domain: [capacity: 1000, per_minute: 60]
      )

      :ets.delete_all_objects(@table)

      # capacity 0 seeds then immediately over-limit; loop to guarantee an error.
      result =
        Enum.reduce_while(1..3, :ok, fn _i, _acc ->
          case RateLimiter.check("tenant-pii", "victim@recipient.example", "sender.example") do
            {:error, %RateLimitError{}} = err -> {:halt, err}
            :ok -> {:cont, :ok}
          end
        end)

      assert {:error, %RateLimitError{} = err} = result
      ctx = err.context || %{}

      refute Map.has_key?(ctx, :recipient)
      refute Map.has_key?(ctx, :sender)
      refute Map.has_key?(ctx, :to)
      refute Map.has_key?(ctx, :from)
      refute Map.has_key?(ctx, :email)
    end
  end

  describe "check/3 concurrent load (ETS atomicity)" do
    test "exactly capacity successes across > capacity concurrent tasks on one key" do
      capacity = 50

      Application.put_env(:mailglass_inbound, :rate_limit,
        tenant: [capacity: capacity, per_minute: 60],
        recipient: [capacity: 100_000, per_minute: 60],
        sender_domain: [capacity: 100_000, per_minute: 60]
      )

      :ets.delete_all_objects(@table)

      task_count = capacity * 3

      results =
        1..task_count
        |> Task.async_stream(
          fn _i ->
            RateLimiter.check("tenant-concurrent", "user@recipient.example", "sender.example")
          end,
          max_concurrency: 32,
          ordered: false
        )
        |> Enum.map(fn {:ok, result} -> result end)

      ok_count = Enum.count(results, &(&1 == :ok))
      err_count = Enum.count(results, &match?({:error, %RateLimitError{}}, &1))

      assert ok_count == capacity, "Expected exactly #{capacity} :ok, got #{ok_count}"
      assert err_count == task_count - capacity
    end
  end

  describe "check/3 independent buckets per key" do
    test "different tenants have independent tenant buckets" do
      Application.put_env(:mailglass_inbound, :rate_limit,
        tenant: [capacity: 1, per_minute: 60],
        recipient: [capacity: 1000, per_minute: 60],
        sender_domain: [capacity: 1000, per_minute: 60]
      )

      :ets.delete_all_objects(@table)

      assert :ok = RateLimiter.check("tenant-x", "u@recipient.example", "sender.example")

      assert {:error, %RateLimitError{}} =
               RateLimiter.check("tenant-x", "u@recipient.example", "sender.example")

      # A different tenant still has a fresh bucket.
      assert :ok = RateLimiter.check("tenant-y", "u@recipient.example", "sender.example")
    end
  end
end
