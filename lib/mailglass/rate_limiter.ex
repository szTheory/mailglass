defmodule Mailglass.RateLimiter do
  @moduledoc """
  Per-`{tenant_id, recipient_domain}` ETS token bucket (SEND-02).

  Hot path is `:ets.update_counter/4` — no GenServer mailbox
  serialization. The `TableOwner` GenServer exists only to own the
  table (see D-22). ≈1-3μs on OTP 27 with `decentralized_counters: true`
  plus `write_concurrency: :auto`.

  ## Invariants

  - **`:transactional` bypass (D-24):** `check/3` with
    `stream == :transactional` returns `:ok` BEFORE any ETS read.
    Password-reset / magic-link / verify-email MUST NOT be throttled
    because a marketing campaign saturated the bucket. Documented as
    a reserved invariant in `docs/api_stability.md`; this is NOT a
    tunable.
  - **Leaky-bucket continuous refill (D-23):** capacity tokens refill
    at `capacity / 60_000` tokens/ms. Default: 100 tokens @ 100/min.

  ## Configuration

      config :mailglass, :rate_limit,
        default: [capacity: 100, per_minute: 100],
        overrides: [
          {{"premium-tenant", "gmail.com"}, [capacity: 500, per_minute: 500]}
        ]

  Missing `:rate_limit` key uses built-in defaults.

  ## Telemetry

  Single-emit `[:mailglass, :outbound, :rate_limit, :stop]` with:
  - Measurements: `%{duration_us: integer()}`
  - Metadata: `%{allowed: boolean(), tenant_id: String.t()}`

  **No PII** — recipient_domain is NOT emitted (domain is less
  sensitive than full address, but to stay inside the Phase 1 D-31
  whitelist we omit it; operators who need it can add a domain-aware
  handler that reads context from other sources).
  """

  alias Mailglass.RateLimitError

  @table :mailglass_rate_limit

  @doc """
  Returns `:ok` when the delivery is allowed, or `{:error, %RateLimitError{}}`
  when the bucket is depleted. `:transactional` stream always returns `:ok`.

  ## Arguments

  - `tenant_id` — binary tenant id
  - `recipient_domain` — binary domain (e.g. `"gmail.com"`)
  - `stream` — `:transactional | :operational | :bulk`
  """
  @doc since: "0.1.0"
  @spec check(String.t(), String.t(), atom()) :: :ok | {:error, RateLimitError.t()}
  def check(_tenant_id, _domain, :transactional) do
    emit_telemetry(0, true, nil)
    :ok
  end

  def check(tenant_id, domain, _stream) when is_binary(tenant_id) and is_binary(domain) do
    start = System.monotonic_time(:microsecond)

    {capacity, refill_per_ms} = limits_for(tenant_id, domain)
    key = {tenant_id, domain}
    now_ms = System.monotonic_time(:millisecond)

    # First-hit: seed bucket with full capacity if key doesn't exist yet.
    :ets.insert_new(@table, {key, capacity, now_ms})

    # Read current state to compute refill delta.
    [{^key, tokens, last}] = :ets.lookup(@table, key)

    # After an over-limit event the counter may be stored as -1 (one below zero).
    # Compute how many tokens to add: restore from negative + elapsed refill, capped at capacity.
    #
    # Example: tokens=-1 (drained), 600ms elapsed, refill_per_ms=0.002, capacity=2:
    #   restore = 1 (to bring -1 -> 0)
    #   refilled = round(600 * 0.002) = 1
    #   total_add = min(1 + 1, 2 - (-1)) = min(2, 3) = 2  -- cap to capacity - tokens
    #   After add: -1 + 2 = 1 token. After decrement: 0. :ok.
    restore = if tokens < 0, do: abs(tokens), else: 0
    elapsed_ms = max(0, now_ms - last)
    refilled = round(elapsed_ms * refill_per_ms)
    # Total tokens to add, capped so bucket doesn't exceed capacity
    total_add = min(restore + refilled, capacity - tokens)

    # Atomic compound update (D-23 token bucket):
    #   Op 1: Add total_add to pos 2 (tokens), capped at capacity.
    #          {pos, incr, threshold, setval}: if tokens + total_add >= capacity, set to capacity.
    #   Op 2: Update timestamp (pos 3) to now_ms (always triggers — any ts >= 0).
    #   Op 3: Decrement tokens (pos 2) by 1. Returns the raw decremented value.
    #          Negative result = over-limit. Zero or positive = allowed.
    #
    # The read-then-update race is acceptable for rate limiting — worst case is
    # a brief burst allowance in a narrow concurrent window.
    result =
      :ets.update_counter(
        @table,
        key,
        [
          {2, total_add, capacity, capacity},
          {3, 0, 0, now_ms},
          {2, -1}
        ],
        {key, capacity, now_ms}
      )

    duration_us = System.monotonic_time(:microsecond) - start

    case result do
      [_refilled, _ts, new_tokens] when new_tokens >= 0 ->
        emit_telemetry(duration_us, true, tenant_id)
        :ok

      _ ->
        emit_telemetry(duration_us, false, tenant_id)
        ms = retry_after_ms(refill_per_ms)

        {:error,
         RateLimitError.new(:per_domain,
           retry_after_ms: ms,
           context: %{tenant_id: tenant_id, domain: domain, retry_after_ms: ms}
         )}
    end
  end

  defp limits_for(tenant_id, domain) do
    cfg = Application.get_env(:mailglass, :rate_limit, [])
    overrides = Keyword.get(cfg, :overrides, [])

    {capacity, per_minute} =
      case List.keyfind(overrides, {tenant_id, domain}, 0) do
        {_, opts} ->
          {Keyword.fetch!(opts, :capacity), Keyword.fetch!(opts, :per_minute)}

        nil ->
          default = Keyword.get(cfg, :default, capacity: 100, per_minute: 100)
          {Keyword.fetch!(default, :capacity), Keyword.fetch!(default, :per_minute)}
      end

    {capacity, per_minute / 60_000}
  end

  defp retry_after_ms(refill_per_ms) when refill_per_ms > 0, do: ceil(1 / refill_per_ms)
  defp retry_after_ms(_), do: 60_000

  defp emit_telemetry(duration_us, allowed, tenant_id) do
    :telemetry.execute(
      [:mailglass, :outbound, :rate_limit, :stop],
      %{duration_us: duration_us},
      %{allowed: allowed, tenant_id: tenant_id}
    )
  end
end
