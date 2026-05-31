# Phase 63: Inbound Contract Inventory Reconciliation - Research

**Researched:** 2026-05-31
**Domain:** Inbound API stability contract inventory reconciliation (`mailglass_inbound`)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
None - analysis stayed within Phase 63 scope.

The following remain explicitly out of scope for v1.4 feature work unless a future milestone separately promotes them: matcher expansion beyond recipient/subject/headers, mailbox lifecycle callbacks beyond `process/1`, public replay API, public provider extension API, public worker/queue contract, synthetic inbound development UI, `gen_smtp` listener work, and ecosystem integrations.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LOCK-01 | Adopter can identify every stable inbound runtime, testing, and operator seam from one canonical inventory. | Stable/testing/operator taxonomy and contract language alignment with core/admin inventory posture. |
| LOCK-02 | Adopter can distinguish stable semantics from reachable/internal modules. | Internal-owner inventory for providers, replay internals, workers, queues, route struct, and implementation modules. |
| LOCK-03 | Deferred inbound capabilities are explicitly named so later sessions do not promote them accidentally. | Prescriptive deferred list and wording guardrails for future phase boundaries. |
</phase_requirements>

## Summary

Phase 63 should be treated as a contract-clarity reconciliation pass, not a feature or architecture phase. The existing `mailglass_inbound/docs/api_stability.md` already has the right buckets (`stable`, `internal`, `deferred`, `testing`) and most required seams; planning should focus on tightening wording and inventory completeness so adopters can reliably infer semantic guarantees without reading internal modules. [VERIFIED: codebase grep]

The strongest precedent is already in-repo: core and admin contract docs explicitly define stability by semantic inventory and reject ExDoc/module reachability as a stability signal. Inbound should mirror this exactly, including explicit deferred/internal guardrails for replay internals, provider modules, workers/queues, and future capability areas. [VERIFIED: codebase grep]

**Primary recommendation:** Plan Phase 63 as a docs-only reconciliation of `mailglass_inbound/docs/api_stability.md` with explicit stable/testing/internal/deferred wording and no public-surface expansion. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Contract inventory truth for inbound | API / Backend | — | Stability semantics are package/API contract policy, not UI or storage behavior. [VERIFIED: codebase grep] |
| Provider support surface definition | API / Backend | Frontend Server (SSR) | Ingress behavior/options are backend seam; docs must avoid exposing provider implementation modules. [VERIFIED: codebase grep] |
| Operator command contract framing | API / Backend | Database / Storage | Replay/prune/doctor command semantics rely on storage truth but stable seam is CLI behavior, not internals. [VERIFIED: codebase grep] |
| Deferred capability boundary | API / Backend | — | Deferred list is contract policy boundary for future phases. [VERIFIED: codebase grep] |

## Project Constraints (from AGENTS.md)

`AGENTS.md` is not present in repo root; no additional project-local agent constraints were discovered. [VERIFIED: codebase grep]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.18` | Runtime and docs/test execution for this repo | Required project runtime baseline in root README. [VERIFIED: codebase grep] |
| ExUnit | bundled | Existing docs-contract assertions and phase verification lanes | Already used by inbound docs contract tests that guard stability wording. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Mix aliases (`verify.stability_contract`) | project-defined | Canonical verification lane across root + inbound docs contract tests | Use for post-edit verification in/after Phase 63 planning. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Canonical inventory reconciliation | ExDoc/public-module enumeration | Reachability freezes internals and violates locked semantics-first taxonomy. [VERIFIED: codebase grep] |

## Architecture Patterns

### System Architecture Diagram

```text
Phase 63 input
  -> Existing inbound doc inventory (api_stability.md)
  -> Core/admin contract language precedent
  -> Shipped ingress/operator/runtime behavior + docs contract tests
  -> Reconciliation decisions
      -> Stable semantics list (runtime + operator + error + telemetry boundaries)
      -> Testing helper list (adopter-facing, non-runtime)
      -> Internal list (reachable implementation details)
      -> Deferred list (explicitly out-of-scope capabilities)
  -> Updated canonical inventory wording
  -> Optional docs-contract assertion tune-up (only if needed to prevent immediate drift)
```

### Recommended Project Structure
```text
mailglass_inbound/
├── docs/api_stability.md                 # canonical Phase 63 target
├── test/mailglass_inbound/docs_contract_test.exs   # drift guard (optional updates)
└── README.md                             # language alignment reference
```

### Pattern 1: Semantics-First Stability Inventory
**What:** Define stable contract by explicit semantic inventory, not exported/reachable modules.
**When to use:** Every contract statement in inbound stability docs.
**Example:**
```elixir
# Source: mailglass_inbound/docs/api_stability.md
# Stable means adopters may rely on explicit runtime semantics such as:
# - canonical InboundMessage shape
# - verify-first ingress behavior
# - bounded async fallback posture
```

### Pattern 2: Public Seam Through Plug, Internal Providers
**What:** Describe provider support through `MailglassInbound.Ingress.Plug` behavior/options; keep provider behavior/modules internal.
**When to use:** Any docs text referring to Postmark/SendGrid/Mailgun/SES support.
**Example:**
```elixir
# Source: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
# provider option dispatches internally; provider modules are implementation support.
```

### Anti-Patterns to Avoid
- **Reachability-as-contract:** Treating public module visibility as stability promise.
- **Internal module promotion:** Listing `MailglassInbound.Ingress.Provider`, `Internal.*`, worker/queue details as stable.
- **Implicit defer list:** Leaving deferred capabilities implied instead of explicit.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stability classification | Ad-hoc module export inventory | Existing core/admin semantics-first taxonomy pattern | Prevents accidental freezing of internal implementation detail. [VERIFIED: codebase grep] |
| Drift protection | New bespoke checker in Phase 63 | Existing `docs_contract_test.exs` + root verify aliases | Current checks already enforce critical no-overclaim boundaries. [VERIFIED: codebase grep] |

**Key insight:** Reusing the established docs-contract posture is lower risk than inventing a new contract framework during a lock milestone. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Stable-By-Reachability Drift
**What goes wrong:** Docs imply reachable modules are stable public API.
**Why it happens:** ExDoc visibility and internal module naming look "public enough."
**How to avoid:** Explicitly separate stable/testing/internal/deferred inventories and say semantics > reachability.
**Warning signs:** Provider behavior modules or internal replay/worker modules appear in stable list.

### Pitfall 2: Operator Semantics Over-Specified
**What goes wrong:** Docs freeze queue names, worker args, or internals instead of command semantics.
**Why it happens:** Implementation details are easiest to describe from code.
**How to avoid:** Phrase operator stability at command behavior/safety semantics level.
**Warning signs:** `Oban.Job` shapes, queue names, retry tuning described as contract.

### Pitfall 3: Deferred Scope Erosion
**What goes wrong:** Future capabilities are omitted or ambiguously worded, then later promoted accidentally.
**Why it happens:** Deferred list becomes stale or incomplete.
**How to avoid:** Keep explicit deferred/internal inventory including matcher expansion, lifecycle callbacks, fan-out, synthetic UI, `gen_smtp`, and ecosystem integrations.
**Warning signs:** Docs mention these areas without `deferred`/internal framing.

## Code Examples

### Stable provider seam is the Plug
```elixir
# Source: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
forward "/inbound/:tenant_id/postmark", MailglassInbound.Ingress.Plug,
  provider: :postmark, router: MyApp.MailglassInboundRouter
```

### Internal provider behavior/module is not public contract
```elixir
# Source: mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex
defmodule MailglassInbound.Ingress.Provider do
  @moduledoc false
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Public API inferred from visibility | Explicit canonical inventory (`stable`/`testing`/`internal`/`deferred`) | v1.3-v1.4 planning posture [ASSUMED] | Contract decisions become reviewable and enforceable by docs tests. |

**Deprecated/outdated:**
- Reachability-driven stability claims for inbound docs. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Exact "when changed" date for current inventory posture is v1.3-v1.4 transition. | State of the Art | Low; affects chronology wording, not implementation plan quality. |

## Open Questions (RESOLVED)

1. **RESOLVED: Should Phase 63 update docs-contract assertions now or defer all assertion broadening to Phase 64?**
   - What we know: Existing inbound docs-contract tests already guard many over-claim vectors. [VERIFIED: codebase grep]
   - Resolution: Phase 63 should update focused docs-contract assertions for the reconciled inventory in the same phase, limited to stable/testing/internal/deferred wording and over-claim prevention. Larger compiled-doc and closed-set proof hardening remains deferred to Phase 64.
   - Planning impact: Include one implementation task for `mailglass_inbound/docs/api_stability.md` and one assertion task for `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`.

## Environment Availability

Step 2.6: SKIPPED (no new external dependencies identified; phase is contract-doc reconciliation with existing test lanes). [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (project Mix test lanes) [VERIFIED: codebase grep] |
| Config file | `mix.exs` aliases + package/local tests [VERIFIED: codebase grep] |
| Quick run command | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` |
| Full suite command | `mix verify.stability_contract` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LOCK-01 | Stable/testing/operator seams named from canonical inventory | contract-doc test | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ |
| LOCK-02 | Stable semantics distinguished from internal/reachable modules | contract-doc test | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ |
| LOCK-03 | Deferred capabilities explicitly named and not over-claimed | contract-doc test | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ |

### Sampling Rate
- **Per task commit:** `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors`
- **Per wave merge:** `mix verify.stability_contract`
- **Phase gate:** Full suite green before `$gsd-verify-work`

### Wave 0 Gaps
- None - existing test infrastructure covers Phase 63 contract-doc requirements. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Ingress verification-before-tenant and provider auth semantics documented at contract level. [VERIFIED: codebase grep] |
| V3 Session Management | no | N/A for this inbound-docs reconciliation slice. [ASSUMED] |
| V4 Access Control | yes | Tenant guard and command confirmation semantics (operator docs posture) remain explicit. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Stable docs should preserve explicit rejection/error semantics and bounded outcomes. [VERIFIED: codebase grep] |
| V6 Cryptography | yes | Signature verification and trust-policy semantics documented without exposing internal modules. [VERIFIED: codebase grep] |

### Known Threat Patterns for Elixir inbound-webhook stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Signature bypass by contract ambiguity | Spoofing | Keep verify-first ingress semantics explicit in stable inventory and provider-surface wording. [VERIFIED: codebase grep] |
| Cross-tenant replay ambiguity | Elevation of privilege | Keep tenant-guard replay semantics stable while replay internals remain internal. [VERIFIED: codebase grep] |
| PII leakage through docs over-claims | Information Disclosure | Phrase telemetry/error/operator seams as PII-safe semantics and avoid internal payload internals as contract. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- `mailglass_inbound/docs/api_stability.md` - current inbound stable/testing/internal/deferred inventory.
- `mailglass_inbound/README.md` - canonical inbound adoption lane and contract framing.
- `mailglass_admin/README.md` - admin semantics-first stability language precedent.
- `README.md` - root semantics-first API stability framing and runtime/test baselines.
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` - public ingress seam and provider dispatch semantics.
- `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex` - internal provider behaviour posture (`@moduledoc false`).
- `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` - replay internals remain implementation support.
- `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex` and `mailglass_inbound/lib/mailglass_inbound/prune/worker.ex` - internal worker/queue details.
- `mailglass_inbound/lib/mix/tasks/mailglass.inbound.{doctor,replay,prune}.ex` - stable operator command semantics surface.
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` - existing drift guards.
- `.planning/phases/63-inbound-contract-inventory-reconciliation/63-CONTEXT.md` - locked decisions and scope constraints.
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/config.json` - requirement mapping and workflow/security/validation toggles.

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - fully derived from in-repo docs/config/tests.
- Architecture: HIGH - phase scope is docs-contract reconciliation with direct module/test evidence.
- Pitfalls: HIGH - backed by current docs tests and locked decisions.

**Research date:** 2026-05-31
**Valid until:** 2026-06-30
