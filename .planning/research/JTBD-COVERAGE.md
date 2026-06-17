# JTBD Coverage, Gaps, and Diminishing Returns

> ⚠️ **STALENESS BANNER (added 2026-06-16).** This file is **5 milestones stale** — it covers up to
> `mailglass_inbound` 0.1.0 / v1.2-still-executing, but the project has since shipped v1.4 (inbound
> stability lock), v1.5 (demo evidence), **v1.6 (inbound `1.0.0` live on Hex)**, v1.7 + v1.11 (admin
> design-system polish), and v1.8–v1.10 (brand). Live versions are now **1.6.2 / 1.6.2 / 1.3.1**.
> The **status tables and gap rows below are out of date** — treat them as historical. However, the
> file's **central conclusion has been borne out**: "after completed v1.2 inbound plus a golden
> example app, further JTBD expansion is mostly diminishing returns — slow down and wait for pull"
> (§5). Every milestone since has been flat-tail polish, exactly as predicted. The 2026-06-16
> next-step assessment confirms the project is feature-complete for its scope; the one remaining
> adopter wedge is onboarding / day-2 DX (see `.planning/threads/adopter-onboarding-day2-confidence.md`),
> which is friction-removal, not a new JTBD category. **Full refresh of this file is deferred to the
> next feature-discovery pass** (a milestone-sized task); it is not a precondition for the onboarding wedge.

**Domain:** Phoenix transactional email framework
**Project:** mailglass (`mailglass` + `mailglass_admin` + `mailglass_inbound`)
**Researched:** 2026-05-23
**Refresh:** #2
**Covers up to:** `mailglass` 1.0.0 / `mailglass_admin` 1.0.0 / `mailglass_inbound` 0.1.0 shipped; Phase 45 complete; v1.2 still executing
**Overall confidence:** HIGH *(as of 2026-05-23; see staleness banner above)*

---

## 0. How to read this

This file is the **source of truth** for adopter jobs-to-be-done.
[`guides/jobs.md`](../../guides/jobs.md) is the public projection of the stable,
already-shipped adopter jobs from this map.

When refreshing:

1. Update **this** file first.
2. Re-project the stable Built rows into `guides/jobs.md`.
3. Only then adjust README or guide links if discoverability drifted.

### Status legend

| Status | Meaning |
|---|---|
| **Built** | Shipped and inside the public `v1.x` promise |
| **Built (unstable)** | Shipped, but outside the `v1.x` promise (`mailglass_inbound`) |
| **Planned-v1.2** | Scoped into the active v1.2 milestone |
| **Deferred-v1.3+** | Captured, deliberately not scheduled |
| **Out-of-scope** | Permanently excluded by product shape |

### Update-order rule

When local planning artifacts disagree, prefer:

1. live code
2. `PROJECT.md`
3. `ROADMAP.md`
4. phase summaries / verification artifacts
5. `STATE.md`

Reason: `STATE.md` still contains known orchestrator bookkeeping drift from the
Phase 44.5 → 45 transition, while `PROJECT.md`, `ROADMAP.md`, and Phase 45
artifacts already reflect that **Phase 45 completed on 2026-05-23**.

### Reader definition

The adopter here is still the same one locked in `PROJECT.md`: a senior or
technical-lead Phoenix engineer shipping transactional email in a SaaS app.

---

## 1. What ecosystems teach us to expect

Primary-source sanity check against current adjacent ecosystems:

- **Rails Action Mailer** converges on the baseline jobs of authoring,
  multipart delivery, attachments, queueing, previewing, and testing.
- **Rails Action Mailbox** converges on inbound routing, async processing, local
  dev visibility, and inbound testing as the expected receive-mail shape.
- **Anymail** converges on normalized webhook/tracking vocabulary plus inbound as
  first-class sister concerns.
- **Laravel Mail** converges on mailables, previewing, attachments, queueing,
  and testing as table stakes.
- **Resend** adds a modern expectation that inbound should have stored payload
  visibility, replay/debug surfaces, and convenience scheduling around send
  flows.

**Conclusion:** the current mailglass JTBD map is already category-complete for
the target adopter. The remaining delta is mostly:

- maturity on inbound,
- adopter-visible trust proof,
- convenience surfaces around already-covered jobs.

No new whole-job category surfaced in external research that should move the
roadmap ahead of the existing gaps.

---

## 2. The full JTBD map

The lifecycle still groups cleanly into **Author → Send → Observe → Operate →
Receive**. The 10 rows marked **★** are the public stable jobs projected into
`guides/jobs.md`.

### Author

| Job ("when you need to…") | Status | Fulfilled by | Why it matters |
|---|---|---|---|
| ★ Build an email that renders everywhere, including Outlook, without Node | Built | `Mailglass.Mailable`, `Mailglass.Components`, `Mailglass.Renderer` | Core authoring job; differentiator versus raw Swoosh |
| ★ See an email before it ships | Built | Preview LiveView, `mailglass_admin_routes` | Preview is a standard expectation in strong ecosystems |
| Localize an email | Built | Gettext integration | Table stakes for serious SaaS apps |
| Author in MJML instead of HEEx | Built (opt-in) | `Mailglass.TemplateEngine.MJML` | Optional compatibility path, not the product center |
| Use a drag-and-drop visual builder | Out-of-scope | — | Wrong product category for this library |

### Send

| Job | Status | Fulfilled by | Why it matters |
|---|---|---|---|
| ★ Ship an auth email you can trust | Built | `deliver/2`, `:transactional` stream, `NoTrackingOnAuthStream` | Security-sensitive differentiator |
| ★ Send reliably in the background | Built | `deliver_later/2`, Oban-optional worker path, idempotency keys | Transactional baseline |
| Attach files | Built | `Mailglass.Message.attach/2` | Table stakes |
| Throttle send rate by tenant/domain | Built | `Mailglass.RateLimiter` | Operational hardening most mailers leave to adopters |
| Route different tenants through different ESPs | Built | `resolve_outbound_adapter_ref/1`, `adapter_ref` routing | Strong multi-tenant differentiator |
| Schedule mail for a specific future time | Deferred-v1.3+ | Oban `scheduled_at` is today's escape hatch | Convenience, not a missing category |

### Observe

| Job | Status | Fulfilled by | Why it matters |
|---|---|---|---|
| ★ Prove what happened to a message | Built | append-only `mailglass_events`, `Mailglass.Events`, PubSub | One of the core reasons to adopt |
| ★ Test email without sending real mail | Built | `MailerCase`, `TestAssertions`, Fake adapter | Evaluation and team productivity baseline |
| Instrument outbound with metrics/tracing | Built | `Mailglass.Telemetry` | Expected in modern production systems |
| Measure opens/clicks when desired | Built (opt-in) | `Mailglass.Tracking` | Supported, but intentionally de-centered |

### Operate

| Job | Status | Fulfilled by | Why it matters |
|---|---|---|---|
| ★ Stop emailing bounced or complaining addresses | Built | `Mailglass.Suppression`, projection from verified events, resync task | Deliverability and compliance baseline |
| ★ Turn provider webhooks into one normalized event stream | Built | `Mailglass.Webhook.*`, Anymail taxonomy, signature verification | Lowers provider-switching cost |
| ★ Figure out why a delivery failed in production | Built | operator LiveView, replay, reconcile, incident guide | Differentiator: in-app operator tooling |
| ★ Run this in a multi-tenant SaaS | Built | `tenant_id` everywhere, `Mailglass.Tenancy`, stream-aware routing | Deep architectural differentiator |
| Comply with one-click unsubscribe | Built | RFC 8058 controller, signed tokens, rotation support | 2024+ sender-requirement baseline |
| Check sending-domain deliverability | Built | `mix mail.doctor` | Differentiator; unusual for framework peers |
| Use a hosted provider dashboard instead of in-app surfaces | Out-of-scope | — | Hosted console is a different product |

### Receive

| Job | Status | Fulfilled by | Why it matters |
|---|---|---|---|
| Receive and route inbound mail to handlers | Built (unstable) | router DSL, `Mailbox` behaviour, Postmark + SendGrid ingress, replayable storage, async execution | Category opened in v1.1 |
| Instrument inbound with telemetry and replay-safety | Built (unstable) | Phase 45 telemetry spans, MIME foundation, replay convergence proof | Phase 45 meaningfully closed part of the maturity gap |
| Receive inbound on Mailgun / SES | Planned-v1.2 | lift-and-alias from outbound verifiers | Biggest remaining provider asymmetry |
| Test inbound handlers and scaffold them | Planned-v1.2 | `MailboxCase`, assertions, generators | Ecosystem expectation confirmed by Rails/Anymail |
| Debug inbound in an operator UI | Planned-v1.2 | `InboundLive`, evidence/timeline/routing-trace surfaces | Strong modern expectation |
| Operate inbound from CLI/runtime tooling | Planned-v1.2 | doctor / replay / prune / rate-limit surfaces | Needed for production confidence |
| Receive via Cloudflare Email Routing | Deferred-v1.3+ | — | Provider-specific tail item |
| Receive via raw SMTP listener | Deferred-v1.3+ | — | Different transport class; likely sibling-lib territory |
| Use a synthetic inbound dev UI | Deferred-v1.2.1 | — | Polish on a category already opened |
| Auto-suppress inbound senders | Deferred-v1.3+ | flag-only today | High risk of destroying diagnostic signal |

### Permanent out-of-scope expectations

| Job an adopter might ask for | Status | Why it stays out |
|---|---|---|
| Newsletters, campaigns, segmentation, drip automation | Out-of-scope | Marketing product, not transactional framework |
| Multi-channel notifications (SMS/push/in-app/Slack) | Out-of-scope | Different abstraction boundary entirely |
| Built-in subscriber preference center | Out-of-scope | Better built on top of suppression/consent primitives |
| Hosted mail ops console | Out-of-scope | mailglass mounts in adopter apps; it does not host |
| AMP for Email | Out-of-scope | Tiny adoption, poor ROI |
| Bamboo API compatibility | Out-of-scope | Migration target is raw Swoosh, not Bamboo emulation |
| MySQL / SQLite persistence | Out-of-scope | Postgres features are load-bearing |

---

## 3. Coverage gaps that still matter

Only missing or meaningfully incomplete adopter jobs belong here. Closed docs
work is removed from the gap list.

| ID | Job affected | What is still missing | Severity | Why it matters |
|---|---|---|---|---|
| **GAP-01** | Evaluate whether to adopt | No golden example app showing install → preview → send → webhook/operator flow → upgrade path end to end | **High** | This is still the single strongest trust artifact missing from adoption |
| **GAP-02** | Receive and route inbound | Inbound category is open, but still lacks admin, test, operator, and docs parity with outbound | **High** | This is now a maturity gap, not a missing category |
| **GAP-03** | Receive inbound on major providers | Mailgun + SES inbound are still not shipped | **Med** | Visible symmetry gap after outbound already normalized those providers |
| **GAP-04** | Schedule a send for future delivery | No thin first-party `deliver_at` convenience surface | **Low** | Real ask, but not worth outranking trust or inbound maturity |
| **GAP-05** | Preference-center story | Boundary exists, but the escape hatch is still under-documented for adopters near that edge | **Low** | Docs gap only; should not trigger product expansion |

### What is no longer a gap

- **JTBD ramp-up docs** are now present and should be maintained, not re-argued.
- **Inbound observability foundation** is no longer a gap at the category level;
  Phase 45 moved it into shipped-but-unstable maturity work.

---

## 4. Recommended priority order

The ordering should stay opinionated:

1. **Golden example app (GAP-01).**
   Highest marginal adoption value. The strongest remaining weakness is not
   product capability; it is lack of a runnable proof artifact an adopter can
   trust quickly.

2. **Finish inbound maturity in v1.2 (GAP-02, GAP-03).**
   This is the last broad job family still below outbound maturity. Phase 45
   already proved the category should continue; the remaining work is coherent
   and already scoped.

3. **Document the preference-center escape hatch (GAP-05).**
   Low effort, prevents repeated confusion at the marketing boundary, and does
   not expand scope.

4. **Only then consider a scheduled-send wrapper (GAP-04).**
   Useful, but this is a convenience on top of an already-served job. It should
   never outrank trust proof or inbound maturity.

5. **Everything else stays pull-driven.**
   Cloudflare inbound, raw SMTP listener, synthetic inbound UI, ecosystem
   integrations, and similar work should happen only with concrete adopter pull.

---

## 5. Diminishing-returns line

The curve has not changed in shape since the first map; it is just clearer now
that Phase 45 closed part of the inbound maturity deficit.

```
served
  │             ┌─────────────── flat tail
  │         ┌───┘
  │     ┌───┘        knee = completed v1.2 inbound
  │  ┌──┘
  │──┘   steep region = current stable outbound/admin jobs
  └──────────────────────────────────────────── jobs built
```

### Steep region: already built

The current stable outbound/admin jobs cover the overwhelming majority of what
the target adopter expects from a transactional email framework:

- authoring,
- preview,
- safe sending,
- async delivery,
- observability,
- testing,
- suppression,
- webhook normalization,
- operator debugging,
- multi-tenancy.

### Knee: completed v1.2 inbound plus proof artifact

The map reaches "basically done" when two things are true:

1. **Inbound v1.2 maturity lands**: providers, test helpers, operator surfaces,
   runtime tooling, and docs.
2. **A golden example app exists** so adopters can trust the system quickly.

That is the saturation line for the target persona.

### Flat tail: build only on pull

Past that point, additional work mostly serves small, non-overlapping slices:

- provider-specific inbound tails,
- SMTP listener as a separate transport class,
- synthetic inbound dev polish,
- ecosystem integrations that only matter if the adopter also uses another
  sibling library,
- marketing-adjacent asks that should remain outside scope.

**Verdict:** after completed v1.2 inbound plus a golden example app, further
JTBD expansion is mostly diminishing returns. Slow down and wait for pull.

---

## 6. Refresh log

| Date | Refresh | Meaningful changes |
|---|---|---|
| 2026-05-22 | #1 | Initial full map. Knee placed at completed-v1.2 inbound. |
| 2026-05-23 | #2 | Public `guides/jobs.md` rewritten as a narrative adopter ramp-up; Phase 45 moved inbound telemetry/replay-safety from planned to built-unstable; docs gap removed from active gaps; external ecosystem sanity check confirmed no missing whole-job category. |

---

## 7. Traceability index

| Gap | Job | Current hook into planning |
|---|---|---|
| GAP-01 | Golden example app | Unscoped; best candidate for v1.3 or a small trust-focused slice |
| GAP-02 | Inbound admin/test/operator/docs maturity | v1.2 Phases 47, 48, 49, 50 |
| GAP-03 | Mailgun + SES inbound | v1.2 Phase 46 and docs in Phase 50 |
| GAP-04 | Scheduled send convenience surface | Unscoped; only if adopter pull appears |
| GAP-05 | Preference-center escape hatch docs | Best handled in docs work, not product work |

---

## 8. Sources

### Internal sources

- `.planning/PROJECT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/phases/45-inbound-telemetry-idempotency-foundation/`
- `.planning/research/FEATURES.md`
- `guides/jobs.md`
- live code under `lib/mailglass/`, `mailglass_admin/lib/`, `mailglass_inbound/lib/`

### External primary sources

- Rails Action Mailer Basics: https://guides.rubyonrails.org/action_mailer_basics.html
- Rails Action Mailbox Basics: https://guides.rubyonrails.org/action_mailbox_basics.html
- Anymail docs: https://anymail.dev/en/stable/
- Laravel Mail docs: https://laravel.com/docs/12.x/mail
- Resend receiving docs: https://resend.com/docs/dashboard/receiving/introduction
