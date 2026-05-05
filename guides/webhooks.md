# Mailglass Webhooks Guide

This guide walks through mounting Mailglass webhook ingest in your
Phoenix app. Mailglass ships first-party verifiers for Postmark (Basic
Auth), SendGrid (ECDSA P-256), and Mailgun (HMAC-SHA256 over the JSON
body's `signature.timestamp <> signature.token`). SES (RSA-signed SNS)
and Resend (Svix-style HMAC) are also shipped providers behind the same
`Mailglass.Webhook.Provider` behaviour.

## 1. Install + endpoint wiring

### Step 1 — Configure `Plug.Parsers` with mailglass's `CachingBodyReader`

Signature verification needs the raw request bytes. Plug parsers
consume the stream, so the reader must capture bytes before any JSON
decoder touches them:

```elixir
# lib/my_app_web/endpoint.ex
plug Plug.Parsers,
  parsers: [:json],
  pass: ["*/*"],
  json_decoder: Jason,
  body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []},
  length: 10_000_000   # 10 MB cap — SendGrid batches up to 128 events
                       # fit under 8 MB with 2 MB headroom.
```

The 10 MB cap is required for SendGrid — their batched event webhooks
can carry up to 128 events per POST.

> **Footgun.** `Plug.Parsers.MULTIPART` does NOT honor `:body_reader`
> (Plug issue #884). If you add `:multipart` to the parsers list for
> another route, those requests bypass mailglass's `CachingBodyReader`.
> Mount multipart under a separate `Plug.Parsers` pipeline.

### Step 2 — Mount the routes in your router

```elixir
# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use Phoenix.Router
  import Mailglass.Webhook.Router

  pipeline :mailglass_webhooks do
    plug :accepts, ["json"]
    # NO :browser, :fetch_session, :protect_from_forgery — webhooks
    # do not carry a session and do not participate in CSRF.
  end

  scope "/", MyAppWeb do
    pipe_through :mailglass_webhooks
    mailglass_webhook_routes "/webhooks"
  end
end
```

This generates two POST routes, each handled by
`Mailglass.Webhook.Plug`:

  * `POST /webhooks/postmark`
  * `POST /webhooks/sendgrid`

Mailgun, SES, and Resend stay off the default zero-arg mount. Opt in
explicitly:

```elixir
scope "/", MyAppWeb do
  pipe_through :mailglass_webhooks
  mailglass_webhook_routes "/webhooks", providers: [:postmark, :sendgrid, :mailgun, :ses, :resend]
end
```

That adds:

  * `POST /webhooks/mailgun`
  * `POST /webhooks/ses`
  * `POST /webhooks/resend`

### Step 3 — Configure provider credentials

```elixir
# config/runtime.exs
config :mailglass, :postmark,
  enabled: true,
  basic_auth:
    {System.fetch_env!("POSTMARK_WEBHOOK_USER"),
     System.fetch_env!("POSTMARK_WEBHOOK_PASS")}

config :mailglass, :sendgrid,
  enabled: true,
  public_key: System.fetch_env!("SENDGRID_WEBHOOK_PUBLIC_KEY"),
  timestamp_tolerance_seconds: 300
```

SendGrid's public key is base64-encoded **SPKI DER** (not PEM). Copy
it verbatim from the SendGrid Event Webhook security settings page.

### Mailgun setup

```elixir
config :mailglass, :mailgun,
  enabled: true,
  signing_key: System.fetch_env!("MAILGUN_WEBHOOK_SIGNING_KEY"),
  timestamp_tolerance_seconds: 28_800,
  future_skew_seconds: 300,
  replay_cache_ttl_seconds: 28_800
```

Mailgun signs the `"signature"` object embedded in the JSON payload.
Mailglass verifies `signature.timestamp <> signature.token` with your
`MAILGUN_WEBHOOK_SIGNING_KEY`, then reads the normalized event from the
payload's `"event-data"` object.

Mailgun replay tokens converge to HTTP `200` as an idempotent no-op,
not `401`. This is intentional: Mailgun retries non-`200` webhook
responses for hours, so duplicate tokens must stop retry amplification
without looking like a forged request.

### Amazon SES (via SNS)

AWS SES delivers webhook events through Amazon SNS HTTP subscriptions. SNS sends
`text/plain` POST requests signed with an RSA certificate. Mailglass verifies the
RSA signature, caches the X.509 certificate in ETS to avoid per-request network calls,
and automatically confirms SNS subscription handshakes.

> **SES is an explicit opt-in provider.** It does not appear in the default route
> surface. Add `:ses` to your `:providers` list when mounting webhook routes.

#### Setup

1. **Add `:ses` to your webhook route providers:**

   ```elixir
   mailglass_webhook_routes "/webhooks", providers: [:postmark, :sendgrid, :ses]
   ```

2. **Configure the SES provider** (optional — defaults are safe):

   ```elixir
   config :mailglass, :ses,
     cert_cache_ttl_seconds: 86_400   # cache X.509 certs for 24 hours (default)
   ```

3. **Create an SNS topic** in the AWS console and subscribe your endpoint:
   - Topic type: Standard
   - Subscription protocol: HTTPS
   - Endpoint: `https://your-app.example.com/webhooks/ses`

4. **Configure SES to publish to your SNS topic:**
   - For classic SES feedback notifications (bounces, complaints, deliveries):
     SES → Configuration → Verified identities → Notifications → Configure SNS Topic
   - For SES event publishing (full event lifecycle including open/click):
     SES → Configuration → Configuration sets → Event destinations → Add destination → SNS

Mailglass automatically handles the SNS `SubscriptionConfirmation` handshake after
your endpoint is reachable. No manual confirmation step is required.

> **Duplicate events:** SES feedback notifications and SES event publishing can both
> deliver bounce/complaint/delivery events to the same SNS topic. If you configure both
> sources pointing to the same topic, you will receive duplicate events per message.
> The `(provider, provider_event_id)` uniqueness constraint prevents duplicate rows in
> the event ledger, but each source still produces an ingest attempt. Point only one
> SES notification source at each SNS topic unless you intentionally want both signals.

#### Supported SES events

| SES event | Normalized type | Notes |
|-----------|----------------|-------|
| Bounce (Permanent, General) | `:bounced` | Hard bounce — triggers suppression |
| Bounce (Permanent, Suppressed) | `:rejected` | Already on suppression list |
| Bounce (Transient) | `:deferred` | Mailbox full or temporary error |
| Bounce (Undetermined) | `:deferred` | Conservative mapping |
| Complaint | `:complained` | Spam report |
| Delivery | `:delivered` | Accepted by recipient MTA |
| Send | `:sent` | Handed to provider (event publishing only) |
| Reject | `:rejected` | SES rejected before sending |
| Open | `:opened` | Requires open tracking enabled on config set |
| Click | `:clicked` | Requires click tracking enabled on config set |
| Rendering Failure | `:failed` | Template rendering error |
| DeliveryDelay | `:deferred` | Transient delivery delay |

### Resend setup

> **Resend is an explicit opt-in provider.** It does not appear in the default
> route surface. Add `:resend` to your `:providers` list when mounting webhook
> routes.

```elixir
mailglass_webhook_routes "/webhooks", providers: [:postmark, :sendgrid, :resend]
```

```elixir
config :mailglass, :resend,
  enabled: true,
  secret: System.fetch_env!("RESEND_WEBHOOK_SECRET"),
  timestamp_tolerance_seconds: 300
```

The secret must look like `whsec_...`. Mailglass verifies the Svix headers
`svix-id`, `svix-timestamp`, and `svix-signature` against the exact raw request
body, so `Mailglass.Webhook.CachingBodyReader` is required at the endpoint
boundary before JSON parsing happens.

Resend currently normalizes these event types into the public Mailglass event
taxonomy:

| Resend event | Normalized type |
|--------------|-----------------|
| `email.sent` | `:sent` |
| `email.delivered` | `:delivered` |
| `email.delivery_delayed` | `:deferred` |
| `email.bounced` | `:bounced` |
| `email.complained` | `:complained` |

## 2. Multi-tenant patterns

Mailglass resolves the tenant AFTER the signature verifies ("verify-first,
tenant-second"). Three resolver shapes ship:

### Strategy A — Single-tenant (default — zero config)

No setup. All events stamp `tenant_id: "default"` via
`Mailglass.Tenancy.SingleTenant`.

### Strategy B — URL prefix via `Mailglass.Tenancy.ResolveFromPath`

```elixir
config :mailglass, tenancy: Mailglass.Tenancy.ResolveFromPath
```

Mount with a `:tenant_id` path parameter:

```elixir
scope "/tenants/:tenant_id" do
  pipe_through :mailglass_webhooks
  mailglass_webhook_routes "/webhooks"
end
```

`POST /tenants/acme/webhooks/postmark` stamps
`tenant_id: "acme"`.

> **Composition is mandatory.** `Mailglass.Tenancy.ResolveFromPath`
> implements `resolve_webhook_tenant/1` only — its `scope/2` raises.
> To use ResolveFromPath for the full `Mailglass.Tenancy` contract,
> wrap it in your own module that implements `scope/2`:
>
>     defmodule MyApp.Tenancy do
>       @behaviour Mailglass.Tenancy
>       @impl Mailglass.Tenancy
>       def scope(query, _context), do: # ... WHERE tenant_id = ?
>       @impl Mailglass.Tenancy
>       defdelegate resolve_webhook_tenant(ctx),
>         to: Mailglass.Tenancy.ResolveFromPath
>     end
>
> Fails CLOSED on misuse (T-04-08 mitigation — forged `tenant_id`
> values only reach the data YOUR `scope/2` exposes).

### Strategy C — Custom behaviour callback

For Stripe-Connect-style (verified payload field) or Shopify-style
(per-shop header) strategies, implement the callback:

```elixir
defmodule MyApp.Tenancy do
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, _ctx), do: # your scope/2 impl

  @impl Mailglass.Tenancy
  def resolve_webhook_tenant(%{headers: headers}) do
    case List.keyfind(headers, "x-shopify-shop-domain", 0) do
      {_, shop_domain} -> {:ok, shop_domain}
      nil -> {:error, :missing_shop_domain}
    end
  end
end

config :mailglass, tenancy: MyApp.Tenancy
```

Returning `{:error, _}` raises
`%Mailglass.TenancyError{type: :webhook_tenant_unresolved}` and the
Plug returns HTTP 422. Returning `{:ok, tenant_id}` stamps the tenant
for the rest of the ingest pipeline (normalize → persist → broadcast).

### Context map the callback receives

```elixir
%{
  provider: :postmark | :sendgrid | :mailgun | :ses,
  conn: Plug.Conn.t(),
  raw_body: binary(),
  headers: [{name, value}],
  path_params: map(),
  verified_payload: nil  # reserved; v0.5 may set this
}
```

## 3. Telemetry recipes

Mailglass emits six webhook events. All metadata complies with the
telemetry PII policy — no `:ip`, `:user_agent`, `:remote_ip`, `:raw_body`,
`:headers`, `:body`, `:to`, `:from`, `:subject`, `:recipient`,
`:email` ever appears.

| Event path | Type | Stop metadata keys |
|------------|------|--------------------|
| `[:mailglass, :webhook, :ingest, :start | :stop | :exception]` | full span | `provider, tenant_id, status, event_count, duplicate, failure_reason, delivery_id_matched` |
| `[:mailglass, :webhook, :signature, :verify, :start | :stop | :exception]` | full span | `provider, status, failure_reason` |
| `[:mailglass, :webhook, :normalize, :stop]` | single emit | `provider, event_type, mapped` |
| `[:mailglass, :webhook, :orphan, :stop]` | single emit | `provider, event_type, tenant_id, age_seconds` |
| `[:mailglass, :webhook, :duplicate, :stop]` | single emit | `provider, event_type` |
| `[:mailglass, :webhook, :reconcile, :start | :stop | :exception]` | full span | `tenant_id, scanned_count, linked_count, remaining_orphan_count, status` |

### Recipe — alert on signature failure rate

```elixir
:telemetry.attach(
  "webhook-signature-failures",
  [:mailglass, :webhook, :signature, :verify, :stop],
  fn _event, _measurements, %{provider: provider, status: :failed, failure_reason: reason}, _ ->
    MyApp.Alerts.signature_failed(provider, reason)
  end,
  nil
)
```

`failure_reason` is always one of the seven atoms from
`Mailglass.SignatureError.__types__/0` (closed atom set). Alert
thresholds keyed to atoms are safe — no regex parsing needed.

### Recipe — distinguish retry storms from real traffic

```elixir
:telemetry.attach(
  "webhook-duplicate-rate",
  [:mailglass, :webhook, :duplicate, :stop],
  fn _event, _measurements, meta, _ ->
    MyApp.Metrics.increment("webhook.duplicate", tags: [provider: meta.provider])
  end,
  nil
)
```

Sustained elevated duplicate rate = the provider is retrying.
Investigate your endpoint's `p95` latency and 5xx rate; mailglass's
own 2 s statement timeout (see §7) bounds ingest latency.

### Auto-suppression behavior

Mailglass v0.3 projects suppressions automatically after a verified
webhook event is matched to a delivery:

- `:complained` -> address-wide suppression
- hard `:bounced` -> address-wide suppression
- `:unsubscribed` -> stream-scoped suppression using the delivery's stream
- `:deferred` -> no immediate suppression; repeated soft bounces are handled by the soft-bounce escalation policy

That projection happens inside mailglass. You do not need a telemetry
handler to create the suppression rows yourself.

Use telemetry for monitoring instead:

```elixir
:telemetry.attach(
  "webhook-auto-suppress-monitor",
  [:mailglass, :suppression, :auto_added, :stop],
  fn _event, _measurements, %{reason: reason, scope: scope, tenant_id: tenant_id}, _ ->
    MyApp.Metrics.increment("mailglass.suppression.auto_added",
      tags: [reason: reason, scope: scope, tenant_id: tenant_id]
    )
  end,
  nil
)
```

If you need to rebuild suppression state from the event ledger, run
`mix mailglass.suppressions.resync --tenant-id <tenant>`.

## 4. IP allowlist (Postmark, opt-in)

## Complaint suppressions are permanent

Mailglass treats complaint suppressions as durable compliance blocks.
You can delete source delivery rows or retained webhook payload data to
meet retention or erasure policy, but the complaint suppression row
itself remains in place to prevent future sends to that recipient.

This is intentional: GDPR or retention cleanup may erase the evidence
that originally produced the complaint, while the suppression record
continues to enforce the "do not send here again" contract.

Postmark publishes ~13 webhook IPs at
<https://postmarkapp.com/support/article/800-ips-for-firewalls>. To
enable:

```elixir
config :mailglass, :postmark,
  basic_auth: {"...", "..."},
  ip_allowlist: ["50.31.156.6/32", "50.31.156.77/32"]  # example
```

> **Forwarded IPs required.** If you enable `ip_allowlist`, you MUST
> configure `Plug.RewriteOn` (or equivalent proxy trust) so
> `conn.remote_ip` reflects the real client. Without
> `:trusted_proxies`, mailglass raises a `SignatureError` with atom
> `:malformed_header` and `context[:detail]` explaining the wiring
> gap. Adopter Logger parsing can key off the atom.

> **Postmark warns IPs change.** The allowlist is opt-in precisely
> because Postmark's own docs acknowledge origin IPs vary by retry
> attempt. If you enable the allowlist, monitor for
> `ip_disallowed` rate increases via the signature-failure telemetry
> handler above.

## 5. Orphan reconciliation (background-first maintenance)

When a webhook arrives BEFORE the matching `Delivery` row commits
(empirical 5–30 s race for low-latency providers), mailglass inserts
the event with `delivery_id: nil + needs_reconciliation: true`.
`Mailglass.Webhook.Reconciler.reconcile/2` sweeps these orphans and
APPENDS a `:reconciled` event when the matching `Delivery` later
commits (append-only ledger — never UPDATE). When Oban is installed,
the same canonical function also runs through the `Mailglass.Webhook.Reconciler`
worker on a background cron schedule.

Wire the cron in your Oban config:

```elixir
config :my_app, Oban,
  repo: MyApp.Repo,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"*/5 * * * *", Mailglass.Webhook.Reconciler},
       {"0 4 * * *", Mailglass.Webhook.Pruner}
     ]}
  ],
  queues: [
    mailglass_reconcile: 1,
    mailglass_maintenance: 1
  ]
```

### Running without Oban

Call the same maintenance tasks manually or from system cron / Kubernetes
CronJob:

```bash
*/5 * * * *  cd /app && mix mailglass.reconcile
0 4 * * *    cd /app && mix mailglass.webhooks.prune
```

Mailglass emits a single `Logger.warning` at app boot when `Oban` is
not loaded, pointing adopters here. `mix mailglass.reconcile` still
performs the orphan sweep in Oban-less installs and reports:

- `linked` — orphan events that were matched to a delivery and had a
  `:reconciled` audit event appended
- `still unmatched` — scanned orphans that remain unresolved after this
  sweep

This is a maintenance backfill path, not a per-delivery operator action.
The Admin UI keeps replay as the only delivery-detail repair action.

## 6. Webhook event retention (Pruner)

Three knobs in `Mailglass.Config :webhook_retention`:

```elixir
config :mailglass, :webhook_retention,
  succeeded_days: 14,      # default
  dead_days: 90,           # default
  failed_days: :infinity   # default — investigatable, never pruned
```

`:infinity` is a STRUCTURAL bypass — the Pruner returns `{:ok, 0}`
without issuing the DELETE. Zero DB cost for disabled classes.

### GDPR erasure is adopter-handled

Pruner DELETEs are retention-policy-driven (status + age), NOT
identity-driven. For targeted GDPR erasure, query directly:

```elixir
from(w in Mailglass.Webhook.WebhookEvent,
  where: fragment("?->>'to' = ?", w.raw_payload, ^email)
)
|> MyApp.Repo.delete_all()
```

The append-only `mailglass_events` ledger's SQLSTATE 45A01 trigger
prevents DELETE there — if you need to hard-purge an identity, you
delete the `mailglass_webhook_events` row (prunable) and leave the
ledger's event rows whose `:delivery_id` no longer resolves (they
become anonymous audit facts).

## 7. Statement timeout runbook

`Mailglass.Webhook.Ingest.ingest_multi/3` issues
`SET LOCAL statement_timeout = '2s'` and
`SET LOCAL lock_timeout = '500ms'` INSIDE its `Repo.transact/1`
closure (Pitfall 6 — outside a transaction these are no-ops). This
bounds the worst-case query latency and breaks the
provider-retry-storm feedback loop.

### Symptom: sustained 5xx under load

1. Provider retries amplify (Postmark retries 10× over 45 minutes).
2. Retries land on a slowing DB → more DB pressure → more 5xx.
3. Loop continues until DB CPU saturates.

### Mitigation (already in place)

The 2 s timeout means an unhealthy ingest fails fast with HTTP 500,
the provider backs off per its retry schedule, and the DB recovers.
No log spam, no unbounded latency growth.

### v0.5 escape-hatch: async ingest

If your normalize/ingest step starts taking >1 s consistently (large
adopter-extending normalizers, batched projection workloads), v0.5
ships `config :mailglass, :webhook_ingest_mode, :async` for opt-in
deferred processing via Oban. v0.1 keeps sync default for predictable
latency + zero ledger-loss risk.

## 8. Response code matrix

| Status | What it means |
|--------|---------------|
| 200 | Event persisted (or replay-duplicate structural no-op; Mailgun token replays stop here) |
| 401 | `%Mailglass.SignatureError{}` — one of the closed atom set (see `Mailglass.SignatureError.__types__/0`) |
| 422 | `%Mailglass.TenancyError{type: :webhook_tenant_unresolved}` — your resolver returned `{:error, _}` |
| 500 | `%Mailglass.ConfigError{}` — plug wiring gap or missing secret. Check Logger output. |

Pattern-match by struct + `:type` atom — NEVER by message string
(api_stability.md enforces the atom contract; messages are free to
change between minor versions).

## 9. Testing your integration

Mailglass ships a test case template and fixture helpers:

```elixir
defmodule MyAppWeb.WebhookIntegrationTest do
  use Mailglass.WebhookCase, async: false

  test "Postmark delivered webhook flow" do
    body = Mailglass.WebhookFixtures.load_postmark_fixture("delivered")
    conn = Mailglass.WebhookCase.mailglass_webhook_conn(:postmark, body)
    # Dispatch through your Phoenix endpoint OR call Mailglass.Webhook.Plug
    # directly, then assert against the PubSub broadcast:
    # Mailglass.WebhookCase.assert_webhook_ingested(%{provider: :postmark})
  end
end
```

`Mailglass.WebhookCase` provides:

  * `mailglass_webhook_conn/2,3` — builds a `%Plug.Conn{}` with the
    right signature header attached (Basic Auth for Postmark, ECDSA
    for SendGrid) and `conn.private[:raw_body]` mirrored.
  * `stub_postmark_fixture/1` + `stub_sendgrid_fixture/1` — load
    shipped JSON fixtures as raw bytes.
  * `assert_webhook_ingested/1,2` — asserts on the post-commit
    `{:delivery_updated, delivery_id, event_type, meta}` broadcast
    the Projector emits.
  * `freeze_timestamp/1` — for SendGrid timestamp-tolerance tests.

A fresh ECDSA P-256 keypair is minted per test setup and stashed in
context as `sendgrid_keypair`. No baked-in signatures on disk
(Pitfall 10).

---

*Last updated: 2026-04-24 (Phase 4 ships at v0.1).*
