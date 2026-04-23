# Phase 4: Webhook Ingest — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in 04-CONTEXT.md — this log preserves the alternatives considered + research grounding.

**Date:** 2026-04-23
**Phase:** 04-webhook-ingest
**Areas discussed:** Provider verifier contract; Plug mounting + CachingBodyReader; Orphan reconciliation scope + cadence; Tenant resolution at webhook boundary; Sync vs async normalization; Raw payload retention; SignatureError taxonomy + auto-suppression (combined)

**Mode:** Research-first (7 parallel `gsd-advisor-researcher` agents spawned per user request — "research using subagents, pros/cons/tradeoffs, lessons from other libs, one-shot perfect recommendations so I don't have to think"). User selected all seven gray areas initially surfaced + deferred to Claude's synthesis.

---

## Area 1 — Provider verifier contract

**Options presented (by researcher):**

| Option | Shape | Selected |
|---|---|---|
| A1. Single callback `verify_and_normalize/3` | One function, verifier owns both crypto + taxonomy | |
| A2. Two callbacks `verify!/3` + `normalize/2` | Split crypto from taxonomy mapping | ✓ |
| A3. Three callbacks `verify/3` + `parse/2` + `normalize/1` | Maximally decomposed | |
| A4. Facade-only concrete modules, internal behaviour gated | Hide extensibility | |
| B1. Input = `%Plug.Conn{}` | Phoenix-coupled | |
| B2. Input = `{raw_body, headers, config}` tuple | Pure functional | ✓ |
| C1. Public behaviour adopter-extensible at v0.1 | "Batteries-included-but-hackable" | |
| C2. Sealed behaviour (`@moduledoc false`) until v0.5 | Freedom to refactor | ✓ |

**User's choice:** Approved synthesis (A2 + B2 + C2). 
**Notes:** SendGrid ECDSA implementation: `:public_key.der_decode/2` + `:public_key.verify/4` (NOT `pem_decode` — SendGrid ships one-line DER base64). 300s replay-tolerance window. Postmark Basic Auth via `Plug.Crypto.secure_compare/2`; IP allowlist opt-in. Peer precedents: django-anymail (verbatim two-callback pattern), ActionMailbox (authenticate-before-action), lattice_stripe, Svix/Standard-Webhooks.

---

## Area 2 — Plug mounting + CachingBodyReader

**Options presented:**

| Option | Description | Selected |
|---|---|---|
| A. Naked Plug, documented | Adopter wires `body_reader` in `Plug.Parsers` themselves | ✓ (escape hatch) |
| B. Router macro `mailglass_webhook_routes "/webhooks"` | LiveDashboard/Oban Web idiom, one-line mount | ✓ (primary) |
| C. Endpoint pipeline macro `use Mailglass.Webhook.Endpoint` | Mixes body_reader + routes into Endpoint | |
| D. Phoenix `forward` to sub-endpoint | Total request-processing isolation | |

**User's choice:** Approved synthesis (B primary + A escape hatch; provider-per-path like ActionMailbox).
**Notes:** CachingBodyReader upgrade vs lattice_stripe: **iodata accumulation across `{:more, _, _}` chunks** to handle SendGrid's 128-event batches. `conn.private[:raw_body]` (not `assigns`). `Plug.Parsers length: 10_000_000` (10 MB cap). `Plug.Parsers.MULTIPART` does NOT honor `:body_reader` (documented footgun). Phoenix LiveDashboard + Oban Web use identical `defmacro name(path, opts)` pattern invoked inside adopter-owned `scope`. Shared vocabulary with Phase 5 admin router (`import X.Router` + `mailglass_<area>_routes path, opts` + `:as` option).

---

## Area 3 — Orphan reconciliation: scope + cadence

**Options presented:**

| Option | Cadence | Selected |
|---|---|---|
| A. Oban cron `*/5` + 60s age + `:reconciled` event append | Ship in Phase 4 | ✓ |
| B. Oban cron `*/15` (Phase 2 STATE note preference) | Ship in Phase 4 | |
| C. Event-driven reconciliation on Delivery commit | Surgical but no crash-recovery | |
| D. Defer to v0.5; Phase 4 telemetry-only | Smallest surface | |

**User's choice:** Approved synthesis (A).
**Notes:** Immutability tension resolved structurally: worker appends NEW `:reconciled` event + updates Delivery projection via Projector. Original orphan event row stays `delivery_id = nil` forever. NO trigger carve-out. Terminal state for permanent orphans (>7d): leave them alone — `find_orphans/1`'s existing cutoff filters them out of scan. Accrue prior art (`~/projects/accrue/accrue/lib/accrue/jobs/meter_events_reconciler.ex`) ported verbatim (60s grace, 1000 rows/tick). Oban-optional degradation: `Logger.warning` at boot + `mix mailglass.reconcile` task — NO Task.Supervisor cron. Researcher specifically refuted the `*/15` STATE note preference — unlocked, `*/5` wins on orphan-linked latency with negligible DB cost.

---

## Area 4 — Tenant resolution at webhook boundary

**Options presented:**

| Option | Description | Selected |
|---|---|---|
| A. URL prefix `/webhooks/:tenant_id/postmark` | Path carries tenant | (as opt-in sugar via ResolveFromPath) |
| B. Secret-per-tenant reverse lookup | O(N) trial loop | |
| C. Provider sub-account identifier in verified payload | Stripe-Connect-style | (adopter-composable) |
| D. SingleTenant default + `c:resolve_webhook_tenant/1` callback | Behaviour callback composes with all strategies | ✓ |

**User's choice:** Approved synthesis (D as contract + A pre-provided as sugar).
**Notes:** Callback shape matches locked Phase 3 D-32 `c:tracking_host/1` and queued v0.5 DELIV-07 `c:adapter_for/1` — consistent convention across `Mailglass.Tenancy` behaviour. Signature verify FIRST, tenant resolve SECOND — closes Stripe-Connect chicken-and-egg trap. Three failure lanes: signature (401), tenant unresolved (422 via new `%TenancyError{type: :webhook_tenant_unresolved}`), orphan delivery (200 + orphan row). Peer precedents: Stripe Connect `event.account`, Shopify `X-Shopify-Shop-Domain`, accrue's `endpoint:` plug opt.

---

## Area 5 — Sync vs async normalization

**Options presented:**

| Option | Description | Selected |
|---|---|---|
| A. Sync (verify + normalize + Multi + broadcast + 200 OK in plug) | No Oban dep, HOOK-06 literal | ✓ |
| B. Async fast-ack (enqueue Oban job, worker normalizes) | Bounded response latency | |
| C. Hybrid (sync insert of raw + async normalize) | Intermediate-state admin UX | |

**User's choice:** Approved synthesis (A; `:async` reserved as v0.5 config knob).
**Notes:** Matches Phase 3 D-20 symmetry (sync `send/2` default, async `deliver_later/2` opt-in). P50 ≈ 15-30ms, P99 ≈ 150-300ms vs SendGrid 10s / Postmark 2min timeouts — ~30-60× headroom. Task.Supervisor fallback REJECTED as unsafe for webhooks (provider already got 200, in-memory loss = unrecoverable ledger corruption). Escape hatch: `:webhook_ingest_mode` config key defaults `:sync`; `:async` is `@moduledoc false` in v0.1. Mitigations: `lock_timeout` + `statement_timeout` on webhook process prevents retry-storm feedback loops. Peer precedents: Anymail sync default, stripity_stripe sync.

---

## Area 6 — Raw payload storage + retention

**Options presented:**

| Option | DB shape | Selected |
|---|---|---|
| Always-on, same table | `mailglass_events.raw_payload` populated always | |
| Selective | Only on errors/terminals | |
| Off-by-default | Opt-in via config | |
| Sampled | Statistical retention | |
| Separate table | `mailglass_webhook_events` FK-linked, prunable | ✓ |

**User's choice:** Approved synthesis (separate table — matches accrue verbatim).
**Notes:** ⚠️ **DDL change**: Phase 4 ships V02 migration creating `mailglass_webhook_events` + dropping `mailglass_events.raw_payload` column. Idempotency split: webhook-source via UNIQUE(provider, provider_event_id) on webhook_events; `mailglass_events.idempotency_key` partial UNIQUE remains for non-webhook sources. Retention policy: `succeeded_days: 14`, `dead_days: 90`, `failed_days: :infinity`, all accept `:infinity`. `Mailglass.Webhook.Pruner` Oban cron + `mix mailglass.webhooks.prune` manual task. Resolves GDPR tension (raw_payload with PII is prunable; events ledger stays append-only pristine). Prior art: accrue `accrue_webhook_events` with `raw_body :binary, redact: true`.

---

## Area 7 — SignatureError taxonomy + Auto-suppression (combined)

### Table A: SignatureError atom set + telemetry catalog

**Proposed atoms (recommendation: include):**
- `:missing_header`, `:malformed_header`, `:bad_credentials`, `:ip_disallowed`, `:bad_signature`, `:timestamp_skew`, `:malformed_key`

**Proposed atoms (recommendation: exclude):**
- `:tampered_body` (ECDSA math can't distinguish from `:bad_signature` — collapse)
- `:secret_not_configured` (belongs in `%ConfigError{type: :webhook_verification_key_missing}`, not SignatureError — avoids accrue's plug.ex:96 muddle)

**Field name debate:**
- Researcher: rename `:type` → `:reason` to match lattice_stripe + accrue precedent.
- Claude judgment: keep `:type` for Phase 1 Mailglass.Error hierarchy consistency (all 7 error structs use `:type + :message + :context`). User confirmed via "follow ur rec".

**Telemetry events (selected):**
- Outer span `[:mailglass, :webhook, :ingest, :*]` ✓
- Inner span `[:mailglass, :webhook, :signature, :verify, :*]` ✓
- Single-emit `[:mailglass, :webhook, :normalize, :stop]` ✓
- Single-emit `[:mailglass, :webhook, :orphan, :stop]` ✓
- Single-emit `[:mailglass, :webhook, :duplicate, :stop]` ✓
- Plus `[:mailglass, :webhook, :reconcile, :*]` full span per D-17 (added during synthesis)

**Metadata whitelist:** atoms/bools/ints + opaque tenant/delivery IDs only. **NO** `:ip`, header values, body size, recipient/subject/body content.

### Table B: Auto-suppression ship vs defer

| Option | Selected |
|---|---|
| B1. Ship full (`:bounced` hard + `:complained` + `:unsubscribed`) | |
| B2. Ship minimal (`:bounced` hard + `:complained` only; defer `:unsubscribed`) | |
| B3. Defer fully to v0.5 DELIV-02 | ✓ |

**User's choice:** Approved synthesis (B3 defer — matches Phase 3 deferred-list lock).
**Notes:** Phase 4 writes Event rows ONLY. Adopters wanting auto-suppression attach telemetry handler on `[:mailglass, :webhook, :normalize, :stop]` + call `Mailglass.Suppressions.add/3` per event. Documented recipe in `guides/webhooks.md`.

---

## Claude's Discretion

See 04-CONTEXT.md §Claude's Discretion — 9 items scoped for the planner + executor (moduledoc wording, NimbleOptions schema exact keys, test fixture layout, mix task arg parsing, etc.).

## Deferred Ideas

See 04-CONTEXT.md `<deferred>` section — 21 items total across v0.5 forward-ref, deliberately rejected alternatives, and adopter-owned concerns.

## Research Agents Spawned (for audit)

1. **Provider verifier contract** — 7 sources (lattice_stripe, django-anymail, ActionMailbox, Svix, OTP 27 public_key docs, SendGrid + Postmark docs)
2. **Plug mounting + CachingBodyReader** — 12 sources (lattice_stripe, Phoenix LiveDashboard, Oban Web, Plug PR #698, Plug issue #884, ActionMailbox, stripity_stripe, django-anymail, Mainmatter webhook blog)
3. **Orphan reconciliation** — 5 sources (accrue prior art, Oban.Plugins.Cron, SendGrid benchmarks, Postmark bounce webhook, Oban Recipes Part 3)
4. **Tenant resolution** — 5 sources (Postmark, SendGrid, Stripe Connect, Shopify, accrue)
5. **Sync vs async normalization** — 10 sources (Postmark retries, SendGrid timeouts, Anymail, stripity_stripe, Stripe webhook docs, Mainmatter blog, Svix timeout best practices)
6. **Raw payload retention** — 3 sources (Anymail, Stripe data retention, MagicBell webhook guide) + 8 accrue source files
7. **SignatureError taxonomy + auto-suppression** — 6 sources (Postmark bounce webhook, Postmark IPs, SendGrid, Anymail tracking, django-anymail sendgrid.py) + lattice_stripe + accrue direct reads

All research files referenced with absolute paths in 04-CONTEXT.md `<canonical_refs>`.
