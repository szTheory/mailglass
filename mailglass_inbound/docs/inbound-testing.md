# mailglass_inbound Testing Guide

This guide assumes you have completed [inbound-install.md](inbound-install.md)
setup. It covers every tool `mailglass_inbound` ships for testing inbound flows:
the `MailboxCase` template, all assertion styles, `Test.Ingress` for driving the
real path, `Fixtures` for building messages without fixtures on disk, and a
StreamData property pattern for proving idempotency convergence.

## MailboxCase setup

`MailglassInbound.MailboxCase` is the `ExUnit.CaseTemplate` you `use` for
inbound mailbox tests. It wires the Ecto sandbox, stamps tenancy, and imports
`TestAssertions` so assertions are available without an explicit `import`.

```elixir
defmodule MyApp.Mailboxes.SupportMailboxTest do
  use MailglassInbound.MailboxCase, async: false

  # TestAssertions, Fixtures, and Test.Ingress are imported/aliased automatically.
  # Write your tests here.
end
```

### Why `async: false` is required

`MailboxCase` checks out an Ecto sandbox in shared mode and resets ETS-backed
state (the SES cert cache, the S3 fetcher seam) in its `setup` callback. Both
are process-global. Running `async: true` MailboxCase tests concurrently causes
non-deterministic sandbox ownership conflicts and shared-state bleed across
tests.

The rule is absolute: **always `use MailglassInbound.MailboxCase, async: false`**.

### The `:router` option

Pass the same router module your endpoint mounts. `Test.Ingress` uses it to
resolve routes through the compiled route data:

```elixir
Test.Ingress.receive_inbound(message, router: MyApp.MailglassInboundRouter)
```

### What MailboxCase provides

- `import MailglassInbound.TestAssertions` — all assertion macros in scope
- `alias MailglassInbound.{Fixtures, Test}` — `Fixtures.build_*` and
  `Test.Ingress.receive_*` without the full module prefix
- Ecto sandbox checkout on the repo configured as `config :mailglass_inbound, :repo`
- `Mailglass.Tenancy.put_current("test-tenant")` (override with `@tag tenant: "acme"`)
- SES cert cache reset between tests
- `on_exit` sandbox teardown

### Supported tags

| Tag | Effect |
| --- | ------ |
| `@tag tenant: "acme"` | Override the default `"test-tenant"` |
| `@tag tenant: :unset` | Disable tenancy stamping for this test |
| `@tag async: false` | Always set — sandbox is in shared mode |

## Test.Ingress: driving the real path

`MailglassInbound.Test.Ingress` drives the **real** synchronous persist + route
+ execute write path and captures the outcome in the current test process. It is
the inbound analog of outbound's `Fake.Storage` → `{:mail, _}` → assertion
triangle.

### receive_inbound/2

Use this entry point when you have a code-built `%InboundMessage{}` (typically
from `Fixtures.build_inbound_message/1`) and want to drive routing through your
compiled router:

```elixir
{:ok, result} = Test.Ingress.receive_inbound(message, router: MyApp.MailglassInboundRouter)
```

The return shape is:

```elixir
{:ok, %{
  message: %MailglassInbound.InboundMessage{},
  outcome: %{outcome: :accept},   # or :ignore / :reject / :bounce / :no_match
  route:   %{status: :matched, mailbox: MyApp.Mailboxes.SupportMailbox},
  persisted: %{}
}}
```

After `receive_inbound/2` returns, the capture tuple
`{:inbound, message, outcome, route}` is in the current test process mailbox,
ready for `assert_inbound_*` assertions.

### receive_provider_payload/3

Use this entry point when you want to exercise the **real** provider
`verify!`/`normalize` seam end to end — the same path the production ingress
plug drives:

```elixir
payload = Fixtures.build_postmark_payload(subject: "Hello")

{:ok, result} = Test.Ingress.receive_provider_payload(
  :postmark,
  payload,
  config: %{basic_auth: {"user", "pass"}},
  headers: [{"authorization", "Basic dXNlcjpwYXNz"}],
  router: MyApp.MailglassInboundRouter
)
```

For `:sendgrid`, `:mailgun`, and `:ses`, the fixture self-signs against
documented default credentials, so `receive_provider_payload/3` works with no
extra `:config` option — the driver defaults to the fixture's own config. For
`:postmark`, supply a matching `config:` and `headers:` pair because the
Postmark fixture carries no auth.

### The one-assertion-per-drive rule

> **The most common footgun in inbound testing.**

Each `assert_inbound_*` call reads the captured `{:inbound, _, _, _}` tuple
from the test process mailbox using `assert_received`, which **consumes** the
tuple. After the first assertion the tuple is gone.

If you need to make a second assertion about the same message, drive a second
call to `receive_inbound/2` or `receive_provider_payload/3` with a distinct
`provider_message_id` (so the persist layer sees a fresh message, not a
duplicate). Replaying the same `provider_message_id` returns `{:ok, %{status:
:skipped}}` and inserts no new capture.

```elixir
# Correct: one assertion per drive
{:ok, _} = Test.Ingress.receive_inbound(message, router: router)
assert_inbound_received(subject: "Hello")  # consumes the capture

# Wrong: the second assertion finds nothing
{:ok, _} = Test.Ingress.receive_inbound(message, router: router)
assert_inbound_received(subject: "Hello")
assert_inbound_accepted()  # FAILS — capture already consumed above

# Correct: drive two messages to make two assertions
msg1 = Fixtures.build_inbound_message(subject: "Hello")
msg2 = Fixtures.build_inbound_message(subject: "Hello")  # fresh provider_message_id

{:ok, _} = Test.Ingress.receive_inbound(msg1, router: router)
assert_inbound_received(subject: "Hello")

{:ok, _} = Test.Ingress.receive_inbound(msg2, router: router)
assert_inbound_accepted()
```

## assert_inbound_received: four matcher styles

`assert_inbound_received` is a macro with four calling styles. All styles
consume the oldest `{:inbound, _, _, _}` tuple from the process mailbox.

### Style 1: presence (bare call)

Assert that any inbound message was received. Use it when you are testing the
drive path itself, not a specific field value:

```elixir
assert_inbound_received()
```

### Style 2: keyword list

Assert that the received message matches a set of field-value pairs. Supported
keys are `:subject`, `:from`, `:to`, `:tenant`, `:provider`,
`:envelope_recipient`:

```elixir
assert_inbound_received(subject: "Re: ticket #42")
assert_inbound_received(from: "alice@example.com", subject: "Hello")
assert_inbound_received(tenant: "acme")
assert_inbound_received(provider: :postmark)
```

`:from` and `:to` match against a bare address string — pass the address itself,
not a struct:

```elixir
# Correct
assert_inbound_received(to: "support@example.com")

# Wrong — will fail with a clear error
assert_inbound_received(to: [%{address: "support@example.com"}])
```

### Style 3: struct/map pattern

Assert using a map pattern. The pattern is matched at compile time with
`assert_received`, so it is fast and precise:

```elixir
assert_inbound_received(%{subject: "Welcome"})
assert_inbound_received(%{tenant_id: "acme", provider: :postmark})
```

### Style 4: predicate function

Assert using a `fn/1` predicate. Use this when you need logic that keyword
matching cannot express:

```elixir
assert_inbound_received(fn msg ->
  String.starts_with?(msg.subject, "Re:") and msg.tenant_id == "acme"
end)

assert_inbound_received(fn msg -> length(msg.attachments) > 0 end)
```

A captured function reference (`&some_fun/1`) also works:

```elixir
assert_inbound_received(&valid_support_message?/1)
```

## assert_no_inbound_received

Asserts that **no** inbound capture arrived in this test process. Useful for
testing that a message was not routed when it should not have been:

```elixir
test "does not process messages from an unknown sender" do
  message = Fixtures.build_inbound_message(from: "unknown@spam.example")
  # Drive against a router with no matching route
  {:ok, %{outcome: %{outcome: :no_match}}} =
    Test.Ingress.receive_inbound(message, router: MyApp.MailglassInboundRouter)

  assert_no_inbound_received()
end
```

## Outcome assertions

Use outcome assertions to verify what the mailbox callback returned. Each
assertion reads the oldest unconsumed capture, so apply one assertion per drive:

```elixir
# Matches outcome == :accept
assert_inbound_accepted()

# Matches outcome == :reject
assert_inbound_rejected()

# Matches outcome == :ignore
assert_inbound_ignored()

# Matches outcome == :bounce
assert_inbound_bounced()
```

These match against the persisted `ExecutionRun.outcome` enum, not the raw
mailbox return atom, so an assertion can never drift from what was actually
written to the database.

## Routing assertions

Use routing assertions to verify which mailbox (or no mailbox) the message was
routed to:

```elixir
# Assert that the message matched a specific mailbox
assert_inbound_routed_to(MyApp.Mailboxes.SupportMailbox)

# Assert that no route matched
assert_inbound_no_match()
```

These also consume one capture each, so follow the one-assertion-per-drive rule.

## Fixtures

`MailglassInbound.Fixtures` builds inbound payloads entirely from code. There
are no `.eml` files on disk and no static fixture files to maintain — each
builder produces a value that round-trips through the real provider
`verify!`/`normalize` seam.

### build_inbound_message/1

Builds a canonical `%MailglassInbound.InboundMessage{}`. Use this with
`Test.Ingress.receive_inbound/2` when you do not need provider-level parsing:

```elixir
message = Fixtures.build_inbound_message(
  subject: "Invoice attached",
  from: "billing@vendor.example",
  to: "ap@myapp.example",
  tenant_id: "acme"
)
```

Supported options: `:tenant_id`, `:provider`, `:provider_message_id`,
`:message_id`, `:from`, `:to`, `:subject`, `:text_body`, `:html_body`,
`:envelope_recipient`.

Every builder defaults a unique `provider_message_id` per call, so multiple
fixtures built in the same test are distinct records.

### build_postmark_payload/1

Builds a raw Postmark inbound JSON body (a binary). Use with
`Test.Ingress.receive_provider_payload(:postmark, …)`:

```elixir
payload = Fixtures.build_postmark_payload(subject: "Support request")
```

Postmark is the one provider whose fixture does not carry auth. Supply a
matching `config:` and `headers:` pair to the driver:

```elixir
config  = %{basic_auth: {"user", System.fetch_env!("POSTMARK_INBOUND_PASS")}}
headers = [{"authorization", "Basic " <> Base.encode64("user:pass")}]

Test.Ingress.receive_provider_payload(:postmark, payload,
  config: config,
  headers: headers,
  router: MyApp.MailglassInboundRouter
)
```

### build_sendgrid_payload/1

Builds a SendGrid multipart-form payload self-signed against the documented
fixture credentials. Works with no extra options in tests:

```elixir
payload = Fixtures.build_sendgrid_payload(subject: "Weekly digest")

Test.Ingress.receive_provider_payload(:sendgrid, payload,
  router: MyApp.MailglassInboundRouter
)
```

To sign against your own credentials (e.g. testing key rotation):

```elixir
payload = Fixtures.build_sendgrid_payload(basic_auth: {"myuser", "mypass"})

Test.Ingress.receive_provider_payload(:sendgrid, payload,
  config: %{basic_auth: {"myuser", "mypass"}},
  router: MyApp.MailglassInboundRouter
)
```

### build_mailgun_payload/1

Builds a Mailgun multipart-params payload HMAC-signed against the documented
fixture signing key. Works with no extra options in tests:

```elixir
payload = Fixtures.build_mailgun_payload(subject: "Inbound from Mailgun")

Test.Ingress.receive_provider_payload(:mailgun, payload,
  router: MyApp.MailglassInboundRouter
)
```

### build_ses_sns_payload/1

Builds a valid X.509-signed SES SNS notification entirely from code. The
builder mints an ephemeral in-memory RSA-2048 keypair per call, primes the real
`CertCache` (no `:httpc` fetch), and primes the `S3Fetcher.Fake` with the raw
MIME body. Works with no extra options in tests when using `MailboxCase` (which
resets the cert cache between tests):

```elixir
payload = Fixtures.build_ses_sns_payload(subject: "SES inbound test")

Test.Ingress.receive_provider_payload(:ses, payload,
  router: MyApp.MailglassInboundRouter
)
```

If you use SES fixtures from a plain `ExUnit.Case` without `MailboxCase`, reset
the cert cache between tests to prevent cross-test state bleed:

```elixir
setup do: Mailglass.Webhook.Providers.SES.CertCache.reset()
```

### Why no .eml files

Code-built fixtures that round-trip through the real provider normalizer are
more faithful than static `.eml` files — they stay in sync with the parser
automatically and require no disk fixtures to maintain or rotate. Provider
fixture signing is ephemeral and per-call, so nothing sensitive is ever written
to disk.

## Idempotency property pattern

`mailglass_inbound` stores inbound records with a provider-specific unique index
(`tenant_id, provider, provider_message_id` for Postmark; `md5(raw_mime)` for
SendGrid, SES, and Mailgun). Replaying the same payload converges to one
`InboundRecord` and one fresh `ExecutionRun`.

The following pattern is the inbound analog of the outbound 1000-replay
convergence proof. It uses `StreamData` + `ExUnitProperties` to generate 1000
random scenarios and drive them against a real Postgres database:

```elixir
defmodule MyApp.InboundIdempotencyTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias MailglassInbound.Execution
  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Ingress.Persist

  @tenant_id "prop-test-tenant"
  @provider "postmark"

  setup do
    owner =
      Sandbox.start_owner!(MyApp.Repo,
        shared: true,
        ownership_timeout: 10 * 60_000
      )

    truncate_all()

    on_exit(fn -> Sandbox.stop_owner(owner) end)

    :ok
  end

  property "1000 replays converge to one InboundRecord per unique payload" do
    check all(
            payloads <- list_of(payload_gen(), min_length: 1, max_length: 10),
            replay_count <- integer(1..10),
            max_runs: 1000
          ) do
      truncate_all()

      for payload <- payloads, _ <- 1..replay_count do
        {:ok, persisted} = Persist.persist(handoff(payload), [])
        _ = Execution.execute(persisted, source: :fresh)
      end

      unique_count =
        payloads
        |> Enum.map(& &1["MessageID"])
        |> Enum.uniq()
        |> length()

      assert MyApp.Repo.aggregate(InboundRecord, :count) == unique_count

      # Filter to :fresh source only — the replay_runs table is shared with
      # ExecutionRun (both map to mailglass_inbound_replay_runs).
      fresh_count =
        MyApp.Repo.aggregate(
          from(r in ExecutionRun, where: r.source == :fresh),
          :count
        )

      assert fresh_count == unique_count
    end
  end

  defp payload_gen do
    gen all(msg_id <- member_of(["m1", "m2", "m3", "m4"])) do
      %{"MessageID" => msg_id, "From" => "a@b.test", "To" => "x@y.test"}
    end
  end

  defp handoff(%{"MessageID" => msg_id} = payload) do
    message = %InboundMessage{
      tenant_id: @tenant_id,
      provider: @provider,
      provider_message_id: msg_id,
      message_id: msg_id,
      envelope_recipient: payload["To"],
      from: [%{address: payload["From"]}],
      to: [%{address: payload["To"]}],
      subject: "Subject #{msg_id}",
      headers: %{},
      received_at: DateTime.utc_now()
    }

    %{tenant_id: @tenant_id, provider: @provider, message: message,
      evidence: %{raw_payload: payload}}
  end

  defp truncate_all do
    MyApp.Repo.query!("TRUNCATE TABLE mailglass_inbound_records CASCADE", [])
    MyApp.Repo.query!("TRUNCATE TABLE mailglass_inbound_replay_runs CASCADE", [])
  end
end
```

Key points for this pattern:

- Use `async: false` — the `TRUNCATE` between iterations deadlocks with a
  per-test transaction wrapper.
- Use `Sandbox.start_owner!/2` with `shared: true` and an extended
  `ownership_timeout` for 1000-iteration runs.
- Filter `ExecutionRun` to `where: r.source == :fresh` — the run table is
  shared with `ReplayRun` rows (both use `mailglass_inbound_replay_runs`).
- Drive `Execution.execute/2` directly, not `Execution.dispatch/2` — `dispatch`
  may spawn async Oban jobs, producing non-deterministic `ExecutionRun` counts.

## What's next

- [inbound-install.md](inbound-install.md) — if you haven't wired the package
  yet
- [inbound-routing-debug.md](inbound-routing-debug.md) — diagnosing matcher
  failures and common routing issues
- [inbound-operator.md](inbound-operator.md) — `mix mailglass.inbound.doctor`,
  replay, prune, and retention config for production operations
