# Inbound Routing Debug Guide

This guide answers the question: "I sent an email but my mailbox didn't process it — why?"

It covers three investigation paths in order of likely root cause, followed by a
fully-narrated debug session from initial confusion to working fix.

## Starting Point — the Routing-Trace Card

Open the failing `InboundRecord` in the `mailglass_admin` inbound LiveView. The
**routing-trace card** (visible in the detail panel) shows every route that was attempted
and which clause caused the route to fail.

Each row in the routing-trace card corresponds to one compiled route. The columns are:

- **Route index + mailbox name** (e.g. `1 — SupportMailbox`)
- **Per-clause pass/fail** — green checkmarks for clauses that passed, red X marks for
  the first clause that failed

Only the first failing clause is shown per route because the router stops evaluating a
route on first failure. A route with three clauses where clause 2 fails never evaluates
clause 3.

Example trace for a route that failed on the recipient clause:

```
Route 1 (SupportMailbox)
  recipient       FAILED  expected "support@example.com" got "support@mg.example.com"
  subject         (not evaluated)
```

Example trace for a route where the recipient matched but a header clause did not:

```
Route 1 (SupportMailbox)
  recipient       PASSED  "support@example.com"
  subject_header  FAILED  expected "Support" got "Re: Billing Question"
```

The routing-trace data is produced by `MailglassInbound.Router.Matcher.explain/2`, which
evaluates each clause of each route against the stored `InboundMessage` and returns a
per-clause verdict list. The LiveView renders those verdicts.

## Common Failure Mode 1 — Header AND-Semantics

All conditions in a single `route/2` call must match. This is AND semantics, not OR.

Consider this router:

```elixir
defmodule MyApp.MailglassInboundRouter do
  use MailglassInbound.Router

  route MyApp.Mailboxes.SupportMailbox,
    recipient: "support@example.com",
    headers: [{"X-Category", "Support"}]
end
```

A message arriving at `support@example.com` with no `X-Category` header does **not** match
this route — both conditions must be true. The routing-trace card would show:

```
Route 1 (SupportMailbox)
  recipient    PASSED  "support@example.com"
  X-Category   FAILED  expected "Support" got []
```

**Fix:** If you want the mailbox to trigger on either condition alone, split into two routes:

```elixir
defmodule MyApp.MailglassInboundRouter do
  use MailglassInbound.Router

  # Matches support@example.com with the X-Category header
  route MyApp.Mailboxes.SupportMailbox,
    recipient: "support@example.com",
    headers: [{"X-Category", "Support"}]

  # Also matches support@example.com without any header requirement
  route MyApp.Mailboxes.SupportMailbox,
    recipient: "support@example.com"
end
```

The first matching route wins. Top-to-bottom evaluation continues until one route passes all
of its clauses.

The `:headers` list itself is also AND: multiple header entries in the same route all have to
match. A header entry uses OR across the values of that header (if the header has multiple
values, any one matching the pattern is sufficient).

## Common Failure Mode 2 — Regex vs Exact Match

The router supports three matching styles:

| Style | Example | Behavior |
|---|---|---|
| Exact string | `"support@example.com"` | Case-sensitive exact equality |
| Regex | `~r/support@/` | Case-sensitive regex by default |
| Regex (case-insensitive) | `~r/support@/i` | Case-insensitive regex |

**Exact string matching is case-sensitive.** `"support@example.com"` does not match
`"Support@Example.com"`. This is the most common surprise for adopters whose mail clients
or forwarding rules alter the case of addresses.

```elixir
# This DOES NOT match "Support@Example.com"
route MyApp.Mailboxes.SupportMailbox, recipient: "support@example.com"

# This matches any case variation
route MyApp.Mailboxes.SupportMailbox, recipient: ~r/\Asupport@example\.com\z/i
```

**There is no wildcard glob.** The `*` character has no special meaning in an exact string
matcher — it is a literal asterisk. To match a wildcard pattern like "support at any
subdomain", use a regex:

```elixir
# This matches support@mg.example.com and support@mail.example.com
route MyApp.Mailboxes.SupportMailbox, recipient: ~r/\Asupport@[^@]+\.example\.com\z/i
```

The routing-trace card shows the matcher that was compiled into the route alongside the
actual value — comparing them makes the case mismatch immediately visible.

## Common Failure Mode 3 — Envelope vs To: Header

The route pattern matches against the **SMTP envelope recipient** (the `RCPT TO:` address),
stored in `envelope_recipient` on the `InboundMessage`. This is **not** the `To:` header in
the message body.

In most direct deliveries these are the same. They diverge when:

- **Mailgun HTTP routes** deliver to a subdomain address (`mg.example.com`) while the `To:`
  header still shows the original address (`example.com`).
- **Email forwarding rules** (Google Workspace "Receive mail as", catch-all forwards, alias
  services) rewrite the envelope recipient to the forwarder's address while preserving the
  original `To:` header.
- **BCC recipients** appear in the envelope but not in any `To:` or `Cc:` header.

The `mailglass_admin` inbound detail panel shows both:

- **Envelope recipient** — the value the router matches against
- **To: header** — the value the email client displays

When you see a `:no_match` outcome for a message that "looks" like it should have matched,
check both fields in the detail view. If the envelope recipient differs from the `To:` header,
the forwarding or subdomain setup is the cause.

## CLI Inspection

Before deploying, you can inspect the compiled route list without a database:

```bash
# List all compiled routes and check for conflicts
mix mailglass.inbound.doctor --verbose
```

The `--verbose` flag prints the resolved route list alongside the check results:

```
route 1: recipient="support@example.com"  →  MyApp.Mailboxes.SupportMailbox
route 2: recipient="billing@example.com"  →  MyApp.Mailboxes.BillingMailbox
```

From IEx, you can also reflect the compiled routes directly:

```elixir
iex> MyApp.MailglassInboundRouter.__mailglass_inbound_routes__()
[
  %MailglassInbound.Router.Route{
    mailbox: MyApp.Mailboxes.SupportMailbox,
    recipient: "support@example.com",
    subject: nil,
    headers: []
  }
]
```

`__mailglass_inbound_routes__/0` is a compile-time function injected by `use MailglassInbound.Router`
into every router module. It returns the route list in declaration order. Use it to verify
that the route you think is there is actually compiled into the module.

## Worked Example — Full Debug Session

This section traces a complete debugging session from initial symptom to working fix.

### Symptom

Your team has wired a Mailgun inbound route to forward all mail arriving at
`support@mg.example.com` to your application. You added this router:

```elixir
defmodule MyApp.MailglassInboundRouter do
  use MailglassInbound.Router

  route MyApp.Mailboxes.SupportMailbox, recipient: "support@example.com"
end
```

Emails arrive — you can see them in the mailglass_admin inbound list — but they all show
outcome `:no_match`. No support tickets are being created. `SupportMailbox.process/1` is
never called.

### Step 1: Open the Routing-Trace Card

You open one of the failing `InboundRecord` rows in the mailglass_admin inbound LiveView.
The detail panel loads. The routing-trace card shows:

```
Route 1 (SupportMailbox)
  recipient  FAILED  expected "support@example.com" got "support@mg.example.com"
```

The failure is immediate: the recipient clause failed on the very first route. The
incoming `envelope_recipient` is `"support@mg.example.com"` but the compiled route
expects `"support@example.com"`.

### Step 2: Understand the Root Cause

Mailgun routes deliver inbound mail via HTTP to your endpoint. The delivery happens at
the **Mailgun routing level**, which operates on the **sending subdomain** you configured
in the Mailgun dashboard (`mg.example.com`). The SMTP envelope carries
`support@mg.example.com` — that is what Mailgun saw as the `RCPT TO:` target.

The `To:` header in the message body still shows `support@example.com` (the address the
sender typed), because mail clients render the `To:` header, not the envelope. This is
why the message looks correct in email clients but fails the router match.

You can confirm this by expanding the "Message headers" section in the mailglass_admin
detail panel:

- **Envelope recipient:** `support@mg.example.com`
- **To: header:** `support@example.com`

They are different. The router matched against the envelope.

### Step 3: Apply the Fix

You have two options:

**Option A — match the subdomain address exactly:**

```elixir
route MyApp.Mailboxes.SupportMailbox, recipient: "support@mg.example.com"
```

This is the most specific fix. It works as long as your Mailgun routing domain stays
`mg.example.com`.

**Option B — match any subdomain using a regex:**

```elixir
route MyApp.Mailboxes.SupportMailbox, recipient: ~r/\Asupport@[^@]+\.example\.com\z/i
```

This matches `support@mg.example.com`, `support@mail.example.com`, and any other
`support@*.example.com` address. Use this if you might change the Mailgun sending subdomain
in the future.

You apply Option A (the exact match) and redeploy.

### Step 4: Verify the Fix with Replay

With the new router compiled, you return to the mailglass_admin inbound LiveView and
open the same failing `InboundRecord`. The replay modal is available from the detail
panel header. You click **Replay** and confirm.

The replay drives the stored `InboundMessage` through the updated router. The outcome
changes from `:no_match` to `:accept`. The routing-trace card now shows:

```
Route 1 (SupportMailbox)
  recipient  PASSED  "support@mg.example.com"
```

`SupportMailbox.process/1` was called and returned `:accept`. The replay confirmed the
fix without requiring a new inbound delivery.

You check the remaining `:no_match` records in the list. Because the Mailgun subdomain
mismatch was the only routing failure, you can replay them in bulk from the CLI:

```bash
mix mailglass.inbound.replay --tenant acme --since 2026-05-01T00:00:00Z
```

All records replay as `:accept`.

---

## References

- [inbound-install.md](inbound-install.md) — initial router setup, body reader config,
  and provider mount paths
- [inbound-operator.md](inbound-operator.md) — `mix mailglass.inbound.doctor`, replay,
  and prune operations in detail
- [inbound-mailgun.md](inbound-mailgun.md) — Mailgun subdomain setup, MX records, and
  the sending subdomain vs primary domain distinction
