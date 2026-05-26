# Phase 51: Stability Closeout - Context

**Gathered:** 2026-05-26 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the remaining stability debt that still contradicts the repo's claimed
trust posture after the live `v1.2` release: Phase 35 Nyquist bookkeeping,
branch-protection automation drift, the bare `mix test` citext OID-cache race,
non-blocking boundary warnings in support/admin verification lanes, and the
old Phase 4 WR-01..WR-06 review items. This phase is a closeout and truth
reconciliation pass, not a new product feature phase.
</domain>

<decisions>
## Implementation Decisions

### Phase 35 Nyquist closeout
- **D-01:** Treat `CLOSE-01` as bookkeeping repair, not new stability-contract implementation. Phase 35 already shipped and its proof artifacts exist; the defect is that `35-VALIDATION.md` still carries stale draft-state fields (`wave_0_complete: false`, pending task rows).

### Branch-protection automation
- **D-02:** Keep branch protection repo-as-code. Update the existing `gh api` desired-state script and scheduled drift workflow to match the current required-check truth instead of replacing them with a manual-only runbook.
- **D-03:** Use `MAINTAINING.md` and the current support-contract buckets as the source of truth for required checks, then align the script/workflow to that truth.

### Citext race remediation
- **D-04:** Fix the bare `mix test` citext failure structurally in the test harness or migration flow. The current probes stay as a safety net, but the phase should remove the underlying shared-type-cache invalidation path rather than adding more retry-only mitigation.

### Boundary-warning closeout
- **D-05:** Resolve boundary warnings narrowly in the support-summary and admin-probe verification paths without widening runtime package boundaries. Default to adjusting test/support seams and helper placement rather than relaxing architectural boundaries.

### WR-01..WR-06 closeout
- **D-06:** Audit the old Phase 4 WR-01..WR-06 items against current code individually. Fix any item that still reproduces or still represents a live risk; otherwise close it explicitly with rationale in the milestone audit rather than reopening historical refactors by default.

### Release-engineering leftovers
- **D-07:** Fold the already-known post-`v1.2` release-engineering leftovers into this closeout pass where they overlap the stability-debt boundary: branch-protection automation drift, release/publish workflow truth cleanup, and related carry-forward bookkeeping discovered in Phase 50.7.

### the agent's Discretion
- Exact artifact update sequence across validation, milestone audit, and maintenance docs.
- Exact shape of any supporting verification scripts or test-harness refactors.
- Whether specific WR items are fixed in code or closed-no-action after audit, as long as each item is explicitly justified.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and project state
- `.planning/ROADMAP.md` — Phase 51 scope, success criteria, and closeout wording.
- `.planning/PROJECT.md` — current release state, accepted carry-forward debt, and milestone framing.
- `.planning/REQUIREMENTS.md` — CLOSE-01..05 requirement definitions and v1.2 traceability.
- `.planning/STATE.md` — current project position and explicit next-step handoff into Phase 51.
- `.planning/METHODOLOGY.md` — decisive-by-default and recommendation-first posture for closeout work.
- `.planning/MILESTONES.md` — milestone-level statement of accepted v1.0/v1.2 closeout debt.

### Prior context and closeout inputs
- `.planning/phases/044.5-v1-0-1-1-release-ceremony/044.5-CONTEXT.md` — prior decision that branch-protection verification remained external debt to be finished in Phase 51.
- `.planning/phases/49-inbound-runtime-operator-tooling/49-CONTEXT.md` — release/runtime-tooling patterns and closeout-quality bar for trust-facing operational seams.
- `.planning/phases/50-inbound-documentation-pass/50-CONTEXT.md` — latest package/docs truth and ship-state framing before the release ceremony.
- `.planning/phases/50.7-v1-2-repo-hygiene-pass/50.7-01-SUMMARY.md` — explicit carry-forward list after the live `v1.2` release.

### Phase 35 / stability contract bookkeeping
- `.planning/milestones/v1.0-phases/35-stability-contract-audit/35-VALIDATION.md` — stale Nyquist bookkeeping artifact to reconcile.
- `test/mailglass/stability_contract_test.exs` — current repo-root stability proof seam, including tracked publish-summary assertions.

### Branch protection and maintenance truth
- `scripts/setup_branch_protection.sh` — existing desired-state branch-protection script; currently stale against modern CI bucket names.
- `.github/workflows/branch-protection-drift.yml` — scheduled re-assert workflow that wraps the script.
- `MAINTAINING.md` — current required-check truth, release runbook, and publish-summary policy.

### Citext race and boundary-warning surfaces
- `test/support/citext_probe.ex` — current root citext recovery probe.
- `mailglass_admin/test/support/citext_probe.ex` — duplicated admin probe path implicated in support/admin verification seams.
- `test/mailglass/persistence_integration_test.exs` — live documentation of the citext OID race and the current mitigation.
- `test/mailglass/migration_test.exs` — schema-level down/up path that still drops and recreates `citext`.
- `test/mailglass/boundary_test.exs` — current explicit runtime boundary contract.
- `lib/mailglass/operator/support_summary.ex` — one of the verification-lane surfaces historically associated with non-blocking boundary noise.

### Historical debt ledger
- `.planning/milestones/v0.1-MILESTONE-AUDIT.md` — preserved WR-01..WR-06 findings and original closeout framing.
- `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/38-CONTEXT.md` — prior release-proof posture and accepted external branch-protection boundary.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/setup_branch_protection.sh`: existing idempotent `gh api` desired-state entrypoint for branch protection.
- `.github/workflows/branch-protection-drift.yml`: existing scheduled wrapper for branch-protection re-assertion.
- `test/support/citext_probe.ex` and `mailglass_admin/test/support/citext_probe.ex`: existing bounded recovery probes that show the current mitigation shape and duplication points.
- `test/mailglass/stability_contract_test.exs`: stable proof seam that already checks sibling-package release truth and publish-summary snapshots.

### Established Patterns
- Planning truth is reconciled in-place through committed artifacts rather than ad hoc notes (`35-VALIDATION.md`, milestone audits, `MAINTAINING.md`).
- Trust-facing maintenance workflows prefer repo-enforced truth plus narrow explicit external steps, not broad manual ceremony.
- Verification-lane warnings are treated as debt to eliminate honestly rather than paper over with broader exclusions.

### Integration Points
- Phase 35 bookkeeping fix will touch archived planning artifacts under `.planning/milestones/v1.0-phases/`.
- Branch-protection work connects `scripts/setup_branch_protection.sh`, `.github/workflows/branch-protection-drift.yml`, and `MAINTAINING.md`.
- Citext and boundary closeout likely intersects root/admin test support, migration/integration tests, and verification entrypoints.
- WR closeout must feed back into `.planning/milestones/v0.1-MILESTONE-AUDIT.md` or the equivalent v1.0 audit closeout record so the debt is explicitly retired.
</code_context>

<specifics>
## Specific Ideas

- The recommended posture is "audit-fix-reconcile", not "rebuild old phases."
- The current branch-protection assets are worth keeping; their defect is drift, not absence.
- The citext probes are evidence of the current failure mode, not the desired end state.
- Phase 51 should end with one coherent closeout truth source instead of leaving separate v1.0 and v1.2 stability leftovers open.
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope.
</deferred>

---

*Phase: 51-stability-closeout*
*Context gathered: 2026-05-26*
