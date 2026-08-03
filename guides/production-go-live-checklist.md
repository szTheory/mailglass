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

## Durable async readiness

`Mailglass.Outbound.Worker` runs under Oban when you call `deliver_later/2`. Production must explicitly select the durable adapter and configure its only outbound queue, `:mailglass_outbound`. A concurrency of `10` is a conservative starting point for moderate send volume; adjust it for delivery lag and your ESP's rate limits.

Before routing live traffic, add this configuration and run the preflight from a booted release or IEx session:

```elixir
config :mailglass, async_adapter: :oban

config :my_app, Oban,
  queues: [mailglass_outbound: 10]

case Mailglass.Config.production_readiness() do
  :ok -> :ok
  {:error, %Mailglass.ConfigError{type: :invalid} = error} -> raise error
end
```

The readiness result is deliberately bounded: it returns `:ok` only when the selected default Oban instance advertises `mailglass_outbound`; otherwise it returns `{:error, %Mailglass.ConfigError{type: :invalid}}` with a non-PII `:reason_class`. It rejects the explicit `:task_supervisor` adapter because that development/test path is non-durable.

This preflight confirms producer configuration only. Phase 153 owns proof that an active consumer is polling the queue in a generated production host.

If you only call `deliver/2`, this section does not apply — `deliver/2` is synchronous and bypasses the job queue entirely.

For authoring mailables and choosing between `deliver/2` and `deliver_later/2`, see [Authoring Mailables](./authoring-mailables.md).

## Payload retention and reconciliation

Provider acceptance and Mailglass persistence are separate systems. Mailglass
uses an at-least-once boundary and records `:retryable`, `:terminal`, or
`:uncertain` outcomes. An uncertain outcome may already have reached the
provider: reconcile with provider evidence and correlation data; there is no
automatic resend.

Set a finite private-content policy appropriate to your support window. The
defaults are terminal/discarded/abandoned `14` days, uncertain `30` days,
legacy queued content `14` days, and one prune batch of `500` payloads:

```elixir
config :mailglass,
  outbound_payload_retention: [
    terminal_days: 14,
    uncertain_days: 30,
    legacy_days: 14,
    prune_batch_size: 500
  ]
```

Successful durable payloads are atomically scrubbed, preserving only a
non-content tombstone. Run the manual, Oban-independent operation for one
tenant at a time; `--tenant TENANT_ID` is mandatory and each invocation handles
at most one batch:

```bash
mix mailglass.outbound.payloads.prune --tenant TENANT_ID
```

For optional scheduling, use `Mailglass.Outbound.PayloadPrunerWorker` on
`:mailglass_maintenance` with exactly one `mailglass_tenant_id` argument. Do
not configure an all-tenant sweep or add maintenance work to
`:mailglass_outbound` delivery readiness.

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
