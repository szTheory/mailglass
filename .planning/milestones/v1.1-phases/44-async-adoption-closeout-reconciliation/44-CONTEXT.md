# Phase 44: Async Adoption Closeout Reconciliation - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Complete the async/adoption verification chain for the `mailglass_inbound`
slice and reconcile the minimum milestone records needed so `EXEC-01`,
`EXEC-02`, and `ADOPT-01` no longer contradict shipped Phase 42 behavior.

This is a closeout-proof phase, not a new product phase. It does not widen the
public `mailglass_inbound` contract, does not add a public replay surface, does
not expand installer/setup automation, and does not turn Phase 44 into a broad
milestone archaeology pass.

</domain>

<decisions>
## Implementation Decisions

### Closeout-proof posture
- **D-44-01:** Phase 44 should be treated as an execution-proof and
  bookkeeping-reconciliation phase for already-shipped Phase 42 behavior, not
  as a runtime feature or integration-expansion phase.
- **D-44-02:** The closeout target is narrow and concrete:
  - create an execution-level `42-VERIFICATION.md`
  - reconcile `EXEC-01`, `EXEC-02`, and `ADOPT-01` in
    `.planning/REQUIREMENTS.md`
  - align any milestone state/roadmap records only where they would otherwise
    preserve contradiction
  - rerun milestone audit/closeout proof after the evidence chain is repaired
- **D-44-03:** Do not accept “bookkeeping only” repair that skips behavioral
  proof. The audit gap exists because summary claims outpaced execution
  verification, so the phase must tie shipped behavior back to requirements.

### Proof strictness
- **D-44-04:** Phase 44 should be strict on shipped package behavior and
  published contract, but not strict on full host-app matrix simulation.
- **D-44-05:** The canonical proof surface for this phase is the existing
  package-boundary evidence set:
  - `mailglass_inbound/test/mailglass_inbound/async_execution_test.exs`
  - `mailglass_inbound/test/mailglass_inbound/worker_test.exs`
  - `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`
  - `test/mailglass/stability_contract_test.exs`
  - release/publish proof already wired at the repo root
- **D-44-06:** The new execution verification artifact must map those proof
  lanes directly to:
  - `EXEC-01` durable Oban-backed async dispatch
  - `EXEC-02` bounded `Task.Supervisor` fallback semantics
  - `ADOPT-01` canonical docs, root proof, and release/publish truth
- **D-44-07:** Do not raise the closeout bar to “prove every adopter wiring
  permutation in a real host app” unless planning intentionally widens the
  public support contract. That would be a different phase with different
  maintainer implications.
- **D-44-08:** Internal worker, queue, retry, and replay machinery must remain
  proof inputs, not promoted public API. Verification should confirm honest
  behavior without widening the stable surface.

### Bookkeeping scope
- **D-44-09:** Bookkeeping repair should stay as narrow as possible while still
  removing contradictions from milestone source-of-truth documents.
- **D-44-10:** The minimum in-scope bookkeeping set is:
  - `.planning/REQUIREMENTS.md`
  - `.planning/STATE.md` if it still claims completion while requirements stay
    pending or verification is missing
  - `.planning/ROADMAP.md` only if its Phase 44 or milestone status would
    remain misleading after the verification repair
  - the new Phase 44 planning artifacts needed to support audit re-run
- **D-44-11:** Explicitly out of scope:
  - revisiting Phase 39-41 recovery beyond Phase 43's completed work
  - live `v1.0` publish closeout
  - older accepted bookkeeping debt such as Phase 35 Nyquist residue
  - non-blocking boundary-warning debt
  - release-process redesign
  - new product/docs surface unrelated to the async/adoption closeout chain

### Recommendation-first workflow posture
- **D-44-12:** Downstream research, planning, and execution should synthesize
  one coherent recommendation set by default for routine gray areas rather than
  surfacing broad option menus.
- **D-44-13:** Alternatives may be mentioned only as overrides or exceptions,
  not as equal-weight menus, unless the decision crosses an escalation
  threshold.
- **D-44-14:** Interrupt the user only when the choice would materially change:
  - stable public API, router DSL, config schema, install contract, or
    docs-promised behavior
  - tenant boundary, security posture, retention policy, or replay/audit truth
    semantics
  - permanent maintainer burden through a new dependency, subsystem, or support
    lane
  - a user-visible default workflow the project owner is especially likely to
    care about directly
- **D-44-15:** If a downstream agent does escalate, it should state which
  trigger above caused the escalation. If no trigger is hit, the agent should
  decide and proceed.

### the agent's Discretion
- Exact wording and section layout for `42-VERIFICATION.md`, as long as it is
  clearly execution-level rather than plan-level verification.
- Exact command grouping for the Phase 42 proof lanes, as long as the artifact
  ties concrete commands back to the three requirements honestly.
- Exact bookkeeping note wording in roadmap/state/requirements reconciliation,
  as long as the repaired source-of-truth chain is explicit and non-marketing.
- Whether the workflow-posture preference is reinforced only in this phase
  context or also in project-level methodology artifacts.

</decisions>

<specifics>
## Specific Ideas

- The right mental model is “Phase 43 finished proof for Phases 39-41; Phase 44
  finishes the same recovery pattern for Phase 42 and then closes the
  contradiction chain.”
- The best closeout proof is library-shaped, not app-demo-shaped:
  focused ExUnit and docs-contract lanes proving the package boundary honestly,
  plus root release/publish truth for the sibling package.
- Swoosh/Oban-style honesty should continue here:
  durable async is a real job system concern, fallback is useful but not magic,
  and docs should never imply stronger guarantees than runtime provides.
- Action Mailbox and Anymail are useful precedent for trust semantics:
  persist truth first, process asynchronously, keep replay/retry semantics
  explicit, and do not blur fresh receive with recovery actions.
- The workflow preference should move further left for Mailglass: default to
  decisive synthesis, escalate only for truly contract- or trust-shaping
  choices.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and closeout posture
- `.planning/ROADMAP.md` — Phase 44 goal, requirement mapping, and milestone
  scope.
- `.planning/PROJECT.md` — `v1.1` narrow-slice posture, optional-Oban
  philosophy, and one-maintainer support constraints.
- `.planning/REQUIREMENTS.md` — `EXEC-01`, `EXEC-02`, and `ADOPT-01` plus
  current traceability contradiction.
- `.planning/STATE.md` — current claimed milestone-complete posture that may
  need reconciliation.
- `.planning/METHODOLOGY.md` — decisive-by-default, honest-surface,
  recommendation-first, and escalation posture.
- `.planning/v1.1-MILESTONE-AUDIT.md` — exact audit failure that Phase 44 is
  meant to close.

### Locked inbound decisions from prior phases
- `.planning/phases/39-inbound-package-foundation/39-CONTEXT.md` — locked
  public contract, mailbox contract, and replay boundary.
- `.planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md`
  — locked ingress/storage truth posture.
- `.planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-CONTEXT.md` —
  locked execution-lineage and replay-honesty semantics.
- `.planning/phases/42-async-execution-and-adopter-proof/42-CONTEXT.md` —
  locked async, fallback, and docs-first adopter posture.
- `.planning/phases/42-async-execution-and-adopter-proof/42-VALIDATION.md` —
  named proof lanes and Nyquist validation map for the shipped Phase 42 slice.
- `.planning/phases/42-async-execution-and-adopter-proof/42-01-SUMMARY.md` —
  async runtime proof summary for `EXEC-01` and `EXEC-02`.
- `.planning/phases/42-async-execution-and-adopter-proof/42-02-SUMMARY.md` —
  docs/adoption proof summary for `ADOPT-01`.
- `.planning/phases/42-async-execution-and-adopter-proof/42-03-SUMMARY.md` —
  root verification and publish-proof summary for the sibling package.
- `.planning/phases/43-execution-verification-recovery/43-RESEARCH.md` —
  recovery-phase pattern to mirror without reopening earlier scope.

### Existing code and proof anchors
- `mailglass_inbound/lib/mailglass_inbound/execution.ex` — shared async/load/
  execute seam.
- `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex` — internal
  Oban worker wrapper and retry/failure mapping.
- `mailglass_inbound/lib/mailglass_inbound/application.ex` — package runtime
  supervision and fallback warning posture.
- `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex` — optional Oban
  gateway and runtime mode selection.
- `mailglass_inbound/README.md` — canonical manual adoption lane.
- `mailglass_inbound/docs/api_stability.md` — stable versus internal contract
  inventory.
- `mailglass_inbound/test/mailglass_inbound/async_execution_test.exs` —
  async/fallback behavioral proof.
- `mailglass_inbound/test/mailglass_inbound/worker_test.exs` — internal worker
  contract proof.
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` — adoption,
  fallback, replay, and root-proof drift guard.
- `test/mailglass/stability_contract_test.exs` — repo-root semantic verification
  and sibling-package release truth.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 42 already named and implemented the proof lanes this closeout needs;
  Phase 44 should reuse those lanes rather than inventing a new verification
  subsystem.
- `mailglass_inbound` already has a narrow public contract and explicit
  internal async boundary; verification can stay honest without widening the
  surface.
- Root stability/release proof already covers `mailglass_inbound`, so
  `ADOPT-01` can be proven through shipped docs and repo-root checks rather
  than speculative environment demos.

### Established Patterns
- Mailglass prefers package-boundary proof with focused ExUnit lanes and
  docs-contract assertions over heavyweight app-matrix simulation.
- Optional dependencies are kept behind gateway modules so public contracts do
  not leak implementation-specific worker/job shapes.
- Recovery/verification phases should repair the exact missing evidence chain,
  not opportunistically broaden scope.
- Honest documentation is treated as part of the stable support contract and is
  therefore valid verification evidence when paired with runtime tests.

### Integration Points
- The new execution verification artifact should tie the Phase 42 summaries,
  validation map, code seams, and test lanes back into requirements and
  milestone audit records.
- Requirement reconciliation should happen only after the execution-level proof
  artifact exists, mirroring the Phase 43 recovery discipline.
- Workflow-posture guidance from this context should feed directly into
  downstream researcher/planner behavior for future Mailglass phases.

</code_context>

<deferred>
## Deferred Ideas

- Canonical host-app fixture or matrix proof for inbound setup permutations —
  separate future phase only if Mailglass wants to widen the adopter support
  promise materially.
- Public replay API or operator surface for inbound recovery — still deferred
  beyond the current milestone.
- Broader project-wide GSD workflow changes outside local planning artifacts —
  worth a dedicated workflow/tooling phase if the project wants enforcement
  beyond Mailglass-specific methodology and context guidance.

</deferred>

---

*Phase: 44-async-adoption-closeout-reconciliation*
*Context gathered: 2026-05-06*
