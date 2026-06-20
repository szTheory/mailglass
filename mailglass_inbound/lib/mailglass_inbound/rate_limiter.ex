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
    {capacity, refill_per_ms} = limits_for(bucket)
    key = {bucket, sub_key}
    now_ms = System.monotonic_time(:millisecond)

    # First-hit: seed bucket with full capacity if key doesn't exist yet.
    :ets.insert_new(@table, {key, capacity, now_ms})

    # Read current state to compute refill delta.
    [{^key, tokens, last}] = :ets.lookup(@table, key)

    restore = if tokens < 0, do: abs(tokens), else: 0
    elapsed_ms = max(0, now_ms - last)
    refilled = round(elapsed_ms * refill_per_ms)
    total_add = min(restore + refilled, capacity - tokens)

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

    case result do
      [_refilled, _ts, new_tokens] when new_tokens >= 0 -> :ok
      _ -> {:error, bucket, refill_per_ms}
    end
  end

  defp limits_for(bucket) do
    cfg = MailglassInbound.Config.rate_limit()
    bucket_cfg = Keyword.fetch!(cfg, bucket)
    capacity = Keyword.fetch!(bucket_cfg, :capacity)
    per_minute = Keyword.fetch!(bucket_cfg, :per_minute)

    {capacity, per_minute / 60_000}
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

  defp retry_after_ms(refill_per_ms) when refill_per_ms > 0, do: ceil(1 / refill_per_ms)
  defp retry_after_ms(_), do: 60_000
end
