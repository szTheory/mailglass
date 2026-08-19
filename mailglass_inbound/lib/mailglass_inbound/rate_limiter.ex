defmodule MailglassInbound.RateLimiter do
  @moduledoc """
  Inbound-local multi-bucket ETS token-bucket rate limiter.

  Cloned from `Mailglass.RateLimiter` — the load-bearing `:ets.update_counter/4`
  refill math is copied verbatim. Adapted for inbound:

  - **Three buckets, fail-fast** via `with`, in order tenant (1000/min) ->
    recipient (500/min) -> sender_domain (200/min). The first bucket to trip
    returns ITS OWN `Retry-After` — never a cross-bucket max.
  - **No stream-based bypass clause** — inbound has no stream semantics, so the
    core limiter's auth-stream short-circuit is intentionally dropped.
  - **No `%Mailglass.Message{}` coupling** — takes plain args.
  - Reads `:mailglass_inbound` config via `MailglassInbound.Config`, never
    `:mailglass`.
  - Builds `Mailglass.RateLimitError` internally (reuse the struct, never
    re-create it): `:per_tenant` for the tenant bucket, `:per_domain` for the
    recipient + sender_domain buckets.

  Hot path is `:ets.update_counter/4` on the `:mailglass_inbound_rate_limit`
  table owned by `MailglassInbound.RateLimiter.TableOwner` — no GenServer
  mailbox serialization.

  ## PII discipline

  The **sender bucket is keyed on the sender DOMAIN only**, never the full sender
  address. The **recipient bucket may key on the full recipient address** — it is
  the routing identity, already persisted in clear, lives only in node-local ETS,
  and is never logged, serialized, or emitted. No hashing required. The error
  context and any telemetry/HTTP body carry the bucket **type**
  (`:tenant | :recipient | :sender_domain`), **never** the key value. This comment
  exists so a future lint pass does not false-positive on the recipient-address
  ETS key.

  ## Per-node scope

  Counters live in node-local ETS — an N-node cluster enforces N x the limit.
  Acceptable for the single-node-default library posture; cluster-global
  enforcement is out of scope until a shared-backend option ships.
  """

  alias Mailglass.RateLimitError
  alias Mailglass.RateLimiter.AtomicBucket

  @table :mailglass_inbound_rate_limit

  @doc """
  Returns `:ok` when the inbound message is under all three bucket limits, or
  `{:error, %RateLimitError{}}` when the first-evaluated bucket
  (tenant -> recipient -> sender_domain) is depleted.

  Arguments:

  - `tenant_id` — the resolved tenant scope (tenant bucket key).
  - `recipient` — the envelope recipient / first `to` address (recipient bucket
    key; may be the full address, see PII discipline).
  - `sender_domain` — the DOMAIN of the first `from` address (sender bucket key;
    never the full sender address).

  The returned error's `retry_after_ms` is the tripped bucket's own refill
  interval. The `context` carries the PII-free bucket `:bucket` type and `:limit`
  (capacity) for the plug to classify and surface — never the recipient/sender
  value.
  """
  @doc since: "1.2.0"
  @spec check(String.t(), String.t() | nil, String.t() | nil) ::
          :ok | {:error, RateLimitError.t()}
  def check(tenant_id, recipient, sender_domain) do
    with :ok <- check_bucket(:tenant, tenant_id),
         :ok <- check_bucket(:recipient, recipient),
         :ok <- check_bucket(:sender_domain, sender_domain) do
      :ok
    else
      {:error, bucket, refill_per_ms} ->
        {:error, build_error(bucket, refill_per_ms)}
    end
  end

  # `check_bucket/2` refill math copied VERBATIM from
  # Mailglass.RateLimiter.check_bucket/2 (the load-bearing :ets.update_counter/4
  # token-bucket logic). On trip, returns {:error, bucket, refill_per_ms} so the
  # caller can build the right error type + the bucket's OWN Retry-After.
  defp check_bucket(bucket, sub_key) do
    {capacity, per_minute} = limits_for(bucket)
    key = {bucket, sub_key}
    now_us = clock_us()

    case AtomicBucket.consume(
           table: @table,
           owner: MailglassInbound.RateLimiter.TableOwner,
           key: key,
           capacity: capacity,
           per_minute: per_minute,
           now_us: now_us
         ) do
      :ok -> :ok
      {:error, :denied} -> {:error, bucket, per_minute}
    end
  end

  defp limits_for(bucket) do
    cfg = MailglassInbound.Config.rate_limit()
    bucket_cfg = Keyword.fetch!(cfg, bucket)
    capacity = Keyword.fetch!(bucket_cfg, :capacity)
    per_minute = Keyword.fetch!(bucket_cfg, :per_minute)

    {capacity, per_minute}
  end

  # Map a tripped bucket to the reused Mailglass.RateLimitError struct. The
  # tenant bucket is :per_tenant; recipient + sender_domain are :per_domain. The
  # context is PII-free: bucket TYPE + capacity only, never the key value
  # (the design contract).
  defp build_error(bucket, refill_per_ms) do
    ms = retry_after_ms(refill_per_ms)
    type = if bucket == :tenant, do: :per_tenant, else: :per_domain
    {capacity, _refill} = limits_for(bucket)

    RateLimitError.new(type,
      retry_after_ms: ms,
      context: %{bucket: bucket, limit: capacity, retry_after_ms: ms}
    )
  end

  defp retry_after_ms(per_minute) when per_minute > 0, do: ceil(60_000 / per_minute)
  defp retry_after_ms(_), do: 60_000

  defp clock_us do
    case Application.get_env(:mailglass_inbound, :rate_limit_clock) do
      fun when is_function(fun, 0) -> fun.()
      _ -> System.monotonic_time(:microsecond)
    end
  end
end
