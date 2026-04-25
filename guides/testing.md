# Testing

mailglass is built for merge-blocking CI. This guide covers the built-in test assertions and the fake adapter for deterministic testing.

## Prerequisites

- `Mailglass.Config` uses `Mailglass.Adapters.Fake` in `config/test.exs`
- Your test case imports `Mailglass.TestAssertions`

## Setup Test Config

```elixir
# config/test.exs
config :mailglass,
  repo: Mailglass.TestRepo,
  adapter: Mailglass.Adapters.Fake
```

## Use TestAssertions

```elixir
defmodule MyApp.UserMailerTest do
  use ExUnit.Case, async: true
  import Mailglass.TestAssertions

  test "sends welcome email" do
    %{email: "bob@example.com"}
    |> MyApp.UserMailer.welcome()
    |> Mailglass.deliver()

    assert_mail_sent(to: "bob@example.com", subject: "Welcome")
  end
end
```

## Inspection helpers

- `last_mail()` — returns the last delivered message in the current process mailbox
- `wait_for_mail(params)` — blocks until a matching mail arrives (useful for async/Oban testing)

## End-to-End Example

```elixir
import Mailglass.TestAssertions

%{email: "test@example.com"}
|> MyApp.UserMailer.welcome()
|> Mailglass.deliver()

assert_mail_sent(to: "test@example.com")
mail = last_mail()
assert mail.subject =~ "Welcome"
```
