# What you can do with mailglass

> **Current as of 2026-06-02.** This guide covers the shipped, `v1.x`-stable
> jobs in `mailglass` and `mailglass_admin`. `mailglass_inbound` is summarized
> near the end; it has its own independent stable `1.0` contract documented in
> `mailglass_inbound/docs/api_stability.md`.

Most docs answer *"how does this feature work?"* This one answers *"what job am
I hiring this library to do in my SaaS?"* Read it once straight through if
you're evaluating mailglass. After that, jump to the job you need.

## The shortest useful mental model

If you only remember one sentence, make it this:

**mailglass is the framework layer around transactional email that Phoenix teams
usually end up rebuilding by hand.**

Here is the lifecycle the library is built around:

1. You define a **Mailable**.
2. mailglass renders it into a **Message**.
3. Sending creates a **Delivery**.
4. Providers later report **Events** about that delivery.
5. Those events can project **Suppressions** that block future sends.
6. If you also receive mail, inbound arrives as an **InboundMessage** and is
   routed to a **Mailbox**.

One distinction is load-bearing:

**dispatch ≠ delivered**

- **Dispatched** means mailglass handed the message to your provider.
- **Delivered** means the recipient's mail server accepted it later, usually via
  webhook evidence.

That distinction shows up everywhere in the library because it is the difference
between "we tried" and "the downstream system accepted it."

## Where mailglass sits in your stack

Imagine a normal SaaS week:

- You add a welcome email.
- You want to preview it before deploy.
- You queue sends so a provider hiccup does not slow the request.
- Support asks whether a receipt really went out.
- A bounce or complaint should stop future sends automatically.
- One tenant wants Postmark, another wants SES.

Without mailglass, that becomes template plumbing, preview tooling, webhook
normalization, suppression rules, signed unsubscribe links, and some kind of
audit trail. With mailglass, those are the default path. You still choose your
transport through [Swoosh](https://hex.pm/packages/swoosh); mailglass does not
replace it.

## The jobs

| # | When you need to… | Go to |
|---|---|---|
| 1 | Build an email that renders everywhere, including Outlook | [Job 1](#job-1-build-an-email-that-renders-everywhere) |
| 2 | See an email before it ships | [Job 2](#job-2-see-an-email-before-it-ships) |
| 3 | Ship an auth email you can trust | [Job 3](#job-3-ship-an-auth-email-you-can-trust) |
| 4 | Send reliably in the background | [Job 4](#job-4-send-reliably-in-the-background) |
| 5 | Prove what actually happened to a message | [Job 5](#job-5-prove-what-actually-happened-to-a-message) |
| 6 | Test your email without sending real mail | [Job 6](#job-6-test-your-email-without-sending-real-mail) |
| 7 | Stop emailing addresses that bounce or complain | [Job 7](#job-7-stop-emailing-addresses-that-bounce-or-complain) |
| 8 | Turn provider webhooks into one event stream | [Job 8](#job-8-turn-provider-webhooks-into-one-event-stream) |
| 9 | Figure out why a delivery failed in production | [Job 9](#job-9-figure-out-why-a-delivery-failed-in-production) |
| 10 | Run all of this in a multi-tenant SaaS | [Job 10](#job-10-run-all-of-this-in-a-multi-tenant-saas) |

---

<!-- J1 -->
## Job 1: Build an email that renders everywhere

*Scenario:* you need a welcome email, a receipt, or an account alert that looks
professional in Gmail, Apple Mail, and the one client everyone secretly fears:
Outlook.

`Mailglass.Components` gives you HEEx-native building blocks that emit the
table-heavy, MSO/VML-backed HTML email clients still require. You write intent;
the library handles the hostile rendering environment.

```elixir
defmodule MyApp.MailTemplates do
  use Phoenix.Component
  import Mailglass.Components

  def welcome(assigns) do
    ~H"""
    <.container>
      <.section>
        <.heading level={1}>Welcome</.heading>
        <.text>Hello <%= @name %>, your account is ready.</.text>
        <.button href="https://example.com/login">Sign in</.button>
      </.section>
    </.container>
    """
  end
end
```

**What this job really buys you:** no Node toolchain, no handwritten Outlook
conditionals, no splitting your mental model between Phoenix templates and "the
special email renderer."

**Go deeper →** [Components](components.md)

---

<!-- J2 -->
## Job 2: See an email before it ships

*Scenario:* product wants a quick tweak, you changed copy and spacing, and you
need to see the real output before a single customer gets it.

Mount the preview behind dev routes. It discovers your Mailables and runs them
through the same renderer used for delivery.

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router
  import MailglassAdmin.Router

  if Application.compile_env(:my_app, :dev_routes) do
    scope "/dev" do
      pipe_through :browser
      mailglass_admin_routes "/mail"
    end
  end
end
```

Open `http://localhost:4000/dev/mail` and you get a sidebar of Mailables,
HTML/Text/Raw/Headers tabs, device-width and dark-mode toggles, plus editable
assigns.

**What this job really buys you:** preview is not a toy renderer. It is the
production renderer with a UI around it, which means less drift and fewer
"looked fine in preview, broke in inbox" surprises.

**Go deeper →** [Preview](preview.md)

---

<!-- J3 -->
## Job 3: Ship an auth email you can trust

*Scenario:* password resets and magic links are not "just another email." If a
tracking pixel leaks data or a rewritten link changes the security posture, you
have built a problem, not a feature.

Define the message on the `:transactional` stream and send it through the normal
surface.

```elixir
defmodule MyApp.UserMailer do
  use Mailglass.Mailable, stream: :transactional

  def password_reset(user, url) do
    new()
    |> to(user.email)
    |> from({"MyApp", "support@example.com"})
    |> subject("Reset your password")
    |> html_body("<p>Reset it here: #{url}</p>")
    |> text_body("Reset it here: #{url}")
    |> Mailglass.Message.put_function(:password_reset)
  end
end

{:ok, _delivery} =
  %{email: "alice@example.com"}
  |> MyApp.UserMailer.password_reset("https://example.com/reset/abc")
  |> Mailglass.deliver()
```

**What this job really buys you:** auth mail is safe by default. Open/click
tracking stays off, and the `NoTrackingOnAuthStream` Credo check turns unsafe
tracking on auth-shaped functions into a compile-time failure.

**Go deeper →** [Getting Started](getting-started.md) · [Authoring Mailables](authoring-mailables.md)

---

<!-- J4 -->
## Job 4: Send reliably in the background

*Scenario:* you want the request to finish fast, but you also want retries and
replays to be boring instead of terrifying.

Use `deliver_later/2`. When Oban is available, mailglass uses it. When it is
not, mailglass degrades to a supervised `Task` and tells you so once at boot.

```elixir
%{email: "alice@example.com"}
|> MyApp.UserMailer.welcome()
|> Mailglass.deliver_later()
```

Every logical send carries an idempotency key, so retried work converges instead
of duplicating mail.

**What this job really buys you:** the common async path without making Oban a
hard requirement, plus replay safety enforced in persistence rather than hoped
for in application code.

**Go deeper →** [Testing](testing.md) · [Authoring Mailables](authoring-mailables.md)

---

<!-- J5 -->
## Job 5: Prove what actually happened to a message

*Scenario:* support asks, "Did the receipt go out?" What they mean is usually
three different questions: was it rendered, was it handed to the provider, and
was it accepted downstream?

mailglass records those facts in an append-only event ledger and broadcasts
status changes over PubSub.

```elixir
Phoenix.PubSub.subscribe(
  Mailglass.PubSub,
  Mailglass.PubSub.Topics.events(tenant_id, delivery.id)
)

def handle_info({:delivery_updated, _delivery_id, status, _meta}, socket) do
  # status flows :queued -> :dispatched -> :delivered (or :bounced)
  {:noreply, assign(socket, :status, status)}
end
```

The `mailglass_events` table is append-only by construction. Updates and deletes
raise `SQLSTATE 45A01`, which means the audit trail is protected from both bugs
and convenience.

**What this job really buys you:** one durable place to ask what happened, with
enough fidelity to answer "we sent it" separately from "the recipient side
accepted it."

**Go deeper →** [Telemetry](telemetry.md)

---

<!-- J6 -->
## Job 6: Test your email without sending real mail

*Scenario:* you want fast tests that tell you what was sent, without provider
credentials, flaky inboxes, or process-mailbox tricks that fall apart under
`async: true`.

Point tests at `Mailglass.Adapters.Fake` and use the shipped assertions.

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

For most app tests, `use Mailglass.MailerCase` is the easier baseline: it wires
the Fake adapter, tenancy, and delivery-event subscription for you.

**What this job really buys you:** the test path is not second-class. The Fake
adapter is the project's own release gate, so the tooling you rely on is held to
the same standard as the library itself.

**Go deeper →** [Testing](testing.md)

---

<!-- J7 -->
## Job 7: Stop emailing addresses that bounce or complain

*Scenario:* a recipient hard-bounces or files a complaint. At that point the
important question is no longer "can we send?" but "can we make sure we never do
this again by accident?"

mailglass projects suppressions from verified webhook events and blocks future
sends before they reach your provider.

```elixir
case Mailglass.deliver(message) do
  {:ok, delivery} ->
    handle_sent(delivery)

  {:error, %Mailglass.SuppressedError{} = error} ->
    Logger.info("Delivery blocked: #{error.message}")
end
```

Hard bounces and complaints create standing suppressions. Unsubscribes create
stream-aware suppressions. If you ever need to rebuild truth from the ledger,
`mix mailglass.suppressions.resync` is the repair path.

**What this job really buys you:** compliance and deliverability policy is not a
spreadsheet, not tribal knowledge, and not a best-effort callback you hope every
team remembers to call.

**Go deeper →** [Webhooks](webhooks.md)

---

<!-- J8 -->
## Job 8: Turn provider webhooks into one event stream

*Scenario:* today's provider is Postmark, tomorrow's might be SES, and you do
not want business logic that knows five webhook dialects.

Mount the webhook routes and let mailglass verify signatures and normalize
events into one vocabulary.

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router
  import Mailglass.Webhook.Router

  scope "/" do
    pipe_through :api
    mailglass_webhook_routes "/webhooks", providers: [:postmark, :sendgrid]
  end
end
```

Postmark and SendGrid ship on the zero-arg mount. `:mailgun`, `:ses`, and
`:resend` are explicit opt-ins. A forged signature raises
`Mailglass.SignatureError` and stops there.

**What this job really buys you:** your app reasons about normalized email
events, not provider payload shape. Provider swaps become infrastructure work,
not domain rewrites.

**Go deeper →** [Webhooks](webhooks.md)

---

<!-- J9 -->
## Job 9: Figure out why a delivery failed in production

*Scenario:* a customer says "I never got it," and you need an answer that is
better than searching logs and reconstructing the timeline in your head.

Mount the operator dashboard in your app, behind your auth.

```elixir
scope "/ops" do
  pipe_through [:browser, :require_authenticated_user]

  mailglass_operator_routes "/mail",
    auth: MyApp.MailglassAdminAuth
end
```

The operator surface turns the event ledger into a timeline you can use:
delivery history, exact stored webhook evidence, replay, and reconciliation of
orphaned webhook races through `mix mailglass.reconcile`.

**What this job really buys you:** production debugging without turning email
operations into a separate product or handing your delivery truth to a hosted
third party.

**Go deeper →** [Operator Incident Support](operator-incident-support.md)

---

<!-- J10 -->
## Job 10: Run all of this in a multi-tenant SaaS

*Scenario:* one workspace sends from `billing@tenant-a.com`, another from
`support@tenant-b.com`, and leaking data across that line would be catastrophic.

mailglass treats multi-tenancy as a first-class domain concern. `tenant_id` is
on every delivery, event, and suppression, and the `Mailglass.Tenancy`
behaviour controls scoping plus optional per-tenant adapter routing.

```elixir
defmodule MyApp.Tenancy do
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, %{tenant_id: tenant_id}) do
    Mailglass.Tenancy.scope(query, %{tenant_id: tenant_id})
  end

  @impl Mailglass.Tenancy
  def resolve_outbound_adapter_ref(%{tenant_id: "acme"}), do: {:ok, :postmark_acme}
  def resolve_outbound_adapter_ref(_ctx), do: :default
end
```

If you do not need this, the single-tenant path is zero-config. If you do need
it, the data model already expects it.

**What this job really buys you:** tenant isolation and provider routing as part
of the framework contract, not an afterthought layered on later.

**Go deeper →** [Multi-Tenancy](multi-tenancy.md)

---

## One more thing: receiving mail

If your SaaS also needs to *receive* email, `mailglass_inbound` is the sibling
package for that job: inbound router DSL, `Mailbox` behaviour, verified ingress,
replayable storage, and async execution.

`mailglass_inbound` `1.0.0` ships its own independent stable `1.0` contract —
verified ingress, replayable storage, async execution, and operator tooling —
documented in [`mailglass_inbound/docs/api_stability.md`](../mailglass_inbound/docs/api_stability.md).

## What mailglass deliberately does not do

The edges matter because they keep the library coherent:

- **Marketing email** is out. Campaigns, lists, segmentation, A/B tests, and
  drip automation belong to [Keila](https://www.keila.io) or
  [Listmonk](https://listmonk.app).
- **Multi-channel notifications** are out. SMS, push, and in-app point toward a
  different abstraction entirely.
- **A hosted ops console** is out. `mailglass_admin` mounts inside your app.
- **A built-in subscriber preference center** is out. Build it on top of
  suppression and consent primitives if your app needs it.

And one boundary is ideological as much as technical:

**Open/click tracking is off by default and never allowed on auth mail.**

That is not missing polish. It is the product stance.

The full rationale for those boundaries lives in `.planning/PROJECT.md`.

---

*Last updated: 2026-05-23. Public JTBD projection refreshed from `.planning/research/JTBD-COVERAGE.md`.*
