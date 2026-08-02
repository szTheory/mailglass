# B2C First-Adopter Profile

This is the production profile for a low-volume, single-brand consumer product run by a solo operator. It is deliberately opinionated: automate routine delivery, preserve durable evidence, and make failures visible without requiring a person to refresh a page or inspect raw provider payloads.

## Start with the three streams

Classify mail by why the recipient receives it, not by the template's tone.

| Stream | B2C examples | Unsubscribe policy |
|---|---|---|
| `:transactional` | magic links, verification, receipts, payment failures, security alerts, account deletion | No unsubscribe header. Never use for engagement mail. |
| `:operational` | study reminders, return nudges, progress digests, CEFR milestones, curriculum updates requested by the learner | Always provide the complete RFC 8058 header pair. |
| `:bulk` | waitlist announcements, new-language promotion, campaigns sent to a broad opted-in audience | Mailglass injects its stream-level RFC 8058 headers automatically. |

Mailglass's built-in unsubscribe suppression is scoped to the originating address and stream. An operational or bulk unsubscribe therefore does not suppress a transactional magic link. Hard bounces and complaints are intentionally address-wide and can block transactional delivery. Do not bypass that safety rule: the product must provide verified email replacement and an account-recovery path that does not depend on sending to the suppressed address.

An operational mailable opts into one-click unsubscribe by supplying both headers together:

```elixir
defmodule MyApp.StudyReminder do
  use Mailglass.Mailable,
    stream: :operational,
    tracking: [opens: false, clicks: true]

  def for_learner(learner, unsubscribe_url) do
    new()
    |> to(learner.email)
    |> subject("Your next Spanish review is ready")
    |> header("List-Unsubscribe", "<#{unsubscribe_url}>")
    |> header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
    |> text_body("Your review is ready.")
  end
end
```

Generate `unsubscribe_url` in the host or preference service from an opaque, signed recipient reference. Its POST action must be idempotent and disable only the represented notification category. Do not put an email address in the token or URL. Chimeway owns notification-key/channel preferences, quiet hours, caps, scheduling, digests, and fallback; Mailglass transports the headers and records delivery evidence. The built-in Mailglass stream-level endpoint remains the safe default when category-specific preferences are not needed.

## Keep one tenant and two sending identities

`Mailglass.Tenancy.SingleTenant` is the zero-configuration default. It uses the literal tenant ID `"default"`, applies no query restriction, and stamps verified webhooks consistently. Do not invent customer-account tenancy for a single-brand consumer product.

Sending identity is separate from tenancy. Give authentication and billing mail a transactional identity, and give engagement mail a second identity or subdomain so reputation incidents cannot couple them. A small custom tenancy resolver can select named adapters while retaining one logical tenant:

```elixir
defmodule MyApp.MailglassTenancy do
  @behaviour Mailglass.Tenancy

  @impl true
  def scope(query, _context), do: query

  @impl true
  def resolve_webhook_tenant(_context), do: {:ok, "default"}

  @impl true
  def resolve_outbound_adapter_ref(%{message: %{stream: :transactional}}),
    do: {:ok, :transactional}

  def resolve_outbound_adapter_ref(%{message: %{stream: stream}})
      when stream in [:operational, :bulk],
      do: {:ok, :engagement}
end
```

Configure `:transactional` and `:engagement` as named adapter references and set `config :mailglass, tenancy: MyApp.MailglassTenancy`. Queued deliveries persist the selected reference, so retries do not jump between identities.

For a new engagement domain, start with opted-in, recently active recipients and a sender-domain bucket with no large burst:

```elixir
config :mailglass, :rate_limit,
  sender_domain: [
    default: [capacity: 10, per_minute: 10],
    overrides: [
      {"learn.example.com", [capacity: 10, per_minute: 10]}
    ]
  ]
```

Treat that value as a conservative launch setting, not a universal guarantee. Reduce volume automatically on sustained deferrals and adjust from provider reputation evidence. Transactional messages bypass Mailglass rate limits by design; authentication abuse throttling belongs in Sigra or the host.

Run `mix mail.doctor` before launch and after DNS changes. It proves DNS facts, not inbox placement. Follow [Google's sender guidance](https://support.google.com/mail/answer/81126?hl=en) to authenticate mail, increase volume gradually, send consistently, and begin with engaged recipients.

## Observe outcomes without collecting message content

Attach to the durable provider-feedback event:

```elixir
:telemetry.attach(
  "myapp-mailglass-feedback",
  [:mailglass, :delivery, :feedback, :stop],
  fn _event, %{count: 1}, metadata, _config ->
    MyApp.Observability.record_mail_feedback(metadata.status,
      tenant_id: metadata.tenant_id,
      provider: metadata.provider,
      stream: metadata.stream,
      mailable: metadata.mailable
    )
  end,
  nil
)
```

The event is emitted once after a new durable provider or compliance fact is committed. Status is one of `:sent`, `:delivered`, `:bounced`, `:complained`, `:deferred`, `:rejected`, `:opened`, `:clicked`, or `:unsubscribed`. Metadata contains only `tenant_id`, `delivery_id`, `provider`, `stream`, `mailable`, and `status`; it never contains an address, subject, header, URL, token, or body.

At launch volume, alert on every complaint. A percentage over tens or hundreds of recipients is too noisy to be a useful control. Add rate-based alerts only after the denominator becomes stable. The Mailglass ledger remains the audit source of truth; telemetry and PubSub are operational signals.

Keep open tracking disabled. [Apple Mail Privacy Protection](https://support.apple.com/en-nz/guide/iphone/iphf084865c7/26/ios/26) means an open is not reliable evidence of a human reading a message. Never drive suppression, re-engagement, curriculum decisions, or product analytics from opens. Click tracking may be used for non-authentication mail when justified; authentication links must not be rewritten or tracked.

## Compose with the family instead of expanding Mailglass

| Concern | Owner |
|---|---|
| Message render, send, normalized provider evidence, suppression | Mailglass |
| Preference categories, quiet hours, caps, scheduling, digesting, channel fallback | Chimeway |
| Authentication tokens, sessions, passkeys, TOTP, prescan-safe consumption | Sigra/host |
| Subscription state, dunning, Stripe webhook workflows | Accrue |
| Support conversations and automated support handling | Cairnloop/host |
| Dashboards, SLOs, and paging | Parapet |
| Mobile notification-open evidence | `crosswake_chimeway` |
| Mobile route activation after an ordinary HTTPS link opens | Crosswake |

Do not create `crosswake_mailglass`. Mailglass links are normal host-generated HTTPS URLs. Crosswake activates the corresponding route after the operating system opens one; Chimeway already owns notification-open evidence, and Sigra owns authentication returns. A Mailglass companion would add three-way coupling without introducing a stable capability.

Reconsider that boundary only after two independent adopters implement the same provider-neutral, versioned, signed email-to-route-intent adapter and demonstrate why it cannot live in the host, Chimeway, or Crosswake activation layer.

## Launch gates

Before the first paid subscription:

1. Sigra or the host validates magic-link GETs without consuming them, then consumes the token atomically from a CSRF-protected POST. Provider link scanners must not log the user in or invalidate the link.
2. Chimeway or the host has an idempotent category-specific one-click endpoint for every operational category.
3. Parapet consumes `[:mailglass, :delivery, :feedback, :stop]` and pages on any complaint.
4. Accrue's Stripe test-mode paths cover payment success, failure, action required, recovery, and missing tax location using [Stripe's subscription webhook state](https://docs.stripe.com/billing/subscriptions/webhooks) as authority.
5. The host can replace a hard-bounced or complained-about email address through a separately verified recovery path.
6. Production inbound processing uses Oban. The Task supervisor fallback is not durable enough for a production support mailbox.
7. The operator dashboard visibly advances provider status and suppression evidence without a browser reload.

## Evidence that justifies more Mailglass

- Add declarative stream routing only after two adopters independently duplicate or misconfigure the resolver pattern.
- Add automated warmup support only after planned engagement volume exceeds roughly 500 messages per day or sustained provider deferrals appear.
- Add a generic inbound thread model only after two products need the same `In-Reply-To`/`References` abstraction.
- Add inbound charset transcoding only with a retained non-UTF-8 message that fails a real workflow.
- Store rendered-message snapshots only when an operator must reproduce exact content and has approved encryption, retention, access, and deletion policy.
- Add aggregate complaint-rate UI only when volume supplies a stable denominator; use provider tools and any-complaint paging before then.
