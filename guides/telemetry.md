# Telemetry

mailglass emits standard `:telemetry` spans on every entry point — delivery, rendering, webhook ingest, and reconciliation.

## Prerequisites

- `telemetry` dependency available (installed by default)
- An event handler attached to `:mailglass` events

## Available Spans

The following spans include `[ID, :start | :stop | :exception]` events:

- `[:mailglass, :deliver]` — synchronous delivery pipeline
- `[:mailglass, :render]` — render pipeline (HEEx to HTML/Text)
- `[:mailglass, :webhook, :ingest]` — webhook verification and ingest
- `[:mailglass, :reconcile]` — delivery status reconciliation

## PII Whitelist

Telemetry metadata includes:
- `tenant_id`
- `message_id`
- `stream` (e.g. transactional)
- `adapter`
- `status`
- `latency`

It **never** includes recipient addresses, subject lines, or message bodies.

## Example: Logging delivery latency

```elixir
:telemetry.attach(
  "log-delivery",
  [:mailglass, :deliver, :stop],
  fn _name, measurements, metadata, _config ->
    Logger.info("Delivered message #{metadata.message_id} in #{measurements.duration}ms")
  end,
  nil
)
```

## End-to-End Example

```elixir
:telemetry.attach(
  "test-telemetry",
  [:mailglass, :render, :stop],
  fn _name, _measurements, metadata, _config ->
    send(self(), {:telemetry_rendered, metadata.function})
  end,
  nil
)

MyApp.UserMailer.welcome(%{email: "alice@example.com"})
|> Mailglass.Renderer.render()

assert_receive {:telemetry_rendered, :welcome}
```
