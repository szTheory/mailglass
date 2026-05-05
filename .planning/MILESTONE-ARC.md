# Milestone Arc: mailglass Through v1.0

This document is the canonical pre-`v1.0` milestone vision for mailglass.
It exists to keep `$gsd-new-milestone` grounded in the product arc instead of
starting from a blank prompt every time.

## Current Strategic Posture

- **Trajectory:** Operator-first
- **Planning horizon:** Concrete through `v1.0`; lighter-weight beyond that
- **Current product thesis:** Become the canonical production transactional
  email framework for Phoenix SaaS apps before expanding into inbound or
  broader adjacent surfaces
- **Current rule:** Pre-`v1.0` milestones optimize for operator confidence,
  adopter confidence, and production maturity

## Status Key

- `candidate` — viable next milestone, not yet started
- `active` — current open milestone
- `shipped` — completed and archived
- `deferred` — intentionally not next
- `future-bet` — visible but not committed in the pre-`v1.0` sequence

## Arc

### `shipped` — v0.1 Validation Release

**Goal:** Prove the thesis with a real Phoenix-first transactional email
framework built on Swoosh.

**Why it mattered:** Without a usable core, every later promise was still
theoretical.

**Delivered:**
- HEEx-native mailables and rendering pipeline
- Dev preview dashboard
- Event ledger, tenancy, webhook foundation, install flow, test surface

**Unlocked next:** Production-hardening work instead of greenfield framework
construction.

### `shipped` — v0.2 Production-Credible Core

**Goal:** Make the transactional core credible for real teams, not just a demo.

**Why it mattered:** Production teams need stable APIs, unsubscribe,
suppression, and release discipline before broader adoption.

**Delivered:**
- Native `Mailglass.Message` API
- Stream policy and Feedback-ID support
- RFC 8058 unsubscribe
- Webhook-driven suppression and release hardening

**Unlocked next:** Full provider coverage and operator/admin depth.

### `shipped` — v0.3 Webhook Coverage Complete

**Goal:** Complete first-party webhook/provider coverage and ship the milestone
cleanly.

**Why it mattered:** Mailglass could not claim production transactional
coverage while major providers were still missing or partially verified.

**Delivered:**
- Mailgun, SES, and Resend first-party webhook support
- End-to-end provider coverage across Postmark / SendGrid / Mailgun / SES / Resend
- v0.3.x publish recovery and closeout

**Unlocked next:** Shift from provider parity to operator confidence and
adopter confidence.

### `shipped` — v0.4 Operator Confidence

**Goal:** Make mailglass credible for production operators, not just library
authors.

**Why now:** The framework core and provider coverage are in place. The next
gap is operating, inspecting, and trusting the system in a real SaaS app.

**Must land:**
- Prod-mountable admin MVP in `mailglass_admin`
- Sent-mail browser and per-delivery event timeline
- Suppression management UI
- Webhook replay operator flow
- Step-up auth on destructive actions
- `mix mail.doctor` core DNS checks: SPF, DKIM, DMARC, MX, BIMI
- Per-tenant adapter resolver
- Carry-forward ship/install fixes from `Issue #25` and `Issue #9` (closed in Phase 27 — see REL-17/REL-18)

**Explicit non-goals:**
- Inbound routing
- Marketing / campaigns / lists / automation
- Broad new transport/provider expansion

**Exit criteria:**
- An adopter can send, inspect, diagnose, and safely operate transactional
  mail from inside a Phoenix app
- The release/install story is credible on a fresh host
- The product story shifts from “library with primitives” to “operational
  email framework”

**Unlocks next:** Adoption hardening and production-support polish.

**Activation note (2026-05-01):** `v0.4` is now the active milestone.
Phase 22 completed the read-only operator data foundation, so the next work
starts at production admin mount/auth rather than re-scoping the milestone.

### `shipped` — v0.5 Adoption Hardening

**Goal:** Reduce adopter friction and close the “serious SaaS team” integration
gaps.

**Why now:** Once the operator story is real, the next leverage comes from
making setup, scaffolding, testing, and troubleshooting feel unusually smooth.

**Must land:**
- Per-domain rate limiting
- `mix mailglass.gen.mailable`
- Richer test assertion helpers
- Webhook troubleshooting guide
- Install/smoke contract tightening where still brittle
- Upgrade/operator docs improvements driven by real friction

**Explicit non-goals:**
- Inbound routing
- Marketing surfaces
- Large new conceptual surface area unrelated to adoption depth

**Exit criteria:**
- New adopters can install, scaffold, test, and debug without hand-rolled
  glue
- The product feels intentionally designed for repeat adoption, not just
  “possible to integrate”

**Unlocks next:** Production maturity and stabilization.

### `shipped` — v0.6 Production Maturity

**Goal:** Make the system resilient and legible under real production support
conditions.

**Why now:** After operator UX and adoption UX are strong, the remaining work
is making the product boring in the best sense: observable, stable, and easy
to support.

**Must land:**
- Observability and operator workflow polish
- Replay / reconcile / admin authorization hardening
- Deferred verification and regression gaps closed where still material
- Production-oriented docs for failure modes, incident response, and support

**Explicit non-goals:**
- Inbound routing
- Marketing surfaces
- Major pre-`v1.0` abstraction pivots

**Exit criteria:**
- Mailglass feels stable during incidents, not just during development
- Known operator and support workflows are documented and defensible

**Unlocks next:** `v1.0` stability lock with confidence.

### `active` — v1.0 Stability Lock

**Goal:** Declare the transactional/admin core stable for long-lived production
adoption.

**Why now:** The framework should only call itself `v1.0` once the core
surface is stable, documented, and proven enough to promise continuity.

**Must land:**
- API stability lock across the transactional/admin core
- Long-lived deprecation policy
- Production references or equivalent proof artifacts
- Final docs / positioning sweep aligned with actual shipped scope
- Upgrade guarantees for future minor releases

**Explicit non-goals:**
- Inbound routing
- Marketing surfaces
- “Everything email-related” expansion

**Exit criteria:**
- Maintainers can promise core stability with a straight face
- Adopters can choose mailglass without expecting major churn in the core
  transactional/admin surface

**Unlocks next:** The right to expand beyond the current product boundary.

**Activation note (2026-05-05):** `v1.0 Stability Lock` is now the active milestone. Research locked the milestone shape to a docs-heavy proof release with targeted contract enforcement, not product-surface expansion.

## Future Bets (post-`v1.0`)

### `future-bet` — mailglass_inbound

**Why visible:** It is still part of the product vision, but pre-`v1.0`
focus should stay on becoming the best production transactional email
framework first.

**Candidate scope:**
- Router DSL
- Mailbox behaviour
- Provider-specific ingress plugs
- Storage adapters
- Async routing via Oban
- Conductor-style dev UI

**Trigger to promote:** Sustained adopter pull after the outbound/operator core
is stable, or strong evidence that inbound materially improves the transactional
framework story rather than diluting it.

### `future-bet` — adjacent deliverability / workflow bets

Keep visible but uncommitted until user pull justifies them:
- Warmup scheduler
- BIMI tooling beyond `mail.doctor`
- A/B testing or automation surfaces

## Workflow Contract

Future milestone creation and closeout should treat this file as the strategic
source of truth:

1. `$gsd-new-milestone` should read this file if present and surface the next
   recommended milestone candidates before freeform scoping.
2. The chosen milestone should move from `candidate` to `active` when the new
   milestone is initialized.
3. `$gsd-complete-milestone` should move the current milestone from `active`
   to `shipped` during archive/closeout.
4. The arc can be revised after each milestone, but only deliberately — not by
   drifting doc-by-doc.

---
*Last updated: 2026-05-05 after activating v1.0 Stability Lock.*
