# Authoring Mailables

Use `Mailglass.Mailable` to define message builders on the native v0.2 API. The macro imports the common `Mailglass.Message` setters so the default path does not have to call `Swoosh.Email.*` directly.

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
    |> to(invoice.customer_email)
    |> from({"Billing", "billing@example.com"})
    |> subject("Receipt #{invoice.number}")
    |> html_body("<p>Receipt #{invoice.number}</p>")
    |> put_tag("billing")
    |> Mailglass.Message.put_function(:receipt)
  end
end
```

## Generated plaintext

`Mailglass.Renderer.render/2` derives `text_body` from rendered `html_body` before CSS inlining and replaces any `text_body` already set on the message. The public `Mailglass.Message.text_body/2` setter remains available, but it is not an explicit-text override for Mailables sent through `Mailglass.deliver/1`.

## Use `update_swoosh/2` only for unsupported Swoosh features

Keep uncommon provider-specific calls isolated:

```elixir
def receipt_with_template(invoice) do
  new()
  |> to(invoice.customer_email)
  |> subject("Receipt #{invoice.number}")
  |> Mailglass.Message.update_swoosh(fn email ->
    Swoosh.Email.put_provider_option(email, :template_id, "receipt-template")
  end)
  |> Mailglass.Message.put_function(:receipt_with_template)
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
