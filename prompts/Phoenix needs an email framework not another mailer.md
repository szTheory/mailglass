# Phoenix needs an email framework, not another mailer

**Elixir's email story ends where the interesting work begins.** Swoosh ships an excellent `compose → adapter → deliver` primitive, but everything beyond that — responsive templates, preview dashboards, one-click unsubscribe, bounce/complaint normalization, suppression lists, inbound routing, marketing campaigns, multi-tenant sending — is left to the developer. The result is a community where every Phoenix team rebuilds the same 40% of Rails ActionMailer + Django Anymail + Rails ActionMailbox + Laravel Mailcoach from scratch, badly.

This is a **real, top-tier gap** — larger in surface area than the auth or Stripe gaps Jonathan is already filling, and more clearly differentiated from incumbents. The 2024 Gmail/Yahoo bulk-sender rules, the rise of React Email, and Phoenix 1.7's removal of `Phoenix.View` have left Swoosh-era patterns visibly creaky in 2026. A batteries-included, Phoenix-native email **suite** — built on Swoosh rather than replacing it — is worth building, should ship as 3–4 coordinated packages, and has a plausible path to becoming canonical the way Oban did.

The rest of this document maps the terrain, benchmarks each prior-art anchor, identifies the precise shape of the opportunity, and gives a prioritized roadmap.

---

## 1. The Elixir ecosystem audit at a glance

Swoosh is healthy and extensible. Bamboo is in maintenance mode. Everything else is a fragment.

| Library | Role | Last release | Monthly dl | Status | Critical gap |
|---|---|---|---|---|---|
| **Swoosh** | Core mailer + 15+ adapters | v1.25.0, Apr 2026 | ~39k | ✅ Active | No deliver_later, no preview dashboard beyond in-memory `Plug.Swoosh.MailboxPreview`, no List-Unsubscribe helpers, no webhook normalization |
| **Bamboo** | Legacy mailer | v2.5.0, Jul 2025 | lower than Swoosh | ⚠️ Maintenance (beam-community) | Superseded by Swoosh; Phoenix 1.7 ships Swoosh default |
| **Phoenix.Swoosh** | View/Component bridge | v1.2.1 | — | ⚠️ Slow | Phoenix.View removal (#287) still only partly addressed |
| **gen_smtp** | Erlang SMTP client/server | v1.3.0, May 2025 | — | ✅ Stable | Foundation lib; needs wrapper UX |
| **mail** (DockYard) | RFC 2822 parser/builder | v0.5.2, Jan 2026 | ~153k | ✅ Active | Parse-only; not an inbound framework |
| **mailibex** | DKIM/SPF/DMARC + MIME | GitHub only | — | ⚠️ Niche (~65★) | Only Elixir lib with DKIM signing; not on Hex, not integrated with Swoosh |
| **Premailex** | CSS inliner + HTML→text | v0.3.20 | — | ⚠️ Slow | Canonical inliner; needs first-class Swoosh integration |
| **mjml / mjml_eex** | MJML compiler via mrml NIF | v5.3.1 / v0.13.0 | ~43k | ✅ Active (akoutmos) | HEEx-parsing interop keeps breaking across Phoenix upgrades |
| **mua** | Modern SMTP client | v0.2.6, Dec 2025 | ~5k | ✅ Active | Now integrated directly into Swoosh |
| **bamboo_smtp** | Bamboo SMTP adapter | v4.2.2, Sep 2022 | — | ❌ Stagnant | — |
| **Keila** | Newsletter *application* | v0.19.0, Feb 2026 | ~2.1k ★ | ✅ Active (Pentacent) | **App, not a library** — cannot be embedded; AGPLv3 |
| **Oban Pro** | Job engine + Workflow DAG | v1.5+ | commercial | ✅ Active | No email product; provides primitives for drip orchestration |

### The four concrete gaps

1. **No marketing-email library.** Keila is a standalone app. Nothing ships as an embeddable library for subscribers/lists/segments/campaigns.
2. **No inbound-email framework.** Requested on ElixirForum since at least 2018. gen_smtp, mail, mailibex, pique are building blocks; there is no ActionMailbox equivalent that handles provider webhooks + routing DSL + Mailbox modules.
3. **No deliverability/compliance layer.** No List-Unsubscribe (RFC 8058) helpers, no normalized webhook event model, no suppression list, no DKIM-signing integration, no DNS doctor.
4. **No production email admin.** `Plug.Swoosh.MailboxPreview` is dev-only and in-memory. Zero Oban-Web-style sent-email dashboard with webhook timeline, resend, suppression management.

**Swoosh is the right foundation to build on, not replace.** It has ~19M all-time downloads, is actively maintained, and its adapter/ApiClient behaviours are exactly the extensibility seams a higher-level library needs.

---

## 2. Developer pain points are specific, frequent, and unanswered

Direct evidence from ElixirForum, GitHub issues, and blog posts clusters into seven recurring themes. Quotes are representative, not exhaustive.

**Transactional friction.** Phoenix 1.7 ships Swoosh as default, but Swoosh has no `deliver_later`. Bamboo migrants routinely ask for it: *"I'm currently transitioning from Bamboo to Swoosh… In Bamboo, I was using `deliver_later`… Now that I'm switching…"* ([ElixirForum 65703](https://elixirforum.com/t/65703)). The canonical answer is "wire Oban yourself." Runtime/secret config for adapters also trips users repeatedly ([Swoosh #463](https://github.com/swoosh/swoosh/issues/463)).

**Tailwind-in-email is unsolved.** *"I already have TailwindCSS setup, but would like to style my emails using the same. Has anyone figured out how to do this?"* ([44657](https://elixirforum.com/t/44657)). The community answer is "use external tools (MJML, Maizzle, Topol)." No batteries-included story.

**MJML + HEEx interop is fragile.** *"We are using MJML to template our emails… Suddenly, the HEEX parser started caring a lot more about the contents of our mjml-heex"* ([69206](https://elixirforum.com/t/69206)). Phoenix's debug annotations feature breaks MJML rendering ([73978](https://elixirforum.com/t/73978)). `mjml_nif` changelog shows repeated fixes for this interop — a symptom of wrapping a foreign compiler rather than owning the pipeline.

**Preview dashboard is thin.** Swoosh mailbox does not auto-refresh — a Bamboo regression: *"having to find the appropriate window/tab with Swoosh /dev/mailbox and refreshing it manually to check if/what has been just sent"* ([46094](https://elixirforum.com/t/46094)). Breaks with dynamic ESP templates ([46034](https://elixirforum.com/t/46034)). No seed/fixture previews like Rails ActionMailer::Preview.

**Deliverability is DIY.** Zero hits for `List-Unsubscribe` as a built-in in Swoosh or Bamboo — a universal requirement since Feb 2024. Users hit Gmail/Outlook spam walls ([46301](https://elixirforum.com/t/46301), [22738](https://elixirforum.com/t/22738)). DKIM/SPF/DMARC primitives exist in `mailibex` but aren't integrated with Swoosh or published to Hex.

**Inbound email has been asked for since 2018, still unanswered.** *"I know there are many different libraries to handle sending mail, but are there any for handling receiving of emails?"* ([22785](https://elixirforum.com/t/22785)). *"I would like to write an Elixir/Phoenix application that simply serves as an email router"* ([42469](https://elixirforum.com/t/42469)).

**Marketing/newsletter is a leak.** When users ask how to handle newsletters in Phoenix, the community routes them to Mailchimp or listmonk ([53660](https://elixirforum.com/t/53660)) — i.e., *leave Elixir*.

**Verdict: email is a real, partially-filled gap.** Swoosh solves compose-and-deliver. Everything else is a daily friction point with no canonical library. The Rails framing — *"There doesn't appear to be a standard way of doing this, which surprises me. Coming from the Rails world…"* ([28840](https://elixirforum.com/t/28840)) — has not aged out.

---

## 3. Prior-art decisions, distilled

This is where the design work lives. Each row below is a battle-tested pattern plus a specific footgun to avoid.

### Rails ActionMailer + ActionMailbox + Letter Opener

Anchor of \"Mailers are controllers for email.\" Convention-over-configuration for template lookup (`app/views/<mailer>/<action>.{html,text}.erb`), auto-multipart when both formats exist, pluggable delivery methods, parameterized mailers with `.with(params)`, callbacks, interceptors/observers, previews at `/rails/mailers` with live reload, `ActiveJob` integration via `deliver_later`. ActionMailbox adds ingresses (Mailgun/Postmark/SendGrid/Mandrill/relay) → `InboundEmail` model (ActiveStorage-backed raw MIME) → routing DSL → Mailbox classes → auto-incineration after 30 days → `/rails/conductor/action_mailbox` dev UI.

**Lessons to port:** The \"controller for email\" mental model, automatic multipart, `/rails/mailers` preview routes, the Mailbox routing DSL, per-env preview interceptors, and — above all — the **Conductor dev UI** for synthesizing inbound emails. That last feature is absent from every other ecosystem and is a DX superpower.

**Footguns to avoid:** Previews drift silently from real callers (no compile-time link). `default_url_options[:host]` forgetting is the #1 runtime failure. `deliver_later` serialization blows up at dequeue on non-GlobalID objects. Interceptors are stringy class names; easy to typo and leave sandbox on in prod. `ActionMailer::Base.deliveries` is global, not per-test-process.

### Laravel Mail + Mailables + Mailcoach

One-class-per-email (`OrderShipped extends Mailable`) with the v9+ `envelope()` / `content()` / `attachments()` lifecycle split. `ShouldQueue` marker interface for opt-in async. Markdown Mailables ship pre-built Blade components (`x-mail::message`, `x-mail::button`) — the shortest path to responsive email that covers 80% of transactional cases. `Mail::fake()` plus `assertSent(fn($m) => $m->hasTo(...)->hasTag(...))` is the cleanest test DSL in any ecosystem. Preview a Mailable by returning it from a route — zero ceremony.

**Mailcoach** (Spatie's commercial Laravel package) is the single most important data point for the marketing opportunity: an **embeddable** campaign + automation + transactional manager sold as a paid Laravel package with an \"unlimited-domains license\" aimed at SaaS products embedding it for customers. Keila does not fill this slot. Laravel has demonstrated commercial demand.

**Footguns:** `Mail::to()` is cumulative on the facade — loop bugs are routine. Queued Mailables + DB transactions require `afterCommit()`. Public-property-auto-exposure-to-Blade is an implicit rule that surprises newcomers.

### Django + django-anymail

**The single most important architectural lesson in the entire research base.** Anymail does not replace Django's `EmailMessage`; it extends it with ESP-normalized attributes (`tags`, `metadata`, `merge_data`, `merge_global_data`, `merge_headers`, `template_id`, `track_opens`, `track_clicks`, `esp_extra`) and normalizes every provider's webhook into a single `AnymailTrackingEvent` dispatched via Django signals. The canonical event taxonomy — `queued / sent / rejected / failed / bounced / deferred / delivered / autoresponded / opened / clicked / complained / unsubscribed / subscribed / unknown` — plus the canonical reject_reason set (`invalid / bounced / timed_out / blocked / spam / unsubscribed / other`) is the de-facto standard, tested across 14+ providers.

**Port verbatim.** Elixir should adopt this taxonomy exactly, dispatch events via `Phoenix.PubSub` or a handler behaviour, and preserve an `esp_event` escape hatch.

**Footguns:** event ordering is not guaranteed across providers; batched webhooks require per-event error isolation (one handler raising should not nuke the whole batch); non-ASCII and merge_headers unsupported by some providers — raise explicit `UnsupportedFeature` rather than silent no-op.

### Resend + React Email + JSX Email

Resend's SDK is the cleanest modern provider shape: flat POJO, `{data, error}` return tuple, `scheduled_at` first-class, batch via `resend.batch.send([...])`, `react:` field that accepts a component. React Email separates template authoring (a JSX component library emitting email-safe HTML with MSO fallbacks baked into each primitive) from sending (any provider). The `<Tailwind>` wrapper compiles utility classes to inlined styles at render time. `PreviewProps` static property on components doubles as preview fixture and test data. Dev server with per-email \"Send to me\" button, device toggle, hot reload.

**Lessons to port:** Phoenix function components for email are the obvious analog — `<.button href=...>`, `<.container>`, `<.heading>`, `<.preheader>` with MSO VML fallbacks baked in. `preview_props/0` callback on mailer modules. Flat POJO send form (`Mail.send(%{to:, from:, subject:, html:})`) alongside the module-based Mailable for one-offs. Linter and spam-score as mix tasks.

**Footguns:** React Email preview is a bundled Next.js app and occasionally breaks on Next.js internal changes (issue #2432). Hooks don't work in preview (#649). \"Works across all clients\" is only true for shipped components; custom styles still require cross-client testing.

### MJML vs. Maizzle vs. component-native

| | MJML | Maizzle | React Email / Phoenix Components |
|---|---|---|---|
| Authoring | Custom XML DSL | Raw HTML + Tailwind | Components (JSX/HEEx) |
| Responsive | Free (built-in) | `dark:` + media queries via Tailwind | Via shipped primitives with MSO fallback |
| Dark mode | Hand-coded CSS | First-class via Tailwind `dark:` | Component/style level |
| Build pipeline | Compiler only | Full SSG (inline / minify / plaintext / URL params) | Component render + juice |
| Composability | Low (XML tags) | Medium (PostHTML `<component>`) | High (full function composition) |
| Elixir integration | `mjml_eex` via mrml NIF (fragile HEEx interop) | Possible via Tailwind + Premailex | Natural — Phoenix.Component is already HEEx |
| Client compatibility | Proven table output | You maintain tables | Ships per-component MSO fallbacks |

**Recommendation:** Make **HEEx + Phoenix.Component the default renderer** with shipped email primitives, CSS inlining via Premailex, auto plaintext via Floki, optional Tailwind with an email-safe preset. Ship **MJML via mrml NIF as an opt-in alternate renderer** for teams who want MJML's proven table output (`renderer: :mjml`). Do not build AMP for Email (dead after Cloudflare's Oct 2025 deprecation; <5% of senders use it per ESPC data).

### Provider SDK patterns that converge

All modern providers converge on a flat JSON shape with `tags`, `metadata`, `template_id`, `headers`, `attachments`, batch endpoints, template APIs, suppression APIs, and inbound parsing. The differences are idiomatic:

- **Postmark** — cleanest JSON, Message Streams separate transactional from broadcast, modular webhooks, raw MIME for bounces, **no HMAC on inbound** (Basic Auth + IP allowlist only).
- **SendGrid** — richer `personalizations[]` array, ECDSA-signed webhooks, mature dynamic templates.
- **Mailgun** — uniquely flexible Routes DSL for inbound, HMAC-SHA256 webhook signing, recipient-variables for batch merge.
- **SES** — cheapest at scale, configuration sets per-send, SNS-based inbound (not a webhook pattern).
- **Resend** — modern SDK DX, `react:` field, `scheduled_at` first-class, newest.

**Normalize the send shape to Resend's flat POJO** as the canonical lingua franca; let each adapter translate to SendGrid `personalizations` or SES v2 as needed.

### Rails Noticed — the multi-channel generalization

Noticed treats each event as a `Notifier` class declaring `deliver_by :database / :email / :slack / :ios / :action_cable` with per-channel conditionals (`if: -> recipient { recipient.prefers_email? }`), delays, and bulk-vs-per-recipient distinction. Each channel gets its own job so Slack failing doesn't block email.

**Port as a companion package.** Not v1 scope, but the right abstraction for v2: an event-first model where email is one of many delivery channels.

### Local dev SMTP catchers

Letter Opener, MailCatcher, MailHog (unmaintained since 2020), Mailpit (9.1k ★, actively maintained Go binary). **Mailpit is the current state-of-art**: REST API, HTML compatibility check via caniemail, link check, SpamAssassin hook, chaos mode, SMTP relay/release, WebSocket push, 100–200 emails/sec throughput.

**Recommendation:** Don't reinvent a local SMTP catcher. Ship a first-class Mailpit integration for polyglot teams. Own the in-app Phoenix LiveView preview/inbox layer where the DX wins are.

---

## 4. Deliverability and compliance in 2025–2026

This is the single most concrete reason to build a new library **now** rather than wait. The compliance landscape changed materially in 2024–2025 and Swoosh/Bamboo did not respond.

**Gmail/Yahoo bulk sender rules** (Feb 2024 → Nov 2025 enforcement) require, for any sender over 5,000 msgs/day to consumer inboxes: SPF + DKIM + DMARC with alignment (≥ `p=none`), PTR, TLS, RFC 5322 compliance, one-click unsubscribe (RFC 8058), honoring unsubscribes within 48 hours, spam rate <0.30%. Gmail escalated to 550-class **permanent rejections** in November 2025. Microsoft (Outlook/Hotmail) joined the requirements in May 2025 — now \"Yahooglesoft.\" Classification as a bulk sender is permanent, not reversible.

**One-click unsubscribe (RFC 8058 + RFC 2369)** requires both `List-Unsubscribe: <https://...>, <mailto:...>` and `List-Unsubscribe-Post: List-Unsubscribe=One-Click` headers, signed into DKIM's `h=` tag, with an HTTPS POST endpoint that is idempotent, returns 200 without redirect, and encodes an opaque token (not the raw email). Zero Elixir libraries help with this today.

**Feedback-ID header** for Gmail Postmaster is mandatory for FBL data. Format: `campaign:customer:mailtype:stableSenderID`. Must be in the DKIM `h=` tag.

**The library should ship these as MUSTs:**

1. RFC-compliant message construction (Message-ID, Date, MIME-Version, UTF-8 headers).
2. DKIM signing support (in-library for self-hosted relay; pass-through for ESPs that sign).
3. One-click unsubscribe helpers: signed opaque-token generation, a Phoenix controller template for the POST endpoint that is idempotent and 200-without-redirect.
4. Message-stream separation: distinct `:transactional` vs `:marketing` config; marketing auto-adds `List-Unsubscribe`, `List-Unsubscribe-Post`, `Precedence: bulk`, physical-address footer; transactional auto-adds `Auto-Submitted: auto-generated`.
5. Suppression list (Ecto-backed, pluggable): auto-suppress on hard bounce / complaint / explicit unsubscribe; pre-send check returns `{:error, :suppressed}`.
6. Normalized webhook events (Anymail taxonomy) with mandatory HMAC/signature verification per provider.
7. Physical address enforcement for marketing stream (refuse to send without it — CAN-SPAM/CASL requirement).
8. Feedback-ID header emission with stable SenderID.

**SHOULDs** include `mix mail.doctor` (live DNS checks for SPF/DKIM/DMARC/MTA-STS with alignment analysis), consent records schema (GDPR SAR export + erase), soft-bounce escalation (5 consecutive in 7 days → hard suppress), telemetry events at every stage, rate limiting per recipient domain, tracking-off-by-default with per-recipient opt-out.

**Tracking pixels and click rewriting are a legal hot zone** under GDPR/ePrivacy. Apple Mail Privacy Protection proxy-fetches all images on delivery, inflating open rates toward 100% for ~50% of consumer mail; Gmail caches via googleusercontent.com. Treat open rate as aggregate trend only. Link rewriting must use signed tokens (never open-redirect), a dedicated subdomain (never the brand apex), and should be disabled by default on messages carrying auth tokens (password reset, magic link). This is a differentiator: **ship tracking off by default**, unlike most commercial ESPs.

---

## 5. Canonical webhook event taxonomy

Adopt Anymail's vocabulary verbatim. It is the only normalized taxonomy with real adoption across 14+ providers.

```elixir
defmodule Mail.TrackingEvent do
  defstruct [
    :event_id,       # provider-unique, for idempotency
    :event_type,     # canonical atom, see below
    :message_id,     # ties back to send-time return
    :recipient,
    :timestamp,
    :description,
    :reject_reason,  # when type in [:rejected, :bounced]
    :mta_response,
    :tags, :metadata,
    :click_url, :user_agent, :ip_address, :geo,
    :provider,       # :postmark | :sendgrid | :mailgun | :ses | :resend | ...
    :esp_event       # raw payload escape hatch
  ]
end
```

| `event_type` | Meaning | Canonical action |
|---|---|---|
| `:queued` | ESP accepted for delivery | log |
| `:sent` | ESP handed off to receiving MTA | log |
| `:rejected` | ESP refused (suppression, policy) | suppress |
| `:failed` | ESP couldn't process (template error) | alert |
| `:bounced` | Receiving MTA rejected | if hard → suppress; if soft → counter |
| `:deferred` | Transient; will retry | log |
| `:delivered` | Receiving MTA accepted | log |
| `:autoresponded` | Vacation/auto-reply | log |
| `:opened` | Open pixel fired | aggregate metric only (MPP) |
| `:clicked` | Tracked link clicked | engagement metric |
| `:complained` | Spam report | suppress immediately |
| `:unsubscribed` | Recipient unsubscribed | suppress; honor within 48h |
| `:subscribed` | List-management | log |
| `:unknown` | Unrecognized | log |

`reject_reason` ∈ `:invalid | :bounced | :timed_out | :blocked | :spam | :unsubscribed | :other | nil`.

---

## 6. The architecture recommendation

**A suite of 3–4 coordinated Hex packages built on Swoosh**, following the Oban Web / LiveDashboard mount pattern. Do not replace Swoosh; compose on top of it. Do not monorepo everything into one package; different users want different parts.

```
mail_core          — shared primitives, no UI
├── Mail.Email (delegates to %Swoosh.Email{})
├── Mail.Mailable (behaviour: envelope / content / attachments / preview_props)
├── Mail.Components (Phoenix HEEx primitives with MSO fallbacks)
├── Mail.Markdown (Markdown → Components theme)
├── Mail.Pipeline (render → Tailwind → Premailex inline → minify → plaintext)
├── Mail.TrackingEvent, Mail.InboundMessage (normalized structs)
├── Mail.Suppressions (Ecto schema + behaviour for storage)
├── Mail.Webhooks (router plug + per-provider HMAC verifiers)
├── Mail.Adapters.{Postmark, SendGrid, Mailgun, SES, Resend, SMTP, Failover}
└── Mail.TestAssertions (extends Swoosh.TestAssertions)

transactional_mail — OPTIONAL, mountable UI + send API for app-side transactional
├── preview dashboard (LiveView)
├── sent-email inbox (with webhook timeline, resend, suppression UI)
└── unsubscribe controller template

marketing_mail     — contacts, lists, segments, campaigns, forms, analytics, UI
├── Ecto schemas (contacts, lists, memberships, segments, campaigns, sends, events, links, forms, form_fields, templates, suppressions, api_keys)
├── segment query language (Keila-style MongoDB-ish JSON → SQL)
├── LiveView admin dashboard (router macro)
├── Oban workers (campaign scheduler, rate-limited sender)
└── double opt-in + form controller + unsubscribe + preference center

inbound_mail       — independent from marketing/transactional
├── Mail.Inbound.Router (routing DSL: route ~r/save@/, to: Mailbox)
├── Mail.Inbound.Mailbox behaviour
├── Ingress plugs: Postmark, SendGrid, Mailgun, SES (SNS), Relay (SMTP pipe)
├── Storage behaviour (LocalFS, S3; Waffle optional)
├── Oban-backed async routing with incineration
└── LiveView Conductor (dev-only; synthesize / replay inbound emails)

mail_notifier      — v2, companion package (Noticed-equivalent)
└── Notifier behaviour with deliver_by :email / :database / :pubsub / :slack / :sms / :push
```

### Why a suite, not a monolith

Orthogonal problem spaces with different users: someone shipping password resets shouldn't inherit subscriber/list schemas. Someone building a newsletter shouldn't inherit inbound infrastructure. Each package follows the **Oban Web precedent**: `import MarketingMail.Router` + `marketing_mail_dashboard "/admin/marketing"` in the host app's router. Single `use Mail.Mailer`. Zero Node. Zero migrations the user doesn't want.

### Why build on Swoosh rather than replace it

Swoosh has 19M+ downloads, 15+ adapters with community-maintained extensions, a proven `Swoosh.Adapter` / `Swoosh.ApiClient` / `Swoosh.TestAssertions` architecture, and active maintenance through April 2026. Replacing it fragments the ecosystem and throws away the adapter network effect. Adopting it as the transport layer under a higher-level framework is strictly dominant.

### The Mailer DX target

```elixir
defmodule MyApp.Mailers.UserMailer do
  use Mail.Mailable,
    from: {"MyApp", "noreply@myapp.com"},
    layout: {MyAppWeb.EmailLayouts, :default},
    components: MyAppWeb.EmailComponents,
    stream: :transactional

  import MyAppWeb.Gettext

  deftyped :welcome do
    field :user, User.t()
    field :magic_link, String.t()
  end

  mail :welcome do
    subject   dgettext("emails", "Welcome, %{name}!", name: @user.name)
    preheader dgettext("emails", "Your account is ready.")
    to        @user.email
    tag       "welcome"
    metadata  %{user_id: @user.id}

    ~H"""
    <.container>
      <.heading>Hey {@user.name} 👋</.heading>
      <.text>Thanks for signing up. Click below to activate.</.text>
      <.button href={@magic_link}>Activate account</.button>
    </.container>
    """
  end

  def preview_props(:welcome) do
    %{user: %User{name: "Ada", email: "ada@example.com"},
      magic_link: "https://app.myapp.com/magic/abc"}
  end
end

# Callsite
MyApp.Mailers.UserMailer.deliver(:welcome, user: u, magic_link: link)
MyApp.Mailers.UserMailer.deliver_later(:welcome, [user: u, magic_link: link], queue: :mailers)
MyApp.Mailers.UserMailer.deliver(:welcome, [...], tenant: current_tenant, locale: "fr")
```

Key design choices that differentiate this from every prior attempt:

- **Colocated `preview_props/1`**: Rails' single biggest preview footgun is silent drift between preview modules and real callers. Colocating fixtures in the mailer module makes the compiler enforce signature alignment.
- **`deftyped` struct validation**: Laravel Mailable has typed constructors; React Email has TypeScript. The Elixir analog is a struct + validator (`Peri` or a built-in) enforced at `deliver` time.
- **`deliver_later` as a first-class method**: closes the single most cited Swoosh gap.
- **Per-tenant adapter resolver**: `config :mail_core, resolver: {MyApp.TenantRouter, :resolve, []}` lets every send resolve to a tenant-scoped adapter config (Postmark Server / SendGrid Subuser / Resend per-domain key). Stripe-Connect-style multi-tenancy without ceremony.
- **Process-isolated test mailbox**: `Mail.TestAssertions` writes to the per-test process dictionary, exploiting BEAM's process isolation — no manual `deliveries.clear` dance.

### The preview dashboard target

A single LiveView mounted via `mail_dashboard "/dev/mail"` with:

- Sidebar: tree of mailers → mail functions → preview scenarios (auto-discovered from `preview_props/1`).
- Top bar: device (320/480/600/768 widths), dark/light toggle, client simulator (Gmail/Outlook-Win/Apple — toggleable CSS-stripping emulation), locale dropdown, RTL toggle, HTML/Text/Raw/Headers tabs.
- Main pane: sandboxed `<iframe srcdoc>` re-rendering on every assigns change; Phoenix LiveReload hot-reloads on template edits.
- Right drawer: editable assigns form that re-renders live (React Email / Mailing pattern — nobody in the Rails world has this).
- \"Send test to me\" button.
- In prod (admin mount): **Inbox** tab showing sent emails with webhook delivery timeline (sent → delivered → opened → clicked → bounced), resend button, suppression list management.

This is what beats React Email, Mailing, and ActionMailer::Preview combined — hot reload + device + dark + client sim + live assigns form + webhook timeline, native to Phoenix with no Node dependency.

---

## 7. Prioritized feature roadmap

### v0.1 — Validation (3 months, mail_core only)

Goal: prove the thesis with the minimum viable alternative to Swoosh + Phoenix.Swoosh + Premailex + mjml_eex manually wired. Ship:

- `Mail.Mailable` behaviour + `deliver / deliver_later / deliver_many` (Oban integration).
- `Mail.Components`: `<.container>`, `<.section>`, `<.row>`, `<.column>`, `<.heading>`, `<.text>`, `<.button>`, `<.img>`, `<.link>`, `<.hr>`, `<.preheader>` — all with MSO VML fallbacks baked in.
- `Mail.Pipeline`: HEEx → CSS inline (Premailex) → minify → auto-plaintext (Floki).
- Gettext-first i18n (dgettext with `"emails"` domain).
- `Mail.TestAssertions` extending Swoosh's with `assert_mail_sent MailerMod, :scenario, fn params -> ... end`, `last_email/0`, `wait_for_email/1`.
- Preview dashboard (dev): sidebar + device toggle + dark toggle + HTML/Text/Raw tabs + auto-discover `preview_props/1`.
- Docs: migration guide from raw Swoosh + Phoenix.Swoosh.

### v0.5 — Deliverability differentiation (3–6 months)

What makes it THE canonical choice for production senders. Ship:

- List-Unsubscribe + List-Unsubscribe-Post headers + signed-token unsubscribe controller generator.
- Message-stream separation (`:transactional` vs `:marketing`) with auto-inject rules.
- `Mail.Suppressions` Ecto schema + pre-send check + auto-add on bounce/complaint/unsubscribe.
- `Mail.Webhooks` router plug with per-provider HMAC verification (Postmark Basic, SendGrid ECDSA, Mailgun HMAC-SHA256, SES SNS signature, Resend).
- Normalized `Mail.TrackingEvent` dispatch via handler behaviour.
- `mix mail.doctor` — live DNS checks (SPF lookup count, DKIM presence, DMARC policy, alignment).
- Feedback-ID helper with stable SenderID.
- Per-tenant adapter resolver.
- Prod-mountable admin dashboard with sent-email inbox + webhook timeline + resend + suppression UI.

### v1.0 — Marketing module (6–9 months after v0.5)

Separate `marketing_mail` package. The Keila-equivalent but embeddable. Ship:

- Schemas: contacts, lists, memberships, segments, campaigns, sends, events, links, forms, form_fields, templates.
- Double opt-in + hosted/embedded signup forms.
- Segment query language (Keila's MongoDB-ish JSON AST compiled to SQL).
- Broadcast campaigns: MJML / block editor / markdown; scheduled send; Liquid personalization.
- Analytics dashboard (Listmonk-style materialized view).
- LiveView admin mounted via `marketing_mail_dashboard`.
- Rate-limited Oban sender (per-provider rate, per-domain rate).
- Preference center LiveView.

### v1.5 — Inbound module (parallel, independent package)

Separate `inbound_mail` package. Ship:

- `Mail.Inbound.Router` DSL (recipient regex, subject pattern, header matcher, function matcher).
- `Mail.Inbound.Mailbox` behaviour with `before_process / process / bounce_with`.
- Ingress plugs: Postmark (JSON), SendGrid (multipart), Mailgun (form/mime), SES (SNS), Relay (SMTP via gen_smtp).
- Storage behaviour with LocalFS + S3 reference adapters.
- Async routing via Oban with incineration.
- `Mail.Inbound.Conductor` — dev LiveView for synthesizing/replaying inbound.

### v2 — Differentiation (pick 1–2 based on community pull)

- **Drip / automation engine** on Oban Pro Workflow: triggers, audience filter, ordered steps with waits, conditional branches. Own `automation_runs` state table.
- **`mail_notifier`** companion package — Noticed-equivalent multi-channel notifier.
- **A/B subject + content** with sticky variant assignment.
- **Warmup scheduler** with automatic daily ramp.
- **BIMI record generator**.
- **Inbound Authentication-Results parser** (ARC chain handling) — useful for inbound routing decisions.

### The killer differentiator

The single feature that would make this THE canonical Phoenix email library is the **unified preview + admin dashboard**: a LiveView that is simultaneously (a) the Rails `ActionMailer::Preview` with React Email's device/dark/live-assigns UX in dev, and (b) the Postmark Activity panel with webhook delivery timeline + resend + suppression UI in prod. No other ecosystem ships this as one integrated surface. It's the natural home for every DX win identified in the research, and it leverages LiveView's real-time push in a way Rails/Laravel/Django can't match.

---

## 8. Risks and failure modes

**Scope creep is the largest risk.** The research scope covers seven distinct concerns (transactional, marketing, inbound, templating, preview, deliverability, admin). A single repo attempting all seven at once will take 18+ months and never ship. The suite-of-packages strategy mitigates this *if* v0.1 ships in 3 months and validates demand before v0.5 work begins. **Do not build marketing or inbound before v0.5 ships and adoption is proven.**

**Maintenance burden is non-trivial.** Email is a compliance-moving target (Gmail/Yahoo/Microsoft rule changes), a provider-moving target (new ESPs, API changes), and a standards-moving target (RFC updates). Expect ~20–30% of maintenance time on compliance/provider drift alone. Swoosh absorbs provider churn today; building on it delegates that cost.

**The Elixir market is smaller than Rails/Laravel/Django.** Raw Phoenix developer count is perhaps 5–10% of Rails' — BUT it skews senior and technical-lead, the users most likely to adopt a batteries-included opinionated framework (same demographic Oban serves). Commercial viability precedent: Oban Pro proves Elixir infrastructure libraries can be commercially sustainable at this market size.

**Competing directly with Swoosh fails.** Every prior \"Swoosh replacement\" attempt has died. Building on it is strictly dominant.

**Competing directly with Keila fails for marketing.** Keila owns the standalone-app slot. The winning move is the **embeddable library** slot Mailcoach commercially validated — differentiate on \"mount it in your existing Phoenix app\" rather than \"replace your email provider.\"

**React Email / JSX Email / Resend SDKs are \"good enough\" for Phoenix teams with a small Node sidecar.** The library must genuinely beat \"run a small Node process + use Resend directly\" on DX, not just match it. The winning moves are: zero Node dependency, native HEEx components, Phoenix LiveView preview dashboard with webhook timeline, first-class Oban async, compile-time typed params via `deftyped`, Gettext-first i18n.

**One-person maintainership risk.** Jonathan is already building two other libraries (auth + Stripe). Email at this scope is a full third library-ecosystem. Either (a) commit to a narrower v0.1 that can coast for 6 months, (b) find a co-maintainer early, or (c) consider a commercial model (Oban-style open core) to fund sustained work.

**Failure mode to anticipate:** v0.1 ships, gets ~1k downloads/month, but the marketing module (v1.0) never lands because scope is vast and the transactional users don't need it. This is acceptable. `mail_core` + `transactional_mail` alone would still be the best transactional email story in Elixir and worth building, even if marketing never ships.

---

## 9. Recommendation

**Build it.** Email is the single largest unaddressed framework gap in Phoenix in 2026, larger than auth (which has multiple decent libraries) or payments (where Stripe is already fine and Jonathan's in-flight lib is additive). The 2024 Gmail/Yahoo/Microsoft rules, the rise of component-based email, and the broken state of MJML + HEEx interop have created a rare alignment: a concrete compliance deadline, a concrete DX pattern to steal, and a concrete demonstrated incumbent weakness — all at once.

**Ship it as a suite, not a monolith.** Start with `mail_core` (v0.1 in 3 months). Layer `transactional_mail` + deliverability in v0.5. Add `marketing_mail` in v1.0 only if validated demand materializes. Add `inbound_mail` in parallel as a smaller independent package.

**Build on Swoosh.** Do not replace it. The adapter network effect is worth far more than any API-shape refinement.

**Own the preview + admin dashboard.** That is the irreplicable Phoenix-native advantage and the single feature worth being stubborn about.

**Copy Django Anymail's taxonomy verbatim.** It is the most portable intellectual asset in the entire research base and takes 40 lines of Elixir to port.

**Copy Rails ActionMailer's preview convention, but fix the drift.** Colocate `preview_props/1` on the mailer itself so the compiler catches signature mismatches Rails silently permits.

**Copy Laravel Mailcoach's commercial thesis.** Embeddable-for-SaaS is the slot Keila cannot fill and commercial validation already exists.

**Ship tracking off by default.** GDPR/ePrivacy pressure + Apple MPP make open tracking unreliable anyway. On-by-default tracking is a legal liability; off-by-default tracking with opt-in is a differentiator.

The batteries-included Phoenix email ecosystem is achievable, differentiated, and commercially sustainable at Phoenix-market scale. The only real question is discipline of scope: v0.1 must not try to be v1.0.

---

## 10. Reference link table

### Elixir ecosystem
- Swoosh — https://hex.pm/packages/swoosh · https://github.com/swoosh/swoosh · https://hexdocs.pm/swoosh/Swoosh.html · https://hexdocs.pm/swoosh/Swoosh.Adapters.Local.html · https://hexdocs.pm/swoosh/Swoosh.TestAssertions.html
- Bamboo — https://hex.pm/packages/bamboo · https://github.com/beam-community/bamboo
- Phoenix.Swoosh — https://hex.pm/packages/phoenix_swoosh
- gen_smtp — https://hex.pm/packages/gen_smtp
- DockYard mail — https://hex.pm/packages/mail · https://github.com/DockYard/elixir-mail
- mailibex — https://github.com/kbrw/mailibex
- Premailex — https://hex.pm/packages/premailex
- mjml NIF — https://hex.pm/packages/mjml · https://github.com/adoptoposs/mjml_nif
- mjml_eex — https://hexdocs.pm/mjml_eex · https://github.com/akoutmos/mjml_eex
- mua — https://hex.pm/packages/mua
- Keila — https://github.com/pentacent/keila · https://www.keila.io/docs/
- Oban Pro Workflow — https://oban.pro · https://oban.pro/docs/pro/1.5.3/Oban.Pro.Workflow.html

### Community pain points
- ElixirForum 65703 (deliver_later gap) — https://elixirforum.com/t/best-practice-for-replacing-bamboos-deliver-later-and-deliver-later-with-swoosh/65703
- ElixirForum 44657 (Tailwind email) — https://elixirforum.com/t/has-anyone-figured-out-how-to-style-emails-with-tailwindcss-on-phoenix-1-6/44657
- ElixirForum 69206 (MJML + HEEx) — https://elixirforum.com/t/heex-parsing-breaks-on-some-mjml/69206
- ElixirForum 46094 (mailbox auto-refresh) — https://elixirforum.com/t/phx-1-6-x-swoosh-local-development-e-mail-preview-mailbox-auto-refresh/46094
- ElixirForum 22785 (inbound email) — https://elixirforum.com/t/are-there-any-libraries-that-help-with-receiving-email-in-an-elixir-application/22785
- ElixirForum 42469 (inbound router) — https://elixirforum.com/t/receiving-email-in-a-phoenix-1-6-app-should-i-switch-out-swoosh-and-use-mailman/42469
- ElixirForum 53660 (newsletter) — https://elixirforum.com/t/good-practices-for-email-sending-email-and-newsletter-system/53660
- Swoosh #463 (runtime config) — https://github.com/swoosh/swoosh/issues/463

### Rails prior art
- ActionMailer Basics — https://guides.rubyonrails.org/action_mailer_basics.html
- ActionMailer::Preview — https://api.rubyonrails.org/classes/ActionMailer/Preview.html
- ActionMailer::Parameterized — https://api.rubyonrails.org/classes/ActionMailer/Parameterized.html
- Action Mailbox Basics — https://guides.rubyonrails.org/action_mailbox_basics.html
- Mail gem — https://github.com/mikel/mail
- Letter Opener — https://github.com/ryanb/letter_opener
- Letter Opener Web — https://github.com/fgrehm/letter_opener_web
- Mailpit — https://github.com/axllent/mailpit · https://mailpit.axllent.org/
- Noticed gem — https://github.com/excid3/noticed
- Caffeinate (drip) — https://github.com/joshmn/caffeinate

### Laravel / Django / Node prior art
- Laravel Mail — https://laravel.com/docs/11.x/mail · https://laravel.com/api/11.x/Illuminate/Mail/Mailable.html
- Mailcoach — https://mailcoach.app · https://spatie.be/products/mailcoach · https://github.com/spatie/Mailcoach
- django-anymail — https://anymail.dev · https://github.com/anymail/django-anymail · https://anymail.dev/en/stable/sending/tracking/
- Resend — https://resend.com · https://github.com/resend/resend-node
- React Email — https://react.email · https://github.com/resend/react-email · https://react.email/docs/utilities/render
- JSX Email — https://jsx.email · https://github.com/shellscape/jsx-email
- Mailing (Rails-inspired) — https://www.mailing.run
- MJML — https://mjml.io · https://github.com/mjmlio/mjml · https://mjml.io/documentation/
- Maizzle — https://maizzle.com · https://github.com/maizzle/framework
- Listmonk — https://listmonk.app · https://github.com/knadh/listmonk
- caniemail — https://www.caniemail.com

### Provider docs
- Postmark webhooks — https://postmarkapp.com/developer/webhooks/webhooks-overview
- Postmark inbound — https://postmarkapp.com/developer/webhooks/inbound-webhook
- SendGrid Event Webhook — https://www.twilio.com/docs/sendgrid/for-developers/tracking-events/event
- SendGrid Inbound Parse — https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/setting-up-the-inbound-parse-webhook
- Mailgun Routes — https://documentation.mailgun.com/docs/mailgun/user-manual/receive-forward-store/routes
- Mailgun webhooks security — https://documentation.mailgun.com/docs/mailgun/user-manual/webhooks/securing-webhooks
- AWS SES inbound — https://docs.aws.amazon.com/ses/latest/dg/receiving-email-action-s3.html
- Cloudflare Email Workers — https://developers.cloudflare.com/email-routing/email-workers/

### Deliverability and compliance
- RFC 5322 (message format) — https://datatracker.ietf.org/doc/html/rfc5322
- RFC 2369 (List-Unsubscribe) — https://datatracker.ietf.org/doc/html/rfc2369
- RFC 2919 (List-ID) — https://datatracker.ietf.org/doc/html/rfc2919
- RFC 3834 (Auto-Submitted) — https://datatracker.ietf.org/doc/html/rfc3834
- RFC 6376 (DKIM) — https://datatracker.ietf.org/doc/html/rfc6376
- RFC 7208 (SPF) — https://datatracker.ietf.org/doc/html/rfc7208
- RFC 7489 (DMARC) — https://datatracker.ietf.org/doc/html/rfc7489
- RFC 8058 (one-click unsubscribe) — https://datatracker.ietf.org/doc/html/rfc8058
- RFC 8461 (MTA-STS) — https://datatracker.ietf.org/doc/html/rfc8461
- RFC 8617 (ARC) — https://datatracker.ietf.org/doc/html/rfc8617
- Google sender guidelines — https://support.google.com/mail/answer/81126
- Google sender FAQ — https://support.google.com/a/answer/14229414
- Google Postmaster Tools — https://postmaster.google.com
- Yahoo sender best practices — https://senders.yahooinc.com/best-practices/
- Microsoft SNDS — https://sendersupport.olc.protection.outlook.com/snds/
- Postmark one-click unsubscribe — https://postmarkapp.com/support/article/1299-how-to-include-a-list-unsubscribe-header
- Red Sift 2026 sender requirements — https://redsift.com/guides/bulk-email-sender-requirements
- Litmus dark mode — https://www.litmus.com/blog/the-ultimate-guide-to-dark-mode-for-email-marketers
- Litmus preview text — https://www.litmus.com/blog/the-ultimate-guide-to-preview-text-support
- Apple MPP analysis — https://postmarkapp.com/blog/how-apples-mail-privacy-changes-affect-email-open-tracking

### Legal
- CAN-SPAM FTC guide — https://www.ftc.gov/business-guidance/resources/can-spam-act-compliance-guide-business
- CASL (Canada) — https://crtc.gc.ca/eng/internet/anti.htm
- GDPR — https://gdpr.eu/