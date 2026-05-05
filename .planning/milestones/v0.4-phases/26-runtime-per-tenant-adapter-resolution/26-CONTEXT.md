# Phase 26: runtime-per-tenant-adapter-resolution - Context

**Gathered:** 2026-05-01 (assumptions mode, research-backed)
**Status:** Ready for planning

<domain>
## Phase Boundary

Add runtime per-tenant outbound adapter resolution to the mailglass delivery pipeline without breaking existing single-tenant defaults.

This phase is about outbound transport selection and routing semantics. It is not an operator UI feature, not a provider failover/load-balancing system, not a full transport-registry product, and not a generic secrets-management subsystem.

</domain>

<decisions>
## Implementation Decisions

### Resolver ownership and public contract
- **D-26-01:** Per-tenant outbound adapter resolution should live on the existing `Mailglass.Tenancy` seam as a new optional callback, not as a separate global resolver tuple and not as a registry/service API.
- **D-26-02:** The callback should return a stable adapter reference / route identity, not raw adapter secrets or an opaque serialized adapter tuple. The actual adapter module + opts should resolve through a Mailglass-owned adapter registry config surface such as `config :mailglass, adapters: [...]`.
- **D-26-03:** The callback context should stay outbound-focused and narrow. It should include the message and runtime delivery mode needed to choose a route, but should not become a grab-bag for unrelated policy.
- **D-26-04:** The existing explicit per-call override surface should remain the highest-priority escape hatch for tests and advanced caller control. Downstream design may support both `opts[:adapter]` and `opts[:adapter_ref]`, but the normal runtime path is tenant callback → adapter ref → registry lookup.

### Default and fallback behavior
- **D-26-05:** Single-tenant apps must retain today’s deterministic default behavior. If no tenant resolver is configured, or if the resolver intentionally falls back, mailglass continues to use the global `config :mailglass, adapter` path.
- **D-26-06:** The resolver contract should support an explicit “use default” outcome rather than forcing every tenant-aware callback to return a full adapter config on every send.
- **D-26-07:** Invalid resolver output, unresolved routes, or malformed adapter configs must fail loudly with typed, actionable errors. Silent fallback from a broken tenant-specific route to the global default is not acceptable.
- **D-26-07a:** The new `config :mailglass, adapters:` registry is an additive advanced surface for named route targets. `config :mailglass, adapter` remains the zero-config default and must not become mandatory for single-tenant adopters.

### Resolution timing and queue semantics
- **D-26-08:** Synchronous sends should resolve the effective route at send time using the current message and tenant context.
- **D-26-09:** Asynchronous sends should not rely on fully late-bound provider resolution forever. Queue-time routing intent must be persisted so retries and delayed execution do not silently drift across providers after a config change.
- **D-26-10:** Phase 26 should use a hybrid model for queued sends:
  - snapshot a stable route identity / adapter ref at enqueue time
  - resolve adapter module, opts, secrets, and other runtime credentials from that ref at dispatch time
  This preserves queue semantics without storing raw secrets in delivery rows or job args.
- **D-26-11:** Full adapter-config snapshotting is out for the default design. Persisting raw provider credentials or opaque serialized adapter config would add security, upgrade, and support burden disproportionate to this phase.
- **D-26-12:** The persisted route identity should be durable enough to answer “which provider path was this delivery intended to use?” even if execution happens later.

### Persistence and delivery-model posture
- **D-26-13:** The outbound delivery model should persist stable route intent on the delivery row, using the existing `provider` field if it is semantically sufficient or a new explicit route-ref field if it is not. Downstream planning may choose the exact column shape, but the contract must remain durable and grep-able.
- **D-26-14:** Job args should remain small and stable. Do not serialize full adapter config into Oban args.
- **D-26-15:** Rehydration/dispatch logic should continue to load the delivery by id and dispatch through one canonical path, but that path must honor the persisted adapter ref rather than recomputing provider choice from scratch with no historical anchor.
- **D-26-15a:** Internal route metadata must use a reserved internal namespace or explicit schema field, not ambiguous free-form metadata keys that can collide with adopter-owned metadata.

### Runtime architecture and caching posture
- **D-26-16:** Do not introduce a `Mailglass.AdapterRegistry`, process-backed cache, or hidden singleton in Phase 26.
- **D-26-17:** Runtime per-tenant resolution should stay pure and explicit first. If route-resolution cost later proves meaningful, caching can be added in a later phase with clear invalidation semantics and benchmark evidence.
- **D-26-18:** Failover, round-robin, and other availability/load-balancing transport policies are separate concerns from tenant routing. Phase 26 should not conflate them.

### DX and ecosystem fit
- **D-26-19:** The adopter mental model should be:
  - one global adapter default for the simple case
  - one tenant-owned runtime callback for exceptions
  - one Mailglass-owned adapter registry for reusable named routes
  - one canonical outbound pipeline
  - one durable adapter ref for queued work
  This is the least-surprising shape for a Phoenix library in this problem space.
- **D-26-20:** The API should feel closer to Django/Anymail/Bamboo-style runtime backend selection than to a Laravel/Symfony-style explosion of named mailers per tenant.
- **D-26-21:** Do not expose transport selection through message headers or other user-content surfaces. Routing is infrastructure policy, not email content.
- **D-26-22:** Documentation and examples should emphasize common multi-tenant cases directly:
  - different ESP per tenant
  - same ESP with different per-tenant credentials/subaccounts
  - same provider family with different streams/domains

### Safety boundaries and non-goals
- **D-26-23:** Phase 26 is not a compile-time configuration expansion. The effective route must be resolvable at runtime without recompilation.
- **D-26-24:** Phase 26 is not a forensic “exact historical secret replay” system. It should preserve route intent and operational clarity, not raw credential history.
- **D-26-25:** Phase 26 should not force a second-class experience on single-tenant adopters just to support advanced multi-tenant cases.

### Decision posture for downstream agents
- **D-26-26:** Downstream planning and execution should research broadly, synthesize one cohesive recommendation set, and avoid escalating routine design choices back to the user.
- **D-26-27:** Escalate only for very impactful decisions likely to change:
  - the public adapter/tenancy contract
  - queue determinism or retry semantics in a surprising way
  - tenant trust boundaries or cross-tenant safety guarantees
  - secret-handling posture
  - long-term maintainer burden through new runtime stateful infrastructure

### the agent's Discretion
- Exact callback name and exact return tuple/map shape, as long as it clearly supports a durable adapter ref and explicit default/error outcomes.
- Exact error-module placement and wording, as long as failures stay typed, loud, and actionable.
- Exact registry validation/accessor module shape, as long as route refs resolve deterministically to adapter tuples and secrets stay outside persisted state.
- Exact persistence field choice (`provider` reuse versus explicit route-ref field), as long as queue-time route intent is durably stored and auditable.
- Exact precedence rules between per-call override, persisted route ref, tenant callback, registry lookup, and global default, as long as they are documented explicitly and keep explicit per-call override as the top-priority escape hatch.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and project posture
- `.planning/ROADMAP.md` — Phase 26 goal, milestone position, and dependency chain.
- `.planning/PROJECT.md` — multi-tenant-first product stance, Phoenix-first architecture, maintainer constraints, and v0.4 operator-confidence framing.
- `.planning/REQUIREMENTS.md` — `TENANT-01`, `TENANT-02`, and `TENANT-03`.
- `.planning/STATE.md` — current milestone state and neighboring phase context.
- `.planning/METHODOLOGY.md` — decisive-by-default, honest-surface, and recommendation-first project lenses.

### Prior phase and prior research constraints
- `.planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md` — strongest prior capture of the project’s recommendation-first and escalate-only-on-high-impact posture.
- `.planning/phases/25-deliverability-doctor/25-CONTEXT.md` — recent locked preference for broad research, one coherent default, and honest runtime surfaces.
- `.planning/milestones/v0.1-research/ARCHITECTURE.md` — earlier `AdapterRegistry`/route-caching proposal to treat as precedent, not as a locked implementation requirement.
- `.planning/milestones/v0.1-research/PITFALLS.md` — hidden-singleton and per-tenant adapter footguns to avoid.
- `.planning/milestones/v0.2-REQUIREMENTS.md` §`DELIV-07` — earlier route-identity framing for per-tenant adapter resolution.

### Existing implementation seams
- `lib/mailglass/outbound.ex` — current adapter resolution and sync/async delivery pipeline.
- `lib/mailglass/outbound/delivery.ex` — delivery schema, including the existing `provider` field and queued/send lifecycle surface.
- `lib/mailglass/outbound/worker.ex` — queued dispatch job shape and current `delivery_id` + `mailglass_tenant_id` contract.
- `lib/mailglass/tenancy.ex` — existing optional tenant runtime hooks and fallback dispatch pattern.
- `lib/mailglass/tenancy/single_tenant.ex` — zero-config single-tenant default semantics.
- `lib/mailglass/adapter.ex` — adapter behaviour contract.
- `lib/mailglass/adapters/swoosh.ex` — adapter/module-plus-opts runtime shape that downstream routing must interoperate with.
- `guides/multi-tenancy.md` — current adopter-facing tenancy guidance.
- `config/config.exs` — current global default adapter contract.
- `config/runtime.exs` — current adopter runtime-config example surface.

### External standards and ecosystem precedents
- `https://hexdocs.pm/elixir/1.18.0/library-guidelines.html` — Elixir library guidance against unnecessary complexity and surprising global behavior.
- `https://hexdocs.pm/elixir/1.4.5/behaviours.html` — optional callback behaviour patterns.
- `https://hexdocs.pm/elixir/config-and-distribution.html` — runtime configuration and secret-resolution posture.
- `https://hexdocs.pm/swoosh/Swoosh.Adapter.html` — module-and-config adapter contract precedent.
- `https://hexdocs.pm/oban/unique_jobs.html` — queue uniqueness semantics and why insertion-time uniqueness is distinct from execution semantics.
- `https://guides.rubyonrails.org/action_mailer_basics.html` — default mailer plus per-message delivery overrides.
- `https://laravel.com/docs/13.x/mail` — default mailer plus named mailer selection and the limits of named-transport expansion.
- `https://docs.djangoproject.com/en/dev/topics/email/` — explicit backend instance selection via `get_connection`.
- `https://anymail.dev/en/v12.0/tips/multiple_backends/` — practical multiple-ESP/backend patterns.
- `https://hexdocs.pm/bamboo/Bamboo.Mailer.html` — explicit mailer/runtime transport configuration precedent in Elixir.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.Tenancy` already owns optional tenant-specific runtime hooks beyond pure query scoping, making it the least-surprising home for outbound routing.
- `Mailglass.Outbound.resolve_adapter/1` already centralizes global/default adapter resolution, giving Phase 26 one obvious insertion point for tenant-aware routing.
- `Mailglass.Outbound.Worker` already keeps queued args minimal (`delivery_id`, `mailglass_tenant_id`), which is a good constraint to preserve.
- `Mailglass.Adapters.Swoosh` already models the adapter-as-module-plus-opts shape Phase 26 must feed at runtime.

### Established Patterns
- Mailglass prefers explicit runtime seams over hidden processes or framework magic.
- Optional callbacks with `function_exported?/3` fallback are already an accepted pattern in the tenancy layer.
- Queue jobs persist stable identifiers, then rehydrate runtime state rather than serializing heavy payloads.
- Single-tenant zero-config behavior is treated as a first-class product requirement, not a degraded fallback.

### Integration Points
- `Outbound.send/2` and `deliver_later/2` need a shared route-resolution layer that can honor per-call override, tenant callback, adapter-ref registry, and global default coherently.
- Queue insertion needs to resolve and persist a stable adapter ref on the delivery row before async execution begins.
- Async dispatch needs to resolve credentials/config from the persisted adapter ref without recomputing provider choice from scratch.
- Delivery tests, tenancy tests, and async worker tests will need new coverage for fallback, route persistence, retry semantics, and malformed tenant resolver output.

</code_context>

<specifics>
## Specific Ideas

- The right Phase 26 mental model is:
  - boring global default
  - explicit tenant hook for exceptional routing
  - reusable named adapter refs in config
  - queue-time adapter-ref persistence
  - dispatch-time secret resolution
  - no hidden registry magic
- The best precedent mix for this repo is:
  - Elixir optional callback seams for the contract shape
  - Swoosh/Bamboo runtime adapter objects for the transport shape
  - Django/Anymail-style explicit backend resolution for multi-tenant DX
  - avoidance of named-mailer explosion from Laravel/Symfony when tenant count grows
- Great DX for adopters here means:
  - one obvious place to put tenant routing logic
  - deterministic single-tenant behavior when they do nothing
  - explicit typed failures when tenant routing is broken
  - clear docs for “different ESP”, “same ESP different credentials”, and “same provider different stream/domain” cases

</specifics>

<deferred>
## Deferred Ideas

- A dedicated `Mailglass.AdapterRegistry` or process-backed route cache with invalidation semantics.
- Provider failover, round-robin, or other availability/load-balancing policy transport composition.
- Exact historical encrypted snapshotting of full adapter config for replay/forensics.
- Operator/admin UI for inspecting or changing tenant routing.
- Cross-node route cache coordination or dynamic control-plane tooling.

</deferred>

---

*Phase: 26-runtime-per-tenant-adapter-resolution*
*Context gathered: 2026-05-01*
