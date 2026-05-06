# mailglass

> *Mail you can see through.*

## What This Is

**mailglass** is a batteries-included transactional email framework for Phoenix — the layer that sits on top of [Swoosh](https://hex.pm/packages/swoosh) and ships everything Swoosh deliberately doesn't: HEEx-native components, a LiveView preview/admin dashboard, normalized webhook events, signed unsubscribe tokens with RFC 8058 List-Unsubscribe headers, message-stream separation, suppression lists, an append-only event ledger, multi-tenant routing, and `mix mail.doctor` deliverability checks. It's for senior Phoenix teams shipping production transactional email (welcome flows, password resets, magic links, receipts, notifications) who today rebuild 40% of ActionMailer + Anymail + ActionMailbox by hand on every project.

It is shipped as three sibling Hex packages: `mailglass` (core), `mailglass_admin` (mountable LiveView dashboard), and `mailglass_inbound` (Action Mailbox equivalent — post-`v1.0`).

## Current State

**`v1.0 Stability Lock` shipped on 2026-05-06.**

- Planning milestone closed: 4 phases (35-38), 12 plans, all complete
- Current package version in repo: `mailglass` 0.3.2 / `mailglass_admin` 0.3.2
- Release posture: repo proof and rehearsal artifacts are complete; the live publish still follows the Phase 38 checklist and external closeout steps

v0.6 milestone closed 2026-05-05. 3 phases (32-34), 9 plans, Production Maturity complete.
v0.5 milestone closed 2026-05-03. 4 phases (28-31), 7 plans, Adoption Hardening complete.

**Codebase characteristics:**
- Three sibling Hex packages (`mailglass`, `mailglass_admin`, `mailglass_inbound`)
- Phoenix 1.8+ / Elixir 1.18+ / OTP 27+ / Postgres only
- Append-only `mailglass_events` ledger with SQLSTATE 45A01 immutability trigger
- Multi-tenant first-class — `tenant_id` on every record
- 12 custom Credo checks operationalizing domain rules at lint time
- Boundary-enforced module hierarchy
- Optional-deps (Oban, OpenTelemetry, MJML, gen_smtp, sigra) gated through `Mailglass.OptionalDeps.*` modules
- HEEx + MSO VML fallbacks; zero Node toolchain anywhere
- Preview LiveView shipped at v0.1; production admin workflows, replay history, and tenant-safe operator actions shipped by v0.5

**Open issues / debt**:
- GitHub branch-protection verification remains a manual closeout step because the required-check configuration lives outside the repo.
- Non-blocking boundary warnings remain in support-summary and admin probe verification paths.
- Bare `mix test` citext-OID-cache race remains a known non-blocking test-environment sharp edge.
- Phase 4 standard-depth review WR-01..WR-06 remains tracked but non-blocking.

## Latest Completed Milestone

<details>
<summary>v1.0 Stability Lock — milestone closed 2026-05-06</summary>

**Goal:** Declare the transactional/admin core stable for long-lived production adoption without expanding the product boundary.

- **Stable surface lock** — core and admin contract inventories are now canonical, narrow, and backed by compiled-doc and docs-surface proof. ✓
- **Compatibility promise** — `1.x` deprecation/support policy and the canonical `0.x -> 1.0` upgrade path are now explicit and mechanically verified. ✓
- **Trust and release proof** — semantic stability verification, canonical testing/admin trust docs, and committed release rehearsal artifacts are now shipped. ✓

**Accepted closeout debt:**

- Phase 35 Nyquist bookkeeping still reports `wave_0_complete: false` even though verification now passes.
- Non-blocking boundary warnings remain in the stability verification lane.
- Manual GitHub branch-protection verification remains external to the repo.

</details>

## Current Milestone

### v1.1 Inbound Core Slice (**opened 2026-05-06**)

**Goal:** Open `mailglass_inbound` as the first deliberate post-`v1.0` expansion, proving Mailglass can receive, persist, route, and process inbound transactional email without weakening the locked outbound/admin core.

**Target features:**
- Canonical `mailglass_inbound` package contract: `%InboundMessage{}`, router DSL, and mailbox behaviour
- First-party Postmark and SendGrid ingress with normalized plus raw-source durable storage
- Tenant-safe replayable inbound persistence and mailbox execution outcomes
- Async routing that prefers Oban but still supports a bounded non-Oban fallback
- Honest install, testing, replay, and operator docs for the first inbound slice

**Status:** Phase 39 completed on 2026-05-06. The remaining live `v1.0` release closeout stays external to this milestone scope.

## Milestone Goals

- **Core inbound slice only** — ship the package contract, two ingress providers, replayable storage, and async execution; do not sprawl into the full historical inbound wish list.
- **Operator-trustworthy persistence** — store normalized inbound data and raw provider source so debugging and replay are first-class, not afterthoughts.
- **Package honesty over breadth** — prefer a smaller `mailglass_inbound` that is supportable and verifiable now over broad provider/UI scope that would dilute the first post-`v1.0` expansion.

## Core Value

**Email you can see, audit, and trust before it ships.** Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure — without leaving Phoenix or bolting on Node.

If everything else fails, the preview dashboard, normalized event ledger, and one-line `Mailglass.deliver/2 → deliver_later/2` ergonomics must work flawlessly.

## Validated Requirements (v0.1 & v0.2 — SHIPPED)

All 84 v1 REQ-IDs and 38 v0.2 REQ-IDs satisfied.

**By category (v0.2 - Production-Credible Core):**
- ✓ API-01..07 — Mailable API redesign + native Message field setters + `api_stability.md` v2 + codemod task + deprecation warnings + migration guide
- ✓ STREAM-01..04 — Message-stream separation (`:transactional`/`:operational`/`:bulk`) + runtime + compile-time enforcement + stream-aware Feedback-ID
- ✓ UNSUB-01..06 — RFC 8058 List-Unsubscribe headers + signed-token controller + rotation + generator + property tests
- ✓ SUPP-01..05 — Auto-suppression on bounce/complaint/unsubscribe + soft-bounce escalation + resync mix task + default-deny pre-send check
- ✓ REL-01..16 — Release-engineering hardening: 9 v0.1.2 polish TODOs + Tests gate halt-on-failure + Credo strict + Dialyzer halt-exit-status + release ceremony (CHANGELOG, migration guide, Hex publish)

**By category (v0.1):**
- ✓ CORE-01..07 — Error hierarchy, Config, Telemetry whitelist, Repo.transact/1, IdempotencyKey, OptionalDeps gateway, boundary
- ✓ AUTHOR-01..05 — Mailable behaviour, HEEx components with MSO fallbacks, render pipeline <50ms, Gettext i18n, MJML opt-in
- ✓ PERSIST-01..06 — 3 tables (deliveries/events/suppressions), append-only trigger, idempotency partial UNIQUE, append/1 + append_multi/3, migration generator
- ✓ TENANT-01..03 — tenant_id on every schema, Tenancy behaviour + SingleTenant default, NoUnscopedTenantQueryInLib Credo enforcement
- ✓ TRANS-01..04 — Adapter behaviour, Fake (merge gate), Swoosh wrapper, Outbound facade
- ✓ SEND-01..05 — Preflight pipeline, ETS RateLimiter, Outbound.Worker, Suppression check_before_send, PubSub.Topics
- ✓ TRACK-01..03 — Off by default, NoTrackingOnAuthStream lint, signed Phoenix.Token rewriting
- ✓ HOOK-01..07 — CachingBodyReader, Postmark + SendGrid HMAC, Anymail taxonomy verbatim, one-Multi ingest, 1000-replay convergence
- ✓ COMP-01..02 — RFC headers, Feedback-ID
- ✓ PREV-01..06 — mailglass_admin sibling package, Router macro, PreviewLive with sidebar/tabs/device toggle, LiveReload, brand-conformant components, committed bundle
- ✓ TEST-01..05 — TestAssertions (4 matcher styles), per-domain Case templates, StreamData properties, real-provider sandbox advisory cron, Clock injection
- ✓ LINT-01..12 — 12 custom Credo checks operationalizing domain rules at lint time
- ✓ INST-01..04 — `mix mailglass.install` with idempotent sidecars, golden-diff CI, verify.phase aliases
- ✓ CI-01..07 — GHA workflows, single-cell required matrix, Conventional Commits, Release Please linked-versions, tarball whitelisted, Actions SHA-pinned, HEX_API_KEY in protected Environment
- ✓ DOCS-01..05 — ExDoc with 9 guides, migration-from-swoosh, doc-contract tests, governance files
- ✓ BRAND-01..03 — Brand-conformant UI + voice + docs

## Active

- [x] `MODEL-01` — adopter can depend on one canonical `%InboundMessage{}` struct for the first-party inbound package
- [x] `ROUTE-01` — adopter can route inbound mail to mailboxes using one DSL that matches recipient, subject, and headers
- [x] `MAILBOX-01` — adopter can implement mailbox handlers with explicit `:accept`, `:reject`, `:ignore`, and `{:bounce, reason}` outcomes
- [ ] `INGRESS-01` — maintainer can verify and normalize Postmark inbound into the canonical model, with SendGrid following in the same milestone
- [ ] `STORE-01` — operator can persist inbound messages as both normalized canonical data and raw provider source material for replay/debug
- [ ] `EXEC-01` — adopter can execute inbound routing through Oban when available and through a bounded fallback when it is absent

## Out of Scope

Explicit boundaries with permanent reasoning to prevent re-litigation.

- **Marketing email** (campaigns, contact lists, segmentation, drip automations, A/B testing, broadcast scheduling) — that's [Keila](https://www.keila.io) / [Listmonk](https://listmonk.app) territory. Mailglass is forever **transactional + operational** mail.
- **Single-pane multi-channel notifications** (push, SMS, in-app, Slack alongside email) — that's a [Noticed](https://github.com/excid3/noticed)-shaped library with a different abstraction. Mailglass stays focused on email so it can be excellent at email.
- **Built-in subscriber management / preference center** — depends on having marketing concerns; if/when individual adopters need it, they can build it on the suppression + consent primitives mailglass exposes.
- **AMP for Email** — declared dead post-Cloudflare's October 2025 sunset; <5% adoption.
- **MJML as a default rendering path** — HEEx + Phoenix.Component with MSO fallbacks IS the default. MJML stays as opt-in `Mailglass.TemplateEngine.MJML` via the `mjml` Hex package.
- **Standalone ops console / SaaS dashboard** — `mailglass_admin` mounts in adopters' Phoenix apps; we don't run hosted infrastructure.
- **Backwards compatibility with Bamboo APIs** — Bamboo in maintenance mode; Swoosh is Phoenix 1.7+ default. Migration guide is from raw Swoosh + `Phoenix.Swoosh`.
- **Pre-Phoenix-1.8 / pre-LiveView-1.0 / pre-Elixir-1.18 support** — bleeding-edge floor (Elixir 1.18+, OTP 27+, Phoenix 1.8+, LiveView 1.0+, Ecto 3.13+).
- **Custom SMTP server** — `gen_smtp` for inbound relay is the floor; mailglass is not building or maintaining an SMTP daemon.
- **MySQL/SQLite support** — Postgres only. Advisory locks, JSONB, partial unique indexes, triggers are load-bearing.
- **Open/click tracking on by default** — privacy-first stance; legal liability on auth-carrying messages.
- **Open core / paid Pro tier** — MIT pure OSS across all sibling packages forever. No `mailglass_pro`.
- **Hosted SaaS Pro tier** — same as standalone ops console; we mount, never host.
- **Conductor-style inbound dev UI in `v1.1`** — the first inbound milestone proves routing, storage, and execution before adding a synthetic/replay LiveView surface.
- **Mailgun / SES / `gen_smtp` relay ingress in `v1.1`** — the first inbound milestone proves the package on Postmark + SendGrid before broadening provider or transport scope.

## Context

**The gap mailglass fills.** Swoosh is the canonical Phoenix mailer (39k downloads/month, healthy maintenance, extensible). It is excellent at the `compose → adapter → deliver` primitive. But everything around it — responsive templates, preview dashboards, normalized webhook events, suppression enforcement, signed unsubscribe, inbound routing, admin tooling, deliverability tooling — is left to each project to rebuild. The 2024 Gmail/Yahoo bulk-sender rules, React Email's emergence, and Phoenix 1.7's removal of `Phoenix.View` made the timing acute.

**Position relative to the ecosystem.** Mailglass is **not** a Swoosh replacement; it composes on top. It is **not** Bamboo (maintenance mode). It is **not** Keila (newsletter application, AGPLv3, not embeddable). It IS the missing framework layer between Swoosh's transport and a senior Phoenix team's transactional email needs.

**Engineering DNA inherited from prior libraries** (accrue, lattice_stripe, sigra, scrypath):

- Pluggable behaviours over magic — narrow callbacks, minimal surface
- Errors as a public API contract — structured `Mailglass.Error.t()` with closed `:type` atom set, `:cause` excluded from `Jason.Encoder`, one mapper per provider
- Telemetry as first-class — `[:mailglass, :domain, :resource, :action, :start | :stop | :exception]` 4-level naming, never raise from handlers, never include PII
- Append-only event ledger with Postgres trigger immutability — every mutation flows through `Ecto.Multi` that includes a `mailglass_events` row; SQLSTATE 45A01 on UPDATE/DELETE
- Sibling packages with linked-version releases — Release Please with `separate-pull-requests: false` + linked-versions plugin
- Fake adapter as required release gate — real-provider sandbox tests advisory only (daily cron + `workflow_dispatch`)
- Custom Credo checks for domain rules — domain invariants enforced at lint time
- Continuous phase counter & evidence-led backlog triage — the `.planning/` discipline this very document is part of

**Brand voice.** mailglass is "clear, exact, confident (not cocky), warm (not cute), modern (not trendy), technical (not intimidating)." The voice is "a thoughtful maintainer." Errors are specific and composed ("Delivery blocked: recipient is on the suppression list" — never "Oops!"). Documentation prefers the direct word ("preview" over "experience the full rendering lifecycle"). Visual palette: **Ink** #0D1B2A, **Glass** #277B96, **Ice** #A6EAF2, **Mist** #EAF6FB, **Paper** #F8FBFD, **Slate** #5C6B7A. Typography: Inter (UI/body), Inter Tight (display), IBM Plex Mono (code). Mobile-first responsive. No glassmorphism, bevels, lens flares, or "literal broken glass" visuals.

**Target persona / JTBD.** Senior or technical-lead Phoenix developers shipping production transactional email for SaaS apps. Common JTBDs: "let me ship a welcome email I can preview before deploying," "let me trust my password-reset deliveries," "let me audit why a customer's receipt didn't arrive," "let me operationalize bounce/complaint handling without rolling my own webhook plumbing," "let me support multiple tenants with different sending domains."

**Prior research artifacts** (preserved in `prompts/`, source of truth for vocabulary + conventions):

- `Phoenix needs an email framework not another mailer.md` — the founding thesis
- `mailglass-brand-book.md` — visual identity, voice, palette
- `mailer-domain-language-deep-research.md` — canonical vocabulary (Mailable / Message / Delivery / Event / InboundMessage / Mailbox / Suppression)
- `mailglass-engineering-dna-from-prior-libs.md` — engineering patterns distilled
- Various Elixir/Ecto/Phoenix/LiveView/Plug/OSS-CI/CD best-practices research files

## Constraints

- **Tech stack**: Elixir 1.18+ / OTP 27+ / Phoenix 1.8+ / LiveView 1.0+ / Ecto 3.13+ / Postgres (Postgrex). Bleeding-edge floor.
- **Required deps**: `:ecto_sql`, `:postgrex`, `:phoenix`, `:swoosh`, `:nimble_options`, `:telemetry`, `:gettext`, `:premailex`, `:floki`. Hard required from v0.1.
- **Optional deps**: `:oban`, `:opentelemetry`, `:sigra`, `:mjml`, `:gen_smtp`. CI must pass `mix compile --no-optional-deps --warnings-as-errors`.
- **Persistence**: Postgres only. MySQL/SQLite explicitly not supported.
- **Phoenix coupling**: Phoenix is a hard dep; mailglass is unapologetically Phoenix-first.
- **License**: MIT across all sibling packages, forever.
- **Distribution**: Hex.pm only. Source on GitHub. No standalone npm packages, no compiled binaries, no Node toolchain anywhere.
- **Compliance**: RFC 8058, 2024 Gmail/Yahoo bulk-sender rules, US CAN-SPAM, GDPR-shaped consent + suppression audit trail.
- **Privacy**: open/click tracking off by default. Telemetry metadata never includes recipient addresses, message bodies, or response payloads.
- **Security**: webhook signature failures raise `Mailglass.SignatureError` at call site — no recovery from forged webhooks. Unsubscribe tokens are signed with rotation support.
- **Maintenance budget**: one-person maintainer realistic; v0.1 must be coastable for 6 months without releases. Provider/compliance churn is expected to consume 20–30% of maintenance time forever.

## Key Decisions

| ID | Decision | Rationale | Outcome |
|----|----------|-----------|---------|
| D-01 | Sibling packages from v0.1 (`mailglass`, `mailglass_admin`, `mailglass_inbound` v0.5+) | Per accrue/sigra DNA — admin is mounted in adopters' apps, not run standalone; linked-version releases via Release Please | ✓ Validated v0.1 — Release Please linked-versions works; `mailglass_admin/mix.exs` pins `{:mailglass, "== <ver>"}` |
| D-02 | MIT license across all packages | Aligns with Swoosh/Phoenix/Ecto; maximizes adoption | ✓ Held v0.1 |
| D-03 | Marketing email **permanently** out of scope | Different problem (lists/segments/campaigns), different compliance surface, different abstraction | ✓ Held v0.1 |
| D-04 | Single-pane multi-channel notifications **out** | That's a Noticed-shaped lib; mailglass stays email-only | ✓ Held v0.1 |
| D-05 | Inbound (Action Mailbox equivalent) **in scope** as `mailglass_inbound` sibling package | Inbound webhook plumbing shares HMAC + plug + event-normalization infrastructure with the existing mailglass delivery and webhook foundation | — Active in v1.1 core slice |
| D-06 | Bleeding-edge version floor (Elixir 1.18+ / OTP 27+ / Phoenix 1.8+ / LiveView 1.0+ / Ecto 3.13+) | Newest features (streams, async, scopes, schema_redact, colocated hooks); smallest CI matrix | ✓ Validated v0.1 — Elixir 1.19 type checker forced struct-discrimination tests via `__struct__` comparison (worked, with documented workaround) |
| D-07 | Ecto + Phoenix **required**; Oban **optional** | mailglass is a Phoenix-first framework; `deliver_later/2` degrades to `Task.Supervisor` with a warning when Oban absent | ✓ Validated v0.1 — Outbound.Worker conditionally compiled; Task.Supervisor fallback path tested |
| D-08 | Open/click tracking **off by default** | Apple Mail Privacy Protection makes opens noisy; auth-carrying messages must NEVER have rewritten links | ✓ Validated v0.1 — NoTrackingOnAuthStream Credo check operationalizes |
| D-09 | Multi-tenancy **first-class from v0.1** | Phoenix 1.8 scopes default makes this the right time; harder to retrofit | ✓ Held v0.1 — `tenant_id` on every schema |
| D-10 | v0.1 normalizes **Postmark + SendGrid** webhooks; Mailgun/SES/Resend land in v0.5 | Most-used per Anymail data; smallest validation matrix | ✓ Held v0.1 |
| D-11 | Preview LiveView is **dev-only at v0.1**, prod admin lands at v0.5 | v0.1 surface stays scoped; admin UI needs event taxonomy maturity | ✓ Held v0.1 |
| D-12 | Full `mix mailglass.install` with golden-diff CI from v0.1 | "Batteries-included" brand promise demands one-command setup | ✓ Validated v0.1 — Phase 07.1 closed installer blockers G-1..G-5 (real `Apply.run` driving golden test) |
| D-13 | Test pyramid: doctests + ExUnit + StreamData property + Mox + **Fake adapter release gate** + real-provider sandbox advisory only | Per accrue DNA — real provider tests on daily cron + `workflow_dispatch`, never block PRs | ✓ Held v0.1 |
| D-14 | Anymail event taxonomy **verbatim** for normalized webhook events | Don't reinvent; multi-language standard; lowers cognitive cost for polyglot teams | ⚠ Held with one amendment — `:reconciled` is `@mailglass_internal_types` (audit-only), never emitted by provider mappers |
| D-15 | `mailglass_events` table is **append-only**, enforced by Postgres trigger raising SQLSTATE 45A01 | Per accrue DNA — single source of truth; immutability is structural, not policy | ✓ Validated v0.1 — `Mailglass.Repo` write path translates SQLSTATE at four sites |
| D-16 | Conventional Commits + Release Please + sibling-linked-version automation; Hex publish from protected ref only | Per OSS CI/CD best practices; squash-merge workflow keeps casual contributor UX low-friction | ✓ Validated v0.1 — release-please extra-files no-op surfaced; mitigated with workflow sed step |
| D-17 | Custom Credo checks enforce domain rules | Per engineering DNA — invariants caught at lint time, not just runtime | ✓ Validated v0.1 — 12 checks operational |
| D-18 | Renderer default is HEEx + `Phoenix.Component` with MSO VML fallbacks; MJML opt-in via `:mjml` Hex package (NOT `:mrml`) | Native composition, no Node, killer differentiator vs React Email + Mailing | ✓ Held v0.1 |
| D-19 | Brand voice & visual identity locked to `prompts/mailglass-brand-book.md` | Brand discipline prevents drift toward generic SaaS or growth-marketing aesthetic | ✓ Held v0.1 |
| D-20 | Domain vocabulary locked to `prompts/mailer-domain-language-deep-research.md` | Borrowed from battle-tested libs; avoid "Email" or "Status" as ambiguous primitives | ✓ Held v0.1 |
| D-21 | Adapter call between Multi#1 and Multi#2 (never inside transaction) | Postgres pool starvation prevention | ✓ Held v0.1 — Phase 3 Outbound enforces |
| D-22 | The first `mailglass_inbound` milestone stays narrow: Postmark + SendGrid ingress, normalized plus raw replayable storage, and Oban-optional execution; Conductor/Mailgun/SES/SMTP are deferred | Protect the locked `v1.x` core and make the first sibling-package expansion supportable for a one-person maintainer | — Active in v1.1 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions with `D-NN` ID
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state
5. Brand voice / domain vocabulary still aligned with `prompts/` source-of-truth files? Reconcile any drift.

---
*Last updated: 2026-05-06 — opened v1.1 Inbound Core Slice and locked the first `mailglass_inbound` milestone boundaries.*
