defmodule Mailglass.RateLimiterTest do
  use ExUnit.Case, async: false

  alias Mailglass.{RateLimiter, RateLimitError}

  setup do
    prev_config = Application.get_env(:mailglass, :rate_limit)

    on_exit(fn ->
      if prev_config do
        Application.put_env(:mailglass, :rate_limit, prev_config)
      else
        Application.delete_env(:mailglass, :rate_limit)
      end
    end)

    # Reset the ETS table between tests by deleting all entries
    :ets.delete_all_objects(:mailglass_rate_limit)
    :ok
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
    test "Test 4: after over-limit, waiting refill_ms then calling again returns :ok" do
      # Capacity 2, per_minute 120 => refill_per_ms = 120/60000 = 0.002 t/ms => 500ms to get 1 token
      Application.put_env(:mailglass, :rate_limit, default: [capacity: 2, per_minute: 120])
      :ets.delete_all_objects(:mailglass_rate_limit)

      # Drain
      assert :ok = RateLimiter.check("tenant-refill", "refill.com", :operational)
      assert :ok = RateLimiter.check("tenant-refill", "refill.com", :operational)

      assert {:error, %RateLimitError{}} =
               RateLimiter.check("tenant-refill", "refill.com", :operational)

      # Wait 600ms for at least 1 token to refill (refill rate: 1 token per 500ms)
      Process.sleep(600)

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
end
