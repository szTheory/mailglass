---
id: SEED-008
status: active
planted: 2026-09-17
planted_during: v2.8 (Truthful Repo) scoping
trigger_when: when planning outbound operator evidence, deliverability, adopter onboarding, or delivery-audit work
scope: medium
source: real adopter incident (GetFluent, reported via cross-session field report 2026-09-15)
---

# SEED-008: Delivery-Absence Detection

## Why This Matters

**This is the first seed planted from a real adopter incident rather than an
internal idea.** That alone raises its weight.

GetFluent sent **zero transactional email for twelve days and could not tell.**
Swoosh's Resend adapter treats any 2xx as success
(`deps/swoosh/lib/swoosh/adapters/resend.ex:118`), so `deliver/1` returned
`{:ok, %{id: ...}}` throughout.

mailglass handles the *recording* side of this correctly. Verified at source:

- The send path writes `status: :queued` (`lib/mailglass/outbound/persistence.ex:20`),
  then after the adapter returns writes `status: :sent, last_event_type: :dispatched,
  dispatched_at: ...` (`persistence.ex:71-75`).
- `delivered_at` (`migrations/postgres/v01.ex:34`) **stays NULL** and `last_event_type`
  never becomes `:delivered` unless a provider webhook fires.
- So mailglass never *claims* delivery it cannot prove. The `dispatch ≠ delivered`
  doctrine is implemented faithfully.

**And it would still not have saved them.** Without webhooks wired, an adopter sees
twelve days of rows reading `:sent` / `delivered_at: NULL` — honest bookkeeping with
nothing raising a hand. The doctrine is worth nothing to an adopter who has not wired
webhooks, which is exactly the adopter most likely to need it.

The gap is not truthfulness. **It is the absence of an absence-signal.**

## The Two Unserved Capabilities

Both were independently identified by the adopter as things they would otherwise
build themselves. Verified as not existing upstream:

### 1. Sender-domain preflight

**DOES NOT EXIST as a provider-API check.**

- `mix mail.doctor` is DNS-only — SPF/DKIM/DMARC/MX/BIMI via `:inet_res.resolve/3`
  (`lib/mailglass/deliverability/resolver.ex:55`), on-demand, requires explicit
  `--domain`, and makes **zero HTTP calls**. No `/v3/domains`, no `ListIdentities`,
  no `verified_senders` anywhere in `lib/`. No provider is named in `deliverability/`
  at all.
- Boot runs `Mailglass.Runtime.bootstrap!/0` (`lib/mailglass/runtime.ex:22-46`) but
  validates only config schema, `:schema` identifier, and that the Repo adapter is
  Postgres.
- The config schema has **no `from`/`from_domain`/`sender` key at all**
  (`lib/mailglass/config.ex`); the only `sender_domain` is a rate-limit bucket
  (`config.ex:155`).

The adopter's framing is good: their `config/runtime.exs` already `fetch_env!`s
`EMAIL_FROM_ADDRESS`, so a missing value crash-loops. The ask extends *"is it set"*
to *"is it usable"* — check the configured From domain against the provider's
verified-domains endpoint and refuse to start if absent.

### 2. "Nothing delivered in N"

**DOES NOT EXIST.** No zero-volume, stall, or age-threshold detection in core or admin.

- `mix mailglass.reconcile` sweeps **orphan webhook events** only — events with
  `delivery_id: nil` + `needs_reconciliation: true` (`lib/mailglass/events/reconciler.ex:58`).
  It queries *events*, not deliveries, so it requires webhooks to already be firing and
  cannot detect "dispatched but never delivered."
- No query anywhere selects deliveries stuck in `:queued`/`:sent` past an age threshold.
- `Operator.SupportSummary.summarize_tenant/1` gives failed-ingest counts, orphan
  backlog, and replay outcomes over 24h — nothing about volume falling to zero.
- Admin surfaces a passive empty state only
  (`mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex:73-101`).

Closest existing hook an adopter could build on:
`[:mailglass, :delivery, :feedback, :stop]` (`lib/mailglass/outbound/projector.ex:196`).

For a low-volume product, **zero deliveries is indistinguishable from low traffic**
without an explicit check. That is the core insight and it generalizes past this adopter.

## When to Surface

**Trigger:** when planning outbound operator evidence, deliverability tooling, adopter
onboarding, or delivery-audit work. Pairs naturally with `SEED-004` (sent-email snapshot
retention) — both answer "what actually happened to our mail?", from opposite ends.

## Design Cautions (if this is ever built)

- **Scope discipline.** "Alerting" drags toward multi-channel notification, which is
  permanently out of scope (PROJECT.md). The deliverable is a *queryable signal* and
  possibly a telemetry event / mix task — **not** a notifier.
- **Absence-detection needs a volume baseline**, or it pages every quiet weekend. Any
  design must confront "zero is normal for this tenant" or it becomes noise — the exact
  failure v2.8 exists to prevent.
- **Provider-API preflight adds an HTTP dependency to boot.** Today the deliverability
  path is deliberately zero-HTTP and provider-agnostic. A boot-time provider call is a
  real architectural change: it introduces a startup network dependency and a new failure
  mode. Consider opt-in, and consider failing open with a loud log rather than refusing
  to boot.
- **Two sharp edges an adopter hits today**, worth fixing regardless of this seed:
  Delivery `status` has **no `:delivered` value** — the set is
  `[:queued, :sent, :dispatched, :failed, :suppressed]` (`lib/mailglass/outbound/delivery.ex:54`),
  so confirmation lives in `last_event_type`/`delivered_at`; and the Operator row
  projection exposes `status`, `last_event_type`, `last_event_at` but **not**
  `delivered_at`/`dispatched_at` (`lib/mailglass/operator/deliveries.ex:83-95`).

## Related

- `SEED-004` — sent-email snapshot retention (provider-independent message body)
- `.planning/research/JTBD-COVERAGE.md` — note this map is stale (v1.2-era) and does not
  yet carry this gap
- Adopter record: GetFluent `lib-requests/2026-09-15-mailglass.md`, SEED-009/SEED-010

---

*Planted 2026-09-17 during v2.8 scoping. Deliberately NOT in v2.8 scope — v2.8 is a
truthfulness milestone and this is product expansion. Recorded so the signal is not lost.*
