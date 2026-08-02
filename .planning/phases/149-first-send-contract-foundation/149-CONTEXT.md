# Phase 149: First-Send Contract Foundation - Context

**Gathered:** 2026-08-02 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the documented first-send contract true for one supported outbound message: an unstamped default `Mailglass.Tenancy.SingleTenant` caller can render and send synchronously or select durable async delivery as tenant `"default"`; custom tenancy and invalid recipient/body shapes fail with typed errors before side effects; and published plaintext/CSS-inlining semantics agree across direct rendering, sync send, async send, and preview. Private durable-envelope persistence and atomic enqueue belong to Phase 150; dispatch outcome and payload-lifecycle convergence belong to Phase 151.

</domain>

<decisions>
## Implementation Decisions

### Tenancy contract
- **D-01:** Shared outbound preflight treats the configured `Mailglass.Tenancy.SingleTenant` resolver as an implicit valid tenant `"default"` when no process-local tenant stamp exists.
- **D-02:** Any configured custom tenancy implementation remains fail-closed: absent, invalid, or unrestorable tenant context produces a typed, actionable tenancy failure and must never fall back to tenant `"default"`.

### Envelope preflight and error contract
- **D-03:** Add one shared, pure envelope/body validation gate used by outbound paths before rendering, suppression checks, rate-limit consumption, persistence, job insertion, or provider dispatch.
- **D-04:** Recipient validation counts every entry across the native Swoosh `to`, `cc`, and `bcc` collections and accepts exactly one total envelope recipient. Zero recipients and every multi-recipient combination are rejected without silently selecting or dropping an address.
- **D-05:** Body validation accepts only supported shapes with a non-empty HTML and/or plaintext body. Unsupported functions, values, or empty-body shapes fail explicitly before a delivery row or job exists.
- **D-06:** Envelope/body preflight failures reuse `%Mailglass.SendError{type: :preflight_rejected}` with bounded, actionable, non-PII context. Do not introduce a separate public error family for these cases.

### Rendering and published configuration
- **D-07:** `Mailglass.Renderer` is the single implementation point for body precedence and renderer configuration so direct render, synchronous send, async preparation, and preview observe the same semantics.
- **D-08:** Preserve adopter-authored plaintext. Text-only messages remain non-empty and sendable without manufacturing an HTML body.
- **D-09:** Generate automatic plaintext only for HTML-only messages when `renderer.plaintext` is enabled; disabling it leaves HTML-only mail without generated plaintext and never deletes explicit plaintext.
- **D-10:** Honor `renderer.css_inliner`: `:premailex` uses the current inliner and `:none` skips CSS inlining while retaining the rest of the render pipeline.

### the agent's Discretion
- Exact internal validator/helper module boundaries, provided all outbound entry points share the same pure pre-side-effect gate.
- Exact non-PII context keys/messages beneath the locked `%Mailglass.SendError{type: :preflight_rejected}` public contract.
- Test-file decomposition and implementation sequencing within the locked behavior above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and public contract
- `.planning/ROADMAP.md` — Phase 149 goal, success criteria, and boundaries with Phases 150-151.
- `.planning/REQUIREMENTS.md` — Authoritative FIRST-01 through FIRST-07 acceptance contract.
- `.planning/STATE.md` — Locked v2.4 constraints, one-recipient contract, and deferred ownership.
- `docs/api_stability.md` — Stable typed-error matching, error-context privacy, and compatibility contract.

### Runtime and authoring behavior
- `lib/mailglass/outbound.ex` — Canonical convergence point for sync, async, batch, preflight, persistence, and dispatch.
- `lib/mailglass/renderer.ex` — Shared rendering pipeline used by direct rendering and delivery/preview paths.
- `lib/mailglass/tenancy.ex` — Process stamp, default resolver, and fail-closed tenancy semantics.
- `lib/mailglass/config.ex` — Published renderer and tenancy configuration schema.
- `guides/authoring-mailables.md` — Published native authoring and explicit-body surface.
- `guides/preview.md` — Published promise that preview uses the production renderer.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.Tenancy.current/0` and `Mailglass.Tenancy.SingleTenant` already encode the resolver-specific `"default"` fallback distinction.
- `Mailglass.SendError` and its existing `:preflight_rejected` type provide the established typed failure surface.
- `Mailglass.Renderer.render/2` is already the shared pure rendering seam.
- `Mailglass.Message` setters preserve native Swoosh envelope/body representation without a new authoring API.
- `test/mailglass/outbound/preflight_test.exs` contains the nearest no-side-effect preflight test patterns.

### Established Patterns
- Public failures use Mailglass error structs and callers match `%Struct{type: atom}`, never message strings.
- Public error context excludes recipient addresses and message content.
- Outbound paths use `with`-based short-circuiting before persistence.
- Preview invokes `Mailglass.Renderer.render/1` and does not send.
- Direct renderer behavior and async preflight already have focused test seams in `test/mailglass/renderer_test.exs` and `test/mailglass/outbound/deliver_later_test.exs`.

### Integration Points
- `lib/mailglass/outbound.ex` — place common tenancy/envelope/body validation ahead of existing side-effecting checks for sync, async, and batch entry points.
- `lib/mailglass/renderer.ex` — implement body precedence plus plaintext and CSS-inliner settings.
- `lib/mailglass/tenancy.ex` — reconcile SingleTenant fallback with outbound preflight without weakening custom tenancy.
- `lib/mailglass/config.ex` — expose the already-validated renderer subtree through the existing configuration seam.
- `mailglass_admin/lib/mailglass_admin/preview_live.ex` — regression-proof renderer parity in preview.
- `docs/api_stability.md`, `guides/authoring-mailables.md`, `guides/getting-started.md`, `guides/jobs.md`, `guides/preview.md`, and `guides/multi-tenancy.md` — reconcile adopter documentation with runtime behavior without expanding scope.

</code_context>

<specifics>
## Specific Ideas

No additional specific requirements — use the established Mailglass/Swoosh surfaces and the locked decisions above.

</specifics>

<deferred>
## Deferred Ideas

- Complete private outbound-envelope fidelity and atomic durable enqueue — Phase 150.
- Sync/async wire equivalence, structured dispatch outcomes, retry honesty, and private-payload lifecycle — Phase 151.
- Recipient fan-out — future requirement RCPT-01, explicitly outside v2.4.
- Native HEEx assigns, new providers/integrations, sent-message snapshots, and admin visual changes remain milestone-level deferrals.

</deferred>

---

*Phase: 149-first-send-contract-foundation*
*Context gathered: 2026-08-02*
