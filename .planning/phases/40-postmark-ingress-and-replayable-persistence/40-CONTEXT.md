# Phase 40: Postmark Ingress and Replayable Persistence - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Accept authentic Postmark inbound webhook payloads, normalize them into the
canonical `MailglassInbound.InboundMessage` shape, persist one canonical row
plus one linked evidence row, and prove that the normalized message can be
handed into the routing contract without changing shape later.

This phase does not execute mailboxes yet, does not define async runner
semantics, does not broaden the public mailbox or router contract, and does not
pretend replay is the same thing as a fresh inbound receive.

</domain>

<decisions>
## Implementation Decisions

### Phase boundary and delivery shape
- **D-40-01:** Phase 40 stops at `verify -> normalize -> persist -> route
  compatibility`. It should not call `Mailbox.process/1` yet.
- **D-40-02:** First real mailbox execution should start in Phase 41, with
  async/Oban and bounded fallback semantics remaining Phase 42 work. Do not
  smuggle runner semantics into ingress storage work.
- **D-40-03:** The user-facing Phase 40 story must be honest: “Postmark ingress
  and replayable storage are real now; mailbox execution is next.” Do not
  market the provider slice as end-to-end processing before the execution phase
  lands.

### Ingress architecture
- **D-40-04:** Follow the existing Mailglass webhook house pattern:
  - adopter-facing mount/config seam outside
  - provider-specific verification/normalization inside
  - conn-free provider contract
  - verify before tenant resolution, persistence, or routing
- **D-40-05:** Keep the provider seam internal and sealed. The stable public
  contract is the inbound package’s adopter-facing ingress/routing surface, not
  a user-extensible provider behaviour in Phase 40.
- **D-40-06:** Reuse the existing raw-body capture and ingress-choke-point style
  already used in `mailglass` webhooks. Capture exact request bytes only on the
  inbound ingress path, not globally across unrelated routes.
- **D-40-07:** Align Postmark authentication with the current Mailglass
  webhook posture and Postmark guidance:
  - support HTTP Basic Auth as the default protection seam
  - keep IP allowlisting optional
  - fail closed on unverifiable requests

### Canonical normalization
- **D-40-08:** Normalize Postmark inbound data only into the already-locked
  `%MailglassInbound.InboundMessage{}` fields. Do not widen the public struct
  for Postmark-only quirks.
- **D-40-09:** Map Postmark’s `MessageID` into `provider_message_id`, and map
  the RFC `Message-Id` header into `message_id` when present. Keep those two
  identifiers distinct.
- **D-40-10:** Map Postmark’s `OriginalRecipient` into the canonical
  `envelope_recipient` field. Do not route only on visible `To` headers when
  the provider gives the actual RCPT target.
- **D-40-11:** Normalize sender and recipient fields from Postmark’s structured
  contact data, not from legacy string fields when the richer shape is already
  available.
- **D-40-12:** Preserve honest provider limitations in the normalized shape:
  - BCC may be absent or partial by provider design
  - stripped-reply/body helpers are provider conveniences, not universal truth
  - attachment bytes are evidence, not canonical attachment metadata

### Persistence and replay semantics
- **D-40-13:** Persist one canonical inbound row plus one linked evidence row in
  one package-local transaction using `Ecto.Multi`-style semantics. The durable
  truth boundary is:
  - canonical adopter-facing normalized row
  - raw provider evidence row
- **D-40-14:** Treat Postmark retries and manual replays as ingress idempotency
  concerns, not as new fresh receives. The recommended dedupe anchor is
  `(tenant_id, provider, provider_message_id)` for Postmark-backed rows.
- **D-40-15:** The evidence row should preserve:
  - raw webhook JSON payload
  - selected raw request headers
  - verification facts
  - parse warnings
  - attachment blobs when the provider payload includes them
- **D-40-16:** `raw_mime` may remain `nil` for Postmark in Phase 40 if the
  provider webhook does not deliver a trustworthy raw-message artifact directly.
  Do not fake raw MIME by reconstructing it from parsed fields.
- **D-40-17:** Do not write `ReplayRun` rows during fresh ingress. Replay
  lineage rows remain execution-history artifacts for actual replay work, not
  receive-time storage.
- **D-40-18:** Replay must stay clearly separate from fresh receive semantics:
  a later replay reuses stored evidence linked to the original inbound record;
  it is not inserted as a brand-new inbound message.

### Routing compatibility and DX
- **D-40-19:** Phase 40 should prove route compatibility against the normalized
  message shape, but that proof should stay narrow:
  - matcher can evaluate the normalized message
  - no-match is explicit and non-exceptional
  - matched mailbox identity may be surfaced internally
  - mailbox execution does not happen yet
- **D-40-20:** Do not broaden the router or mailbox contracts as a side effect
  of Postmark ingress work. Body matching, attachment matching, fan-out, hooks,
  and runner options remain deferred exactly as Phase 39 declared.
- **D-40-21:** The public DX should feel idiomatic for Phoenix/Plug/Ecto:
  - one obvious mount/config path
  - one stable normalized value object
  - one durable transaction boundary
  - explicit success/rejection/duplicate outcomes
  Avoid callback soup, hidden global state, or implicit provider magic.

### Lessons from adjacent ecosystems
- **D-40-22:** Borrow from Rails Action Mailbox what it got right:
  - durable inbound records before app-specific processing
  - explicit routing/mailbox separation
  - debugging/forensics value of retained inbound evidence
  Do not copy its heavier built-in lifecycle/retention machinery into this
  phase.
- **D-40-23:** Borrow from Anymail what it got right:
  - normalize one common inbound message surface
  - keep provider specifics accessible but outside the core normalized shape
  - design for webhook retries and duplicate delivery attempts up front
- **D-40-24:** Learn from the footguns those ecosystems expose:
  - too much hidden processing behind signals/jobs obscures idempotency
  - too much built-in workflow surface increases support burden
  - “reachable” provider internals quickly get treated as public API if the
    docs are not explicit and tests do not enforce the boundary

### Recommendation-first workflow posture
- **D-40-25:** For inbound-provider work, downstream research and planning
  should default to one cohesive recommendation set and escalate only when a
  choice would materially change:
  - the stable public contract
  - tenant/security trust boundaries
  - replay/audit truth semantics
  - irreversible retention/security posture
  - major long-term maintainer burden

### the agent's Discretion
- Exact internal module names for inbound ingress plug/router/provider seams.
- Exact unique index and conflict-handling shape used to make Postmark ingress
  idempotent.
- Exact normalized field mapping helpers and parse-warning representation.
- Exact return shape for internal route-compatibility proof, as long as it does
  not imply mailbox execution has already started.

</decisions>

<specifics>
## Specific Ideas

- The best mental model is: “inbound equivalent of the webhook ingest seam,”
  not “mini workflow engine.”
- The recommended sequence is:
  - exact raw body capture
  - Postmark auth verification
  - tenant resolution
  - pure normalization into `%InboundMessage{}`
  - one transaction for canonical row + evidence row
  - narrow route-match proof
- Postmark docs indicate inbound webhook retries on non-`200` responses, waits
  up to two minutes for a response, and allows manual retry of failed inbound
  messages. That makes ingress idempotency a first-order design concern, not a
  cleanup task.
- Postmark’s `OriginalRecipient` and `MessageID` are the most valuable provider
  facts for routing and idempotent persistence. Preserve them directly.
- Keep future operator/replay UI possibilities open by storing honest evidence
  now, but do not front-run that future UI in this phase’s public API.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked posture
- `.planning/ROADMAP.md` — Phase 40/41/42 split and milestone sequencing.
- `.planning/PROJECT.md` — narrow first-inbound-slice posture and one-maintainer
  honesty constraints.
- `.planning/REQUIREMENTS.md` — `INGRESS-01` and `STORE-01` boundaries.
- `.planning/STATE.md` — current milestone position.
- `.planning/METHODOLOGY.md` — recommendation-first and honest-surface posture.
- `.planning/phases/39-inbound-package-foundation/39-CONTEXT.md` — locked
  inbound contract and replay boundary inherited by this phase.

### Existing local code and pattern anchors
- `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex` — stable
  normalized inbound contract.
- `mailglass_inbound/lib/mailglass_inbound/router.ex` — router DSL and matcher
  boundary that Phase 40 must not widen.
- `mailglass_inbound/lib/mailglass_inbound/mailbox.ex` — mailbox contract that
  Phase 40 must not execute yet.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex` — package-local
  persistence boundary.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex` —
  canonical row shape.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex`
  — raw evidence row shape.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/replay_run.ex` —
  replay execution lineage shape that must stay distinct from fresh receive.
- `mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs`
  — storage foundation and current indexes/FKs.
- `mailglass_inbound/docs/api_stability.md` — stable/internal/deferred
  inventory for the sibling package.

### Existing Mailglass ingress patterns
- `lib/mailglass/webhook/provider.ex` — narrow internal provider seam precedent.
- `lib/mailglass/webhook/plug.ex` — verify-first ingress orchestration, tenant
  ordering, and error semantics.
- `lib/mailglass/webhook/ingest.ex` — one-transaction ingest pattern and
  idempotent replay posture.
- `lib/mailglass/webhook/providers/postmark.ex` — current Postmark auth posture
  and provider-specific normalization style.
- `lib/mailglass/webhook/caching_body_reader.ex` — raw-body capture pattern.

### Official ecosystem references
- `https://postmarkapp.com/developer/webhooks/inbound-webhook` — inbound JSON
  webhook contract and field shape.
- `https://postmarkapp.com/developer/user-guide/inbound/parse-an-email` —
  inbound field semantics, retry behavior, and `MailboxHash`/reply parsing.
- `https://postmarkapp.com/developer/api/messages-api` — inbound message
  details, `OriginalRecipient`, `MessageID`, and manual retry endpoint context.
- `https://postmarkapp.com/manual` — Postmark guidance to protect inbound
  webhooks with HTTP Basic Auth.
- `https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark`
  — retry schedule and manual retry posture.
- `https://guides.rubyonrails.org/action_mailbox_basics.html` — durable inbound
  record plus routing/mailbox separation precedent.
- `https://anymail.dev/en/v8.2/inbound/` — normalized inbound handling and
  duplicate/retry-aware processing precedent.
- `https://hexdocs.pm/plug/Plug.Parsers.html` — `:body_reader` raw-body access
  idiom for Plug/Phoenix.
- `https://hexdocs.pm/ecto/Ecto.Multi.html` — idiomatic single-transaction
  composition for ingress persistence.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.Webhook.CachingBodyReader` already demonstrates the exact raw-body
  capture pattern Phase 40 should reuse.
- `Mailglass.Webhook.Plug` already demonstrates the right verify-first ordering,
  provider dispatch, and explicit response-mapping discipline.
- `MailglassInbound.InboundRecords.*` already gives the canonical/evidence/replay
  split this phase should build on instead of redesigning storage.
- `MailglassInbound.Router.Matcher` already provides the narrow route
  compatibility seam Phase 40 should prove without executing mailboxes.

### Established Patterns
- Public contracts are narrow and explicitly inventoried; reachability does not
  imply stability.
- Provider-specific logic lives behind package-local seams; adopter-facing
  surfaces stay smaller than implementation reachability.
- Optional/runtime variability is gated through explicit seam modules, not
  scattered `Code.ensure_loaded?` checks.
- Durable truth is written transactionally first; later runtime side effects are
  layered on top rather than mixed into parsing code.

### Integration Points
- The new Postmark inbound seam should feel like the inbound sibling of the
  existing webhook provider/plug pipeline.
- Canonical and evidence writes should stay package-local through
  `MailglassInbound.Repo`, not cross-couple to `mailglass` tables.
- Route-compatibility proof should compose directly with the existing router
  matcher and become the handoff point for Phase 41 execution work.

</code_context>

<deferred>
## Deferred Ideas

- Live mailbox execution on fresh ingress.
- Async runner selection, Oban integration, and bounded non-Oban fallback.
- Replay execution commands and operator/UI surfaces.
- Broadening the public router/matcher contract beyond recipient, subject, and
  headers.
- Raw MIME reconstruction or provider round-trips that pretend to provide a
  trustworthy raw message artifact when Postmark did not send one directly.

</deferred>

---

*Phase: 40-postmark-ingress-and-replayable-persistence*
*Context gathered: 2026-05-06*
