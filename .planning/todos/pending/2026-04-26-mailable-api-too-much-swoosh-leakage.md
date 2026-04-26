---
created: 2026-04-26T16:18:00.000Z
title: Mailable API leaks Swoosh — abstract above it, keep Swoosh as escape hatch
area: api
files:
  - lib/mailglass/mailable.ex
  - lib/mailglass/message.ex
  - prompts/mailglass-brand-book.md (voice/UX intent)
  - prompts/mailer-domain-language-deep-research.md (domain language)
priority: api-design (revisit before stabilizing the Mailable contract)
---

## Problem

User-facing feedback from szTheory during the v0.1.0 publish cycle on
2026-04-26: the current Mailable API forces adopters to drop into
Swoosh for ordinary email construction:

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

User's reaction:

> I personally find it confusing having to drop into Swoosh here. Like
> to build emails or whatever? Confusing interface — seems like mailglass
> should abstract above Swoosh not force users to drop down into Swoosh
> except for like emergency escape hatches? Or maybe I'm missing
> something.

This violates the brand-voice principle in CLAUDE.md / brand-book:
"clear, exact, confident-not-cocky, **technical not intimidating**,
a thoughtful maintainer." Forcing adopters to know Swoosh's API to
construct an ordinary receipt email is intimidating — it makes
mailglass a thin wrapper instead of a framework layer. The whole
point of mailglass-the-framework (per PROJECT.md) is that it ships
"the layer Swoosh deliberately omits." That promise is undermined
when basic field-setting requires Swoosh.

## Solution (TBD — design discussion needed)

Possible directions to evaluate:

1. **First-class fluent API on `Mailglass.Message`** that mirrors common
   field setters: `to/2`, `from/2`, `subject/2`, `body/2`, `html/2`,
   `headers/3`, `attachment/2`, etc. Internally these still build a
   Swoosh.Email but adopters never see Swoosh names.

2. **`use Mailglass.Mailable` injects** ActionMailer-style ergonomics:
   the mailable function returns a `%Message{}` from explicit field
   keywords:

       def receipt(invoice) do
         message(
           to: invoice.customer_email,
           from: {"Billing", "billing@example.com"},
           subject: "Receipt #{invoice.number}",
           assigns: %{invoice: invoice}
         )
       end

   `update_swoosh/2` stays as the documented escape hatch for
   Swoosh-only features (custom adapters, raw headers, MIME shenanigans).

3. **HEEx component-driven layout**: the `body/0` callback returns a
   HEEx template; the message struct binds `to`/`from`/`subject` via
   front-matter or by a separate `headers/1` callback. Closer to
   ActionMailbox+ActionMailer hybrid.

Read first when revisiting:
- `prompts/mailer-domain-language-deep-research.md` — the domain
  vocabulary mailglass committed to (Mailable / Message / Delivery /
  Event etc.)
- `prompts/mailglass-brand-book.md` — voice + UX intent
- ActionMailer API surface for inspiration (`mail to:, from:, subject:`)
- Anymail's recipient/sender API for normalized contact handling
- Laravel Mailable's `build()` method for fluent vs. property style

This is API-shape work — touch BEFORE the Mailable contract stabilizes
in v0.2 (otherwise breaking change later costs adopter trust). Not a
v0.1.x patch — likely a v0.2 spec change with deprecation warnings on
the Swoosh-leak path.

## Adopter impact

Currently `accrue` (jon's project) is on `mailglass`. Any v0.2 API change
should land with deprecation warnings + a CHANGELOG migration section
so adopters can move on their schedule.
