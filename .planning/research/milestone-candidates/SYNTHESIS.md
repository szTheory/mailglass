---
created: 2026-05-06
purpose: Persistent milestone-candidate research synthesis. Re-read this before re-researching the same question on the next /gsd-new-milestone pass.
inputs:
  - 01-inbound-providers.md
  - 02-inbound-admin.md
  - 03-inbound-dx.md
  - 04-inbound-runtime.md
  - 05-strategic-alternatives.md
recommendation: v1.2 Inbound Production Confidence (7 phases, ~18-20 plans)
status: awaiting user approval (2026-05-06)
---

# v1.2 Synthesis — Recommendation

## Recommendation

**Milestone v1.2 — Inbound Production Confidence**

**Goal:** Bring `mailglass_inbound` to the operator/dev/admin maturity that outbound reached across v0.4–v0.6, so adopters on the major providers can install, debug from the dashboard, write tests, and operate inbound in production with the same confidence they already get on outbound.

**One-sentence framing:** v1.1 opened the inbound package; v1.2 finishes opening it.

## Why this and not something else

Five parallel research agents investigated five candidate directions. Convergence was unusually strong; Agent 5 (the strategic devil's-advocate) tried six alternatives and concluded the hypothesis "substantially stands." The single defensible challenger — closing v1.0 carry-forward debt — gets **bundled in** as the final phase rather than replacing the milestone, because (a) the debt is small-bore and not adopter-facing, (b) RETROSPECTIVE.md's own lesson is that compounding debt across milestones is the failure mode, and (c) every alternative direction (relay/multi-tenant/outbound-deepening/marketing-adjacent/test-extraction) had weaker vision-fit and weaker adopter pull than completing what v1.1 just opened.

The unifying argument: D-22 explicitly justified v1.1's narrow scope ("supportable for a one-person maintainer") and named exactly what was deferred. v1.2 is the deliberate completion of that deferral list, plus the v0.4–v0.6 outbound-arc patterns mirrored over to the inbound side.

## Confidence-amplifying findings (lift cost is lower than expected)

The biggest single finding is from Agent 1: **the outbound webhook providers at `lib/mailglass/webhook/providers/` already ship full-fat verifiers for Mailgun (HMAC-SHA256 + ETS replay cache) and SES (SNS X.509 + CertCache + TrustPolicy + SubscriptionConfirmation auto-confirm).** Inbound provider expansion is mostly a **lift-and-alias** job, not new cryptography. This dramatically lowers the cost estimate vs. what one would assume from D-22's deferral language.

Similarly: Agent 2 finds `OperatorLive → InboundLive` is near-1:1 module-for-module; Agent 3 finds `MailerCase → MailboxCase` and `TestAssertions → InboundTestAssertions` are direct ports; Agent 4 finds replay primitives, idempotency, and pruner patterns are already shipped on outbound and ready to mirror. The structural work was done in v0.1–v1.1; v1.2 is mostly mirroring, aliasing, and connecting.

## What's in scope (target features)

1. **Mailgun + SES inbound ingress** — alias outbound verifiers; new `MailglassInbound.MIME` shared module; new `S3Fetcher` behaviour with optional `:ex_aws_s3` adapter (new `Mailglass.OptionalDeps.ExAwsS3` gateway mirroring existing `gen_smtp` gateway); plug allowlist extension. **Defer Cloudflare Email Routing** (no first-party contract). **Defer `gen_smtp` listener** to its own milestone (different transport class than webhook ingress).
2. **Inbound admin LiveView** — `InboundLive` (master/detail, tenant-required-or-empty), evidence card, timeline, replay modal (simpler than outbound — no ambiguous case), routing trace card ("why didn't this match this mailbox?"). **Defer synthetic-inbound compose form** to v1.2.1 (deserves its own security design pass).
3. **Inbound test helpers + DX parity** — `MailglassInbound.TestAssertions` (4 matcher styles + 4 outcome-specific + 2 routing); `MailglassInbound.MailboxCase` with the HI-01 snapshot/restore pattern; `MailglassInbound.Test.Ingress` + `Fixtures` (code-built payloads, NOT `.eml`-on-disk); 3 Igniter generators (`gen.mailbox`, `gen.inbound_router`, `gen.inbound_route`).
4. **Inbound runtime operator tooling** — `mix mailglass.inbound.doctor` (route compile/conflict, handler check, signature config, MIME backend availability), `mix mailglass.inbound.replay` (CLI surface for `Internal.Replay.replay/2`), `mix mailglass.inbound.prune` (Oban-optional, mirrors `Webhook.Pruner`); ingress-stage rate limiting (3 buckets: tenant/sender_domain/recipient, no `:transactional` bypass); suppression **flag-only** on inbound (no auto-bounce — preserves diagnostic signal).
5. **Inbound telemetry foundation** — currently **zero** `:telemetry` calls in `mailglass_inbound/lib/`. Add 4-level spans at ingress/route/execute/persist with start/stop/exception, PII-free metadata; wire `MailglassAdmin.PubSub.Topics` for live admin updates.
6. **Idempotency convergence proof** — StreamData property: 1000-replay convergence on inbound, mirroring the outbound v0.1 webhook ingest proof.
7. **Inbound documentation** — install guide, testing guide, operator/replay guide, Mailgun + SES setup guides, routing debugging guide.
8. **Stability closeout** — Phase 35 Nyquist `wave_0_complete: false` bookkeeping, manual GitHub branch-protection automation (or document the boundary), citext-OID-cache test race, non-blocking boundary warnings in support-summary/admin probe paths, Phase 4 standard-depth review WR-01..WR-06, v1.0 live publish closeout coordination.

## What's deliberately out (and why)

- **Cloudflare Email Routing** — Workers-based forwarding shape isn't a stable first-party webhook contract. Wait for adopter pull.
- **`gen_smtp` listener** — different transport class entirely (TLS-terminated SMTP listener, not HTTP plug). Belongs in its own milestone or its own `mailglass_relay` sibling package. Don't conflate.
- **Synthetic-inbound compose form** — Conductor-style "fake an inbound message" UX needs an explicit security design pass (dev-only enforcement, never-in-prod gate, tenant-scoping on synthetic stamps). Slip to v1.2.1.
- **Auto-suppression on inbound flooders** — destroys diagnostic signal; flag-only is the right policy in v1.2. Auto-suppression deferred to v1.3 once we have real adopter signal.
- **MX/HTTPS reachability checks in `inbound.doctor`** — relay mode doesn't exist yet; HTTPS reachability is a deployment concern, not a library concern.

## Phase shape (proposal)

| # | Phase | Goal | Deps |
|---|-------|------|------|
| 45 | Inbound Telemetry + Idempotency Foundation | 4-level telemetry spans across all inbound stages; 1000-replay convergence StreamData property; shared MIME module | — |
| 46 | Mailgun + SES Inbound Ingress | Lift-and-alias outbound verifiers; S3 fetcher behaviour + optional `:ex_aws_s3` gateway; Mailgun replay cache; plug allowlist extension | 45 |
| 47 | Inbound Test Helpers + Generators | `TestAssertions`, `MailboxCase`, `Test.Ingress`, `Fixtures`, 3 Igniter generators | 45 |
| 48 | Inbound Admin LiveView | `InboundLive`, evidence/timeline cards, replay modal, routing trace card, pub_sub wiring | 45 |
| 49 | Inbound Runtime Operator Tooling | `inbound.doctor`, `inbound.replay`, `inbound.prune`, ingress rate limiting (3 buckets), suppression flag | 45, 46 |
| 50 | Inbound Documentation Pass | Install + testing + operator + Mailgun/SES setup + routing debug guides | 46, 47, 48, 49 |
| 51 | Stability Closeout | Phase 35 Nyquist, branch-protection automation, citext race, boundary warnings, WR-01..06, v1.0 publish coordination | — (parallel-safe) |

**7 phases, estimated ~18–22 plans.** Larger than v1.1 (6 phases / 17 plans) but similar density. Phase 51 is parallel-safe with everything else (no overlap with inbound work).

## Per-area decisions (auto-resolved unless flagged VERY impactful)

| Area | Decision | Rationale | Impactful? |
|------|----------|-----------|------------|
| Provider scope | Mailgun + SES; defer Cloudflare + gen_smtp | Lift-and-alias vs new transport class | ⚠ User confirm |
| Synthetic-inbound dev tool | Defer to v1.2.1 | Security design pass needed | No (deferred, not killed) |
| Suppression on inbound | Flag-only, no auto-bounce | Preserves diagnostic signal; matches ActionMailbox + Anymail | No |
| Rate-limit position | Ingress-stage post-verify | DoS protection without losing legit signal | No |
| Rate-limit buckets | tenant + sender_domain + recipient (no transactional bypass) | Inbound has no transactional semantics | No |
| Retention defaults | records 90d / evidence 30d / execution_runs 90d / replay_runs 30d | Mirrors `Webhook.Pruner`; conservative | No |
| Test fixture format | Code-built only, never `.eml` on disk | Avoids real-PII commits; matches Credo `NoPIIInTelemetry` ethos | No |
| MIME backend | Optional `:gen_smtp`/`:mimemail` via `OptionalDeps` gateway | Honors D-07 optional-deps pattern | No |
| S3 fetcher | Behaviour + Fake; real adapter via optional `:ex_aws_s3` | Honors D-07; adopter wires their own AWS creds | No |
| Closeout debt | Bundle as Phase 51 (not separate milestone) | Avoid compounding; v1.0 contract debt | No |

The only **VERY impactful** decision the user should explicitly confirm is the **provider scope** (Mailgun + SES yes; Cloudflare + gen_smtp deferred). Everything else is auto-resolved with rationale captured here.

## Cuttable scope (if maintainer wants tighter milestone)

1. **Drop SES S3 fetcher real adapter** — ship behaviour + Fake only; let adopters wire `:ex_aws_s3` themselves in v1.2.1 (Agent 1 explicitly callout)
2. **Drop one of Mailgun or SES** — though both are roughly equivalent cost given the lift-and-alias pattern
3. **Slip Phase 51 closeout** — defer to v1.3 (but per Agent 5, this is the wrong call; debt compounds)
4. **Slip Phase 50 documentation** — but Agent 4 + Agent 1 both call out adopter docs as the gating factor for "use confidently in their app"

Recommended cut order if needed: SES S3 fetcher → cut Cloudflare investigation entirely → tighten Phase 50 doc count.

## Sources

- `01-inbound-providers.md` — Agent 1 verdict and per-provider table
- `02-inbound-admin.md` — Agent 2 admin LiveView reuse map
- `03-inbound-dx.md` — Agent 3 API mirror proposal
- `04-inbound-runtime.md` — Agent 4 telemetry gap finding and operator tool inventory
- `05-strategic-alternatives.md` — Agent 5 hypothesis stress-test

## Next action (this session)

1. Surface ONE question to the user: **provider scope confirmation** (Mailgun + SES yes; Cloudflare + gen_smtp deferred to v1.3 / own milestone).
2. On approval, proceed with `/gsd-new-milestone` workflow steps 3.5 → 11: PROJECT.md update, STATE.md reset, REQUIREMENTS.md authoring (REQ-IDs grouped by category), spawn `gsd-roadmapper` with phase numbering continued from 44.
