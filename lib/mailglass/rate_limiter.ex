defmodule Mailglass.RateLimiter do
  @moduledoc """
  Multi-bucket ETS token bucket rate limiter.

  Hot path is `:ets.update_counter/4` — no GenServer mailbox
  serialization. The `TableOwner` GenServer exists only to own the
  table (see ). ≈1-3μs on OTP 27 with `decentralized_counters: true`
  plus `write_concurrency: :auto`.

  ## Invariants

  - **`:transactional` bypass:** `check/1` with
    `stream == :transactional` returns `:ok` BEFORE any ETS read.
    Password-reset / magic-link / verify-email MUST NOT be throttled
    because a marketing campaign saturated the bucket. Documented as
    a reserved invariant in `docs/api_stability.md`; this is NOT a
    tunable.
  - **Leaky-bucket continuous refill:** capacity tokens refill
    at `capacity / 60_000` tokens/ms.

  ## Configuration

      config :mailglass, :rate_limit,
        tenant_recipient: [
          default: [capacity: 100, per_minute: 100],
          overrides: [
            {{"premium-tenant", "gmail.com"}, [capacity: 500, per_minute: 500]}
          ]
        ],
        global_recipient: [
          default: [capacity: 1000, per_minute: 1000]
        ],
        sender_domain: [
          default: [capacity: 500, per_minute: 500]
        ]

  ## Telemetry

  Single-emit `[:mailglass, :outbound, :rate_limit, :stop]` with:
  - Measurements: `%{duration_us: integer()}`
  - Metadata: `%{allowed: boolean(), tenant_id: String.t()}`

  **No PII** — domains are NOT emitted in telemetry (to stay inside
  the   whitelist).
  """

  alias Mailglass.RateLimitError
  alias Mailglass.RateLimiter.AtomicBucket

  @table :mailglass_rate_limit

  @doc """
  Returns `:ok` when the delivery is allowed, or `{:error, %RateLimitError{}}`
  when any bucket is depleted. `:transactional` stream always returns `:ok`.
  """
  @doc since: "0.5.0"
  @spec check(Mailglass.Message.t()) :: :ok | {:error, RateLimitError.t()}
  def check(%Mailglass.Message{stream: :transactional}) do
    emit_telemetry(0, true, nil)
    :ok
  end

  def check(%Mailglass.Message{} = msg) do
    start = System.monotonic_time(:microsecond)

    recipient_domain = extract_recipient_domain(msg)
    sender_domain = extract_sender_domain(msg)

    # We check three buckets in order. Any failure short-circuits.
    with :ok <- check_bucket(:tenant_recipient, {msg.tenant_id, recipient_domain}),
         :ok <- check_bucket(:global_recipient, recipient_domain),
         :ok <- check_bucket(:sender_domain, sender_domain) do
      duration_us = System.monotonic_time(:microsecond) - start
      emit_telemetry(duration_us, true, msg.tenant_id)
      :ok
    else
      {:error, refill_per_ms} ->
        duration_us = System.monotonic_time(:microsecond) - start
        emit_telemetry(duration_us, false, msg.tenant_id)
        ms = retry_after_ms(refill_per_ms)

        {:error,
         RateLimitError.new(:per_domain,
           retry_after_ms: ms,
           context: %{
             tenant_id: msg.tenant_id,
             domain: recipient_domain,
             recipient_domain: recipient_domain,
             sender_domain: sender_domain,
             retry_after_ms: ms
           }
         )}
    end
  end

  @doc """
  Backward compatibility shim for `check/3`. Delegates to `check/1` by
  building a synthetic message.
  """
  @doc since: "0.1.0"
  @spec check(String.t(), String.t(), atom()) :: :ok | {:error, RateLimitError.t()}
  def check(tenant_id, domain, stream) do
    # Build a synthetic message for the check.
    # Note: sender_domain will be empty in this shim since we don't have the full message.
    email = Swoosh.Email.new() |> Swoosh.Email.to({"Recipient", "user@" <> domain})
    msg = %Mailglass.Message{tenant_id: tenant_id, stream: stream, swoosh_email: email}
    check(msg)
  end

  defp check_bucket(type, sub_key) do
    {capacity, per_minute} = limits_for(type, sub_key)
    key = {type, sub_key}
    now_us = clock_us()

    case AtomicBucket.consume(
           table: @table,
           owner: Mailglass.RateLimiter.TableOwner,
           key: key,
           capacity: capacity,
           per_minute: per_minute,
           now_us: now_us
         ) do
      :ok -> :ok
      {:error, :denied} -> {:error, per_minute}
    end
  end

  defp limits_for(type, sub_key) do
    cfg = get_config()
    type_cfg = Keyword.get(cfg, type, [])
    overrides = Keyword.get(type_cfg, :overrides, [])

    {capacity, per_minute} =
      case List.keyfind(overrides, sub_key, 0) do
        {_, opts} ->
          {Keyword.fetch!(opts, :capacity), Keyword.fetch!(opts, :per_minute)}

        nil ->
          default_limits = default_limits_for(type)
          default = Keyword.get(type_cfg, :default, default_limits)
          {Keyword.fetch!(default, :capacity), Keyword.fetch!(default, :per_minute)}
      end

    {capacity, per_minute}
  end

  defp get_config do
    cfg = Mailglass.Config.rate_limit()

    if Keyword.has_key?(cfg, :default) or Keyword.has_key?(cfg, :overrides) do
      # Backward compatibility: If :default or :overrides are present at the
      # top level, wrap them into :tenant_recipient.
      tenant_recipient = Keyword.take(cfg, [:default, :overrides])
      rest = Keyword.drop(cfg, [:default, :overrides])
      Keyword.put(rest, :tenant_recipient, tenant_recipient)
    else
      cfg
    end
  end

  defp default_limits_for(:tenant_recipient), do: [capacity: 100, per_minute: 100]
  defp default_limits_for(:global_recipient), do: [capacity: 1000, per_minute: 1000]
  defp default_limits_for(:sender_domain), do: [capacity: 500, per_minute: 500]

  defp retry_after_ms(per_minute) when per_minute > 0, do: ceil(60_000 / per_minute)
  defp retry_after_ms(_), do: 60_000

  defp clock_us do
    case Application.get_env(:mailglass, :rate_limit_clock) do
      fun when is_function(fun, 0) -> fun.()
      _ -> System.monotonic_time(:microsecond)
    end
  end

  defp emit_telemetry(duration_us, allowed, tenant_id) do
    :telemetry.execute(
      [:mailglass, :outbound, :rate_limit, :stop],
      %{duration_us: duration_us},
      %{allowed: allowed, tenant_id: tenant_id}
    )
  end

  defp extract_recipient_domain(%Mailglass.Message{
         swoosh_email: %Swoosh.Email{to: [{_, addr} | _]}
       }) do
    case String.split(addr, "@", parts: 2) do
      [_, d] -> String.downcase(d)
      _ -> ""
    end
  end

  defp extract_recipient_domain(_), do: ""

  defp extract_sender_domain(%Mailglass.Message{swoosh_email: %Swoosh.Email{from: {_, addr}}}) do
    case String.split(addr, "@", parts: 2) do
      [_, d] -> String.downcase(d)
      _ -> ""
    end
  end

  defp extract_sender_domain(%Mailglass.Message{swoosh_email: %Swoosh.Email{from: addr}})
       when is_binary(addr) do
    case String.split(addr, "@", parts: 2) do
      [_, d] -> String.downcase(d)
      _ -> ""
    end
  end

  defp extract_sender_domain(_), do: ""
end
