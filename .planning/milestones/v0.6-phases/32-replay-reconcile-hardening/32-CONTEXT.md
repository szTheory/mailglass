# Phase 32: Replay & Reconcile Hardening - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Harden operator-facing replay and reconciliation behavior so replay/reconcile workflows remain tenant-safe, authorization-safe, auditable, and low-surprise under production support conditions.

This phase is about tightening the existing repair paths and the operator contract around them. It is not a bulk incident-recovery console, not a general backfill product, not a new cross-tenant maintenance UI, and not a library-owned authentication product.

</domain>

<decisions>
## Implementation Decisions

### Recent authorization policy
- **D-32-01:** Keep recent-auth enforcement adopter-owned and action-time enforced through the existing `MailglassAdmin.Auth.authorize/2` `:destructive_action` seam. Do not move freshness enforcement to mount time, modal-open time, or router-only checks.
- **D-32-02:** Replay and any new manual repair action introduced in this phase must follow one server-side sequence: resolve the exact tenant-safe target, call `:destructive_action` authorization with full context, then execute the command.
- **D-32-03:** Do not introduce new public action atoms such as `:replay_webhook` or `:reconcile_delivery` in Phase 32. The current seam is sufficient and keeps the public auth contract small.
- **D-32-04:** Document a 15-minute recent-auth example window for adopters, but keep the actual threshold adopter-configurable through their auth implementation.
- **D-32-05:** Auth-denied or stale-auth attempts should fail before replay/reconcile work begins. Do not emit replay requested/failed audit rows for authorization denials unless a later phase intentionally introduces a separate denied-attempt audit semantic.

### Reconcile surface and operator entrypoints
- **D-32-06:** Keep replay as the only operator-facing manual repair action in the current delivery-detail UI.
- **D-32-07:** Do not add a per-delivery `Reconcile` CTA beside `Replay webhook` in Phase 32. Current reconciliation semantics are orphan-scan based, not exact selected-delivery based, and a delivery-level button would imply false precision.
- **D-32-08:** Reconciliation remains background-first and maintenance-oriented in this phase: Oban cron where available, with a CLI/maintenance fallback.
- **D-32-09:** If a future manual reconcile action becomes necessary, it should live in a separate tenant-scoped maintenance surface, not in the current delivery header and not with a global/nil-tenant default.
- **D-32-10:** Phase 32 should harden and clarify the existing manual reconcile fallback surface rather than broaden it into a new operator workflow product.

### Ambiguity and exact-target handling
- **D-32-11:** Never guess across multiple replayable raw webhook rows. Ambiguity is a precondition state, not a failure state.
- **D-32-12:** Keep the operator-visible availability model separate from command outcomes:
  - `:ready`
  - `:choice_required`
  - `:unavailable`
- **D-32-13:** Replay remains exact-target only. A delivery can be a convenience entrypoint, but execution still requires one concrete webhook identity.
- **D-32-14:** Reconcile must not gain pseudo-exact delivery semantics unless a later phase introduces a true delivery-to-orphan target identity with clear tenant-safe guarantees.
- **D-32-15:** Reason-specific unavailable states should stay explicit and low-claiming, for example historical linkage gaps, multiple candidates, or no linked webhook events yet.

### Operator outcome language and audit semantics
- **D-32-16:** Standardize operator-facing repair language around two layers:
  - availability: `ready`, `choice required`, `unavailable`
  - action outcome: `requested`, `completed`, `failed`
- **D-32-17:** Completed repair actions must separately express material effect:
  - replay: `new work` or `no change`
  - reconcile: `linked` or `still unmatched`
- **D-32-18:** Prefer `completed` over `succeeded` in operator copy. `Succeeded` overclaims when replay is a no-op.
- **D-32-19:** Operator copy must describe what mailglass observed, not what the operator hoped happened. Avoid verbs like `fixed`, `restored`, or `reprocessed successfully` when the durable result could be a no-op.
- **D-32-20:** Raw ledger event atoms such as `:webhook_replay_succeeded` remain internal audit facts. The UI should render stable presenter-level wording rather than exposing those atoms directly.
- **D-32-21:** Replay/reconcile audit events must remain visually distinct from provider lifecycle events in timelines and summaries.

### Recommendation-first project posture for this phase
- **D-32-22:** Downstream agents should research broadly, synthesize one cohesive recommendation set, and avoid escalating routine tradeoffs back to the user.
- **D-32-23:** Escalate only when a decision would materially change:
  - public auth/router/session contract
  - tenant trust boundaries
  - replay/reconcile audit retention semantics
  - operator-visible safety semantics in a surprising way
  - long-term maintainer burden through new repair modes or new maintenance surfaces
- **D-32-24:** This recommendation-first posture should be applied earlier, not later, in Phase 32 research and planning. Default to coherent recommendations unless the choice is genuinely high-impact.

### the agent's Discretion
- Exact internal presenter module names for repair-state copy and mapping.
- Exact wording for availability and effect labels, as long as the semantics above remain intact.
- Exact helper/facade placement for the shared destructive-action authorization sequence.
- Exact docs/test locations used to clarify the reconcile fallback path and stale-auth expectations.

</decisions>

<specifics>
## Specific Ideas

- Replay and reconcile should feel like one safety model even though they are different mechanics:
  - exact target resolution when applicable
  - action-time authorization
  - durable audit evidence
  - low-claim operator wording
  - clear separation between “you may act,” “the action completed,” and “something materially changed”
- The operator contract should read more like GitHub/Stripe/Shopify repair tooling:
  - explicit delivery history
  - exact redelivery when possible
  - separate reconciliation/backfill concepts
  - no guessing across ambiguous targets
- The user preference for this phase is explicit:
  - research deeply
  - recommend decisively
  - escalate only for truly high-impact contract choices

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and current project posture
- `.planning/ROADMAP.md` — Phase 32 goal, success criteria, and milestone position.
- `.planning/PROJECT.md` — v0.6 production-maturity framing, operator-trust posture, and maintainer constraints.
- `.planning/REQUIREMENTS.md` — `MAT-01` requirement definition.
- `.planning/STATE.md` — current milestone state.
- `.planning/METHODOLOGY.md` — decisive-by-default and recommendation-first project lenses.

### Prior locked replay/operator decisions
- `.planning/milestones/v0.4-phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md` — exact replay target semantics, tenant-safe replay rules, and replay audit posture.
- `.planning/milestones/v0.4-phases/26-runtime-per-tenant-adapter-resolution/26-CONTEXT.md` — strong recent precedent for recommendation-first synthesis and escalate-only-on-high-impact choices.

### Existing implementation seams
- `mailglass_admin/lib/mailglass_admin/auth.ex` — canonical auth/actor normalization seam.
- `mailglass_admin/lib/mailglass_admin/operator/mount.ex` — mount-time operator access authorization.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — current action-time replay authorization and operator UX flow.
- `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` — current replay affordance and summary wording.
- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` — current ambiguity/exact-target replay UX.
- `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` — current operator timeline copy and replay audit presentation.
- `lib/mailglass/webhook/replay.ex` — canonical tenant-scoped replay command and current outcome model.
- `lib/mailglass/operator/replay_targets.ex` — replay target resolution and ambiguity states.
- `lib/mailglass/operator/replay_history.ex` — durable replay-history read model.
- `lib/mailglass/operator/timeline.ex` — delivery event timeline read model.
- `lib/mailglass/webhook/reconciler.ex` — current background reconciliation flow and semantics.
- `lib/mailglass/events/reconciler.ex` — orphan discovery/linking behavior used by reconciliation.
- `lib/mix/tasks/mailglass.reconcile.ex` — manual reconcile entrypoint and current fallback contract.
- `guides/webhook-troubleshooting.md` — current operator-facing replay/reconcile troubleshooting story.

### Relevant tests and behavioral locks
- `test/mailglass/webhook/replay_test.exs` — replay result semantics, audit writes, tenant mismatch behavior.
- `test/mailglass/webhook/reconciler_test.exs` — append-only reconcile behavior and no orphan-row mutation.
- `test/mailglass/operator/timeline_test.exs` — replay audit timeline behavior.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — operator replay UX and stale-auth behavior.
- `mailglass_admin/test/support/endpoint_case.ex` — example adopter-owned recent-auth window and `:stale_auth` behavior.

### External precedents and ecosystem priors
- `https://hexdocs.pm/phoenix_live_view/security-model.html` — LiveView requires security checks at mount and again in `handle_event`; supports action-time enforcement posture.
- `https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/sudo-mode` — recent-auth model for sensitive actions.
- `https://docs.github.com/en/rest/repos/webhooks` — exact webhook delivery inspection and redelivery model.
- `https://docs.stripe.com/webhooks/process-undelivered-events?locale=en-GB` — manual processing of undelivered events, idempotency expectations, and retry coexistence.
- `https://shopify.dev/docs/apps/build/webhooks/best-practices` — reconciliation jobs as a complement to webhook delivery.
- `https://shopify.dev/docs/apps/build/webhooks/troubleshooting-webhooks` — delivery metrics, retry limits, and delayed processing guidance.
- `https://hexdocs.pm/oban/unique_jobs.html` — uniqueness vs concurrency semantics for any queued repair work.
- `https://docs.adyen.com/development-resources/webhooks/troubleshoot/` — explicit failed-delivery troubleshooting and manual retry posture.
- `https://docs.aws.amazon.com/sns/latest/dg/sns-message-delivery-retries.html` — retry-policy and permanent-failure boundaries for HTTP webhook delivery.
- `https://anymail.dev/en/stable/sending/tracking/` — normalized sent-mail tracking identity and event-processing posture in a mature library.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MailglassAdmin.Auth` already gives Phase 32 one clean action-time authorization seam for replay and any future destructive operator actions.
- `Mailglass.Webhook.Replay` already models the exact-target command and the replay/no-op distinction the UI should preserve.
- `Mailglass.Operator.ReplayTargets` already distinguishes exact, ambiguous, and unavailable replayability states.
- `Mailglass.Operator.ReplayHistory` already provides durable repair-history reads separate from flashes.
- `Mailglass.Webhook.Reconciler` and `Mix.Tasks.Mailglass.Reconcile` already define the maintenance-oriented reconcile path that should be clarified rather than reinvented.

### Established Patterns
- Operator access is authorized at mount, but destructive work is re-authorized at action time.
- Tenant safety is enforced before target lookup and command execution.
- Append-only ledger facts are the durable truth; projections and mutable tables are secondary.
- The project prefers narrow honest surfaces over premature control consoles.
- Recommendation-first synthesis is already an explicit methodology lens and should be applied strongly here.

### Integration Points
- Phase 32 should introduce one shared helper/presenter layer for repair-state wording rather than sprinkling raw outcome atoms through multiple UI components.
- Replay UX, replay history, and future reconcile summaries should converge on one repair-state vocabulary.
- The manual reconcile fallback path needs consistency work so runtime warnings, task behavior, and docs tell the same story.
- Tests should lock the difference between:
  - auth denial vs repair failure
  - ambiguity vs unavailable
  - completed with new work vs completed with no change

</code_context>

<deferred>
## Deferred Ideas

- A tenant-scoped maintenance UI for manual reconciliation or orphan sweeps.
- Global or cross-tenant human-triggered reconcile surfaces.
- New public auth action atoms for each operator repair action.
- Bulk replay, time-window replay, or generalized backfill/rebuild workflows.
- Library-owned reauthentication UI/redirect flows.

</deferred>

---

*Phase: 32-replay-reconcile-hardening*
*Context gathered: 2026-05-05*
