# Rate Limiting

Mailglass includes a multi-bucket rate limiter designed to protect sender reputation and satisfy ISP throughput requirements. Limits apply to one envelope recipient at a time: Mailglass accepts exactly one recipient per email, never recipient fan-out.

With the default unstamped tenancy resolver, the tenant is `"default"`. Async
sends are processed by normal Oban work on `:mailglass_outbound`; rate-limit
rejection happens before a payload or queue entry is created.

## The Three Buckets

Every outbound message passes through three rate limit checks in sequence. If any bucket is exhausted, the delivery fails with a `Mailglass.RateLimitError`.

| Bucket Type | Scope | Purpose | Default |
|-------------|-------|---------|---------|
| `:tenant_recipient` | `{tenant_id, recipient_domain}` | Prevents a single tenant from saturating a shared recipient domain (e.g. gmail.com) and affecting other tenants. | 100/min |
| `:global_recipient` | `recipient_domain` | Protects your shared IP reputation by limiting aggregate throughput to any single recipient domain across all tenants. | 1000/min |
| `:sender_domain` | `sender_domain` | Protects your sender domain reputation by limiting total volume sent from that domain across all recipients. | 500/min |

## Configuration

Rate limits are configured in `config/config.exs` or `config/runtime.exs`. You can set global defaults and per-domain overrides for each bucket.

<!-- docs: executable -->
```elixir
config :mailglass, :rate_limit,
  tenant_recipient: [
    default: [capacity: 100, per_minute: 100],
    overrides: [
      {{"premium-tenant", "gmail.com"}, [capacity: 500, per_minute: 500]}
    ]
  ],
  global_recipient: [
    default: [capacity: 1000, per_minute: 1000],
    overrides: [
      {"gmail.com", [capacity: 5000, per_minute: 5000]}
    ]
  ],
  sender_domain: [
    default: [capacity: 500, per_minute: 500],
    overrides: [
      {"marketing.example.com", [capacity: 200, per_minute: 200]}
    ]
  ]
```

### Bucket Parameters

- `:capacity` — The maximum number of tokens in the bucket (burst allowance).
- `:per_minute` — The refill rate of tokens per minute.

## Transactional Bypass (D-24)

Messages sent via the `:transactional` stream **always bypass all rate limits**. 

Password resets, magic links, and verification emails must not be throttled because a marketing campaign or bulk broadcast saturated the rate limit buckets. This is a core invariant of Mailglass and is not tunable.

## Handling RateLimitError

When a message is throttled, `Mailglass.deliver/2` (or `deliver_later/2`) returns `{:error, %Mailglass.RateLimitError{}}`. 

Adopters should handle this error based on their application needs:
- **Synchronous:** Inform the user or retry after the `retry_after_ms` period.
- **Asynchronous (Oban):** Oban automatically retries failed jobs. The `RateLimitError` is transient, so the job will eventually succeed as tokens refill.

<!-- docs: executable -->
```elixir
case MyApp.UserMailer.welcome(user) |> Mailglass.deliver() do
  :ok -> :ok
  {:error, %Mailglass.RateLimitError{retry_after_ms: ms}} ->
    # Log or handle throttle
    {:error, :throttled}
end
```

## Implementation Details

The rate limiter uses an ETS-backed token bucket algorithm (`:ets.update_counter/4`) for high performance. It executes in the caller's process and does not require a GenServer bottleneck.

Telemetry events are emitted for every check at `[:mailglass, :outbound, :rate_limit, :stop]`.
