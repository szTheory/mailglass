defmodule Mailglass.RateLimiterTest do
  use ExUnit.Case, async: false

  alias Mailglass.{RateLimiter, RateLimitError}

  setup do
    prev_config = Application.get_env(:mailglass, :rate_limit)
    prev_clock = Application.get_env(:mailglass, :rate_limit_clock)
    prev_owner = Application.get_env(:mailglass, :rate_limit_table_owner)

    on_exit(fn ->
      if prev_config do
        Application.put_env(:mailglass, :rate_limit, prev_config)
      else
        Application.delete_env(:mailglass, :rate_limit)
      end

      restore_env(:rate_limit_clock, prev_clock)
      restore_env(:rate_limit_table_owner, prev_owner)
    end)

    # Reset the ETS table between tests by deleting all entries
    :ets.delete_all_objects(:mailglass_rate_limit)
    :ok
  end

  defp restore_env(key, nil), do: Application.delete_env(:mailglass, key)
  defp restore_env(key, value), do: Application.put_env(:mailglass, key, value)

  describe "atomic fixed-point bucket" do
    test "fails closed instead of raising while its ETS owner restarts" do
      # Deleting a named ETS table simulates the narrow owner-restart window:
      # callers must receive the normal limiter error, never :badarg.
      :ets.delete(:mailglass_rate_limit)

      assert {:error, %RateLimitError{}} =
               RateLimiter.check("restart-window", "restart.test", :operational)

      on_exit(fn -> await_table(:mailglass_rate_limit) end)
    end

    test "concurrent callers receive exactly the refilled capacity without losing fractional time" do
      now = :atomics.new(1, [])
      :atomics.put(now, 1, 0)
      Application.put_env(:mailglass, :rate_limit_clock, fn -> :atomics.get(now, 1) end)
      Application.put_env(:mailglass, :rate_limit, default: [capacity: 10, per_minute: 10])

      for _ <- 1..10, do: assert(:ok = RateLimiter.check("atomic", "exact.test", :operational))
      :atomics.put(now, 1, 60_000_000)

      parent = self()

      tasks =
        for _ <- 1..40 do
          Task.async(fn ->
            send(parent, :ready)

            receive do
              :go -> RateLimiter.check("atomic", "exact.test", :operational)
            end
          end)
        end

      for _ <- tasks, do: assert_receive(:ready)
      Enum.each(tasks, &send(&1.pid, :go))

      results = Enum.map(tasks, &Task.await(&1, 5_000))
      assert Enum.count(results, &(&1 == :ok)) == 10

      # 100 ms at 10/min is a retained fractional refill; a later 5.9 s completes it.
      :atomics.put(now, 1, 60_100_000)
      assert {:error, %RateLimitError{}} = RateLimiter.check("atomic", "exact.test", :operational)
      :atomics.put(now, 1, 66_000_000)
      assert :ok = RateLimiter.check("atomic", "exact.test", :operational)
    end

    test "full active table fails closed and idle entries are reclaimed" do
      now = :atomics.new(1, [])
      :atomics.put(now, 1, 0)
      Application.put_env(:mailglass, :rate_limit_clock, fn -> :atomics.get(now, 1) end)
      Application.put_env(:mailglass, :rate_limit_table_owner, max_keys: 4, idle_expiry_ms: 100)
      Application.put_env(:mailglass, :rate_limit, default: [capacity: 1, per_minute: 1])

      assert :ok = RateLimiter.check("a", "cap.test", :operational)
      assert :ok = RateLimiter.check("b", "cap.test", :operational)
      assert {:error, %RateLimitError{}} = RateLimiter.check("c", "cap.test", :operational)

      :atomics.put(now, 1, 101_000)
      assert :ok = RateLimiter.check("c", "cap.test", :operational)
    end

    test "concurrent compound keys cannot replace each other's observed state" do
      Application.put_env(:mailglass, :rate_limit, default: [capacity: 10, per_minute: 0])

      results =
        for {tenant, domain} <- [{"tenant-a", "one.test"}, {"tenant-b", "two.test"}], _ <- 1..20 do
          Task.async(fn -> RateLimiter.check(tenant, domain, :operational) end)
        end
        |> Enum.map(&Task.await(&1, 5_000))

      assert Enum.count(results, &(&1 == :ok)) == 20
      assert Enum.count(Enum.take(results, 20), &(&1 == :ok)) == 10
      assert Enum.count(Enum.drop(results, 20), &(&1 == :ok)) == 10
    end
  end

  describe "check/3 :transactional bypass (D-24)" do
    test "Test 1: :transactional always returns :ok without touching ETS" do
      # With an impossibly small capacity (0), transactional still passes
      Application.put_env(:mailglass, :rate_limit, default: [capacity: 0, per_minute: 0])
      :ets.delete_all_objects(:mailglass_rate_limit)

      assert :ok = RateLimiter.check("tenant-a", "example.com", :transactional)
      # No ETS entry should exist — transactional bypasses ETS entirely
      assert :ets.lookup(:mailglass_rate_limit, {"tenant-a", "example.com"}) == []
    end
  end

  describe "check/3 token bucket — fresh bucket" do
    test "Test 2: first :operational call returns :ok (fresh bucket, capacity 100)" do
      Application.put_env(:mailglass, :rate_limit, default: [capacity: 100, per_minute: 100])
      :ets.delete_all_objects(:mailglass_rate_limit)

      assert :ok = RateLimiter.check("tenant-a", "example.com", :operational)
    end
  end

  describe "check/3 token bucket — over-limit" do
    test "Test 3: 101 rapid calls — 100 :ok, then {:error, %RateLimitError{}}" do
      Application.put_env(:mailglass, :rate_limit, default: [capacity: 100, per_minute: 100])
      :ets.delete_all_objects(:mailglass_rate_limit)

      results =
        for _i <- 1..101 do
          RateLimiter.check("tenant-over", "burst.com", :operational)
        end

      ok_count = Enum.count(results, &(&1 == :ok))
      err_count = Enum.count(results, &match?({:error, %RateLimitError{}}, &1))

      assert ok_count == 100, "Expected 100 :ok, got #{ok_count}"
      assert err_count == 1, "Expected 1 error, got #{err_count}"

      [{:error, %RateLimitError{} = err}] =
        Enum.filter(results, &match?({:error, %RateLimitError{}}, &1))

      assert err.type == :per_domain
      assert err.retry_after_ms >= 1
    end
  end

  describe "check/3 token bucket — refill" do
    test "Test 4: deterministic elapsed time refills a depleted bucket" do
      Application.put_env(:mailglass, :rate_limit, default: [capacity: 2, per_minute: 120])
      now = :atomics.new(1, [])
      :atomics.put(now, 1, 0)
      Application.put_env(:mailglass, :rate_limit_clock, fn -> :atomics.get(now, 1) end)
      :ets.delete_all_objects(:mailglass_rate_limit)

      # Drain
      assert :ok = RateLimiter.check("tenant-refill", "refill.com", :operational)
      assert :ok = RateLimiter.check("tenant-refill", "refill.com", :operational)

      assert {:error, %RateLimitError{}} =
               RateLimiter.check("tenant-refill", "refill.com", :operational)

      # 120/min refills one whole token after 500ms.
      :atomics.put(now, 1, 500_000)

      assert :ok = RateLimiter.check("tenant-refill", "refill.com", :operational)
    end
  end

  describe "check/3 tenant + domain isolation" do
    test "Test 5: different {tenant_id, domain} pairs have independent buckets" do
      Application.put_env(:mailglass, :rate_limit, default: [capacity: 2, per_minute: 60])
      :ets.delete_all_objects(:mailglass_rate_limit)

      # Drain tenant-a's bucket
      assert :ok = RateLimiter.check("tenant-a", "example.com", :operational)
      assert :ok = RateLimiter.check("tenant-a", "example.com", :operational)

      assert {:error, %RateLimitError{}} =
               RateLimiter.check("tenant-a", "example.com", :operational)

      # tenant-b same domain should still have a fresh bucket
      assert :ok = RateLimiter.check("tenant-b", "example.com", :operational)
      assert :ok = RateLimiter.check("tenant-b", "example.com", :operational)

      assert {:error, %RateLimitError{}} =
               RateLimiter.check("tenant-b", "example.com", :operational)

      # tenant-a different domain should also be fresh
      assert :ok = RateLimiter.check("tenant-a", "other.com", :operational)
    end
  end

  describe "check/3 error shape — PII compliance (T-3-03-02)" do
    test "Test 6: RateLimitError context contains :tenant_id and :domain — no PII keys" do
      Application.put_env(:mailglass, :rate_limit, default: [capacity: 0, per_minute: 60])
      :ets.delete_all_objects(:mailglass_rate_limit)

      # With capacity=0, first call should error
      result = RateLimiter.check("tenant-pii", "pii.com", :operational)

      # With capacity 0, the bucket seeds and immediately over-limit
      case result do
        {:error, %RateLimitError{} = err} ->
          ctx = err.context
          assert Map.has_key?(ctx, :tenant_id)
          assert Map.has_key?(ctx, :domain)
          # PII keys must NOT be present
          refute Map.has_key?(ctx, :recipient)
          refute Map.has_key?(ctx, :to)
          refute Map.has_key?(ctx, :email)

        :ok ->
          # Capacity=0 quirk: seed inserts capacity tokens, so first might succeed
          # Force to over-limit with a second call
          result2 = RateLimiter.check("tenant-pii", "pii.com", :operational)
          assert {:error, %RateLimitError{} = err} = result2
          ctx = err.context
          assert Map.has_key?(ctx, :tenant_id)
          assert Map.has_key?(ctx, :domain)
          refute Map.has_key?(ctx, :recipient)
          refute Map.has_key?(ctx, :to)
          refute Map.has_key?(ctx, :email)
      end
    end
  end

  describe "check/3 telemetry" do
    test "Test 7: emits [:mailglass, :outbound, :rate_limit, :stop] with :allowed and :tenant_id" do
      Application.put_env(:mailglass, :rate_limit, default: [capacity: 100, per_minute: 100])
      :ets.delete_all_objects(:mailglass_rate_limit)

      ref =
        :telemetry_test.attach_event_handlers(self(), [[:mailglass, :outbound, :rate_limit, :stop]])

      RateLimiter.check("tenant-tel", "tel.com", :operational)

      assert_receive {[:mailglass, :outbound, :rate_limit, :stop], ^ref, %{duration_us: _}, meta}
      assert Map.has_key?(meta, :allowed)
      assert Map.has_key?(meta, :tenant_id)
      # Must NOT have PII keys
      refute Map.has_key?(meta, :recipient)
      refute Map.has_key?(meta, :to)
      refute Map.has_key?(meta, :email)

      :telemetry.detach(ref)
    end
  end

  describe "check/3 configuration overrides" do
    test "Test 8: per-tenant override capacity=5 limits after 5 calls; override capacity=500 allows 500" do
      Application.put_env(:mailglass, :rate_limit,
        default: [capacity: 5, per_minute: 60],
        overrides: [
          {{"premium-tenant", "gmail.com"}, [capacity: 500, per_minute: 500]}
        ]
      )

      :ets.delete_all_objects(:mailglass_rate_limit)

      # Default capacity=5: 5 should succeed, 6th fails
      for _i <- 1..5 do
        assert :ok = RateLimiter.check("regular-tenant", "example.com", :operational)
      end

      assert {:error, %RateLimitError{type: :per_domain}} =
               RateLimiter.check("regular-tenant", "example.com", :operational)

      # Override capacity=500: 500 should succeed
      :ets.delete_all_objects(:mailglass_rate_limit)

      ok_count =
        Enum.count(1..500, fn _ ->
          RateLimiter.check("premium-tenant", "gmail.com", :operational) == :ok
        end)

      assert ok_count == 500
    end
  end

  describe "check/1 multi-bucket — global_recipient" do
    test "Test 9: global_recipient bucket throttles even if tenant bucket is fresh" do
      Application.put_env(:mailglass, :rate_limit,
        global_recipient: [default: [capacity: 2, per_minute: 60]]
      )

      :ets.delete_all_objects(:mailglass_rate_limit)

      msg1 = %Mailglass.Message{
        tenant_id: "tenant-1",
        stream: :operational,
        swoosh_email: Swoosh.Email.new() |> Swoosh.Email.to("u1@global.com")
      }

      msg2 = %Mailglass.Message{
        tenant_id: "tenant-2",
        stream: :operational,
        swoosh_email: Swoosh.Email.new() |> Swoosh.Email.to("u2@global.com")
      }

      msg3 = %Mailglass.Message{
        tenant_id: "tenant-3",
        stream: :operational,
        swoosh_email: Swoosh.Email.new() |> Swoosh.Email.to("u3@global.com")
      }

      assert :ok = RateLimiter.check(msg1)
      assert :ok = RateLimiter.check(msg2)
      assert {:error, %RateLimitError{}} = RateLimiter.check(msg3)
    end
  end

  describe "check/1 multi-bucket — sender_domain" do
    test "Test 10: sender_domain bucket throttles across recipients" do
      Application.put_env(:mailglass, :rate_limit,
        sender_domain: [default: [capacity: 2, per_minute: 60]]
      )

      :ets.delete_all_objects(:mailglass_rate_limit)

      email1 =
        Swoosh.Email.new() |> Swoosh.Email.from("app@sender.com") |> Swoosh.Email.to("u1@a.com")

      email2 =
        Swoosh.Email.new() |> Swoosh.Email.from("app@sender.com") |> Swoosh.Email.to("u2@b.com")

      email3 =
        Swoosh.Email.new() |> Swoosh.Email.from("app@sender.com") |> Swoosh.Email.to("u3@c.com")

      assert :ok =
               RateLimiter.check(%Mailglass.Message{
                 tenant_id: "t1",
                 stream: :operational,
                 swoosh_email: email1
               })

      assert :ok =
               RateLimiter.check(%Mailglass.Message{
                 tenant_id: "t1",
                 stream: :operational,
                 swoosh_email: email2
               })

      assert {:error, %RateLimitError{}} =
               RateLimiter.check(%Mailglass.Message{
                 tenant_id: "t1",
                 stream: :operational,
                 swoosh_email: email3
               })
    end
  end

  defp await_table(table, attempts \\ 50)
  defp await_table(_table, 0), do: :ok

  defp await_table(table, attempts) do
    if :ets.whereis(table) == :undefined do
      Process.sleep(10)
      await_table(table, attempts - 1)
    else
      :ok
    end
  end
end
