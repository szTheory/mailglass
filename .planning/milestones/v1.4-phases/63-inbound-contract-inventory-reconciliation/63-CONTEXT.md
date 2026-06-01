# Phase 63: Inbound Contract Inventory Reconciliation - Context

**Gathered:** 2026-05-31 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Reconcile `mailglass_inbound/docs/api_stability.md` against shipped behavior so adopters can tell stable semantics from reachable implementation details.

This phase is a contract-inventory phase only. It covers LOCK-01, LOCK-02, and LOCK-03 by clarifying stable runtime, testing, operator, telemetry, and error-contract seams; internal implementation support; and explicitly deferred inbound capabilities. It must not add matcher expansion, lifecycle callbacks, public replay API, provider extension API, worker/queue contract, synthetic inbound dev UI, ecosystem integrations, or `gen_smtp` listener work.
</domain>

<decisions>
## Implementation Decisions

### Contract Taxonomy Alignment
- **D-01:** Keep `mailglass_inbound/docs/api_stability.md` aligned with the core/admin semantics-first taxonomy: stability is defined by the explicit inventory, not by ExDoc visibility, module reachability, source comments, or tests that mention an internal module.
- **D-02:** Preserve the distinct inbound buckets needed for this milestone: `stable` runtime seams, `testing` helper seams, `internal` implementation support, and `deferred` capabilities.

### Provider Surface Posture
- **D-03:** Document existing provider support through `MailglassInbound.Ingress.Plug` behavior/options and request semantics, not as public provider module APIs.
- **D-04:** Keep `MailglassInbound.Ingress.Provider` and concrete provider modules such as `MailglassInbound.Ingress.Providers.*` internal, even when they are reachable or used by tests.

### Operator Seam Classification
- **D-05:** Treat `mix mailglass.inbound.doctor`, `mix mailglass.inbound.replay`, and `mix mailglass.inbound.prune` as stable at the command behavior and safety-semantics level.
- **D-06:** Keep operator implementation modules internal, including `MailglassInbound.Internal.Doctor`, `MailglassInbound.Internal.Replay`, `MailglassInbound.Internal.Prune`, operator record/detail/timeline helpers, worker modules, queue details, retry tuning, and direct Oban job shapes.
- **D-07:** Stable operator wording should focus on tenant guards, confirmation tiers, replay-over-stored-truth semantics, prune destructiveness, exit semantics, PII-safe telemetry, and documented command options. It must not freeze internal modules, UI/DOM shape, queue names, or worker args.

### Deferred/Internal Inventory Completeness
- **D-08:** Make the internal/deferred inventory explicit rather than implied. At minimum, Phase 63 planning should account for replay internals, worker/queue details, route structs, provider modules, matcher expansion, lifecycle callbacks, fan-out, synthetic UI, `gen_smtp`, and ecosystem integrations.
- **D-09:** Keep deferred capability wording in `mailglass_inbound/docs/api_stability.md` as a guardrail for future sessions: these items are acknowledged, not accidentally promoted into the v1.4 scope.

### the agent's Discretion
- Planner may decide the exact section organization inside `mailglass_inbound/docs/api_stability.md` as long as the resulting inventory remains readable, canonical, and mechanically checkable in later Phase 64 work.
- Planner may decide whether to update docs-contract assertions during Phase 63 or leave most executable checks to Phase 64, but Phase 63 should not make claims that Phase 64 cannot verify.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` - Phase 63 goal, requirements, success criteria, and non-goals.
- `.planning/REQUIREMENTS.md` - LOCK-01, LOCK-02, LOCK-03 and v1.4 out-of-scope table.
- `.planning/PROJECT.md` - v1.4 milestone intent, convergence posture, and stability-lock scope guardrails.
- `.planning/STATE.md` - current v1.4 preflight locks and prior trust-contract decisions.
- `.planning/METHODOLOGY.md` - decisive-by-default, honest-surface, recommendation-first, and compatibility-contract lenses.

### Stability Contract Language
- `docs/api_stability.md` - core semantics-first stability inventory language and maintainer rules.
- `mailglass_admin/docs/api_stability.md` - sibling package precedent for semantic stability without freezing internal LiveView/DOM implementation.
- `mailglass_inbound/docs/api_stability.md` - target inventory to reconcile.

### Inbound Runtime And Provider Seams
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` - public ingress plug behavior/options and provider dispatch semantics.
- `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex` - internal provider behaviour and mixed-arity provider implementation contract.
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex` - concrete provider implementation to keep internal.
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/sendgrid.ex` - concrete provider implementation to keep internal.
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/mailgun.ex` - concrete provider implementation to keep internal.
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex` - concrete provider implementation to keep internal.

### Operator And Internal Seams
- `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex` - stable operator command behavior and exit semantics.
- `mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex` - stable operator command behavior, tenant guard, and replay confirmation semantics.
- `mailglass_inbound/lib/mix/tasks/mailglass.inbound.prune.ex` - stable operator command behavior, destructive confirmation, and prune semantics.
- `mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex` - internal doctor implementation.
- `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` - internal replay implementation.
- `mailglass_inbound/lib/mailglass_inbound/internal/prune.ex` - internal prune implementation.
- `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex` - internal worker implementation.
- `mailglass_inbound/lib/mailglass_inbound/prune/worker.ex` - internal scheduled prune worker implementation.

### Existing Drift Guards
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` - current docs-contract assertions and exclusions relevant to provider, worker, replay, matcher, lifecycle, fan-out, and release-proof wording.
- `mix.exs` - root `verify.stability_contract` and inbound docs-contract wiring precedent for Phase 64.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mailglass_inbound/docs/api_stability.md` already contains the canonical inbound inventory structure and several stable/internal/deferred entries; Phase 63 should reconcile and sharpen it rather than create a new source of truth.
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` already guards several over-claims, including public provider extension API, public replay API, public worker contract, replay-as-fresh wording, and deferred matcher/lifecycle/fan-out claims.
- `docs/api_stability.md` and `mailglass_admin/docs/api_stability.md` provide the established contract language to mirror: semantic contract beats reachability.

### Established Patterns
- Public stability inventories list adopter-facing semantic seams narrowly and explicitly.
- Internal sections can name reachable modules when doing so prevents accidental promotion.
- Deferred sections should name known future capability areas without treating them as planned work.
- Testing helpers can be adopter-facing without being part of the runtime stable contract.
- Operator command semantics can be stable while underlying Mix task helper modules, internal service modules, workers, queue details, and storage plumbing remain internal.

### Integration Points
- Phase 63 primarily edits `mailglass_inbound/docs/api_stability.md`.
- Phase 63 may update `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` if the inventory wording needs immediate drift protection, but broader compiled-doc and closed-set verification belongs to Phase 64.
- Later Phase 65 docs should reference this canonical inventory rather than redefining stable/internal/deferred posture in README, operator, or testing docs.
</code_context>

<specifics>
## Specific Ideas

No additional user corrections were made. The user confirmed the assumption set as presented.
</specifics>

<deferred>
## Deferred Ideas

None - analysis stayed within Phase 63 scope.

The following remain explicitly out of scope for v1.4 feature work unless a future milestone separately promotes them: matcher expansion beyond recipient/subject/headers, mailbox lifecycle callbacks beyond `process/1`, public replay API, public provider extension API, public worker/queue contract, synthetic inbound development UI, `gen_smtp` listener work, and ecosystem integrations.
</deferred>

---

*Phase: 63-inbound-contract-inventory-reconciliation*
*Context gathered: 2026-05-31*
