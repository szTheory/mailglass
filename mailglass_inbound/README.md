# MailglassInbound

`mailglass_inbound` is the inbound sibling package for Mailglass. This README
is the canonical adoption lane for the shipped inbound slice: install the
package manually, wire the endpoint/body-reader path explicitly, mount the
provider plugs you need, choose the async execution mode you want, and verify
the contract with the package test lanes.

## Stable Package Surface

The stable inbound package contract is intentionally narrow:

- `MailglassInbound`
- `MailglassInbound.InboundMessage`
- `MailglassInbound.Ingress.Plug`
- `MailglassInbound.Ingress.CachingBodyReader`
- `MailglassInbound.Router`
- `MailglassInbound.Mailbox`

Use [`docs/api_stability.md`](docs/api_stability.md) as the canonical inventory
for what is stable, what is internal, and what is still deferred.
Stable inventoried surfaces require a deprecation bridge or major-version
change before semantic breakage; internal/deferred surfaces may change without
deprecation even when reachable or documented for troubleshooting.

## Testing Helpers

The package ships four testing helpers in `lib/` so you can drive and assert
inbound flows in your own suite:

- `MailglassInbound.Fixtures` — build a canonical `%MailglassInbound.InboundMessage{}`
  or raw provider payloads that round-trip through the real provider parser.
- `MailglassInbound.Test.Ingress` — drive the real synchronous persist + route +
  execute path and capture the outcome in your test process.
- `MailglassInbound.TestAssertions` — `assert_inbound_received/0,1`,
  `assert_inbound_accepted/0`, `assert_inbound_routed_to/1`, and friends.
- `MailglassInbound.MailboxCase` — an `ExUnit.CaseTemplate` you `use` that imports
  `TestAssertions`, checks out an Ecto sandbox on your configured repo, and sets
  tenancy. Configure your repo first: `config :mailglass_inbound, :repo, MyApp.Repo`.

```elixir
defmodule MyApp.WelcomeMailboxTest do
  use MailglassInbound.MailboxCase, async: false

  test "accepts a welcome message" do
    message = Fixtures.build_inbound_message(subject: "Welcome")

    # Drive routing through your compiled `use MailglassInbound.Router` module
    # (the same router your endpoint mounts) via the `:router` option.
    {:ok, %{outcome: %{outcome: :accept}, route: %{mailbox: MyApp.WelcomeMailbox}}} =
      Test.Ingress.receive_inbound(message, router: MyApp.MailglassInboundRouter)

    # ONE assertion per drive: each `assert_inbound_*` reads the captured tuple
    # with `assert_received`, which CONSUMES it from the process mailbox. To run
    # a second assertion, drive a second message (with a distinct
    # `provider_message_id` so it is a fresh receive, not a deduped one).
    assert_inbound_received(subject: "Welcome")
  end
end
```

## Current package compatibility

Inbound setup is manual in this phase. There is no generated setup path for
`mailglass_inbound`, so adopters should wire the package explicitly.

### 1. Add the dependency and fetch deps

```elixir
defp deps do
  [
    {:mailglass_inbound, "~> 2.3"},
    {:mailglass, "~> 2.6"},
    {:oban, "~> 2.21"}
  ]
end
```

If you do not want durable background execution yet, omit `{:oban, "~> 2.21"}`
and the package will use the bounded fallback described below.

Fetch dependencies:

```bash
mix deps.get
```

### 2. Run the inbound migrations

`mailglass_inbound` persists canonical receive truth, raw evidence, and
append-only execution lineage. Run the package migrations in the host app
before mounting ingress:

```bash
mix ecto.migrate
```

### 3. Wire `Plug.Parsers` with the package body reader

Postmark verification requires the exact request bytes. SendGrid raw MIME
delivery does not need the cached raw body, but the shared ingress path should
still be wired once at the endpoint:

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Jason,
  body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}
```

Without that `body_reader`, the Postmark path fails closed with
`:webhook_caching_body_reader_missing`.

### 4. Define the router and mailboxes

```elixir
defmodule MyApp.MailglassInboundRouter do
  use MailglassInbound.Router

  route MyApp.Mailboxes.SupportMailbox, recipient: "support@example.com"
end
```

Mailboxes implement one stable callback:

```elixir
defmodule MyApp.Mailboxes.SupportMailbox do
  @behaviour MailglassInbound.Mailbox

  @impl true
  def process(message) do
    _ = message
    :accept
  end
end
```

Supported outcomes are `:accept`, `:ignore`, `{:reject, reason}`, and
`{:bounce, reason}`.

### 5. Mount the provider ingress paths

Mount one obvious route per provider you are using:

```elixir
forward "/inbound/:tenant_id/postmark",
  MailglassInbound.Ingress.Plug,
  provider: :postmark,
  router: MyApp.MailglassInboundRouter

forward "/inbound/:tenant_id/sendgrid",
  MailglassInbound.Ingress.Plug,
  provider: :sendgrid,
  router: MyApp.MailglassInboundRouter
```

The plug verifies first, resolves the tenant, normalizes into
`%MailglassInbound.InboundMessage{}`, and persists canonical and raw evidence
rows before mailbox execution is dispatched for newly inserted records.

### 6. Configure each provider

```elixir
config :mailglass_inbound, :postmark,
  basic_auth: {"postmark-user", "postmark-pass"},
  ip_allowlist: []

config :mailglass_inbound, :sendgrid,
  basic_auth: {"sendgrid-user", "sendgrid-pass"}
```

Postmark uses shared-secret basic auth plus optional IP allowlisting. SendGrid
ships shared-secret basic auth only in this slice.

### 7. Choose the async execution mode

Oban-backed execution is the durable path. When Oban is present, new matched
records are enqueued through an internal worker after persistence commits.

Task.Supervisor fallback is bounded best-effort only. When Oban is absent, the
package starts a supervised background task with no durable enqueue and no
automatic retry. Recovery after node loss or shutdown depends on replay or operator action
over the stored receive truth.

You may force fallback mode explicitly:

```elixir
config :mailglass_inbound, :async_adapter, :task_supervisor
```

The public contract does not include Oban job shapes, queue names, worker
modules, or replay orchestration details.

### 8. Follow the same canonical path into operations, testing, and compatibility

After wiring inbound, continue through the matching deep-dive guides that stay
subordinate to this README path:

- operator command semantics:
  [`docs/inbound-operator.md`](docs/inbound-operator.md)
- testing harness, process-local assertion behavior, and one-assertion-per-drive:
  [`docs/inbound-testing.md`](docs/inbound-testing.md)
- compatibility and deprecation posture for stable versus internal/deferred
  inbound surfaces:
  [`../guides/compatibility-and-deprecations.md`](../guides/compatibility-and-deprecations.md)

## Provider Notes

Keep the README as the primary setup path, then use the focused provider guides
for provider-specific caveats:

- [`docs/postmark_ingress.md`](docs/postmark_ingress.md) for raw-body
  verification, duplicate behavior, and Postmark-specific persistence notes
- [`docs/sendgrid_ingress.md`](docs/sendgrid_ingress.md) for raw MIME delivery,
  duplicate fingerprinting, and replay/recovery posture

## Receive, Duplicate, And Replay Truth

The package stores two kinds of truth:

- canonical normalized rows for stable routing and mailbox inputs
- raw evidence for provider payloads, raw MIME, verification facts, parse
  warnings, and replay support

Fresh ingress persists canonical plus raw evidence truth before any mailbox
execution is dispatched. Provider retries are acknowledged from receive truth;
mailbox outcomes do not drive provider retry semantics.

Duplicate fresh ingress is explicit and provider-specific:

- Postmark collapses on `(tenant_id, provider, provider_message_id)`
- SendGrid collapses on `(tenant_id, provider, raw_mime_fingerprint)`

Replay is a recovery operation over stored canonical plus raw evidence truth.
It is not a fresh provider receive, it does not silently reroute to a different
mailbox, and it is not a public API in this phase.

## Verification Commands

Recommended package proof lanes after wiring the package:

```bash
mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors
mix test test/mailglass_inbound/ingress/plug_test.exs test/mailglass_inbound/replay_test.exs --warnings-as-errors
```

Those lanes prove the package docs, duplicate handling, async ingress
acknowledgment, replay posture, and stability claims stay aligned with shipped
behavior.

## Deferred Beyond This Slice

These capabilities remain intentionally out of the stable inbound contract:

- a publicly stable replay/command-surface API
- an operator dashboard for inbound receive or replay flows
- direct worker contracts, queue configuration, or Oban job return values
- providers beyond Postmark and SendGrid
- matcher expansion beyond recipient, subject, and headers
