# Testing

`guides/testing.md` is the canonical testing guide for mailglass adopters. Start
with the default Fake-adapter path, then opt into the narrower cross-process,
Oban, and PubSub lanes only when your test actually needs them.

## deliver/2 baseline

The stable `deliver/2` story is:

- `Mailglass.Adapters.Fake` in `config/test.exs`
- `import Mailglass.TestAssertions`
- process-local assertions that stay `async: true` safe by default

Minimal setup:

```elixir
# config/test.exs
config :mailglass,
  repo: MyApp.Repo,
  adapter: Mailglass.Adapters.Fake
```

```elixir
defmodule MyApp.UserMailerTest do
  use ExUnit.Case, async: true
  import Mailglass.TestAssertions

  test "delivers the welcome message" do
    %{email: "user@example.com"}
    |> MyApp.UserMailer.welcome()
    |> Mailglass.deliver()

    assert_mail_sent(subject: "Welcome", to: "user@example.com")
  end
end
```

For library tests and most adopter integration tests, prefer
`use Mailglass.MailerCase` instead of rebuilding the setup yourself. It checks
out the Fake adapter, stamps tenancy, subscribes to delivery events, and keeps
the common path honest.

Helper semantics in this baseline are exact:

- `assert_mail_sent/0,1` reads the current test process mailbox.
- `last_mail/0` reads Fake-backed delivery storage and does not consume the process mailbox.
- `wait_for_mail/1` waits up to a timeout for `{:mail, %Mailglass.Message{}}`
  to arrive and fails if nothing arrives before the timeout.

Use `last_mail/0` when you want to inspect the most recent delivered message
without consuming mailbox state. Use `wait_for_mail/1` when delivery may arrive
slightly later than the assertion site.

## deliver_later/2 baseline

The stable `deliver_later/2` default also starts with Fake assertions plus
`Mailglass.MailerCase`.

`Mailglass.MailerCase` sets
`Application.put_env(:mailglass, :async_adapter_impl, Mailglass.Outbound.AsyncAdapter.Inline)`
in setup, so the default library test path runs `deliver_later/2`
synchronously under the calling test's ownership. That keeps the baseline
deterministic and avoids optional dependencies.

Typical test:

```elixir
defmodule MyApp.UserMailerLaterTest do
  use Mailglass.MailerCase, async: true

  alias MyApp.UserMailer

  test "delivers later using the default inline adapter" do
    {:ok, _delivery} =
      %{email: "later@example.com"}
      |> UserMailer.welcome()
      |> Mailglass.deliver_later()

    assert_mail_sent(to: "later@example.com")
  end
end
```

If your app deliberately exercises cross-process dispatch instead of the inline
baseline, keep that as an explicit exception and follow the ownership guidance
below.

## Optional Oban lanes

Only document and support two Oban lanes:

- `:inline`
- `:manual`

Both are explicit `async: false` lanes. Both require the `oban_jobs` table to
exist in the test database.

`Mailglass.MailerCase` enforces the `async: false` requirement for any
`@tag oban: ...` test because Oban's testing mode is global process state.
`test/support/oban_helpers.ex` exists to ensure the `oban_jobs` table is present
for these tests.

Use `@tag oban: :inline` when you want Oban-backed `deliver_later/2` to execute
the job synchronously.

```elixir
defmodule MyApp.ObanInlineMailerTest do
  use Mailglass.MailerCase, async: false

  @tag oban: :inline
  test "runs the outbound worker inline" do
    {:ok, _delivery} =
      %{email: "inline@example.com"}
      |> MyApp.UserMailer.welcome()
      |> Mailglass.deliver_later()

    assert_mail_sent(to: "inline@example.com")
  end
end
```

Use `@tag oban: :manual` when you need queue assertions such as
`assert_enqueued/1` or explicit worker execution.

```elixir
defmodule MyApp.ObanManualMailerTest do
  use Mailglass.MailerCase, async: false
  use Oban.Testing, repo: MyApp.Repo

  @tag oban: :manual
  test "asserts on the queued job" do
    {:ok, _delivery} =
      %{email: "manual@example.com"}
      |> MyApp.UserMailer.welcome()
      |> Mailglass.deliver_later()

    assert_enqueued(worker: Mailglass.Outbound.Worker)
  end
end
```

If you are not explicitly asserting on Oban behavior, stay on the baseline and
avoid introducing the extra lane.

## Cross-process and browser ownership

Prefer explicit ownership transfer before any shared/global mode.

Recommended first:

- `Mailglass.Adapters.Fake.allow/2` for the specific process that needs access
- the normal Ecto SQL sandbox ownership-transfer pattern for browser, LiveView,
  or worker processes

Example:

```elixir
test "a spawned process can deliver into this test's Fake bucket" do
  parent = self()

  task =
    Task.async(fn ->
      Mailglass.Adapters.Fake.allow(parent, self())

      %{email: "child@example.com"}
      |> MyApp.UserMailer.welcome()
      |> Mailglass.deliver()
    end)

  Task.await(task)

  assert %Mailglass.Message{} = wait_for_mail(500)
end
```

Only fall back to shared/global mode when targeted ownership transfer is not a
fit. The non-async fallback is `setup :set_mailglass_global`, which requires
`async: false`.

```elixir
defmodule MyApp.GlobalMailerTest do
  use Mailglass.MailerCase, async: false

  setup :set_mailglass_global

  test "uses shared/global Fake access as an escape hatch" do
    :ok = Mailglass.Adapters.Fake.set_shared(self())
  end
end
```

That fallback broadens access for the duration of the test. Keep it narrow,
prefer `Fake.allow/2`, and do not treat shared/global mode as the baseline.

## PubSub and webhook assertions

Use PubSub-backed assertions when you are proving delivery state or
webhook-driven state transitions, not mailbox delivery.

- `assert_mail_delivered/2`
- `assert_mail_bounced/2`

These helpers wait for `{:delivery_updated, delivery_id, status, meta}` PubSub
broadcasts. They do not inspect the Fake mailbox or Fake delivery storage.

`Mailglass.MailerCase` subscribes the test process to the tenant-wide events
topic. If you are outside `MailerCase`, subscribe explicitly before asserting.

```elixir
test "asserts on a delivered event broadcast" do
  tenant_id = "test-tenant"
  delivery_id = Ecto.UUID.generate()

  Phoenix.PubSub.subscribe(
    Mailglass.PubSub,
    Mailglass.PubSub.Topics.events(tenant_id, delivery_id)
  )

  Phoenix.PubSub.broadcast(
    Mailglass.PubSub,
    Mailglass.PubSub.Topics.events(tenant_id, delivery_id),
    {:delivery_updated, delivery_id, :delivered, %{tenant_id: tenant_id}}
  )

  assert_mail_delivered(delivery_id, 100)
end
```

Use these assertions for webhook and projection flows. Use `assert_mail_sent/1`,
`last_mail/0`, and `wait_for_mail/1` for message-delivery assertions.

## Footguns and strict-CI posture

- Keep the default path simple: Fake adapter, `Mailglass.TestAssertions`, and
  `Mailglass.MailerCase` before any optional lane.
- `last_mail/0` is storage-backed inspection, not a mailbox receive.
- `wait_for_mail/1` is timeout-based and should be used only when delivery is
  expected to arrive asynchronously.
- Prefer `Fake.allow/2` plus normal sandbox ownership transfer over
  shared/global mode.
- Shared/global mode is the `async: false` fallback via
  `setup :set_mailglass_global`.
- Oban lanes are intentionally narrow: `:inline` and `:manual` only, both
  `async: false`, both requiring `oban_jobs`.
- PubSub assertions prove delivery-status changes, not mailbox state.

This narrow posture is the merge-blocking CI story: one stable baseline first,
then explicit exceptions only when the test really needs them.
