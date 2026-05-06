# Postmark Ingress

Use the README as the primary setup lane. This guide keeps the Postmark-specific
details focused: raw-body verification, configuration, duplicate behavior, and
the exact receive truth the package stores.

## Mount Path

Mount the package-local plug on one obvious route:

```elixir
forward "/inbound/:tenant_id/postmark",
  MailglassInbound.Ingress.Plug,
  provider: :postmark,
  router: MyApp.MailglassInboundRouter
```

The ingress plug is verify-first:

1. read exact request bytes from `conn.private[:raw_body]`
2. verify Postmark Basic Auth and optional IP allowlist
3. resolve tenant scope
4. normalize into `%MailglassInbound.InboundMessage{}`
5. persist one canonical row plus one raw evidence row
6. dispatch mailbox execution only for newly inserted records

## Plug.Parsers Wiring

Your endpoint must wire the package body reader:

```elixir
plug Plug.Parsers,
  parsers: [:json],
  pass: ["*/*"],
  json_decoder: Jason,
  body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}
```

Without that `body_reader`, the ingress plug returns a config error instead of
attempting verification on reconstructed payload state.

## Configuration

Configure the Postmark verification seam through `:mailglass_inbound`:

```elixir
config :mailglass_inbound, :postmark,
  basic_auth: {"postmark-user", "postmark-pass"},
  ip_allowlist: []
```

Basic auth is the default protection seam. IP allowlisting is optional and
fails closed when enabled.

## Persistence Semantics

A verified inbound request writes two truths:

- one canonical normalized row in `mailglass_inbound_records`
- one linked raw evidence row in `mailglass_inbound_evidence`

The raw evidence row carries payload JSON, selected raw headers, verification
facts, parse warnings, and attachment blobs. `raw_mime` stays `nil` unless
Postmark provides a trustworthy raw artifact directly. The package does not
reconstruct raw MIME from parsed fields.

If the record is new and the router finds a mailbox, execution is dispatched
after persistence commits. Oban-backed execution is the durable path. Without
Oban, Task.Supervisor fallback is bounded best-effort only.

## Route Compatibility

The route compatibility contract stays narrow:

- mailbox matching is evaluated against the stored canonical record
- `:no_match` remains explicit and non-exceptional
- duplicate ingress does not create new routing or replay state

## Duplicate Handling

Postmark retries and manual retries collapse on the canonical idempotency
anchor:

`(tenant_id, provider, provider_message_id)`

The plug returns an explicit `duplicate` success outcome instead of pretending a
new inbound receive occurred, and it does not dispatch mailbox execution again.

## Replay Honesty

Replay operates on stored canonical plus raw evidence truth. It is not a fresh
provider receive, it does not silently reroute to a different mailbox, and it
remains an internal replay recovery path rather than a public API.
