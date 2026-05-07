# Phase 39: Inbound Package Foundation - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the canonical `mailglass_inbound` package contract for the first
inbound slice: one normalized inbound message model, one router DSL, one
mailbox behaviour, and one tenant-safe storage foundation for canonical
records plus raw evidence.

This phase establishes the adopter-facing contract and persistence shape. It
does not implement provider-specific ingress end to end, broad provider parity,
Conductor UI, SMTP relay ingress, or a generalized workflow engine for inbound
automation.

</domain>

<decisions>
## Implementation Decisions

### Canonical `InboundMessage` contract
- **D-39-01:** The canonical adopter-facing `%InboundMessage{}` contract must
  be a plain normalized struct, not an Ecto schema.
- **D-39-02:** `%InboundMessage{}` is the normalized routing and mailbox input,
  not the durable truth record and not the replay/audit history record.
- **D-39-03:** Stable first-class fields on `%InboundMessage{}` should cover:
  tenant scope, provider provenance, provider message reference when available,
  RFC `Message-ID`, envelope recipient, sender/recipient header data, subject,
  normalized headers, sent/received timestamps, normalized body fields, and a
  normalized attachment manifest.
- **D-39-04:** `tenant_id` and envelope-recipient semantics are first-class
  stable fields. Do not make routing depend only on visible `To` headers.
- **D-39-05:** Raw provider payloads, raw request headers/body, signature
  evidence, replay identifiers, mailbox outcomes, retention policy, storage
  paths, and provider-only extras must stay out of the stable public struct.
- **D-39-06:** Provider-specific extras may only enter the stable struct if
  they normalize honestly across first-party ingress providers. Do not use the
  public struct as a dumping ground for provider shape drift.

### Router DSL shape
- **D-39-07:** The public routing contract should use one adopter-owned router
  module with a thin declarative macro DSL that compiles into normalized pure
  route data consumed by a plain runtime matcher engine.
- **D-39-08:** Routing semantics are top-to-bottom, first-match wins, exactly
  one mailbox target per inbound message.
- **D-39-09:** Multiple matcher clauses on one route are logical `AND`. Multiple
  route lines are logical `OR` by order.
- **D-39-10:** The public Phase 39 matcher surface should stay narrow:
  recipient, subject, and header matching only, with exact string and regex
  support only.
- **D-39-11:** No-match must be an explicit non-exceptional result. Route miss
  is not an automatic bounce.
- **D-39-12:** Defer arbitrary function predicates, mailbox self-registration,
  body/attachment/provider/raw-MIME matching, negation/boolean combinators, and
  multi-match fan-out routing.

### Mailbox behaviour contract
- **D-39-13:** The public mailbox contract should be one narrow behaviour with
  one stable callback: `process/1`.
- **D-39-14:** Mailbox outcome classes should be locked to:
  - `:accept`
  - `:ignore`
  - `{:reject, reason}`
  - `{:bounce, reason}`
- **D-39-15:** Raised exceptions, exits, and throws are execution failures, not
  mailbox outcomes. Retry and failure handling should key off execution failure,
  not overload reject/bounce semantics.
- **D-39-16:** Async execution mode must stay behind internal runners so inline,
  Oban-backed, bounded fallback, and replay execution all invoke the same
  adopter callback contract.
- **D-39-17:** Do not expose `before_process`, `after_process`, `around_process`,
  `handle_failed`, or queue/job-shaped callbacks in the Phase 39 public API.
- **D-39-18:** `{:bounce, reason}` is a first-class recorded outcome now, but
  richer bounce-delivery machinery remains a later-phase concern.

### Storage and evidence boundary
- **D-39-19:** `mailglass_inbound` should store one stable canonical inbound
  record plus one internal raw-evidence record in Postgres.
- **D-39-20:** Canonical persisted data is adopter-facing and provider-normalized.
  Evidence data is raw/debug/replay material and may remain provider-shaped.
- **D-39-21:** Attachment bytes, raw MIME, provider payload JSON, selected raw
  ingress headers, verification facts, and parse warnings belong in the evidence
  boundary, not on the canonical row and not on the stable public struct.
- **D-39-22:** Replay must never masquerade as a fresh receive. Replay is a new
  execution against stored evidence linked to the original inbound message.
- **D-39-23:** Keep the no-cross-package-FK posture. Package-local FK from
  inbound evidence to the package’s own canonical inbound record is acceptable;
  cross-package coupling to `mailglass` tables is not.
- **D-39-24:** The storage design should preserve append-only truth for evidence
  and replay history. Avoid mutable “latest truth only” semantics.
- **D-39-25:** Do not introduce behaviour-backed external raw storage or a full
  event-sourced projection model in Phase 39. Both expand support and mental
  burden beyond the narrow first inbound slice.

### Recommendation-first downstream posture
- **D-39-26:** Downstream research, planning, and implementation for this phase
  should default to decisive one-shot synthesis rather than repeated user
  interviewing.
- **D-39-27:** Escalate only when a choice is likely to materially change:
  - the stable public `mailglass_inbound` contract
  - tenant trust boundaries
  - replay/audit semantics
  - package-support burden in a meaningful way
  - a user-visible default workflow the project owner is especially likely to
    care about directly
- **D-39-28:** This recommendation-first posture should be shifted left in GSD
  workflows for Mailglass generally: research broadly, recommend one coherent
  set, and surface options only for truly high-impact contract or trust choices.

### the agent's Discretion
- Exact field names for normalized recipient/header/body/attachment fields, as
  long as the boundary between stable normalized data and evidence remains
  intact.
- Exact internal module names for the router engine, execution runner, replay
  runner, and persistence mappers.
- Exact canonical/evidence table names and whether evidence is one table or a
  small cluster of package-local tables.
- Exact docs and tests used to prove first-match routing, mailbox outcome
  semantics, and replay distinction.

</decisions>

<specifics>
## Specific Ideas

- The recommended shape should feel like the inbound analog to
  `Mailglass.Message`: one stable value object for adopters, with internal
  persistence and execution seams carrying the operational machinery.
- The best DX target is “Phoenix router + plain behaviour + explicit outcome
  tuples,” not “mini workflow engine.”
- The recommended replay model should feel like GitHub/Stripe-style redelivery:
  clearly linked to original evidence and never presented as a brand-new
  receive.
- Provider variability must be handled honestly. Postmark and SendGrid can
  differ on raw MIME and attachment fidelity, so the stable public contract
  should normalize what Mailglass can truly promise and keep the rest in raw
  evidence.
- Mailbox matching should stay conservative in Phase 39. Recipient, subject,
  and header matching are enough to prove the package contract without dragging
  in speculative body/content-routing complexity.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and project posture
- `.planning/ROADMAP.md` — Phase 39 goal, plan breakdown, and milestone scope.
- `.planning/PROJECT.md` — `v1.1` inbound-slice framing, maintainer posture,
  package boundary, and optional-Oban philosophy.
- `.planning/REQUIREMENTS.md` — `MODEL-01`, `ROUTE-01`, and `MAILBOX-01`
  requirement definitions plus adjacent storage/execution constraints.
- `.planning/STATE.md` — current milestone state and precondition posture.
- `.planning/METHODOLOGY.md` — decisive-by-default, honest-surface, and
  recommendation-first lenses.

### Existing contract and pattern anchors
- `docs/api_stability.md` — narrow stable-vs-internal contract discipline to
  mirror in `mailglass_inbound`.
- `README.md` — current sibling-package story and adopter-facing product
  language.
- `lib/mailglass/router.ex` — precedent for thin compile-time authoring macros
  with explicit validation.
- `lib/mailglass/webhook/provider.ex` — precedent for narrow, conn-free
  provider contracts with clear public/internal boundaries.
- `lib/mailglass/message.ex` — precedent for stable plain value-object contract
  instead of schema-shaped public API.
- `lib/mailglass/schema.ex` — current schema conventions for internal persisted
  records.
- `lib/mailglass/repo.ex` — current host-repo boundary and Postgres-owned
  persistence posture.
- `lib/mailglass/optional_deps.ex` — optional-dependency gating philosophy that
  inbound execution must preserve.

### Earlier inbound research and locked pitfalls
- `.planning/milestones/v0.1-research/FEATURES.md` — earlier inbound feature
  catalog, including router/mailbox/storage precedents worth narrowing.
- `.planning/milestones/v0.1-research/ARCHITECTURE.md` — earlier domain nouns
  and aggregate boundaries for `InboundMessage` and `Mailbox`.
- `.planning/milestones/v0.1-research/PITFALLS.md` — migration-ordering and
  no-cross-package-FK lessons that still apply to `mailglass_inbound`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.Message` already establishes the value-object pattern Mailglass
  prefers for stable adopter data contracts.
- `Mailglass.Router` already shows the house style for thin macros with strict
  compile-time validation and a narrow public option surface.
- `Mailglass.Webhook.Provider` already demonstrates the preferred contract
  posture for ingress boundaries: normalized narrow callbacks, no `%Plug.Conn{}`
  leakage, provider churn kept behind internal seams.
- `Mailglass.Schema` and `Mailglass.Repo` already define the internal
  persistence conventions a package-local inbound storage layer should reuse.
- `Mailglass.OptionalDeps.*` already defines how optional Oban support should
  remain honest and gated.

### Established Patterns
- Stable public value objects are kept separate from internal persistence and
  implementation machinery.
- Macros are used only when they materially improve compile-time validation or
  authoring ergonomics.
- Public contracts stay narrow and explicitly inventoried; reachability does not
  imply stability.
- Tenant scope is a first-class concern and should remain explicit on every
  inbound routing and persistence object.
- Operational truth is kept durable and auditable rather than flattened into
  mutable convenience state.

### Integration Points
- The inbound router should follow the authoring feel of existing Mailglass
  router seams while compiling to a pure matcher representation for replay and
  testing.
- Mailbox execution must remain compatible with later Oban-backed execution and
  bounded fallback execution without changing the adopter callback contract.
- Canonical inbound records and raw evidence records should live entirely inside
  `mailglass_inbound` and integrate with the host app only through the
  configured Repo boundary.
- Replay and later provider ingress plans should build on the Phase 39
  distinction between normalized message, raw evidence, and execution history.

</code_context>

<deferred>
## Deferred Ideas

- Arbitrary function predicates and custom matcher behaviours in the routing DSL.
- Body, attachment, provider, or raw-MIME routing matchers.
- Multi-match / fan-out routing.
- Mailbox lifecycle hooks beyond `process/1`.
- External object-storage behaviour for raw evidence.
- Full event-sourced inbound projection architecture.
- Conductor-style inbound dev UI.
- Mailgun, SES, and SMTP relay ingress.

</deferred>

---

*Phase: 39-inbound-package-foundation*
*Context gathered: 2026-05-06*
