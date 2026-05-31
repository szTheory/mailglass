# Phase 58: verify-first-webhook-operator-path - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Complete the v1.3 trust journey proof for signed webhook verification and one deterministic non-happy-path operator diagnosis scenario.

This phase satisfies `JOUR-03` and `JOUR-04`: the webhook proof must execute the real verify-first signed payload route path, include a deterministic failing-signature assertion, script one deterministic operator troubleshooting scenario, and align both paths with the existing trust checkpoint semantics. It extends the Phase 57 runner/checkpoint foundation; it does not introduce new provider breadth, CI trust lanes, release gates, or reference-host product features.

</domain>

<decisions>
## Implementation Decisions

### Runner Contract
- **D-01:** Keep `mix verify.reference_host.journey` as the only supported trust-runner entrypoint for Phase 58.
- **D-02:** Extend the existing `trust_runner.v1` checkpoint semantics without renaming the Phase 57 stage keys: `install`, `preview`, `send`, `webhook_ingest`, and `operator_troubleshooting`.
- **D-03:** Treat Phase 58 as a semantic deepening of the existing `webhook_ingest` and `operator_troubleshooting` stages, not as a replacement checkpoint schema.

### Webhook Verification Path
- **D-04:** Execute webhook proof through the maintained reference host's public inbound route into `MailglassInbound.Ingress.Plug`.
- **D-05:** Use one existing reference-host provider route, Postmark or SendGrid, with real provider verification semantics. Do not call provider modules directly and do not rely on lower-level test drivers as the primary trust proof.
- **D-06:** Preserve the Phase 52 public-seam boundary: the reference host may use public route wiring and public ingress plugs only, with no copied provider internals or internal-module coupling.

### Negative Signature Assertion
- **D-07:** Include a deterministic failing-signature assertion that proves the real ingress path returns `401` with a closed rejected/signature reason.
- **D-08:** The negative assertion must prove verify-first ordering by showing forged input does not proceed into tenant resolution, persistence, or mailbox execution.

### Operator Diagnosis Scenario
- **D-09:** Use the existing deterministic `:no_match` routing diagnosis surface as the non-happy-path operator scenario.
- **D-10:** Checkpoint operator evidence under the existing `operator_troubleshooting` stage instead of inventing a separate operator evidence schema.
- **D-11:** Operator evidence should align with existing routing-trace / doctor-style evidence shapes: deterministic finding or trace data, closed status language, observed facts, remediation, and machine-readable fields where available.

### Claude's Discretion
- Exact provider choice for the representative signed route, as long as it uses a real reference-host public route and real provider verification.
- Exact checkpoint field additions, provided `trust_runner.v1`, stage names, deterministic ordering, and existing validator compatibility are preserved or intentionally extended.
- Exact test file split and helper names for positive/negative route proof and operator diagnosis proof.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase intent and locked requirements
- `.planning/ROADMAP.md` - Phase 58 goal, requirement mapping (`JOUR-03`, `JOUR-04`), and success criteria.
- `.planning/REQUIREMENTS.md` - v1.3 deterministic trust journey requirements and traceability mapping.
- `.planning/PROJECT.md` - v1.3 preflight locks, public-seam posture, and out-of-scope provider breadth.
- `.planning/STATE.md` - current milestone state and active risk context.
- `.planning/METHODOLOGY.md` - recommendation-first, honest-surface, and decisive-by-default methodology lenses.

### Prior locked context
- `.planning/phases/52-trust-scope-lock-reference-host-baseline/52-CONTEXT.md` - reference-host public-seam boundary and scope lock.
- `.planning/phases/57-deterministic-trust-runner-fixtures/57-CONTEXT.md` - canonical runner entrypoint, deterministic fixtures, and checkpoint schema contract.

### Runner and checkpoint implementation
- `mix.exs` - `verify.reference_host.journey` alias and preferred test environment.
- `lib/mix/tasks/mailglass.trust.run.ex` - canonical trust-runner task, stage pipeline, and checkpoint writing.
- `lib/mailglass/reference_host/trust_checkpoint.ex` - `trust_runner.v1` checkpoint encoder, bounded claim text, stage ordering, and deterministic hash.
- `test/support/reference_host/trust_runner_fixtures.ex` - deterministic fixture IDs and stage ordering.
- `scripts/check_trust_runner_checkpoint.sh` - executable checkpoint schema/order/hash validator.
- `test/reference_host/trust_runner_command_contract_test.exs` - pinned runner command and Phase 58 deferred-semantics boundary.
- `test/reference_host/trust_runner_checkpoint_contract_test.exs` - repeatable checkpoint/hash contract.

### Reference host and webhook ingress surfaces
- `reference/host_app/lib/mailglass_reference_host_web/router.ex` - public Postmark/SendGrid inbound routes through `MailglassInbound.Ingress.Plug`.
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` - verify-before-tenant ordering and signature-error response mapping.
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex` - Postmark provider verification/normalization seam.
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/sendgrid.ex` - SendGrid provider verification/normalization seam.
- `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` - existing plug-level signature failure and verify-first test patterns.
- `mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs` - existing real provider verify/normalize seam tests and deterministic payload fixtures.

### Operator diagnosis surfaces
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - operator routing-trace behavior for `:no_match` records.
- `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` - deterministic routing-trace and evidence-card tests.
- `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex` - DNS-free operator diagnosis command and exit-code semantics.
- `mailglass_inbound/lib/mailglass_inbound/operator/formatter.ex` - machine-readable/human operator finding format.
- `mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex` - deterministic doctor findings and evidence shape.
- `mailglass_admin/docs/operator-trust.md` - operator trust posture and bounded replay/fresh-receive language.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix verify.reference_host.journey` already delegates to `mix mailglass.trust.run`, giving Phase 58 the correct public runner surface.
- `Mailglass.ReferenceHost.TrustCheckpoint` already provides schema-versioned deterministic checkpoint output and hashing.
- `Mailglass.ReferenceHost.TrustRunnerFixtures` already pins stable fixture IDs for `webhook_ingest` and `operator_troubleshooting`.
- `reference/host_app` already mounts public Postmark and SendGrid inbound routes through `MailglassInbound.Ingress.Plug`.
- `MailglassInbound.Ingress.Plug` already implements verify-before-tenant behavior and maps signature errors to deterministic `401` JSON responses.
- Existing inbound fixtures and tests already exercise real provider verify/normalize seams.
- `MailglassAdmin.InboundLive` and inbound doctor formatter already expose deterministic operator evidence surfaces suitable for a scripted non-happy-path diagnosis.

### Established Patterns
- Trust proof is evidence-led: deterministic commands, schema-versioned machine-readable checkpoint artifacts, and executable validators.
- Reference host work must use documented public seams only and remain a thin proof host.
- Webhook verification must fail closed before tenant work or persistence.
- Operator evidence uses bounded, PII-conscious, deterministic language and should not over-claim a broad public API beyond existing docs.

### Integration Points
- `lib/mix/tasks/mailglass.trust.run.ex` is the natural place to replace placeholder stage signals for `webhook_ingest` and `operator_troubleshooting` with real deterministic proof checks.
- `lib/mailglass/reference_host/trust_checkpoint.ex` may need additive evidence fields while preserving existing stage order and checkpoint hash determinism.
- `scripts/check_trust_runner_checkpoint.sh` should be extended only as needed to validate Phase 58 evidence semantics.
- Reference-host router proof should drive `/inbound/:tenant_id/postmark` or `/inbound/:tenant_id/sendgrid` through Phoenix/Plug routing, not through direct provider calls.
- Operator proof should seed or drive a deterministic no-match scenario and capture diagnosis evidence that downstream CI/release lanes can consume in Phase 59/60.

</code_context>

<specifics>
## Specific Ideas

- Prefer one representative provider path over provider-matrix breadth; v1.3 trust proof validates a single representative journey.
- Treat failing signature as a trust-boundary proof, not just a response-code test: no tenant lookup, no persistence, no mailbox execution.
- Use `:no_match` routing trace as the operator non-happy path because it is already deterministic, operator-facing, and evidence-rich.
- Preserve the existing stage names so Phase 59 CI trust lanes and Phase 60 release gates consume one stable artifact shape.

</specifics>

<deferred>
## Deferred Ideas

- Required repo-head and clean-baseline CI trust lanes are Phase 59 scope.
- Published-version trust proof, post-publish smoke reliability closure, and release checklist gating are Phase 60 scope.
- Docs boundary/contract positioning is Phase 61 scope.
- Provider-matrix broadening, `gen_smtp` transport expansion, and ecosystem integrations remain out of scope for v1.3.

</deferred>

---

*Phase: 58-verify-first-webhook-operator-path*
*Context gathered: 2026-05-27*
