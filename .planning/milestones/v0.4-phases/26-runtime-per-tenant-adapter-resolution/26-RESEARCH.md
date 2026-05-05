# Phase 26: Runtime Per-Tenant Adapter Resolution - Research

**Researched:** 2026-05-01
**Domain:** Elixir/Phoenix outbound email routing, multi-tenancy, Swoosh/Oban integration
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Source: [VERIFIED: .planning/phases/26-runtime-per-tenant-adapter-resolution/26-CONTEXT.md]

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

### Claude's Discretion
Source: [VERIFIED: .planning/phases/26-runtime-per-tenant-adapter-resolution/26-CONTEXT.md]
- Exact callback name and exact return tuple/map shape, as long as it clearly supports a durable adapter ref and explicit default/error outcomes.
- Exact error-module placement and wording, as long as failures stay typed, loud, and actionable.
- Exact registry validation/accessor module shape, as long as route refs resolve deterministically to adapter tuples and secrets stay outside persisted state.
- Exact persistence field choice (`provider` reuse versus explicit route-ref field), as long as queue-time route intent is durably stored and auditable.
- Exact precedence rules between per-call override, persisted route ref, tenant callback, registry lookup, and global default, as long as they are documented explicitly and keep explicit per-call override as the top-priority escape hatch.

### Deferred Ideas (OUT OF SCOPE)
Source: [VERIFIED: .planning/phases/26-runtime-per-tenant-adapter-resolution/26-CONTEXT.md]
- A dedicated `Mailglass.AdapterRegistry` or process-backed route cache with invalidation semantics.
- Provider failover, round-robin, or other availability/load-balancing policy transport composition.
- Exact historical encrypted snapshotting of full adapter config for replay/forensics.
- Operator/admin UI for inspecting or changing tenant routing.
- Cross-node route cache coordination or dynamic control-plane tooling.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TENANT-01 | Adopter can configure runtime per-tenant adapter resolution for outbound delivery. | Add an optional `Mailglass.Tenancy` outbound-route callback that returns `:default`, `{:ok, adapter_ref}`, or `{:error, reason}` and resolves refs through additive `config :mailglass, adapters:` entries. |
| TENANT-02 | Delivery pipeline resolves the effective adapter using tenant context without recompilation. | Resolve at runtime inside `Mailglass.Outbound`, persist a durable route ref on the delivery row for async, and rehydrate adapter module/opts from that ref at dispatch time. |
| TENANT-03 | Single-tenant apps retain a deterministic default path when no tenant resolver is configured. | Keep `config :mailglass, adapter` unchanged as the zero-config default and treat `:default` / missing callback as the existing path. |
</phase_requirements>

## Summary

Mailglass already has the right seams for this feature: `Mailglass.Tenancy` owns optional runtime callbacks, `Mailglass.Outbound` already centralizes adapter resolution and queueing, and the async path already persists a `Delivery` row then rehydrates by `delivery_id`. [VERIFIED: lib/mailglass/tenancy.ex] [VERIFIED: lib/mailglass/outbound.ex] [VERIFIED: lib/mailglass/outbound/worker.ex]

The planner should treat this as an additive routing layer, not a new subsystem. The low-surprise design is: keep the existing global `config :mailglass, adapter` path for single-tenant apps, add an optional tenant callback that returns a durable route ref, add additive `config :mailglass, adapters:` registry entries for reusable named routes, and persist the chosen route ref on the delivery row before async work leaves the caller process. [VERIFIED: config/config.exs] [VERIFIED: lib/mailglass/outbound.ex] [CITED: https://hexdocs.pm/elixir/1.19.3/config-and-distribution.html] [CITED: https://docs.djangoproject.com/en/dev/topics/email/] [CITED: https://anymail.dev/en/v12.0/tips/multiple_backends/]

**Primary recommendation:** Add an optional `Mailglass.Tenancy` outbound-route callback plus an explicit persisted `adapter_ref` field on `mailglass_deliveries`; do not overload `provider` as the only durable route identity.

## Project Constraints (from CLAUDE.md)

- Multi-tenancy is first-class and cannot be treated as an afterthought. [VERIFIED: CLAUDE.md]
- Errors are a public API contract, so new route failures must be typed and actionable. [VERIFIED: CLAUDE.md]
- Telemetry metadata must never include PII. [VERIFIED: CLAUDE.md]
- Optional dependencies must stay behind existing optional-dep gateway patterns; Oban remains optional. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs]
- Runtime config should stay runtime-only; do not introduce compile-time adapter expansion outside `Mailglass.Config`. [VERIFIED: CLAUDE.md] [CITED: https://hexdocs.pm/elixir/1.19.3/config-and-distribution.html]
- Do not introduce hidden singleton processes in library code. [VERIFIED: CLAUDE.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tenant-aware outbound route selection | API / Backend | Database / Storage | Routing depends on tenant context and message data at send time; it should run inside `Mailglass.Outbound`, not in client/UI code. [VERIFIED: lib/mailglass/outbound.ex] [VERIFIED: lib/mailglass/tenancy.ex] |
| Adapter registry config validation | API / Backend | — | Registry entries are runtime config read by library code and should be validated where adapter resolution happens. [VERIFIED: config/config.exs] [CITED: https://hexdocs.pm/elixir/1.19.3/config-and-distribution.html] |
| Durable route identity for async sends | Database / Storage | API / Backend | Queue determinism requires persisting route intent on the delivery row before the worker runs. [VERIFIED: lib/mailglass/outbound.ex] [VERIFIED: lib/mailglass/outbound/delivery.ex] |
| Async dispatch rehydration | API / Backend | Database / Storage | The worker already loads by `delivery_id`; it should consume persisted route identity instead of recomputing provider choice. [VERIFIED: lib/mailglass/outbound/worker.ex] [VERIFIED: lib/mailglass/outbound.ex] |
| Single-tenant default behavior | API / Backend | — | The existing global adapter path is already a runtime backend concern and must remain the default. [VERIFIED: config/config.exs] [VERIFIED: lib/mailglass/outbound.ex] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | 1.8.5 | Runtime/library host stack already locked by the repo. [VERIFIED: mix.exs] [VERIFIED: mix hex.info phoenix] | Phase 26 should preserve existing Phoenix-first patterns, not introduce a parallel transport abstraction. [VERIFIED: CLAUDE.md] |
| Ecto | 3.13.5 | Persist delivery route identity and drive migration/change-set work. [VERIFIED: mix.exs] [VERIFIED: mix hex.info ecto] | The async path already uses `Delivery` rows plus `Ecto.Multi`, so persistence changes belong here. [VERIFIED: lib/mailglass/outbound.ex] [VERIFIED: lib/mailglass/outbound/delivery.ex] |
| Swoosh | 1.25.0 (repo lock), 1.25.1 docs checked | Underlying adapter contract used by `Mailglass.Adapters.Swoosh`. [VERIFIED: mix.lock] [VERIFIED: mix hex.info swoosh] [CITED: https://hexdocs.pm/swoosh/1.25.1/Swoosh.Adapter.html] | The repo already bridges to `Swoosh.Adapter.deliver/2` with module+opts semantics. [VERIFIED: lib/mailglass/adapters/swoosh.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Oban | 2.21.1 (repo lock), 2.22.1 docs checked | Async queue worker and enqueue semantics. [VERIFIED: mix.lock] [VERIFIED: mix hex.info oban] [CITED: https://hexdocs.pm/oban/unique_jobs.html] | Use only for queue-time persistence and dispatch; do not rely on Oban uniqueness as a substitute for persisted route identity. [VERIFIED: lib/mailglass/outbound/worker.ex] |
| NimbleOptions | 1.1.1 | Validate additive `config :mailglass, adapters:` shape consistently with the repo’s config posture. [VERIFIED: mix.exs] [VERIFIED: mix hex.info nimble_options] | Use for registry validation if Phase 26 adds new config surface. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Mailglass.Tenancy` optional callback | Separate global resolver tuple | Adds a second routing seam and breaks the repo’s existing tenancy pattern. [VERIFIED: lib/mailglass/tenancy.ex] |
| Explicit `adapter_ref` field | Reuse `provider` only | `provider` cannot distinguish same-provider-different-credentials/domain cases and is already operator-facing language. [VERIFIED: lib/mailglass/outbound/delivery.ex] [VERIFIED: lib/mailglass/operator/deliveries.ex] |
| Single callback + named refs | Laravel-style named mailer expansion | Too heavy for tenant-scale routing and drifts into failover/load-balancing surfaces this phase explicitly excludes. [CITED: https://laravel.com/docs/13.x/mail] |

**Version verification:** Current repo/runtime versions were verified with `mix hex.info` and `mix.lock`. [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info swoosh] [VERIFIED: mix hex.info oban] [VERIFIED: mix.lock]

## Architecture Patterns

### System Architecture Diagram

`Message + tenant context`
→ `Mailglass.Outbound preflight`
→ `per-call override?`
→ yes: `adapter/module opts directly`
→ no: `Mailglass.Tenancy outbound-route callback`
→ `:default` => global `config :mailglass, adapter`
→ `{:ok, adapter_ref}` => lookup in `config :mailglass, adapters`
→ `persist delivery with adapter_ref (+ provider label if available)`
→ sync: `call adapter now`
→ async: `enqueue job with delivery_id only`
→ worker `dispatch_by_id/1`
→ `load delivery + adapter_ref`
→ `registry lookup at dispatch time`
→ `call adapter`
→ `persist dispatched/failed outcome`. [VERIFIED: lib/mailglass/outbound.ex] [VERIFIED: lib/mailglass/outbound/worker.ex]

### Recommended Project Structure

```text
lib/mailglass/
├── tenancy.ex                  # add optional outbound-route callback
├── outbound.ex                 # shared resolution + sync/async precedence
├── outbound/delivery.ex        # durable adapter_ref field + changeset
├── adapters/swoosh.ex          # existing module+opts interop
└── config.ex / config_schema   # additive adapter registry validation if split out
```

### Pattern 1: Optional tenancy callback returning a durable ref
**What:** Use a new optional `Mailglass.Tenancy` callback for outbound routing, mirroring existing optional tenancy hooks. [VERIFIED: lib/mailglass/tenancy.ex] [CITED: https://hexdocs.pm/elixir/1.4.5/behaviours.html]
**When to use:** Any send path that does not supply an explicit per-call adapter override.
**Example:**
```elixir
@optional_callbacks resolve_outbound_adapter: 1
@callback resolve_outbound_adapter(%{
  tenant_id: String.t() | nil,
  message: Mailglass.Message.t(),
  mode: :sync | :async
}) :: :default | {:ok, atom()} | {:error, term()}
```

### Pattern 2: Persist route intent at enqueue time, resolve secrets at dispatch time
**What:** Persist `adapter_ref` on `Delivery` before queue handoff; never persist raw credentials in delivery metadata or Oban args. [VERIFIED: lib/mailglass/outbound.ex] [VERIFIED: lib/mailglass/outbound/worker.ex] [CITED: https://hexdocs.pm/oban/unique_jobs.html]
**When to use:** `deliver_later/2`, retry flows, delayed jobs.

### Pattern 3: Additive registry config, not a new runtime process
**What:** Keep `config :mailglass, adapter` untouched and add `config :mailglass, adapters:` only for named routes. [VERIFIED: config/config.exs] [CITED: https://hexdocs.pm/elixir/1.19.3/config-and-distribution.html]
**When to use:** Multi-tenant or multi-route adopters that need reusable named targets.

### Anti-Patterns to Avoid
- **Silent fallback on broken tenant routing:** Broken route output must error, not quietly use the global default. [VERIFIED: .planning/phases/26-runtime-per-tenant-adapter-resolution/26-CONTEXT.md]
- **Using free-form metadata keys for route identity:** Prefer an explicit schema field over adopter-colliding metadata. [VERIFIED: .planning/phases/26-runtime-per-tenant-adapter-resolution/26-CONTEXT.md]
- **Late-bound async re-resolution with no persisted ref:** Retries should not drift across providers after config changes. [VERIFIED: .planning/phases/26-runtime-per-tenant-adapter-resolution/26-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Runtime adapter caching | GenServer/process registry | Pure callback + runtime config lookup | The phase explicitly forbids hidden singleton infrastructure. [VERIFIED: .planning/phases/26-runtime-per-tenant-adapter-resolution/26-CONTEXT.md] |
| Historical config replay | Full adapter snapshot in DB/job args | Persist `adapter_ref`, resolve secrets at dispatch | Avoids secret persistence and upgrade burden. [VERIFIED: .planning/phases/26-runtime-per-tenant-adapter-resolution/26-CONTEXT.md] |
| Failover/load balancing | Named-mailer graph or transport policy engine | Out of scope for Phase 26 | The user explicitly excluded it. [VERIFIED: .planning/phases/26-runtime-per-tenant-adapter-resolution/26-CONTEXT.md] |

## Common Pitfalls

### Pitfall 1: Overloading `provider` as the only durable identity
**What goes wrong:** `provider` can label an ESP family, but cannot distinguish multiple tenant-specific routes that all use the same ESP. [VERIFIED: lib/mailglass/outbound/delivery.ex] [VERIFIED: lib/mailglass/operator/deliveries.ex]
**How to avoid:** Persist a dedicated `adapter_ref`/`route_ref` field and keep `provider` as a secondary human/ops label.

### Pitfall 2: Recomputing async provider choice at dispatch time
**What goes wrong:** Config changes can silently move retries to a different provider path than the original enqueue decision. [VERIFIED: lib/mailglass/outbound.ex] [CITED: https://hexdocs.pm/oban/unique_jobs.html]
**How to avoid:** Resolve route ref at enqueue, persist it, and dispatch from that persisted ref.

### Pitfall 3: Treating invalid tenant output as “use default”
**What goes wrong:** Broken tenant routing becomes invisible and cross-tenant mistakes become harder to detect. [VERIFIED: .planning/phases/26-runtime-per-tenant-adapter-resolution/26-CONTEXT.md]
**How to avoid:** Reserve `:default` as the only intentional fallback outcome; everything else invalid should raise/return typed error.

## Code Examples

### Existing runtime adapter resolution seam
```elixir
defp resolve_adapter(opts) do
  case Keyword.fetch(opts, :adapter) do
    {:ok, {mod, kw}} -> {mod, kw}
    {:ok, mod} when is_atom(mod) -> {mod, []}
    :error ->
      case Application.get_env(:mailglass, :adapter, {Mailglass.Adapters.Fake, []}) do
        {mod, kw} -> {mod, kw}
        mod when is_atom(mod) -> {mod, []}
      end
  end
end
```
Source: [VERIFIED: lib/mailglass/outbound.ex]

### Existing Swoosh adapter contract shape
```elixir
@callback deliver(Swoosh.Email.t(), keyword()) :: {:ok, term()} | {:error, term()}
```
Source: [CITED: https://hexdocs.pm/swoosh/1.25.1/Swoosh.Adapter.html]

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| One global adapter only | Global default plus runtime route selection callback | Keeps the simple case simple while enabling tenant exceptions. [VERIFIED: config/config.exs] [VERIFIED: lib/mailglass/tenancy.ex] |
| Fully late-bound worker choice | Queue-time route snapshot plus dispatch-time secret lookup | Prevents retry drift without storing secrets. [VERIFIED: lib/mailglass/outbound.ex] |
| Multiple named mailers per use case | One send pipeline plus explicit backend override/ref selection | Lower surprise for a library that already centralizes outbound delivery. [CITED: https://docs.djangoproject.com/en/dev/topics/email/] [CITED: https://anymail.dev/en/v12.0/tips/multiple_backends/] |

## Assumptions Log

All key factual claims above were verified in-repo or against official docs. The remaining open items are design recommendations inside the phase’s discretion envelope, not unverified external facts.

## Resolved Design Choices

1. **Column naming:** use `adapter_ref` as the dedicated delivery field. It matches the existing adapter vocabulary used in the codebase, stays clear to adopters, and avoids the broader policy implications of a generic `route_ref`.
2. **Provider label derivation:** do not persist a second provider-family routing field for Phase 26. Persist `adapter_ref` as the durable route identity and derive the runtime adapter/provider path from the resolved adapter tuple or registry entry. Keep `provider` reserved for actual dispatch provenance after send time, not queue-time route intent.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Phase implementation/tests | ✓ | 1.19.5 [VERIFIED: `elixir --version`] | — |
| Mix | Phase implementation/tests | ✓ | 1.19.5 [VERIFIED: `mix --version`] | — |
| PostgreSQL | Ecto/Oban-backed tests | ✓ | server accepting on `5432`, `psql 14.17` [VERIFIED: `pg_isready`][VERIFIED: `psql --version`] | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + Oban.Testing + StreamData [VERIFIED: mix.exs] |
| Config file | `test/test_helper.exs`, `test/support/mailer_case.ex`, `test/support/data_case.ex` [VERIFIED: test/support/mailer_case.ex] |
| Quick run command | `mix test test/mailglass/outbound/deliver_later_test.exs test/mailglass/outbound/worker_test.exs test/mailglass/adapters/swoosh_test.exs test/mailglass/tenancy_test.exs --warnings-as-errors` |
| Full suite command | `mix test --warnings-as-errors` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TENANT-01 | tenant callback + registry ref selection | unit/integration | `mix test test/mailglass/outbound/tenant_adapter_resolution_test.exs --warnings-as-errors` | ❌ Wave 0 |
| TENANT-02 | async persistence + worker rehydration from persisted ref | integration | `mix test test/mailglass/outbound/tenant_route_persistence_test.exs test/mailglass/outbound/worker_test.exs --warnings-as-errors` | ❌ Wave 0 |
| TENANT-03 | deterministic single-tenant fallback path | regression | `mix test test/mailglass/outbound/default_adapter_fallback_test.exs --warnings-as-errors` | ❌ Wave 0 |

### Wave 0 Gaps
- `test/mailglass/outbound/tenant_adapter_resolution_test.exs` — callback outcomes, precedence, invalid output
- `test/mailglass/outbound/tenant_route_persistence_test.exs` — enqueue persistence, retry determinism, worker dispatch
- `test/mailglass/outbound/default_adapter_fallback_test.exs` — no-resolver and `:default` regression coverage

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes | Tenant context must not cross route boundaries. [VERIFIED: CLAUDE.md] |
| V5 Input Validation | yes | Validate callback outputs and registry entries before adapter dispatch. |
| V6 Cryptography | no | Do not add new crypto; keep secret lookup at runtime only. |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant route confusion | Elevation of Privilege | Resolve from stamped tenant context only; invalid output fails loud. [VERIFIED: lib/mailglass/tenancy.ex] |
| Secret persistence in DB/job args | Information Disclosure | Persist only `adapter_ref`; resolve credentials from runtime config at dispatch. [VERIFIED: lib/mailglass/outbound.ex] |
| Silent misrouting after config change | Tampering | Persist route identity at enqueue and dispatch from persisted ref. |

## Sources

### Primary (HIGH confidence)
- `lib/mailglass/tenancy.ex` - existing optional callback pattern and tenancy seam
- `lib/mailglass/outbound.ex` - current adapter resolution, queueing, rehydration, and worker handoff
- `lib/mailglass/outbound/delivery.ex` - current delivery schema
- `lib/mailglass/outbound/worker.ex` - current worker/job contract
- `lib/mailglass/adapters/swoosh.ex` - current module+opts adapter bridge
- `config/config.exs` and `guides/multi-tenancy.md` - current adopter-facing config and docs
- `https://hexdocs.pm/elixir/1.19.3/config-and-distribution.html` - runtime configuration guidance
- `https://hexdocs.pm/elixir/1.4.5/behaviours.html` - optional callback precedent
- `https://hexdocs.pm/swoosh/1.25.1/Swoosh.Adapter.html` - adapter callback contract
- `https://hexdocs.pm/oban/unique_jobs.html` - enqueue-time uniqueness semantics

### Secondary (MEDIUM confidence)
- `https://docs.djangoproject.com/en/dev/topics/email/` - explicit backend selection precedent
- `https://anymail.dev/en/v12.0/tips/multiple_backends/` - practical multi-backend email guidance
- `https://laravel.com/docs/13.x/mail` - heavier named-mailer/failover model used as contrast

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - repo seams and versions are explicit.
- Architecture: HIGH - current pipeline already exposes the required insertion points.
- Pitfalls: HIGH - most risks are directly visible in current code and locked phase constraints.

**Research date:** 2026-05-01
**Valid until:** 2026-05-31
