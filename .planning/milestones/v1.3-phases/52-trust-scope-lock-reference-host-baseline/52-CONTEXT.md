# Phase 52: Trust Scope Lock + Reference Host Baseline - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish one thin maintained reference host app for Mailglass trust proof, with explicit scope allowlist and non-goals. The host must boot from clean checkout with documented setup and prove integration through public seams only.

This phase locks baseline shape and boundaries. It does not broaden provider coverage, add new product features, or absorb release-smoke debt that is mapped to later OPS/EVID phases.

</domain>

<decisions>
## Implementation Decisions

### Reference host artifact
- **D-01:** Create and maintain a dedicated committed reference host app artifact for trust proof work, separate from installer test fixtures (`test/example` remains fixture-only).

### Public seam boundary
- **D-02:** Reference host integration uses documented public Mailglass seams only. Stable anchors include `mix mailglass.install`, `Mailglass.deliver/2` family, `MailglassAdmin.Router.mailglass_admin_routes/2` and `mailglass_operator_routes/2`, and `MailglassInbound.Ingress.Plug`.
- **D-03:** Reference host must not call internal modules or copy provider internals from package source.

### Baseline environment and journey coverage
- **D-04:** Phase 52 baseline is Ecto-capable and suitable for the full trust journey (preview, send, webhook ingest, operator troubleshooting) that Phase 53 will orchestrate.
- **D-05:** Existing no-ecto post-publish smoke remains a separate fast release gate and is not replaced by the reference-host baseline.

### Scope allowlist and enforcement
- **D-06:** Phase 52 must ship explicit proof-scope allowlist and non-goals documentation for the host app.
- **D-07:** Scope boundaries are enforced by review/verification checks (docs or contract checks), not policy prose alone.

### Risk tracking and dependencies
- **D-08:** The open hackney post-publish smoke failure remains tracked as a milestone dependency risk but is not folded into Phase 52 scope; it stays mapped to later OPS/EVID closeout work.

### Claude's Discretion
- Exact reference-host directory name and project layout.
- Exact enforcement mechanism for scope allowlist/non-goals (docs contract test, CI check, or equivalent), as long as it is deterministic and repository-enforced.
- Exact minimal seed/demo data needed for baseline host bootstrapping.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone source of truth
- `.planning/ROADMAP.md` — Phase 52 goal, requirements mapping, and v1.3 scope lock.
- `.planning/REQUIREMENTS.md` — `HOST-01`, `HOST-02`, `HOST-03` and out-of-scope constraints.
- `.planning/PROJECT.md` — trust-proof preflight locks, non-goals, and maintainer posture.
- `.planning/STATE.md` — current milestone position and active risk/dependency notes.
- `.planning/METHODOLOGY.md` — decisive recommendation-first and honest-surface rules.

### Public contract boundaries
- `docs/api_stability.md` — core stable seams and explicit stable/internal split.
- `mailglass_admin/docs/api_stability.md` — stable admin router/auth contract.
- `mailglass_inbound/docs/api_stability.md` — stable inbound ingress/router contract.

### Existing trust and smoke proof seams
- `.github/workflows/post-publish-smoke.yml` — canonical fast consumer-install smoke lane.
- `test/mailglass/install/install_first_preview_smoke_test.exs` — repo-local mirror for release smoke contract.
- `MAINTAINING.md` — release proof posture and required verification lanes.

### Fixture vs maintained-host boundary evidence
- `test/example/README.md` — confirms `test/example` is installer fixture seed, not maintained adopter host.
- `test/support/installer_fixture_helpers.ex` — fixture generation mechanics for installer tests.

### Active risk tracker
- `.planning/todos/pending/2026-05-27-resolve-post-publish-smoke-hackney-dependency-failure.md` — unresolved smoke reliability issue tracked for later phase scope.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix mailglass.install` (`lib/mix/tasks/mailglass.install.ex`) provides canonical host wiring entrypoint.
- `Mailglass` root API (`lib/mailglass.ex`) exposes stable delivery entrypoints needed for host integration.
- `MailglassAdmin.Router` (`mailglass_admin/lib/mailglass_admin/router.ex`) provides stable preview/operator mount macros.
- `MailglassInbound.Ingress.Plug` (`mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`) provides stable inbound verify-first ingress seam.
- Post-publish smoke workflow and mirrored installer smoke test already validate a clean-host bootstrap path.

### Established Patterns
- Stable/internal boundaries are explicit and enforced through api_stability docs plus contract tests.
- Trust claims are backed by deterministic CI or test evidence, not narrative assertions.
- Fast smoke lane and deeper trust journey are intentionally separated to preserve release-window decision speed.

### Integration Points
- Reference host should align with existing install + router + delivery + ingress seams without introducing package-internal coupling.
- Scope allowlist/non-goals should plug into existing docs/contract verification infrastructure.
- Phase 53 deterministic trust runner will consume the host baseline created here.

</code_context>

<specifics>
## Specific Ideas

- Keep the maintained reference host clearly separate from fixture-only test hosts to avoid accidental contract confusion.
- Preserve the current fast no-ecto release smoke gate while introducing a deeper maintained trust baseline for adopter confidence.

</specifics>

<deferred>
## Deferred Ideas

### Reviewed Todos (not folded)
- `Resolve post-publish smoke hackney dependency failure` — reviewed and kept out of Phase 52 because requirements map it to later OPS/EVID reliability closure work; retained as explicit dependency risk.

- Provider-matrix broadening and transport-class expansion remain out of scope for v1.3 trust-proof baseline phases.

</deferred>

---

*Phase: 52-trust-scope-lock-reference-host-baseline*
*Context gathered: 2026-05-27*
