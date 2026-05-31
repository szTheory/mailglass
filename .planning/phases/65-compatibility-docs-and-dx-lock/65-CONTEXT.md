# Phase 65: Compatibility, Docs, and DX Lock - Context

**Gathered:** 2026-05-31 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Give adopters one coherent inbound adoption, compatibility, testing, and
operator-trust story.

This phase covers DX-01, DX-02, DX-03, and DX-04 by aligning existing inbound
README, install/provider/operator/testing/admin-trust docs with the Phase 63
stable/testing/internal/deferred inventory and the Phase 64 executable contract
checks. It is a docs and compatibility-DX lock only. It must not add new
provider behavior, matcher expansion, lifecycle callbacks, public replay API,
provider extension API, worker/queue contract, synthetic inbound dev UI,
ecosystem integrations, `gen_smtp` listener work, or admin DOM/component
guarantees.
</domain>

<decisions>
## Implementation Decisions

### Canonical Adoption Path Ownership
- **D-01:** Keep `mailglass_inbound/README.md` as the single canonical inbound
  adoption lane. Other inbound guides should support, deepen, and stay
  consistent with the README rather than becoming competing setup authorities.
- **D-02:** Planning should verify the full adoption path stays coherent across
  dependency pinning, `body_reader` setup, router/provider wiring, async mode,
  operator follow-through, and links to deeper guides.

### Compatibility And Deprecation Contract Framing
- **D-03:** Express compatibility rules by routing readers to
  `mailglass_inbound/docs/api_stability.md`: explicitly inventoried stable
  inbound surfaces require a deprecation bridge or major-version change before
  breaking semantics.
- **D-04:** State that internal and deferred surfaces may change without
  deprecation, even when modules are reachable, documented for troubleshooting,
  or mentioned by tests. Reachability is not a compatibility promise.
- **D-05:** Apply the compatibility-contract ergonomics lens during planning:
  produce a small deprecation-DX inventory for any stable surface touched by
  the docs pass, including surface, replacement, warning/migration channel,
  `--warnings-as-errors` impact, support horizon, and proof artifact.

### Operator Semantics Trust Boundary
- **D-06:** Lock operator docs at command semantics for
  `mix mailglass.inbound.doctor`, `mix mailglass.inbound.replay`, and
  `mix mailglass.inbound.prune`: documented flags/options, exit semantics,
  tenant guards, confirmation tiers, destructive confirmations, prune behavior,
  and replay-over-stored-truth semantics.
- **D-07:** Keep orchestration modules, internal replay/prune/doctor helpers,
  worker modules, queue names, retry tuning, direct Oban job shapes, admin UI
  implementation details, DOM shape, components, assigns, routes, and CSS
  explicitly non-contractual.
- **D-08:** Admin/operator trust wording must not imply replay as fresh receipt,
  silent reroute, public replay API, stable UI contract, or stable
  DOM/component APIs.

### Testing DX Contract Clarity
- **D-09:** Center testing docs on `MailglassInbound.MailboxCase` and
  `MailglassInbound.Test.Ingress` as the default adopter harness.
- **D-10:** Make process-local capture semantics and `async: false` setup
  consequences explicit enough that adopters do not misread assertion behavior
  or sandbox boundaries.
- **D-11:** Treat the one-assertion-per-drive rule as a hard testing-DX contract:
  each assertion consumes one capture, so examples should drive a new inbound
  message for each assertion instead of stacking multiple consuming assertions
  on one capture.

### the agent's Discretion
- Planner may decide whether compatibility/deprecation wording lives in
  existing compatibility docs, inbound README sections, package-local docs, or
  all of the above, as long as there is one canonical story and drift checks
  guard the resulting contract.
- Planner may decide exact docs-contract assertion names and phrase matching,
  but checks should protect adoption consistency, compatibility posture,
  operator trust boundaries, and testing-DX rules without overfitting ordinary
  prose.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` - Phase 65 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` - DX-01, DX-02, DX-03, DX-04 and v1.4
  out-of-scope table.
- `.planning/PROJECT.md` - v1.4 stability-lock intent, convergence posture, and
  scope guardrails.
- `.planning/STATE.md` - current position, preflight locks, and prior decisions.
- `.planning/METHODOLOGY.md` - decisive-by-default, honest-surface,
  recommendation-first, and compatibility-contract lenses.
- `.planning/phases/63-inbound-contract-inventory-reconciliation/63-CONTEXT.md`
  - locked stable/testing/internal/deferred inventory decisions.
- `.planning/phases/64-contract-verification-hardening/64-CONTEXT.md` - locked
  executable contract and docs-drift proof decisions.

### Adoption And Compatibility Docs
- `mailglass_inbound/README.md` - canonical inbound adoption lane.
- `mailglass_inbound/docs/inbound-install.md` - install and setup deep dive that
  must remain subordinate to the README path.
- `mailglass_inbound/docs/api_stability.md` - canonical inbound stability,
  testing, internal, and deferred contract inventory.
- `guides/compatibility-and-deprecations.md` - project-level compatibility and
  deprecation story checked by docs-contract tooling.
- `docs/compatibility-and-deprecations.md` - ExDoc compatibility/deprecation
  reference checked by docs-contract tooling, if present in the package docs
  topology.

### Operator And Admin Trust Docs
- `mailglass_inbound/docs/inbound-operator.md` - doctor/replay/prune operator
  semantics, exit codes, tenant guards, confirmations, and replay/prune wording.
- `mailglass_inbound/docs/inbound-routing-debug.md` - routing diagnostics and
  operator-facing troubleshooting context.
- `mailglass_admin/docs/operator-trust.md` - admin/operator trust wording and
  non-contractual UI implementation precedent.

### Source Semantics Behind Docs
- `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex` - doctor command
  semantics and exit behavior.
- `mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex` - replay command
  semantics, tenant guard, replay-over-stored-truth behavior, and confirmations.
- `mailglass_inbound/lib/mix/tasks/mailglass.inbound.prune.ex` - prune command
  semantics, tenant guard, destructive confirmations, and exit behavior.
- `mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex` - adopter-facing
  ExUnit case template.
- `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex` - adopter-facing
  inbound test driver.
- `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex` -
  process-local assertion capture semantics and consuming assertions.

### Drift Guards
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` -
  package-local inbound docs-contract assertions.
- `lib/mix/tasks/mailglass.docs.check.ex` - root docs check and Tier-1 docs
  required-phrase posture.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mailglass_inbound/README.md` already presents itself as the canonical inbound
  adoption lane and is already covered by docs-contract checks for setup tokens
  and required language.
- `mailglass_inbound/docs/api_stability.md` already defines the contract
  taxonomy Phase 65 should reference rather than restating independently.
- `mailglass_inbound/docs/inbound-operator.md` already documents operator exit
  codes, tenant requirements, replay/prune confirmations, destructive behavior,
  and replay semantics.
- `mailglass_inbound/docs/inbound-testing.md` and
  `mailglass_inbound/docs/inbound-install.md` already contain the testing-DX
  concepts Phase 65 should make unmistakable.
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` and
  `lib/mix/tasks/mailglass.docs.check.ex` already provide the main drift-guard
  seams for adoption consistency and trust-boundary wording.

### Established Patterns
- Stability is semantics-first and defined by the canonical inventory, not by
  module reachability, source visibility, or generated docs presence.
- Package-local docs-contract tests own inbound-specific wording drift; root
  docs checks own broad Tier-1 documentation posture.
- Operator command semantics may be stable while internal modules, worker
  topology, queue details, retry tuning, job args, and admin UI implementation
  remain internal.
- Testing helpers can be adopter-facing without becoming runtime-stable APIs.

### Integration Points
- Planning should inspect and likely edit `mailglass_inbound/README.md`,
  `mailglass_inbound/docs/inbound-install.md`,
  `mailglass_inbound/docs/inbound-operator.md`,
  `mailglass_inbound/docs/inbound-testing.md`,
  `mailglass_admin/docs/operator-trust.md`, compatibility/deprecation docs, and
  inbound/root docs-contract checks.
- Any docs-contract additions should complement Phase 64's support-contract lane
  rather than creating a separate unverified docs path.
</code_context>

<specifics>
## Specific Ideas

The user confirmed the assumption set as presented. No corrections were made.
</specifics>

<deferred>
## Deferred Ideas

None - analysis stayed within Phase 65 scope.

The following remain explicitly out of scope for v1.4 feature work unless a
future milestone separately promotes them: matcher expansion beyond
recipient/subject/headers, mailbox lifecycle callbacks beyond `process/1`,
public replay API, public provider extension API, public worker/queue contract,
synthetic inbound development UI, `gen_smtp` listener work, ecosystem
integrations, and admin DOM/component guarantees.
</deferred>

---

*Phase: 65-compatibility-docs-and-dx-lock*
*Context gathered: 2026-05-31*
