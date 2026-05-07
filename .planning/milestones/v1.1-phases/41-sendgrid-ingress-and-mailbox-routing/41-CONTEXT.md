# Phase 41: SendGrid Ingress And Mailbox Routing - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend `mailglass_inbound` to a second real provider shape and move the
package from route-compatibility proof into real mailbox execution.

This phase should:
- accept SendGrid inbound mail through a first-party ingress seam
- normalize it into the already-locked `%MailglassInbound.InboundMessage{}`
  contract without widening that contract for provider quirks
- persist canonical plus evidence truth with provider-appropriate duplicate
  protection
- route matched messages into real mailbox execution
- record append-only execution lineage for fresh processing and replay

This phase does not add Oban-backed async execution, bounded fallback
semantics, synthetic/replay UI, signed multipart SendGrid ingress, or broad
matcher expansion. Those remain later work.

</domain>

<decisions>
## Implementation Decisions

### SendGrid ingress security and DX
- **D-41-01:** Phase 41 should ship SendGrid inbound as a strict
  shared-secret/basic-auth ingress, not signed SendGrid Parse security
  policies.
- **D-41-02:** The reason is architectural and DX-driven, not accidental:
  SendGrid inbound arrives as `multipart/form-data`, and `Plug.Parsers`
  multipart parsing does not use the `:body_reader` raw-body seam already used
  for Postmark. Pretending the Postmark raw-body verify-first pattern carries
  over to signed SendGrid multipart ingress would be dishonest.
- **D-41-03:** Keep the adopter-facing ingress story narrow and obvious:
  one stable SendGrid mount/config path, one documented shared-secret/basic-auth
  setup, and no mode matrix for signed-vs-basic-vs-OAuth ingress in this phase.
- **D-41-04:** Signed multipart SendGrid verification is a valid future
  enhancement only if the project is willing to own a dedicated raw-body-first
  multipart ingress seam with its own parsing, testing, and support surface.
  It is explicitly not the Phase 41 recommendation.

### SendGrid normalization and stable contract discipline
- **D-41-05:** `%MailglassInbound.InboundMessage{}` must remain unchanged for
  SendGrid. Do not widen the stable adopter-facing struct for provider-only
  fields.
- **D-41-06:** Phase 41 should require SendGrid’s raw MIME delivery path. If
  the `email` part is absent, the ingress should reject with an explicit
  configuration/help error instead of silently degrading into best-effort
  parsing.
- **D-41-07:** Normalize SendGrid primarily from raw MIME plus the provider
  envelope metadata, not from ad hoc multipart convenience fields when the raw
  message is the more honest source of truth.
- **D-41-08:** For SendGrid:
  - `provider` should be `:sendgrid`
  - `provider_message_id` should remain `nil`
  - RFC `Message-ID` should map only to `message_id`
  - `envelope_recipient` should come from the provider envelope recipient, not
    guessed solely from visible headers
- **D-41-09:** Keep SendGrid-only facts in evidence, not in the stable struct:
  spam verdict fields, SPF/DKIM/provider auth details, multipart field names,
  attachment bytes, raw MIME, raw multipart payloads, and provider-only parse
  helpers all stay in the evidence boundary.

### Provider-specific duplicate protection
- **D-41-10:** Phase 41 should stop assuming `provider_message_id` is the only
  ingress idempotency anchor across providers.
- **D-41-11:** Postmark should keep its current `(tenant_id, provider,
  provider_message_id)` duplicate-collapse semantics.
- **D-41-12:** SendGrid duplicate protection should be provider-specific and
  internal. The recommended anchor is a deterministic fingerprint of the raw
  MIME, scoped by `(tenant_id, provider)`, rather than overloading RFC
  `Message-ID` into `provider_message_id`.
- **D-41-13:** Duplicate ingress remains an ingress-truth concern, not a
  mailbox-processing concern. A duplicate fresh receive must not silently
  trigger a second mailbox execution attempt.

### Mailbox execution timing and recording
- **D-41-14:** Phase 41 should execute mailboxes inline only after successful
  persistence commit.
- **D-41-15:** Do not execute `Mailbox.process/1` inside the same database
  transaction as canonical/evidence persistence. Mailbox processing is a
  post-commit side-effect boundary, and keeping it outside the transaction is
  more idiomatic for Elixir/Ecto and more coherent with existing Mailglass
  outbound/webhook patterns.
- **D-41-16:** The fresh-ingress sequence should be:
  - verify
  - normalize
  - persist canonical row + evidence row
  - route
  - execute matched mailbox inline
  - append execution lineage row
- **D-41-17:** `:no_match` is a first-class recorded result and must stay
  distinct from `:ignore`. `:ignore` means a matched mailbox chose not to act;
  `:no_match` means routing never selected a mailbox.
- **D-41-18:** Raised exceptions, exits, throws, invalid return shapes, and
  future timeout/cancellation cases are execution failures, not mailbox
  outcomes. Preserve the existing stable mailbox outcome contract:
  - `:accept`
  - `:ignore`
  - `{:reject, reason}`
  - `{:bounce, reason}`
- **D-41-19:** Once persistence succeeded, the ingress response should still
  acknowledge the request with `200` even when mailbox execution records
  `:reject`, `:bounce`, `:ignore`, `:no_match`, or `:failed`. Provider retry
  behavior must not become the mailbox retry mechanism.

### Execution lineage and replay truth
- **D-41-20:** Phase 41 should generalize the current replay-only lineage model
  into one append-only execution lineage model shared by fresh processing and
  replay.
- **D-41-21:** Each execution attempt should point back to the immutable
  canonical inbound row and immutable evidence row, and record at least:
  - execution source (`:fresh` or `:replay`)
  - mailbox identity
  - execution outcome (`:no_match`, `:accept`, `:ignore`, `:reject`,
    `:bounce`, or `:failed`)
  - outcome reason when applicable
  - failure metadata when applicable
  - executed timestamp
  - small internal metadata facts only
- **D-41-22:** Do not mutate the canonical inbound row with “latest mailbox
  status,” “latest replay,” or other execution convenience state. Canonical
  receive truth and append-only execution truth remain separate.
- **D-41-23:** Replay remains “run mailbox processing again against already
  stored inbound truth,” not “re-ingest” and not “pretend this was freshly
  received again.”
- **D-41-24:** Default replay should run the originally matched mailbox, not
  re-evaluate the current router. If the project later wants “what would
  today’s routing do?”, that must be a separately named operation such as
  reroute preview or reparse+rereoute, not the meaning of replay.
- **D-41-25:** Replay should reuse the stored canonical record and stored
  evidence row as truth inputs. Do not re-normalize the provider payload by
  default during replay, because parser changes would silently rewrite history.

### Downstream posture
- **D-41-26:** Downstream research, planning, and execution for this phase
  should continue the decisive-by-default posture: use the cohesive
  recommendation set here as the default implementation target, and only
  escalate if a choice would materially change the stable public contract,
  trust/security semantics, or long-term maintainer burden beyond what is
  already locked here.

### the agent's Discretion
- Exact internal module names for the SendGrid ingress seam, MIME parser, and
  execution runner.
- Exact schema/module naming for the generalized execution lineage table, as
  long as fresh execution and replay share one coherent append-only truth
  model.
- Exact fingerprinting implementation used for SendGrid duplicate protection.
- Exact error structs, response payload fields, and parse-warning representation
  as long as the stable contract and truth boundaries above remain intact.

</decisions>

<specifics>
## Specific Ideas

- The right DX target is “one honest SendGrid path that works naturally in a
  Phoenix app,” not “support every SendGrid security mode in v1 of inbound.”
- The best mental model is:
  - Postmark proves JSON verify-first ingress
  - SendGrid proves multipart/raw-MIME provider variability
  - mailbox execution remains one narrow callback regardless of provider
- The execution story should feel like existing Mailglass delivery/webhook
  architecture: durable truth first, then a clear side-effect boundary, then
  append-only outcome recording.
- Replay should feel closer to Stripe/GitHub-style redelivery history than to
  “simulate a brand-new receive.” Operator trust matters more than speculative
  smartness here.
- Requiring raw MIME is a feature, not a burden. It preserves attachment/body
  fidelity and keeps the normalized contract honest.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked posture
- `.planning/ROADMAP.md` — Phase 41 goal and plan split, plus Phase 42 boundary
  that keeps async/fallback work out of this phase.
- `.planning/PROJECT.md` — current `v1.1` inbound-slice posture, maintainer
  budget, and package-honesty constraints.
- `.planning/REQUIREMENTS.md` — `INGRESS-02` and `STORE-02` boundaries plus the
  adjacent execution/adoption requirements.
- `.planning/STATE.md` — current milestone position after Phase 40.
- `.planning/METHODOLOGY.md` — decisive-by-default, honest-surface, and
  recommendation-first lenses.
- `.planning/phases/39-inbound-package-foundation/39-CONTEXT.md` — locked
  inbound public contract, storage boundary, mailbox contract, and replay
  semantics.
- `.planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md`
  — locked Postmark ingress, route-compatibility, and replayable-storage
  decisions this phase builds on.

### Existing local code and pattern anchors
- `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex` — stable
  normalized inbound contract that SendGrid must not widen.
- `mailglass_inbound/lib/mailglass_inbound/mailbox.ex` — stable mailbox
  callback and locked outcome contract.
- `mailglass_inbound/lib/mailglass_inbound/router.ex` — router authoring seam
  and first-match posture.
- `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex` — current
  route-match semantics and explicit `:no_match` behavior.
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` — current ingress
  orchestration and Postmark-first verify/normalize/persist flow to extend.
- `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex` — current
  provider-seam contract and likely extension point.
- `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` — current
  canonical/evidence persistence boundary, duplicate handling, and route proof.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex` — current
  replay-lineage normalization boundary to generalize into shared execution
  lineage.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex`
  — canonical stored truth and current Postmark-specific unique constraint.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex`
  — evidence boundary for provider-shaped payloads, raw MIME, and attachment
  blobs.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/replay_run.ex` —
  current replay lineage model to evolve into a broader execution truth model.
- `mailglass_inbound/docs/api_stability.md` — stable/internal/deferred surface
  inventory that Phase 41 must update honestly.
- `mailglass_inbound/docs/postmark_ingress.md` — current ingress docs and the
  exact Phase 40 user story Phase 41 extends.
- `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` — existing
  ingress orchestration proof shape.
- `mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs` —
  duplicate handling and route-proof expectations.
- `mailglass_inbound/test/mailglass_inbound/mailbox_test.exs` — locked mailbox
  outcome semantics.
- `mailglass_inbound/test/mailglass_inbound/replay_test.exs` — replay-lineage
  and append-only truth expectations already proven.

### Existing Mailglass precedents
- `lib/mailglass/outbound.ex` — side effects stay outside transaction boundary.
- `lib/mailglass/webhook/ingest.ex` — durable ingest truth first, then
  downstream behavior on top.
- `lib/mailglass/webhook/caching_body_reader.ex` — raw-body capture precedent
  and the reason multipart SendGrid does not automatically fit the Postmark
  pattern.
- `lib/mailglass/webhook/providers/sendgrid.ex` — current SendGrid ECDSA
  verification style and provider-specific cautionary precedent.

### Official and ecosystem references
- `https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/setting-up-the-inbound-parse-webhook`
  — SendGrid Inbound Parse setup and raw-MIME configuration expectations.
- `https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/securing-your-parse-webhooks`
  — SendGrid Parse security modes and the complexity of signed multipart
  verification.
- `https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/inbound-email`
  — SendGrid inbound overview and provider behavior context.
- `https://hexdocs.pm/plug/Plug.Parsers.html` — `Plug.Parsers` behavior,
  including multipart parser caveats and `:body_reader` limitations.
- `https://hexdocs.pm/plug/Plug.Conn.html` — lower-level multipart part-reading
  APIs if the signed-multipart path is pursued later.
- `https://hexdocs.pm/ecto/Ecto.Multi.html` — transaction-composition posture
  for canonical/evidence writes.
- `https://hexdocs.pm/oban/Oban.Worker.html` — future Phase 42 async execution
  posture and failure-vs-outcome mental model.
- `https://guides.rubyonrails.org/action_mailbox_basics.html` — durable inbound
  storage, SendGrid raw-MIME precedent, and routing/mailbox separation.
- `https://anymail.dev/en/stable/inbound/` — normalized inbound contract and
  duplicate/retry-aware processing lessons.
- `https://anymail.dev/en/v14.0/esps/sendgrid/` — SendGrid-specific raw-MIME
  and provider-shape lessons relevant to DX and contract honesty.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MailglassInbound.Ingress.Plug` already owns the verify -> tenant ->
  normalize -> persist orchestration seam and should remain the single obvious
  first-party ingress entrypoint.
- `MailglassInbound.Ingress.Persist` already owns canonical/evidence truth
  boundaries and is the right place to evolve provider-specific duplicate logic.
- `MailglassInbound.Router` and `MailglassInbound.Router.Matcher` already prove
  the route contract and should feed directly into real execution rather than
  being replaced.
- `MailglassInbound.InboundRecords` and `ReplayRun` already contain the right
  outcome-vs-failure normalization logic to generalize into shared execution
  lineage.
- Existing outbound/webhook code already establishes the house rule that
  side-effect work belongs after durable writes, not inside transaction bodies.

### Established Patterns
- Stable adopter contracts are plain value objects or narrow behaviors, not
  schema-shaped public APIs.
- Provider quirks stay behind internal seams and evidence boundaries unless they
  normalize honestly across providers.
- Durable truth is append-only and auditable; convenience “latest state”
  mutations are avoided when they would blur support forensics.
- Optional heavier execution machinery belongs behind internal seams so later
  async work can reuse the same contract.

### Integration Points
- SendGrid ingress should plug into the same package-level ingress surface as
  Postmark while using provider-specific verification and normalization inside.
- Fresh mailbox execution should consume the same `%InboundMessage{}` and router
  data already proven by current tests.
- Shared execution lineage should integrate with existing replay lineage
  assumptions so Phase 42 can swap callers without rewriting truth semantics.

</code_context>

<deferred>
## Deferred Ideas

- Signed SendGrid multipart ingress with raw-body-first manual multipart
  parsing.
- OAuth-backed SendGrid Parse authentication modes.
- Reparse+rereoute or “what would current router do?” operator tooling.
- Oban-backed async execution and bounded non-Oban fallback semantics.
- Conductor-style synthetic inbound UI or replay controls.
- Matcher expansion beyond recipient, subject, and headers.

</deferred>

---

*Phase: 41-sendgrid-ingress-and-mailbox-routing*
*Context gathered: 2026-05-06*
