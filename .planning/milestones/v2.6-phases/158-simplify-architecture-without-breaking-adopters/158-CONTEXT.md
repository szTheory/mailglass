# Phase 158: Simplify Architecture Without Breaking Adopters - Context

**Gathered:** 2026-08-17
**Status:** Ready for planning
**Mode:** Auto-generated for an infrastructure-only phase

<domain>
## Phase Boundary

Make core and inbound ownership explicit and cycle-free through narrow integration seams, while preserving all existing v2 Config, Outbound, and inbound Plug contracts. This phase is an internal architecture refactor only: no admin/operator UI work, package collapse, public removal or rename, new provider, or unrelated product capability.

</domain>

<decisions>
## Implementation Decisions

### the agent's Discretion
- All internal module, collaborator, behaviour, and port names are discretionary when they follow existing Elixir conventions and preserve public contracts.
- Prefer executable architecture constraints, characterization tests, and measured dependency evidence over line-count-driven extraction.
- Introduce additive runtime values behind compatible configuration façades; each OTP application continues to own and validate its own environment.
- Keep shared logic with one clear owner, but retain independently released core and inbound packages and package-local optional integrations.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- Existing `Boundary` declarations, Mix `xref`, stability contracts, provider behaviours, optional-dependency gateways, and the inbound `S3Fetcher` port establish the preferred enforcement and capability patterns.
- `Mailglass.Config`, `Mailglass.Outbound`, and `MailglassInbound.Ingress.Plug` are stable public façades to preserve.

### Established Patterns
- Core may expose narrow shared primitives; inbound may depend on those declared surfaces, but core must not compile-reference inbound production code.
- Verification precedes tenant/database work, provider I/O stays outside durable transactions, and broadcasts remain post-commit best effort.
- Configuration is validated at application boot with NimbleOptions; tests require an explicit cache invalidation seam when application environment changes.

### Integration Points
- Core runtime/config boot: `lib/mailglass/config.ex` and `lib/mailglass/application.ex`.
- Outbound orchestration: `lib/mailglass/outbound.ex` and its persistence/dispatch collaborators.
- Inbound integration and HTTP pipeline: `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`, provider, persistence, execution, PubSub, and tenancy seams.
- Architecture gates: both package `mix.exs` files, compile-connected `xref` checks, and static production-edge contracts.

</code_context>

<specifics>
## Specific Ideas

Keep the result simple and elegant: one validated runtime source of truth, thin stable façades, small consumer-oriented ports, one owner per business rule, and automated gates that prevent dependency cycles or implementation leakage from returning.

</specifics>

<deferred>
## Deferred Ideas

- Admin/operator UI behavior, styling, navigation, and visual cleanup.
- General CI gate consolidation beyond the compile-cycle/package-edge proof required by ARCH-01; that belongs to Phase 159.
- Release certification and publication; that belongs to Phase 160.
- Breaking v2 API removals or package consolidation.

</deferred>
