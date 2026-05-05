# Upgrading from v0.1 to v0.2

This guide is the authoritative migration path from the v0.1 mailable API to the v0.2 public surface. The big change is that the common authoring path now uses native `Mailglass.Message` setters instead of direct `Swoosh.Email` calls inside your mailables.

## Before/After Examples

In v0.1, mailables commonly piped directly into `Swoosh.Email`:

```elixir
# v0.1 Mailable
defmodule MyApp.WelcomeEmail do
  use Mailglass.Mailable, stream: :transactional

  def welcome(user) do
    new()
    |> Swoosh.Email.to(user.email)
    |> Swoosh.Email.from("hello@myapp.com")
    |> Swoosh.Email.subject("Welcome!")
    |> Swoosh.Email.html_body("<h1>Welcome</h1>")
    |> Swoosh.Email.attachment("path/to/guide.pdf")
    |> Mailglass.Message.put_function(:welcome)
  end
end
```

In v0.2, the same mailable becomes:

```elixir
# v0.2 Mailable
defmodule MyApp.WelcomeEmail do
  use Mailglass.Mailable, stream: :transactional

  def welcome(user) do
    new()
    |> to(user.email)
    |> from("hello@myapp.com")
    |> subject("Welcome!")
    |> html_body("<h1>Welcome</h1>")
    |> attach("path/to/guide.pdf")
    |> Mailglass.Message.put_function(:welcome)
  end
end
```

The codemod covers these eight setters:

- `to/2`
- `from/2`
- `subject/2`
- `text_body/2`
- `html_body/2`
- `header/3`
- `attachment/2` -> `attach/2`
- `put_tag/2`

## Codemod Walkthrough

`mix mailglass.upgrade.v0_2` is an Igniter-backed codemod. Use it as a dry-run first, then apply once the diff looks right.

1. Ensure you have the `igniter` dependency installed in your `mix.exs`:

```elixir
def deps do
  [
    {:igniter, "~> 0.7", only: [:dev, :test]}
  ]
end
```

2. Fetch the dependency:

```bash
mix deps.get
```

3. Preview the rewrite:

```bash
mix mailglass.upgrade.v0_2
```

4. Apply the rewrite:

```bash
mix mailglass.upgrade.v0_2 --apply
```

5. Compile and run your test suite before committing the change:

```bash
mix compile
mix test
```

## Ambiguous Cases / Recipes

The codemod rewrites only the eight setters above. If you use another `Swoosh.Email` function, the task leaves that call in place and emits a warning with the migration-guide URL and the supported escape hatch.

```text
Skipping unknown Swoosh.Email function: put_provider_option/2. Review https://hexdocs.pm/mailglass/guides/upgrading-from-v0_1.html for ambiguous-case migration guidance and the Mailglass.Message.update_swoosh/2 escape hatch.
```

If you still need advanced Swoosh capabilities that are not native setters, keep the common path on `Mailglass.Message` and use `Mailglass.Message.update_swoosh/2` only around the unsupported call:

```elixir
new()
|> to("user@example.com")
|> Mailglass.Message.update_swoosh(fn email ->
  Swoosh.Email.put_provider_option(email, :template_id, "my-template")
end)
|> Mailglass.Message.put_function(:welcome)
```

## New in v0.2

### Per-Domain Rate Limiting

v0.2 introduces a multi-bucket rate limiter to protect your sender reputation. Outbound messages (except those on the `:transactional` stream) are now checked against:
- `:tenant_recipient` limits (100/min default)
- `:global_recipient` limits (1000/min default)
- `:sender_domain` limits (500/min default)

If you see `{:error, %Mailglass.RateLimitError{}}`, your message was throttled. See the [Rate Limiting Guide](rate-limiting.md) for configuration overrides.

### Enhanced Test Assertions

The testing surface has been modernized. `import Mailglass.TestAssertions` now provides:
- `assert_mail_sent(params)`
- `last_mail()`
- `wait_for_mail(params)`

These replace manual mailbox inspections and work seamlessly with the new `Mailglass.Adapters.Fake`.

## Dependency Matrix

To use this upgrade codemod successfully, ensure your dependencies meet the minimum versions:
- `mailglass`: `~> 0.2`
- `phoenix`: `~> 1.8`
- `phoenix_live_view`: `~> 1.1`
- `igniter`: `~> 0.7`

## Troubleshooting

### Codemod skips my mailables

- Ensure your mailables use the `use Mailglass.Mailable` macro.
- The codemod targets direct `Swoosh.Email` calls. If you have aliased `Swoosh.Email` or are using qualified calls that don't match the expected patterns, you may need to update them manually.

### "RateLimitError" after upgrading

- v0.2 enables rate limiting by default for `:bulk` and `:operational` streams.
- If your existing volume exceeds the new defaults, configure overrides in `config/runtime.exs` or move time-sensitive alerts to the `:transactional` stream.

### Tests fail with "no mail sent"

- Confirm you have switched to `Mailglass.Adapters.Fake` in `config/test.exs`.
- Ensure you are importing `Mailglass.TestAssertions` and not relying on internal mailbox structure which may have changed.

---

*Last updated: 2026-05-03 (Phase 31 ships at v0.1).*
