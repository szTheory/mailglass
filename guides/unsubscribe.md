# RFC 8058 Unsubscribe

This guide is the adopter contract for Mailglass one-click unsubscribe. It covers the config, router mount, read-only generator, built-in GET page, POST replay behavior, DKIM follow-up, and a safe `secret_key_base` rotation playbook.

## 1) Configure the compliance endpoint

Add the compliance subtree in `config/runtime.exs`:

```elixir
config :mailglass, :compliance,
  endpoint: MyAppWeb.Endpoint,
  host: "unsubscribe.example.com",
  scheme: "https",
  mount_path: "/mailglass/unsubscribe",
  previous_secrets: [],
  redirect: nil,
  lifecycle: MyApp.MailLifecycle
```

Key points:

- `endpoint` is optional. When omitted, Mailglass falls back to `Mailglass.Tracking.endpoint/0`.
- `host` must be the public unsubscribe origin. Mailglass rejects local, private, path-bearing, and malformed hosts.
- `mount_path` is the canonical absolute path prefix used in generated links.
- `previous_secrets` is the rotation escape hatch for old `secret_key_base` values.
- `redirect` affects GET only. POST one-click requests never redirect.
- `lifecycle` preserves the existing `Mailglass.Lifecycle` callback/config shape for
  bounded adopter work after committed one-click convergence; it does not extend the
  primary unsubscribe transaction.

## 2) Mount the router macro

Mount the built-in controller through `Mailglass.Router`:

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router
  import Mailglass.Router

  scope "/" do
    pipe_through :browser
    mailglass_router_routes "/mailglass"
  end
end
```

That macro expands to one GET route and one POST route:

- `GET /mailglass/unsubscribe/:token`
- `POST /mailglass/unsubscribe/:token`

Keep the macro path aligned with `mount_path`. `mailglass_router_routes "/mailglass"` and `mount_path: "/mailglass/unsubscribe"` are the matching default pair.

## 3) Use the generator as a checklist, not a code copier

Run the read-only checklist task:

```bash
mix mailglass.gen.unsubscribe
```

The task prints config, router, preflight, UAT, and DKIM instructions. It copies zero files. Re-running it should still copy zero files.

## 4) Understand GET vs POST behavior

Mailglass ships one controller for both mailbox-provider POSTs and user-visible browser GETs:

- `GET /mailglass/unsubscribe/:token` renders a built-in confirmation page by default.
- If `redirect` is configured, GET redirects to that path instead of rendering the library page.
- `POST /mailglass/unsubscribe/:token` is the RFC 8058 one-click endpoint. RFC 8058 requires the HTTPS POST and no redirect; it does not define Mailglass's response body.
- A first valid convergence, replay, concurrent replay, invalid/expired/missing token, and missing Delivery each return a byte-empty `200`. Mailglass owns the byte-empty `200` privacy compatibility contract.
- A genuine database/convergence failure returns a byte-empty `500`; it is never
  disguised as a privacy-preserving no-op.
- A valid POST converges to the canonical `:unsubscribed` event and immutable
  `:address_stream` suppression. The Delivery-derived normalized address and originating
  stream define its scope, so request data cannot widen it.
- Replays and concurrent POSTs converge on that same pair without duplicate durable
  facts. Effects run only for created convergence; replays do not emit effects.

Use the built-in page if you want a safe default. Use `redirect` only when your app owns the confirmation UI.

## 5) Use lifecycle hooks as compatible post-commit work

`lifecycle` modules retain the compatible `Mailglass.Lifecycle.handle_event/2`
signature. After the primary convergence commits, Mailglass calls
`handle_event(Ecto.Multi.new(), attrs)` only for a newly created convergence and
runs the returned Multi as a separate, best-effort transaction. Its failure is
logged and does not roll back the canonical event/suppression pair or change the
already-successful POST. Keep attrs bounded to domain facts; no token or message
content is forwarded.

```elixir
defmodule MyApp.MailLifecycle do
  @behaviour Mailglass.Lifecycle

  @impl true
  def handle_event(multi, %{event: :unsubscribed, tenant_id: tenant_id, delivery_id: delivery_id}) do
    Ecto.Multi.insert(
      multi,
      {:audit_unsubscribe, delivery_id},
      MyApp.UnsubscribeAudit.changeset(%MyApp.UnsubscribeAudit{}, %{
        tenant_id: tenant_id,
        delivery_id: delivery_id
      })
    )
  end
end
```

Do not rely on lifecycle work to co-commit with the unsubscribe pair. Mailglass
also performs its broadcast after commit and best-effort; created convergence runs
effects; replays do not.

## 6) Rotate `secret_key_base` without breaking in-flight links

`previous_secrets` exists for emergency or scheduled endpoint-secret rotation. Add the old raw `secret_key_base` values before switching the endpoint to the new secret:

```elixir
config :mailglass, :compliance,
  endpoint: MyAppWeb.Endpoint,
  host: "unsubscribe.example.com",
  scheme: "https",
  mount_path: "/mailglass/unsubscribe",
  previous_secrets: [
    System.fetch_env!("MAILGLASS_OLD_SECRET_KEY_BASE")
  ]
```

Rotation playbook:

1. Deploy with the new endpoint secret and the old secret in `previous_secrets`.
2. Confirm an old unsubscribe link still resolves.
3. Wait out your unsubscribe token lifetime, or at least the window in which old emails are still likely to be clicked.
4. Remove the old secret from `previous_secrets` in a later deploy.

This keeps old links valid while all newly generated links use the current secret.

## 7) UAT checklist

Run these checks before rollout:

1. Generate a real unsubscribe link from a bulk delivery.
2. Browser GET check: visit `GET /mailglass/unsubscribe/:token` and confirm the built-in page renders, or confirm the configured redirect lands on your app page.
3. One-click POST check: POST the real signed bulk-delivery link and confirm a byte-empty `200` without redirecting. Do not record the token or message content.
4. Replay POST check: repeat the same POST and confirm it still returns a byte-empty `200` and no duplicate effect.
5. Enforcement check: send a same-tenant, normalized-address, origin-stream bulk message through `Mailglass.Outbound`; preflight must block it. Verify transactional and unrelated-stream messages still pass. Keep evidence to bounded IDs and outcome facts, never the token or message content.
6. Generator check: rerun `mix mailglass.gen.unsubscribe` and confirm it still copies zero files.
7. DKIM check: inspect an actual delivered message and verify both `List-Unsubscribe` and `List-Unsubscribe-Post` appear in the DKIM `h=` list.

## 8) Troubleshooting

### User sees "unsubscribe token invalid"

- Confirm the route really is `GET /mailglass/unsubscribe/:token`.
- Confirm `mailglass_router_routes "/mailglass"` matches `mount_path: "/mailglass/unsubscribe"`.
- Confirm the token was generated by the same environment and host configuration that is serving the route.

### Old links broke after a deploy

- Add the previous raw `secret_key_base` values to `previous_secrets`.
- Re-test an old link before removing the legacy secret.

### Inbox UI does not show one-click unsubscribe

- Confirm the message stream is `:bulk`, or `:operational` with explicit opt-in.
- Confirm both unsubscribe headers are present.
- Confirm both headers are DKIM-signed in `h=`.
- Verify your ESP did not strip `List-Unsubscribe-Post`.

### POST created multiple unsubscribe rows

That is a bug. Mailglass is designed to converge replayed POSTs onto the same durable `:unsubscribed` event. Re-run the POST replay check and inspect event idempotency before rollout.
