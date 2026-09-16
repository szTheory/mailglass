# Phase 165: Reconcile terminal proof and milestone archive ordering - Context

**Gathered:** 2026-09-13 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Restore a truthful v2.7 lifecycle after the approved Phase 165 planning write intentionally made the successful Phase 164 terminal report historical. Reconcile only milestone metadata and lifecycle machinery, complete and verify Phase 165, produce a passing canonical milestone audit, archive v2.7, and then establish terminal proof over the final archived SHA. This phase adds no product, API, schema, UI, dependency, CI-topology, release, or repository-hygiene capability.

</domain>

<decisions>
## Implementation Decisions

### Lifecycle authority and ordering
- **D-01:** Treat `tmp/phase-164-finalize.FGINGn/report.json` as immutable historical evidence for Phase 164 at `851e3640f7f0eb6e784611d157e3a7329f87e2dc`; never edit, rerun, or cite it as authority for Phase 165 or the archived milestone.
- **D-02:** Add a separate, narrowly v2.7-scoped milestone terminal authority. Leave `/Users/jon/.local/bin/mailglass-finalize-phase 164` and its Phase 164 contract unchanged.
- **D-03:** The milestone authority must expose one installed command accepting only `v2.7`, authenticate the final archived layout, and write only ignored evidence.
- **D-04:** Enforce this order: reconcile metadata and terminal machinery; validate, verify, and complete Phase 165; write a passing canonical audit; preview and execute the full milestone archive; finish every archive-related tracked commit and protected integration; obtain exact attempt-one push CI and natural scheduled evidence for that final archive SHA; run the milestone finalizer once.
- **D-05:** No later v2.7 lifecycle mutation may follow terminal capture. Future milestones are outside the proof's exact archived-SHA claim.

### Minimal reconciliation and scope
- **D-06:** Repair the strict three-source metadata by adding `WSPC-01`, `WSPC-03`, and `WSPC-04` to the appropriate Phase 161 summary frontmatter. The planner must confirm the smallest truthful summary placement against plan ownership; `161-04-SUMMARY.md` is the preferred target because Plan 161-04 owns the final workspace-requirement verification task.
- **D-07:** Re-run validation for Phases 161 and 163 so current validation records use the workflow-recognized `status: validated` while preserving their existing green Nyquist evidence.
- **D-08:** Reconcile ROADMAP, PROJECT, STATE, and `state.json` so they include Phase 165 and contain no stale claim that the Phase 164 terminal step remains pending or is still authoritative for milestone completion.
- **D-09:** Phase 165 receives no new REQ-ID and does not remap the sixteen existing v2.7 requirements.
- **D-10:** Preserve the evidence-backed repository-hygiene policy block. Do not close the fourteen PRs, force a release, change product behavior or workflow topology, upgrade dependencies, or perform destructive cleanup.
- **D-11:** Exclude legacy quick tasks from v2.7 archival because the current completion workflow cannot attribute them accurately to this milestone.

### Verification and operator contract
- **D-12:** Phase 165 needs both an ordinary pre-archive gate and a terminal post-archive gate. Ordinary verification must include focused negative coverage for stale audit data, incomplete archive layout, dirty or moving HEAD, caller-selected or rerun CI, non-natural schedules, and tracked-output leakage.
- **D-13:** Before archival, the canonical audit must report no critical gaps, strict requirements `16/16`, phases `5/5`, integration `16/16`, flows `5/5`, and compliant validation for all five phases. The PR-hygiene policy block remains explicitly disclosed as accepted operational debt.
- **D-14:** The archive dry-run must identify a non-null audit target and exactly Phases 161–165, with quick tasks excluded. Completion must archive ROADMAP, REQUIREMENTS, the canonical audit, and all five phase directories; MILESTONES, PROJECT, STATE, and `state.json` must agree that v2.7 is complete and archived.
- **D-15:** The final milestone report must pass at exact clean `HEAD == origin/main`, authenticate the archived evidence, use exact attempt-one push CI and natural attempt-one schedules, and prove no later v2.7 write.
- **D-16:** Existing approval covers repository-local planning, metadata repair, tests, audit generation, and archive dry-run. Require a fresh exact-tuple approval before creating or changing an installed external terminal executable, and require explicit `--confirm` immediately before the milestone archive mutation.
- **D-17:** Remote tag push, branch deletion, workflow dispatch or rerun, merge bypass, release, and publication remain unauthorized.

### the agent's Discretion
- Exact repository-local module names and internal decomposition for the v2.7 finalizer.
- Exact test-fixture organization and diagnostic wording, provided the authority and negative-case requirements above remain fail-closed.
- Whether machine-state reconciliation is performed by existing GSD helpers or a narrowly scoped repository utility, provided all tracked sources converge truthfully.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone intent and current truth
- `.planning/PROJECT.md` — v2.7 scope, non-goals, and operating principles.
- `.planning/REQUIREMENTS.md` — the sixteen existing requirements and explicit exclusions.
- `.planning/ROADMAP.md` — phase ordering, Phase 164's stale terminal wording, and the Phase 165 boundary.
- `.planning/STATE.md` — current lifecycle and accumulated-context state.
- `.planning/state.json` — machine-readable planning state that must converge with the Markdown artifacts.
- `.planning/METHODOLOGY.md` — decisive, recommendation-first, honest-surface-area, and compatibility lenses.
- `tmp/v2.7-MILESTONE-AUDIT.md` — read-only baseline audit and the exact gaps Phase 165 must close.

### Historical authority and prior evidence
- `tmp/phase-164-finalize.FGINGn/report.json` — immutable historical Phase 164 terminal report.
- `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-04-SUMMARY.md` — preferred repair target for omitted workspace requirement metadata.
- `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-VALIDATION.md` — legacy validation status and existing Nyquist evidence.
- `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-VERIFICATION.md` — passing evidence for all four workspace requirements.
- `.planning/phases/163-deterministic-release-path-timeout-repairs/163-VALIDATION.md` — legacy validation status and existing Nyquist evidence.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md` — Phase 164 terminal authority and no-later-write contract.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-VALIDATION.md` — established separation of ordinary, protected, and terminal evidence.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-VERIFICATION.md` — Phase 164 authority boundaries and closeout evidence.

### Existing finalizer and lifecycle workflows
- `scripts/finalize_phase_164.sh` — current Phase 164 exact-SHA verifier and allowed completion-metadata range.
- `scripts/mailglass_finalize_phase_loader.mjs` — installed-loader authentication and Phase 164-only surface.
- `/Users/jon/.local/bin/mailglass-finalize-phase` — installed historical authority that must remain compatible and unchanged.
- `/Users/jon/.codex/gsd-core/workflows/audit-milestone.md` — canonical audit path and strict evidence classification.
- `/Users/jon/.codex/gsd-core/workflows/complete-milestone.md` — archive preview, confirmation, moves, state rewrites, and later commits.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/finalize_phase_164.sh`: reusable fail-closed patterns for clean/exact HEAD checks, CI selection, natural-schedule proof, ignored output, and terminal observation.
- `scripts/mailglass_finalize_phase_loader.mjs`: reusable digest/authentication and installed-loader structure, but its Phase 164 path/range assumptions must not be broadened in place.
- Existing Phase 161/163 verification and validation artifacts: authoritative evidence for metadata-only normalization without re-opening product work.

### Established Patterns
- Ordinary repository verification, controlled-host checks, protected integration, and terminal capture are separate authorities.
- Terminal proof is meaningful only when captured after all tracked lifecycle mutations at the exact protected-main SHA.
- Installed external authority changes use an exact source/digest/destination/runtime/predecessor/rollback approval tuple.
- Audit completion requires three-source requirement evidence and `status: validated` validation records.

### Integration Points
- Canonical audit generation consumes REQUIREMENTS, SUMMARY frontmatter, VERIFICATION, VALIDATION, and integration evidence.
- Milestone completion relocates all phase directories and the audit, archives ROADMAP and REQUIREMENTS, then rewrites milestone/project/state artifacts.
- The new terminal authority must resolve and authenticate archived v2.7 paths after those moves, not live Phase 164 paths before them.
- Protected-main CI and natural schedules provide the remote evidence consumed only after the final archive SHA exists.

</code_context>

<specifics>
## Specific Ideas

- Shift all repository-local work left and proceed automatically with recommended defaults.
- Ask the user only at the two narrow mutation boundaries: the exact installed-authority approval tuple and the archive command's explicit `--confirm` checkpoint.
- Credentials should be consumed ephemerally from the existing GitHub keychain path when authorized; never copy them into tracked or report output.

</specifics>

<deferred>
## Deferred Ideas

- Closing the fourteen policy-blocked PRs, creating a release, pushing a tag, deleting branches, publishing artifacts, changing workflow topology, dependency upgrades, and product/API/schema/UI work are outside Phase 165.
- Historical quick-task archival is excluded rather than misattributed to v2.7.

### Reviewed Todos (not folded)

None — no pending todo matched Phase 165.

</deferred>

---

*Phase: 165-reconcile-terminal-proof-and-milestone-archive-ordering*
*Context gathered: 2026-09-13*
