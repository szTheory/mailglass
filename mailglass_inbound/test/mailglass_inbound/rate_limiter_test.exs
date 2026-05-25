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

    on_exit(fn ->
      if is_nil(prior_rate_limit) do
        Application.delete_env(:mailglass_inbound, :rate_limit)
      else
        Application.put_env(:mailglass_inbound, :rate_limit, prior_rate_limit)
      end
    end)

    # The TableOwner (supervised by MailglassInbound.Application) creates the
    # table at boot; clear it between tests.
    :ets.delete_all_objects(@table)
    :ok
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
