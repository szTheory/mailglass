# Phase 162: Protected Release and Scheduled-Control Recovery - Context

**Gathered:** 2026-08-22 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Reconcile PR #222, its candidate commits and checks, release/recovery branches, tags, published Hex facts, retained local release evidence, and `.planning/release-target.json` into one evidence-backed narrative. Restore truthful release-please, repository-hygiene, and post-publish outcomes through their existing protected control and scheduled paths. This phase may disposition blocked release state and narrowly repair control reporting, but it does not force a publication, broaden release authority, repair the database or gallery timeouts assigned to Phase 163, or perform the final documentation/artifact cleanup assigned to Phase 164.

</domain>

<decisions>
## Implementation Decisions

### Release-State Disposition
- **D-01:** Treat the current v2.5.0 candidate state as a blocked reconciliation, not as release authorization. Produce an append-only narrative that joins PR #222 head/base/check facts, candidate and published tags, exact Hex versions/checksums, `.planning/release-target.json`, retained WT-03 publish-summary deltas, and the relevant release/recovery refs.
- **D-02:** The tracked target's current `authorized` / `publication: not_started` state does not authorize merge, tag creation, or publication by itself. Refresh all time-sensitive GitHub, Git, Actions, and Hex facts immediately before any disposition and record `cannot-check` rather than infer when a source is unavailable.
- **D-03:** Give PR #222 and every retained stale release/recovery branch or check exactly one explicit outcome: merge only through the existing protected exact-candidate path, retire with a recorded evidence-backed reason, or retain with a named recovery condition. Nothing may remain auto-merge-armed or unexplained in limbo, and no retained Phase 161 evidence may be deleted merely because the release is blocked.

### Scheduled-Control Truth
- **D-04:** Preserve the existing authority boundary: push, hourly schedule, and digest-free manual release-please runs remain proposal-only. Only the protected exact candidate-digest dispatch may validate and merge the reviewed proposal and cross into tag/release creation; Phase 162 must not add merge, tag, publish, or protected-dispatch authority to ordinary control or scheduled entry points.
- **D-05:** Record control-run and applicable observed scheduled-run evidence separately. A manual dispatch may prove the control path but never substitutes for scheduled execution; pending elapsed-time evidence remains pending, and unavailable evidence reports `cannot-check`.
- **D-06:** Release-please and repository-hygiene must expose bounded, inspectable outcomes through agreeing logs and machine-readable evidence. Preserve the existing `pass`, policy `blocked`, and `cannot-check` semantics, make the narrowest changes needed for truthful results, and do not redesign workflow topology or weaken the already-green protected `CI Green` path.

### Immutable Post-Publish Recovery
- **D-07:** Post-publish recovery is valid only for an exact immutable target whose tracked release state and public package facts prove publication. The existing recovery path must resolve all expected package tags to the same target SHA and verify the authorized content digest.
- **D-08:** While the target remains authorized but unpublished, record post-publish as blocked or inapplicable. Do not substitute `main`, reinterpret a release-event no-op as consumer proof, or force a new release solely to satisfy this phase.

### the agent's Discretion
- Exact filename and schema for the append-only Phase 162 reconciliation artifact, provided every claim cites its source, capture time, immutable identity, and outcome.
- Exact ordering of read-only GitHub, Git, Actions, Hex, and local-ledger queries.
- Exact narrow implementation seam for truthful scheduled/control reporting, provided the authority and evidence contracts above remain unchanged.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Contract
- `.planning/ROADMAP.md` § Phase 162 — fixed goal, success criteria, and Phase 163/164 boundaries.
- `.planning/REQUIREMENTS.md` § Automation and Release Truth — AUTO-01 through AUTO-05 and milestone exclusions.
- `.planning/PROJECT.md` § Current Milestone: v2.7 Repository Stewardship & Operational Hygiene — maintenance-only intent and non-negotiable scope locks.
- `.planning/STATE.md` § Accumulated Context — sequencing, scheduled-proof rule, and time-sensitive evidence concern.
- `.planning/METHODOLOGY.md` — decisive-by-default, honest-surface, recommendation-first, and compatibility-contract lenses.

### Preserved Phase 161 Inputs
- `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-CONTEXT.md` — recoverability-first decisions and explicit Phase 162 handoff boundary.
- `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md` § Phase 162 Handoff — retained WT-03 evidence, release/recovery identities, exact diff, and recovery conditions.
- `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-PRESERVATION-RECONCILIATION.tsv` — one-to-one preserved identities and verified recovery refs.

### Existing Release and Automation Controls
- `.github/workflows/release-please.yml` — proposal-only triggers, protected exact-candidate validation/merge, and release creation authority.
- `.github/workflows/repo-hygiene.yml` — scheduled/control entry points and JSON artifact handling.
- `.github/workflows/post-publish-smoke.yml` — immutable target resolution and recovery entry points.
- `dev/mix/tasks/mailglass.repo.hygiene.ex` — repository status classification and machine-readable report generation.
- `scripts/release_policy.exs` — target lifecycle and protected-release policy semantics.
- `scripts/check_post_publish_target.sh` — exact tag/SHA/content-digest validation.
- `scripts/verify_published_release.sh` — immutable publication and post-publish evidence verification.
- `scripts/reconcile_release_versions.exs` — local release manifest/target reconciliation behavior.
- `.planning/release-target.json` — current tracked authorization and publication ledger.
- `.planning/publish/mailglass-publish-summary.json`, `.planning/publish/mailglass_admin-publish-summary.json`, and `.planning/publish/mailglass_inbound-publish-summary.json` — retained package publication evidence; compare with WT-03 rather than overwriting it.
- `MAINTAINING.md` § Release Flow and recovery guidance — current documented protected workflow, to use as evidence rather than silently treating as settled truth.

No external specifications are canonical for this phase; live GitHub, Actions, Git, and Hex facts must be freshly captured during execution.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/release-please.yml` already separates proposal mode from protected exact-digest authority and validates the proposal head, base/source SHA, required checks, content digest, target versions, and protected-main relationship.
- `scripts/release_policy.exs` plus the `scripts/release_policy_*` wrappers already model the release-target lifecycle, expected tags, package state, content digest, and protected dispatch; extend or reuse these contracts instead of inventing a second release ledger.
- `mix mailglass.repo.hygiene --check` already emits repository findings, and `.github/workflows/repo-hygiene.yml` already preserves a JSON report artifact even when policy blocks the run.
- `.github/workflows/post-publish-smoke.yml`, `scripts/check_post_publish_target.sh`, and `scripts/verify_published_release.sh` already provide the exact-target recovery and verification seams required by AUTO-05.
- Phase 161's inventory, reconciliation TSV, preservation refs, and WT-03 exact diff provide recoverable local evidence for comparison without destructive cleanup.

### Established Patterns
- Release authority is fail-closed and bound to protected `main`, one reviewed proposal head, one dual-authorized candidate digest, one content digest, and exact package versions.
- All three expected release tags must be authoritatively present or absent as a coherent set; partial or unknowable state is a failure, not an inferred success.
- Control truth distinguishes a policy block from an inability to query remote state, and machine-readable artifacts must agree with human-readable logs.
- Published-package proof is immutable-target proof. Scheduled post-publish resolution uses a completed ledger target; an authorized or not-started target cannot masquerade as published evidence.
- Release and planning artifacts are contractual/forensic evidence. Corrections append and cite prior facts rather than rewrite history.

### Integration Points
- GitHub PR #222 and `release-please--branches--main`: proposal identity, head/base OIDs, labels, required checks, mergeability, and auto-merge state.
- GitHub Actions: release-please, repository-hygiene, and post-publish-smoke control/scheduled runs, including live analysis provenance from release-please run `32587776542`, repo-hygiene run `32573781732`, and post-publish run `32572135200`.
- Git/Hex: the candidate tags, their exact commit identities, public package versions, and Hex checksums must reconcile with the ledger rather than with local branch names alone.
- `.planning/release-target.json`: shared lifecycle ledger consumed by protected release and post-publish recovery.
- WT-03 and the Phase 161 evidence set: retained local proposal/publish-summary evidence that must receive an explicit Phase 162 outcome.

</code_context>

<specifics>
## Specific Ideas

- Use one append-only reconciliation narrative as the human-reviewable source tying every live query and retained local artifact to a single disposition.
- Preserve explicit three-state operational language: `pass`, policy `blocked`, and `cannot-check`; do not collapse blocked and unknown into generic failure or green.

</specifics>

<deferred>
## Deferred Ideas

- PostgreSQL property-test and admin gallery-matrix timeout repairs — Phase 163.
- Final maintainer/version/release documentation reconciliation, generated/tracked artifact classification, ignore-rule cleanup, and quiet repository closeout — Phase 164.
- CI efficiency/topology overhaul (SEED-006) — outside v2.7.

### Reviewed Todos (not folded)

None — no pending todos matched Phase 162.

</deferred>

---

*Phase: 162-protected-release-and-scheduled-control-recovery*
*Context gathered: 2026-08-22*
