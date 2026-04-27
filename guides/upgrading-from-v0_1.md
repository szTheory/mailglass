# Upgrading from v0.1 to v0.2

This guide helps you safely migrate your existing Mailglass applications from the v0.1 API to the v0.2 API. The primary change in v0.2 is the introduction of native setter functions on `Mailglass.Message`, removing direct dependencies on `Swoosh.Email` in your mailables.

## Before/After Examples

In v0.1, you used `Swoosh.Email` functions to construct messages:

```elixir
# v0.1 Mailable
defmodule MyApp.WelcomeEmail do
  use Mailglass.Mailable, stream: :transactional

  def build(user) do
    msg()
    |> Swoosh.Email.to(user.email)
    |> Swoosh.Email.from("hello@myapp.com")
    |> Swoosh.Email.subject("Welcome!")
    |> Swoosh.Email.html_body("<h1>Welcome</h1>")
    |> Swoosh.Email.attachment("path/to/guide.pdf")
  end
end
```

In v0.2, you use the native `Mailglass.Message` functions directly, and `attachment/2` is renamed to `attach/2`:

```elixir
# v0.2 Mailable
defmodule MyApp.WelcomeEmail do
  use Mailglass.Mailable, stream: :transactional

  def build(user) do
    msg()
    |> to(user.email)
    |> from("hello@myapp.com")
    |> subject("Welcome!")
    |> html_body("<h1>Welcome</h1>")
    |> attach("path/to/guide.pdf")
  end
end
```

## Codemod Walkthrough

To automate the transition to the new API, v0.2 includes an Igniter-powered codemod that will automatically rewrite your standard Swoosh setters.

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

3. Run the automated codemod task:

```bash
mix mailglass.upgrade.v0_2 --apply
```

This task safely traverses your codebase and replaces the known 8 `Swoosh.Email` calls (`to/2`, `from/2`, `subject/2`, `text_body/2`, `html_body/2`, `header/3`, `attachment/2`, and `put_tag/2`) with the newly imported native equivalents.

## Ambiguous Cases / Recipes

The codemod handles the 8 core standard setters. If you used other `Swoosh.Email` functions (e.g., `put_provider_option/3`), the codemod will skip them and emit a warning:

```text
Skipping unknown Swoosh.Email function: put_provider_option/2
```

**Recipe for Unsupported Swoosh Functions:**
If you still need advanced Swoosh capabilities that are not supported natively, use the `Mailglass.Message.update_swoosh/2` escape hatch:

```elixir
msg()
|> to("user@example.com")
# Update the underlying Swoosh.Email struct directly
|> Mailglass.Message.update_swoosh(fn email ->
  Swoosh.Email.put_provider_option(email, :template_id, "my-template")
end)
```

## Dependency Matrix

To use this upgrade codemod successfully, ensure your dependencies meet the minimum versions:
- `mailglass`: `~> 0.2`
- `igniter`: `~> 0.7`

## Rollback Procedure

If the codemod produces unintended changes, do not panic. Since the tool operates on standard Elixir AST, you can safely abort and rollback the changes using Git:

1. View the changes the codemod made:
   `git diff`
2. Discard all unstaged changes:
   `git checkout .` or `git restore .`

After checking out, review your AST and file an issue if the codemod failed to parse a standard pattern.
