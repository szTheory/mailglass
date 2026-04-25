# Authoring Mailables

Use `Mailglass.Mailable` to define message builders that stay close to plain Swoosh while adding tenant, stream, and telemetry metadata.

## Prerequisites

- `mix mailglass.install` has already run
- `Mailglass.Config` is set in `runtime.exs`
- You have at least one sender address configured for your provider

## Define a mailable module

```elixir
defmodule MyApp.BillingMailer do
  use Mailglass.Mailable, stream: :operational

  def receipt(invoice) do
    new()
    |> Mailglass.Message.update_swoosh(fn email ->
      email
      |> Swoosh.Email.to(invoice.customer_email)
      |> Swoosh.Email.from({"Billing", "billing@example.com"})
      |> Swoosh.Email.subject("Receipt #{invoice.number}")
    end)
    |> Mailglass.Message.put_function(:receipt)
  end
end
```

## Render and deliver

```elixir
invoice = %{number: "INV-1001", customer_email: "alice@example.com"}

{:ok, _delivery} =
  invoice
  |> MyApp.BillingMailer.receipt()
  |> Mailglass.deliver()
```

## Use async delivery

```elixir
invoice
|> MyApp.BillingMailer.receipt()
|> Mailglass.deliver_later()
```

## End-to-End Example

```elixir
invoice = %{number: "INV-1002", customer_email: "bob@example.com"}

{:ok, delivery} =
  invoice
  |> MyApp.BillingMailer.receipt()
  |> Mailglass.deliver()

delivery.status
```
