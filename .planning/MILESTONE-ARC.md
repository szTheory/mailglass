# Milestone Arc: mailglass Post-v1.0

This document is the canonical milestone arc for mailglass after the `v1.0`
stability lock.
It exists to keep `$gsd-new-milestone` grounded in the product arc instead of
starting from a blank prompt every time.

## Current Strategic Posture

- **Trajectory:** Operator-first
- **Planning horizon:** `v1.2` is shipped; next milestone should be chosen from explicit candidates rather than implied carry-forward
- **Current product thesis:** Become the canonical production transactional
  email framework for Phoenix SaaS apps with a credible inbound sibling package,
  then expand only where operator and adopter leverage stay clear
- **Current rule:** Post-`v1.0` milestones should protect the narrow core
  contract while expanding only where product leverage is clear

## Status Key

- `candidate` — viable next milestone, not yet started
- `active` — current open milestone
- `shipped` — completed and archived
- `deferred` — intentionally not next
- `future-bet` — visible but not committed in the milestone sequence

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

### `shipped` — v1.0 Stability Lock

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

**Shipped note (2026-05-06):** `v1.0 Stability Lock` is now shipped. The contract, compatibility, trust-doc, and release-rehearsal proof surfaces are archived; remaining branch-protection proof is explicit accepted external debt.

## Recently Shipped

### `shipped` — v1.1 Inbound Core Slice (`mailglass_inbound`)

**Why it mattered:** Opened the inbound sibling package without weakening the
locked `v1.x` outbound/admin core.

**Delivered:**
- Router DSL and mailbox behaviour
- Postmark and SendGrid inbound ingress
- Replayable normalized + raw inbound storage
- Oban-backed async routing with bounded fallback

**Unlocked next:** Provider expansion, operator/admin depth, DX parity, and
runtime tooling for inbound.

### `shipped` — v1.2 Inbound Production Confidence

**Why now:** Once the inbound package existed, the highest-leverage next step
was to make it genuinely operable and supportable for real adopters instead of
leaving it as a narrow proof slice.

**Delivered:**
- Inbound telemetry, MIME seam, and 1000-replay convergence proof
- Mailgun and SES inbound ingress
- Inbound test helpers, fixtures, and generators
- Tenant-safe inbound admin LiveView and runtime operator tooling
- Six inbound guides plus repo-truth closeout
- Phase 51 stability debt retirement inside the same milestone

**Unlocked next:** A choice among ecosystem integrations, broader inbound
transport/provider expansion, or adjacent operator leverage.

## Candidate Milestones

### `candidate` — Ecosystem Integrations

**Why it is viable:** `SEED-003-ecosystem-integrations` survived milestone
closeout as a real opportunity, but it was intentionally kept dormant rather
than being smuggled into `v1.2`.

**Possible scope:**
- High-value integrations with adjacent Phoenix/email tooling
- Lightweight glue that improves adoption without creating a second product
- Work that builds on the now-stable inbound + operator surface

**Why it is not active yet:** The seed is acknowledged, not selected.

### `candidate` — Broader Inbound Expansion

**Why it is viable:** `v1.2` shipped the credible operator-grade inbound base,
so the next inbound milestone could broaden transport and provider reach.

**Possible scope:**
- Cloudflare Email Routing support
- `gen_smtp` relay ingress
- Conductor-style synthetic inbound dev tooling

**Why it is not active yet:** These were explicitly deferred past `v1.2` and
need fresh scoping because they are not all the same transport/problem class.

### `deferred` — Ecosystem Integrations Seed

**Item:** `SEED-003-ecosystem-integrations`

**Status:** Dormant at `v1.2` milestone close on 2026-05-26.

## Future Bets (post-`v1.0`)

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
*Last updated: 2026-05-26 after shipping and archiving v1.2 Inbound Production Confidence.*
