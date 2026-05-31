# mailglass

> *Mail you can see through.*

## What This Is

**mailglass** is a batteries-included transactional email framework for Phoenix — the layer that sits on top of [Swoosh](https://hex.pm/packages/swoosh) and ships everything Swoosh deliberately doesn't: HEEx-native components, a LiveView preview/admin dashboard, normalized webhook events, signed unsubscribe tokens with RFC 8058 List-Unsubscribe headers, message-stream separation, suppression lists, an append-only event ledger, multi-tenant routing, and `mix mail.doctor` deliverability checks. It's for senior Phoenix teams shipping production transactional email (welcome flows, password resets, magic links, receipts, notifications) who today rebuild 40% of ActionMailer + Anymail + ActionMailbox by hand on every project.

It is shipped as three sibling Hex packages: `mailglass` (core), `mailglass_admin` (mountable LiveView dashboard), and `mailglass_inbound` (Action Mailbox equivalent — post-`v1.0`).

## Current State

**`v1.3 Adopter Trust Proof` shipped on 2026-05-31.**

- Milestone archive complete: 7 phases (`52`, `57-62`), 18 plans, 16/16 requirements satisfied, final audit `status: passed`
- **Current package versions on Hex: `mailglass` 1.3.0 / `mailglass_admin` 1.3.0 / `mailglass_inbound` 0.3.0** (live on 2026-05-29; reference-host trust proof aligned in Phase 62)
- The maintained `reference/host_app` now proves a narrow, public-seam-only adopter path with an explicit scope contract and non-goals.
- One canonical deterministic trust runner now covers install -> preview -> send -> signed webhook ingest -> operator troubleshooting, with stable `trust_runner.v1` checkpoint evidence.
- Required repo-head and clean-baseline trust lanes enforce checkpoint evidence, Hex-first dependency resolution, and branch-protection/release-gate expectations.
- Post-publish smoke now runs a published-version trust journey and guards the current release line against stale-lock and hackney dependency regressions.
- Reference-host and trust-entry docs now route guarantee truth to canonical `api_stability.md` inventories and `mix verify.stability_contract`, with deterministic docs-check enforcement against contract-boundary drift.
- Backlog phase 999.1 completed on 2026-05-27: planning-artifact comment cleanup now covers scoped core/admin/inbound source paths, with Credo drift prevention (`Mailglass.Credo.NoPlanningArtifactComments`) and guard tests added
- Backlog phase 999.2 completed on 2026-05-27: deterministic preview URL/capture matrix foundations, mix screenshot capture workflow, advisory CI artifact lane, and docs claim-boundary contract checks are now in place
- `mailglass_inbound` now has production-credible telemetry, Mailgun + SES ingress, test helpers + generators, admin observability, operator tooling, and six first-party inbound guides
- Phase 51 retired the remaining v1.0 carry-forward debt inside the same milestone: Phase 35 Nyquist bookkeeping, branch-protection repo truth, bare `mix test` citext race, boundary warnings, and WR-01..WR-06 dispositions
- `v1.1` remains the previous shipped slice: `mailglass` 1.0.0 / `mailglass_admin` 1.0.0 / `mailglass_inbound` 0.1.0 published on 2026-05-07 via Phase 44.5

v1.0 milestone closed 2026-05-06. 4 phases (35-38), 12 plans, Stability Lock complete.
v0.6 milestone closed 2026-05-05. 3 phases (32-34), 9 plans, Production Maturity complete.
v0.5 milestone closed 2026-05-03. 4 phases (28-31), 7 plans, Adoption Hardening complete.

**Codebase characteristics:**
- Three sibling Hex packages (`mailglass`, `mailglass_admin`, `mailglass_inbound`) — `mailglass_inbound` opened in v1.1
- Phoenix 1.8+ / Elixir 1.18+ / OTP 27+ / Postgres only
- Append-only `mailglass_events` ledger with SQLSTATE 45A01 immutability trigger
- Multi-tenant first-class — `tenant_id` on every record
- 17 custom Credo checks operationalizing domain rules at lint time (every check registered in `.credo.exs` and meta-test-enforced against the inert-guard blind spot as of Phase 45)
- Boundary-enforced module hierarchy
- Optional-deps (Oban, OpenTelemetry, MJML, gen_smtp, sigra) gated through `Mailglass.OptionalDeps.*` modules
- HEEx + MSO VML fallbacks; zero Node toolchain anywhere
- Preview LiveView shipped at v0.1; production admin workflows, replay history, and tenant-safe operator actions shipped by v0.5
- Inbound package: canonical `%InboundMessage{}` value object, thin router DSL, mailbox behaviour with locked outcomes, Postmark + SendGrid first-party ingress, tenant-safe replayable storage of normalized + raw provider source, Oban-backed async execution with bounded `Task.Supervisor` fallback (v1.1)

**Open issues / debt**:
- Release-workflow fanout still relies on the documented `workflow_dispatch` fallback because GitHub `GITHUB_TOKEN` anti-recursion blocks downstream publish workflows from release-created releases.
- Admin publish still needs an explicit Hex-index wait on inbound when sibling packages release in parallel.
- `SEED-003-ecosystem-integrations` is intentionally deferred and remains dormant for later milestone selection.
- v1.3 trust proof is archived; the next recommended milestone is an inbound stability lock for `mailglass_inbound` contract and compatibility posture.
- `mailglass_inbound` runtime capability is stronger than its contract framing in some docs; `mailglass_inbound` still sits outside the `1.x` compatibility promise and needs a dedicated stability-lock milestone after trust proof work.
- A few latent hardening notes remain in per-phase review artifacts, but none block the shipped `v1.2` surface.

## Current Milestone

No active milestone. Next milestone definition should start from `$gsd-new-milestone`.

## Latest Completed Milestone

<details>
<summary>v1.3 Adopter Trust Proof — milestone closed 2026-05-31</summary>

**Goal:** Prove real-world adoption confidence with one maintained Phoenix reference host app and deterministic trust evidence across local, CI, and published-version release checks.

- **Reference host baseline** — shipped a maintained Phoenix host app with clean-checkout setup, public-seam-only integration, and a fail-closed scope contract. ✓
- **Deterministic trust journey** — shipped `mix verify.reference_host.journey` and stable `trust_runner.v1` checkpoint evidence for install, preview, send, webhook ingest, and operator troubleshooting. ✓
- **CI/release trust evidence** — required repo-head and clean-baseline lanes now publish checkpoint artifacts and guard Hex-first dependency resolution. ✓
- **Published-version proof** — post-publish smoke now runs the current-release trust journey and blocks stale release-line claims. ✓
- **Contract-boundary docs** — reference docs are usage proof only; public guarantee truth routes to canonical stability inventories and executable contract checks. ✓

**Accepted residual debt:**

- Advisory review notes remain for docs checker path-scoping consistency, async mutation flake risk, and broad assertion granularity.
- `mailglass_inbound` still needs a dedicated stability-lock milestone before it carries the same compatibility posture as the core/admin `1.x` surface.

</details>

<details>
<summary>v1.2 Inbound Production Confidence — milestone closed 2026-05-26</summary>

**Goal:** Finish opening `mailglass_inbound` so adopters can install, observe, test, and operate inbound mail with the same confidence already available on outbound.

- **Telemetry + replay proof** — shipped PII-safe inbound spans, PubSub hooks, never-raise MIME parsing, and a 1000-replay convergence proof. ✓
- **Major-provider ingress** — shipped Mailgun and SES inbound verification, normalization, replay-safe persistence, and bounded S3 fetch handling. ✓
- **Adopter DX** — shipped `MailboxCase`, `TestAssertions`, `Test.Ingress`, code-built fixtures, and three Igniter generators. ✓
- **Operator/admin depth** — shipped `InboundLive`, routing-trace and evidence views, replay controls, `mailglass.inbound.{doctor,replay,prune}`, rate limiting, and suppression-flag-only behavior. ✓
- **Closeout discipline** — published `mailglass` 1.2.0 / `mailglass_admin` 1.2.0 / `mailglass_inbound` 0.2.0, then resolved the remaining v1.0 carry-forward debt in Phase 51 before archiving. ✓

**Accepted residual debt:**

- Release-workflow fallback remains manual-by-design until a future maintainer chooses PAT-based or alternate fanout automation.
- `SEED-003-ecosystem-integrations` is acknowledged and dormant, not promoted into the next milestone automatically.

</details>

<details>
<summary>v1.1 Inbound Core Slice — milestone closed 2026-05-06 (audit re-passed 2026-05-07)</summary>

**Goal:** Open `mailglass_inbound` as the first deliberate post-`v1.0` expansion, proving Mailglass can receive, persist, route, and process inbound transactional email without weakening the locked outbound/admin core.

- **Inbound package foundation** — canonical `%InboundMessage{}`, thin router DSL, mailbox behaviour with locked outcomes, package-local persistence boundary, optional-Oban execution seam. ✓
- **First-party provider ingress** — Postmark verify-first ingress with sealed normalization; SendGrid second-provider proof with shared canonical shape and provider-specific dedup. ✓
- **Replayable persistence** — normalized canonical inbound rows alongside raw provider source evidence; replay over stored truth that never pretends a stored message is a fresh provider event. ✓
- **Async execution + adopter proof** — Oban-backed inbound worker, bounded `Task.Supervisor` fallback with explicit warn-on-enter, canonical install / testing / operator docs, repo-root release-proof coverage for the new sibling package. ✓
- **Audit-gap closure** — Phase 43 recovered Phases 39-41 verification artifacts and added Phase 41 validation; Phase 44 recovered Phase 42 verification and reconciled REQUIREMENTS.md / STATE.md / ROADMAP.md so the v1.1 audit re-ran with `status: passed`. No source code under `mailglass/` or `mailglass_inbound/` was modified during the gap closure. ✓

**Accepted closeout debt:**

- No new debt introduced in v1.1. Carry-forward only: v1.0 partial Nyquist bookkeeping for Phase 35, non-blocking boundary warnings in support-contract lanes, manual GitHub branch-protection verification, bare `mix test` citext-OID-cache race.

</details>

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

## Next Milestone Queue (after v1.3)

- **Recommended next milestone after Adopter Trust Proof:** inbound stability lock (`mailglass_inbound` contract + compatibility/deprecation posture hardening).
- Follow-on ordering:
  1) synthetic inbound dev tooling (dev-only, tenant-safe, provenance-stamped),
  2) Cloudflare forwarding recipe docs or narrow pull-driven ecosystem integration slices,
  3) re-evaluate `gen_smtp` listener only with strong adopter pull.
- Guardrail remains: do not auto-promote `SEED-003-ecosystem-integrations` or transport-expansion tails as default next work.

## Core Value

**Email you can see, audit, and trust before it ships.** Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure — without leaving Phoenix or bolting on Node.

If everything else fails, the preview dashboard, normalized event ledger, and one-line `Mailglass.deliver/2 → deliver_later/2` ergonomics must work flawlessly.

## Validated Requirements (v0.1, v0.2, v1.1, v1.3 — SHIPPED)

All 84 v1 REQ-IDs, 38 v0.2 REQ-IDs, and 10 v1.1 REQ-IDs satisfied.

**By category (v1.3 Phase 52 — trust baseline):**
- ✓ HOST-01..03 — Maintained reference host baseline, public-seam-only integration boundary, and fail-closed scope lock artifact/test contracts validated in Phase 52
- ✓ JOUR-01..02 — Canonical deterministic trust-runner command plus deterministic fixture/checkpoint schema and validator contract validated in Phase 57
- ✓ EVID-02, EVID-03 — Clean-baseline trust lane and published-version trust evidence gates validated in Phases 59-60, with current-release Hex proof closed in Phase 62
- ✓ OPS-01..02 — Release-gate drift prevention and smoke reliability guardrails validated in Phase 60
- ✓ DOCB-01..03 — Reference-host usage-proof boundary, canonical stability routing, and deterministic docs-contract enforcement validated in Phase 61

**By category (v1.1 — Inbound Core Slice):**
- ✓ MODEL-01 — Canonical `%MailglassInbound.InboundMessage{}` value object with stable fields for routing, tenancy, and provider provenance — v1.1
- ✓ ROUTE-01 — Inbound router DSL matching on recipient, subject, and headers, backed by compiled ordered route data and pure matcher engine — v1.1
- ✓ MAILBOX-01 — Mailbox behaviour with locked `:accept` / `:reject` / `:ignore` / `{:bounce, reason}` outcomes — v1.1
- ✓ INGRESS-01..02 — First-party Postmark + SendGrid ingress plugs with verify-first signature checks and sealed normalization into the canonical inbound model — v1.1
- ✓ STORE-01..02 — Tenant-safe persistence of normalized canonical data plus raw provider source evidence; replay over stored truth without re-receive ambiguity — v1.1
- ✓ EXEC-01..02 — Oban-backed async mailbox execution with bounded `Task.Supervisor` fallback and explicit warn-on-enter for the degraded path — v1.1
- ✓ ADOPT-01 — Canonical install / testing / operator-trust docs and repo-root release-proof coverage for the inbound sibling package — v1.1

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

- [ ] Define the next milestone requirements, likely an inbound stability lock for `mailglass_inbound` contract and compatibility/deprecation posture.

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
- **Provider-matrix broadening in `v1.3`** — trust proof is a single representative journey, not a breadth expansion milestone.
- **`SEED-003-ecosystem-integrations` auto-promotion in `v1.3`** — remains deferred until trust proof and inbound stability lock are complete.
- **Transport-class expansion (`gen_smtp` listener) in `v1.3`** — requires a dedicated milestone with separate threat model and ops burden review.

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
| D-05 | Inbound (Action Mailbox equivalent) **in scope** as `mailglass_inbound` sibling package | Inbound webhook plumbing shares HMAC + plug + event-normalization infrastructure with the existing mailglass delivery and webhook foundation | ✓ Validated v1.1 — `mailglass_inbound` opened with Postmark + SendGrid ingress, replayable persistence, Oban-optional execution |
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
| D-22 | The first `mailglass_inbound` milestone stays narrow: Postmark + SendGrid ingress, normalized plus raw replayable storage, and Oban-optional execution; Conductor/Mailgun/SES/SMTP are deferred | Protect the locked `v1.x` core and make the first sibling-package expansion supportable for a one-person maintainer | ✓ Validated v1.1 — narrow scope held; Conductor / Mailgun / SES / `gen_smtp` remained deliberately deferred |

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

**Release-cadence rule (added 2026-05-06 — see ROADMAP.md):** Each milestone closes with a release ceremony to Hex.pm before the next milestone implementation starts. Convention: a `Phase X.5` numbered between the last feature phase of milestone N and the first feature phase of milestone N+1 (e.g. Phase 44.5 between v1.1 and v1.2). The 4-milestone-deep gap that accumulated between `v0.3.2` and `1.0.0` (v0.5 + v0.6 + v1.0 + v1.1 all unreleased on Hex while milestone planning labels marched forward) is the failure mode this rule prevents. Milestone "shipped" status now requires both planning-archive completion AND Hex publish — not just one.

---
*Last updated: 2026-05-31 after v1.3 milestone closeout*
