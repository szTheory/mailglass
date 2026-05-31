# Phase 61: docs-contract-boundary-enforcement - Context

**Gathered:** 2026-05-31 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Enforce reference-host docs as usage proof while directing contract guarantees to canonical API stability artifacts. This phase satisfies `DOCB-01`, `DOCB-02`, and `DOCB-03`: reference docs must state their usage-proof-only boundary, trust-journey surfaces must link canonical contract truth, and deterministic docs verification must block wording that implies reference internals are public API guarantees.

This is a docs-contract and verification phase. It does not change the trust runner, reference-host runtime behavior, CI trust-lane posture, release gates, provider breadth, or product APIs.
</domain>

<decisions>
## Implementation Decisions

### Reference-Host Docs Boundary
- **D-01:** Treat `reference/host_app` docs as usage-proof evidence only. They must explicitly avoid framing the reference host as canonical API stability or compatibility contract truth.
- **D-02:** Keep the reference host positioned as a thin maintained trust-proof baseline using public seams only, not as a second product surface or fixture seed.

### Canonical Stability Source Linking
- **D-03:** Every trust-journey-facing doc surface touched by this phase should route guarantee semantics to canonical stability artifacts: `docs/api_stability.md`, `mailglass_admin/docs/api_stability.md`, `mailglass_inbound/docs/api_stability.md`, and the relevant executable contract checks/tests.
- **D-04:** Prefer the broader enforcement path for trust-entry docs, not only the currently enumerated Tier 1 docs, when those surfaces make trust or contract claims. Likely candidates include `reference/host_app/README.md`, `reference/host_app/SCOPE.md`, `MAINTAINING.md`, `guides/webhooks.md`, `guides/webhook-troubleshooting.md`, and `mailglass_admin/docs/operator-trust.md`.

### Docs-Contract Verification
- **D-05:** Extend existing deterministic docs enforcement rather than adding a parallel mechanism. Primary seams are `mix mailglass.docs.check` (`lib/mix/tasks/mailglass.docs.check.ex`) and docs/contract tests under `test/mailglass/` and `test/reference_host/`.
- **D-06:** Verification must fail on language that implies reference-host internals, provider internals, checkpoint implementation details, or dev-only trust-runner implementation modules are public API guarantees.

### Contract-Guarantee Routing
- **D-07:** Language about internals reachable during reference/trust flows should route guarantees to stability inventories and semantic seams, not to implementation reachability.
- **D-08:** If internal implementation names must appear in trust docs, allow them only with explicit non-contract framing plus nearby canonical stability links. Do not apply a blanket ban that would make troubleshooting docs less useful.

### the agent's Discretion
- Exact forbidden-token and required-token lists are planner/implementer discretion, provided they are deterministic, scoped to trust-contract drift, and do not over-block legitimate technical troubleshooting language.
- Exact split between Mix-task checks and ExUnit contract tests is planner/implementer discretion, provided `DOCB-03` is enforced in CI-compatible verification.

### Folded Todos
- None. The weak todo match `.planning/todos/pending/2026-05-28-add-clean-baseline-trust-lane-after-republish.md` was already folded into Phase 60 per `60-CONTEXT.md` decisions D-03/D-04 and is not Phase 61 scope.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` - Phase 61 goal, requirement mapping, and success criteria.
- `.planning/REQUIREMENTS.md` - `DOCB-01`, `DOCB-02`, `DOCB-03` requirement text and v1.3 traceability table.
- `.planning/PROJECT.md` - v1.3 trust-proof posture, public-seam boundary, docs positioning, and maintainer methodology.
- `.planning/METHODOLOGY.md` - recommendation-first and honest-surface-area lenses for trust-contract work.
- `.planning/phases/52-trust-scope-lock-reference-host-baseline/52-CONTEXT.md` - reference-host public-seam boundary and scope lock.
- `.planning/phases/57-deterministic-trust-runner-fixtures/57-CONTEXT.md` - canonical runner, deterministic checkpoint, and bounded claim decisions.
- `.planning/phases/58-verify-first-webhook-operator-path/58-CONTEXT.md` - signed Postmark/no-match proof boundary and docs-boundary deferral.
- `.planning/phases/59-ci-trust-lanes-checkpoint-evidence/59-CONTEXT.md` - trust-lane/checkpoint artifact decisions and docs-boundary deferral.
- `.planning/phases/60-release-trust-gate-drift-prevention/60-CONTEXT.md` - release trust gate decisions and clean-baseline todo disposition.
- `reference/host_app/README.md` - current reference-host usage-proof, public-seam, runner, and bounded claim text.
- `reference/host_app/SCOPE.md` - reference-host in-scope, non-goal, and deferred boundary text.
- `docs/api_stability.md` - core stable/internal contract inventory.
- `mailglass_admin/docs/api_stability.md` - admin stable contract inventory.
- `mailglass_inbound/docs/api_stability.md` - inbound stable/internal contract inventory.
- `mailglass_admin/docs/operator-trust.md` - operator trust and bounded semantic-seam precedent.
- `lib/mix/tasks/mailglass.docs.check.ex` - deterministic Tier 1 docs contract checker.
- `test/mailglass/docs_contract_test.exs` - existing docs contract test precedent.
- `test/reference_host/trust_runner_command_contract_test.exs` - pinned reference-host trust runner command and bounded claim text.
- `test/reference_host/trust_runner_checkpoint_contract_test.exs` - `trust_runner.v1` schema, stage order, and claim-boundary contract tests.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Mailglass.Docs.Check` already centralizes deterministic docs checking with required tokens, forbidden tokens, banned internal planning IDs, and bounded-language checks.
- `test/mailglass/docs_contract_test.exs` already provides ExUnit precedent for docs contract assertions.
- `test/reference_host/trust_runner_command_contract_test.exs` already pins `reference/host_app/README.md` trust-runner command and claim-boundary language.
- `test/reference_host/trust_runner_checkpoint_contract_test.exs` already pins the `trust_runner.v1` claim boundary and deterministic checkpoint semantics.

### Established Patterns
- Docs drift enforcement is deterministic and release-blocking: required/forbidden tokens are checked by Mix tasks and ExUnit tests, not by review prose alone.
- Trust artifacts use bounded claim language, for example "reference-host trust-journey confidence only" and "preview-pipeline confidence only."
- Public contract boundaries are documented in package-local `api_stability.md` files and supported by contract tests.
- Reference-host boundaries are already constrained by `README.md`, `SCOPE.md`, and `test/reference_host/*contract_test.exs`.

### Integration Points
- Add or extend docs-boundary rules in `lib/mix/tasks/mailglass.docs.check.ex`.
- Add focused assertions to `test/mailglass/docs_contract_test.exs` and/or `test/reference_host/*contract_test.exs` where that keeps checks closest to the affected docs.
- Update reference/trust docs so they link canonical contract truth instead of making local guarantee claims.
</code_context>

<specifics>
## Specific Ideas

- Recommended posture: usage-proof docs may describe what the reference host proves, but guarantee semantics belong to stability docs and executable contract tests.
- Recommended wording shape: "This reference host is usage-proof evidence, not API-contract truth. Stable guarantees live in ..." followed by canonical links.
- Allow internal names only when they are clearly marked as implementation detail or troubleshooting context, not stable API.
</specifics>

<deferred>
## Deferred Ideas

- Provider-matrix broadening remains out of scope for v1.3.
- `SEED-003-ecosystem-integrations` promotion remains deferred.
- `gen_smtp` listener or transport-class expansion remains deferred.
- Changing CI trust-lane required-check posture remains out of scope; Phase 60 locked clean-baseline as publish-gate-only.

### Reviewed Todos (not folded)
- `.planning/todos/pending/2026-05-28-add-clean-baseline-trust-lane-after-republish.md` - reviewed as a weak match; not folded because Phase 60 already folded and superseded it.
</deferred>
