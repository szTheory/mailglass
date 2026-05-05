# Telemetry

mailglass emits `:telemetry` events for outbound rendering and dispatch, plus
webhook signature verification, ingest, per-event normalization, orphan
detection, and reconcile sweeps. This guide documents only the event families
and metadata keys that the current code emits.

## What mailglass emits today

### Outbound spans from `Mailglass.Telemetry`

| Event path | Type | Metadata keys |
|------------|------|---------------|
| `[:mailglass, :render, :message, :start | :stop | :exception]` | full span | `tenant_id, mailable` |
| `[:mailglass, :outbound, :send, :start | :stop | :exception]` | full span | caller-supplied whitelist keys such as `tenant_id, mailable, status, delivery_id, latency_ms` |
| `[:mailglass, :outbound, :dispatch, :start | :stop | :exception]` | full span | caller-supplied whitelist keys such as `provider, status, delivery_id, latency_ms` |

### Webhook spans and emits from `Mailglass.Webhook.Telemetry`

| Event path | Type | Stop metadata keys |
|------------|------|--------------------|
| `[:mailglass, :webhook, :ingest, :start | :stop | :exception]` | full span | `provider, tenant_id, status, event_count, duplicate, failure_reason, delivery_id_matched` |
| `[:mailglass, :webhook, :signature, :verify, :start | :stop | :exception]` | full span | `provider, status, failure_reason` |
| `[:mailglass, :webhook, :normalize, :stop]` | single emit | `provider, event_type, mapped` |
| `[:mailglass, :webhook, :orphan, :stop]` | single emit | `provider, event_type, tenant_id, age_seconds` |
| `[:mailglass, :webhook, :duplicate, :stop]` | single emit | `provider, event_type` |
| `[:mailglass, :webhook, :reconcile, :start | :stop | :exception]` | full span | `tenant_id, scanned_count, linked_count, remaining_orphan_count, status` |

## Whitelist and privacy posture

The shipped whitelist in `Mailglass.Telemetry` allows keys such as:

- `tenant_id`
- `mailable`
- `provider`
- `status`
- `message_id`
- `delivery_id`
- `event_id`
- `latency_ms`
- `recipient_count`
- `bytes`
- `retry_count`

Webhook helpers also emit the shipped operational keys:

- `event_count`
- `duplicate`
- `failure_reason`
- `delivery_id_matched`
- `event_type`
- `mapped`
- `age_seconds`
- `scanned_count`
- `linked_count`
- `remaining_orphan_count`

mailglass does not emit recipient addresses, message bodies, subjects, raw
payloads, raw request bodies, IPs, or user agents in telemetry metadata.

## Reading the support model correctly

- Provider lifecycle facts come from outbound dispatch spans and normalized
  provider webhook events.
- Replay facts are operator-triggered audit facts on one exact stored webhook
  row. Replay is not its own telemetry family in this phase.
- Reconcile facts come from the background-first
  `[:mailglass, :webhook, :reconcile, *]` span and from appended
  `:reconciled` ledger events.

If a replay completed with `no change`, that does not mean reconcile ran. If a
reconcile sweep linked an orphan, that does not prove a provider retried
anything. Keep those fact sets separate in alerts and runbooks.

## Minimal attachment examples

### Log webhook ingest failures

```elixir
:telemetry.attach(
  "mailglass-webhook-ingest-log",
  [:mailglass, :webhook, :ingest, :stop],
  fn _event, measurements, metadata, _config ->
    if metadata.status != :ok do
      Logger.warning(
        "mailglass webhook ingest status=#{metadata.status} provider=#{metadata.provider} " <>
          "events=#{metadata.event_count} duration=#{measurements.duration}"
      )
    end
  end,
  nil
)
```

### Track orphan backlog pressure

```elixir
:telemetry.attach(
  "mailglass-webhook-orphans",
  [:mailglass, :webhook, :orphan, :stop],
  fn _event, _measurements, metadata, _config ->
    MyApp.Metrics.increment("mailglass.webhook.orphan",
      tags: [provider: metadata.provider, event_type: metadata.event_type]
    )
  end,
  nil
)
```

### Track reconcile sweep outcomes

```elixir
:telemetry.attach(
  "mailglass-webhook-reconcile",
  [:mailglass, :webhook, :reconcile, :stop],
  fn _event, _measurements, metadata, _config ->
    MyApp.Metrics.gauge("mailglass.webhook.reconcile.remaining", metadata.remaining_orphan_count)
    MyApp.Metrics.increment("mailglass.webhook.reconcile.linked", metadata.linked_count)
  end,
  nil
)
```

## Optional backend recipes

These are optional integration patterns. mailglass does not require any
dashboard or backend beyond `:telemetry`.

### LiveDashboard metrics

Define metrics in your adopter app and mount `Phoenix.LiveDashboard` if you
already use it:

```elixir
summary("mailglass.webhook.ingest.duration", unit: {:native, :millisecond})
counter("mailglass.webhook.duplicate.count")
last_value("mailglass.webhook.reconcile.remaining")
```

### OpenTelemetry bridge

Attach handlers that translate shipped event names into your own spans or
metrics if you already depend on OpenTelemetry:

```elixir
:telemetry.attach(
  "mailglass-otel-bridge",
  [:mailglass, :outbound, :dispatch, :stop],
  fn _event, measurements, metadata, _config ->
    MyApp.Observability.record_mailglass_dispatch(measurements.duration, metadata)
  end,
  nil
)
```

### Sentry breadcrumb or issue enrichment

```elixir
:telemetry.attach(
  "mailglass-sentry-breadcrumbs",
  [:mailglass, :webhook, :signature, :verify, :stop],
  fn _event, _measurements, metadata, _config ->
    if metadata.status != :ok do
      MyApp.ErrorReporter.add_breadcrumb("mailglass webhook signature failure", metadata)
    end
  end,
  nil
)
```

### Honeycomb-style event forwarding

```elixir
:telemetry.attach(
  "mailglass-honeycomb-events",
  [:mailglass, :webhook, :ingest, :stop],
  fn event, measurements, metadata, _config ->
    MyApp.Observability.emit(event, measurements, metadata)
  end,
  nil
)
```

## What this guide does not promise

- No built-in observability dashboard or incident console
- No provider-side truth beyond the facts mailglass persists or emits locally
- No replay telemetry family beyond the existing delivery timeline and audit
  facts
