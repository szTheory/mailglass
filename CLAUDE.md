# CLAUDE.md — mailglass

> Project guide for Claude Code (and any GSD-aware tool) working in this repo.
> This file is the front-page context. Detailed planning artifacts live in `.planning/`.

## What This Is

**mailglass** — a batteries-included transactional email framework for Phoenix. Composes on top of Swoosh (does not replace it), shipping the framework layer Swoosh deliberately omits: HEEx-native components, LiveView preview/admin dashboard, normalized webhook events (Anymail taxonomy), suppression lists, RFC 8058 List-Unsubscribe, multi-tenant routing, append-only event ledger, `mix mail.doctor` deliverability checks.

Three sibling Hex packages, MIT, no Node toolchain anywhere:
- **`mailglass`** — core lib (Phoenix + Ecto + Postgres required, Oban optional)
- **`mailglass_admin`** — mountable LiveView dashboard (dev preview at v0.1, prod admin v0.5)
- **`mailglass_inbound`** — Action Mailbox equivalent (v0.5+, separate package)

**Marketing email and multi-channel notifications are permanently out of scope.** See `.planning/PROJECT.md` Out of Scope for the full list with reasoning.

## Where to Look

| If you need… | Read |
|---|---|
| The vision, scope, brand, locked decisions D-01..D-20 | `.planning/PROJECT.md` |
| The 84 v1 REQ-IDs (CORE/AUTHOR/PERSIST/TENANT/TRANS/SEND/TRACK/HOOK/COMP/PREV/TEST/LINT/INST/CI/DOCS/BRAND) | `.planning/REQUIREMENTS.md` |
| The 7-phase v0.1 roadmap with phase goals + success criteria + dependencies | `.planning/ROADMAP.md` |
| Current state and next action | `.planning/STATE.md` |
| Verified 2026 versions, optional-dep gateway pattern, CI lane structure | `.planning/research/STACK.md` |
| Feature catalog with TS-/DF-/AF- IDs + competitor matrix | `.planning/research/FEATURES.md` |
| Module catalog, data flow diagrams, DDL, behaviour boundaries, 7-layer build order | `.planning/research/ARCHITECTURE.md` |
| 42 pitfalls with prevention strategies + phase mapping | `.planning/research/PITFALLS.md` |
| Single-page synthesis of all four research files | `.planning/research/SUMMARY.md` |
| Deep prior-art research (founding thesis, brand book, domain language, engineering DNA, ecosystem map, best-practices) | `prompts/` (12 files, source of truth for vocabulary + conventions) |
| Workflow toggles (granularity, parallelization, model profile, agents) | `.planning/config.json` |

## Engineering DNA — Conventions That Are Non-Negotiable

These are inherited from 4 prior shipped libraries (accrue, lattice_stripe, sigra, scrypath) and locked in `PROJECT.md`. Custom Credo checks (Phase 6) enforce them at lint time.

- **Pluggable behaviours over magic.** Narrow callbacks. Optional callbacks where lifecycle naturally supports skipping. `use Mailglass.Mailable` injects ≤20 lines.
- **Errors as a public API contract.** Structured `%Mailglass.Error{}` hierarchy with closed `:type` atom set documented in `api_stability.md`. Pattern-match by struct, never by message string.
- **Telemetry on `[:mailglass, :domain, :resource, :action, :start | :stop | :exception]`.** Metadata whitelisted to counts/statuses/IDs/latencies. **Never PII** (no `:to`, `:from`, `:body`, `:html_body`, `:subject`, `:headers`, `:recipient`, `:email`). Handlers that raise must not break business logic.
- **Append-only `mailglass_events` Postgres table.** UPDATE/DELETE raises SQLSTATE 45A01 via trigger. Idempotency keys via `UNIQUE` partial index — webhook replays are safe no-ops.
- **Multi-tenancy first-class from v0.1.** `tenant_id` on every record. `Mailglass.Tenancy.scope/2` behaviour. Cannot be retrofitted (D-09).
- **Sibling packages with linked-version releases.** Release Please with `separate-pull-requests: false` + linked-versions plugin. `mailglass_admin/mix.exs` declares `{:mailglass, "== <version>"}`.
- **Fake adapter is the merge-blocking release gate.** `Mailglass.Adapters.Fake` is built FIRST per D-13. Real-provider sandbox tests are advisory only (daily cron + `workflow_dispatch`, never block PRs).
- **Custom Credo checks at lint time.** Twelve checks enforce domain rules. See `LINT-01..LINT-12` in REQUIREMENTS.md.
- **Optional deps gated through `Mailglass.OptionalDeps.*` modules.** `@compile {:no_warn_undefined, ...}` declared once + `available?/0` predicate + degraded fallback. CI lane `mix compile --no-optional-deps --warnings-as-errors` is mandatory.
- **Open/click tracking off by default.** Per-mailable opt-in. `NoTrackingOnAuthStream` Credo check raises at compile time on auth-context heuristics (`magic_link`, `password_reset`, `verify_email`, `confirm_account`).

## Brand & Voice (applies to docs, errors, log messages, UI)

mailglass is **clear, exact, confident (not cocky), warm (not cute), modern (not trendy), technical (not intimidating)** — "a thoughtful maintainer."

- Errors are specific and composed: "Delivery blocked: recipient is on the suppression list" — never "Oops!"
- Documentation prefers the direct word: "preview" not "experience the full rendering lifecycle."
- Visual palette: **Ink** #0D1B2A, **Glass** #277B96, **Ice** #A6EAF2, **Mist** #EAF6FB, **Paper** #F8FBFD, **Slate** #5C6B7A.
- Typography: Inter (UI/body), Inter Tight (display), IBM Plex Mono (code).
- Mobile-first responsive admin UI. NO glassmorphism, bevels, lens flares, or "literal broken glass" visuals despite the name.

Source of truth: `prompts/mailglass-brand-book.md`.

## Domain Language (use these names, not synonyms)

Borrowed verbatim from battle-tested libraries (ActionMailer, ActionMailbox, Anymail, Laravel Mailable). Source: `prompts/mailer-domain-language-deep-research.md`.

The seven irreducible nouns: **Mailable** (source-level definition), **Message** (rendered email), **Delivery** (recipient/provider-specific send record), **Event** (observed fact, past tense), **InboundMessage** (received email pre-routing), **Mailbox** (inbound handler), **Suppression** (policy record blocking future sends).

Anymail event taxonomy verbatim: `:queued, :sent, :rejected, :failed, :bounced, :deferred, :delivered, :autoresponded, :opened, :clicked, :complained, :unsubscribed, :subscribed, :unknown` with `reject_reason ∈ :invalid | :bounced | :timed_out | :blocked | :spam | :unsubscribed | :other | nil`.

**Critical distinction:** `dispatch` ≠ `delivered`. Dispatch = handed to provider. Delivered = downstream accepted.

**Avoid in core:** "Email" alone (use Message/Delivery/Mailable), "Status" alone (use events + summary projection), "Notification" (drags toward multi-channel — that's out of scope).

## GSD Workflow

This project uses GSD (Get Shit Done) for planning + execution. Common entry points:

- **Plan a phase:** `/gsd-plan-phase <N>` (or `/gsd-discuss-phase <N>` first if you want context-gathering)
- **Execute a phase:** `/gsd-execute-phase <N>` after planning
- **Check progress:** `/gsd-progress`
- **Update state:** managed automatically; never edit `.planning/STATE.md` by hand

**Phases flagged for `/gsd-research-phase` before planning:**
- Phase 2 (Persistence + Tenancy) — `metadata jsonb` projections, orphan reconciliation, `:typed_struct`, status state machine
- Phase 4 (Webhook Ingest) — SendGrid ECDSA on OTP 27 `:crypto`, CachingBodyReader + Plug 1.18
- Phase 5 (Dev Preview LiveView) — `MailglassAdmin.Router` macro signature (prototype against `~/projects/sigra`), session cookie collision, daisyUI 5 + Tailwind v4 sans Node

Other phases (1, 3, 6, 7) plan directly from synthesis — patterns are 4-of-4 convergent across prior libs.

## Commit & Branch Conventions

- **Conventional Commits enforced** (PR title check). Squash-merge workflow.
- `docs(state):` commit type for `.planning/STATE.md` updates — CI path filters skip them.
- **Hex publish only from protected ref** + GitHub Environment with required reviewers. `HEX_API_KEY` is never visible to PR jobs.
- **All third-party GitHub Actions pinned to commit SHA.** Dependabot watches both `mix.lock` and `.github/workflows/`.

## Things Not To Do (the short list — full list in PITFALLS.md)

1. Don't use `Application.compile_env*` outside `Mailglass.Config`.
2. Don't UPDATE or DELETE `mailglass_events` rows — the trigger raises SQLSTATE 45A01 by design.
3. Don't put PII in telemetry metadata.
4. Don't call `Swoosh.Mailer.deliver/1` directly inside mailglass library code (use `Mailglass.Outbound.*`).
5. Don't recover from webhook signature failures — `Mailglass.SignatureError` raises with no recovery path.
6. Don't write to `mailglass_admin/priv/static/` without committing the rebuilt bundle (CI runs `git diff --exit-code`).
7. Don't pattern-match errors by message string. Match the struct.
8. Don't use `name: __MODULE__` to register singletons in library code.
9. Don't enable open/click tracking by default. Don't enable it on auth-carrying messages, ever.
10. Don't ship marketing-email features here. They're permanently out of scope.

## License

MIT across all sibling packages. Forever. (See PROJECT.md D-02.)

---
*Generated: 2026-04-21 from `.planning/` artifacts.*
