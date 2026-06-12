# CLAUDE.md — mailglass

> Project guide for Claude Code (and any GSD-aware tool) working in this repo.
> This file is the front-page context. Detailed planning artifacts live in `.planning/`.

## What This Is

**mailglass** — a batteries-included transactional email framework for Phoenix. Composes on top of Swoosh (does not replace it), shipping the framework layer Swoosh deliberately omits: HEEx-native components, LiveView preview/admin dashboard, normalized webhook events (Anymail taxonomy), suppression lists, RFC 8058 List-Unsubscribe, multi-tenant routing, append-only event ledger, `mix mail.doctor` deliverability checks.

Three sibling Hex packages, MIT, no Node toolchain anywhere:
- **`mailglass`** — core lib (Phoenix + Ecto + Postgres required, Oban optional)
- **`mailglass_admin`** — mountable LiveView dashboard (dev preview shipped v0.1, prod admin shipped v0.5)
- **`mailglass_inbound`** — Action Mailbox equivalent (opened v1.1; now on its own stable `1.0` contract — see `mailglass_inbound/docs/api_stability.md`)

**Marketing email and multi-channel notifications are permanently out of scope.** See `.planning/PROJECT.md` Out of Scope for the full list with reasoning.

**Current state (as of 2026-06-12):** v0.1 → v1.7 shipped to Hex; current versions `mailglass` 1.5.1 / `mailglass_admin` 1.5.1 / `mailglass_inbound` 1.3.0 (core+admin linked; inbound on its own version line). v1.8 (brand system) closed superseded 2026-06-11; **v1.9 "Brand Book Fable" shipped 2026-06-12** — `brandbook-fable/` is the maintainer-approved A/B winner over the frozen codex `brandbook/` (sealed-flap identity, light+dark token system, self-contained HTML book; binding brand constraints in `.planning/milestones/v1.9-phases/87-logo-tournament/87-decision-record.md`). Repo-artifact milestones only — no Hex release since 1.5.1. **Next milestone candidate: A/B winner adoption** (fold brandbook-fable/ into canonical brandbook/, propagate to README/HexDocs/social). v1.7 (Admin UI — IA & Design-System Polish v2) shipped + archived 2026-06-05; v1.5.0 added one-command Docker DX. The 1.5.1 linked release was finished by hand after a release-pipeline snag: a release-please **bot-merged** release SHA gets no `ci.yml` run (GitHub anti-recursion), so `publish-hex`'s `gate-ci-green` blocks with "no ci.yml runs found for SHA" — recover by dispatching `ci.yml` on the release tag (or pushing the release commit under a human identity) so a green run exists, then publish. Inbound's exact `{:mailglass, "== <core>"}` pin forces a **paired inbound release on every core bump** (that pin-drag is why core 1.5.1 dragged inbound to 1.3.0). Posture is quiet maintenance / adopter-pull — no milestone in flight. `.planning/STATE.md` is the live source of truth for milestone/phase status — read it rather than trusting any milestone number hardcoded in this file.

## Where to Look

| If you need… | Read |
|---|---|
| The vision, scope, brand, locked decisions D-01..D-22 | `.planning/PROJECT.md` |
| Current-milestone REQ-IDs (v1.2: TEL/MIME/MGUN/AWS/TEST/GEN/ALIVE/OPS/DOCS/CLOSE). Shipped v1 REQ-IDs (84 across CORE/AUTHOR/PERSIST/…) are recorded under PROJECT.md "Validated Requirements" | `.planning/REQUIREMENTS.md` |
| The current-milestone roadmap (phase goals + success criteria + dependencies); per-milestone archives live in `.planning/milestones/` | `.planning/ROADMAP.md` |
| Adopter-facing user flows / jobs-to-be-done — the ramp-up map for anyone *using* the library | `guides/jobs.md` |
| Internal JTBD frontier map — what's built vs. gaps, priority ordering, the diminishing-returns line (feeds milestone planning) | `.planning/research/JTBD-COVERAGE.md` |
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

## Decision Policy — Research-First, Decide, Escalate Rarely

This applies in **every** context — discuss/plan/spec phases **and** mid-execution, debugging, and release ceremonies. It is not limited to scoping workflows.

For any gray-area decision:

1. **Research first.** Spawn research subagent(s) (parallel, one per area) to investigate pros/cons/tradeoffs, what's idiomatic for this ecosystem (Elixir/Plug/Ecto/Phoenix), lessons + footguns from comparable successful libs (even cross-language), DX/UX implications, and what the `prompts/` research + `PROJECT.md` already settle. Don't punt the research to the user.
2. **Synthesize + decide.** Produce one coherent recommendation set where choices reinforce each other and the locked vision, then **proceed** with it. Document the decision + rationale (in CONTEXT.md / the plan / the commit) — never silently drop a decision.
3. **Escalate only genuinely strategic forks.** Ask the user ONLY when research leaves no clear winner AND the call is one a staff/architect engineer would personally want: ship-or-don't, license, vendor/framework lock-in that's expensive to reverse, brand/visual identity, or a public-API shape where the *project's own goals* (not ecosystem norms) decide and it could plausibly go either way. A strong idiomatic precedent settles it → research-and-lock, do not ask (even for irreversible public-API shape — see the `%InboundMessage{} :signals` precedent).
4. **Reversibility test before asking:** if it can be added/changed later without rip-out, just pick the recommended option. When in doubt, lean toward NOT asking — "one-shot a perfect set of recommendations." A wrong call is cheaper than breaking the user's flow; they can redirect mid-execution.

Encoded for GSD in `~/.claude/get-shit-done/USER-PROFILE.md` (advisor mode, `vendor_philosophy: opinionated` → `minimal_decisive`), in `.planning/config.json` `preferences.vendor_philosophy`, and in the user memory `feedback_research_driven_recommendations.md`. Persist multi-pass research under `.planning/research/` so it isn't regenerated.

## Commit & Branch Conventions

- **Conventional Commits enforced** (PR title check). Squash-merge workflow.
- `docs(state):` commit type for `.planning/STATE.md` updates — CI path filters skip them.
- **Hex publish only from a protected ref**, via the `hex-publish` GitHub Environment so `HEX_API_KEY` is never visible to PR jobs. Releases are **fully hands-free**: a Release Please PR auto-merges on green (see `release-please.yml` "Arm auto-merge") and the publish fan-out runs with no human approval gate (the `hex-publish` environment intentionally has no required reviewers). Tightening this back to a required-reviewer gate is a deliberate policy change, not the current default.
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
*Generated: 2026-04-21 from `.planning/` artifacts. "What This Is" + "Where to Look" refreshed 2026-05-22; current-state reconciled 2026-06-05 to live `mailglass` 1.5.1 / `mailglass_admin` 1.5.1 / `mailglass_inbound` 1.3.0 (v1.7 shipped, quiet-maintenance posture).*
