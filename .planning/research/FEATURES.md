# Feature Research — mailglass v0.2 (Production-Credible Core)

**Domain:** Phoenix-native transactional email framework — v0.2 increment on shipped v0.1
**Researched:** 2026-04-26
**Milestone scope:** v0.2 NEW features only. v0.1 features (TS-01..TS-20, DF-01..DF-12) are shipped and not re-researched here.
**Confidence:** HIGH (sourced from framework comparisons + RFC + ESP docs + ecosystem research)

---

## Executive Framing

v0.2 has three pillars. They are not equal-weight:

1. **API stability** (highest stakes) — downstream OSS deps (`accrue` and others) are about to pin to mailglass. Every breaking change after v0.2 multiplies cost across downstream pinners. The Mailable API redesign is the single most consequential change in this milestone.
2. **Deliverability floor** (compliance-driven) — RFC 8058 + auto-suppression are legally required for bulk/operational mail under Gmail/Yahoo/Microsoft 2024-2025 enforcement. They are correctness requirements, not features.
3. **Release-engineering hardening** — closing v0.1.2 debt so the publish pipeline is trustworthy for coordinated sibling releases.

The comparison frameworks (ActionMailer 7.x, Laravel Mailable 11+, Symfony Mailer 7) confirm a consistent pattern after 10+ years of API stability: **thin declarative class + named field setters + one documented escape hatch to the underlying transport**. mailglass v0.2 reaches that same maturity for the Elixir ecosystem.

---

## Feature Landscape

### Table Stakes (v0.2 — Must-Have for API Stability Promise)

These are the features that the "Production-Credible Core" milestone name requires. Missing any one means the API-freeze promise is hollow or the deliverability floor claim fails.

| # | Feature | Why Expected | Complexity | v0.1 Dependency | Source |
|---|---------|--------------|------------|-----------------|--------|
| TS-V2-01 | Native `Mailglass.Message` field setters: `to/2`, `from/2`, `subject/2`, `body/2`, `header/3`, `attach/2`, `reply_to/2`, `cc/2`, `bcc/2`, `preheader/2` — all operating on `%Mailglass.Message{}` directly without touching `%Swoosh.Email{}` | ActionMailer, Laravel Mailable, and Symfony Mailer all provide a thin fluent-setter layer that hides the underlying transport struct. After 10+ years, their adopters don't know or care what Mail::Message, Symfony\Mime\Email, or SwiftMessage look like. mailglass v0.1 injects `import Swoosh.Email` which leaks the underlying struct — adopter feedback explicitly flagged this as the #1 UX issue. | M | AUTHOR-01 (Mailable behaviour), v0.1 Message wrapper struct | v0.1 adopter feedback (STATE.md TODO-6); Laravel docs (envelope/content/attachments pattern); ActionMailer guide (mail() method hides Mail gem) |
| TS-V2-02 | `update_swoosh/2` retained as documented escape hatch — the only documented path to `%Swoosh.Email{}` mutation | Every mature framework provides exactly one escape hatch: ActionMailer exposes `message` on `MessageDelivery`; Laravel exposes `using: [fn(Email $msg)]` on Envelope; Symfony exposes `TransportInterface` injection. The escape hatch must be explicit, documented, and named — not hidden. Domain language guide §3 calls this "intentional not default." | S | TRANS-03 (Swoosh wrapper) | PROJECT.md target features; domain language doc §3 (escape hatch note) |
| TS-V2-03 | `api_stability.md` v2 — explicit public-surface freeze: which modules, typespecs, and callback signatures are stable, which are internal, what the deprecation policy is | Downstream pinners need a contract document. Elixir community expects this at 0.x boundary. Oban has `Oban.Web.api_stability.md`; sigra has a similar artifact. Without it, "stable" is a verbal claim with no enforcement. | S | All v0.1 features (defines what's frozen) | PROJECT.md driving constraint; D-22 pending decision |
| TS-V2-04 | Deprecation warnings on v0.1 Mailable paths (specifically: `import Swoosh.Email` injection removed, one-cycle grace period where old call sites get `IO.warn/2` deprecation at compile time with migration hint) | One-cycle backwards compatibility (`~> 0.1` adopters see warnings, not compile errors) is the industry norm. Phoenix itself uses this pattern on major API changes. Allows adopters to migrate at their own pace without being broken immediately. | S | AUTHOR-01 (use macro injection point) | Standard Elixir/Phoenix practice; PROJECT.md BC policy |
| TS-V2-05 | `mix mailglass.upgrade.v0_2` codemod task — mechanically rewrites the single safe transformation: replaces `import Swoosh.Email` call sites in Mailable modules with the new native setter API where the transformation is unambiguous | Mix tasks as upgrade helpers are the Phoenix/Ecto standard (see `mix phx.gen.*`, `mix ecto.gen.migration`). Igniter (v0.7.x, 2026-current) provides AST-safe rewrite via Sourceror zippers. Ambiguous cases emit a warning and leave the code unchanged rather than silently corrupting it. | M | TS-V2-01 (new API must exist first) | Igniter docs; Sourceror readme; Phoenix mix task patterns |
| TS-V2-06 | Message-stream separation: `:transactional` / `:operational` / `:bulk` as first-class atoms on `%Mailglass.Message{}` with compile-time enforcement (Credo check `NoUnstreamedBulkMailable`) and runtime enforcement (pre-send guard raises `StreamPolicyError` if stream is missing or invalid) | Postmark pioneered message streams (transactional vs broadcast/bulk infrastructure separation). Gmail/Yahoo bulk-sender rules require `:bulk` to carry RFC 8058 headers; `:transactional` must never carry List-Unsubscribe (it would imply the transactional message is bulk). The compile/runtime double-enforcement prevents policy drift. | M | PERSIST-01 (`stream` column already in `mailglass_deliveries`), AUTHOR-01 | PROJECT.md v0.2 target; Postmark Message Streams docs; Gmail bulk-sender rules |
| TS-V2-07 | RFC 8058 List-Unsubscribe auto-injection on `:bulk` (mandatory), opt-in on `:operational` — exactly two headers injected: `List-Unsubscribe: <https://...>` and `List-Unsubscribe-Post: List-Unsubscribe=One-Click` | RFC 8058 exact requirements (HIGH confidence, verified from IETF datatracker): (1) `List-Unsubscribe` MUST contain one HTTPS URI. (2) `List-Unsubscribe-Post` MUST contain exactly `List-Unsubscribe=One-Click` — no other value. (3) Both MUST be covered by a valid DKIM signature in the `h=` tag. (4) No redirects on the POST endpoint. (5) Gmail/Yahoo enforce since 2024-06; Microsoft since 2025-05. | L | TS-V2-06 (stream separation must exist first; `:bulk` is the trigger), AUTHOR-01, HOOK-01..07 (webhook ingest already built) | RFC 8058 IETF; Gmail bulk-sender rules; Postmark List-Unsubscribe guide |
| TS-V2-08 | Signed-token unsubscribe controller — `Phoenix.Token`-based HMAC URL `?t=<signed_token>` with configurable rotation, one-click POST endpoint returning 200 within implementation constraints, idempotent unsubscribe action (second POST is a no-op) | Phoenix.Token is the correct choice over JWT for in-ecosystem Phoenix apps: no extra dep, built-in max_age/rotation, built-in salt-based namespace isolation, BEAM-native. JWT adds complexity without benefit here. RFC 8058 does not specify the token format, only that the URL must be opaque and contain enough info to identify recipient + list. The POST endpoint has no RFC-specified return value requirement — but Google tests for 200 success in practice. | M | TS-V2-07 (headers must reference this endpoint), TS-V2-10 (suppression write on unsubscribe) | RFC 8058 §3; Phoenix.Token docs; OWASP token guidance |
| TS-V2-09 | `mix mailglass.gen.unsubscribe` — generates the unsubscribe controller, route, and view stubs in the adopter's app with brand-conformant defaults | Generators are table stakes for a batteries-included framework. Without `mix mailglass.gen.unsubscribe`, adopters hand-wire a non-trivial HMAC controller — the exact friction mailglass promises to eliminate. Modeled after `mix phx.gen.auth` in Phoenix. | M | TS-V2-08 (generates stubs for the controller pattern) | Phoenix generator patterns; PROJECT.md batteries-included promise |
| TS-V2-10 | Auto-suppression on `:bounced` and `:complained` events — when webhook ingest normalizes these event types, `Mailglass.Suppression` is automatically written in the same `Ecto.Multi` as the event append | Hard bounces and spam complaints are deliverability-fatal if not suppressed. This is not opt-in behavior — it is a correctness requirement. Anymail (Django) does NOT implement this automatically (leaves it to custom signal receivers). mailglass should be opinionated here. Postmark auto-deactivates on hard bounce + spam complaint. SendGrid auto-suppresses hard bounces only. | M | HOOK-01..07 (webhook ingest), PERSIST-04 (suppressions table), CORE-04 (Ecto.Multi) | Anymail docs (confirmed no auto-suppression); Postmark bounce docs; SendGrid bounce docs |
| TS-V2-11 | Auto-suppression on `:unsubscribed` events — webhook-normalized unsubscribe creates a `Suppression` with `reason: :unsubscribe` | Required by CAN-SPAM (honor within 10 business days), GDPR (consent withdrawal), and Gmail bulk-sender rules. Missing this means a recipient who unsubscribes via ESP's unsubscribe link still receives mail from the app. | S | TS-V2-10 (same mechanism, different event type) | CAN-SPAM; GDPR; Gmail guidelines |
| TS-V2-12 | Soft-bounce escalation: configurable threshold (default: 5 soft bounces in 7 days → hard suppress) with `suppression_reason: :escalated_soft_bounce`. Industry standard is 3-5 attempts over 72 hours (SendGrid); 3-5 over several days (Postmark guide); mailglass default of 5-in-7 is slightly more lenient (transactional mail gets more grace than broadcast) | ESPs do not standardize escalation thresholds — they deliberately leave this to senders. Industry consensus: 3-5 soft bounces over 3-7 days is the typical recommendation. mailglass should ship a sensible default with adopter-configurable override via NimbleOptions. | M | TS-V2-10 (core suppression write mechanism), TS-V2-06 (stream-aware: `:transactional` gets more grace than `:bulk`) | SendGrid bounce docs; Postmark bounce guide; deliverability best-practices sources |
| TS-V2-13 | `mix mailglass.suppressions.resync` — rebuilds the `mailglass_suppressions` table from the append-only `mailglass_events` ledger (projection rebuild). Supports `--dry-run` flag. Required for disaster recovery and post-migration correctness. | Append-only event ledgers require the ability to reconstruct any projection from scratch. The suppressions table is a projection of bounce/complaint/unsubscribe events. Resync restores correctness after: (a) adopter data migrations, (b) corruption recovery, (c) first-time migration from raw Swoosh. This is the operational analog of `mix ecto.reset` — necessary for trustworthy infrastructure. | M | TS-V2-10 (knows which event types trigger suppression), PERSIST-02 (event ledger), PERSIST-04 (suppressions table) | Append-only event ledger design principle (domain language doc §12); PROJECT.md core value |
| TS-V2-14 | Stable Feedback-ID format updated for stream: `{stream}:{mailable_name}:{sender_id}:{tenant_id_prefix}` — DKIM-signed, no PII per slot, ≤64 chars per slot | Gmail Feedback Loop (FBL) requires Feedback-ID for complaint rate attribution. Format: 4 colon-separated slots, broadest to most specific. Google strips PII — tenant_id must be hashed/truncated, not raw. Already exists in v0.1 (COMP-02) but needs stream-aware update per v0.2 stream separation. | S | TS-V2-06 (stream is now a first-class field), COMP-02 (v0.1 Feedback-ID base) | Google Postmaster Tools FBL docs; Gmail Feedback-ID format guide; suped.com Feedback-ID article |

### Differentiators (v0.2 Specific — What Sets mailglass Apart in This Milestone)

These are the choices that distinguish mailglass's approach from rolling your own or using Anymail directly.

| # | Feature | Value Proposition | Complexity | v0.1 Dependency | Source |
|---|---------|-------------------|------------|-----------------|--------|
| DF-V2-01 | Compile-time stream enforcement via new Credo check `NoUnstreamedBulkMailable` — Mailable modules that call `deliver/2` on `:bulk` or `:operational` without a declared stream are flagged at lint time, not runtime | No other Elixir framework enforces email stream policy at the AST level. ActionMailer has no equivalent. This is the same "domain rules at lint time" DNA from v0.1 (DF-09). Policy violations surface during `mix credo` not at 2am from a bounce spike. | M | TS-V2-06 (stream separation), LINT-01..12 (existing Credo check infrastructure) | D-17 (custom Credo checks enforce domain rules); DF-09 v0.1 |
| DF-V2-02 | `update_swoosh/2` named escape hatch — named, documented, and intentionally signal-y to discourage casual use | ActionMailer's `message` method and Laravel's `using: [fn]` are the precedent. The key insight: the escape hatch should be **findable** (documented) but **obviously non-default** (named to signal "this is the escape"). `update_swoosh/2` reads as a liability warning, not an invitation. Competitors use neutral names like `withSymfonyMessage` that don't discourage overuse. | S | TS-V2-02 (this IS the escape hatch) | Domain language doc §3 (intentional escape hatch); Engineering DNA §2 (errors as public API contract — same philosophy) |
| DF-V2-03 | One-click unsubscribe built into the framework layer, not delegated to ESP | Postmark and SendGrid auto-inject List-Unsubscribe for their own hosted unsubscribe pages — but adopters lose control of the unsubscribe flow and brand. mailglass generates an in-app controller that (a) lets adopters brand the confirmation page, (b) writes to their own suppression store, (c) gives them an audit event in the ledger. This is the difference between ESP-managed and app-managed compliance. | M | TS-V2-07 (header injection), TS-V2-08 (signed token), TS-V2-09 (generator) | Postmark List-Unsubscribe guide; RFC 8058 |
| DF-V2-04 | Resync task as explicit "projection rebuild" UX — teaches adopters to think in events, not mutable state | Most ORMs have no equivalent — suppression is mutable state that drifts from history. `mix mailglass.suppressions.resync` is the operational surface of the append-only ledger philosophy. It signals "your suppressions are a derived view of observable history, not a ground truth table." | M | TS-V2-13 | Domain language doc §12 (prefer facts first, summaries second); D-15 (append-only ledger) |
| DF-V2-05 | Igniter-based codemod upgrade task (NOT regex-based) — AST-safe rewrites with structured warnings for ambiguous cases | Phoenix generators use file templates + string injection. mailglass v0.2 uses Igniter/Sourceror zipper-based AST rewrites that are semantically aware. Ambiguous cases emit `IO.warn` + human-readable description of what couldn't be automated — rather than silently corrupting or silently skipping. This is infrastructure-grade migration tooling, not a bash sed script. | M | TS-V2-05 | Igniter docs (v0.7.x, 2026); Sourceror readme; Alembic Igniter blog |

### Anti-Features (Explicitly NOT Building in v0.2 — With Reasoning)

These are features that will be requested or seem like natural extensions. Documenting the "no" prevents re-litigation.

| # | Anti-Feature | Why People Will Ask | Why mailglass Won't (v0.2) | What to Do Instead |
|---|--------------|---------------------|---------------------------|-------------------|
| AF-V2-01 | Preference center as the List-Unsubscribe target (redirect to "manage preferences" page on one-click) | "Can we show a preference page instead of immediately unsubscribing?" | RFC 8058 requires one-click full unsubscribe — no intermediate steps, no secondary click actions. Gmail specifically rejects implementations that redirect one-click to a preference page. This is a compliance failure, not a UX choice. | Link to a preference center from the unsubscribe confirmation page (post-redirect). Build preference center on top of `Mailglass.Suppression` + a custom LiveView. Defer an optional `mix mailglass.gen.preference_center` to v0.5+. |
| AF-V2-02 | Auto-unsuppression on user action (e.g., user logs in after suppression → auto-reactivate) | "If the user is active again, shouldn't we re-enable them?" | Auto-unsuppression on user action is a deliverability anti-pattern. Hard bounces and spam complaints are evidence of address-level or relationship-level issues, not transient states. Auto-reactivation risks re-violating CAN-SPAM. Only manual admin action or explicit double opt-in re-consent should unsuppress. | `Mailglass.Suppression.remove/2` is the explicit unsuppression API for admin-initiated or consent-backed reactivation. Never call it from automated event handlers. |
| AF-V2-03 | Automatic List-Unsubscribe on `:transactional` stream | "Shouldn't all emails have unsubscribe headers for safety?" | `:transactional` messages (password resets, magic links, receipts) must NOT have List-Unsubscribe headers. Reason: (1) Gmail/Yahoo bulk-sender rules apply to bulk/promotional mail, not transactional. (2) An unsubscribe header on a password reset implies it is optional — it is not. (3) Email clients may render an "Unsubscribe" button next to password-reset emails, causing user confusion and accidental suppression of legitimate transactional accounts. | Stream policy is the enforcement mechanism: `:transactional` → never List-Unsubscribe. `:bulk` → mandatory. `:operational` → opt-in. The `NoUnstreamedBulkMailable` Credo check enforces this at lint time. |
| AF-V2-04 | Preference/frequency controls built into the unsubscribe flow ("only unsubscribe from marketing emails") | "When someone unsubscribes, offer them 'I only want weekly emails.'" | Preference management requires subscriber-list concepts (categories, frequencies, segments) which are permanently out of scope (AF-01 from v0.1). Preference centers are marketing-email infrastructure. Building them now couples mailglass to marketing-email abstractions that conflict with PROJECT.md Out of Scope. | `Mailglass.Suppression` + custom Phoenix LiveView preference page (AF-12 from v0.1 documents this pattern). v0.5+ may add `mix mailglass.gen.preference_center` as an optional scaffold. |
| AF-V2-05 | JWT-based unsubscribe tokens | "JWT is an industry standard; Phoenix.Token is Phoenix-specific." | Phoenix.Token is correct for in-Phoenix apps: no extra dep, built-in max_age rotation, salt-based namespace isolation, BEAM-native signing. JWT adds `joken` or `jose` dep, new serialization format, expiry-management overhead — for no benefit in a Phoenix-only context. JWT is appropriate when tokens cross system boundaries (e.g., to a separate API service). This token never leaves the Phoenix app. | Use `Phoenix.Token.sign/3` with dedicated salt (`"mailglass_unsubscribe"`) and configurable `max_age`. Document secret key rotation. |
| AF-V2-06 | Replacing the Igniter/Sourceror codemod with a regex-based string substitution | "Sourceror adds a dev dep; can we just use `String.replace`?" | Regex-based codemods corrupt code when adopters use multi-line patterns, aliased module names, or non-standard formatting. `String.replace` on Elixir AST is never safe for semantic rewrites. Igniter/Sourceror produces a structured diff the user can review before applying. The extra dep is optional (codemod task only, dev dep). | `mix mailglass.upgrade.v0_2` requires `:igniter` in dev deps. Adopters who decline can follow the 5-step manual migration guide in HexDocs. |
| AF-V2-07 | Soft-bounce auto-suppression with zero configurable threshold (suppress on first soft bounce) | "Hard-suppress immediately for maximum safety." | Transactional email to temporarily-full mailboxes is legitimate. Suppressing on first soft bounce causes false suppressions for real accounts (e.g., password reset fails once because mailbox was full). Aggressive suppression on `:transactional` streams reduces deliverability of legitimate auth mail. | Make the threshold configurable via NimbleOptions: `soft_bounce_escalation: [threshold: 5, window_days: 7]`. Stream-aware defaults: `:transactional` gets higher tolerance, `:bulk` gets lower tolerance. |
| AF-V2-08 | ESP-managed suppression sync (pulling Postmark/SendGrid suppression lists via API on boot) | "Can we sync the ESP's suppression list into mailglass on startup?" | ESP suppression lists are not read-all accessible. Postmark does not expose a read-all-suppressed endpoint. SendGrid's suppression list API requires pagination over potentially millions of rows. Syncing on startup creates startup latency and a race condition. The append-only ledger approach is strictly better: suppressions are derived from observed events, not pulled from external state. | The resync task (TS-V2-13) rebuilds from the local event ledger — not from ESP APIs. Adopters migrating from another system can bulk-import via a v0.5+ `mix mailglass.suppressions.import` task. |

---

## Feature Dependencies

```
TS-V2-06 Stream separation
    ├──required-by──> TS-V2-07 RFC 8058 injection (must know stream = :bulk)
    ├──required-by──> TS-V2-12 Soft-bounce escalation (stream-aware thresholds)
    ├──required-by──> TS-V2-14 Feedback-ID stream slot update
    └──required-by──> DF-V2-01 NoUnstreamedBulkMailable Credo check

TS-V2-01 Native Message field setters
    ├──required-by──> TS-V2-04 Deprecation warnings (must have replacement before deprecating)
    ├──required-by──> TS-V2-05 Codemod task (rewrites to the new API)
    └──enables──────> TS-V2-02 update_swoosh/2 escape hatch (documented alongside setters)

TS-V2-07 RFC 8058 header injection
    └──required-by──> TS-V2-08 Signed-token controller (provides the HTTPS URI the header points to)
                          └──required-by──> TS-V2-09 mix mailglass.gen.unsubscribe

TS-V2-10 Auto-suppress on :bounced/:complained
    ├──required-by──> TS-V2-11 Auto-suppress on :unsubscribed (same mechanism)
    ├──required-by──> TS-V2-12 Soft-bounce escalation (builds on suppression write path)
    └──required-by──> TS-V2-13 Suppressions resync (resync replays the same logic)

HOOK-01..07 (v0.1 webhook ingest — ALREADY BUILT)
    └──required-by──> TS-V2-10 Auto-suppression (events must arrive normalized first)

PERSIST-04 (v0.1 suppressions table — ALREADY BUILT)
    └──required-by──> TS-V2-10..TS-V2-13 (all suppression writes land here)

PERSIST-02 (v0.1 event ledger — ALREADY BUILT)
    └──required-by──> TS-V2-13 Resync (reads events to rebuild suppressions)

TS-V2-03 api_stability.md v2
    └──documents──> TS-V2-01 + TS-V2-02 + TS-V2-06..TS-V2-14 (everything frozen in v0.2)
```

### Dependency Notes (Critical Ordering)

**Stream separation (TS-V2-06) must land before RFC 8058 (TS-V2-07).** The header injection logic branches on `message.stream == :bulk`. Without stream as a first-class field on Message, the injection has no discriminant.

**Message field setters (TS-V2-01) must land before the deprecation (TS-V2-04) and codemod (TS-V2-05).** You cannot deprecate a path without first providing its replacement.

**Webhook ingest (HOOK-01..07, v0.1) is a hard prerequisite for auto-suppression.** Auto-suppression fires when normalized `:bounced`/`:complained`/`:unsubscribed` events arrive. Without normalized events, there is nothing to trigger on. This is already satisfied by v0.1.

**Suppressions table (PERSIST-04, v0.1) already exists** — v0.2 adds auto-write triggers, not the schema. The schema was purposely stubbed in v0.1 with this extension point in mind.

**RFC 8058 requires DKIM `h=` coverage for both `List-Unsubscribe` and `List-Unsubscribe-Post`.** ESPs handle DKIM signing of custom headers if the headers are present before signing. mailglass must inject both headers in the compose pipeline (before Swoosh dispatches to the adapter). Injecting headers post-dispatch is too late and violates the RFC. Known DKIM gap: SendGrid's nodejs library historically did not auto-include `List-Unsubscribe-Post` in `h=` (GitHub issue #893). Adopters should verify DKIM coverage in their ESP's diagnostic tools.

---

## Framework Comparison: Mailable API Patterns After 10+ Years

Answers the research question about how mature frameworks hide their underlying transport.

| Aspect | Rails ActionMailer 7.x | Laravel Mailable 11+ | Symfony Mailer 7+ | mailglass v0.1 (broken) | mailglass v0.2 (target) |
|--------|------------------------|---------------------|-------------------|------------------------|------------------------|
| Composition style | `mail(to:, subject:, from:)` in method body | Three-method: `envelope()`, `content()`, `attachments()` | Fluent builder: `$email->to()->subject()->html()` | `import Swoosh.Email` leaks `%Swoosh.Email{}` directly | Native setters: `to/2`, `from/2`, `subject/2` on `%Mailglass.Message{}` |
| Underlying transport exposed? | No — Mail gem fully hidden | No — Symfony Mailer hidden | No — transport DI'd, not exposed | Yes — `import Swoosh.Email` is the leakage | No — `%Swoosh.Email{}` hidden |
| Escape hatch | `.message` on `MessageDelivery` | `using: [fn(Email $msg)]` in Envelope | Inject `TransportInterface` directly | (none needed — it's all exposed) | `update_swoosh/2` — named to signal escape |
| Escape hatch friction level | Low (neutral name, easily reached) | Low (keyword arg in Envelope) | Medium (requires DI change) | N/A | Medium-High (name signals "use sparingly") |
| Stream/category concept | No first-class concept | No first-class concept | No first-class concept | `:stream` field exists but not enforced | `:transactional`/`:operational`/`:bulk` compile + runtime enforced |
| RFC 8058 auto-injection | Manual only | Manual only | Manual only | Not present | Auto on `:bulk`, opt-in on `:operational` |
| Auto-suppression on bounce | Via ActiveSuppression gem (not built-in) | Manual webhook handler | Not present | Pre-send check only (not auto-populated) | Built into webhook ingest Multi |

**Key pattern across all three mature frameworks:** The transport struct is never visible in normal authoring. The escape hatch is explicitly documented and typically named to signal its exceptional nature. After 10+ years, adopters of ActionMailer, Laravel Mailable, and Symfony Mailer can author email classes without knowing anything about the underlying transport library.

---

## RFC 8058 Implementation Details

Verified against IETF datatracker (HIGH confidence).

### Required Headers (Exact Format)

```
List-Unsubscribe: <https://app.example.com/mailglass/unsubscribe?t=OPAQUE_SIGNED_TOKEN>
List-Unsubscribe-Post: List-Unsubscribe=One-Click
```

Rules (verbatim from RFC 8058):
- `List-Unsubscribe` MUST contain one HTTPS URI. MAY also contain a `mailto:` URI (optional, secondary).
- `List-Unsubscribe-Post` value is EXACTLY `List-Unsubscribe=One-Click` — no variation permitted.
- Both headers MUST appear in the DKIM `h=` tag of a valid signature.
- No redirects on the POST endpoint (RFC explicitly prohibits: "redirected POST actions have historically not worked reliably").
- POST body will contain `List-Unsubscribe=One-Click` as the form body.

### DKIM Coverage Requirement

Headers injected BEFORE the Swoosh adapter call are covered by ESP DKIM. Headers injected post-dispatch are NOT covered. mailglass must inject both headers in the pre-dispatch compose pipeline.

Known issue (MEDIUM confidence, sourced from SendGrid GitHub issue #893): SendGrid historically did not include `list-unsubscribe-post` in `h=` even when the header was present. Adopters should verify DKIM coverage in their ESP's Postmaster-level diagnostic tools.

### Common Implementation Bugs to Avoid

1. **Unsigned URLs** — injecting headers but not verifying DKIM coverage at the ESP. Gmail silently ignores the one-click button if `h=` does not include `list-unsubscribe-post`.
2. **Preference center redirect** — pointing List-Unsubscribe to a page that requires a second click. Non-compliant; Google has confirmed this is rejected.
3. **GET endpoint instead of POST** — RFC 8058 requires POST for one-click. Implementing a GET handler is a misread of the spec.
4. **Non-opaque tokens** — including plaintext email address in the URL. RFC requires opaque identifier to prevent scraping.
5. **URL too long** — some email clients truncate headers. Keep the HTTPS URI under 200 characters. Phoenix.Token URLs with reasonable salt lengths fit easily.
6. **Injecting List-Unsubscribe on `:transactional` stream** — signals password-reset emails are optional. They are not.

### POST Endpoint Requirements

RFC 8058 does not specify a return value. In practice, Google tests for HTTP 200. The endpoint must:
- Accept `Content-Type: application/x-www-form-urlencoded` with body `List-Unsubscribe=One-Click`
- Return 200 within 5 seconds (practical industry limit; RFC does not specify)
- Be idempotent — second POST for same token must return 200, not 4xx
- Not require cookies, HTTP auth, or any session state (RFC explicit requirement)

---

## Auto-Suppression Behavior Model

### Anymail Comparison (Django World)

Anymail does NOT implement automatic suppression. It emits Django signals for normalized tracking events and leaves suppression writes to custom signal receivers. This is a deliberate design choice — Anymail normalizes events, adopters decide consequences.

mailglass v0.2 should be MORE opinionated: auto-suppression is the correct default for production email senders. The Anymail approach requires every adopter to wire the same signal receiver; mailglass does it once in the framework.

### Trigger Events

| Event Type | Action | Suppression Reason | Reversible? |
|-----------|--------|-------------------|-------------|
| `:bounced` (hard) | Immediate suppress | `:hard_bounce` | Admin-only via `Suppression.remove/2` |
| `:complained` | Immediate suppress | `:complaint` | Not reversible (Postmark won't let you reactivate; treat as permanent) |
| `:unsubscribed` | Immediate suppress | `:unsubscribe` | Admin-only with explicit consent re-confirmation |
| `:bounced` (soft, count < threshold) | Increment counter | — (no suppression yet) | N/A |
| `:bounced` (soft, count >= threshold in window) | Escalate to suppress | `:escalated_soft_bounce` | Admin-only |

### Soft-Bounce Escalation Window

Industry consensus (MEDIUM confidence, from SendGrid + Postmark + deliverability guide sources):
- SendGrid: retries for 72 hours, then converts to deferral list (not auto-suppression — explicitly left to sender)
- Postmark: auto-deactivates on hard bounce only, not soft bounce
- Deliverability expert consensus: 3-5 bounces over 3-7 days before treating as permanent

mailglass v0.2 default: `threshold: 5, window_days: 7` (transactional-mail-appropriate — more lenient than broadcast norms because password-reset mailboxes deserve more retries than newsletter addresses). Configurable via NimbleOptions.

---

## Codemod Task Design (mix mailglass.upgrade.v0_2)

### Tool Decision: Igniter + Sourceror

Igniter v0.7.x (January 2026, active maintenance) uses Sourceror for zipper-based AST rewriting. This is the correct choice because:
- Raw regex/`String.replace` — semantically unsafe, corrupts multi-line patterns and aliased module names
- Igniter/Sourceror produces a structured diff the user can review before applying
- Sourceror's patch-based approach preserves formatting for unchanged code sections; only patched nodes are reformatted
- The codemod dep is optional (`:igniter` in dev deps only)

### Mechanically Safe Rewrites (AUTO-APPLY)

The codemod task auto-applies only transformations where the AST pattern is unambiguous:

1. Remove `import Swoosh.Email` from `use Mailglass.Mailable` expansion — safe because the import is injected by the macro.
2. Replace bare `subject("Welcome")` → `subject(msg, "Welcome")` — safe when the `%Mailglass.Message{}` variable name is statically determinable in scope.
3. Replace bare `to("user@example.com")` → `to(msg, "user@example.com")` — same constraint.

### Ambiguous Cases (WARN + SKIP)

The task emits a structured warning and leaves code unchanged when:

1. The `%Mailglass.Message{}` variable name cannot be determined statically (multiple bindings, piped returns, dynamic construction).
2. The adopter has `update_swoosh/2` calls in the module — indicates manual escape-hatch usage; codemod should not touch that file.
3. The module uses `defmacro` or generates code dynamically — AST rewriting of metaprogrammed code is unsafe.

UX pattern (matching Igniter's best-effort philosophy):

```
[mailglass.upgrade.v0_2] lib/my_app/user_mailer.ex
  WARNING: Cannot automatically rewrite `subject/1` on line 12 —
  message variable binding is ambiguous. Apply manually:
    subject(msg, "Welcome to MyApp")
  See: https://hexdocs.pm/mailglass/migration-v0-2.html#mailable-api
```

---

## MVP Definition for v0.2

### Ship in v0.2 (Required for Milestone Promise)

- [x] **TS-V2-01** Native Message field setters — removes the Swoosh leakage
- [x] **TS-V2-02** `update_swoosh/2` escape hatch — documented, named
- [x] **TS-V2-03** `api_stability.md` v2 — public surface freeze
- [x] **TS-V2-04** Deprecation warnings — one-cycle BC for v0.1 adopters
- [x] **TS-V2-05** `mix mailglass.upgrade.v0_2` codemod task
- [x] **TS-V2-06** Message-stream separation with compile + runtime enforcement
- [x] **TS-V2-07** RFC 8058 List-Unsubscribe auto-injection on `:bulk`
- [x] **TS-V2-08** Signed-token unsubscribe controller (Phoenix.Token)
- [x] **TS-V2-09** `mix mailglass.gen.unsubscribe` generator
- [x] **TS-V2-10** Auto-suppress on `:bounced`/`:complained`
- [x] **TS-V2-11** Auto-suppress on `:unsubscribed`
- [x] **TS-V2-12** Soft-bounce escalation (configurable threshold)
- [x] **TS-V2-13** `mix mailglass.suppressions.resync`
- [x] **TS-V2-14** Feedback-ID stream-aware format update

### Defer to v0.3+

- Preference center generator (`mix mailglass.gen.preference_center`) — requires marketing-category concepts out of scope
- ESP suppression list API sync — pull-based import from ESP APIs
- Webhook coverage expansion (Mailgun, SES, Resend) — v0.3 milestone
- Granular stream-level unsubscribe ("unsubscribe from `:bulk` only") — requires preference model

---

## Feature Prioritization Matrix

| # | Feature | User Value | Implementation Cost | Priority | Blocks v0.2 ship? |
|---|---------|-----------|---------------------|----------|--------------------|
| TS-V2-01 | Native Message setters | HIGH | M | P1 | YES (downstream pinners) |
| TS-V2-02 | update_swoosh/2 escape hatch | HIGH | S | P1 | YES (API contract) |
| TS-V2-03 | api_stability.md v2 | HIGH | S | P1 | YES (is the promise) |
| TS-V2-04 | Deprecation warnings | MEDIUM | S | P1 | YES (one-cycle BC) |
| TS-V2-05 | Codemod task | MEDIUM | M | P1 | YES (adoption migration path) |
| TS-V2-06 | Stream separation | HIGH | M | P1 | YES (gates RFC 8058) |
| TS-V2-07 | RFC 8058 auto-injection | HIGH | L | P1 | YES (deliverability floor) |
| TS-V2-08 | Signed-token controller | HIGH | M | P1 | YES (required for TS-V2-07) |
| TS-V2-09 | gen.unsubscribe generator | MEDIUM | M | P1 | YES (batteries-included promise) |
| TS-V2-10 | Auto-suppress bounce/complaint | HIGH | M | P1 | YES (deliverability) |
| TS-V2-11 | Auto-suppress on unsubscribed | HIGH | S | P1 | YES (CAN-SPAM/GDPR) |
| TS-V2-12 | Soft-bounce escalation | MEDIUM | M | P1 | YES (suppression completeness) |
| TS-V2-13 | suppressions.resync | MEDIUM | M | P1 | YES (operational trust) |
| TS-V2-14 | Feedback-ID stream update | LOW | S | P2 | NO (polish on existing feature) |
| DF-V2-01 | NoUnstreamedBulkMailable Credo | MEDIUM | M | P1 | YES (stream enforcement) |
| DF-V2-03 | In-app unsubscribe (vs ESP-hosted) | HIGH | M | P1 | YES (brand control + audit trail) |

**Priority key:**
- P1: Ships in v0.2 — required for milestone promise
- P2: Ships in v0.2 if time allows; deferred to v0.2.1 if constrained

---

## Competitor Feature Analysis

| Feature | ActionMailer 7.x (Rails) | Laravel Mailable 11+ | Symfony Mailer 7+ | mailglass v0.2 |
|---------|-------------------------|---------------------|-------------------|----------------|
| Transport layer hidden from adopter | ✓ (Mail gem fully hidden) | ✓ (Symfony Mailer hidden) | ✓ (via DI abstraction) | ✓ (v0.2 removes Swoosh leakage) |
| Documented escape hatch | ✓ `.message` on MessageDelivery | ✓ `using: [fn]` in Envelope | ✓ inject TransportInterface | ✓ `update_swoosh/2` |
| Message-stream separation | — (no concept) | — (no concept) | — (no concept) | ✓ :transactional/:operational/:bulk |
| RFC 8058 auto-injection | — (manual only) | — (manual only) | — (manual only) | ✓ (auto on :bulk, opt-in :operational) |
| Auto-suppression on bounce | △ (ActiveSuppression gem, not built-in) | △ (manual webhook handler) | — | ✓ (built into webhook ingest Multi) |
| Soft-bounce escalation | — | — | — | ✓ (configurable threshold) |
| Codemod upgrade task | △ (`rails app:update`, no AST safety) | △ (`artisan` generators, no semantic rewrite) | — | ✓ (Igniter/Sourceror AST-safe) |
| Compile-time stream policy | — | — | — | ✓ (NoUnstreamedBulkMailable Credo) |

---

## Sources

### Verified (HIGH confidence)

- RFC 8058 IETF datatracker: https://datatracker.ietf.org/doc/html/rfc8058 — exact header format, DKIM requirements, POST endpoint rules, no-redirect requirement
- ActionMailer Basics: https://guides.rubyonrails.org/action_mailer_basics.html — `mail()` hides Mail gem, `.message` escape hatch on `MessageDelivery`
- Laravel 11 Mail docs: https://laravel.com/docs/11.x/mail — envelope/content/attachments three-method pattern, `using: [fn]` escape hatch
- Symfony Mailer docs: https://symfony.com/doc/current/mailer.html — fluent Email builder API, TransportInterface escape hatch
- Postmark List-Unsubscribe guide: https://postmarkapp.com/support/article/1299-how-to-include-a-list-unsubscribe-header — auto-injection on broadcast streams confirmed
- Google Postmaster FBL: https://support.google.com/a/answer/6254652 — 4-slot Feedback-ID format, SenderID constraints, no-PII rule
- Igniter v0.7.x docs: https://hexdocs.pm/igniter/readme.html — upgrade task, mix igniter.upgrade drop-in replacement
- Sourceror readme: https://hexdocs.pm/sourceror/readme.html — patch-based approach preserves unchanged formatting; formatting-loss caveat on full rewrites

### Verified (MEDIUM confidence)

- Anymail tracking docs: https://anymail.dev/en/stable/sending/tracking/ — confirmed NO auto-suppression in Anymail; events only, signal receivers handle consequences
- SendGrid bounce docs: https://docs.sendgrid.com/ui/sending-email/bounces — 72h retry for soft bounce; does not auto-suppress; leaves threshold to sender
- Postmark bounce handling guide: https://postmarkapp.com/guides/transactional-email-bounce-handling-best-practices — "retry a couple of times then treat as hard bounce," no exact numeric threshold
- SendGrid GitHub issue #893: https://github.com/sendgrid/sendgrid-nodejs/issues/893 — confirmed DKIM h= / List-Unsubscribe-Post coverage gap in SendGrid tooling
- Alembic Igniter blog: https://alembic.com.au/blog/igniter-rethinking-code-generation-with-project-patching — best-effort semantic rewrite, defers to human judgment on ambiguity
- Suped.com Feedback-ID format: https://www.suped.com/knowledge/email-deliverability/technical/how-should-i-format-feedback-id-for-gmail — 4-slot hierarchy (D=platform, C=client, B=stream, A=specific)

### Project-Internal (HIGH confidence)

- `.planning/PROJECT.md` — v0.2 target features, locked decisions D-22..D-24 pending, Out of Scope permanents
- `.planning/STATE.md` — milestone spec, v0.1.2 TODOs folded into v0.2
- `.planning/milestones/v0.1-research/FEATURES.md` — prior TS-/DF-/AF- catalog (v0.1 features not re-researched)
- `prompts/mailer-domain-language-deep-research.md` — domain vocabulary: Suppression/UnsubscribeToken/SuppressionReason canonical names; escape hatch intentional-not-default pattern

---

*Feature research for: mailglass v0.2 — Production-Credible Core (subsequent milestone)*
*Researched: 2026-04-26*
