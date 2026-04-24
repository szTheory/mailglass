# Mailglass Webhooks Guide

This guide walks through mounting Mailglass webhook ingest in your
Phoenix app. Mailglass ships first-party verifiers for Postmark (Basic
Auth) and SendGrid (ECDSA P-256); v0.5 adds Mailgun, SES, and Resend
behind the same internal `Mailglass.Webhook.Provider` behaviour.

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

## 2. Multi-tenant patterns (D-12)

Mailglass resolves the tenant AFTER the signature verifies (D-13
"verify-first, tenant-second"). Three resolver shapes ship:

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
  provider: :postmark | :sendgrid,
  conn: Plug.Conn.t(),
  raw_body: binary(),
  headers: [{name, value}],
  path_params: map(),
  verified_payload: nil  # reserved; v0.5 may set this
}
```

## 3. Telemetry recipes

Mailglass emits six webhook events. All metadata complies with the
D-23 whitelist — no `:ip`, `:user_agent`, `:remote_ip`, `:raw_body`,
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
`Mailglass.SignatureError.__types__/0` (closed set per D-21). Alert
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

### Recipe — auto-suppression on bounce/complaint (D-25)

Until v0.5 DELIV-02 ships first-class auto-suppression, attach a
telemetry handler on the ingest span:

```elixir
:telemetry.attach(
  "auto-suppress",
  [:mailglass, :webhook, :ingest, :stop],
  fn _event, _measurements, meta, _ ->
    # ingest meta carries `event_count` + `duplicate` — but not the
    # per-event type. For suppression decisions you need the per-event
    # normalize emit metadata:
    :ok
  end,
  nil
)

:telemetry.attach(
  "auto-suppress-normalize",
  [:mailglass, :webhook, :normalize, :stop],
  fn _event, _measurements, %{event_type: type, provider: provider}, _ ->
    if type in [:bounced, :complained, :unsubscribed] do
      # You'll need the recipient too — mailglass does NOT include it
      # in normalize metadata (D-23). Subscribe to the adopter's own
      # PubSub topic or query mailglass_events by (tenant_id, type) to
      # pull the recipient address, then:
      MyApp.Suppressions.maybe_add(provider, type)
    end
  end,
  nil
)
```

> **Note on recipient discovery.** Mailglass deliberately excludes the
> recipient email from telemetry metadata per D-23. Your
> auto-suppression handler can pull the recipient from the normalized
> `mailglass_events` row via the `:delivery_id` → `mailglass_deliveries`
> join. This is the v0.1 pattern; v0.5 ships first-class
> auto-suppression that reads the ledger internally.

## 4. IP allowlist (Postmark, opt-in per D-04)

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

## 5. Orphan reconciliation (Oban cron)

When a webhook arrives BEFORE the matching `Delivery` row commits
(empirical 5–30 s race for low-latency providers), mailglass inserts
the event with `delivery_id: nil + needs_reconciliation: true`.
`Mailglass.Webhook.Reconciler` (Oban worker) sweeps these orphans and
APPENDS a `:reconciled` event when the matching `Delivery` later
commits (D-18 — append, never UPDATE).

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

Call the mix tasks from system cron / Kubernetes CronJob:

```bash
*/5 * * * *  cd /app && mix mailglass.reconcile
0 4 * * *    cd /app && mix mailglass.webhooks.prune
```

Mailglass emits a single `Logger.warning` at app boot when `Oban` is
not loaded, pointing adopters here.

## 6. Webhook event retention (Pruner)

Three knobs in `Mailglass.Config :webhook_retention` (D-16):

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

## 7. Statement timeout runbook (D-29)

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
| 200 | Event persisted (or replay-duplicate structural no-op) |
| 401 | `%Mailglass.SignatureError{}` — one of 7 D-21 atoms |
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
