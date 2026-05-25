# Mailgun Ingress

This guide assumes you have completed the [inbound-install.md](inbound-install.md) setup.
It covers only the Mailgun-specific configuration: mounting the ingress route, configuring
your signing key, understanding the two payload modes, and what the package does with each
verified request.

## Mount Path

Mount the ingress plug on a dedicated Mailgun route in your Phoenix router:

```elixir
forward "/inbound/:tenant_id/mailgun",
  MailglassInbound.Ingress.Plug,
  provider: :mailgun,
  router: MyApp.MailglassInboundRouter
```

The ingress plug is verify-first:

1. read the exact request bytes from `conn.private[:raw_body]`
2. verify the HMAC-SHA256 signature triple from the flat form fields
3. reject replays (return `200` — see Replay Protection below)
4. resolve tenant scope
5. normalize into `%MailglassInbound.InboundMessage{}`
6. persist one canonical row plus one raw evidence row
7. dispatch mailbox execution only for newly inserted records

## Plug.Parsers Wiring

Your endpoint must include the caching body reader from the install guide:

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Jason,
  body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}
```

Without this `body_reader`, verification fails immediately — the raw bytes that
Mailgun signs are not available for HMAC computation.

## Mailgun Route Setup

In the Mailgun dashboard, configure an inbound route to forward received mail to your endpoint:

1. Navigate to **Receiving → Routes → Create Route**.
2. Set a **filter expression** — for example:
   - Match a specific recipient: `match_recipient("support@mg.example.com")`
   - Catch all: `match_all()`
3. Set the **action** to Forward with your endpoint URL:
   `https://your-app.example.com/inbound/YOUR_TENANT_ID/mailgun`
4. Save the route.

### Inbound Domain and MX Records

Mailgun inbound operates on a **sending subdomain**, not your primary domain. The
conventional subdomain is `mg.example.com` — you configure this in the Mailgun dashboard
under **Sending → Domains** and then set MX records on `mg.example.com`, not on
`example.com` itself.

Attempting to use your main domain's MX records for Mailgun inbound will not work. Use the
`mg.` subdomain (or whichever subdomain you configured in Mailgun) consistently in your
Route filter expressions and forward actions.

## Configuration

Add the Mailgun signing key to your application config:

```elixir
# config/runtime.exs
config :mailglass_inbound, :mailgun,
  signing_key: System.get_env("MAILGUN_WEBHOOK_SIGNING_KEY")
```

**Where to find the signing key:** Mailgun Dashboard → **Settings → API Security →
HTTP Webhook Signing Key** (labeled "Webhook Signing Key", distinct from your API key).

### Optional Tuning Knobs

```elixir
config :mailglass_inbound, :mailgun,
  signing_key: System.get_env("MAILGUN_WEBHOOK_SIGNING_KEY"),
  # How far in the past a timestamp is tolerated (default: 300 seconds / 5 minutes)
  timestamp_tolerance_seconds: 300,
  # How far in the future a timestamp is tolerated (default: 60 seconds)
  future_skew_seconds: 60,
  # How long replay tokens are retained in the cache (default: 28800 seconds / 8 hours)
  replay_cache_ttl_seconds: 28_800
```

The defaults match Mailgun's documented behavior and are suitable for production use.

## Signing Key Rotation

To rotate the Mailgun webhook signing key:

1. Generate a new signing key in the Mailgun dashboard.
2. Update `signing_key` in your config and redeploy.

During deployment, Mailgun's 5-minute timestamp tolerance means requests signed with the
old key continue to pass verification as long as they arrive within 300 seconds of the
timestamp. There is no downtime gap during key rotation.

## Verification

Mailgun inbound requests carry three flat form fields used for HMAC verification:

| Field | Description |
|---|---|
| `timestamp` | Unix timestamp (integer, as a string) when Mailgun generated the request |
| `token` | Random 50-character nonce unique to this delivery attempt |
| `signature` | HMAC-SHA256 of `timestamp <> token` hex-encoded lowercase |

The verification algorithm:

1. Compute `HMAC-SHA256(signing_key, timestamp <> token)`.
2. Compare the result (hex-encoded, lowercase) to `signature` using a constant-time comparison.
3. Reject the request if the timestamp is more than `timestamp_tolerance_seconds` in the past
   or more than `future_skew_seconds` in the future.

**Important:** Mailgun inbound uses **flat form fields**, not the nested JSON
`%{"signature" => %{...}}` envelope that Mailgun outbound webhooks use. The signing input
is a direct string concatenation of `timestamp` and `token`, not a JSON document.

## Replay Protection

After a request passes HMAC and timestamp verification, the `token` field is checked against
an in-memory replay cache. If the same token has already been seen:

- The plug returns `200 OK` immediately (a no-op).
- No second `InboundRecord` is created.
- No mailbox execution is triggered.

The response is `200`, not `401`. This is deliberate: Mailgun retries on non-200 responses,
which would create an infinite retry loop for a request the system has already processed.
Returning `200` signals to Mailgun that the delivery succeeded.

The replay cache retains tokens for `replay_cache_ttl_seconds` (default: 8 hours). Tokens
that arrive after the TTL expires are treated as new deliveries.

## Two Payload Modes

Mailgun delivers inbound mail in one of two formats, detected automatically by the plug:

### Raw MIME Mode

When the Mailgun route action includes the **raw MIME** option (the request carries a
`body-mime` field), the plug parses the raw MIME bytes through the built-in MIME parser.
This mode produces higher-fidelity normalization: attachment content-types, structured
headers, and multi-part boundaries are all resolved from the original MIME structure.

### Parsed Mode (Default)

When the Mailgun route sends parsed fields (no `body-mime` field), the plug normalizes
from Mailgun's flat form fields:

- `body-plain` / `stripped-text` → `text_body`
- `body-html` / `stripped-html` → `html_body`
- `message-headers` (JSON-encoded header pairs) → structured `headers` map
- `recipient` → `envelope_recipient`
- `from`, `to`, `cc`, `bcc`, `reply-to` → address lists

No adopter configuration is needed to select a mode — the plug detects it from the
presence of the `body-mime` field in the request.

## Persistence Semantics

A verified Mailgun request writes two records before mailbox execution:

- one canonical normalized row in `mailglass_inbound_records`
- one linked raw evidence row in `mailglass_inbound_evidence`

The evidence row carries the full raw form payload, selected request headers,
verification facts, parse warnings, and attachment blobs. If raw MIME mode was used,
the evidence row also stores the original MIME bytes.

Duplicate requests (same `tenant_id`, `provider`, and `provider_message_id`) collapse
on the canonical row — no second record is created and no second mailbox execution is
dispatched.

Mailbox execution is dispatched after persistence commits. The Oban-backed path is the
durable route. Without Oban, `Task.Supervisor` fallback is bounded best-effort only —
no automatic retry on execution failure.
