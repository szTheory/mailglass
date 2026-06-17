# Production Go-Live Checklist

Work through this checklist before routing live traffic through mailglass. Each section is a focused verification step with links to the canonical guide for detail. Complete all seven sections before marking the deployment ready.

## Deliverability: mix mail.doctor

Run DNS-only DKIM, SPF, and DMARC checks against your sending domain before launch:

```bash
mix mail.doctor --domain yourdomain.com
mix mail.doctor --domain yourdomain.com --dkim-selector default
mix mail.doctor --domain yourdomain.com --verbose
mix mail.doctor --domain yourdomain.com --format json
```

This command requires the application to be running — it calls `Mix.Task.run("app.start")` internally. Run it against the real sending domain, not localhost. A clean run confirms DNS records are discoverable by receiving mail servers.

For DKIM record setup and selector configuration, see [DKIM Setup](./dkim-setup.md).

## Webhook wiring: mix mailglass.doctor

Verify that `Mailglass.Webhook.CachingBodyReader` is wired correctly in `endpoint.ex` before accepting webhook events from your provider:

```bash
mix mailglass.doctor
```

This check is OFFLINE — it reads `endpoint.ex` from disk and does not boot the host application. Three-state exit:

- Exit `0` — `CachingBodyReader` is wired correctly; webhooks will verify.
- Exit `1` — `CachingBodyReader` is absent. Run `mix mailglass.install` to fix.
- Exit `2` — Cannot diagnose; `endpoint.ex` was not found or the OTP app is not detectable.

If exit 1, run `mix mailglass.install` to wire the parser automatically, then re-run `mix mailglass.doctor` to confirm exit 0. An unwired `CachingBodyReader` produces silent 401 failures on every incoming webhook — signature verification cannot proceed without the raw request bytes.

For the full webhook setup walkthrough, see [Webhooks](./webhooks.md).

## Webhook secret provisioning and rotation

Provision the webhook verification secret from your provider's dashboard at deploy time. For Postmark, this is the Basic Auth user and password. For SendGrid, it is the Event Webhook public key. For Mailgun, it is the Webhook Signing Key.

Set the credential as an environment variable and reference it in your mailglass config — never hardcode secrets in `config/prod.exs`.

To rotate a webhook secret:

1. Obtain the new credential from the provider dashboard.
2. Update the environment variable in your deployment environment.
3. Redeploy.
4. Run `mix mailglass.doctor` to confirm the wiring is intact.

For setup details and provider-specific config keys, see [Webhooks](./webhooks.md). For incident recovery when webhooks stop verifying after a rotation, see the `guides/webhook-troubleshooting.md` runbook in the repository.

## Oban queue sizing

`Mailglass.Outbound.Worker` runs under Oban when you call `deliver_later/2`. Queue throughput depends on the `:concurrency` setting in your Oban config. The relevant queue is named `:mailglass`:

```elixir
config :my_app, Oban,
  queues: [mailglass: 10]
```

A concurrency of `10` is a conservative starting point for moderate send volume. Increase it if deliveries lag under load; decrease it if you are rate-limited by your ESP. Monitor the queue depth with your existing Oban instrumentation.

If you are not using Oban (i.e., you only call `deliver/2`), this section does not apply — `deliver/2` is synchronous and bypasses the job queue entirely.

For authoring mailables and choosing between `deliver/2` and `deliver_later/2`, see [Authoring Mailables](./authoring-mailables.md).

## Per-tenant adapter routing

If your application routes email through different ESPs per tenant — for example, one tenant on Postmark and another on SendGrid — implement the `c:Mailglass.Tenancy.resolve_outbound_adapter_ref/1` callback in your tenancy module. It receives a context map (`%{tenant_id, message, mode}`) and returns `{:ok, adapter_ref}` or `:default`:

```elixir
defmodule MyApp.Tenancy do
  @behaviour Mailglass.Tenancy

  @impl true
  def resolve_outbound_adapter_ref(%{tenant_id: tenant_id}) do
    {:ok, adapter_ref_for(tenant_id)}
  end
end
```

Without this callback, all tenants share the single adapter configured under `config :mailglass, adapter:`.

For the full callback interface, named adapter ref setup, and config examples, see [Multi-Tenancy](./multi-tenancy.md).

## Suppression strategy

The suppression list blocks delivery to opted-out, hard-bounced, and tenant-excluded recipients. When delivery is blocked, mailglass raises `Mailglass.SuppressedError` with a `:type` of `:address`, `:domain`, or `:address_stream`. This is a permanent policy block — never retryable.

Confirm your application handles `Mailglass.SuppressedError` without treating it as an unexpected failure: a suppression hit is expected behavior, not a bug.

For RFC 8058 List-Unsubscribe wiring and suppression record management, see [Unsubscribe](./unsubscribe.md). The `Mailglass.Suppression` module exposes functions for querying and managing suppression records programmatically.

## Telemetry and alerting

mailglass emits telemetry on these event families:

- `[:mailglass, :outbound, :dispatch, :start | :stop | :exception]`
- `[:mailglass, :render, :message, :start | :stop | :exception]`
- `[:mailglass, :webhook, :ingest, :start | :stop | :exception]`
- `[:mailglass, :webhook, :reconcile, :start | :stop | :exception]`

Before going live, attach at minimum:

- An `:exception` handler on `:outbound, :dispatch` to track delivery failures.
- An `:exception` handler on `:webhook, :reconcile` to catch reconciliation failures.

PII is never emitted in telemetry metadata by convention — `:to`, `:from`, `:body`, `:subject`, and `:recipient` are not present in any metadata map.

For the full telemetry reference including all metadata keys, see [Telemetry](./telemetry.md).
